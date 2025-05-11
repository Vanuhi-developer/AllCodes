<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class SlotData extends Model
{
    // If table name doesn't follow Laravel's convention
    protected $table = 'slot_data'; 

    // The attributes that are mass assignable
    protected $fillable = [
        'slot_number',
        'status',
        'vehicle_plate',
        'reserved_for',
        'floor_level',
        'section',
    ];

    // The attributes that should be cast to native types
    protected $casts = [
        'status' => 'string',
        'floor_level' => 'integer',
    ];

    // If you want to handle created_at and updated_at with different column names
    // public $timestamps = false; // If you don't want timestamps
    // const CREATED_AT = 'creation_date'; // Specify custom column name for created_at
    // const UPDATED_AT = 'modification_date'; // Specify custom column name for updated_at
}
