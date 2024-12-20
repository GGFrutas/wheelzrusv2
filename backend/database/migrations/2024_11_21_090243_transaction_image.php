<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class CreateTransactionImagesTable extends Migration
{
    public function up()
    {
        Schema::create('transaction_images', function (Blueprint $table) {
            $table->id();
            $table->foreignId('transaction_id')->constrained('transactions')->onDelete('cascade');
            $table->string('file_path'); // Path to the photo file
            $table->timestamps();
        });
    }

    public function down()
    {
        Schema::dropIfExists('transaction_images');
    }
}
