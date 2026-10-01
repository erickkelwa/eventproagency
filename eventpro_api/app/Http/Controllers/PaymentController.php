<?php

namespace App\Http\Controllers;

use App\Models\Payment;
use App\Models\Booking;
use App\Models\ServiceBooking;
use App\Services\BrevoMailService;
use App\Services\FcmService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Str;

class PaymentController extends Controller
{
    // ══════════════════════════════════════════════════════════
    // M-PESA  (Safaricom Daraja STK Push)
    // ══════════════════════════════════════════════════════════
    public function stkPush(Request $request)
    {
        $request->validate([
            'phone'        => 'required|string',
            'amount'       => 'required|numeric|min:1',
            'booking_type' => 'required|in:event,service',
            'booking_id'   => 'required|integer',
            'email'        => 'nullable|email',
            'fcm_token'    => 'nullable|string',
        ]);

        $phone = $this->normalizeKenyaPhone($request->phone);

        $cfg       = config('services.daraja');
        $key       = $cfg['consumer_key']    ?? null;
        $secret    = $cfg['consumer_secret'] ?? null;
        $shortcode = $cfg['short_code']      ?? null;
        $passkey   = $cfg['passkey']         ?? null;

        // ── MOCK fallback when Daraja credentials are absent ──
        if (!$key || !$secret || !$shortcode || !$passkey) {
            return $this->stkPushMock($request, $phone);
        }

        $baseUrl = ($cfg['env'] ?? 'sandbox') === 'production'
            ? $cfg['production_base']
            : $cfg['sandbox_base'];

        try {
            $token         = $this->darajaToken($baseUrl, $key, $secret);
            $timestamp     = now()->format('YmdHis');
            $password      = base64_encode($shortcode . $passkey . $timestamp);
            $transactionId = 'EP' . strtoupper(Str::random(10));

            $res = Http::withToken($token)
                ->timeout(30)
                ->post("{$baseUrl}/mpesa/stkpush/v1/processrequest", [
                    'BusinessShortCode' => $shortcode,
                    'Password'          => $password,
                    'Timestamp'         => $timestamp,
                    'TransactionType'   => 'CustomerPayBillOnline',
                    'Amount'            => round($request->amount),
                    'PartyA'            => $phone,
                    'PartyB'            => $shortcode,
                    'PhoneNumber'       => $phone,
                    'CallBackURL'       => $cfg['callback_url'],
                    'AccountReference'  => 'EventPro',
                    'TransactionDesc'   => 'EventPro payment',
                ]);

            $data = $res->json();

            // ResponseCode "0" means the STK push was accepted and sent to the phone
            if (($data['ResponseCode'] ?? null) !== '0') {
                return response()->json([
                    'error'  => $data['ErrorMessage'] ?? 'STK push failed',
                    'detail' => $data,
                ], 502);
            }

            $payment = Payment::create([
                'transaction_id'      => $transactionId,
                'checkout_request_id' => $data['CheckoutRequestID'] ?? '',
                'amount'              => $request->amount,
                'currency'            => 'KES',
                'phone'               => $phone,
                'email'               => $request->email,
                'fcm_token'           => $request->fcm_token,
                'status'              => 'pending',
                'payment_method'      => 'mpesa',
                'booking_type'        => $request->booking_type,
                'booking_id'          => $request->booking_id,
            ]);

            return response()->json([
                'message' => 'M-Pesa STK Push sent. Enter your PIN on your phone.',
                'payment' => $payment,
            ]);
        } catch (\Exception $e) {
            return response()->json(['error' => $e->getMessage()], 500);
        }
    }

    /** Fetch a Daraja OAuth access token. */
    private function darajaToken(string $baseUrl, string $key, string $secret): string
    {
        $res = Http::withBasicAuth($key, $secret)
            ->timeout(30)
            ->get("{$baseUrl}/oauth/v1/generate?grant_type=client_credentials");

        $token = $res->json('access_token');
        if (!$token) {
            throw new \Exception('Failed to obtain Daraja access token: ' . $res->body());
        }
        return $token;
    }

    /**
     * Daraja async callback for STK Push.
     * Must be publicly reachable at the CallBackURL. Returns 2xx quickly.
     */
    public function mpesaCallback(Request $request)
    {
        $result     = $request->input('Body.stkCallback', []);
        $resultCode = $result['ResultCode'] ?? null;
        $checkoutId = $result['CheckoutRequestID'] ?? null;

        if ($checkoutId) {
            $payment = Payment::where('checkout_request_id', $checkoutId)->first();
            if ($payment) {
                if ($resultCode === 0) {
                    $items   = collect($result['CallbackMetadata']['Item'] ?? []);
                    $receipt = optional($items->firstWhere('Name', 'MpesaReceiptNumber'))['Value']
                        ?? $payment->receipt_number;
                    $payment->update([
                        'status'               => 'completed',
                        'mpesa_receipt_number' => $receipt,
                        'receipt_number'       => $receipt,
                        'paid_at'              => now(),
                    ]);
                    $this->markBookingComplete($payment->fresh());
                    $this->notifyPaymentCompleted($payment->fresh());
                } else {
                    $payment->update(['status' => 'failed']);
                }
            }
        }

        return response()->json(['result' => 'OK'], 200);
    }

    /** Mock STK push used when Daraja credentials are not configured. */
    private function stkPushMock(Request $request, string $phone)
    {
        try {
            $transactionId     = 'EP' . strtoupper(Str::random(10));
            $checkoutRequestId = 'ws_CO_' . date('dmYHis') . rand(100, 999);
            $receiptNumber     = 'QHX' . strtoupper(Str::random(6));

            $payment = Payment::create([
                'transaction_id'      => $transactionId,
                'checkout_request_id' => $checkoutRequestId,
                'amount'              => $request->amount,
                'currency'            => 'KES',
                'phone'               => $phone,
                'email'               => $request->email,
                'fcm_token'           => $request->fcm_token,
                'status'              => 'completed',
                'payment_method'      => 'mpesa',
                'mpesa_receipt_number'=> $receiptNumber,
                'receipt_number'      => $receiptNumber,
                'booking_type'        => $request->booking_type,
                'booking_id'          => $request->booking_id,
                'paid_at'             => now(),
            ]);

            sleep(1); // Simulate network latency

            $this->notifyPaymentCompleted($payment);

            return response()->json([
                'message' => 'M-Pesa STK Push sent (MOCK)',
                'payment' => $payment,
            ]);
        } catch (\Exception $e) {
            return response()->json(['error' => $e->getMessage()], 500);
        }
    }

    // ══════════════════════════════════════════════════════════
    // AIRTEL MONEY  (Airtel Africa USSD Push)
    // Docs: https://developers.airtel.africa/
    // ══════════════════════════════════════════════════════════
    public function airtelPush(Request $request)
    {
        $request->validate([
            'phone'        => 'required|string',
            'amount'       => 'required|numeric',
            'booking_type' => 'required|in:event,service',
            'booking_id'   => 'required|integer',
            'email'        => 'nullable|email',
            'fcm_token'    => 'nullable|string',
        ]);

        $phone = $this->normalizeKenyaPhone($request->phone);

        try {
            // ── REAL INTEGRATION (uncomment when credentials are ready) ──
            // $clientId     = config('services.airtel.client_id');
            // $clientSecret = config('services.airtel.client_secret');
            // $country      = 'KE';   // or 'UG', 'TZ', 'RW', 'ZM' etc.
            // $currency     = 'KES';
            //
            // Step 1: Get access token
            // $tokenResponse = Http::post('https://openapi.airtel.africa/auth/oauth2/token', [
            //     'client_id'     => $clientId,
            //     'client_secret' => $clientSecret,
            //     'grant_type'    => 'client_credentials',
            // ]);
            // $token = $tokenResponse->json()['access_token'];
            //
            // Step 2: Initiate USSD Push
            // $reference = 'EP' . strtoupper(Str::random(8));
            // $pushResponse = Http::withToken($token)
            //     ->withHeaders(['X-Country' => $country, 'X-Currency' => $currency])
            //     ->post('https://openapi.airtel.africa/merchant/v2/payments/', [
            //         'reference' => $reference,
            //         'subscriber'=> ['country' => $country, 'currency' => $currency, 'msisdn' => $phone],
            //         'transaction'=> ['amount' => $request->amount, 'country' => $country, 'currency' => $currency, 'id' => $reference],
            //     ]);
            // $airtelTxId = $pushResponse->json()['data']['transaction']['id'] ?? null;

            // ── MOCK MODE ───────────────────────────────────────
            $transactionId = 'EP' . strtoupper(Str::random(10));
            $receiptNumber = 'AT' . strtoupper(Str::random(10));

            $payment = Payment::create([
                'transaction_id'      => $transactionId,
                'checkout_request_id' => 'AIRTEL_' . date('dmYHis') . rand(100, 999),
                'amount'              => $request->amount,
                'currency'            => 'KES',
                'phone'               => $phone,
                'email'               => $request->email,
                'fcm_token'           => $request->fcm_token,
                'status'              => 'completed',
                'payment_method'      => 'airtel',
                'receipt_number'      => $receiptNumber,
                'booking_type'        => $request->booking_type,
                'booking_id'          => $request->booking_id,
                'paid_at'             => now(),
            ]);

            sleep(1);

            $this->markBookingComplete($payment);
            $this->notifyPaymentCompleted($payment);

            return response()->json([
                'message' => 'Airtel Money push sent (MOCK)',
                'payment' => $payment,
            ]);
        } catch (\Exception $e) {
            return response()->json(['error' => $e->getMessage()], 500);
        }
    }

    // ══════════════════════════════════════════════════════════
    // PAYPAL  (PayPal Orders API v2)
    // Docs: https://developer.paypal.com/docs/api/orders/v2/
    // ══════════════════════════════════════════════════════════

    /** Step 1: Create PayPal order → return approval URL to app */
    public function paypalCreateOrder(Request $request)
    {
        $request->validate([
            'amount'       => 'required|numeric',
            'currency'     => 'required|string|size:3',
            'booking_type' => 'required|in:event,service',
            'booking_id'   => 'required|integer',
        ]);

        try {
            // ── REAL INTEGRATION (uncomment when credentials are ready) ──
            // $clientId     = config('services.paypal.client_id');
            // $clientSecret = config('services.paypal.client_secret');
            // $baseUrl      = config('services.paypal.sandbox') 
            //               ? 'https://api-m.sandbox.paypal.com'
            //               : 'https://api-m.paypal.com';
            //
            // $token = Http::withBasicAuth($clientId, $clientSecret)
            //     ->asForm()
            //     ->post("$baseUrl/v1/oauth2/token", ['grant_type' => 'client_credentials'])
            //     ->json()['access_token'];
            //
            // $order = Http::withToken($token)
            //     ->post("$baseUrl/v2/checkout/orders", [
            //         'intent' => 'CAPTURE',
            //         'purchase_units' => [[
            //             'amount' => ['currency_code' => $request->currency, 'value' => number_format($request->amount, 2)],
            //         ]],
            //         'application_context' => [
            //             'return_url' => url('/api/payments/paypal/capture'),
            //             'cancel_url' => url('/api/payments/paypal/cancel'),
            //         ],
            //     ])->json();
            // $orderId     = $order['id'];
            // $approvalUrl = collect($order['links'])->firstWhere('rel', 'approve')['href'];

            // ── MOCK MODE ───────────────────────────────────────
            $orderId     = 'PAYPAL-' . strtoupper(Str::random(12));
            $approvalUrl = 'https://www.sandbox.paypal.com/checkoutnow?token=' . $orderId;

            // Pre-create payment record (status = pending until capture)
            $transactionId = 'EP' . strtoupper(Str::random(10));
            $payment = Payment::create([
                'transaction_id'      => $transactionId,
                'checkout_request_id' => $orderId,
                'amount'              => $request->amount,
                'currency'            => strtoupper($request->currency),
                'phone'               => $request->phone ?? 'N/A',
                'status'              => 'pending',
                'payment_method'      => 'paypal',
                'paypal_order_id'     => $orderId,
                'booking_type'        => $request->booking_type,
                'booking_id'          => $request->booking_id,
            ]);

            return response()->json([
                'order_id'    => $orderId,
                'approval_url'=> $approvalUrl,
                'transaction_id' => $transactionId,
            ]);
        } catch (\Exception $e) {
            return response()->json(['error' => $e->getMessage()], 500);
        }
    }

    /** Step 2: Capture PayPal order after user approves */
    public function paypalCapture(Request $request)
    {
        $request->validate([
            'order_id'       => 'required|string',
            'transaction_id' => 'required|string',
        ]);

        try {
            // ── REAL INTEGRATION ──────────────────────────────
            // $token = ... (same auth as above)
            // $capture = Http::withToken($token)
            //     ->post("$baseUrl/v2/checkout/orders/{$request->order_id}/capture")
            //     ->json();
            // $captureId = $capture['purchase_units'][0]['payments']['captures'][0]['id'] ?? null;

            // ── MOCK MODE ───────────────────────────────────────
            $payment = Payment::where('transaction_id', $request->transaction_id)->firstOrFail();
            $payment->update([
                'status'         => 'completed',
                'receipt_number' => $request->order_id,
                'paid_at'        => now(),
            ]);

            $this->markBookingComplete($payment);

            return response()->json(['message' => 'Payment captured', 'payment' => $payment->fresh()]);
        } catch (\Exception $e) {
            return response()->json(['error' => $e->getMessage()], 500);
        }
    }

    // ══════════════════════════════════════════════════════════
    // EQUITY BANK  (Jenga API — EazzyPay / Card)
    // Docs: https://developer.jengaapi.io/
    // ══════════════════════════════════════════════════════════
    public function equityCharge(Request $request)
    {
        $request->validate([
            'amount'       => 'required|numeric',
            'booking_type' => 'required|in:event,service',
            'booking_id'   => 'required|integer',
            // EazzyPay (mobile-wallet): phone only
            // Card mode: card_number, expiry_month, expiry_year, cvv, card_holder
            'payment_subtype' => 'required|in:eazzypay,card',
            'phone'         => 'required_if:payment_subtype,eazzypay',
        ]);

        try {
            // ── REAL INTEGRATION (uncomment when credentials are ready) ──
            // $apiKey      = config('services.jenga.api_key');
            // $merchantCode= config('services.jenga.merchant_code');
            // $privateKey  = config('services.jenga.private_key');   // RSA private key
            // $baseUrl     = 'https://sandbox.jengahq.io';           // or api.jengahq.io for production
            //
            // Step 1: Authenticate
            // $token = Http::withHeaders(['Api-Key' => $apiKey])
            //     ->post("$baseUrl/identity-test/v2/token")->json()['accessToken'];
            //
            // Step 2: For EazzyPay (USSD push)
            // $ref = 'EP' . strtoupper(Str::random(8));
            // Http::withToken($token)->withHeaders(['signature' => $this->jengaSignature($privateKey, $ref)])
            //     ->post("$baseUrl/transaction-test/v2/airtel/receive", [
            //         'customer'    => ['name' => 'Customer', 'mobile' => $request->phone],
            //         'transaction' => ['amount' => (string)$request->amount, 'currency' => 'KES', 'reference' => $ref],
            //         'channel'     => 'EazzyPay',
            //     ]);

            // ── MOCK MODE ───────────────────────────────────────
            $transactionId = 'EP' . strtoupper(Str::random(10));
            $receiptNumber = 'EQ' . strtoupper(Str::random(10));

            $payment = Payment::create([
                'transaction_id'      => $transactionId,
                'checkout_request_id' => 'JENGA_' . date('dmYHis') . rand(100, 999),
                'amount'              => $request->amount,
                'currency'            => 'KES',
                'phone'               => $request->phone ?? 'N/A',
                'status'              => 'completed',
                'payment_method'      => 'equity',
                'receipt_number'      => $receiptNumber,
                'booking_type'        => $request->booking_type,
                'booking_id'          => $request->booking_id,
                'paid_at'             => now(),
            ]);

            sleep(1);

            $this->markBookingComplete($payment);

            return response()->json([
                'message' => 'Equity charge processed (MOCK)',
                'payment' => $payment,
            ]);
        } catch (\Exception $e) {
            return response()->json(['error' => $e->getMessage()], 500);
        }
    }

    // ══════════════════════════════════════════════════════════
    // STATUS / POLLING  (unified across all gateways)
    // ══════════════════════════════════════════════════════════
    public function status($transactionId)
    {
        $payment = Payment::where('transaction_id', $transactionId)->firstOrFail();

        // For a real (pending) M-Pesa payment, poll Daraja directly so the app
        // reflects the true state even if the async callback is delayed.
        // (Mock payments are created already-completed and never hit this path.)
        if ($payment->status === 'pending'
            && $payment->payment_method === 'mpesa'
            && $payment->checkout_request_id) {

            $cfg = config('services.daraja');
            if ($cfg['consumer_key'] && $cfg['consumer_secret'] && $cfg['short_code'] && $cfg['passkey']) {
                $this->refreshFromDaraja($payment, $cfg);
            }
        }

        return response()->json(['payment' => $payment->fresh()]);
    }

    /**
     * Render a printable HTML receipt (opened in the browser from the app).
     * Looked up by transaction_id, matching /payments/status/{id}.
     */
    public function receipt($transactionId)
    {
        $payment = Payment::where('transaction_id', $transactionId)->firstOrFail();

        $status     = ucfirst($payment->status ?? 'unknown');
        $amount     = 'KES ' . number_format((float) $payment->amount, 2);
        $receipt    = $payment->getDisplayReceipt() ?? 'N/A';
        $gateway    = $payment->getGatewayLabel();
        $method     = $payment->getReceiptLabel();
        $date       = ($payment->paid_at ?? $payment->created_at)?->format('d M Y, H:i') ?? '';
        $email      = $payment->email ?: '';
        $refType    = $payment->booking_type === 'service' ? 'Service Booking' : 'Event Booking';
        $bookingRef = '#' . $payment->booking_id;
        $statusStyle = ($payment->status === 'completed')
            ? 'background:rgba(0,166,81,.15);color:#3ddc84;'
            : 'background:rgba(255,193,7,.15);color:#ffca28;';

        $esc = fn ($v) => htmlspecialchars((string) $v, ENT_QUOTES, 'UTF-8');

        $html = <<<HTML
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>EventPro Receipt {$esc($transactionId)}</title>
<style>
  body{font-family:-apple-system,Segoe UI,Roboto,Helvetica,Arial,sans-serif;background:#0f1220;color:#e8eaf2;margin:0;padding:24px;}
  .card{max-width:520px;margin:0 auto;background:#171a2b;border:1px solid #262a45;border-radius:16px;padding:28px;box-shadow:0 8px 30px rgba(0,0,0,.35);}
  .brand{text-align:center;font-weight:800;letter-spacing:.5px;font-size:20px;margin-bottom:4px;}
  .sub{text-align:center;color:#9aa0be;font-size:13px;margin-bottom:22px;}
  .amount{text-align:center;font-size:34px;font-weight:800;margin:6px 0 2px;}
  .status{text-align:center;display:inline-block;margin:0 auto 22px;padding:6px 14px;border-radius:999px;font-size:13px;font-weight:700;
    background:{$statusStyle};}
  .statuswrap{text-align:center;margin-bottom:8px;}
  table{width:100%;border-collapse:collapse;margin-top:8px;}
  td{padding:12px 4px;border-bottom:1px solid #262a45;font-size:14px;vertical-align:top;}
  td.k{color:#9aa0be;width:45%;}
  td.v{text-align:right;font-weight:600;word-break:break-all;}
  .foot{text-align:center;color:#6b7194;font-size:12px;margin-top:22px;}
  @media print{body{background:#fff;color:#111}.card{border:none;box-shadow:none}}
</style>
</head>
<body>
  <div class="card">
    <div class="brand">EventPro</div>
    <div class="sub">Payment Receipt</div>
    <div class="amount">{$esc($amount)}</div>
    <div class="statuswrap"><span class="status">{$esc($status)}</span></div>
    <table>
      <tr><td class="k">Transaction ID</td><td class="v">{$esc($transactionId)}</td></tr>
      <tr><td class="k">Payment Method</td><td class="v">{$esc($gateway)}</td></tr>
      <tr><td class="k">{$esc($method)}</td><td class="v">{$esc($receipt)}</td></tr>
      <tr><td class="k">Date</td><td class="v">{$esc($date)}</td></tr>
      <tr><td class="k">{$esc($refType)}</td><td class="v">{$esc($bookingRef)}</td></tr>
HTML;
        if ($email !== '') {
            $html .= "      <tr><td class=\"k\">Paid By</td><td class=\"v\">{$esc($email)}</td></tr>\n";
        }
        $html .= <<<HTML
    </table>
    <div class="foot">Thank you for choosing EventPro. Keep this receipt for your records.</div>
  </div>
</body>
</html>
HTML;

        return response($html, 200)->header('Content-Type', 'text/html');
    }

    /** Query Daraja for the current state of a pending STK push. */
    private function refreshFromDaraja(Payment $payment, array $cfg): void
    {
        $baseUrl   = ($cfg['env'] ?? 'sandbox') === 'production' ? $cfg['production_base'] : $cfg['sandbox_base'];
        $timestamp = now()->format('YmdHis');
        $password  = base64_encode($cfg['short_code'] . $cfg['passkey'] . $timestamp);

        try {
            $token = $this->darajaToken($baseUrl, $cfg['consumer_key'], $cfg['consumer_secret']);
            $res = Http::withToken($token)->timeout(30)->post("{$baseUrl}/mpesa/stkpushquery/v1/query", [
                'BusinessShortCode' => $cfg['short_code'],
                'Password'          => $password,
                'Timestamp'         => $timestamp,
                'CheckoutRequestID' => $payment->checkout_request_id,
            ]);

            $data       = $res->json();
            $resultCode = $data['ResultCode'] ?? null;

            if ($resultCode === 0) {
                $items   = collect($data['CallbackMetadata']['Item'] ?? []);
                $receipt = optional($items->firstWhere('Name', 'MpesaReceiptNumber'))['Value']
                    ?? $payment->receipt_number;
                $payment->update([
                    'status'               => 'completed',
                    'mpesa_receipt_number' => $receipt,
                    'receipt_number'       => $receipt,
                    'paid_at'              => now(),
                ]);
                $this->markBookingComplete($payment->fresh());
                $this->notifyPaymentCompleted($payment->fresh());
            } elseif ($resultCode === 1) {
                // 1 = cancelled by user
                $payment->update(['status' => 'failed']);
            }
            // Any other code: leave pending (still awaiting customer PIN / processing)
        } catch (\Exception $e) {
            // Non-fatal: keep the current status and let the next poll retry.
            report($e);
        }
    }

    // ══════════════════════════════════════════════════════════
    // PAYSTACK  (Card + Mobile Money)
    // Docs: https://paystack.com/docs/api/
    // ══════════════════════════════════════════════════════════

    /**
     * Initialize a Paystack transaction.
     * POST /payments/paystack/initialize
     * Body: { amount, email, booking_type, booking_id, fcm_token? }
     * Returns: { authorization_url, reference, payment_id }
     */
    public function paystackInitialize(Request $request)
    {
        $request->validate([
            'amount'       => 'required|numeric|min:1',
            'email'        => 'required|email',
            'booking_type' => 'required|in:event,service',
            'booking_id'   => 'required|integer',
            'fcm_token'    => 'nullable|string',
        ]);

        $cfg       = config('services.paystack');
        $secretKey = $cfg['secret_key'] ?? null;

        // ── MOCK fallback when keys are absent ──
        if (!$secretKey) {
            $reference     = 'EP_MOCK_' . strtoupper(\Illuminate\Support\Str::random(10));
            $payment = Payment::create([
                'transaction_id'      => $reference,
                'checkout_request_id' => $reference,
                'amount'              => $request->amount,
                'currency'            => 'KES',
                'email'               => $request->email,
                'fcm_token'           => $request->fcm_token,
                'status'              => 'completed',
                'payment_method'      => 'paystack',
                'booking_type'        => $request->booking_type,
                'booking_id'          => $request->booking_id,
                'paid_at'             => now(),
            ]);
            $this->markBookingComplete($payment);
            $this->notifyPaymentCompleted($payment);
            return response()->json([
                'mock'              => true,
                'authorization_url' => null,
                'reference'         => $reference,
                'payment'           => $payment,
            ]);
        }

        try {
            // Paystack expects amount in kobo/cents (×100)
            $amountInKobo  = (int) round($request->amount * 100);
            $reference     = 'EP_' . strtoupper(\Illuminate\Support\Str::random(12));

            $res = Http::withToken($secretKey)
                ->timeout(30)
                ->post("{$cfg['base_url']}/transaction/initialize", [
                    'email'        => $request->email,
                    'amount'       => $amountInKobo,
                    'reference'    => $reference,
                    'callback_url' => $cfg['callback_url'],
                    'currency'     => 'KES',
                    'metadata'     => [
                        'booking_type' => $request->booking_type,
                        'booking_id'   => $request->booking_id,
                        'fcm_token'    => $request->fcm_token,
                    ],
                ]);

            $data = $res->json();

            if (!($data['status'] ?? false)) {
                return response()->json([
                    'error'  => $data['message'] ?? 'Paystack initialization failed',
                    'detail' => $data,
                ], 502);
            }

            $payment = Payment::create([
                'transaction_id'      => $reference,
                'checkout_request_id' => $reference,
                'amount'              => $request->amount,
                'currency'            => 'KES',
                'email'               => $request->email,
                'fcm_token'           => $request->fcm_token,
                'status'              => 'pending',
                'payment_method'      => 'paystack',
                'booking_type'        => $request->booking_type,
                'booking_id'          => $request->booking_id,
            ]);

            return response()->json([
                'authorization_url' => $data['data']['authorization_url'],
                'reference'         => $reference,
                'payment'           => $payment,
            ]);
        } catch (\Exception $e) {
            return response()->json(['error' => $e->getMessage()], 500);
        }
    }

    /**
     * Paystack redirects the user here after payment (GET).
     * Also used as a webhook endpoint.
     * GET /payments/paystack/callback?reference=xxx
     */
    public function paystackCallback(Request $request)
    {
        $reference = $request->query('reference') ?? $request->input('data.reference');

        if (!$reference) {
            return response()->json(['error' => 'Missing reference'], 400);
        }

        $cfg       = config('services.paystack');
        $secretKey = $cfg['secret_key'] ?? null;

        if (!$secretKey) {
            return response()->json(['error' => 'Paystack not configured'], 500);
        }

        try {
            $res  = Http::withToken($secretKey)
                ->timeout(30)
                ->get("{$cfg['base_url']}/transaction/verify/{$reference}");

            $data   = $res->json();
            $status = $data['data']['status'] ?? null;

            $payment = Payment::where('transaction_id', $reference)->first();

            if (!$payment) {
                return response()->json(['error' => 'Payment record not found'], 404);
            }

            if ($status === 'success') {
                $meta = $data['data']['metadata'] ?? [];
                $payment->update([
                    'status'  => 'completed',
                    'paid_at' => now(),
                ]);
                $this->markBookingComplete($payment->fresh());
                $this->notifyPaymentCompleted($payment->fresh());

                return response()->json(['message' => 'Payment verified successfully', 'payment' => $payment->fresh()]);
            }

            $payment->update(['status' => 'failed']);
            return response()->json(['error' => 'Payment not successful', 'status' => $status], 400);

        } catch (\Exception $e) {
            return response()->json(['error' => $e->getMessage()], 500);
        }
    }

    // ══════════════════════════════════════════════════════════
    // HELPERS
    // ══════════════════════════════════════════════════════════
    private function normalizeKenyaPhone(string $phone): string
    {
        $phone = preg_replace('/[\s\-\+]/', '', $phone);
        if (str_starts_with($phone, '0')) {
            return '254' . substr($phone, 1);
        }
        if (!str_starts_with($phone, '254')) {
            return '254' . $phone;
        }
        return $phone;
    }

    private function markBookingComplete(Payment $payment): void
    {
        if ($payment->status !== 'completed') return;

        if ($payment->booking_type === 'event') {
            $booking = Booking::find($payment->booking_id);
            if ($booking) {
                $booking->update(['status' => 'completed', 'qr_code' => \Illuminate\Support\Str::uuid()]);
            }
        } elseif ($payment->booking_type === 'service') {
            $booking = ServiceBooking::find($payment->booking_id);
            if ($booking) {
                $booking->update(['status' => 'paid']);
            }
        }
    }

    /**
     * Send a payment receipt email when a payment reaches 'completed'.
     * No-ops when there is no email on file or Brevo is not configured.
     */
    private function notifyPaymentCompleted(Payment $payment): void
    {
        if ($payment->status !== 'completed') return;

        $amount = 'KES ' . number_format((float) $payment->amount, 2);

        // ── Push notification via FCM ──
        if ($payment->fcm_token) {
            try {
                app(FcmService::class)->sendToUser(
                    $payment->fcm_token,
                    'Payment Successful',
                    'Your payment of ' . $amount . ' (Ref ' . $payment->transaction_id . ') was received.',
                    ['transaction_id' => $payment->transaction_id, 'status' => 'completed']
                );
            } catch (\Throwable $e) {
                \Illuminate\Support\Facades\Log::error('FCM notify failed: ' . $e->getMessage());
            }
        }

        // ── Receipt email via Brevo ──
        $email = $payment->email;
        if (!$email) {
            \Illuminate\Support\Facades\Log::info(
                'Payment completed but no email provided; skipped receipt.',
                ['payment_id' => $payment->id]
            );
            return;
        }

        if (!env('BREVO_API_KEY')) {
            \Illuminate\Support\Facades\Log::warning(
                'Payment completed but BREVO_API_KEY not set; skipped receipt email.',
                ['payment_id' => $payment->id]
            );
            return;
        }

        try {
            app(BrevoMailService::class)
                ->sendReceipt($email, '', $payment->amount, $payment->transaction_id);
        } catch (\Throwable $e) {
            \Illuminate\Support\Facades\Log::error('Receipt email failed: ' . $e->getMessage());
        }
    }
}
