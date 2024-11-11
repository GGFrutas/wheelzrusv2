<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class CreateTransactionsTable extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {   
        Schema::create('transactions', function (Blueprint $table) {
            $table->id(); // Auto-incrementing primary key
            $table->unsignedBigInteger('user_id'); // Foreign key to users table
            $table->decimal('amount', 10, 2); // Transaction amount
            $table->dateTime('transaction_date'); // Date and time of transaction
            $table->string('transaction_id')->unique(); // Unique transaction identifier
            $table->string('booking')->nullable(); // Booking reference/details
            $table->string('location')->nullable(); // Transaction location
            $table->string('destination')->nullable(); // Transaction destination
            $table->dateTime('eta')->nullable(); // Estimated time of arrival
            $table->string('status')->default('pending'); // Transaction status
            $table->text('description')->nullable(); // Optional description
            $table->timestamps(); // created_at and updated_at
           
            // Define foreign key constraint
            $table->foreign('user_id')
                  ->references('id')
                  ->on('users')
                  ->onDelete('cascade');
        });
    }
    
    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::dropIfExists('transactions');
    }
}
