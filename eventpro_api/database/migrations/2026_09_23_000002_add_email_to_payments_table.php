<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class AddEmailToPaymentsTable extends Migration
{
    public function up()
    {
        Schema::table('payments', function (Blueprint $table) {
            // Customer email captured from the app so a receipt can be sent
            // on completion (the Laravel booking tables are not shared with
            // the Flutter/Firebase app, so we cannot resolve it from a booking).
            $table->string('email')->nullable()->after('phone');
        });
    }

    public function down()
    {
        Schema::table('payments', function (Blueprint $table) {
            $table->dropColumn('email');
        });
    }
}
