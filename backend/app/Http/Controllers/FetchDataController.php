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



class FetchDataController extends Controller
{
    protected $url = "https://jralejandria-alpha-dev-yxe.odoo.com";
    protected $db = 'jralejandria-alpha-dev-yxe-production-alpha-24065126';
    // protected $odoo_url = "http://192.168.76.205:8080/odoo/jsonrpc";
    protected $odoo_url = "https://jralejandria-alpha-dev-yxe.odoo.com/jsonrpc";

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
            "consignee_province","consignee_city","consignee_barangay","consignee_street", "foas_datetime", "service_type", "booking_service", "pl_proof_filename", 
            "de_assignation_time", "pl_assignation_time", "dl_assignation_time", "pe_assignation_time", "name", "stage_id", "pe_release_by", "de_release_by","pl_receive_by","dl_receive_by",
            "pl_proof_stock", "pl_proof_filename_stock","dl_hwb_signed","dl_hwb_signed_filename", "dl_delivery_receipt", "dl_delivery_receipt_filename","dl_packing_list", "dl_packing_list_filename",
            "dl_delivery_note","dl_delivery_note_filename","dl_stock_delivery_receipt","dl_stock_delivery_receipt_filename","dl_sales_invoice","dl_sales_invoice_filename", "dl_proof_filename",
            "pe_proof_filename","de_proof_filename",
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
            "consignee_province","consignee_city","consignee_barangay","consignee_street", "foas_datetime",  "service_type","booking_service","pl_proof_filename", 
            "de_assignation_time", "pl_assignation_time", "dl_assignation_time", "pe_assignation_time","stage_id", "pe_release_by", "de_release_by","pl_receive_by","dl_receive_by",
            "pl_proof_stock", "pl_proof_filename_stock","dl_hwb_signed","dl_hwb_signed_filename", "dl_delivery_receipt", "dl_delivery_receipt_filename","dl_packing_list", "dl_packing_list_filename",
            "dl_delivery_note","dl_delivery_note_filename","dl_stock_delivery_receipt","dl_stock_delivery_receipt_filename","dl_sales_invoice","dl_sales_invoice_filename","dl_proof_filename",
            "pe_proof_filename","de_proof_filename",
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

        // foreach($filtered as $manager) {
        //     jsonRpcRequest($jobUrl, [
        //         'jsonrpc' => '2.0',
        //         'method' => 'call',
        //         'params' => [
        //             'model' => 'dispatch.manager',
        //             'id' => $manager['id'],
        //             'method' => 'run_laravel_job',
        //         ],
        //         'id' => rand(1000, 9999)
        //     ]);
        // }
            

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
                        ['fields' => ['id', 'consolidation_id','consol_origin', 'consol_destination','type_consol']]
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
                    $consolType = $nb['type_consol'] ?? null;
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
                            ['fields' => ['id', 'name', 'consolidated_date', 'is_backload', 'is_diverted','status']]
                        ]
                    ],
                    'id' => rand(1000, 9999)
                ]);

                $consolidationData = $masterRes['result'][0] ?? null;
                if ($consolidationData) {
                    $consolidationData['consolidated_date'] = is_string($consolidationData['consolidated_date']) ? $consolidationData['consolidated_date'] : '';
                    $consolidationData['consol_origin'] = $consolOriginId;
                    $consolidationData['consol_destination'] = $consolDestinationId;
                    $consolidationData['type_consol'] = $consolType;
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

        // \Log::info("Booking Refs collected:", $bookingRefs);

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
                'transactions' => $data,
                
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

        // \Log::info("Booking Refs collected:", $bookingRefs);

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
}