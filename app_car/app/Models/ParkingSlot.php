<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class ParkingSlot extends Model
{
    use HasFactory;

    // Define the table name (optional if your table name is the plural form of the model name)
    protected $table = 'parking_slots';

    // Define the columns that are mass assignable
    protected $fillable = ['count_slot'];

    // If you want to define the default value for count_slot directly here (optional)
    protected $attributes = [
        'count_slot' => 4, // Default value for count_slot
    ];

    // Optionally, you can define the timestamps if you want to customize them
    const CREATED_AT = 'created_at';
    const UPDATED_AT = 'updated_at';
}
