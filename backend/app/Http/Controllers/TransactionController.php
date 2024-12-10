<?php

namespace App\Http\Controllers;
use Illuminate\Support\Facades\Log;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use App\Models\Transaction;
use App\Models\TransactionImage;

class TransactionController extends Controller
{
    public function create(Request $request)
    {
        try {
            // Log::info($request->all());
            // Log::info($request->headers->all()); // Log all headers
            Log::info($request->allFiles());
            Log::info('transaction_image_path:', $request->file('transaction_image_path'));
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
                'transaction_image_path' => 'required|array', // Accept PNG/JPEG/JPG
                'transaction_image_path.*' => 'file|mimes:png,jpeg,jpg',
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
}