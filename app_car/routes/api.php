<?php
use App\Http\Controllers\RestController;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

// Public routes (no authentication required)
Route::post('/register', [RestController::class, 'register']); // Move this outside the auth middleware
Route::post('/get-token', [RestController::class, 'getToken'])->name('token');
Route::post('direct-login', [RestController::class, 'directLogin']);
Route::patch('/updateSlot/{slot_number}', [RestController::class, 'updateSlotData']);
Route::get('/parking-slot/count', [RestController::class, 'getCountSlot']);
Route::get('/decrementtCountSlot', [RestController::class, 'decrementCountSlot']);
Route::get('/incrementtCountSlot', [RestController::class, 'incrementCountSlot']);

Route::post('/check-booking-code', [RestController::class, 'checkBookingCode']);


// Protected routes (requires authentication)
Route::middleware('auth:sanctum')->group(function () {
    Route::post('/slots', [RestController::class, 'getSlotData']);
    Route::post('/book-slot', [RestController::class, 'bookSlot']);

    });

