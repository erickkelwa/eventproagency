<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class AddPaymentMethodToPaymentsTable extends Migration
{
    public function up()
    {
        Schema::table('payments', function (Blueprint $table) {
            // Payment gateway: mpesa | airtel | paypal | equity
            $table->string('payment_method')->default('mpesa')->after('status');
            // Unified receipt/reference number across all gateways
            $table->string('receipt_number')->nullable()->after('mpesa_receipt_number');
            // Currency code: KES, USD, UGX etc.
            $table->string('currency', 3)->default('KES')->after('amount');
            // PayPal-specific: order ID before capture
            $table->string('paypal_order_id')->nullable()->after('receipt_number');
        });
    }

    public function down()
    {
        Schema::table('payments', function (Blueprint $table) {
            $table->dropColumn(['payment_method', 'receipt_number', 'currency', 'paypal_order_id']);
        });
    }
}
