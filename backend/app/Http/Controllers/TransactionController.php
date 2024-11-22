namespace App\Http\Controllers;

use Illuminate\Support\Facades\Log;
use Illuminate\Http\Request;
use App\Models\Transaction;
use App\Models\TransactionImage;

class TransactionController extends Controller
{
    public function create(Request $request)
    {
        try {
            Log::info($request->all());
            Log::info($request->headers->all()); // Log all headers
    
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
                'transaction_images' => 'required|array', // Expect an array of files
                'transaction_images.*' => 'file|mimes:png,jpeg,jpg', // Validate each file
                'transaction_images_type' => 'required|array', // Type array to differentiate between signature and image proof
                'transaction_images_type.*' => 'in:signature,image_proof', // Type should be either 'signature' or 'image_proof'
            ]);
            Log::info('Validation passed.', $validated);
    
            // Save transaction data first
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
            ]);
            $transaction->save();
            Log::info('Transaction saved successfully.');
    
            // Store each image and its type
            if ($request->hasFile('transaction_images')) {
                $transactionImages = $request->file('transaction_images');
                $transactionImagesType = $request->input('transaction_images_type');

                foreach ($transactionImages as $index => $file) {
                    if ($file->isValid()) {
                        // Store the file (either signature or image proof)
                        $filePath = $file->store('transaction_images', 'public');
                        Log::info('File stored at: ' . $filePath);

                        // Create a new transaction image record and associate it with the transaction
                        TransactionImage::create([
                            'transaction_id' => $transaction->id, // Associate image with the created transaction
                            'file_path' => $filePath,
                            'type' => $transactionImagesType[$index], // 'signature' or 'image_proof'
                        ]);
                    }
                }
            }

            return response()->json(['message' => 'Transaction and images saved successfully']);
        } catch (\Illuminate\Validation\ValidationException $e) {
            return response()->json(['errors' => $e->errors()], 422);
        } catch (\Exception $e) {
            Log::error('Unexpected error: ' . $e->getMessage());
            return response()->json(['error' => 'Unexpected error occurred'], 500);
        }
    }
}
