<?php

use App\Http\Controllers\Auth\AuthenticationController;
use App\Http\Controllers\TransactionController;
use Illuminate\Http\Middleware\HandleCors;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\DB;

Route::middleware([HandleCors::class])->group(function () {
    Route::get('/user', function (Request $request) {
        return $request->user();
    })->middleware('auth:sanctum');

    Route::get('/test', function()  {
        return response([
            'message' => 'Api is working'
        ], 200);
    });
    Route::post('/createTransaction', [TransactionController::class, 'create'])->middleware('api');
    // Route::post('createTransaction', [TransactionController::class, 'create']);
    Route::post('loginDriver', [AuthenticationController::class, 'loginDriver']);
    Route::post('register', [AuthenticationController::class, 'register']);
    Route::post('login', [AuthenticationController::class, 'login']);
    Route::post('logout', [AuthenticationController::class, 'logout'])->middleware('auth:sanctum');
    Route::put('update', [AuthenticationController::class, 'updateProfile'])->middleware('auth:sanctum');
    Route::get('/odoo/users', [AuthenticationController::class, 'getOdooUsers']);
    Route::get('/odoo/booking', [TransactionController::class, 'getBooking']);
    Route::get('/odoo/history', [TransactionController::class, 'getHistory']);
    Route::get('/odoo/reason', [TransactionController::class, 'getRejectionReason']);
    Route::post('/odoo/{transactionId}/status', [TransactionController::class, 'updateStatus']);
    Route::post('/odoo/reject-booking', [TransactionController::class, 'rejectBooking']);
    Route::get('/odoo/reject_vendor', [TransactionController::class, 'rejectVendor']);
    Route::post('/odoo/pod-accepted-to-ongoing', [TransactionController::class, 'uploadPOD']);
    Route::post('/odoo/pod-ongoing-to-complete', [TransactionController::class, 'uploadPOD_sec']);


});