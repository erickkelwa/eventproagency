<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class CreatePaymentsTable extends Migration
{
    public function up()
    {
        Schema::create('payments', function (Blueprint $table) {
            $table->id();
            $table->string('transaction_id')->unique();
            $table->string('checkout_request_id');
            $table->decimal('amount', 10, 2);
            $table->string('phone');
            $table->string('status')->default('pending'); // pending, processing, completed, failed, cancelled
            $table->string('mpesa_receipt_number')->nullable();
            $table->string('booking_type'); // 'event' or 'service'
            $table->unsignedBigInteger('booking_id');
            $table->timestamp('paid_at')->nullable();
            $table->timestamps();
        });
    }

    public function down()
    {
        Schema::dropIfExists('payments');
    }
}
