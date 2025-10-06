<?php

namespace App\Http\Controllers;
use Illuminate\Support\Facades\Log;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use App\Models\Transaction;
use App\Models\RejectionReason;
use App\Models\TransactionImage;
use PhpXmlRpc\Client;
use PhpXmlRpc\Value;
use PhpXmlRpc\Request as XmlRpcRequest;
use Ripcord\Ripcord; 
use Illuminate\Support\Facades\Http;
use GuzzleHttp\Guzzle;
use Carbon\Carbon;

function jsonRpcRequest($url, $payload){
    
    try {

        $client = new \GuzzleHttp\Client([
            'verify' => false,
            'headers' => [
                'Content-Type' => 'application/json',
                'Accept-Encoding' => 'gzip, deflate, br'
            ],
            'timeout' => 30,
            'connect_timeout' => 10,
        ]);
        
        $response = $client->post($url, [
            'body' => json_encode($payload, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES),
            'decode_content' => true,

        ]);

        $rawBody = (string) $response->getBody();

        $cleanBody = trim($rawBody);
        $lastBrace = strrpos($cleanBody, '}');
        if ($lastBrace !== false) {
            $cleanBody = substr($cleanBody, 0, $lastBrace + 1);
        }

        $decoded = json_decode($cleanBody, true);

        if(json_last_error() !== JSON_ERROR_NONE){
            Log::error('X JSON_RPC Invalid JSON Response', [
                'url' => $url,
                'error' => json_last_error_msg(),
                'raw' => substr($cleanBody, -500),
            ]);
            return ['error' => 'Malformed JSON response'];
        }

        return $decoded;

    } catch (\GuzzleHttp\Exception\RequestException $e) {
        // ✅ More specific catch for network errors
        Log::error('X JSON_RPC Network Error', [
            'url' => $url,
            'payload' => $payload,
            'error' => $e->getMessage(),
            'code' => $e->getCode(),
        ]);
        return ['error' => 'Network error'];
    } catch (\Exception $e) {
        Log::error('X JSON_RPC Request Failed', [
            'url' => $url,
            'payload' => $payload,
            'error' => $e->getMessage(),
        ]);
        return ['error' => 'Unexpected error'];
    }

}

class TransactionController extends Controller
{
    protected $url = "http://gsq-ibx-rda:8068";
    protected $db = 'rda_beta_new';
    // protected $odoo_url = "http://192.168.118.102:8000/odoo/jsonrpc";
    protected $odoo_url = "http://gsq-ibx-rda:8068/jsonrpc";

    private function authenticateDriver(Request $request)
    {
        $url = $this->url;
        $db = $this->db;
      
        $uid = $request->query('uid') ;
        $login = $request->header('login'); 
        $odooPassword = $request->header('password');
        Log::info('🔐 Login request', [
            'uid' => $request->query('uid'),
            'headers' => [
                'login' => $request->header('login'),
                'password' => $request->header('password'), // ⚠️ don't log in production
            ],
            'body' => $request->all(), // This shows form or JSON body content
        ]);
        
        Log::info("Login is {$login}, UID is {$uid}, Password is {$odooPassword}");
        
        if (!$uid) {
            return response()->json(['success' => false, 'message' => 'UID is required'], 400);
        }

        $odooUrl = "{$this->url}/jsonrpc"; 
       
        
        $response = jsonRpcRequest("$odooUrl", [
            'jsonrpc' => '2.0',
            'method' => 'call',
            'params' => [
                'service' => 'common',
                'method' => 'login',
                'args' => [
                    $db, $login, $odooPassword],
            ],
            'id' => 1
        ]);
      

        if (!isset($response['result']) || !is_numeric($response['result'])) {
            Log::error('❌ Auth failed', [
                'login' => $login,
                'db' => $db,
                'response' => $response
            ]);
            return response()->json(['success' => false, 'message' => 'Login failed'], 403);
        }

      
        $uid = $response['result'];

        // Step 2: Get res.users to find partner_id
        $userRes = jsonRpcRequest("$odooUrl", [
            'jsonrpc' => '2.0',
            'method' => 'call',
            'params' => [
                'service' => 'object',
                'method' => 'execute_kw',
                'args' => [
                    $db,
                    $uid,
                    $odooPassword,
                    'res.users',
                    'search_read',
                    [[['id', '=', $uid]]],
                    ['fields' => ['partner_id', 'login']]
                ]
            ],
            'id' => 2
        ]);

        $userData = $userRes['result'][0] ?? null;
        if (!$userData || !isset($userData['partner_id'][0])) {
            Log::error("❌ No partner_id for user $uid");
            return response()->json(['success' => false, 'message' => 'No partner found'], 404);
        }

        $partnerId = $userData['partner_id'][0];
        $partnerName = $userData['partner_id'][1] ?? '';
        $user = [
            'id' => $uid,
            'login' => $login
        ];

        // Step 3: Get res.partner to check driver_access
        $partnerRes = jsonRpcRequest("$odooUrl", [
            'jsonrpc' => '2.0',
            'method' => 'call',
            'params' => [
                'service' => 'object',
                'method' => 'execute_kw',
                'args' => [
                    $db,
                    $uid,
                    $odooPassword,
                    'res.partner',
                    'search_read',
                    [[['id', '=', $partnerId]]],
                    ['fields' => ['name', 'driver_access']]
                ]
            ],
            'id' => 3
        ]);

        $isDriver = $partnerRes['result'][0]['driver_access'] ?? false;
        if (!$isDriver) {
            Log::warning("❌ Partner $partnerId is not a driver");
            return response()->json(['success' => false, 'message' => 'Not a driver'], 403);
        }

        return [
            'uid' => $uid,
            'login' => $login,
            'partner_id' => $partnerId,
            'partner_name' => $userData['partner_id'][1] ?? '',
        ];
    }

    private function processDispatchManagers(array $domain, string $partnerId, bool $filterByDriver = true): array
    {
        $odooUrl = "{$this->url}/jsonrpc";
        $jobUrl = "{$this->url}/job_dispatcher/queue_job";
        $db = $this->db;
        $uid = request()->query('uid');
        $login = request()->header('login');
        $password = request()->header('password');

        $fields = [
            "id", "de_request_status", "pl_request_status", "dl_request_status", "pe_request_status",
            "dispatch_type", "de_truck_driver_name", "dl_truck_driver_name", "pe_truck_driver_name", "pl_truck_driver_name",
            "de_request_no", "pl_request_no", "dl_request_no", "pe_request_no", "origin_port_terminal_address", "destination_port_terminal_address", "arrival_date", "delivery_date",
            "container_number", "seal_number", "booking_reference_no", "origin_forwarder_name", "destination_forwarder_name", "freight_booking_number",
            "origin_container_location", "freight_bl_number", "de_proof", "de_signature", "pl_proof", "pl_signature", "dl_proof", "dl_signature", "pe_proof", "pe_signature",
            "freight_forwarder_name", "shipper_phone", "consignee_phone", "dl_truck_plate_no", "pe_truck_plate_no", "de_truck_plate_no", "pl_truck_plate_no",
            "de_truck_type", "dl_truck_type", "pe_truck_type", "pl_truck_type", "shipper_id", "consignee_id", "shipper_contact_id", "consignee_contact_id", "vehicle_name",
            "pickup_date", "departure_date","origin", "destination", "de_completion_time", "booking_status",
            "pl_completion_time", "dl_completion_time", "pe_completion_time", "shipper_province","shipper_city","shipper_barangay","shipper_street", 
            "consignee_province","consignee_city","consignee_barangay","consignee_street", "foas_datetime", "service_type", "booking_service",
            "de_assignation_time", "pl_assignation_time", "dl_assignation_time", "pe_assignation_time", "name", "stage_id", "pe_release_by", "de_release_by","pl_receive_by","dl_receive_by"
        ];

        $fieldsToString =[
            "de_request_status", "pl_request_status", "dl_request_status", "pe_request_status",
            "dispatch_type", 
            "de_request_no", "pl_request_no", "dl_request_no", "pe_request_no", "origin_port_terminal_address", "destination_port_terminal_address", "arrival_date", "delivery_date",
            "container_number", "seal_number", "booking_reference_no", "origin_forwarder_name", "destination_forwarder_name", "freight_booking_number",
            "origin_container_location", "freight_bl_number", "de_proof", "de_signature", "pl_proof", "pl_signature", "dl_proof", "dl_signature", "pe_proof", "pe_signature",
            "freight_forwarder_name", "shipper_phone", "consignee_phone", "dl_truck_plate_no", "pe_truck_plate_no", "de_truck_plate_no", "pl_truck_plate_no",
            "de_truck_type", "dl_truck_type", "pe_truck_type", "pl_truck_type", "shipper_id", "consignee_id", "shipper_contact_id", "consignee_contact_id", "vehicle_name",
            "pickup_date", "departure_date","origin", "destination", "de_completion_time", "booking_status",
            "pl_completion_time", "dl_completion_time", "pe_completion_time","shipper_province","shipper_city","shipper_barangay","shipper_street",
            "consignee_province","consignee_city","consignee_barangay","consignee_street", "foas_datetime",  "service_type","booking_service",
            "de_assignation_time", "pl_assignation_time", "dl_assignation_time", "pe_assignation_time","stage_id", "pe_release_by", "de_release_by","pl_receive_by","dl_receive_by"
        ];

       
       

        // Step 1: Fetch dispatch.manager records
        $response = jsonRpcRequest($odooUrl, [
            'jsonrpc' => '2.0',
            'method' => 'call',
            'params' => [
                'service' => 'object',
                'method' => 'execute_kw',
                'args' => [
                    $db,
                    $uid,
                    $password,
                    'dispatch.manager',
                    'search_read',
                    [$domain],
                    ['fields' => $fields]
                ]
            ],
            'id' => rand(1000, 9999)
        ]);

        $records = $response['result'] ?? [];
       

        if (empty($records)) {
            Log::warning("❌ No dispatch.manager records found for driver $partnerId");
            return [];
        }

        // Step 2: Filter by driver name
         $filtered = $records;
        if ($filterByDriver) {
            $filtered = array_filter($records, function ($manager) use ($partnerId) {
                foreach (["de_truck_driver_name", "dl_truck_driver_name", "pe_truck_driver_name", "pl_truck_driver_name"] as $field) {
                    if (isset($manager[$field][1]) && $manager[$field][1] === $partnerId) {
                        return true;
                    }
                }
                return false;
            });
            $filtered = array_values($filtered);
        }


        // Step 3: Normalize fields and enrich with history
        $results = [];

        foreach ($filtered as &$manager) {
            foreach ($fieldsToString as $field) {
                $value = $manager[$field] ?? null;
                $manager[$field] = match (true) {
                    $value === null, $value === false => "",
                    is_array($value) && isset($value[1]) => $value[1],
                    is_bool($value) => $value ? "true" : "false",
                    default => (string) $value
                };
            }
        }
        unset($manager);

        foreach($filtered as $manager) {
            jsonRpcRequest($jobUrl, [
                'jsonrpc' => '2.0',
                'method' => 'call',
                'params' => [
                    'model' => 'dispatch.manager',
                    'id' => $manager['id'],
                    'method' => 'run_laravel_job',
                ],
                'id' => rand(1000, 9999)
            ]);
        }
            

        // ✅ Step 3: Fetch ALL milestone histories in one go
        $dispatchIds = array_column($filtered, 'id');
        $historyRes = jsonRpcRequest($odooUrl, [
            'jsonrpc' => '2.0',
            'method' => 'call',
            'params' => [
                'service' => 'object',
                'method' => 'execute_kw',
                'args' => [
                    $db,
                    $uid,
                    $password,
                    'dispatch.milestone.history',
                    'search_read',
                    [[['dispatch_id', 'in', $dispatchIds]]],
                    ['fields' => [
                        "id", "dispatch_id", "dispatch_type", "fcl_code",
                        "scheduled_datetime", "actual_datetime", "service_type",
                    ]]
                ]
            ],
            'id' => rand(1000, 9999)
        ]);

        $histories = $historyRes['result'] ?? [];
        // 
        // ✅ Step 4: Group histories by dispatch_id
        $historyMap = [];
        foreach ($histories as $history) {
            $dispatchId = is_array($history['dispatch_id']) ? $history['dispatch_id'][0] : $history['dispatch_id'];
            if ($dispatchId !== null) {
                $historyMap[$dispatchId][] = $history;
            }
        }


        
        foreach ($filtered as &$manager) {
            $manager['history'] = $historyMap[$manager['id']] ?? [];

            $notebookRes = jsonRpcRequest($odooUrl, [
                'jsonrpc' => '2.0',
                'method' => 'call',
                'params' => [
                    'service' => 'object',
                    'method' => 'execute_kw',
                    'args' => [$db, $uid, $password, 'consol.type.notebook', 'search_read',
                        [['|', ['consol_origin', '=', $manager['id']], ['consol_destination', '=', $manager['id']]]],
                        ['fields' => ['id', 'consolidation_id','consol_origin', 'consol_destination']]
                    ]
                ],
                'id' => rand(1000, 9999)
            ]);

            $conslMasterId = null;
            foreach ($notebookRes['result'] as $nb) {
                $raw = $nb['consolidation_id'] ?? null;
                if (is_array($raw) && isset($raw[0])) {
                    $conslMasterId = $raw[0];
                    $consolOriginId = $nb['consol_origin'] ?? null;
                    $consolDestinationId = $nb['consol_destination'] ?? null;
                    break; // take the first valid consolidation
                }
            }

            if ($conslMasterId) {
                $masterRes = jsonRpcRequest($odooUrl, [
                    'jsonrpc' => '2.0',
                    'method' => 'call',
                    'params' => [
                        'service' => 'object',
                        'method' => 'execute_kw',
                        'args' => [$db, $uid, $password, 'pd.consol.master', 'search_read',
                            [[['id', '=', $conslMasterId]]],
                            ['fields' => ['id', 'name', 'consolidated_date', 'is_backload', 'is_diverted']]
                        ]
                    ],
                    'id' => rand(1000, 9999)
                ]);

                $consolidationData = $masterRes['result'][0] ?? null;
                if ($consolidationData) {
                    $consolidationData['consolidated_date'] = is_string($consolidationData['consolidated_date']) ? $consolidationData['consolidated_date'] : '';
                    $consolidationData['consol_origin'] = $consolOriginId;
                    $consolidationData['consol_destination'] = $consolDestinationId;
                    $manager['backload_consolidation'] = $consolidationData;
                }
            }
        }
        unset($manager);

        return $filtered;
    }

    public function getTodayBooking(Request $request)
    {
        
        $user = $this->authenticateDriver($request);
        if(!is_array($user)) return $user;

        $url = $this->url;
        $db = $this->db;
        $odooUrl = $this->odoo_url;  

        $uid = $user['uid'];
        $odooPassword = $request->header('password');
        $partnerId = $user['partner_id'];
        $partnerName = $user['partner_name'];

        $today = date('Y-m-d');
        $tomorrow = date('Y-m-d', strtotime('+1 day'));


         $domain = [
            "&",  // AND all of the following
                // ["dispatch_type", "!=", "ff"],

                "|",  // OR: date range match
                    "&", 
                        [ "pickup_date", ">=", $today ],
                        [ "pickup_date", "<=", $tomorrow ],
                    "&", 
                        [ "delivery_date", ">=", $today ],
                        [ "delivery_date", "<=", $tomorrow ],

                "|", "|", "|",  // OR: driver match
                    ["de_truck_driver_name", "=", $partnerId],
                    ["dl_truck_driver_name", "=", $partnerId],
                    ["pe_truck_driver_name", "=", $partnerId],
                    ["pl_truck_driver_name", "=", $partnerId],
                
        ];

        
        $driverData = $this->processDispatchManagers($domain, $partnerName);

        // 🔹 Step 2: collect booking refs from driverData
        $bookingRefs = collect($driverData)
            ->pluck('booking_reference_no') // ⚠️ ensure this matches Odoo field
            ->filter()
            ->unique()
            ->toArray();

        \Log::info("Booking Refs collected:", $bookingRefs);

        // 🔹 Step 3: fetch FF by those booking refs
        $ffData = [];
        if (!empty($bookingRefs)) {
            $ffDomain = [
                ["dispatch_type", "ilike", "ff"], // case-insensitive match
                ["booking_reference_no", "in", array_values($bookingRefs)],
            ];
            // \Log::info("FF Domain:", $ffDomain);

            $ffData = $this->processDispatchManagers($ffDomain, $partnerName, false);
            // \Log::info("FF Data fetched:", $ffData);
        }

        // 🔹 Step 4: merge driver + FF results
        $data = array_merge($driverData, $ffData);


        // ✅ Final return
        return response()->json([
            'data' => [
                'transactions' => $data
            ]
        ]);
    }

    public function getOngoingBooking(Request $request)
    {
        $user = $this->authenticateDriver($request);
        if(!is_array($user)) return $user;

        $url = $this->url;
        $db = $this->db;
        $odooUrl = $this->odoo_url;  

        $uid = $user['uid'];
        $odooPassword = $request->header('password');
        $partnerId = $user['partner_id'];
        $partnerName = $user['partner_name'];

        $page = (int) request()->query('page', 1);
        $limit = (int) request()->query('limit', 10);
        $offset = ($page - 1) * $limit;

        $today = date('Y-m-d');
        $tomorrow = date('Y-m-d', strtotime('+1 day'));
        // Step 4: Find all dispatch.manager records where driver name matches
        $domain =[
            "&",  // AND all of the following
                "|", "|", "|", // OR: status is "Ongoing" in any leg
                    ["de_request_status", "=", "Ongoing"],
                    ["pl_request_status", "=", "Ongoing"],
                    ["dl_request_status", "=", "Ongoing"],
                    ["pe_request_status", "=", "Ongoing"],

                "|", "|", "|",  // OR: driver match
                    ["de_truck_driver_name", "=", $partnerId],
                    ["dl_truck_driver_name", "=", $partnerId],
                    ["pe_truck_driver_name", "=", $partnerId],
                    ["pl_truck_driver_name", "=", $partnerId]
        ];

        $data = $this->processDispatchManagers($domain,  $partnerName);


        // ✅ Final return
        return response()->json([
            'data' => [
                'transactions' => $data
            ]
        ]);

        
    }

    public function getHistoryBooking(Request $request)
    {
        $url = $this->url;
        $db = $this->db;
      
        $user = $this->authenticateDriver($request);
        if(!is_array($user)) return $user;

        
        $odooUrl = $this->odoo_url;  

        $uid = $user['uid'];
        $odooPassword = $request->header('password');
        $partnerId = $user['partner_id'];
        $partnerName = $user['partner_name'];

        $today = date('Y-m-d');
        $tomorrow = date('Y-m-d', strtotime('+1 day'));
        

        $domain = [
            "&",  // AND all of the following
                // Grouped ORs for Completed or Rejected
                "|",
                // Group 1: Completed statuses
                "|", 
                    ["de_request_status", "=", "Completed"],
                    "|",
                        ["pl_request_status", "=", "Completed"],
                        "|",
                            ["dl_request_status", "=", "Completed"],
                            ["pe_request_status", "=", "Completed"],

                "|",
                    // Group 1: Completed statuses
                    "|", 
                        ["de_request_status", "=", "Backload"],
                        "|",
                            ["pl_request_status", "=", "Backload"],
                            "|",
                                ["dl_request_status", "=", "Backload"],
                                ["pe_request_status", "=", "Backload"],

                // Group 2: Rejected statuses
                "|", ["stage_id", "=", 6], ["stage_id", "=", 7],

                "|", "|", "|",  // OR: driver match
                    ["de_truck_driver_name", "=", $partnerId],
                    ["dl_truck_driver_name", "=", $partnerId],
                    ["pe_truck_driver_name", "=", $partnerId],
                    ["pl_truck_driver_name", "=", $partnerId]
        ];

        
        $data = $this->processDispatchManagers($domain, $partnerName);


        // ✅ Final return
        return response()->json([
            'data' => [
                'transactions' => $data
            ]
        ]);
        

    }

    public function getAllHistory(Request $request)
    {
        $url = $this->url;
        $db = $this->db;
      
        $user = $this->authenticateDriver($request);
        if(!is_array($user)) return $user;

        $odooUrl = $this->odoo_url;  

        $uid = $user['uid'];
        $odooPassword = $request->header('password');
        $partnerId = $user['partner_id'];
        $partnerName = $user['partner_name'];


        $today = date('Y-m-d');
        $tomorrow = date('Y-m-d', strtotime('+1 day'));
     
        $domain = [
            "&",  // AND all of the following
                // Grouped ORs for Completed or Rejected
                "|",
                // Group 1: Completed statuses
                "|", 
                    ["de_request_status", "=", "Completed"],
                    "|",
                        ["pl_request_status", "=", "Completed"],
                        "|",
                            ["dl_request_status", "=", "Completed"],
                            ["pe_request_status", "=", "Completed"],

                "|",
                        // Group 1: Completed statuses
                        "|", 
                            ["de_request_status", "=", "Backload"],
                            "|",
                                ["pl_request_status", "=", "Backload"],
                                "|",
                                    ["dl_request_status", "=", "Backload"],
                                ["pe_request_status", "=", "Backload"],

                // Group 2: Rejected statuses
                "|", ["stage_id", "=", 6], ["stage_id", "=", 7],

                "|", "|", "|",  // OR: driver match
                    ["de_truck_driver_name", "=", $partnerId],
                    ["dl_truck_driver_name", "=", $partnerId],
                    ["pe_truck_driver_name", "=", $partnerId],
                    ["pl_truck_driver_name", "=", $partnerId]
        ];

        
        $data = $this->processDispatchManagers($domain, $partnerName);


        // ✅ Final return
        return response()->json([
            'data' => [
                'transactions' => $data
            ]
        ]);
    }

    public function getAllBooking(Request $request)
    {
        $url = $this->url;
        $db = $this->db;
      
        $user = $this->authenticateDriver($request);
        if(!is_array($user)) return $user;

        $odooUrl = $this->odoo_url;  

        $uid = $user['uid'];
        $odooPassword = $request->header('password');
        $partnerId = $user['partner_id'];
        $partnerName = $user['partner_name'];

        $today = date('Y-m-d');

        $page = (int) request()->query('page', 1);
        $limit = (int) request()->query('limit', 5);
        $offset = ($page - 1) * $limit;

        // Step 5: Queue a job for each dispatch.manager record
        $domain =[
            "|", "|", "|", // OR: driver match
            ["de_truck_driver_name", "=", $partnerId],
            ["dl_truck_driver_name", "=", $partnerId],
            ["pe_truck_driver_name", "=", $partnerId],
            ["pl_truck_driver_name", "=", $partnerId],
            // "|",
            // ['pickup_date', ">=", $today],
            // ['delivery_date', ">=", $today],
           
            // ["dispatch_type", "=", "ff"]

        ];
        $countRes = jsonRpcRequest($odooUrl, [
            'jsonrpc' => '2.0',
            'method' => 'call',
            'params' => [
                'service' => 'object',
                'method' => 'execute_kw',
                'args' => [
                    $db,
                    $uid,
                    $odooPassword,
                    'dispatch.manager',
                    'search_count',
                    [$domain]
                ]
            ],
            'id' => rand(1000, 9999)
        ]);

        $total = $countRes['result'] ?? 0;
        $lastPage = (int) ceil($total / $limit);


        
        $driverData = $this->processDispatchManagers($domain, $partnerName);

        // 🔹 Step 2: collect booking refs from driverData
        $bookingRefs = collect($driverData)
            ->pluck('booking_reference_no') // ⚠️ ensure this matches Odoo field
            ->filter()
            ->unique()
            ->toArray();

        \Log::info("Booking Refs collected:", $bookingRefs);

        // 🔹 Step 3: fetch FF by those booking refs
        $ffData = [];
        if (!empty($bookingRefs)) {
            $ffDomain = [
                ["dispatch_type", "ilike", "ff"], // case-insensitive match
                ["booking_reference_no", "in", array_values($bookingRefs)],
            ];
            // \Log::info("FF Domain:", $ffDomain);

            $ffData = $this->processDispatchManagers($ffDomain, $partnerName, false);
            // \Log::info("FF Data fetched:", $ffData);
        }

        // 🔹 Step 4: merge driver + FF results
        $data = array_merge($driverData, $ffData);


        // ✅ Final return
        return response()->json([
            'data' => [
                'transactions' => $data,
            'current_page' => $page,
            'last_page' => $lastPage
            ]
        ]);
    }
  

    public function updateStatus(Request $request ,$transactionId)
    {
        // Log::info("Transaction ID is {$transactionId}");
        Log::info("Incoming update request", ['data' => $request->all()]);

        $validated = $request->validate([
            'requestNumber' => 'required|string',
            'requestStatus' => 'required|string',
            'timestamp' => 'required|date',
        ]);
       
        $url = $this->url;
        $db = $this->db;

        $uid = $request->query('uid') ;
        $odooPassword = $request->header('password');
        
        if (!$uid) {
            return response()->json(['success' => false, 'message' => 'UID is required'], 400);
        }
        
        
        $odooUrl = $this->odoo_url;
        $updateStatus = [
            "jsonrpc" => "2.0",
            "method" => "call",
            "params" => [
                "service" => "object",
                "method" => "execute_kw",
                "args" => [
                    $db, 
                    $uid, 
                    $odooPassword, 
                    "dispatch.manager", 
                    "search_read",
                    [[["id", "=", $transactionId],
                    '|','|','|',
                    ['de_request_no', '=', $validated['requestNumber']],
                    ['dl_request_no', '=', $validated['requestNumber']],
                    ['pe_request_no', '=', $validated['requestNumber']],
                    ['pl_request_no', '=', $validated['requestNumber']],
                    ]],  // Search by Request Number
                    ["fields" => [
                        "id", "name","de_request_status", "pl_request_status", "dl_request_status", "pe_request_status",
                        "de_request_no", "pl_request_no", "dl_request_no", "pe_request_no"
                    ]]
                ]
            ],
            "id" => 1
        ];
    
        $statusResponse = json_decode(file_get_contents($odooUrl, false, stream_context_create([
            "http" => [
                "header" => "Content-Type: application/json",
                "method" => "POST",
                "content" => json_encode($updateStatus),
            ],
        ])), true);
    
        if (!isset($statusResponse['result']) || empty($statusResponse['result'])) {
            Log::error("❌ No data on this ID", ["response" => $statusResponse]);
            return response()->json(['success' => false, 'message' => 'Data not found'], 404);
        }

        $transactionIds = $statusResponse['result'][0] ?? null;
   
      
        if (!$transactionIds || !is_array($transactionIds)) {
            Log::error("Incorrect structure", ["response" => $statusResponse]);
            return response()->json(['success' => false, 'message' => 'Transaction structure is incorrect.'], 404);
        }

        $updateField = null;

        $requestNumber = (string) $validated['requestNumber'];

        // Debugging log
        Log::info("Transaction Data", ["transaction" => $transactionIds, "requestNumber" => $requestNumber]);
        

        if (isset($transactionIds['de_request_no']) && (string) $transactionIds['de_request_no'] === $validated['requestNumber']){
            $updateField = "de_request_status";
        }elseif (isset($transactionIds['dl_request_no']) && (string) $transactionIds['dl_request_no'] === $validated['requestNumber']){
            $updateField = "dl_request_status";
        }elseif (isset($transactionIds['pe_request_no']) && (string) $transactionIds['pe_request_no'] === $validated['requestNumber']){
            $updateField = "pe_request_status";
        }elseif (isset($transactionIds['pl_request_no']) && (string) $transactionIds['pl_request_no'] === $validated['requestNumber']){
            $updateField = "pl_request_status";
        }

        if (!$updateField) {
            Log::error("❌ Request number doesn't match any field", [
                "requestNumber" => $requestNumber,
                "de_request_no" => $transactionIds['de_request_no'] ?? 'N/A',
                "dl_request_no" => $transactionIds['dl_request_no'] ?? 'N/A',
                "pe_request_no" => $transactionIds['pe_request_no'] ?? 'N/A',
                "pl_request_no" => $transactionIds['pl_request_no'] ?? 'N/A'
            ]);
            return response()->json(['success' => false, 'message' => 'Invalid request number'], 400);
        }

        $updatePending = [
            "jsonrpc" => "2.0",
            "method" => "call",
            "params" => [
                "service" => "object",
                "method" => "execute_kw",
                "args" => [
                    $db, 
                    $uid, 
                    $odooPassword, 
                    "dispatch.manager", 
                    "write",
                    [
                        [$transactionIds['id']],
                        [
                            $updateField => $request->requestStatus,
                        ]
                    ]
                ]
            ],
            "id" => 2
        ];

        $updateResponse = json_decode(file_get_contents($odooUrl,false,stream_context_create([
            "http" => [
                "header" => "Content-Type: application/json",
                "method" => "POST",
                "content" => json_encode($updatePending),
            ]
        ])), true);

        if (isset($updateResponse['result']) && $updateResponse['result']) {
            return response()->json(['success' => true, 'message'=>'Transaction status updated succcessfully!']);
        }else{
            Log::error("Failed to update status", ["response" => $updateResponse]);
            return response()->json(['success' => false,'message'=>'Failed to update transaction'], 500);
        }
       
        return response()->json($statusResponse);
    }

    private function handleDispatchRequest(Request $request)
    {
        $url = $this->url;
        $db = $this->db;
        $uid = $request->query('uid') ;
        $odooPassword = $request->header('password');
        $images = $request->input('images');
        $signature = $request->input('signature');
        $transactionId = (int)$request->input('id');
        $dispatchType = $request->input('dispatch_type');
        $requestNumber = $request->input('request_number');
        $actualTime = $request->input('timestamp');
        $enteredName = $request->input('enteredName');
        $newStatus = $request->input('newStatus');
        $containerNumber = $request->input('enteredContainerNumber');

        Log::info('Received file uplodad request', [
            'uid' => $uid,
            'id' => $transactionId,
            'dispatch_type' => $dispatchType,
            'requestNumber' => $requestNumber,
            'actualTime' => $actualTime,
            
            'enteredContainerNumber' => $containerNumber,
            // 'images' => $request->input('images'),
            // 'signature' => $request->input('signature'),
        ]); 

        

        if (!$uid) {
            return response()->json(['success' => false, 'message' => 'UID is required'], 400);
        }

        $odooUrl = $this->odoo_url;
        $proof_attach = [
            "jsonrpc" => "2.0",
            "method" => "call",
            "params" => [
                "service" => "object",
                "method" => "execute_kw",
                "args" => [
                    $db, 
                    $uid, 
                    $odooPassword, 
                    "dispatch.manager", 
                    "search_read",
                    [[["id", "=", $transactionId]]],  // Search by Request Number
                    ["fields" => ["dispatch_type","de_request_no", "pl_request_no", "dl_request_no", "pe_request_no","service_type", "booking_reference_no" ]]
                ]
            ],
            "id" => 1
        ];
        
        $statusResponse = json_decode(file_get_contents($odooUrl, false, stream_context_create([
            "http" => [
                "header" => "Content-Type: application/json",
                "method" => "POST",
                "content" => json_encode($proof_attach),
            ],
        ])), true);
    
        if (!isset($statusResponse['result']) || empty($statusResponse['result'])) {
            Log::error("❌ No data on this ID", ["response" => $statusResponse]);
            return response()->json(['success' => false, 'message' => 'Data not found'], 404);
        }

        $type = $statusResponse['result'][0] ?? null;
      
        if (!$type) {
            Log::error("❌ Missing dispatch_type", ["response" => $statusResponse]);
            return response()->json(['success' => false, 'message' => 'dispatch_type is missing or invalid'], 404);
        }
        
        // Check that the type is valid before proceeding
        if (!in_array($type['dispatch_type'], ['ot', 'dt'])) {
            Log::error("Incorrect dispatch_type", ["dispatch_type" => $type, "response" => $statusResponse]);
            return response()->json(['success' => false, 'message' => 'Invalid dispatch_type value'], 404);
        }

        return $type;
    }
    private function buildUpdateField1($type, $requestNumber, $images, $signature, $enteredName, $actualTime, $containerNumber, $newStatus, $serviceType) 
    {
        $updateField = [];
        if ($type['dispatch_type'] == "ot" && $type['de_request_no'] == $requestNumber) {
            Log::info("Updating PE proof and signature for request number: {$requestNumber}");
            $updateField = [
                "pe_proof" => $images,
                "pe_signature" => $signature,
                "pe_release_by" => $enteredName,
                "stage_id" => 5,
                "de_request_status" => $newStatus,
            ];
            
            
        } elseif ($type['dispatch_type'] == "ot" && $type['pl_request_no'] == $requestNumber) {
            Log::info("Updating PL proof and signature for request number: {$requestNumber}");
            $updateField = [
                "pl_proof" => $images,
                "pl_signature" => $signature,
                "dl_receive_by" => $enteredName,
                "pl_request_status" => $newStatus,
                "container_number" => $containerNumber
            ];
            if($serviceType == 2){
                $updateField["stage_id"] = 5;
            }
            
            
        }

        if ($type['dispatch_type'] == "dt" && $type['dl_request_no'] == $requestNumber) {
            Log::info("Updating PL proof and signature for request number: {$requestNumber}");
            $updateField = [
                "pl_proof" => $images,
                "pl_signature" => $signature,
                "pe_release_by" => $enteredName,
                "stage_id" => 5,
                "dl_request_status" => $newStatus,
                "container_number" => $containerNumber
            ];
            if($serviceType == 2){
                $updateField["stage_id"] = 5;
            }
            
            
        } elseif ($type['dispatch_type'] == "dt" && $type['pe_request_no'] == $requestNumber) {
            Log::info("Updating PE proof and signature for request number: {$requestNumber}");
            $updateField = [
                "pe_proof" => $images,
                "pe_signature" => $signature,
                "dl_receive_by" => $enteredName,
                "pe_request_status" => $newStatus,
            ];
        }
        return $updateField;
    }

    private function buildUpdateField2($type, $requestNumber, $images, $signature, $enteredName, $actualTime, $containerNumber, $newStatus, $serviceType)
    {
        $updateField = [];
        if ($type['dispatch_type'] == "ot" && $type['de_request_no'] == $requestNumber) {
            Log::info("Updating DE proof and signature for request number: {$requestNumber}");
            $updateField = [
                "de_proof" => $images,
                "de_signature" => $signature,
                "de_release_by" => $enteredName,
                "de_completion_time" => $actualTime,
                // "de_request_status" => $newStatus,
            ];
        }  
        if ($type['dispatch_type'] == "ot" && $type['pl_request_no'] == $requestNumber) {
            Log::info("Updating DL proof and signature for request number: {$requestNumber}");
            $updateField = [
                "dl_proof" => $images,
                "dl_signature" => $signature,
                "pl_receive_by" => $enteredName,
                "stage_id" => 7,
                "pl_completion_time" => $actualTime,
                // "pl_request_status" => $newStatus,
                "container_number" => $containerNumber
            ];
        }

        if ($type['dispatch_type'] === "dt" && $type['dl_request_no'] === $requestNumber && isset($type['service_type']) && $type['service_type'] == 2) {
            Log::info("Updating DL proof and signature for request number: {$requestNumber} with service_type = 2");
            $updateField = [
                "dl_proof" => $images,
                "dl_signature" => $signature,
                "de_release_by" => $enteredName,
                "dl_completion_time" => $actualTime,
                "stage_id" => 7,
                // "dl_request_status" => $newStatus,
                "container_number" => $containerNumber
            ];
        }   
        if($type['dispatch_type'] === "dt" && $type['dl_request_no'] === $requestNumber) {
            $updateField = [
                "dl_proof" => $images,
                "dl_signature" => $signature,
                "de_release_by" => $enteredName,
                "dl_completion_time" => $actualTime,
                // "dl_request_status" => $newStatus,
                "container_number" => $containerNumber
            ];
        }  
        if ($type['dispatch_type'] === "dt" && $type['pe_request_no'] === $requestNumber) {
            Log::info("Updating DE proof and signature for request number: {$requestNumber}");
            $updateField = [
                "de_proof" => $images,
                "de_signature" => $signature,
                "pl_receive_by" => $enteredName,
                "stage_id" => 7,
                "pe_completion_time" => $actualTime,
                // "pe_request_status" => $newStatus,
                "container_number" => $containerNumber
            ];
        }
        return $updateField;
    }


    private function updateFFContainerNumber($type, $containerNumber, $db, $uid, $odooPassword, $odooUrl)
    {
        $bookingRef = $type['booking_reference_no'] ?? null;
        if ($bookingRef && $containerNumber) {
            $searchFF = [
                "jsonrpc" => "2.0",
                "method" => "call",
                "params" => [
                    "service" => "object",
                    "method" => "execute_kw",
                    "args" => [
                        $db,
                        $uid,
                        $odooPassword,
                        "dispatch.manager",
                        "search",
                        [[
                            ["booking_reference_no", '=', $bookingRef],
                            ["dispatch_type", '=', "ff"]
                        ]]
                    ],
                ],
                "id" => 101
            ];
            $ffRes = jsonRpcRequest($odooUrl, $searchFF);
            $ffIds = $ffRes['result'] ?? [];

            if (!empty($ffIds)) {
                // ✅ Update container_number only in ff
                $updateFFContainer = [
                    "jsonrpc" => "2.0",
                    "method" => "call",
                    "params" => [
                        "service" => "object",
                        "method" => "execute_kw",
                        "args" => [
                            $db,
                            $uid,
                            $odooPassword,
                            "dispatch.manager",
                            "write",
                            [
                                $ffIds,
                                [
                                    "container_number" => $containerNumber
                                ]
                            ]
                        ]
                    ],
                    "id" => 102
                ];
                $ffUpdateRes = jsonRpcRequest($odooUrl, $updateFFContainer);
                Log::info("Updated container_number in FF for bookingRef {$bookingRef}, ffIds: " . json_encode($ffIds));
            } else {
                Log::warning("No FF found for bookingRef {$bookingRef}");
            }
        }
    }

    private function updateDispatchRecord($transactionId, $updateField, $db, $uid, $odooPassword, $odooUrl)
    {
        $updatePOD = [
            "jsonrpc" => "2.0",
            "method" => "call",
            "params" => [
                "service" => "object",
                "method" => "execute_kw",
                "args" => [
                    $db, 
                    $uid, 
                    $odooPassword, 
                    "dispatch.manager", 
                    "write",
                    [
                        [$transactionId],
                       
                        $updateField,
                        
                    ]
                ],
                "kwargs" => [
                    "context" => [
                        "skip_set_status" => true
                    ]
                ]
            ],
            "id" => 4
        ];

        $response = file_get_contents($odooUrl, false, stream_context_create([
            "http" => [
                "header" => "Content-Type: application/json",
                "method" => "POST",
                "content" => json_encode($updatePOD),
            ]
        ]));

        return json_decode($response, true);

    }

    private function getMilestoneHistory($transactionId, $db, $uid, $odooPassword, $odooUrl)
    {
        $milestoneCodeSearch = [
            "jsonrpc" => "2.0",
            "method" => "call",
            "params" => [
                "service" => "object",
                "method" => "execute_kw",
                "args" => [
                    $db, 
                    $uid, 
                    $odooPassword, 
                    "dispatch.milestone.history", 
                    "search_read",
                    [[["dispatch_id", "=", $transactionId]]],  // Search by Request Number
                    ["fields" => ["id","dispatch_type","actual_datetime","scheduled_datetime","fcl_code","is_backload"]]
                ]
            ],
            "id" => 5
        ];
    
        $response = file_get_contents($odooUrl, false, stream_context_create([
            "http" => [
                "header" => "Content-Type: application/json",
                "method" => "POST",
                "content" => json_encode($milestoneCodeSearch),
            ],
        ]));

        $fcl_code_response = json_decode($response, true);

        if (!isset($fcl_code_response['result']) || empty($fcl_code_response['result'])) {
            Log::error("❌ No data on this ID", ["response" => $fcl_code_response]);
            return response()->json(['success' => false, 'message' => 'Data not found'], 404);
        }

        return $fcl_code_response['result'];

    }

    private function updateMilestoneAndSendEmail(array $milestoneResultList, string $milestoneCodeToUpdate, string $actualTime, string $db, int $uid, string $odooPassword, string $odooUrl)
    {
        $milestoneIdToUpdate = null;
        $fcl_code = null;

        foreach ($milestoneResultList as $milestone) {
            if ($milestone['fcl_code'] === $milestoneCodeToUpdate) {
                $milestoneIdToUpdate = $milestone['id'];
                $fcl_code = $milestone['fcl_code'];
                    Log::info("🆗 Milestone matched and ID found", [
                    'milestone_id' => $milestoneIdToUpdate,
                    'fcl_code' => $fcl_code
                ]);
                break;
            }
        }

        if (!$milestoneIdToUpdate) {
            return response()->json(['success' => false, 'message' => 'Milestone not found'], 404);
        }

        $update_actual_time = [
            "jsonrpc" => "2.0",
            "method" => "call",
            "params" => [
                "service" => "object",
                "method" => "execute_kw",
                "args" => [
                    $db,
                    $uid,
                    $odooPassword,
                    "dispatch.milestone.history",
                    "write",
                    [
                        [$milestoneIdToUpdate],
                        [
                            'actual_datetime' => $actualTime,
                            'button_readonly' => true, 
                            'button_confirm_semd' => false,
                            'clicked_by' => (int) $uid,
                        ]
                    ]
                ]
            ],
            "id" => 6
        ];

        $updateActualResponse = json_decode(file_get_contents($odooUrl, false, stream_context_create([
            "http" => [
                "header" => "Content-Type: application/json",
                "method" => "POST",
                "content" => json_encode($update_actual_time),
            ]
        ])), true);
        Log::debug("📝 Actual time update response", ['response' => $updateActualResponse]);

        if (!isset($updateActualResponse['result']) || !$updateActualResponse['result']) {
            Log::error("⚠️ POD updated but failed to update milestone", ['response' => $updateActualResponse]);
            return response()->json(['success' => false, 'message' => 'POD updated but milestone failed'], 500);
        }
                   
        $fcl_code_email = [
            'TYOT' => 'dispatch_manager.a2_email_notification_shipper_template',
            'TEOT' => 'dispatch_manager.a7_shipper_arrived_shiplocation_template',
            'TLOT' => 'dispatch_manager.a5_email_notification_laden_template',
            'CLOT' => 'dispatch_manager.a6_notification_container_outbound_template',
            'CYDT' => 'dispatch_manager.b4_container_vendor_yard_template',
            'GLDT' => 'dispatch_manager.a5_email_notification_laden_template',
            'CLDT' => 'dispatch_manager.c2_consignee_arrived_conslocation_template',
            'GYDT' => 'dispatch_manager.a2_email_notification_shipper_template',
        ];

        $template_xml_id = $fcl_code_email[$fcl_code] ?? null;

        if($template_xml_id) {
            Log::info("✅ Actual datetime successfully updated for milestone ID: $milestoneIdToUpdate");
            [$module, $xml_id] = explode('.', $template_xml_id, 2);
            $get_template_id = [
                "jsonrpc" => "2.0",
                "method" => "call",
                "params" => [
                    "service" => "object",
                    "method" => "execute_kw",
                    "args" => [
                        $db,
                        $uid,
                        $odooPassword,
                        "ir.model.data",
                        "search_read",
                        [
                            [["module", "=", $module], ["name", "=", $xml_id]],
                            ["res_id"]
                        ]
                        
                    ]
                ],
                "id" => 7
            ];
            $templateResponse = json_decode(file_get_contents($odooUrl, false, stream_context_create([
                "http" => [
                    "header" => "Content-Type: application/json",
                    "method" => "POST",
                    "content" => json_encode($get_template_id),
                ]
            ])), true);

            Log::debug("🔍 Template response", ['response' => $templateResponse]);

            $template_id = $templateResponse['result'] ?? [];

            if (!empty($template_id) && isset($template_id[0]['res_id'])) {
                $resolved_id = $template_id[0]['res_id'];
                Log::info("📩 Template ID resolved: $resolved_id for $template_xml_id");

                $send_email = [
                    "jsonrpc" => "2.0",
                    "method" => "call",
                    "params" => [
                        "service" => "object",
                        "method" => "execute_kw",
                        "args" => [
                            $db,
                            $uid,
                            $odooPassword,
                            "mail.template",
                            "send_mail",
                            [
                                $resolved_id,
                                $milestoneIdToUpdate,
                                true
                            ]
                        ]
                    ],
                    "id" => 8
                ];

                $sendEmailResponse = json_decode(file_get_contents($odooUrl, false, stream_context_create([
                    "http" => [
                        "header" => "Content-Type: application/json",
                        "method" => "POST",
                        "content" => json_encode($send_email),
                    ]
                ])), true);

                if(isset($sendEmailResponse['result']) && $sendEmailResponse['result']) {
                    Log::info("Milestone updated and email sent.");
                    return response()->json([
                        'success' => true,
                        'message' => 'Milestone updated and email sent successfully.',
                        'milestone_id' => $milestoneIdToUpdate,
                        'template_id' =>  $resolved_id,

                    ], 200);
                } else {
                    Log::warning("Milestone update, but email is not sent", ['response' => $sendEmailResponse]);
                    return response()->json(['success' => true, 'message' => 'Milestsone updated, but email failed'], 200);
                }
            } else {
                Log::error("Failed to resolve template XML ID $template_xml_id");
                return response()->json(['success' => false, 'message' => 'Template not found'], 500);
            }
            Log::info("Milestone updated!");
        } else {
            Log::warning("No template configured for FCL Code: $fcl_code");
            return response()->json(['success' => true, 'message' => 'Milestone updated but no email sent'], 200);
        }
    }

    
    private function resolveMilestoneCode($type, $requestNumber, $serviceType)
    {
        if ($type['dispatch_type'] == "ot" && $type['de_request_no'] == $requestNumber && $serviceType == 1) {
            return "TYOT";
        }
        if ($type['dispatch_type'] == "ot" && $type['pl_request_no'] == $requestNumber && $serviceType == 1) {
            return "TLOT";
        }
        if ($type['dispatch_type'] == "dt" && $type['dl_request_no'] == $requestNumber && $serviceType == 1) {
            return "GYDT";
        }
        if ($type['dispatch_type'] == "dt" && $type['pe_request_no'] == $requestNumber && $serviceType == 1) {
            return "GLDT";
        }
        if ($type['dispatch_type'] == "ot" && $type['pl_request_no'] == $requestNumber && $serviceType == 2) {
            return "LTEOT";
        }
        if ($type['dispatch_type'] == "dt" && $type['dl_request_no'] == $requestNumber && $serviceType == 2) {
            return "LGYDT";
        }
        return null;
    }

    private function resolveMilestoneCode2($type, $requestNumber, $serviceType)
    {
        if ($type['dispatch_type'] == "ot" && $type['de_request_no'] == $requestNumber && $serviceType == 1) {
            return "TEOT";
        }
        if ($type['dispatch_type'] == "ot" && $type['pl_request_no'] == $requestNumber && $serviceType == 1) {
            return "CLOT";
        }
        if ($type['dispatch_type'] == "dt" && $type['dl_request_no'] == $requestNumber && $serviceType == 1) {
            return "CLDT";
        }
        if ($type['dispatch_type'] == "dt" && $type['pe_request_no'] == $requestNumber && $serviceType == 1) {
            return "CYDT";
        }
        if ($type['dispatch_type'] == "ot" && $type['pl_request_no'] == $requestNumber && $serviceType == 2) {
            return "LCLOT";
        }
        if ($type['dispatch_type'] == "dt" && $type['dl_request_no'] == $requestNumber && $serviceType == 2) {
            return "LCLDT";
        }
        return null;
    }

    private function consolidationMaster($transactionId,$actualTime,$db,$uid,$odooPassword,$odooUrl,$bookingRef)
    {
        $notebookRes = jsonRpcRequest($odooUrl, [
            'jsonrpc' => '2.0',
            'method' => 'call',
            'params' => [
                'service' => 'object',
                'method' => 'execute_kw',
                'args' => [$db, $uid, $odooPassword, 'consol.type.notebook', 'search_read',
                    [[['consol_destination', '=', $transactionId]]],
                    ['fields' => ['id', 'consolidation_id', 'consol_origin','consol_destination']]
                ]
            ],
            'id' => rand(1000, 9999)
        ]);

        
        if (empty($notebookRes['result'])) {
            return; // no consolidation notebook found
        }

        $resultSummary = [];

        foreach ($notebookRes['result'] as $nb) {
            $raw = $nb['consolidation_id'] ?? null;
            if (!is_array($raw) || !isset($raw[0])) {
                // $conslMasterId = $raw[0];
                continue; // take the first valid consolidation
            }
            $consolMasterId = $raw[0];
            $consolOriginId = $nb['consol_origin'][0] ?? null;
            $consolDestinationId = $nb['consol_destination'][0] ?? null;

            if(!$consolMasterId) continue;

            if ($consolDestinationId) {
                $updateDestinationStage = jsonRpcRequest($odooUrl, [
                    'jsonrpc' => '2.0',
                    'method' => 'call',
                    'params' => [
                        'service' => 'object',
                        'method' => 'execute_kw',
                        'args' => [
                            $db, $uid, $odooPassword,
                            'dispatch.manager', 'write',
                            [[$consolDestinationId], ['stage_id' => 7, 'de_completion_time' => $actualTime]]
                        ]
                    ],
                    'id' => rand(1000, 9999)
                ]);

                Log::info("Backloaded destination forced to stage 7", [
                    'consolDestinationId' => $consolDestinationId,
                    'response' => $updateDestinationStage
                ]);

                // Continue with normal master/origin updates even if destination updated
            }
           
           
            $updateConsolMaster = jsonRpcRequest($odooUrl, [
                'jsonrpc' => '2.0',
                'method' => 'call',
                'params' => [
                    'service' => 'object',
                    'method' => 'execute_kw',
                    'args' => [$db, $uid, $odooPassword, 'pd.consol.master', 'write',
                        [[$consolMasterId], ['status' => 'execution']]
                    ]
                ],
                'id' => rand(1000, 9999)
            ]);

            Log::info("Consolidation master updated", ['consolMasterId' => $consolMasterId, 'response' => $updateConsolMaster]);
            $resultSummary['updateConsolMaster'] = $updateConsolMaster;

            if($consolOriginId) {
                $updateConsolOrigin = jsonRpcRequest($odooUrl, [
                    'jsonrpc' => '2.0',
                    'method' => 'call',
                    'params' => [
                        'service' => 'object',
                        'method' => 'execute_kw',
                        'args' => [$db, $uid, $odooPassword, 'dispatch.manager', 'write',
                            [[$consolOriginId], ['stage_id' => 5]]
                        ]
                    ],
                    'id' => rand(1000, 9999)
                ]);
                Log::info("Consolidation origin updated", ['consolOriginId' => $consolOriginId, 'response' => $updateConsolOrigin]);
                $resultSummary['updateConsolOrigin'] = $updateConsolOrigin;

                $searchBooking = jsonRpcRequest($odooUrl,[
                    "jsonrpc" => "2.0",
                    "method" => "call",
                    "params" => [
                        "service" => "object",
                        "method" => "execute_kw",
                        "args" => [
                            $db,
                            $uid,
                            $odooPassword,
                            "freight.management",
                            "search_read",
                            [[["booking_reference_no", '=', $bookingRef]]],
                            ["fields" => ["id", "stage_id"]]
                        ],
                    ],
                    "id" => rand(1000, 9999)
                ]);
               
                
                $bookingIds = $searchBooking['result'][0]['id'] ?? null;

                if ($bookingIds) {
                    $updateBookingStage =jsonRpcRequest($odooUrl, [
                        "jsonrpc" => "2.0",
                        "method" => "call",
                        "params" => [
                            "service" => "object",
                            "method" => "execute_kw",
                            "args" => [
                                $db,
                                $uid,
                                $odooPassword,
                                "freight.management",
                                "write",
                                [
                                    [$bookingIds],
                                    [
                                        "stage_id" => 6
                                    ]
                                ]
                            ]
                        ],
                        "id" => rand(1000, 9999)
                    ]);
                    $resultSummary['updateBookingStage'] = $updateBookingStage;
                    Log::info("Updated booking stage for bookingRef {$bookingRef}, bookingId: {$bookingIds}");
                
                } else {
                    Log::warning("No booking found for bookingRef {$bookingRef}");
                }

                $fclToUpdate = ['TYOT', 'TEOT'];

                $milestones = jsonRpcRequest($odooUrl, [
                    'jsonrpc' => '2.0',
                    'method' => 'call',
                    'params' => [
                        'service' => 'object',
                        'method' => 'execute_kw',
                        'args' => [$db, $uid, $odooPassword, 'dispatch.milestone.history', 'search_read',
                            [[['dispatch_id', '=', $consolOriginId], ['fcl_code', 'in', $fclToUpdate]]],
                            ['fields' => ['id','fcl_code']]
                        ]
                    ],
                    'id' => rand(1000, 9999)
                ]);
                foreach ($milestones['result'] as $ms) {
                    $updateMilestone = jsonRpcRequest($odooUrl, [
                        'jsonrpc' => '2.0',
                        'method' => 'call',
                        'params' => [
                            'service' => 'object',
                            'method' => 'execute_kw',
                            'args' => [$db, $uid, $odooPassword, 'dispatch.milestone.history', 'write',
                                [[$ms['id']], [
                                'actual_datetime' => $actualTime,
                                'button_readonly' => true,
                                'button_confirm_semd' => false,
                                'clicked_by' => (int) $uid
                            ]]
                            ]
                        ],
                        'id' => rand(1000, 9999)
                    ]);
                    Log::info("Consolidation origin milestone updated", ['consolOriginId' => $consolOriginId, 'milestoneId' => $ms['id'], 'fcl_code' => $fclToUpdate, 'response' => $updateMilestone]);
                    $resultSummary['milestone'][] = $updateMilestone;
                }
            }
        }

        
        return $resultSummary;
    }

    private function divertedConsol($transactionId,$actualTime,$db,$uid,$odooPassword,$odooUrl,$bookingRef)
    {
        $notebookRes = jsonRpcRequest($odooUrl, [
            'jsonrpc' => '2.0',
            'method' => 'call',
            'params' => [
                'service' => 'object',
                'method' => 'execute_kw',
                'args' => [$db, $uid, $odooPassword, 'consol.type.notebook', 'search_read',
                    [[['consol_destination', '=', $transactionId]]],
                    ['fields' => ['id', 'consolidation_id', 'consol_origin','consol_destination','type_consol']]
                ]
            ],
            'id' => rand(1000, 9999)
        ]);

        
        if (empty($notebookRes['result'])) {
            return; // no consolidation notebook found
        }

        $resultSummary = [];

        

        foreach ($notebookRes['result'] as $nb) {
            $consolMasterId = $nb['consolidation_id'][0] ?? null;
            $consolOriginId = $nb['consol_origin'][0] ?? null;
            $consolDestinationId = $nb['consol_destination'][0] ?? null;
            $consolType = $nb['type_consol'][0] ?? null;

            if (!$consolMasterId) continue;

            Log::info("Backloaded destination", [
                'consolDestinationId' => $consolDestinationId,
            ]);

            // Origin milestone update (CLDT/TEOT)
            if ($consolDestinationId && $consolType == 2) {
                $fclToUpdate = ['GLDT'];
                $milestones = jsonRpcRequest($odooUrl, [
                    'jsonrpc' => '2.0',
                    'method' => 'call',
                    'params' => [
                        'service' => 'object',
                        'method' => 'execute_kw',
                        'args' => [$db, $uid, $odooPassword, 'dispatch.milestone.history', 'search_read',
                            [[['dispatch_id', '=', $consolDestinationId], ['fcl_code', 'in', $fclToUpdate]]],
                            ['fields' => ['id','fcl_code']]
                        ]
                    ],
                    'id' => rand(1000, 9999)
                ]);

                foreach ($milestones['result'] as $ms) {
                    $updateMilestone = jsonRpcRequest($odooUrl, [
                        'jsonrpc' => '2.0',
                        'method' => 'call',
                        'params' => [
                            'service' => 'object',
                            'method' => 'execute_kw',
                            'args' => [$db, $uid, $odooPassword, 'dispatch.milestone.history', 'write',
                                [[$ms['id']], [
                                    'actual_datetime' => $actualTime,
                                    'button_readonly' => true,
                                    'button_confirm_semd' => false,
                                    'clicked_by' => (int) $uid
                                ]]
                            ]
                        ],
                        'id' => rand(1000, 9999)
                    ]);
                    Log::info("📝 Consolidation origin milestone updated", [
                        'consolOriginId' => $consolOriginId,
                        'milestoneId' => $ms['id'],
                        'fcl_code' => $ms['fcl_code'],
                        'response' => $updateMilestone
                    ]);

                    if ($ms['fcl_code'] === 'GLDT') {
                        $updateOrigin = jsonRpcRequest($odooUrl, [
                            'jsonrpc' => '2.0',
                            'method' => 'call',
                            'params' => [
                                'service' => 'object',
                                'method' => 'execute_kw',
                                'args' => [$db, $uid, $odooPassword, 'dispatch.manager', 'write',
                                    [[$consolOriginId], ['de_request_status' => 'Ongoing']] 
                                ]
                            ],
                            'id' => rand(1000, 9999)
                        ]);
                        Log::info("🔄 Consol origin set to ongoing due to GLDT milestone", [
                            'consolOriginId' => $consolOriginId,
                            'response' => $updateOrigin
                        ]);
                    }
                }

                 $searchDispatch = jsonRpcRequest($odooUrl, [
                    "jsonrpc" => "2.0",
                    "method" => "call",
                    "params" => [
                        "service" => "object",
                        "method" => "execute_kw",
                        "args" => [
                            $db,
                            $uid,
                            $odooPassword,
                            "dispatch.manager",
                            "search_read",
                            [[["id", '=', $transactionId]]],
                            ["fields" => ["id", "stage_id", "pe_completion_time","pe_request_status"]]
                        ]
                    ],
                    "id" => rand(1000, 9999)
                ]);

                $bookingId = $searchDispatch['result'][0]['id'] ?? null;
                if ($bookingId) {
                    $updateBookingStage = jsonRpcRequest($odooUrl, [
                        "jsonrpc" => "2.0",
                        "method" => "call",
                        "params" => [
                            "service" => "object",
                            "method" => "execute_kw",
                            "args" => [
                                $db,
                                $uid,
                                $odooPassword,
                                "dispatch.manager",
                                "write",
                                [[$bookingId], ["stage_id" => 7, "pe_completion_time" => $actualTime,"pe_request_status" => 'Completed']]
                            ]
                        ],
                        "id" => rand(1000, 9999)
                    ]);
                    Log::info("✅ Booking stage updated", ['bookingRef' => $bookingRef, 'bookingId' => $bookingId, 'response' => $updateBookingStage]);
                }
            }

         
        }
        return $resultSummary;
    }

    private function updateBookingStage1($bookingRef, $db, $uid, $odooPassword, $odooUrl)
    {
        if (!$bookingRef) return;

        $searchBooking = [
            "jsonrpc" => "2.0",
            "method" => "call",
            "params" => [
                "service" => "object",
                "method" => "execute_kw",
                "args" => [
                    $db,
                    $uid,
                    $odooPassword,
                    "freight.management",
                    "search_read",
                    [[["booking_reference_no", '=', $bookingRef]]],
                    ["fields" => ["id", "stage_id", "waybill_id"]]
                ],
            ],
            "id" => rand(1000, 9999)
        ];
        $searchResponse = json_decode(file_get_contents($odooUrl, false, stream_context_create([
            "http" => [
                "header" => "Content-Type: application/json",
                "method" => "POST",
                "content" => json_encode($searchBooking),
            ]
        ])), true);
        
        $bookingIds = $searchResponse['result'][0]['id'] ?? null;
        $waybillId = $searchResponse['result'][0]['waybill_id'] ?? null;

        if ($bookingIds) {
            if ($waybillId) {
                $updateBookingStage = [
                    "jsonrpc" => "2.0",
                    "method" => "call",
                    "params" => [
                        "service" => "object",
                        "method" => "execute_kw",
                        "args" => [
                            $db,
                            $uid,
                            $odooPassword,
                            "freight.management",
                            "write",
                            [
                                [$bookingIds],
                                [
                                    "stage_id" => 5
                                ]
                            ]
                        ]
                    ],
                    "id" => rand(1000, 9999)
                ];
                $response = json_decode(file_get_contents($odooUrl, false, stream_context_create([
                    "http" => [
                        "header" => "Content-Type: application/json",
                        "method" => "POST",
                        "content" => json_encode($updateBookingStage),
                    ]
                ])), true);

                Log::info("Updated booking stage for bookingRef {$bookingRef}, bookingId: {$bookingIds}");

                return $response;
            } else {
                Log::warning("No found for {$bookingRef} but no waybill");
            }
            
        } else {
            Log::warning("No booking found for bookingRef {$bookingRef}");
        }
    }

    private function updateBookingStage2($bookingRef, $db, $uid, $odooPassword, $odooUrl)
    {
        if (!$bookingRef) return;

        $searchBooking = [
            "jsonrpc" => "2.0",
            "method" => "call",
            "params" => [
                "service" => "object",
                "method" => "execute_kw",
                "args" => [
                    $db,
                    $uid,
                    $odooPassword,
                    "freight.management",
                    "search_read",
                    [[["booking_reference_no", '=', $bookingRef]]],
                    ["fields" => ["id", "stage_id"]]
                ],
            ],
            "id" => rand(1000, 9999)
        ];
        $searchResponse = json_decode(file_get_contents($odooUrl, false, stream_context_create([
            "http" => [
                "header" => "Content-Type: application/json",
                "method" => "POST",
                "content" => json_encode($searchBooking),
            ]
        ])), true);
        
        $bookingIds = $searchResponse['result'][0]['id'] ?? null;

        if ($bookingIds) {
            $updateBookingStage = [
                "jsonrpc" => "2.0",
                "method" => "call",
                "params" => [
                    "service" => "object",
                    "method" => "execute_kw",
                    "args" => [
                        $db,
                        $uid,
                        $odooPassword,
                        "freight.management",
                        "write",
                        [
                            [$bookingIds],
                            [
                                "stage_id" => 6
                            ]
                        ]
                    ]
                ],
                "id" => rand(1000, 9999)
            ];
            $response = json_decode(file_get_contents($odooUrl, false, stream_context_create([
                "http" => [
                    "header" => "Content-Type: application/json",
                    "method" => "POST",
                    "content" => json_encode($updateBookingStage),
                ]
            ])), true);

            Log::info("Updated booking stage for bookingRef {$bookingRef}, bookingId: {$bookingIds}");

            return $response;
           
        } else {
            Log::warning("No booking found for bookingRef {$bookingRef}");
        }
    }


    public function uploadPOD(Request $request)
    {
        $url = $this->url;
        $db = $this->db;
        $uid = $request->query('uid') ;
        $odooPassword = $request->header('password');
        $images = $request->input('images');
        $signature = $request->input('signature');
        $transactionId = (int)$request->input('id');
        $dispatchType = $request->input('dispatch_type');
        $requestNumber = $request->input('request_number');
        $actualTime = $request->input('timestamp');
        $enteredName = $request->input('enteredName');
        $newStatus = $request->input('newStatus');
        $containerNumber = $request->input('enteredContainerNumber');
        $odooUrl = $this->odoo_url;

        $type = $this->handleDispatchRequest($request);
        if ($type instanceof \Illuminate\Http\JsonResponse) return $type;

        $serviceType = is_array($type['service_type']) ? $type['service_type'][0] : $type['service_type'];
        $updateField = $this->buildUpdateField1($type, $requestNumber, $images, $signature, $enteredName, $actualTime, $containerNumber, $newStatus, $serviceType);

        if (empty($updateField)) {
            return response()->json(['success' => false, 'message' => 'No matching update rules found'], 400);
        }
        
        $updateResponse = $this->updateDispatchRecord($transactionId, $updateField, $db, $uid, $odooPassword, $odooUrl);

        if (!($updateResponse['result'] ?? false)) {
            Log::error("Failed to insert image", ["response" => $updateResponse]);
            return response()->json(['success' => false, 'message' => 'Failed to upload POD'], 500);
        }

        $this->updateFFContainerNumber($type, $containerNumber, $db, $uid, $odooPassword, $odooUrl);

        $bookingRef = $type['booking_reference_no'] ?? null; // needed by divertedConsol

        if($type['pe_request_no'] == $requestNumber) {
            $this->divertedConsol($transactionId, $actualTime, $db, $uid, $odooPassword, $odooUrl, $bookingRef);
        }
        
       
        $milestoneResult = $this->getMilestoneHistory($transactionId, $db, $uid, $odooPassword, $odooUrl);
        if ($milestoneResult instanceof \Illuminate\Http\JsonResponse) return $milestoneResult;

        $milestoneCodeToUpdate = $this->resolveMilestoneCode($type, $requestNumber, $serviceType);  

        if(in_array($milestoneCodeToUpdate, ['TYOT', 'LCLOT'])) {
            $bookingRef = $type['booking_reference_no'] ?? null;
            if($bookingRef) {
                $this->updateBookingStage1($bookingRef, $db, $uid, $odooPassword, $odooUrl);
            }
        }

        if($milestoneCodeToUpdate === 'TLOT'){
            $notebookRes = jsonRpcRequest($odooUrl, [
                'jsonrpc' => '2.0',
                'method' => 'call',
                'params' => [
                    'service' => 'object',
                    'method' => 'execute_kw',
                    'args' => [$db, $uid, $odooPassword, 'consol.type.notebook', 'search_read',
                        [[['consol_origin', '=', $transactionId]]],
                        ['fields' => ['id', 'consolidation_id', 'consol_origin']]
                    ]
                ],
                'id' => rand(1000, 9999)
            ]);

            if (!empty($notebookRes['result'])) {
                foreach ($notebookRes['result'] as $nb) {
                    $consolMaster = $nb['consolidation_id'] ?? null;
                    $consolMasterId = is_array($consolMaster) && isset($consolMaster[0]) ? $consolMaster[0] : null;

                    if ($consolMasterId) {
                        $updateConsolMaster = jsonRpcRequest($odooUrl, [
                            'jsonrpc' => '2.0',
                            'method' => 'call',
                            'params' => [
                                'service' => 'object',
                                'method' => 'execute_kw',
                                'args' => [$db, $uid, $odooPassword, 'pd.consol.master', 'write',
                                    [[$consolMasterId], ['status' => 'completed']]
                                ]
                            ],
                            'id' => rand(1000, 9999)
                        ]);

                        Log::info("✅ Consolidation master updated", [
                            'consolMasterId' => $consolMasterId,
                            'response' => $updateConsolMaster
                        ]);
                    } else {
                        Log::warning("⚠ consolidation_id missing in notebook record", ['notebook' => $nb]);
                    }
                }
            }else{
                Log::warning("No consolidation notebook for transactio {$transactionId}");
            }
        }
        if ($milestoneCodeToUpdate) {
            return $this->updateMilestoneAndSendEmail(
                $milestoneResult,   // ✅ use the same variable
                $milestoneCodeToUpdate,
                $actualTime,
                $db,
                $uid,
                $odooPassword,
                $odooUrl
            );
        }
        return response()->json(['success' => true, 'message' => 'POD uploaded, but no matching milestone found']);

    }



    public function uploadPOD_sec(Request $request)
    {
        $url = $this->url;
        $db = $this->db;
        $uid = $request->query('uid') ;
        $odooPassword = $request->header('password');
        $images = $request->input('images');
        $signature = $request->input('signature');
        $transactionId = (int)$request->input('id');
        $dispatchType = $request->input('dispatch_type');
        $requestNumber = $request->input('request_number');
        $actualTime = $request->input('timestamp');
        $enteredName = $request->input('enteredName');
        $newStatus = $request->input('newStatus');
        $containerNumber = $request->input('enteredContainerNumber');
        $odooUrl = $this->odoo_url;

        $type = $this->handleDispatchRequest($request);
        if ($type instanceof \Illuminate\Http\JsonResponse) return $type;

        $serviceType = is_array($type['service_type']) ? $type['service_type'][0] : $type['service_type'];
        $updateField = $this->buildUpdateField2($type, $requestNumber, $images, $signature, $enteredName, $actualTime, $containerNumber, $newStatus, $serviceType);

        if (empty($updateField)) {
            return response()->json(['success' => false, 'message' => 'No matching update rules found'], 400);
        }
        
        $updateResponse = $this->updateDispatchRecord($transactionId, $updateField, $db, $uid, $odooPassword, $odooUrl);

        if (!($updateResponse['result'] ?? false)) {
            Log::error("Failed to insert image", ["response" => $updateResponse]);
            return response()->json(['success' => false, 'message' => 'Failed to upload POD'], 500);
        }

        $bookingRef = $type['booking_reference_no'] ?? null;

        $this->updateFFContainerNumber($type, $containerNumber, $db, $uid, $odooPassword, $odooUrl);

        $this->consolidationMaster($transactionId,$actualTime,$db,$uid,$odooPassword,$odooUrl, $bookingRef);
       
        $milestoneResult = $this->getMilestoneHistory($transactionId, $db, $uid, $odooPassword, $odooUrl);
        if ($milestoneResult instanceof \Illuminate\Http\JsonResponse) return $milestoneResult;

        $milestoneCodeToUpdate = $this->resolveMilestoneCode2($type, $requestNumber, $serviceType);  
        if(in_array($milestoneCodeToUpdate, ['CYDT', 'LCLDT'])) {
            $bookingRef = $type['booking_reference_no'] ?? null;
            if($bookingRef) {
                $this->updateBookingStage2($bookingRef, $db, $uid, $odooPassword, $odooUrl);
            }
        }

        if ($milestoneCodeToUpdate) {
            return $this->updateMilestoneAndSendEmail(
                $milestoneResult,   // ✅ use the same variable
                $milestoneCodeToUpdate,
                $actualTime,
                $db,
                $uid,
                $odooPassword,
                $odooUrl
            );
        }
        return response()->json(['success' => true, 'message' => 'POD uploaded, but no matching milestone found']);
    }

}