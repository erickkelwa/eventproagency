<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\EventController;
use App\Http\Controllers\AdminController;
use App\Http\Controllers\ServiceController;
use App\Http\Controllers\PaymentController;

// ── Public Routes ────────────────────────────────────────────
Route::post('/auth/register', [AuthController::class, 'register']);
Route::post('/auth/login',    [AuthController::class, 'login']);
Route::post('/auth/google',   [AuthController::class, 'googleLogin']);

Route::get('/events',      [EventController::class, 'index']);
Route::get('/events/{id}', [EventController::class, 'show']);

Route::get('/services',      [ServiceController::class, 'index']);
Route::get('/services/{id}', [ServiceController::class, 'show']);

// ── Payment Status (public — polling from app) ───────────────
Route::get('/payments/status/{id}', [PaymentController::class, 'status']);
// Legacy alias kept for backwards compatibility
Route::get('/payments/mpesa/status/{id}', [PaymentController::class, 'status']);

// ── Payment Receipt (public — opened in browser from app) ────
Route::get('/payments/receipt/{id}', [PaymentController::class, 'receipt']);

// ── PayPal Webhook/Callback (public) ────────────────────────
Route::post('/payments/paypal/capture', [PaymentController::class, 'paypalCapture']);

// ── Payment Initiation (public) ─────────────────────────────
// The Flutter app authenticates via Firebase Auth and never issues Sanctum
// tokens, so these mock payment endpoints are public. The controllers do not
// depend on an authenticated user.
Route::post('/payments/mpesa/stk-push',           [PaymentController::class, 'stkPush']);
Route::post('/payments/mpesa/callback',           [PaymentController::class, 'mpesaCallback']);
Route::post('/payments/airtel/push',              [PaymentController::class, 'airtelPush']);
Route::post('/payments/paypal/create-order',      [PaymentController::class, 'paypalCreateOrder']);
Route::post('/payments/equity/charge',            [PaymentController::class, 'equityCharge']);
Route::post('/payments/paystack/initialize',      [PaymentController::class, 'paystackInitialize']);
Route::get('/payments/paystack/callback',         [PaymentController::class, 'paystackCallback']);
Route::post('/payments/paystack/webhook',         [PaymentController::class, 'paystackCallback']);

// ── Protected Routes ─────────────────────────────────────────
Route::middleware('auth:sanctum')->group(function () {
    Route::post('/auth/logout',        [AuthController::class, 'logout']);
    Route::get('/auth/me',             [AuthController::class, 'me']);
    Route::post('/user/fcm-token',     [AuthController::class, 'updateFcmToken']);

    Route::post('/service-bookings', [ServiceController::class, 'storeBooking']);

    // ── Admin Routes ──────────────────────────────────────────
    Route::middleware('role:admin')->prefix('admin')->group(function () {
        Route::get('/dashboard', [AdminController::class, 'dashboard']);

        Route::get('/events',        [AdminController::class, 'events']);
        Route::post('/events',       [AdminController::class, 'storeEvent']);
        Route::put('/events/{id}',   [AdminController::class, 'updateEvent']);
        Route::delete('/events/{id}',[AdminController::class, 'deleteEvent']);

        Route::post('/check-in',   [AdminController::class, 'checkIn']);
        Route::get('/reports',     [AdminController::class, 'reports']);
    });
});
