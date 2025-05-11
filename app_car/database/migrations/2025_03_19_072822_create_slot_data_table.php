<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('slot_data', function (Blueprint $table) {
            $table->id();
            $table->string('slot_number', 10)->unique();
            $table->enum('status', ['free', 'busy', 'reserved'])->default('free');
            $table->string('vehicle_plate', 15)->nullable();
            $table->string('reserved_for')->nullable();
            $table->integer('floor_level');
            $table->string('section', 50)->nullable();
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('slot_data');
    }
};
