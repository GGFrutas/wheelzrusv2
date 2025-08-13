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
            ]
        ]);
        
        $response = $client->post($url, [
            'body' => json_encode($payload)
        ]);

        return json_decode($response->getBody(), true );

    } catch (\Exception $e) {
        Log::error('X JSON_RPC Request Failed', [
            'url' => $url,
            'payload' => $payload,
            'error' => $e->getMessage(),
        ]);
        return [];
    }
}

class TransactionController extends Controller
{
    protected $url = "https://jralejandria-beta-dev-yxe.odoo.com";
    protected $db = 'jralejandria-beta-dev-yxe-production-beta-22570487';
    // protected $odoo_url = "http://192.168.118.102:8000/odoo/jsonrpc";
    protected $odoo_url = "https://jralejandria-beta-dev-yxe.odoo.com/jsonrpc";

   

    public function getTodayBooking(Request $request)
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
                'args' => [$db, $login, $odooPassword],
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

        $today = date('Y-m-d');
        $tomorrow = date('Y-m-d', strtotime('+1 day'));
        // Step 4: Find all dispatch.manager records where driver name matches
        $dispatchRes =jsonRpcRequest("$odooUrl", [
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
                    'search_read',
                    [[
                        "&",  // AND all of the following
                            ["dispatch_type", "!=", "ff"],

                            "|",  // OR: date range match
                                "&", 
                                    [ "arrival_date", ">=", $today ],
                                    [ "arrival_date", "<=", $tomorrow ],
                                "&", 
                                    [ "departure_date", ">=", $today ],
                                    [ "departure_date", "<=", $tomorrow ],

                            "|", "|", "|",  // OR: driver match
                                ["de_truck_driver_name", "=", $partnerId],
                                ["dl_truck_driver_name", "=", $partnerId],
                                ["pe_truck_driver_name", "=", $partnerId],
                                ["pl_truck_driver_name", "=", $partnerId],

                         
                    ]],

                    ["fields" => [
                        "id", "de_request_status", "pl_request_status", "dl_request_status", "pe_request_status",
                        "dispatch_type", "de_truck_driver_name", "dl_truck_driver_name", "pe_truck_driver_name", "pl_truck_driver_name",
                        "de_request_no", "pl_request_no", "dl_request_no", "pe_request_no", "origin_port_terminal_address", "destination_port_terminal_address", "arrival_date", "delivery_date",
                        "container_number", "seal_number", "booking_reference_no", "origin_forwarder_name", "destination_forwarder_name", "freight_booking_number",
                        "origin_container_location", "freight_bl_number", "de_proof", "de_signature", "pl_proof", "pl_signature", "dl_proof", "dl_signature", "pe_proof", "pe_signature",
                        "freight_forwarder_name", "shipper_phone", "consignee_phone", "dl_truck_plate_no", "pe_truck_plate_no", "de_truck_plate_no", "pl_truck_plate_no",
                        "de_truck_type", "dl_truck_type", "pe_truck_type", "pl_truck_type", "shipper_id", "consignee_id", "shipper_contact_id", "consignee_contact_id", "vehicle_name",
                        "pickup_date", "departure_date","origin", "destination", "de_rejection_time", "pl_rejection_time", "dl_rejection_time", "pe_rejection_time", "de_completion_time", 
                        "pl_completion_time", "dl_completion_time", "pe_completion_time", "shipper_province","shipper_city","shipper_barangay","shipper_street", 
                        "consignee_province","consignee_city","consignee_barangay","consignee_street", "foas_datetime", "service_type", "booking_service",
                        "de_assignation_time", "pl_assignation_time", "dl_assignation_time", "pe_assignation_time", "name", "stage_id"
                    ]],
                ]
            ],
            'id' => 4
        ]);

        $dispatchManagers = $dispatchRes['result'] ?? [];

        if (empty($dispatchManagers)) {
            Log::warning("❌ No dispatch.manager records found for driver $partnerName");
            // return response()->json(['success' => false, 'message' => 'No dispatch manager records found'], 404);
        }

        $filteredManagers = array_filter($dispatchManagers, function ($manager) use ($partnerName) {
            foreach (["de_truck_driver_name", "dl_truck_driver_name", "pe_truck_driver_name", "pl_truck_driver_name"] as $field) {
                if (
                    isset($manager[$field][1]) && $manager[$field][1] == $partnerName
                ) {
                    return true;
                }
            }
            return false;
        });

        $filteredManagers = array_values($filteredManagers);

        // Step 5: Queue a job for each dispatch.manager record
        $fieldsToString = [
            "de_request_status", "pl_request_status", "dl_request_status", "pe_request_status",
            "dispatch_type", 
            "de_request_no", "pl_request_no", "dl_request_no", "pe_request_no", "origin_port_terminal_address", "destination_port_terminal_address", "arrival_date", "delivery_date",
            "container_number", "seal_number", "booking_reference_no", "origin_forwarder_name", "destination_forwarder_name", "freight_booking_number",
            "origin_container_location", "freight_bl_number", "de_proof", "de_signature", "pl_proof", "pl_signature", "dl_proof", "dl_signature", "pe_proof", "pe_signature",
            "freight_forwarder_name", "shipper_phone", "consignee_phone", "dl_truck_plate_no", "pe_truck_plate_no", "de_truck_plate_no", "pl_truck_plate_no",
            "de_truck_type", "dl_truck_type", "pe_truck_type", "pl_truck_type", "shipper_id", "consignee_id", "shipper_contact_id", "consignee_contact_id", "vehicle_name",
            "pickup_date", "departure_date","origin", "destination","de_rejection_time", "pl_rejection_time", "dl_rejection_time", "pe_rejection_time", "de_completion_time", 
            "pl_completion_time", "dl_completion_time", "pe_completion_time","shipper_province","shipper_city","shipper_barangay","shipper_street",
            "consignee_province","consignee_city","consignee_barangay","consignee_street", "foas_datetime",  "service_type","booking_service",
            "de_assignation_time", "pl_assignation_time", "dl_assignation_time", "pe_assignation_time","stage_id"
        ];

        $jobResponses = [];

        foreach ($filteredManagers  as $manager) {

            foreach ($fieldsToString as $field){
                if (!isset($manager[$field]) || $manager[$field] === null || $manager[$field] === false) {
                    $manager[$field] = "";
                } elseif (is_array($manager[$field]) && count($manager[$field]) > 1 && is_string($manager[$field][1])) {
                    $manager[$field] = $manager[$field][1]; // ✅ convert [id, name] to name
                } elseif (is_bool($manager[$field])) {
                    $manager[$field] = $manager[$field] ? "true" : "false";
                } else {
                    $manager[$field] = (string) $manager[$field];
                }
            }

            $jobRes = jsonRpcRequest("$url/job_dispatcher/queue_job", [
                'jsonrpc' => '2.0',
                'method' => 'call',
                'params' => [
                    'model' => 'dispatch.manager',
                    'id' => $manager['id'],
                    'method' => 'run_laravel_job',
                ],
                'id' => 5
            ]);

              $dispatchId = $manager['id'];

            

            $historyRes = jsonRpcRequest("$odooUrl", [
                'jsonrpc' => '2.0',
                'method' => 'call',
                'params' => [
                    'service' => 'object',
                    'method' => 'execute_kw',
                    'args' => [
                        $db,
                        $uid,
                        $odooPassword,
                        'dispatch.milestone.history',
                        'search_read',
                        [[[

                            'dispatch_id','=', $dispatchId
                            
                        ]]],
                        ["fields" => [
                            "id", "dispatch_id", "dispatch_type", "fcl_code", "scheduled_datetime","service_type"
                        ]],
                    ]
                ],
                'id' => 6
            ]);

            $dispatchHistory = is_array($historyRes['result']) ? $historyRes['result'] : [];
            $manager['history'] = $dispatchHistory;


            

            $jobResponses[] = $manager;
        }

        // ✅ Final return
        return response()->json([
            'data' => [
                'transactions' => $jobResponses
            ]
        ]);
    }
    public function getOngoingBooking(Request $request)
    {
        $url = $this->url;
        $db = $this->db;

        $page = (int) request()->query('page', 1);
        $limit = (int) request()->query('limit', 10);
        $offset = ($page - 1) * $limit;
      
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
                'args' => [$db, $login, $odooPassword],
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

        $today = date('Y-m-d');
        $tomorrow = date('Y-m-d', strtotime('+1 day'));
        // Step 4: Find all dispatch.manager records where driver name matches
        $dispatchRes =jsonRpcRequest("$odooUrl", [
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
                    'search_read',
                    [[
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
                    ]],

                    ["fields" => [
                        "id", "de_request_status", "pl_request_status", "dl_request_status", "pe_request_status",
                        "dispatch_type", "de_truck_driver_name", "dl_truck_driver_name", "pe_truck_driver_name", "pl_truck_driver_name",
                        "de_request_no", "pl_request_no", "dl_request_no", "pe_request_no", "origin_port_terminal_address", "destination_port_terminal_address", "arrival_date", "delivery_date",
                        "container_number", "seal_number", "booking_reference_no", "origin_forwarder_name", "destination_forwarder_name", "freight_booking_number",
                        "origin_container_location", "freight_bl_number", "de_proof", "de_signature", "pl_proof", "pl_signature", "dl_proof", "dl_signature", "pe_proof", "pe_signature",
                        "freight_forwarder_name", "shipper_phone", "consignee_phone", "dl_truck_plate_no", "pe_truck_plate_no", "de_truck_plate_no", "pl_truck_plate_no",
                        "de_truck_type", "dl_truck_type", "pe_truck_type", "pl_truck_type", "shipper_id", "consignee_id", "shipper_contact_id", "consignee_contact_id", "vehicle_name",
                        "pickup_date", "departure_date","origin", "destination", "de_rejection_time", "pl_rejection_time", "dl_rejection_time", "pe_rejection_time", "de_completion_time", 
                        "pl_completion_time", "dl_completion_time", "pe_completion_time", "shipper_province","shipper_city","shipper_barangay","shipper_street", 
                        "consignee_province","consignee_city","consignee_barangay","consignee_street", "foas_datetime", "service_type", "booking_service",
                        "de_assignation_time", "pl_assignation_time", "dl_assignation_time", "pe_assignation_time", "name"
                    ]],
                ]
            ],
            'id' => 4
        ]);

        $dispatchManagers = $dispatchRes['result'] ?? [];

        if (empty($dispatchManagers)) {
            Log::warning("❌ No dispatch.manager records found for driver $partnerName");
            // return response()->json(['success' => false, 'message' => 'No dispatch manager records found'], 404);
        }

        $filteredManagers = array_filter($dispatchManagers, function ($manager) use ($partnerName) {
            foreach (["de_truck_driver_name", "dl_truck_driver_name", "pe_truck_driver_name", "pl_truck_driver_name"] as $field) {
                if (
                    isset($manager[$field][1]) && $manager[$field][1] == $partnerName
                ) {
                    return true;
                }
            }
            return false;
        });

        $filteredManagers = array_values($filteredManagers);

        // Step 5: Queue a job for each dispatch.manager record
        $fieldsToString = [
            "de_request_status", "pl_request_status", "dl_request_status", "pe_request_status",
            "dispatch_type", 
            "de_request_no", "pl_request_no", "dl_request_no", "pe_request_no", "origin_port_terminal_address", "destination_port_terminal_address", "arrival_date", "delivery_date",
            "container_number", "seal_number", "booking_reference_no", "origin_forwarder_name", "destination_forwarder_name", "freight_booking_number",
            "origin_container_location", "freight_bl_number", "de_proof", "de_signature", "pl_proof", "pl_signature", "dl_proof", "dl_signature", "pe_proof", "pe_signature",
            "freight_forwarder_name", "shipper_phone", "consignee_phone", "dl_truck_plate_no", "pe_truck_plate_no", "de_truck_plate_no", "pl_truck_plate_no",
            "de_truck_type", "dl_truck_type", "pe_truck_type", "pl_truck_type", "shipper_id", "consignee_id", "shipper_contact_id", "consignee_contact_id", "vehicle_name",
            "pickup_date", "departure_date","origin", "destination","de_rejection_time", "pl_rejection_time", "dl_rejection_time", "pe_rejection_time", "de_completion_time", 
            "pl_completion_time", "dl_completion_time", "pe_completion_time","shipper_province","shipper_city","shipper_barangay","shipper_street",
            "consignee_province","consignee_city","consignee_barangay","consignee_street", "foas_datetime",  "service_type","booking_service",
            "de_assignation_time", "pl_assignation_time", "dl_assignation_time", "pe_assignation_time"
        ];

        $jobResponses = [];

        foreach ($filteredManagers  as $manager) {

            foreach ($fieldsToString as $field){
                if (!isset($manager[$field]) || $manager[$field] === null || $manager[$field] === false) {
                    $manager[$field] = "";
                } elseif (is_array($manager[$field]) && count($manager[$field]) > 1 && is_string($manager[$field][1])) {
                    $manager[$field] = $manager[$field][1]; // ✅ convert [id, name] to name
                } elseif (is_bool($manager[$field])) {
                    $manager[$field] = $manager[$field] ? "true" : "false";
                } else {
                    $manager[$field] = (string) $manager[$field];
                }
            }

            $jobRes = jsonRpcRequest("$url/job_dispatcher/queue_job", [
                'jsonrpc' => '2.0',
                'method' => 'call',
                'params' => [
                    'model' => 'dispatch.manager',
                    'id' => $manager['id'],
                    'method' => 'run_laravel_job',
                ],
                'id' => 5
            ]);

              $dispatchId = $manager['id'];

            

            $historyRes = jsonRpcRequest("$odooUrl", [
                'jsonrpc' => '2.0',
                'method' => 'call',
                'params' => [
                    'service' => 'object',
                    'method' => 'execute_kw',
                    'args' => [
                        $db,
                        $uid,
                        $odooPassword,
                        'dispatch.milestone.history',
                        'search_read',
                        [[[

                            'dispatch_id','=', $dispatchId
                            
                        ]]],
                        ["fields" => [
                            "id", "dispatch_id", "dispatch_type", "fcl_code", "scheduled_datetime","service_type"
                        ]],
                    ]
                ],
                'id' => 6
            ]);

            $dispatchHistory = is_array($historyRes['result']) ? $historyRes['result'] : [];
            $manager['history'] = $dispatchHistory;


            

            $jobResponses[] = $manager;

            
        }
        $totalCount = count($jobResponses);
        $totalPages = ceil($totalCount / $limit);
        $hasMore = $page < $totalPages;

        $pageResponse = array_slice($jobResponses, $offset, $limit);

        // ✅ Final return
        return response()->json([
            'data' => [
                'transactions' => $jobResponses,
                'pagination' => [
                    'current_page' => $page,
                    'per_page' => $limit,
                    'total_count' => $totalCount,
                    'total_pages' => ceil($totalCount / $limit),
                    'has_more' => ($offset + $limit) < $totalCount
                ]
            ]
        ]);
    }

    public function getHistoryBooking(Request $request)
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
                'args' => [$db, $login, $odooPassword],
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

        $today = date('Y-m-d');
        $tomorrow = date('Y-m-d', strtotime('+1 day'));
        // Step 4: Find all dispatch.manager records where driver name matches
        $dispatchRes =jsonRpcRequest("$odooUrl", [
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
                    'search_read',
                    [[
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

                            // Group 2: Rejected statuses
                            "|", ["stage_id", "=", 6], ["stage_id", "=", 7],

                            "|", "|", "|",  // OR: driver match
                                ["de_truck_driver_name", "=", $partnerId],
                                ["dl_truck_driver_name", "=", $partnerId],
                                ["pe_truck_driver_name", "=", $partnerId],
                                ["pl_truck_driver_name", "=", $partnerId]
                    ]],

                    ["fields" => [
                        "id", "de_request_status", "pl_request_status", "dl_request_status", "pe_request_status",
                        "dispatch_type", "de_truck_driver_name", "dl_truck_driver_name", "pe_truck_driver_name", "pl_truck_driver_name",
                        "de_request_no", "pl_request_no", "dl_request_no", "pe_request_no", "origin_port_terminal_address", "destination_port_terminal_address", "arrival_date", "delivery_date",
                        "container_number", "seal_number", "booking_reference_no", "origin_forwarder_name", "destination_forwarder_name", "freight_booking_number",
                        "origin_container_location", "freight_bl_number", "de_proof", "de_signature", "pl_proof", "pl_signature", "dl_proof", "dl_signature", "pe_proof", "pe_signature",
                        "freight_forwarder_name", "shipper_phone", "consignee_phone", "dl_truck_plate_no", "pe_truck_plate_no", "de_truck_plate_no", "pl_truck_plate_no",
                        "de_truck_type", "dl_truck_type", "pe_truck_type", "pl_truck_type", "shipper_id", "consignee_id", "shipper_contact_id", "consignee_contact_id", "vehicle_name",
                        "pickup_date", "departure_date","origin", "destination", "de_rejection_time", "pl_rejection_time", "dl_rejection_time", "pe_rejection_time", "de_completion_time", 
                        "pl_completion_time", "dl_completion_time", "pe_completion_time", "shipper_province","shipper_city","shipper_barangay","shipper_street", 
                        "consignee_province","consignee_city","consignee_barangay","consignee_street", "foas_datetime", "service_type", "booking_service",
                        "de_assignation_time", "pl_assignation_time", "dl_assignation_time", "pe_assignation_time", "stage_id", "write_date", "name", "pe_release_by", "de_release_by",
                        "dl_receive_by", "pl_receive_by"
                    ]],
                ]
            ],
            'id' => 4
        ]);

        $dispatchManagers = $dispatchRes['result'] ?? [];

        if (empty($dispatchManagers)) {
            Log::warning("❌ No dispatch.manager records found for driver $partnerName");
            // return response()->json(['success' => false, 'message' => 'No dispatch manager records found'], 404);
        }

        $filteredManagers = array_filter($dispatchManagers, function ($manager) use ($partnerName) {
            foreach (["de_truck_driver_name", "dl_truck_driver_name", "pe_truck_driver_name", "pl_truck_driver_name"] as $field) {
                if (
                    isset($manager[$field][1]) && $manager[$field][1] == $partnerName
                ) {
                    return true;
                }
            }
            return false;
        });

        $filteredManagers = array_values($filteredManagers);

        // Step 5: Queue a job for each dispatch.manager record
        $fieldsToString = [
            "de_request_status", "pl_request_status", "dl_request_status", "pe_request_status",
            "dispatch_type", 
            "de_request_no", "pl_request_no", "dl_request_no", "pe_request_no", "origin_port_terminal_address", "destination_port_terminal_address", "arrival_date", "delivery_date",
            "container_number", "seal_number", "booking_reference_no", "origin_forwarder_name", "destination_forwarder_name", "freight_booking_number",
            "origin_container_location", "freight_bl_number", "de_proof", "de_signature", "pl_proof", "pl_signature", "dl_proof", "dl_signature", "pe_proof", "pe_signature",
            "freight_forwarder_name", "shipper_phone", "consignee_phone", "dl_truck_plate_no", "pe_truck_plate_no", "de_truck_plate_no", "pl_truck_plate_no",
            "de_truck_type", "dl_truck_type", "pe_truck_type", "pl_truck_type", "shipper_id", "consignee_id", "shipper_contact_id", "consignee_contact_id", "vehicle_name",
            "pickup_date", "departure_date","origin", "destination","de_rejection_time", "pl_rejection_time", "dl_rejection_time", "pe_rejection_time", "de_completion_time", 
            "pl_completion_time", "dl_completion_time", "pe_completion_time","shipper_province","shipper_city","shipper_barangay","shipper_street",
            "consignee_province","consignee_city","consignee_barangay","consignee_street", "foas_datetime",  "service_type","booking_service",
            "de_assignation_time", "pl_assignation_time", "dl_assignation_time", "pe_assignation_time","stage_id", "write_date",
        ];

        $jobResponses = [];

        foreach ($filteredManagers  as $manager) {

            foreach ($fieldsToString as $field){
                if (!isset($manager[$field]) || $manager[$field] === null || $manager[$field] === false) {
                    $manager[$field] = "";
                } elseif (is_array($manager[$field]) && count($manager[$field]) > 1 && is_string($manager[$field][1])) {
                    $manager[$field] = $manager[$field][1]; // ✅ convert [id, name] to name
                } elseif (is_bool($manager[$field])) {
                    $manager[$field] = $manager[$field] ? "true" : "false";
                } else {
                    $manager[$field] = (string) $manager[$field];
                }
            }

            $jobRes = jsonRpcRequest("$url/job_dispatcher/queue_job", [
                'jsonrpc' => '2.0',
                'method' => 'call',
                'params' => [
                    'model' => 'dispatch.manager',
                    'id' => $manager['id'],
                    'method' => 'run_laravel_job',
                ],
                'id' => 5
            ]);

              $dispatchId = $manager['id'];

            

            $historyRes = jsonRpcRequest("$odooUrl", [
                'jsonrpc' => '2.0',
                'method' => 'call',
                'params' => [
                    'service' => 'object',
                    'method' => 'execute_kw',
                    'args' => [
                        $db,
                        $uid,
                        $odooPassword,
                        'dispatch.milestone.history',
                        'search_read',
                        [[[

                            'dispatch_id','=', $dispatchId
                            
                        ]]],
                        ["fields" => [
                            "id", "dispatch_id", "dispatch_type", "fcl_code", "scheduled_datetime","actual_datetime","service_type"
                        ]],
                    ]
                ],
                'id' => 6
            ]);

            $dispatchHistory = is_array($historyRes['result']) ? $historyRes['result'] : [];
            $manager['history'] = $dispatchHistory;


            

            $jobResponses[] = $manager;
        }

        // ✅ Final return
        return response()->json([
            'data' => [
                'transactions' => $jobResponses
            ]
        ]);
    }

    public function getAllHistory(Request $request)
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
                'args' => [$db, $login, $odooPassword],
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

        $today = date('Y-m-d');
        $tomorrow = date('Y-m-d', strtotime('+1 day'));
        // Step 4: Find all dispatch.manager records where driver name matches
        $dispatchRes =jsonRpcRequest("$odooUrl", [
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
                    'search_read',
                    [[
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

                            // Group 2: Rejected statuses
                            "|", ["stage_id", "=", 6], ["stage_id", "=", 7],

                            "|", "|", "|",  // OR: driver match
                                ["de_truck_driver_name", "=", $partnerId],
                                ["dl_truck_driver_name", "=", $partnerId],
                                ["pe_truck_driver_name", "=", $partnerId],
                                ["pl_truck_driver_name", "=", $partnerId]
                    ]],

                    ["fields" => [
                        "id", "de_request_status", "pl_request_status", "dl_request_status", "pe_request_status",
                        "dispatch_type", "de_truck_driver_name", "dl_truck_driver_name", "pe_truck_driver_name", "pl_truck_driver_name",
                        "de_request_no", "pl_request_no", "dl_request_no", "pe_request_no", "origin_port_terminal_address", "destination_port_terminal_address", "arrival_date", "delivery_date",
                        "container_number", "seal_number", "booking_reference_no", "origin_forwarder_name", "destination_forwarder_name", "freight_booking_number",
                        "origin_container_location", "freight_bl_number", "de_proof", "de_signature", "pl_proof", "pl_signature", "dl_proof", "dl_signature", "pe_proof", "pe_signature",
                        "freight_forwarder_name", "shipper_phone", "consignee_phone", "dl_truck_plate_no", "pe_truck_plate_no", "de_truck_plate_no", "pl_truck_plate_no",
                        "de_truck_type", "dl_truck_type", "pe_truck_type", "pl_truck_type", "shipper_id", "consignee_id", "shipper_contact_id", "consignee_contact_id", "vehicle_name",
                        "pickup_date", "departure_date","origin", "destination", "de_rejection_time", "pl_rejection_time", "dl_rejection_time", "pe_rejection_time", "de_completion_time", 
                        "pl_completion_time", "dl_completion_time", "pe_completion_time", "shipper_province","shipper_city","shipper_barangay","shipper_street", 
                        "consignee_province","consignee_city","consignee_barangay","consignee_street", "foas_datetime", "service_type", "booking_service",
                        "de_assignation_time", "pl_assignation_time", "dl_assignation_time", "pe_assignation_time", "stage_id", "write_date", "name", "pe_release_by", "de_release_by",
                        "dl_receive_by", "pl_receive_by"


                    ]],
                ]
            ],
            'id' => 4
        ]);

        $dispatchManagers = $dispatchRes['result'] ?? [];

        if (empty($dispatchManagers)) {
            Log::warning("❌ No dispatch.manager records found for driver $partnerName");
            // return response()->json(['success' => false, 'message' => 'No dispatch manager records found'], 404);
        }

        $filteredManagers = array_filter($dispatchManagers, function ($manager) use ($partnerName) {
            foreach (["de_truck_driver_name", "dl_truck_driver_name", "pe_truck_driver_name", "pl_truck_driver_name"] as $field) {
                if (
                    isset($manager[$field][1]) && $manager[$field][1] == $partnerName
                ) {
                    return true;
                }
            }
            return false;
        });

        $filteredManagers = array_values($filteredManagers);

        // Step 5: Queue a job for each dispatch.manager record
        $fieldsToString = [
            "de_request_status", "pl_request_status", "dl_request_status", "pe_request_status",
            "dispatch_type", 
            "de_request_no", "pl_request_no", "dl_request_no", "pe_request_no", "origin_port_terminal_address", "destination_port_terminal_address", "arrival_date", "delivery_date",
            "container_number", "seal_number", "booking_reference_no", "origin_forwarder_name", "destination_forwarder_name", "freight_booking_number",
            "origin_container_location", "freight_bl_number", "de_proof", "de_signature", "pl_proof", "pl_signature", "dl_proof", "dl_signature", "pe_proof", "pe_signature",
            "freight_forwarder_name", "shipper_phone", "consignee_phone", "dl_truck_plate_no", "pe_truck_plate_no", "de_truck_plate_no", "pl_truck_plate_no",
            "de_truck_type", "dl_truck_type", "pe_truck_type", "pl_truck_type", "shipper_id", "consignee_id", "shipper_contact_id", "consignee_contact_id", "vehicle_name",
            "pickup_date", "departure_date","origin", "destination","de_rejection_time", "pl_rejection_time", "dl_rejection_time", "pe_rejection_time", "de_completion_time", 
            "pl_completion_time", "dl_completion_time", "pe_completion_time","shipper_province","shipper_city","shipper_barangay","shipper_street",
            "consignee_province","consignee_city","consignee_barangay","consignee_street", "foas_datetime",  "service_type","booking_service",
            "de_assignation_time", "pl_assignation_time", "dl_assignation_time", "pe_assignation_time","stage_id", "write_date", "pe_release_by", "de_release_by",
                        "dl_receive_by", "pl_receive_by"
        ];

        $jobResponses = [];

        foreach ($filteredManagers  as $manager) {

            foreach ($fieldsToString as $field){
                if (!isset($manager[$field]) || $manager[$field] === null || $manager[$field] === false) {
                    $manager[$field] = "";
                } elseif (is_array($manager[$field]) && count($manager[$field]) > 1 && is_string($manager[$field][1])) {
                    $manager[$field] = $manager[$field][1]; // ✅ convert [id, name] to name
                } elseif (is_bool($manager[$field])) {
                    $manager[$field] = $manager[$field] ? "true" : "false";
                } else {
                    $manager[$field] = (string) $manager[$field];
                }
            }

            $jobRes = jsonRpcRequest("$url/job_dispatcher/queue_job", [
                'jsonrpc' => '2.0',
                'method' => 'call',
                'params' => [
                    'model' => 'dispatch.manager',
                    'id' => $manager['id'],
                    'method' => 'run_laravel_job',
                ],
                'id' => 5
            ]);

              $dispatchId = $manager['id'];

            

            $historyRes = jsonRpcRequest("$odooUrl", [
                'jsonrpc' => '2.0',
                'method' => 'call',
                'params' => [
                    'service' => 'object',
                    'method' => 'execute_kw',
                    'args' => [
                        $db,
                        $uid,
                        $odooPassword,
                        'dispatch.milestone.history',
                        'search_read',
                        [[[

                            'dispatch_id','=', $dispatchId
                            
                        ]]],
                        ["fields" => [
                            "id", "dispatch_id", "dispatch_type", "fcl_code", "scheduled_datetime","actual_datetime","service_type"
                        ]],
                    ]
                ],
                'id' => 6
            ]);

            $dispatchHistory = is_array($historyRes['result']) ? $historyRes['result'] : [];
            $manager['history'] = $dispatchHistory;


            

            $jobResponses[] = $manager;
        }

        // ✅ Final return
        return response()->json([
            'data' => [
                'transactions' => $jobResponses
            ]
        ]);
    }

    public function getAllBooking(Request $request)
    {
        $url = $this->url;
        $db = $this->db;

        $inputStart =  Carbon::parse($request->input('start'));

        $start =$inputStart->copy()->subDays($inputStart->dayOfWeek % 7)->startOfDay();

        $end = $start->copy()->addDays(6)->endOfDay();

       

        $page = (int) request()->query('page', 1);
        $limit = (int) request()->query('limit', 5);
        $offset = ($page - 1) * $limit;
      
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
                'args' => [$db, $login, $odooPassword],
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

        $today = date('Y-m-d');
        
        
        // Step 4: Find all dispatch.manager records where driver name matches
        $dispatchRes =jsonRpcRequest("$odooUrl", [
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
                    'search_read',
                    [[
                    
                        "|", "|", "|",
                        ["de_truck_driver_name", "=", $partnerId],
                        ["dl_truck_driver_name", "=", $partnerId],
                        ["pe_truck_driver_name", "=", $partnerId],
                        ["pl_truck_driver_name", "=", $partnerId],

                        "|",
                        ['arrival_date', ">=", $today],
                        ['departure_date', ">=", $today],
                    
                        
                    
                        ["dispatch_type", "!=", "ff"]
                    ]],
                    ["fields" => [
                        "id", "de_request_status", "pl_request_status", "dl_request_status", "pe_request_status",
                        "dispatch_type", "de_truck_driver_name", "dl_truck_driver_name", "pe_truck_driver_name", "pl_truck_driver_name",
                        "de_request_no", "pl_request_no", "dl_request_no", "pe_request_no", "origin_port_terminal_address", "destination_port_terminal_address", "arrival_date", "delivery_date",
                        "container_number", "seal_number", "booking_reference_no", "origin_forwarder_name", "destination_forwarder_name", "freight_booking_number",
                        "origin_container_location", "freight_bl_number", "de_proof", "de_signature", "pl_proof", "pl_signature", "dl_proof", "dl_signature", "pe_proof", "pe_signature",
                        "freight_forwarder_name", "shipper_phone", "consignee_phone", "dl_truck_plate_no", "pe_truck_plate_no", "de_truck_plate_no", "pl_truck_plate_no",
                        "de_truck_type", "dl_truck_type", "pe_truck_type", "pl_truck_type", "shipper_id", "consignee_id", "shipper_contact_id", "consignee_contact_id", "vehicle_name",
                        "pickup_date", "departure_date","origin", "destination", "de_rejection_time", "pl_rejection_time", "dl_rejection_time", "pe_rejection_time", "de_completion_time", 
                        "pl_completion_time", "dl_completion_time", "pe_completion_time", "shipper_province","shipper_city","shipper_barangay","shipper_street", 
                        "consignee_province","consignee_city","consignee_barangay","consignee_street", "foas_datetime", "service_type", "booking_service",
                        "de_assignation_time", "pl_assignation_time", "dl_assignation_time", "pe_assignation_time", "name", "stage_id"
                    ]
                    ]
                ]
            ],
            'id' => 4
        ]);

        $dispatchManagers = $dispatchRes['result'] ?? [];

        if (empty($dispatchManagers)) {
            Log::warning("❌ No dispatch.manager records found for driver $partnerName");
            // return response()->json(['success' => false, 'message' => 'No dispatch manager records found'], 404);
        }

        $filteredManagers = array_filter($dispatchManagers, function ($manager) use ($partnerName) {
            foreach (["de_truck_driver_name", "dl_truck_driver_name", "pe_truck_driver_name", "pl_truck_driver_name"] as $field) {
                if (
                    isset($manager[$field][1]) && $manager[$field][1] == $partnerName
                ) {
                    return true;
                }
            }
            return false;
        });

        $filteredManagers = array_values($filteredManagers);

        // Step 5: Queue a job for each dispatch.manager record
        $fieldsToString = [
            "de_request_status", "pl_request_status", "dl_request_status", "pe_request_status",
            "dispatch_type", 
            "de_request_no", "pl_request_no", "dl_request_no", "pe_request_no", "origin_port_terminal_address", "destination_port_terminal_address", "arrival_date", "delivery_date",
            "container_number", "seal_number", "booking_reference_no", "origin_forwarder_name", "destination_forwarder_name", "freight_booking_number",
            "origin_container_location", "freight_bl_number", "de_proof", "de_signature", "pl_proof", "pl_signature", "dl_proof", "dl_signature", "pe_proof", "pe_signature",
            "freight_forwarder_name", "shipper_phone", "consignee_phone", "dl_truck_plate_no", "pe_truck_plate_no", "de_truck_plate_no", "pl_truck_plate_no",
            "de_truck_type", "dl_truck_type", "pe_truck_type", "pl_truck_type", "shipper_id", "consignee_id", "shipper_contact_id", "consignee_contact_id", "vehicle_name",
            "pickup_date", "departure_date","origin", "destination","de_rejection_time", "pl_rejection_time", "dl_rejection_time", "pe_rejection_time", "de_completion_time", 
            "pl_completion_time", "dl_completion_time", "pe_completion_time","shipper_province","shipper_city","shipper_barangay","shipper_street",
            "consignee_province","consignee_city","consignee_barangay","consignee_street", "foas_datetime",  "service_type","booking_service",
            "de_assignation_time", "pl_assignation_time", "dl_assignation_time", "pe_assignation_time","stage_id"
        ];

        $jobResponses = [];

        foreach ($filteredManagers  as $manager) {

            foreach ($fieldsToString as $field){
                if (!isset($manager[$field]) || $manager[$field] === null || $manager[$field] === false) {
                    $manager[$field] = "";
                } elseif (is_array($manager[$field]) && count($manager[$field]) > 1 && is_string($manager[$field][1])) {
                    $manager[$field] = $manager[$field][1]; // ✅ convert [id, name] to name
                } elseif (is_bool($manager[$field])) {
                    $manager[$field] = $manager[$field] ? "true" : "false";
                } else {
                    $manager[$field] = (string) $manager[$field];
                }
            }

            $jobRes = jsonRpcRequest("$url/job_dispatcher/queue_job", [
                'jsonrpc' => '2.0',
                'method' => 'call',
                'params' => [
                    'model' => 'dispatch.manager',
                    'id' => $manager['id'],
                    'method' => 'run_laravel_job',
                ],
                'id' => 5
            ]);

              $dispatchId = $manager['id'];

            

            $historyRes = jsonRpcRequest("$odooUrl", [
                'jsonrpc' => '2.0',
                'method' => 'call',
                'params' => [
                    'service' => 'object',
                    'method' => 'execute_kw',
                    'args' => [
                        $db,
                        $uid,
                        $odooPassword,
                        'dispatch.milestone.history',
                        'search_read',
                        [[[

                            'dispatch_id','=', $dispatchId
                            
                        ]]],
                        ["fields" => [
                            "id", "dispatch_id", "dispatch_type", "fcl_code", "scheduled_datetime","service_type"
                        ]],
                    ]
                ],
                'id' => 6
            ]);

            $dispatchHistory = is_array($historyRes['result']) ? $historyRes['result'] : [];
            $manager['history'] = $dispatchHistory;


            

            $jobResponses[] = $manager;


           
        }
        $totalCount = count($jobResponses);
        $totalPages = ceil($totalCount / $limit);
        $hasMore = $page < $totalPages;

        $pageResponse = array_slice($jobResponses, $offset, $limit);

        return response()->json([
            'data' => [
                 'week' => $start->toDateString() . ' to ' . $end->toDateString(),

                'transactions' => $jobResponses,
                'pagination' => [
                    'current_page' => $page,
                    'per_page' => $limit,
                    'total_count' => $totalCount,
                    'total_pages' => ceil($totalCount / $limit),
                    'has_more' => ($offset + $limit) < $totalCount
                ]
            ]
        ]);
    }

    public function getHistory(Request $request)
    {
        $url = $this->url;
        $db = $this->db;

       
      
        $uid = $request->query('uid') ;
        $login = $request->header('login'); 
        $odooPassword = $request->header('password');
        $bookingId = $request->query('booking_id'); // Get booking ID from query
        Log::info('🔐 Login request', [
            'uid' => $request->query('uid'),
            'headers' => [
                'login' => $request->header('login'),
                'password' => $request->header('password'), // ⚠️ don't log in production
            ],
            'body' => $request->all(), // This shows form or JSON body content
        ]);
        
      
        
        if (!$uid) {
            return response()->json(['success' => false, 'message' => 'UID is required for details'], 400);
        }

        $odooUrl = "{$this->url}/jsonrpc"; 
       
        
        $response = jsonRpcRequest("$odooUrl", [
            'jsonrpc' => '2.0',
            'method' => 'call',
            'params' => [
                'service' => 'common',
                'method' => 'login',
                'args' => [$db, $login, $odooPassword],
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

        
        // Step 4: Find all dispatch.manager records where driver name matches
        $dispatchRes =jsonRpcRequest("$odooUrl", [
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
                    'search_read',
                    [[
                    
                        "|", "|", "|",
                        ["de_truck_driver_name", "=", $partnerId],
                        ["dl_truck_driver_name", "=", $partnerId],
                        ["pe_truck_driver_name", "=", $partnerId],
                        ["pl_truck_driver_name", "=", $partnerId],
                    
                        
                    
                        
                    ]],
                    ["fields" => [
                        "id", "de_request_status", "pl_request_status", "dl_request_status", "pe_request_status",
                        "dispatch_type", "de_request_no", "pl_request_no", "dl_request_no", "pe_request_no", 
                    ]],
                ]
            ],
            'id' => 4
        ]);
       

        $dispatchManagers = $dispatchRes['result'] ?? [];

        if (empty($dispatchManagers)) {
            Log::warning("❌ No dispatch.manager records found for driver $partnerName");
            return response()->json(['success' => false, 'message' => 'No dispatch manager records found'], 404);
        }

        

  

        // Step 5: Queue a job for each dispatch.manager record
        $fieldsToString = [
           "de_request_status", "pl_request_status", "dl_request_status", "pe_request_status",
            "dispatch_type", 
            "de_request_no", "pl_request_no", "dl_request_no", "pe_request_no", 
        ];

        $jobResponses = [];

        foreach ($dispatchManagers  as $manager) {

            foreach ($fieldsToString as $field){
                if (!isset($manager[$field]) || $manager[$field] === null || $manager[$field] === false) {
                    $manager[$field] = "";
                } elseif (is_array($manager[$field]) && count($manager[$field]) > 1 && is_string($manager[$field][1])) {
                    $manager[$field] = $manager[$field][1]; // ✅ convert [id, name] to name
                } elseif (is_bool($manager[$field])) {
                    $manager[$field] = $manager[$field] ? "true" : "false";
                } else {
                    $manager[$field] = (string) $manager[$field];
                }
            }

            $jobRes = jsonRpcRequest("$url/job_dispatcher/queue_job", [
                'jsonrpc' => '2.0',
                'method' => 'call',
                'params' => [
                    'model' => 'dispatch.manager',
                    'id' => $manager['id'],
                    'method' => 'run_laravel_job',
                ],
                'id' => 5
            ]);

            

          

            $dispatchId = $manager['id'];

            

            $historyRes = jsonRpcRequest("$odooUrl", [
                'jsonrpc' => '2.0',
                'method' => 'call',
                'params' => [
                    'service' => 'object',
                    'method' => 'execute_kw',
                    'args' => [
                        $db,
                        $uid,
                        $odooPassword,
                        'dispatch.milestone.history',
                        'search_read',
                        [[[

                            'dispatch_id','=', $dispatchId
                            
                        ]]],
                        ["fields" => [
                            "id", "dispatch_id", "dispatch_type", "fcl_code", "scheduled_datetime","service_type"
                        ]],
                    ]
                ],
                'id' => 6
            ]);

            $dispatchHistory = $historyRes['result'] ?? [];
            $manager['history'] = $dispatchHistory;

            $jobResponses[] = $manager;
        }

        // ✅ Final return
        return response()->json([
            'data' => [
                'transactions' => $jobResponses
            ]
        ]);
    }
   
    public function getRejectionReason(Request $request)
    {
        $url = $this->url;
        $db = $this->db;

        $uid = $request->query('uid') ;
        $odooPassword = $request->header('password');
        Log::info("UID is {$uid}, Password is {$odooPassword}");
        
        if (!$uid) {
            return response()->json(['success' => false, 'message' => 'UID is required'], 400);
        }

        $odooUrl = $this->odoo_url;

        $checkAccessRequest = [
            "jsonrpc" => "2.0",
            "method" => "call",
            "params" => [
                "service" => "object",
                "method" => "execute_kw",
                "args" => [
                    $db, 
                    $uid, 
                    $odooPassword, 
                    "dispatch.reject.reason", 
                    "check_access_rights",
                    ["read"],  // Search by UID
                    ["raise_exception" => false] // Don't raise exception if access is denied]
                ]
            ],
            "id" => 1
        ];
        $option = [
            "http" => [
                "header" => "Content-Type: application/json",
                "method" => "POST",
                "content" => json_encode($checkAccessRequest),
                "ignore_errors" => true,
            ],
        ];
        $context = stream_context_create($option);
        $jsonresponse = file_get_contents($odooUrl, false, $context);

        if($jsonresponse === false) {
            Log::error("❌ Failed to connect to Odoo API", ["response" => $jsonresponse]);
            return response()->json(['error' => 'Access Denied'], 403);
        }
        $jsonResult = json_decode($jsonresponse, true);
        Log::info("JSON Raw response: ", ["response" => $jsonresponse]);
        if(!isset($jsonResult['result']) || $jsonResult['result'] === false) {
            Log::error("🚨 UID {$uid} cannot read `dispatch.reject.reason`.");
            return response()->json(["error" => "Access Denied"], 403);
        } else {
            Log::info("✅ UID {$uid} can read 'dispatch.reject.reason`.");
        }

        
        
        $rejectReasons = [
            "jsonrpc" => "2.0",
            "method" => "call",
            "params" => [
                "service" => "object",
                "method" => "execute_kw",
                "args" => [
                    $db, 
                    $uid, 
                    $odooPassword, 
                    "dispatch.reject.reason", 
                    "search_read",
                    [[]],  
                    ["fields" => [
                        "id", "name",
                    ]]
                ]
            ],
            "id" => 2
        ];
    
        $rejectResponse = json_decode(file_get_contents($odooUrl, false, stream_context_create([
            "http" => [
                "header" => "Content-Type: application/json",
                "method" => "POST",
                "content" => json_encode($rejectReasons),
            ],
        ])), true);
    
        if (!isset($rejectResponse['result']) || empty($rejectResponse['result'])) {
            Log::error("❌ No reject reasons", ["response" => $rejectResponse]);
            return response()->json(['success' => false, 'message' => 'Reasons not found'], 404);
        }
        return response()->json($rejectResponse);
        

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

    public function rejectBooking(Request $request)
    {
        $url = $this->url;
        $db = $this->db;

        $uid = $request->uid ;
        $odooPassword = $request->header('password');
        $actualTime = $request->input('timestamp');
        $requestNumber = $request->input('request_number');
        Log::info("UID is {$uid}, Password is {$odooPassword}");
        
        if (!$uid) {
            return response()->json(['success' => false, 'message' => 'UID is required'], 400);
        }

        $odooUrl = $this->odoo_url;

        $checkAccessRequest = [
            "jsonrpc" => "2.0",
            "method" => "call",
            "params" => [
                "service" => "object",
                "method" => "execute_kw",
                "args" => [
                    $db, 
                    $uid, 
                    $odooPassword, 
                    "dispatch.reject.vendor", 
                    "check_access_rights",
                    ["read"],  // Search by UID
                    ["raise_exception" => false] // Don't raise exception if access is denied]
                ]
            ],
            "id" => 1
        ];
        $option = [
            "http" => [
                "header" => "Content-Type: application/json",
                "method" => "POST",
                "content" => json_encode($checkAccessRequest),
                "ignore_errors" => true,
            ],
        ];
        $context = stream_context_create($option);
        $jsonresponse = file_get_contents($odooUrl, false, $context);
        if($jsonresponse === false) {
            Log::error("❌ Failed to connect to Odoo API", ["response" => $jsonresponse]);
            return response()->json(['error' => 'Access Denied'], 403);
        }
        $jsonResult = json_decode($jsonresponse, true);
        Log::info("JSON Raw response: ", ["response" => $jsonresponse]);
        if(!isset($jsonResult['result']) || $jsonResult['result'] === false) {
            Log::error("🚨 UID {$uid} cannot read `dispatch.reject.vendor`.");
            return response()->json(["error" => "Access Denied"], 403);
        } else {
            Log::info("✅ UID {$uid} can read 'dispatch.reject.vendor`.");
        }


        
        $rejectVendor = [
            "jsonrpc" => "2.0",
            "method" => "call",
            "params" => [
                "service" => "object",
                "method" => "execute_kw",
                "args" => [
                    $db, 
                    $uid, 
                    $odooPassword, 
                    "dispatch.reject.vendor", 
                    "create",
                    [[
                        "dispatch_id" => $request->transaction_id,
                        "create_uid" => $request->uid,
                        'reason' => $request->reason,
                        'note' => $request->feedback,
                    ]],  
                   
                ]
            ],
            "id" => 2
        ];

        $response = json_decode(file_get_contents($odooUrl, false, stream_context_create([
            "http" => [
                "header" => "Content-Type: application/json",
                "method" => "POST",
                "content" => json_encode($rejectVendor),
            ],
        ])), true);
    
        if (!isset($response['result']) || empty($response['result'])) {
            Log::error("❌ No reject reasons", ["response" => $response]);
            return response()->json(['success' => false, 'message' => 'Reasons not found'], 404);
        }

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
                    [[["id", "=", $request->transaction_id]]],  // Search by Request Number
                    ["fields" => ["dispatch_type","de_request_no", "pl_request_no", "dl_request_no", "pe_request_no","service_type" ]]
                ]
            ],
            "id" => 3
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

        $updateField = [];

        if ($type['dispatch_type'] == "ot" && $type['de_request_no'] == $requestNumber) {
            $updateField = [
                "de_rejection_time" => $actualTime,
            ];
        } elseif ($type['dispatch_type'] == "ot" && $type['pl_request_no'] == $requestNumber) {
            $updateField = [
                "pl_rejection_time" => $actualTime,
            ];
        }

        if ($type['dispatch_type'] == "dt" && $type['dl_request_no'] == $requestNumber) {
            $updateField = [
                "dl_rejection_time" => $actualTime,
            ];
        } elseif ($type['dispatch_type'] == "dt" && $type['pe_request_no'] == $requestNumber) {
            $updateField = [
                "pe_rejection_time" => $actualTime,
            ];
        }

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
                        [$request->transaction_id],
                       
                        $updateField,
                        
                    ]
                ]
            ],
            "id" => 4
        ];

        $updateResponse = json_decode(file_get_contents($odooUrl,false,stream_context_create([
            "http" => [
                "header" => "Content-Type: application/json",
                "method" => "POST",
                "content" => json_encode($updatePOD),
            ]
        ])), true);


        if (isset($updateResponse['result']) && $updateResponse['result']) {
            Log::info("✅ POD uploaded. Proceeding with milestone update.");

            
            return response()->json(['success' => true, 'message' => 'POD uploaded, but no matching milestone found']);

        }else{
            Log::error("Failed to insert image", ["response" => $updateResponse]);
            return response()->json(['success' => false,'message'=>'Failed to upload POD'], 500);
        }
    
        return response()->json($statusResponse);
       

    }


    public function rejectVendor(Request $request)
    {
        
        $url = $this->url;
        $db = $this->db;

        $uid = $request->query('uid') ;
        $odooPassword = $request->header('password');
        Log::info("UID is {$uid}, Password is {$odooPassword}");
        
        if (!$uid) {
            return response()->json(['success' => false, 'message' => 'UID is required'], 400);
        }

        $odooUrl = $this->odoo_url;
        // $client = new Client("$url/xmlrpc/2/object");

        // $checkAccessRequest = new XmlRpcRequest('execute_kw', [
        //     new Value($db, "string"),
        //     new Value($uid, "int"),
        //     new Value($odooPassword, "string"),
        //     new Value("dispatch.reject.vendor", "string"),
        //     new Value("check_access_rights", "string"), 
        //     new Value([new Value("read", "string")], "array"), // ✅ Corrected array wrapping
        //     new Value(["raise_exception" => new Value(false, "boolean")], "struct") // ✅ Fixed boolean format
                
        // ]);

        
        // $searchResponse = $client->send($checkAccessRequest);
        // // dd($searchResponse);

        // Log::info("🔍 Search Users Raw Response: ", ["response" => var_export($searchResponse->value(), true)]);
        
        // if (empty($searchResponse->value())) {
        //     Log::error("🚨 UID {$uid} cannot read `dispatch.reject.vendor`.");
        //     return response()->json(["error" => "Access Denied"], 403);
        // } else {
        //     Log::info("✅ UID {$uid} can read 'dispatch.reject.vendor`.");
        // }

        $checkAccessRequest = [
            "jsonrpc" => "2.0",
            "method" => "call",
            "params" => [
                "service" => "object",
                "method" => "execute_kw",
                "args" => [
                    $db, 
                    $uid, 
                    $odooPassword, 
                    "dispatch.reject.vendor", 
                    "check_access_rights",
                    ["read"],  // Search by UID
                    ["raise_exception" => false] // Don't raise exception if access is denied]
                ]
            ],
            "id" => 1
        ];
        $option = [
            "http" => [
                "header" => "Content-Type: application/json",
                "method" => "POST",
                "content" => json_encode($checkAccessRequest),
                "ignore_errors" => true,
            ],
        ];
        $context = stream_context_create($option); 
        $jsonresponse = file_get_contents($this->odoo_url, false, $context);
        if($jsonresponse === false) {
            Log::error("❌ Failed to connect to Odoo API", ["response" => $jsonresponse]);
            return response()->json(['error' => 'Access Denied'], 403);
        }
        $jsonResult = json_decode($jsonresponse, true);
        Log::info("JSON Raw response: ", ["response" => $jsonresponse]);
        if(!isset($jsonResult['result']) || $jsonResult['result'] === false) {
            Log::error("🚨 UID {$uid} cannot read `dispatch.reject.vendor`.");
            return response()->json(["error" => "Access Denied"], 403);
        } else {
            Log::info("✅ UID {$uid} can read 'dispatch.reject.vendor`.");
        }
        

        
        
        $rejectvendors = [
            "jsonrpc" => "2.0",
            "method" => "call",
            "params" => [
                "service" => "object",
                "method" => "execute_kw",
                "args" => [
                    $db, 
                    $uid, 
                    $odooPassword, 
                    "dispatch.reject.vendor", 
                    "search_read",
                    [[]],  
                    ["fields" => [
                        "id", "dispatch_id", "create_uid", "reason", "note"
                    ]]
                ]
            ],
            "id" => 2
        ];
    
        $rejectResponse = json_decode(file_get_contents($odooUrl, false, stream_context_create([
            "http" => [
                "header" => "Content-Type: application/json",
                "method" => "POST",
                "content" => json_encode($rejectvendors),
            ],
        ])), true);
    
        if (!isset($rejectResponse['result']) || empty($rejectResponse['result'])) {
            Log::error("❌ No reject vendors", ["response" => $rejectResponse]);
            return response()->json(['success' => false, 'message' => 'vendors not found'], 404);
        }
        return response()->json($rejectResponse);
        

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

        Log::info('Received file uplodad request', [
            'uid' => $uid,
            'id' => $transactionId,
            'dispatch_type' => $dispatchType,
            'requestNumber' => $request->requestNumber,
            'actualTime' => $actualTime,
            
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
                    ["fields" => ["dispatch_type","de_request_no", "pl_request_no", "dl_request_no", "pe_request_no","service_type" ]]
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
            ];
        }

        if ($type['dispatch_type'] == "dt" && $type['dl_request_no'] == $requestNumber) {
            Log::info("Updating PL proof and signature for request number: {$requestNumber}");
           $updateField = [
                "pl_proof" => $images,
                "pl_signature" => $signature,
                "pe_release_by" => $enteredName,
                "stage_id" => 5,
                "dl_request_status" => $newStatus,
            ];
        } elseif ($type['dispatch_type'] == "dt" && $type['pe_request_no'] == $requestNumber) {
            Log::info("Updating PE proof and signature for request number: {$requestNumber}");
            $updateField = [
                "pe_proof" => $images,
                "pe_signature" => $signature,
                "dl_receive_by" => $enteredName,
                "pe_request_status" => $newStatus,
            ];
        }
      
        Log::info("Requested status update: {$newStatus}");

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
            "id" => 2
        ];

        $updateResponse = json_decode(file_get_contents($odooUrl,false,stream_context_create([
            "http" => [
                "header" => "Content-Type: application/json",
                "method" => "POST",
                "content" => json_encode($updatePOD),
            ]
        ])), true);


        if (isset($updateResponse['result']) && $updateResponse['result']) {
            Log::info("✅ POD uploaded. Proceeding with milestone update. POD JOURNEY");

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
                        ["fields" => ["id","dispatch_type","actual_datetime","scheduled_datetime","fcl_code"]]
                    ]
                ],
                "id" => 3
            ];
        
            $fcl_code_response = json_decode(file_get_contents($odooUrl, false, stream_context_create([
                "http" => [
                    "header" => "Content-Type: application/json",
                    "method" => "POST",
                    "content" => json_encode($milestoneCodeSearch),
                ],
            ])), true);
    
            if (!isset($fcl_code_response['result']) || empty($fcl_code_response['result'])) {
                Log::error("❌ No data on this ID", ["response" => $fcl_code_response]);
                return response()->json(['success' => false, 'message' => 'Data not found'], 404);
            }

            $milestoneResult = $fcl_code_response['result'][0];
            // Log::info("🎯 Milestone result list", ['result' => $milestoneResult]);

            $serviceType = is_array($type['service_type']) ? $type['service_type'][0] : $type['service_type'];


            $milestoneCodeToUpdate = null;
            $milestoneIdToUpdate = null;
            

            // Determine milestone code based on dispatch_type, request number, and service_type
            if ($type['dispatch_type'] == "ot" && $type['de_request_no'] == $requestNumber && $serviceType == 1) {
                $milestoneCodeToUpdate = "TYOT";
                Log::info("Milestone to update: {$milestoneCodeToUpdate} with actual time: {$actualTime}");
            } elseif ($type['dispatch_type'] == "ot" && $type['pl_request_no'] == $requestNumber && $serviceType == 1) {
                $milestoneCodeToUpdate = "TLOT";
                Log::info("Milestone to update: {$milestoneCodeToUpdate} with actual time: {$actualTime}");
            } elseif ($type['dispatch_type'] == "dt" && $type['dl_request_no'] == $requestNumber && $serviceType == 1) {
                $milestoneCodeToUpdate = "GYDT";
                Log::info("Milestone to update: {$milestoneCodeToUpdate} with actual time: {$actualTime}");
            } elseif ($type['dispatch_type'] == "dt" && $type['pe_request_no'] == $requestNumber && $serviceType == 1) {
                $milestoneCodeToUpdate = "GLDT";
                Log::info("Milestone to update: {$milestoneCodeToUpdate} with actual time: {$actualTime}");
            }

            if ($type['dispatch_type'] == "ot" && $type['pl_request_no'] == $requestNumber && $serviceType == 2) {
                $milestoneCodeToUpdate = "LTEOT";
                Log::info("Milestone to update: {$milestoneCodeToUpdate} with actual time: {$actualTime}");
            } elseif ($type['dispatch_type'] == "dt" && $type['dl_request_no'] == $requestNumber && $serviceType == 2) {
                $milestoneCodeToUpdate = "LGYDT";
                Log::info("Milestone to update: {$milestoneCodeToUpdate} with actual time: {$actualTime}");
            }

            $milestoneResultList = $fcl_code_response['result'];
          

            if ($milestoneCodeToUpdate) {
               
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
                

                if ($milestoneIdToUpdate) {
                    // Update actual datetime
                    
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
                                        'clicked_by' => $uid,
                                    ]
                                ]
                            ]
                        ],
                        "id" => 4
                    ];

                    $updateActualResponse = json_decode(file_get_contents($odooUrl, false, stream_context_create([
                        "http" => [
                            "header" => "Content-Type: application/json",
                            "method" => "POST",
                            "content" => json_encode($update_actual_time),
                        ]
                    ])), true);
                    Log::debug("📝 Actual time update response", ['response' => $updateActualResponse]);

                    if (isset($updateActualResponse['result']) && $updateActualResponse['result']) {
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
                                "id" => 5
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

                                // $send_email = [
                                //     "jsonrpc" => "2.0",
                                //     "method" => "call",
                                //     "params" => [
                                //         "service" => "object",
                                //         "method" => "execute_kw",
                                //         "args" => [
                                //             $db,
                                //             $uid,
                                //             $odooPassword,
                                //             "mail.template",
                                //             "send_mail",
                                //             [
                                //                 $resolved_id,
                                //                 $milestoneIdToUpdate,
                                //                 true
                                //             ]
                                //         ]
                                //     ],
                                //     "id" => 6
                                // ];

                                // $sendEmailResponse = json_decode(file_get_contents($odooUrl, false, stream_context_create([
                                //     "http" => [
                                //         "header" => "Content-Type: application/json",
                                //         "method" => "POST",
                                //         "content" => json_encode($send_email),
                                //     ]
                                // ])), true);

                                // if(isset($sendEmailResponse['result']) && $sendEmailResponse['result']) {
                                //     Log::info("Milestone updated and email sent.");
                                //     return response()->json([
                                //         'success' => true,
                                //         'message' => 'Milestone updated and email sent successfully.',
                                //         'milestone_id' => $milestoneIdToUpdate,
                                //         'template_id' =>  $resolved_id,

                                //     ], 200);
                                // } else {
                                //     Log::warning("Milestone update, but email is not sent", ['response' => $sendEmailResponse]);
                                //     return response()->json(['success' => true, 'message' => 'Milestsone updated, but email failed'], 200);
                                // }
                            } else {
                                Log::error("Failed to resolve template XML ID $template_xml_id");
                                return response()->json(['success' => false, 'message' => 'Template not found'], 500);
                            }
                            Log::info("Milestone updated!");
                        } else {
                            Log::warning("No template configured for FCL Code: $fcl_code");
                            return response()->json(['success' => true, 'message' => 'Milestone updated but no email sent'], 200);
                        }
                    } else {
                        Log::error("⚠️ POD updated but failed to update milestone", ['response' => $updateActualResponse]);
                        return response()->json(['success' => false, 'message' => 'POD updated but milestone failed'], 500);
                    }
                }
            }
            return response()->json(['success' => true, 'message' => 'POD uploaded, but no matching milestone found']);

        }else{
            Log::error("Failed to insert image", ["response" => $updateResponse]);
            return response()->json(['success' => false,'message'=>'Failed to upload POD'], 500);
        }
    
        return response()->json($statusResponse);

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

        Log::info('Received file uplodad request', [
            'uid' => $uid,
            'id' => $transactionId,
            'dispatch_type' => $dispatchType,
            'requestNumber' => $request->requestNumber,
            'actualTime' => $actualTime,
            
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
                    ["fields" => ["dispatch_type","de_request_no", "pl_request_no", "dl_request_no", "pe_request_no","service_type" ]]
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
        } elseif ($type['dispatch_type'] == "ot" && $type['pl_request_no'] == $requestNumber) {
            Log::info("Updating DL proof and signature for request number: {$requestNumber}");
            $updateField = [
                "dl_proof" => $images,
                "dl_signature" => $signature,
                "pl_receive_by" => $enteredName,
                "stage_id" => 7,
                "pl_completion_time" => $actualTime,
                // "pl_request_status" => $newStatus,
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
            ];
        } elseif($type['dispatch_type'] === "dt" && $type['dl_request_no'] === $requestNumber) {
             $updateField = [
                "dl_proof" => $images,
                "dl_signature" => $signature,
                "de_release_by" => $enteredName,
                "dl_completion_time" => $actualTime,
                // "dl_request_status" => $newStatus,
            ];
        } elseif ($type['dispatch_type'] === "dt" && $type['pe_request_no'] === $requestNumber) {
            Log::info("Updating DE proof and signature for request number: {$requestNumber}");
            $updateField = [
                "de_proof" => $images,
                "de_signature" => $signature,
                "pl_receive_by" => $enteredName,
                "stage_id" => 7,
                "pe_completion_time" => $actualTime,
                // "pe_request_status" => $newStatus,
            ];
        }

       

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
                
            ],
            "id" => 2
        ];

        $updateResponse = json_decode(file_get_contents($odooUrl,false,stream_context_create([
            "http" => [
                "header" => "Content-Type: application/json",
                "method" => "POST",
                "content" => json_encode($updatePOD),
            ]
        ])), true);


        if (isset($updateResponse['result']) && $updateResponse['result']) {
            Log::info("✅ POD uploaded. Proceeding with milestone update. POD JOURNEY");

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
                        ["fields" => ["id","dispatch_type","actual_datetime","scheduled_datetime","fcl_code"]]
                    ]
                ],
                "id" => 3
            ];
        
            $fcl_code_response = json_decode(file_get_contents($odooUrl, false, stream_context_create([
                "http" => [
                    "header" => "Content-Type: application/json",
                    "method" => "POST",
                    "content" => json_encode($milestoneCodeSearch),
                ],
            ])), true);
    
            if (!isset($fcl_code_response['result']) || empty($fcl_code_response['result'])) {
                Log::error("❌ No data on this ID", ["response" => $fcl_code_response]);
                return response()->json(['success' => false, 'message' => 'Data not found'], 404);
            }

            $milestoneResult = $fcl_code_response['result'][0];
            // Log::info("🎯 Milestone result list", ['result' => $milestoneResult]);

            $serviceType = is_array($type['service_type']) ? $type['service_type'][0] : $type['service_type'];


            $milestoneCodeToUpdate = null;
            $milestoneIdToUpdate = null;

           
            // Determine milestone code based on dispatch_type, request number, and service_type
            if ($type['dispatch_type'] == "ot" && $type['de_request_no'] == $requestNumber && $serviceType == 1) {
                $milestoneCodeToUpdate = "TEOT";
                Log::info("Milestone to update: {$milestoneCodeToUpdate} with actual time: {$actualTime}");
            } elseif ($type['dispatch_type'] == "ot" && $type['pl_request_no'] == $requestNumber && $serviceType == 1) {
                $milestoneCodeToUpdate = "CLOT";
                Log::info("Milestone to update: {$milestoneCodeToUpdate} with actual time: {$actualTime}");
            } elseif ($type['dispatch_type'] == "dt" && $type['dl_request_no'] == $requestNumber && $serviceType == 1) {
                $milestoneCodeToUpdate = "CLDT";
                Log::info("Milestone to update: {$milestoneCodeToUpdate} with actual time: {$actualTime}");
            } elseif ($type['dispatch_type'] == "dt" && $type['pe_request_no'] == $requestNumber && $serviceType == 1) {
                $milestoneCodeToUpdate = "CYDT";
                Log::info("Milestone to update: {$milestoneCodeToUpdate} with actual time: {$actualTime}");
            }

            if ($type['dispatch_type'] == "ot" && $type['pl_request_no'] == $requestNumber && $serviceType == 2) {
                $milestoneCodeToUpdate = "LCLOT";
                Log::info("Milestone to update: {$milestoneCodeToUpdate} with actual time: {$actualTime}");
            } elseif ($type['dispatch_type'] == "dt" && $type['dl_request_no'] == $requestNumber && $serviceType == 2) {
                $milestoneCodeToUpdate = "LCLDT";
                Log::info("Milestone to update: {$milestoneCodeToUpdate} with actual time: {$actualTime}");
            }

            $milestoneResultList = $fcl_code_response['result'];
          

            if ($milestoneCodeToUpdate) {
               
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
                

                if ($milestoneIdToUpdate) {
                    // Update actual datetime
                    
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
                                        'clicked_by' => $uid,
                                    ]
                                ]
                            ]
                        ],
                        "id" => 4
                    ];

                    $updateActualResponse = json_decode(file_get_contents($odooUrl, false, stream_context_create([
                        "http" => [
                            "header" => "Content-Type: application/json",
                            "method" => "POST",
                            "content" => json_encode($update_actual_time),
                        ]
                    ])), true);
                    Log::debug("📝 Actual time update response", ['response' => $updateActualResponse]);

                    if (isset($updateActualResponse['result']) && $updateActualResponse['result']) {
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
                                "id" => 5
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

                                // $send_email = [
                                //     "jsonrpc" => "2.0",
                                //     "method" => "call",
                                //     "params" => [
                                //         "service" => "object",
                                //         "method" => "execute_kw",
                                //         "args" => [
                                //             $db,
                                //             $uid,
                                //             $odooPassword,
                                //             "mail.template",
                                //             "send_mail",
                                //             [
                                //                 $resolved_id,
                                //                 $milestoneIdToUpdate,
                                //                 true
                                //             ]
                                //         ]
                                //     ],
                                //     "id" => 6
                                // ];

                                // $sendEmailResponse = json_decode(file_get_contents($odooUrl, false, stream_context_create([
                                //     "http" => [
                                //         "header" => "Content-Type: application/json",
                                //         "method" => "POST",
                                //         "content" => json_encode($send_email),
                                //     ]
                                // ])), true);

                                // if(isset($sendEmailResponse['result']) && $sendEmailResponse['result']) {
                                //     Log::info("Milestone updated and email sent.");
                                //     return response()->json([
                                //         'success' => true,
                                //         'message' => 'Milestone updated and email sent successfully.',
                                //         'milestone_id' => $milestoneIdToUpdate,
                                //         'template_id' =>  $resolved_id,

                                //     ], 200);
                                // } else {
                                //     Log::warning("Milestone update, but email is not sent", ['response' => $sendEmailResponse]);
                                //     return response()->json(['success' => true, 'message' => 'Milestsone updated, but email failed'], 200);
                                // }
                            } else {
                                Log::error("Failed to resolve template XML ID $template_xml_id");
                                return response()->json(['success' => false, 'message' => 'Template not found'], 500);
                            }
                            Log::info("Milestone updated!");
                        } else {
                            Log::warning("No template configured for FCL Code: $fcl_code");
                            return response()->json(['success' => true, 'message' => 'Milestone updated but no email sent'], 200);
                        }
                    } else {
                        Log::error("⚠️ POD updated but failed to update milestone", ['response' => $updateActualResponse]);
                        return response()->json(['success' => false, 'message' => 'POD updated but milestone failed'], 500);
                    }
                }
            }
            return response()->json(['success' => true, 'message' => 'POD uploaded, but no matching milestone found']);

        }else{
            Log::error("Failed to insert image", ["response" => $updateResponse]);
            return response()->json(['success' => false,'message'=>'Failed to upload POD'], 500);
        }
    
        return response()->json($statusResponse);

       
    }
}