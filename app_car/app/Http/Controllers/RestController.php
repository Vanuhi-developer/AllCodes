<?php
namespace App\Http\Controllers;

use App\Models\User;
use App\Models\SlotData;
use App\Models\ParkingSlot;
use App\Http\Requests\Auth\LoginRequest;
use App\Http\Requests\Auth\RegisterRequest;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Auth;
use App\Classes\ApiResponse;
use Illuminate\Http\Request;

class RestController extends Controller
{
  
    public function register(RegisterRequest $request)
    {
        try {
            $data = $request->validated();

            $user = User::create([
                'name' => $data['name'],
                'email' => $data['email'],
                'password' => Hash::make($data['password']),
                'phone' => $data['phone'], 
            ]);

            Auth::login($user);

            $token = $user->createToken('access-token', ['*'])->plainTextToken;

            return ApiResponse::success([
                'token' => $token
            ], __('Registration successful and user logged in.'));

        } catch (\Exception $e) {
            return ApiResponse::error(__('Internal server error'), 500);
        }
    }

    public function getSlotData()
    {
        try {
            $slots = SlotData::all();

            if ($slots->isEmpty()) {
                return ApiResponse::error(__('No parking slots found'), 404);
            }

            return ApiResponse::success($slots, __('Parking slots data retrieved successfully'));

        } catch (\Exception $e) {
            return ApiResponse::error(__('Internal server error'), 500);
        }
    }
    public function updateSlotData(Request $request, $slot_number)
{
    $validatedData = $request->validate([
        'status' => 'required|in:busy,free,reserved',
    ]);

    $slot = SlotData::where('slot_number', $slot_number)->first();

    if (!$slot) {
        return ApiResponse::error(__('Parking slot not found'), 404);
    }

    if ($slot->status === 'reserved' && $validatedData['status'] === 'free') {
        return ApiResponse::error(__('Cannot change status from reserved to free'), 403);
    }

    try {
        $slot->update($validatedData);

        return ApiResponse::success($slot, __('Parking slot updated successfully'));
    } catch (\Exception $e) {
        return ApiResponse::error(__('Failed to update slot'), 500);
    }
}


    

    public function getToken(LoginRequest $request)
    {
        $email = $request->email;
        $password = $request->password;

        $apiMail = config('app.api_mail');
        $apiMailPass = config('app.api_mail_pass');

        try {
             if ($email === $apiMail && $password === $apiMailPass) {
                 $user = User::firstOrCreate(
                    ['email' => $email],
                    [
                        'name' => 'Testing user',
                        'password' => Hash::make($password),
                    ]
                );

                 return $this->generateTokenResponse($user);
            }

             $user = User::where('email', $email)->first();

            if ($user && Hash::check($password, $user->password)) {
                 return $this->generateTokenResponse($user);
            }

            return ApiResponse::error(__('Invalid credentials'), 401);

        } catch (\Exception $e) {
            return ApiResponse::error(__('Internal server error'), 500);
        }
    }

   
    private function generateTokenResponse(User $user)
    {

        $token = $user->createToken('access-token', ['*'])->plainTextToken;

        $user->tokens->last()->forceFill(['expires_at' => now()->addMinutes(60)])->save();

        return ApiResponse::success([
            'token' => $token
        ], __('Successfully logged in'));
    }
    
    public function bookSlot(Request $request)
{
    $request->validate([
        'slot_number' => 'required|exists:slot_data,slot_number',
        'user_id' => 'required|exists:users,id', 
    ]);

    $userId = $request->user_id;  

    $user = User::find($userId);

    if (!$user) {
        return ApiResponse::error(__('User not found'), 404);
    }

    if ($user->email === config('app.api_mail')) {
        return ApiResponse::error(__('Cannot book slot for test user'), 400);
    }

    $slot = SlotData::where('slot_number', $request->slot_number)->first();

    if (!$slot) {
        return ApiResponse::error(__('Slot not found'), 404);
    }

    if ($slot->status === 'occupied') {
        return ApiResponse::error(__('Slot is already booked'), 400);
    }

    $parkingSlot = ParkingSlot::first();  
    if (!$parkingSlot) {
        return ApiResponse::error(__('Parking slot record not found'), 404);
    }

    if ($parkingSlot->count_slot <= 0) {
        return ApiResponse::error(__('No available slots to book'), 400);
    }

    try {
        $randomCode = str_pad(rand(0, 999999), 6, '0', STR_PAD_LEFT);

        $user->code = $randomCode;
        $user->save();

        $slot->status = 'reserved';
        $slot->user_id = $userId;
        $slot->save();

        $parkingSlot->count_slot -= 1;
        $parkingSlot->save();

        return ApiResponse::success([
            'slot' => $slot,
            'code' => $randomCode,  
        ], __('Slot booked successfully.'));
    } catch (\Exception $e) {
        return ApiResponse::error(__('Internal server error'), 500);
    }
}

    

public function directLogin(Request $request)
{
    $credentials = $request->only('email', 'password');

     $user = User::where('email', $credentials['email'])->first();

    if ($user && Hash::check($credentials['password'], $user->password)) {
        return response()->json([
            'status' => true,
            'message' => 'Login successful',
            'data' => [
                'id' => $user->id,
                'email' => $user->email,
                'name' => $user->name,
            ]
        ]);
    } else {
        return response()->json([
            'status' => false,
            'message' => 'Invalid credentials',
        ], 401);
    }
}
public function incrementCountSlot()
{
    $parkingSlot = ParkingSlot::first();

    if ($parkingSlot) {
        if ($parkingSlot->count_slot >= 0) {
            $parkingSlot->count_slot += 1;
            $parkingSlot->save();

            return response()->json([
                'count_slot' => $parkingSlot->count_slot,
            ]);
        }

        return response()->json([
            'message' => 'Cannot decrement. Parking slots are empty.',
        ], 400);
    }

    return response()->json([
        'message' => 'Parking slot not found',
    ], 404);
}
public function decrementCountSlot()
{
    $parkingSlot = ParkingSlot::first();

    if ($parkingSlot) {
        if ($parkingSlot->count_slot > 0 && $parkingSlot->count_slot<4 ) {
            $parkingSlot->count_slot -= 1;
            $parkingSlot->save();

            return response()->json([
                'count_slot' => $parkingSlot->count_slot,
            ]);
        }

        return response()->json([
            'message' => 'Cannot increment. Parking slots are empty.',
        ], 400);
    }

    return response()->json([
        'message' => 'Parking slot not found',
    ], 404);
}
// public function checkBookingCode(Request $request)
// {
//     $request->validate([
//         'random_code' => 'required|string',
//     ]);

//     $user = User::where('code', $request->random_code)->first();

//     if ($user) {
//         return response()->json([
//             'success' => true,
//             'message' => 'Code found.',
//             'user' => $user,
//         ]);
//     }

//     return response()->json([
//         'success' => false,
//         'message' => 'Code not found.',
//     ], 404);
// }
public function checkBookingCode(Request $request)
{
    $request->validate([
        'random_code' => 'required|string',
    ]);

    $user = User::where('code', $request->random_code)->first();

    if ($user) {
        $user->code = null;
        $user->save();

        return response()->json([
            'success' => true,
            'message' => 'Code found and deleted.',
            'user' => $user,
        ]);
    }

    return response()->json([
        'success' => false,
        'message' => 'Code not found.',
    ], 404);
}


public function getCountSlot()
    {
        $parkingSlot = ParkingSlot::first();

        if ($parkingSlot) {
            return response()->json([
                'count_slot' => $parkingSlot->count_slot,
            ]);
        }

        return response()->json([
            'message' => 'Parking slot not found',
        ], 404);
    }

}






// <?php
// namespace App\Http\Controllers;

// use App\Models\User;
// use App\Models\SlotData;
// use App\Http\Requests\Auth\LoginRequest;
// use App\Http\Requests\Auth\RegisterRequest; // Make sure to create this request
// use Illuminate\Support\Facades\Hash;
// use Illuminate\Support\Facades\Auth;
// use App\Classes\ApiResponse;
// use Illuminate\Http\Request;

// class RestController extends Controller
// {
//     /**
//      * Handle user registration.
//      */
//     public function register(RegisterRequest $request)
//     {
//         try {
//             // Validate the registration data
//             $data = $request->validated();

//             // Create the new user
//             $user = User::create([
//                 'name' => $data['name'],
//                 'email' => $data['email'],
//                 'password' => Hash::make($data['password']),
//                 'phone' => $data['phone'], // Ensure phone field is part of the request if you want it
//             ]);

//             // Automatically log the user in after registration
//             Auth::login($user);

//             // Generate an API token
//             $token = $user->createToken('access-token', ['*'])->plainTextToken;

//             return ApiResponse::success([
//                 'token' => $token
//             ], __('Registration successful and user logged in.'));

//         } catch (\Exception $e) {
//             return ApiResponse::error(__('Internal server error'), 500);
//         }
//     }

//     /**
//      * Handle login and return a token.
//      */
//     public function getSlotData()
//     {
//         try {
//             // Fetch all slot data from the database
//             $slots = SlotData::all();

//             if ($slots->isEmpty()) {
//                 return ApiResponse::error(__('No parking slots found'), 404);
//             }

//             return ApiResponse::success($slots, __('Parking slots data retrieved successfully'));

//         } catch (\Exception $e) {
//             return ApiResponse::error(__('Internal server error'), 500);
//         }
//     }
//     public function updateSlotData(Request $request, $slot_number)
//     {
//         $validatedData = $request->validate([
//             'status' => 'required|in:busy,free,reserved',
//         ]);

//         $slot = SlotData::where('slot_number', $slot_number)->first();

//         if (!$slot) {
//             return ApiResponse::error(__('Parking slot not found'), 404);
//         }

//         try {
//             $slot->update($validatedData);
            
//             // Optional: Broadcast the change if needed
//             // event(new SlotUpdated($slot));

//             return ApiResponse::success($slot, __('Parking slot updated successfully'));
//         } catch (\Exception $e) {
//             return ApiResponse::error(__('Failed to update slot'), 500);
//         }
//     }

    

//     public function getToken(LoginRequest $request)
//     {
//         $email = $request->email;
//         $password = $request->password;

//         $apiMail = config('app.api_mail');
//         $apiMailPass = config('app.api_mail_pass');

//         try {
//              if ($email === $apiMail && $password === $apiMailPass) {
//                  $user = User::firstOrCreate(
//                     ['email' => $email],
//                     [
//                         'name' => 'Testing user',
//                         'password' => Hash::make($password),
//                     ]
//                 );

//                  return $this->generateTokenResponse($user);
//             }

//              $user = User::where('email', $email)->first();

//             if ($user && Hash::check($password, $user->password)) {
//                  return $this->generateTokenResponse($user);
//             }

//             return ApiResponse::error(__('Invalid credentials'), 401);

//         } catch (\Exception $e) {
//             return ApiResponse::error(__('Internal server error'), 500);
//         }
//     }

   
//     private function generateTokenResponse(User $user)
//     {

//         $token = $user->createToken('access-token', ['*'])->plainTextToken;

//         $user->tokens->last()->forceFill(['expires_at' => now()->addMinutes(60)])->save();

//         return ApiResponse::success([
//             'token' => $token
//         ], __('Successfully logged in'));
//     }
    
//     public function bookSlot(Request $request)
// {
//     $request->validate([
//         'slot_number' => 'required|exists:slot_data,slot_number',
//         'user_id' => 'required|exists:users,id', 
//     ]);

//     $userId = $request->user_id;  

//     $user = User::find($userId);

//     if (!$user) {
//         return ApiResponse::error(__('User not found'), 404);
//     }

//     if ($user->email === config('app.api_mail')) {
//         return ApiResponse::error(__('Cannot book slot for test user'), 400);
//     }

//     $slot = SlotData::where('slot_number', $request->slot_number)->first();

//     if (!$slot) {
//         return ApiResponse::error(__('Slot not found'), 404);
//     }

//     if ($slot->status === 'occupied') {
//         return ApiResponse::error(__('Slot is already booked'), 400);
//     }

//     try {
//         $randomCode = str_pad(rand(0, 999999), 6, '0', STR_PAD_LEFT);

//         $user->code = $randomCode;
//         $user->save();

//         $slot->status = 'reserved';
//         $slot->user_id = $userId;
//         $slot->save();

//         return ApiResponse::success([
//             'slot' => $slot,
//             'code' => $randomCode,  
//         ], __('Slot booked successfully.'));
//     } catch (\Exception $e) {
//         return ApiResponse::error(__('Internal server error'), 500);
//     }
// }

    

// public function directLogin(Request $request)
// {
//     $credentials = $request->only('email', 'password');

//      $user = User::where('email', $credentials['email'])->first();

//     if ($user && Hash::check($credentials['password'], $user->password)) {
//         return response()->json([
//             'status' => true,
//             'message' => 'Login successful',
//             'data' => [
//                 'id' => $user->id,
//                 'email' => $user->email,
//                 'name' => $user->name,
//             ]
//         ]);
//     } else {
//         return response()->json([
//             'status' => false,
//             'message' => 'Invalid credentials',
//         ], 401);
//     }
// }

// }