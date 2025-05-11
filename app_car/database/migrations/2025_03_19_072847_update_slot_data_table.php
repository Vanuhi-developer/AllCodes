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
        Schema::table('slot_data', function (Blueprint $table) {
            // Drop the 'floor_level' and 'section' columns
            $table->dropColumn(['floor_level', 'section']);
            
            // Add the 'user_id' column (for foreign key reference to users table)
            $table->foreignId('user_id')->nullable()->constrained('users')->onDelete('set null');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('slot_data', function (Blueprint $table) {
            // Re-add the 'floor_level' and 'section' columns
            $table->integer('floor_level');
            $table->string('section', 50)->nullable();
            
            // Drop the 'user_id' column
            $table->dropForeign(['user_id']);
            $table->dropColumn('user_id');
        });
    }
};
