<?php

namespace App\Http\Controllers;
use Illuminate\Support\Facades\Log;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use App\Models\Transaction;
use App\Models\RejectionReason;
use App\Models\TransactionImage;
use PhpXmlRpc\PhpXmlRpcClient;
use PhpXmlRpc\Client;
use PhpXmlRpc\Value;
use PhpXmlRpc\Request as XmlRpcRequest;
use Ripcord\Ripcord; 

class TransactionController extends Controller
{
    public function getBooking(Request $request)
    {
        $url ="https://jralejandria-beta-dev-yxe.odoo.com";
        $db ='jralejandria-beta-dev-yxe-production-beta-19060481';

        $uid = $request->query('uid') ;
        $odooPassword = $request->header('password');
        Log::info("UID is {$uid}, Password is {$odooPassword}");
        
        if (!$uid) {
            return response()->json(['success' => false, 'message' => 'UID is required'], 400);
        }
        
        $client = new Client("$url/xmlrpc/2/object");

        $checkAccessRequest = new XmlRpcRequest('execute_kw', [
            new Value($db, "string"),
            new Value($uid, "int"),
            new Value($odooPassword, "string"),
            new Value("dispatch.manager", "string"),
            new Value("check_access_rights", "string"), 
            new Value([new Value("read", "string")], "array"), // ✅ Corrected array wrapping
            new Value(["raise_exception" => new Value(false, "boolean")], "struct") // ✅ Fixed boolean format
                
        ]);

        
        $searchResponse = $client->send($checkAccessRequest);
        // dd($searchResponse);

        Log::info("🔍 Search Users Raw Response: ", ["response" => var_export($searchResponse->value(), true)]);
        
        if (empty($searchResponse->value())) {
            Log::error("🚨 UID {$uid} cannot read `dispatch.manager`.");
            return response()->json(["error" => "Access Denied"], 403);
        } else {
            Log::info("✅ UID {$uid} can read 'dispatch.manager`.");
        }
        
        $odooUrl = "https://jralejandria-beta-dev-yxe.odoo.com/jsonrpc";
        $userData = [
            "jsonrpc" => "2.0",
            "method" => "call",
            "params" => [
                "service" => "object",
                "method" => "execute_kw",
                "args" => [
                    $db, 
                    $uid, 
                    $odooPassword, 
                    "res.users", 
                    "search_read",
                    [[["id", "=", $uid]]],  // Search by UID
                    ["fields" => ["id", "login", "partner_id"]]
                ]
            ],
            "id" => 1
        ];
    
        $userResponse = json_decode(file_get_contents($odooUrl, false, stream_context_create([
            "http" => [
                "header" => "Content-Type: application/json",
                "method" => "POST",
                "content" => json_encode($userData),
            ],
        ])), true);
    
        if (!isset($userResponse['result']) || empty($userResponse['result'])) {
            Log::error("❌ No user found for UID: $uid", ["response" => $userResponse]);
            return response()->json(['success' => false, 'message' => 'User not found'], 404);
        }
    
        $user = $userResponse['result'][0];
        $partnerId = $user['partner_id'][0] ?? null;
    
        if (!$partnerId) {
            Log::error("❌ No Partner ID found for user $uid");
            return response()->json(['success' => false, 'message' => 'No partner linked'], 404);
        }
    
        Log::info("✅ Found Partner ID: $partnerId for User $uid");
    
        // 🔍 Check Partner's Driver Access
        $partnerData = [
            "jsonrpc" => "2.0",
            "method" => "call",
            "params" => [
                "service" => "object",
                "method" => "execute_kw",
                "args" => [
                    $db,
                    $uid,
                    $odooPassword,
                    "res.partner",
                    "search_read",
                    [[["id", "=", $partnerId]]],
                    ["fields" => ["id", "name", "driver_access"]]
                ]
            ],
            "id" => 2
        ];
    
        $partnerResponse = json_decode(file_get_contents($odooUrl, false, stream_context_create([
            "http" => [
                "header" => "Content-Type: application/json",
                "method" => "POST",
                "content" => json_encode($partnerData),
            ],
        ])), true);
    
        $isDriver = false;
        if (isset($partnerResponse['result']) && !empty($partnerResponse['result'])) {
            $partner = $partnerResponse['result'][0];
            $isDriver = $partner['driver_access'] ?? false;
            Log::info($isDriver ? "✅ Partner {$partner['name']} is a driver." : "❌ Partner {$partner['name']} is NOT a driver.");
        } else {
            Log::error("❌ No partner record found for ID: $partnerId");
        }
    
        // 🔍 Fetch Pending Transactions
        $transactionData = [
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
                    [[
                        "&", // Ensure both conditions are met
                        "|", "|", "|", "|", // Check if partner_id is in any driver field
                        ["de_truck_driver_name", "=", $partnerId],
                        ["dl_truck_driver_name", "=", $partnerId],
                        ["pe_truck_driver_name", "=", $partnerId],
                        ["pl_truck_driver_name", "=", $partnerId],
        
                        "|", "|", "|", "|", "|", "|","|",// Check if any request status is "Pending"
                        ["de_request_status", "=", "Pending"],
                        ["de_request_status", "=", "Accepted"],
                        ["pl_request_status", "=", "Pending"],
                        ["pl_request_status", "=", "Accepted"],
                        ["dl_request_status", "=", "Pending"],
                        ["dl_request_status", "=", "Accepted"],
                        ["pe_request_status", "=", "Pending"],
                        ["pe_request_status", "=", "Accepted"],
        
                        ["dispatch_type", "!=", "ff"] // Exclude "ff"
                    ]],
                    ["fields" => [
                        "id", "de_request_status", "pl_request_status", "dl_request_status", "pe_request_status",
                        "dispatch_type", "de_truck_driver_name", "dl_truck_driver_name", "pe_truck_driver_name", "pl_truck_driver_name",
                        "de_request_no", "pl_request_no", "dl_request_no", "pe_request_no","origin","destination","arrival_date","delivery_date",
                        "container_number","seal_number","booking_reference_no","origin_forwarder_name","destination_forwarder_name","freight_booking_number",
                        "origin_container_location", "freight_bl_number", "de_proof", "de_signature", "pl_proof", "pl_signature", "dl_proof", "dl_signature", "pe_proof", "pe_signature"
                    ]]
                ]
            ],
            "id" => 3
        ];
    
        $transactionResponse = json_decode(file_get_contents($odooUrl, false, stream_context_create([
            "http" => [
                "header" => "Content-Type: application/json",
                "method" => "POST",
                "content" => json_encode($transactionData),
            ],
        ])), true);
    
        // 🚨 Error Handling for Missing Response
        if (!isset($transactionResponse['result'])) {
            Log::error("❌ Invalid response for transactions", ["response" => $transactionResponse]);
            return response()->json(['success' => false, 'message' => 'Error fetching transactions', 'error_details' => $transactionResponse], 500);
        }

        // ✅ Filter Transactions (Ensure Correct Partner Matching)
        $filteredTransactions = array_filter($transactionResponse['result'], function ($transaction) use ($partnerId) {
            foreach (["de_truck_driver_name", "dl_truck_driver_name", "pe_truck_driver_name", "pl_truck_driver_name"] as $field) {
                if (isset($transaction[$field][0]) && $transaction[$field][0] == $partnerId) { 
                    return true; // ✅ Partner ID matches truck driver field
                }
            }
            return false;
        });

        // ✅ Replace `false` or `null` with an empty string
        foreach ($filteredTransactions as &$transaction) {
            foreach (["de_truck_driver_name", "dl_truck_driver_name", "pe_truck_driver_name", "pl_truck_driver_name", "de_request_status", "pl_request_status", "dl_request_status", "pe_request_status",
            "de_request_no", "pl_request_no", "dl_request_no", "pe_request_no","origin","destination","arrival_date","delivery_date",
            "container_number","seal_number","booking_reference_no","origin_forwarder_name","freight_booking_number", "origin_container_location", "freight_bl_number",
            "de_proof", "de_signature", "pl_proof", "pl_signature", "dl_proof", "dl_signature", "pe_proof", "pe_signature"] as $field) {
                if ($transaction[$field] === false || $transaction[$field] === null) {
                    $transaction[$field] = ""; 
                }
            }
        }

        // ✅ Return Filtered Data
        return response()->json([
            "success" => true,
            "data" => [
                "user" => ["id" => $user['id'], "login" => $user['login']],
                "partner" => ["id" => $partnerId, "driver_access" => $isDriver],
                "transactions" => array_values($filteredTransactions) // ✅ Ensure clean index
            ]
        ]);
                // return response()->json(["success" => true, "data" => $result['result']]);

        
    }
    public function create(Request $request)
    {
       
        try {
            // Log::info($request->all());
            // Log::info($request->headers->all()); // Log all headers
            // Log::info($request->allFiles());
            // Log::info('transaction_image_path:', $request->file('transaction_image_path'));
            // if ($request->hasFile('transaction_image_path')) {
            //     // Store the image and get the file path
            //     $path = $request->file('transactichcon_image_path')->store('transaction_images', 'public');
            //     $validatedData['transaction_image_path'] = $path; // Save the path in validated data
            // }
            // Validate the request
            $validated = $request->validate([
                'user_id' => 'required|integer',
                'amount' => 'required|numeric',
                'transaction_date' => 'required|date',
                'description' => 'required|string',
                'transaction_id' => 'required|string',
                'booking' => 'required|string',
                'location' => 'required|string',
                'destination' => 'required|string',
                'eta' => 'required|date',
                'etd' => 'required|date',
                'status' => 'required|string',
                'signature_path' => 'required|file|mimes:png,jpeg,jpg',
            ]);
            Log::info('Validation passed.', $validated);
    
            // Ensure the uploaded file exists and is valid
            if ($request->hasFile('signature_path') && $request->file('signature_path')->isValid()) {
                try {
                    // Store the file using the correct field name
                    $signaturePath = $request->file('signature_path')->store('signatures', 'public');
                    Log::info('Signature file stored at: ' . $signaturePath);
    
                    // Save transaction data
                    $transaction = new Transaction([
                        'user_id' => $validated['user_id'],
                        'amount' => $validated['amount'],
                        'transaction_date' => $validated['transaction_date'],
                        'description' => $validated['description'],
                        'transaction_id' => $validated['transaction_id'],
                        'booking' => $validated['booking'],
                        'location' => $validated['location'],
                        'destination' => $validated['destination'],
                        'eta' => $validated['eta'],
                        'etd' => $validated['etd'],
                        'status' => $validated['status'],
                        'signature_path' => $signaturePath, // Store the file path
                    ]);
                    $transaction->save();

                    
                    if ($request->hasFile('transaction_image_path')) {
                        $photos = $request->file('transaction_image_path');
                    
                        // Ensure $photos is an array
                        if (!is_array($photos)) {
                            $photos = [$photos];
                        }
                    
                        foreach ($photos as $file) {
                            if ($file->isValid()) {
                                $filePath = $file->store('transaction_images', 'public');
                                TransactionImage::create([
                                    'transaction_id' => $transaction->id,
                                    'file_path' => $filePath,
                                ]);
                            }
                        }
                    }
                    return response()->json(['message' => 'Transaction saved successfully']);
                } catch (\Exception $e) {
                    Log::error('Error saving transaction: ' . $e->getMessage());
                    return response()->json(['error' => 'Error saving transaction'], 500);
                }
            } else {
                return response()->json(['error' => 'Invalid signature file'], 400);
            }
        } catch (\Illuminate\Validation\ValidationException $e) {
            return response()->json(['errors' => $e->errors()], 422);
        } catch (\Exception $e) {
            Log::error('Unexpected error: ' . $e->getMessage());
            return response()->json(['error' => 'Unexpected error occurred'], 500);
        }
    }

    public function getRejectionReason(Request $request)
    {
        
        $url ="https://jralejandria-beta-dev-yxe.odoo.com";
        $db ='jralejandria-beta-dev-yxe-production-beta-19060481';

        $uid = $request->query('uid') ;
        $odooPassword = $request->header('password');
        Log::info("UID is {$uid}, Password is {$odooPassword}");
        
        if (!$uid) {
            return response()->json(['success' => false, 'message' => 'UID is required'], 400);
        }
        
        $client = new Client("$url/xmlrpc/2/object");

        $checkAccessRequest = new XmlRpcRequest('execute_kw', [
            new Value($db, "string"),
            new Value($uid, "int"),
            new Value($odooPassword, "string"),
            new Value("dispatch.reject.reason", "string"),
            new Value("check_access_rights", "string"), 
            new Value([new Value("read", "string")], "array"), // ✅ Corrected array wrapping
            new Value(["raise_exception" => new Value(false, "boolean")], "struct") // ✅ Fixed boolean format
                
        ]);

        
        $searchResponse = $client->send($checkAccessRequest);
        // dd($searchResponse);

        Log::info("🔍 Search Users Raw Response: ", ["response" => var_export($searchResponse->value(), true)]);
        
        if (empty($searchResponse->value())) {
            Log::error("🚨 UID {$uid} cannot read `dispatch.reject.reason`.");
            return response()->json(["error" => "Access Denied"], 403);
        } else {
            Log::info("✅ UID {$uid} can read 'dispatch.reject.reason`.");
        }

        
        $odooUrl = "$url/jsonrpc";
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
            "id" => 1
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
        ]);
       
        $url ="https://jralejandria-beta-dev-yxe.odoo.com";
        $db ='jralejandria-beta-dev-yxe-production-beta-19060481';

        $uid = $request->query('uid') ;
        $odooPassword = $request->header('password');
        
        if (!$uid) {
            return response()->json(['success' => false, 'message' => 'UID is required'], 400);
        }
        
        
        $odooUrl = "https://jralejandria-beta-dev-yxe.odoo.com/jsonrpc";
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
        
        Log::info('📝 Reject Transaction Request:', [
            'uid' => $request->uid,
            'transaction_id' => $request->transaction_id,
            'reason' => $request->reason,
            'feedback' => $request->feedback,
            'timestamp' => now(),
            'ip' => $request->ip(),
            'user_agent' => $request->header('User-Agent'),
        ]);
       
        $url ="https://jralejandria-beta-dev-yxe.odoo.com";
        $db ='jralejandria-beta-dev-yxe-production-beta-19060481';

        $uid = $request->uid ;
        $odooPassword = $request->header('password');
        Log::info("UID is {$uid}, Password is {$odooPassword}");
        
        if (!$uid) {
            return response()->json(['success' => false, 'message' => 'UID is required'], 400);
        }
        
        $client = new Client("$url/xmlrpc/2/object");

        $checkAccessRequest = new XmlRpcRequest('execute_kw', [
            new Value($db, "string"),
            new Value($uid, "int"),
            new Value($odooPassword, "string"),
            new Value("dispatch.reject.vendor", "string"),
            new Value("check_access_rights", "string"), 
            new Value([new Value("read", "string")], "array"), // ✅ Corrected array wrapping
            new Value(["raise_exception" => new Value(false, "boolean")], "struct") // ✅ Fixed boolean format
                
        ]);

        
        $searchResponse = $client->send($checkAccessRequest);
        // dd($searchResponse);

        Log::info("🔍 Search Users Raw Response: ", ["response" => var_export($searchResponse->value(), true)]);
        
        if (empty($searchResponse->value())) {
            Log::error("🚨 UID {$uid} cannot read `dispatch.reject.vendor`.");
            return response()->json(["error" => "Access Denied"], 403);
        } else {
            Log::info("✅ UID {$uid} can read 'dispatch.reject.vendor`.");
        }

        $odooUrl = "$url/jsonrpc";
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
            "id" => 1
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
        return response()->json($response);

    }


    public function rejectVendor(Request $request)
    {
        
        $url ="https://jralejandria-beta-dev-yxe.odoo.com";
        $db ='jralejandria-beta-dev-yxe-production-beta-19060481';

        $uid = $request->query('uid') ;
        $odooPassword = $request->header('password');
        Log::info("UID is {$uid}, Password is {$odooPassword}");
        
        if (!$uid) {
            return response()->json(['success' => false, 'message' => 'UID is required'], 400);
        }
        
        $client = new Client("$url/xmlrpc/2/object");

        $checkAccessRequest = new XmlRpcRequest('execute_kw', [
            new Value($db, "string"),
            new Value($uid, "int"),
            new Value($odooPassword, "string"),
            new Value("dispatch.reject.vendor", "string"),
            new Value("check_access_rights", "string"), 
            new Value([new Value("read", "string")], "array"), // ✅ Corrected array wrapping
            new Value(["raise_exception" => new Value(false, "boolean")], "struct") // ✅ Fixed boolean format
                
        ]);

        
        $searchResponse = $client->send($checkAccessRequest);
        // dd($searchResponse);

        Log::info("🔍 Search Users Raw Response: ", ["response" => var_export($searchResponse->value(), true)]);
        
        if (empty($searchResponse->value())) {
            Log::error("🚨 UID {$uid} cannot read `dispatch.reject.vendor`.");
            return response()->json(["error" => "Access Denied"], 403);
        } else {
            Log::info("✅ UID {$uid} can read 'dispatch.reject.vendor`.");
        }

        
        $odooUrl = "$url/jsonrpc";
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
            "id" => 1
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
       
        $uid = $request->query('uid') ;
        $odooPassword = $request->header('password');
        $images = $request->input('images');
        $signature = $request->input('signature');
        $transactionId = (int)$request->input('id');
        $dispatchType = $request->input('dispatch_type');
        $requestNumber = $request->input('requestNumber');

        Log::info('Received file uplodad request', [
            'uid' => $uid,
            'id' => $transactionId,
            'dispatch_type' => $dispatchType,
            // 'requestNumber' => $request->requestNumber,
            // 'images' => $request->input('images'),
            // 'signature' => $request->input('signature'),
        ]); 

       


        $url ="https://jralejandria-beta-dev-yxe.odoo.com";
        $db ='jralejandria-beta-dev-yxe-production-beta-19060481';

        if (!$uid) {
            return response()->json(['success' => false, 'message' => 'UID is required'], 400);
        }

        $odooUrl = "https://jralejandria-beta-dev-yxe.odoo.com/jsonrpc";
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
                    ["fields" => ["dispatch_type","de_request_no", "pl_request_no", "dl_request_no", "pe_request_no"]]
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

       
        if($type['dispatch_type'] == "ot") {
            if ($requestNumber == $type['de_request_no']) {
                if (empty($type['de_proof']) && empty($type['de_signature'])) {
                    Log::info("Deliver Empty POD Freight side");
                    $updateField = [
                        "pe_proof" => $images,
                        "pe_signature" => $signature,
                    ];
                } else {
                    Log::info("Deliver Empty POD shipper side");
                    $updateField = [
                        "de_proof" => $images,
                        "de_signature" => $signature,
                    ];
                }
            } elseif ($type['pl_request_no'] == $requestNumber) {
                if (empty($type['pl_proof']) && empty($type['pl_signature'])) {
                    Log::info("Pickup Laden POD shipper side");
                    $updateField = [
                        "pl_proof" => $images,
                        "pl_signature" => $signature,
                    ];
                } else {
                    Log::info("Pickup Laden POD Freight side");
                    $updateField = [
                        "dl_proof" => $images,
                        "dl_signature" => $signature,
                    ];
                }
            }
        } elseif ($type['dispatch_type'] == "dt") {    
            if ($type['dl_request_no'] == $requestNumber) {
                if (empty($type['pl_proof']) && empty($type['pl_signature'])) {
                    Log::info("Deliver Laden POD freight side");
                    $updateField = [
                        "dl_proof" => $images,
                        "dl_signature" => $signature,
                    ];
                } else {
                    Log::info("Deliver Laden POD consignee side");
                    $updateField = [
                        "pl_proof" => $images,
                        "pl_signature" => $signature,
                    ];
                }
            } elseif ($type['pe_request_no'] == $requestNumber) {
                if (empty($type['pe_proof']) && empty($type['pe_signature'])) {
                    Log::info("Pickup Empty POD consignee side");
                    $updateField = [
                        "de_proof" => $images,
                        "de_signature" => $signature,
                    ];
                } else {
                    Log::info("Pickup Empty POD Freight side");
                    $updateField = [
                        "pe_proof" => $images,
                        "pe_signature" => $signature,
                    ];
                }
            }
        } else {
            Log::info("Dispatch type not recognized: {$type['dispatch_type']}");
            $updateField = [
                "de_proof" => null,
                "de_signature" => null,
                "pl_proof" => null,
                "pl_signature" => null,
                "dl_proof" => null,
                "dl_signature" => null,
                "pe_proof" => null,
                "pe_signature" => null,
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
                        // [
                            $updateField,
                        // ]
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
            return response()->json(['success' => true, 'message'=>'POD uploaded succcessfully!']);
        }else{
            Log::error("Failed to insert image", ["response" => $updateResponse]);
            return response()->json(['success' => false,'message'=>'Failed to upload POD'], 500);
        }
       
        return response()->json($statusResponse);
       
    }

}