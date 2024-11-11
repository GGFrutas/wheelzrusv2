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

class AuthenticationController extends Controller
{
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
    public function login(LoginRequest $request){
        $credentials = $request->only('email', 'password');

        $user = User::where('email', $credentials['email'])->first();

        if (!$user || !Hash::check($credentials['password'], $user->password)) {
            return response()->json(['message' => 'Invalid credentials'], 401);
        }

        $token = $user->createToken('wheelzrus')->plainTextToken;

        return response()->json([
            'user' => $user,
            'token' => $token
        ], 200);
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