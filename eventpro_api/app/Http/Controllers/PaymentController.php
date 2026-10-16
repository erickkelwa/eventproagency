<?php

namespace App\Http\Controllers;

use App\Models\Payment;
use App\Models\Booking;
use App\Models\Event;
use App\Models\ServiceBooking;
use App\Models\User;
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
            'item_title'   => 'nullable|string|max:120',
            'quantity'     => 'nullable|integer|min:1',
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

        // Daraja REJECTS the STK push if CallBackURL is not a valid public HTTPS
        // URL, which silently forces the mock fallback (no prompt on the phone).
        // If the configured value is missing or malformed (e.g. just a hostname),
        // derive a correct one from the incoming request's public host.
        $callbackUrl = (string) ($cfg['callback_url'] ?? '');
        if (!preg_match('#^https://#i', $callbackUrl)) {
            $callbackUrl = 'https://' . $request->getHost() . '/api/payments/mpesa/callback';
        }

        try {
            $token = $this->darajaToken($baseUrl, $key, $secret);
            if (!$token) {
                // If Daraja sandbox token is unreachable, automatically fall back to simulation
                return $this->stkPushMock($request, $phone);
            }

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
                    'CallBackURL'       => $callbackUrl,
                    'AccountReference'  => 'EventPro',
                    'TransactionDesc'   => 'EventPro payment',
                ]);

            $data = $res->json();

            // ResponseCode "0" means the STK push was accepted and sent to the phone
            if (($data['ResponseCode'] ?? null) !== '0') {
                $errorMessage = $data['ErrorMessage'] ?? 'STK push failed';
                
                // Record the failed attempt so it appears in Admin "Users with Issues"
                Payment::create([
                    'transaction_id'      => $transactionId,
                    'checkout_request_id' => $data['CheckoutRequestID'] ?? '',
                    'amount'              => $request->amount,
                    'currency'            => 'KES',
                    'phone'               => $phone,
                    'email'               => $request->email,
                    'fcm_token'           => $request->fcm_token,
                    'status'              => 'failed',
                    'payment_method'      => 'mpesa',
                    'booking_type'        => $request->booking_type,
                    'booking_id'          => $request->booking_id,
                ]);

                // If sandbox simulation is allowed as fallback, simulate successful push
                if (env('DARAJA_FALLBACK_SIMULATION', false)) {
                    \Illuminate\Support\Facades\Log::warning("Daraja STK push returned non-zero code. Falling back to simulation: {$errorMessage}");
                    return $this->stkPushMock($request, $phone);
                }

                return response()->json([
                    'error'  => $errorMessage,
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
                'item_title'          => Str::limit(trim((string) $request->item_title), 120, '') ?: null,
                'quantity'            => max(1, (int) ($request->quantity ?? 1)),
            ]);

            return response()->json([
                'message' => 'M-Pesa STK Push sent. Enter your PIN on your phone.',
                'payment' => $payment,
            ]);
        } catch (\Exception $e) {
            \Illuminate\Support\Facades\Log::error('Daraja STK Push exception: ' . $e->getMessage());

            // If Daraja sandbox credentials expire, are unreachable, or token generation fails, fall back to simulation
            if (env('DARAJA_FALLBACK_SIMULATION', true)) {
                return $this->stkPushMock($request, $phone);
            }

            return response()->json(['error' => $e->getMessage()], 500);
        }
    }

    /** Fetch a Daraja OAuth access token. */
    private function darajaToken(string $baseUrl, string $key, string $secret): ?string
    {
        try {
            $res = Http::withBasicAuth($key, $secret)
                ->timeout(15)
                ->get("{$baseUrl}/oauth/v1/generate?grant_type=client_credentials");

            $token = $res->json('access_token');
            return $token ?: null;
        } catch (\Throwable $e) {
            \Illuminate\Support\Facades\Log::warning('Daraja token request exception: ' . $e->getMessage());
            return null;
        }
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
                if ($resultCode !== null && (int) $resultCode === 0) {
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
                } elseif ($resultCode !== null && (int) $resultCode === 1032) {
                    // Customer closed the PIN prompt themselves — report it as a
                    // cancellation, not a failure, so the app wording stays honest.
                    $payment->update(['status' => 'cancelled']);
                } elseif ($resultCode !== null) {
                    $payment->update(['status' => 'failed']);
                }
                // No ResultCode at all → leave the payment as-is and let the app
                // keep polling instead of showing a wrong final state.
            }
        }

        return response()->json(['result' => 'OK'], 200);
    }

    /**
     * SAFE diagnostic: reports which Daraja config the LIVE server actually
     * sees (booleans only, never the secret values) and whether it can reach
     * the Daraja token endpoint. Use to confirm env vars are set after deploy.
     * GET /payments/mpesa/diag
     */
    public function darajaDiag()
    {
        $cfg       = config('services.daraja');
        $key       = $cfg['consumer_key']    ?? null;
        $secret    = $cfg['consumer_secret'] ?? null;
        $shortcode = $cfg['short_code']      ?? null;
        $passkey   = $cfg['passkey']         ?? null;
        $env       = $cfg['env'] ?? 'sandbox';
        $baseUrl   = $env === 'production' ? $cfg['production_base'] : $cfg['sandbox_base'];

        // Try a real token request to prove the server can reach Safaricom.
        $tokenOk    = false;
        $tokenError = null;
        $tokenLen   = 0;
        if ($key && $secret) {
            try {
                $res   = Http::withBasicAuth($key, $secret)
                    ->timeout(15)
                    ->get("{$baseUrl}/oauth/v1/generate?grant_type=client_credentials");
                $token = $res->json('access_token');
                $tokenOk = (bool) $token;
                $tokenLen = $token ? strlen($token) : 0;
                if (!$tokenOk) {
                    $tokenError = 'HTTP ' . $res->status() . ' ' . ($res->json('errorMessage') ?? substr($res->body(), 0, 120));
                }
            } catch (\Throwable $e) {
                $tokenError = $e->getMessage();
            }
        }

        return response()->json([
            'env'              => $env,
            'base_url'         => $baseUrl,
            'has_consumer_key' => (bool) $key,
            'has_consumer_secret' => (bool) $secret,
            'has_passkey'      => (bool) $passkey,
            'has_shortcode'    => (bool) $shortcode,
            'shortcode'        => $shortcode,
            'callback_url'     => $cfg['callback_url'] ?? null,
            'fallback_simulation' => env('DARAJA_FALLBACK_SIMULATION', false),
            'daraja_reachable' => $tokenOk,
            'token_length'     => $tokenLen,
            'token_error'      => $tokenError,
        ]);
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
                'item_title'          => Str::limit(trim((string) $request->item_title), 120, '') ?: null,
                'quantity'            => max(1, (int) ($request->quantity ?? 1)),
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
            'item_title'   => 'nullable|string|max:120',
            'quantity'     => 'nullable|integer|min:1',
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
                'item_title'          => Str::limit(trim((string) $request->item_title), 120, '') ?: null,
                'quantity'            => max(1, (int) ($request->quantity ?? 1)),
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
            'email'        => 'nullable|email',
            'item_title'   => 'nullable|string|max:120',
            'quantity'     => 'nullable|integer|min:1',
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
                'email'               => $request->email,
                'status'              => 'pending',
                'payment_method'      => 'paypal',
                'paypal_order_id'     => $orderId,
                'booking_type'        => $request->booking_type,
                'booking_id'          => $request->booking_id,
                'item_title'          => Str::limit(trim((string) $request->item_title), 120, '') ?: null,
                'quantity'            => max(1, (int) ($request->quantity ?? 1)),
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
            $this->notifyPaymentCompleted($payment->fresh());

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
            'email'         => 'nullable|email',
            'item_title'    => 'nullable|string|max:120',
            'quantity'      => 'nullable|integer|min:1',
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
                'email'               => $request->email,
                'status'              => 'completed',
                'payment_method'      => 'equity',
                'receipt_number'      => $receiptNumber,
                'booking_type'        => $request->booking_type,
                'booking_id'          => $request->booking_id,
                'item_title'          => Str::limit(trim((string) $request->item_title), 120, '') ?: null,
                'quantity'            => max(1, (int) ($request->quantity ?? 1)),
                'paid_at'             => now(),
            ]);

            sleep(1);

            $this->markBookingComplete($payment);
            $this->notifyPaymentCompleted($payment);

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

            // NOTE: a pending payment is only ever completed by Safaricom —
            // through the async callback or the stkpushquery above. It used to be
            // auto-completed whenever DARAJA_ENV=sandbox, which made the app shout
            // "Payment Successful" while the PIN prompt was still open.
            // Set DARAJA_DEMO_AUTOCONFIRM=true explicitly if you need a scripted
            // demo that skips the PIN (never enable it for real payments).
            if ($payment->status === 'pending'
                && filter_var(env('DARAJA_DEMO_AUTOCONFIRM', false), FILTER_VALIDATE_BOOLEAN)) {
                $receipt = 'QHX' . strtoupper(Str::random(7));
                $payment->update([
                    'status'               => 'completed',
                    'mpesa_receipt_number' => $receipt,
                    'receipt_number'       => $receipt,
                    'paid_at'              => now(),
                ]);
                $this->markBookingComplete($payment->fresh());
                $this->notifyPaymentCompleted($payment->fresh());
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
        $transactionId = trim((string) $transactionId);

        // Only ever look a payment up by a real payment identifier. This used to
        // fall back to booking_id, which is a small integer (often 0 because event
        // ids are Firestore strings) — so one person's receipt link resolved to
        // somebody else's payment and displayed their email, amount and receipt no.
        $refIsRealId = $transactionId !== ''
            && $transactionId !== '0'
            && preg_match('/^EP[0-9A-Z]{6,}$/i', $transactionId);

        if (!$refIsRealId) {
            abort(404, 'Receipt reference is missing or malformed.');
        }

        $payment = Payment::where('transaction_id', $transactionId)
            ->orWhere('receipt_number', $transactionId)
            ->orWhere('mpesa_receipt_number', $transactionId)
            ->latest('id')
            ->firstOrFail();

        $status     = ucfirst($payment->status ?? 'unknown');
        $amount     = 'KES ' . number_format((float) $payment->amount, 2);
        $receipt    = $payment->getDisplayReceipt() ?? 'N/A';
        $gateway    = $payment->getGatewayLabel();
        $method     = $payment->getReceiptLabel();
        $date       = ($payment->paid_at ?? $payment->created_at)?->format('d M Y, H:i') ?? '';
        $email      = $payment->email ?: '';
        $refType    = $payment->booking_type === 'service' ? 'Service Booking' : 'Event Booking';
        $itemName   = $payment->item_title ?: ($payment->booking_type === 'service' ? 'Service booking' : 'Event ticket');
        $quantity   = max(1, (int) ($payment->quantity ?? 1));
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
      <tr><td class="k">Item</td><td class="v">{$esc($itemName)}&nbsp;&times;{$esc($quantity)}</td></tr>
      <tr><td class="k">{$esc($refType)}</td><td class="v">{$esc($payment->transaction_id)}</td></tr>
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
            // Daraja returns ResultCode as a number on some endpoints and as a
            // numeric string on others. Comparing strictly against ints without
            // casting made an OPEN PIN prompt ("1") fall through to the catch-all
            // branch and mark the payment FAILED before the customer typed a PIN.
            $rawCode    = $data['ResultCode'] ?? null;
            $resultCode = is_numeric($rawCode) ? (int) $rawCode : null;
            $resultDesc = strtolower((string) ($data['ResultDesc'] ?? ''));

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
                // In stkpushquery, ResultCode 1 means "The transaction is being
                // processed at initiator" — the STK prompt is still OPEN on the
                // customer's phone waiting for the PIN. Do NOT mark it failed or
                // cancelled here; only trust an explicit cancel in the description.
                if (str_contains($resultDesc, 'cancel')) {
                    $payment->update(['status' => 'cancelled']);
                }
                // Otherwise leave status pending until the PIN is entered,
                // the prompt is cancelled (1032), or it expires (1037).
            } elseif ($resultCode === 1032) {
                // 1032 = Cancelled by customer on their phone
                $payment->update(['status' => 'cancelled']);
            } elseif ($resultCode === 1037 || $resultCode === 2001) {
                // 1037 = Timeout / user took too long to enter PIN
                // 2001 = Invalid PIN or wrong initiator
                $payment->update(['status' => 'failed']);
            } elseif ($resultCode !== null && $resultCode !== 0) {
                // Any other definitive error code from Daraja (e.g. 1001, 1019, 1025).
                // Still guard against "in progress" wordings so an open PIN prompt
                // can never be flipped to failed.
                if (str_contains($resultDesc, 'process')
                    || str_contains($resultDesc, 'pending')
                    || str_contains($resultDesc, 'initiator')) {
                    // leave pending
                } else {
                    $payment->update(['status' => 'failed']);
                }
            }
            // If ResultCode is null (or query returned 'The transaction is being processed'), leave pending
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
                'item_title'          => Str::limit(trim((string) $request->item_title), 120, '') ?: null,
                'quantity'            => max(1, (int) ($request->quantity ?? 1)),
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
                'item_title'          => Str::limit(trim((string) $request->item_title), 120, '') ?: null,
                'quantity'            => max(1, (int) ($request->quantity ?? 1)),
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
        if (!str_starts_with($phone, '254') && !str_starts_with($phone, '255')) {
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
                $booking->update(['status' => 'completed', 'qr_code' => (string) \Illuminate\Support\Str::uuid()]);
                return;
            }

            // The app pays for a Firestore event, so booking_id usually carries an
            // EVENT id (or 0 when that id is a non-numeric document id). Resolve the
            // paying customer strictly by the email/phone captured at checkout — and
            // never fall back to user 1. That fallback used to credit every unknown
            // purchaser's ticket to whoever happened to own id 1, so the buyer saw
            // someone else's bookings (and that person saw tickets he never bought).
            $user  = $this->resolvePayingUser($payment->email, $payment->phone);
            $event = $payment->booking_id ? Event::find($payment->booking_id) : null;

            if (!$user || !$event) {
                \Illuminate\Support\Facades\Log::info(
                    'Payment completed but no matching SQL booking/event/user; '
                    . 'ticket is issued to the buyer in the app, no booking attributed.',
                    [
                        'payment_id'    => $payment->id,
                        'email'         => $payment->email,
                        'has_user'      => (bool) $user,
                        'has_event_row' => (bool) $event,
                    ]
                );
                return;
            }

            Booking::create([
                'event_id' => $event->id,
                'user_id'  => $user->id,
                'quantity' => 1,
                'amount'   => $payment->amount,
                'status'   => 'completed',
                'qr_code'  => (string) \Illuminate\Support\Str::uuid(),
            ]);
        } elseif ($payment->booking_type === 'service') {
            $booking = ServiceBooking::find($payment->booking_id);
            if ($booking) {
                $booking->update(['status' => 'paid']);
            }
        }
    }

    /**
     * Identify the customer who actually paid, using ONLY exact identifiers.
     * Returns null when nobody matches — callers must then refuse to attribute
     * the booking/receipt to any user rather than guessing.
     */
    private function resolvePayingUser(?string $email, ?string $phone): ?User
    {
        $email = strtolower(trim((string) $email));
        if ($email !== '') {
            $user = User::whereRaw('LOWER(email) = ?', [$email])->first();
            if ($user) return $user;
        }

        $normalized = $this->normalizeKenyaPhone((string) $phone);
        if (strlen($normalized) >= 11 && $normalized !== '254') {
            // Match the stored format exactly (full international or local 07xx),
            // never a loose LIKE '%' suffix scan that could hit an unrelated account.
            $local = '0' . substr($normalized, 3);
            $user  = User::where('phone', $normalized)
                ->orWhere('phone', $local)
                ->orWhere('phone', '+' . $normalized)
                ->first();
            if ($user) return $user;
        }

        return null;
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

        // ── Confirmation email ──────────────────────────────────
        // We only ever mail the address the BUYER typed at checkout. The old
        // "match any user whose phone ends with these digits" guesswork is what
        // sent other people's tickets to whichever account owned the phone prefix
        // (and credited bookings to user id 1). No guess, no email.
        $email = trim((string) $payment->email);
        if ($email === '') {
            \Illuminate\Support\Facades\Log::info(
                'Payment completed but no buyer email captured; skipped confirmation email.',
                ['payment_id' => $payment->id]
            );
            return;
        }

        $buyer    = $this->resolvePayingUser($email, $payment->phone);
        $name     = $buyer?->name ?? '';
        $itemName = $payment->item_title;

        // Fall back to the booking relations when the app did not send a title.
        if (!$itemName) {
            if ($payment->booking_type === 'event') {
                $booking = Booking::with('event')->find($payment->booking_id);
                $itemName = $booking?->event?->title;
            } else {
                $booking = ServiceBooking::with('service')->find($payment->booking_id);
                $itemName = $itemName ?? ($booking?->service?->name ?? $booking?->service?->title);
            }
        }

        $quantity = max(1, (int) ($payment->quantity ?? 1));

        // Never double-send: a payment can reach 'completed' from the async
        // callback AND from a stkpushquery poll in the same minute.
        $dedupeKey = 'ticket_mail_' . $payment->id;
        try {
            if (app('cache')->store('file')->has($dedupeKey)) {
                return;
            }
            app('cache')->store('file')->put($dedupeKey, 1, now()->addDay());
        } catch (\Throwable $e) {
            // Cache unavailable — send anyway; one email is better than none.
        }

        try {
            $softCopyUrl = $this->receiptUrl($payment->transaction_id);

            if ($payment->booking_type === 'event') {
                // 🎉 Congratulations — ticket purchased, with a downloadable pass.
                app(BrevoMailService::class)->sendBookingConfirmation(
                    $email,
                    $name,
                    $itemName,
                    $payment->amount,
                    $payment->transaction_id,
                    $quantity,
                    $softCopyUrl
                );
                \Illuminate\Support\Facades\Log::info(
                    "Booking confirmation email sent for payment #{$payment->transaction_id} to {$email}"
                );
            } else {
                app(BrevoMailService::class)->sendReceipt(
                    $email,
                    $name,
                    $payment->amount,
                    $payment->transaction_id,
                    $itemName,
                    $softCopyUrl
                );
                \Illuminate\Support\Facades\Log::info(
                    "Receipt email sent for payment #{$payment->transaction_id} to {$email}"
                );
            }
        } catch (\Throwable $e) {
            \Illuminate\Support\Facades\Log::error('Confirmation email failed: ' . $e->getMessage());
        }
    }

    /** Public, printable receipt / ticket soft-copy link. */
    private function receiptUrl(string $transactionId): string
    {
        $base = rtrim((string) (config('app.url') ?: env('APP_URL', '')), '/');
        if ($base === '') {
            $base = rtrim(url('/'), '/');
        }
        // Render/Heroku sometimes expose APP_URL as a bare host ("myapp.onrender.com").
        // An email link without a scheme is dead, so normalise it here.
        if (!preg_match('#^https?://#i', $base)) {
            $base = 'https://' . preg_replace('#^/+#', '', $base);
        }
        if (!str_ends_with($base, '/api')) {
            $base .= '/api';
        }

        return $base . '/payments/receipt/' . urlencode($transactionId);
    }
}
