<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Payment extends Model
{
    use HasFactory;

    protected $fillable = [
        'transaction_id',
        'checkout_request_id',
        'amount',
        'currency',
        'phone',
        'email',
        'fcm_token',
        'status',
        'payment_method',       // mpesa | airtel | paypal | equity
        'mpesa_receipt_number', // M-Pesa specific
        'receipt_number',       // unified receipt across all gateways
        'paypal_order_id',      // PayPal order ID (pre-capture)
        'booking_type',
        'booking_id',
        'paid_at',
    ];

    protected $casts = [
        'paid_at' => 'datetime',
        'amount'  => 'float',
        'booking_id' => 'integer',
    ];

    // ── Helpers ──────────────────────────────────────────────
    public function getGatewayLabel(): string
    {
        return match ($this->payment_method) {
            'airtel' => 'Airtel Money',
            'paypal' => 'PayPal',
            'equity' => 'Equity Bank',
            default  => 'M-Pesa',
        };
    }

    public function getReceiptLabel(): string
    {
        return match ($this->payment_method) {
            'airtel' => 'Airtel Transaction ID',
            'paypal' => 'PayPal Order ID',
            'equity' => 'Equity Reference',
            default  => 'M-Pesa Receipt',
        };
    }

    public function getDisplayReceipt(): ?string
    {
        return $this->receipt_number ?? $this->mpesa_receipt_number ?? $this->paypal_order_id;
    }
}
