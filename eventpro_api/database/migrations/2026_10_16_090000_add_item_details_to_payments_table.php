<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * What the customer actually bought, captured at checkout.
 *
 * The app pays for a Firestore event/service whose id is usually a non-numeric
 * document id, so `booking_id` alone can never tell the backend which ticket was
 * sold. Storing the item name + quantity lets the booking-confirmation email (and
 * the downloadable receipt) name the right event for the right payer.
 */
class AddItemDetailsToPaymentsTable extends Migration
{
    public function up()
    {
        Schema::table('payments', function (Blueprint $table) {
            $table->string('item_title')->nullable();
            $table->unsignedInteger('quantity')->default(1);
        });
    }

    public function down()
    {
        Schema::table('payments', function (Blueprint $table) {
            $table->dropColumn(['item_title', 'quantity']);
        });
    }
}
