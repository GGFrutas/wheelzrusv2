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

    Route::post('createTransaction', [TransactionController::class, 'create']);
    Route::post('loginDriver', [AuthenticationController::class, 'loginDriver']);
    Route::post('register', [AuthenticationController::class, 'register']);
    Route::post('login', [AuthenticationController::class, 'login']);
    Route::post('logout', [AuthenticationController::class, 'logout'])->middleware('auth:sanctum');
    Route::put('update', [AuthenticationController::class, 'updateProfile'])->middleware('auth:sanctum');
});