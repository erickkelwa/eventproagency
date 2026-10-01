<?php

return [

    /*
    |--------------------------------------------------------------------------
    | Third Party Services
    |--------------------------------------------------------------------------
    |
    | This file is for storing the credentials for third party services such
    | as Mailgun, Postmark, AWS and more. This file provides the de facto
    | location for this type of information, allowing packages to have
    | a conventional file to locate the various service credentials.
    |
    */

    'mailgun' => [
        'domain' => env('MAILGUN_DOMAIN'),
        'secret' => env('MAILGUN_SECRET'),
        'endpoint' => env('MAILGUN_ENDPOINT', 'api.mailgun.net'),
    ],

    'postmark' => [
        'token' => env('POSTMARK_TOKEN'),
    ],

    'ses' => [
        'key' => env('AWS_ACCESS_KEY_ID'),
        'secret' => env('AWS_SECRET_ACCESS_KEY'),
        'region' => env('AWS_DEFAULT_REGION', 'us-east-1'),
    ],

    // Safaricom Daraja (M-Pesa STK Push)
    'daraja' => [
        // sandbox | production
        'env'            => env('DARAJA_ENV', 'sandbox'),
        'sandbox_base'   => 'https://sandbox.safaricom.co.ke',
        'production_base'=> 'https://api.safaricom.co.ke',
        'consumer_key'     => env('DARAJA_CONSUMER_KEY'),
        'consumer_secret'  => env('DARAJA_CONSUMER_SECRET'),
        'short_code'       => env('DARAJA_SHORTCODE'),
        'passkey'          => env('DARAJA_PASSKEY'),
        // Sandbox test shortcode is 174379; set your callback URL publicly reachable
        'callback_url'     => env('DARAJA_CALLBACK_URL', env('APP_URL') . '/api/payments/mpesa/callback'),
    ],

    // Paystack (Card + Mobile Money)
    'paystack' => [
        'secret_key'   => env('PAYSTACK_SECRET_KEY'),
        'public_key'   => env('PAYSTACK_PUBLIC_KEY'),
        'base_url'     => 'https://api.paystack.co',
        'callback_url' => env('PAYSTACK_CALLBACK_URL', env('APP_URL') . '/api/payments/paystack/callback'),
    ],

];
