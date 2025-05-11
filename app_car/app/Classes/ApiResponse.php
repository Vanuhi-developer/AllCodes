<?php

namespace App\Classes;

class ApiResponse
{
    /**
     * Success response format
     *
     * @param  mixed  $data
     * @param  string $message
     * @param  int    $statusCode
     * @return \Illuminate\Http\JsonResponse
     */
    public static function success($data, $message = 'Request was successful', $statusCode = 200)
    {
        return response()->json([
            'status' => true,
            'message' => $message,
            'data' => $data,
        ], $statusCode);
    }

    /**
     * Error response format
     *
     * @param  string $message
     * @param  int    $statusCode
     * @param  array  $errors
     * @return \Illuminate\Http\JsonResponse
     */
    public static function error($message, $statusCode = 400, $errors = [])
    {
        return response()->json([
            'status' => false,
            'message' => $message,
            'errors' => $errors,
        ], $statusCode);
    }
}
