<?php

namespace App\Http\Controllers\Auth;

use App\Http\Controllers\Controller;
use App\Http\Requests\LoginRequest;
use App\Http\Requests\RegisterRequest;
use App\Models\User;
use Exception;
use Illuminate\Container\Attributes\Auth;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\DB;
use Illuminate\Http\JsonResponse;
use App\Http\Requests\LoginDriverRequest;
use Illuminate\Support\Facades\Log;
use PhpXmlRpc\PhpXmlRpcClient;
use PhpXmlRpc\Client;
use PhpXmlRpc\Value;
use PhpXmlRpc\Request as XmlRpcRequest;
use Ripcord\Ripcord; 

class AuthenticationController extends Controller
{

    public function getOdooUsers()
    {
        // Fetch all users
        $users = User::all();

        // Optionally, filter specific users
        $filteredUsers = User::where('active', '=', true)->get();

        return response()->json([
            'users' => $users,
            'active_users' => $filteredUsers,
        ]);
    }
    public function register(RegisterRequest $request){
        $validatedData = $request->validated();
        if ($request->hasFile('picture')) {
            // Store the image and get the file path
            $path = $request->file('picture')->store('profile_pictures', 'public');
            $validatedData['picture'] = $path; // Save the path in validated data
        }
        $userData = [
            'name' => $validatedData['name'],
            'email' => $validatedData['email'],
            'mobile' => $validatedData['mobile'],
            'company_code' => $validatedData['company_code'] ?? null, // Allow null if not provided
            'password' => Hash::make($validatedData['password'],),
            'picture' => $validatedData['picture'] ?? null,
        ];
        Log::info('User registration data:', $userData);
        try {
            $user = User::create($userData);
            $token = $user->createToken('wheelzrus')->plainTextToken;
        
            return response([
                'user' => $user,
                'token' => $token
            ], 201);
        } catch (\Exception $e) {
            Log::error('User creation failed: ' . $e->getMessage());
            return response()->json(['error' => 'User registration failed.'], 500);
        }
    }
    public function login(Request $request){
      
        $credentials = $request->only('email', 'password');
        
        // Set up the XML-RPC client for Odoo
        $url = 'http://GSQ-IBX-CBR:8068';  // Your local Odoo instance URL
        $db = 'rda_rev_29';  // Replace with your Odoo database name
        // dd($url);

        $username = $credentials['email'];  // Odoo login field
        $password = $credentials['password']; // Odoo password
        
        // Set up the XML-RPC client for authentication
        $client = new Client("$url/xmlrpc/2/common");
    
        // Wrap the parameters in `Value` classes correctly
        $params = [
            new Value($db),  // Database name
            new Value($username),  // Username (email in your case)
            new Value($password),  // Password
            // new Value([]),       // Context (empty array)
            new Value('')
        ];
    
        // Create the authentication request
        $request = new XmlRpcRequest('authenticate', $params);
    
        // Send the request and get the response
        $response = $client->send($request);
        // dd($response->faultCode(), $response->faultString(), $response->value());
        // Check if authentication was successful
        if ($response->faultCode()) {
            return response()->json(['message' => 'Invalid credentials'], 401);
        }
    
        // Get the UID from the response (successful authentication)
        $uid = $response->value();
        
        // Retrieve the user from Odoo
        $user = User::where('login', $username)->first();
        $partner = $user->partner_id;
        

        $res = DB::table('res_partner')
            ->where('id', $partner)
            ->where('driver_access', true)
            ->first();
        

        if (!$res) {
            return response()->json(['message' => 'Access denied'], 403);
        }
        
     
        // If password matches, create the token
        $token = $user->createToken('wheelzrus')->plainTextToken;
    
        return response()->json([
            'user' => $user,
            'token' => $token
        ], 200);
        

        // If authentication fails
        return response()->json(['message' => 'Invalid credentials'], 401);  
    }

    public function logout(Request $request){
        if ($user = $request->user()) {
            $user->currentAccessToken()->delete();

            return response()->json(['message' => 'Logged out successfully'], 200);
        }

        return response()->json(['message' => 'No authenticated user'], 401);
    }

    public function updateProfile(Request $request) {
        $user = $request->user();
        
        // Validate the incoming request data
        $validator = Validator::make($request->all(), [
            'name' => 'sometimes|string|max:255',
            'email' => 'sometimes|email|unique:users,email,' . $user->id,
            'mobile' => 'sometimes|string|unique:users,mobile,' . $user->id,
            'company_code' => 'nullable|string|min:6',
            'password' => 'sometimes|string|min:8|confirmed',
            'picture' => 'nullable|image|mimes:jpeg,png,jpg,gif,svg|max:6144',
        ]);
        
        if ($validator->fails()) {
            return response()->json($validator->errors(), 422);
        }
    
        // Update other fields if present
        if ($request->has('name')) {
            $user->name = $request->input('name');
        }
    
        if ($request->has('email')) {
            $user->email = $request->input('email');
        }
    
        if ($request->has('mobile')) {
            $user->mobile = $request->input('mobile');
        }
    
        if ($request->has('company_code')) {
            $user->company_code = $request->input('company_code');
        }
    
        if ($request->has('password')) {
            $user->password = Hash::make($request->input('password'));
        }
    
        // Check if a new picture was uploaded
        if ($request->hasFile('picture')) {
            // Delete the old picture if it exists
            if ($user->picture) {
                Storage::disk('public')->delete($user->picture);
            }
    
            // Store the new picture and assign the path to the user
            $path = $request->file('picture')->store('profile_pictures', 'public');
            $user->picture = $path; // Save the new picture path
        }
    
        // Save updated user data
        try {
            $user->save();
            return response()->json([
                'message' => 'Profile updated successfully',
                'user' => $user
            ], 200);
        } catch (\Exception $e) {
            Log::error('Profile update failed: ' . $e->getMessage());
            return response()->json(['error' => 'Profile update failed.'], 500);
        }
    }
    
}