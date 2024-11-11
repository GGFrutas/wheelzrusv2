<?php

namespace App\Http\Controllers;
use App\Http\Requests\TransactionRequest;
use App\Models\Transaction;
use App\Models\User;

class TransactionController extends Controller
{
    public function create(TransactionRequest $request){

    $transaction = Transaction::create($request->validated());

    return response()->json([
        'message' => 'Transaction created successfully!',
        'data' => $transaction
    ], 201);
    }
}
