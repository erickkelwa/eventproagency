<?php

namespace App\Services;

use GuzzleHttp\Client;
use Illuminate\Support\Facades\Log;

class BrevoMailService
{
    protected $client;
    protected $apiKey;

    public function __construct()
    {
        $this->client = new Client(['base_uri' => 'https://api.brevo.com/v3/']);
        $this->apiKey = env('BREVO_API_KEY');
    }

    public function sendReceipt($email, $name, $amount, $transactionId)
    {
        $displayName   = $name ?: 'Valued Customer';
        $formattedAmt  = 'KES ' . number_format((float) $amount, 2);
        $date          = now()->format('F j, Y \a\t g:i A');
        $html          = $this->buildReceiptHtml($displayName, $formattedAmt, $transactionId, $date);

        try {
            $response = $this->client->post('smtp/email', [
                'headers' => [
                    'api-key'      => $this->apiKey,
                    'Content-Type' => 'application/json',
                ],
                'json' => [
                    'sender'      => ['name' => 'EventPro Agency', 'email' => 'erickkelwa9@gmail.com'],
                    'to'          => [['email' => $email, 'name' => $displayName]],
                    'subject'     => '✅ Payment Confirmed — EventPro Agency (#' . $transactionId . ')',
                    'htmlContent' => $html,
                ],
            ]);
            return json_decode($response->getBody(), true);
        } catch (\Exception $e) {
            Log::error('Brevo Mail Error: ' . $e->getMessage());
            return false;
        }
    }

    public function sendWelcome($email, $name)
    {
        $displayName = $name ?: 'there';
        $html        = $this->buildWelcomeHtml($displayName);

        try {
            $response = $this->client->post('smtp/email', [
                'headers' => [
                    'api-key'      => $this->apiKey,
                    'Content-Type' => 'application/json',
                ],
                'json' => [
                    'sender'      => ['name' => 'EventPro Agency', 'email' => 'erickkelwa9@gmail.com'],
                    'to'          => [['email' => $email, 'name' => $displayName]],
                    'subject'     => '🎉 Welcome to EventPro Agency!',
                    'htmlContent' => $html,
                ],
            ]);
            return json_decode($response->getBody(), true);
        } catch (\Exception $e) {
            Log::error('Brevo Welcome Email Error: ' . $e->getMessage());
            return false;
        }
    }

    private function buildWelcomeHtml(string $name): string
    {
        return <<<HTML
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  <title>Welcome to EventPro Agency</title>
</head>
<body style="margin:0;padding:0;background-color:#f0f4f8;font-family:'Segoe UI',Arial,sans-serif;">

  <table width="100%" cellpadding="0" cellspacing="0" style="background:#f0f4f8;padding:40px 0;">
    <tr>
      <td align="center">
        <table width="600" cellpadding="0" cellspacing="0" style="max-width:600px;width:100%;background:#ffffff;border-radius:16px;overflow:hidden;box-shadow:0 4px 24px rgba(0,0,0,0.08);">

          <!-- Header -->
          <tr>
            <td style="background:linear-gradient(135deg,#1a1a2e 0%,#16213e 50%,#0f3460 100%);padding:48px 40px 40px;text-align:center;">
              <div style="display:inline-block;background:rgba(255,255,255,0.1);border-radius:12px;padding:10px 20px;margin-bottom:16px;">
                <span style="color:#e94560;font-size:22px;font-weight:800;letter-spacing:2px;">EVENT</span><span style="color:#ffffff;font-size:22px;font-weight:800;letter-spacing:2px;">PRO</span>
              </div>
              <p style="color:rgba(255,255,255,0.6);font-size:13px;margin:4px 0 24px;letter-spacing:1px;text-transform:uppercase;">Agency</p>
              <div style="font-size:56px;margin-bottom:16px;">🎉</div>
              <h1 style="color:#ffffff;font-size:28px;font-weight:700;margin:0 0 10px;">Welcome Aboard!</h1>
              <p style="color:rgba(255,255,255,0.7);font-size:15px;margin:0;">Your account has been created successfully.</p>
            </td>
          </tr>

          <!-- Body -->
          <tr>
            <td style="padding:40px 40px 24px;">
              <p style="color:#1a1a2e;font-size:16px;font-weight:600;margin:0 0 12px;">Hi {$name} 👋</p>
              <p style="color:#555;font-size:14px;line-height:1.8;margin:0 0 24px;">
                We're thrilled to have you join <strong>EventPro Agency</strong>! You now have access to a world of unforgettable events and professional services.
              </p>

              <!-- Feature cards -->
              <table width="100%" cellpadding="0" cellspacing="0">
                <tr>
                  <td width="33%" style="padding:0 6px 0 0;vertical-align:top;">
                    <div style="background:#f8faff;border:1px solid #e2e8f0;border-radius:12px;padding:20px;text-align:center;">
                      <div style="font-size:28px;margin-bottom:8px;">🎪</div>
                      <p style="color:#1a1a2e;font-size:13px;font-weight:600;margin:0 0 4px;">Browse Events</p>
                      <p style="color:#888;font-size:12px;margin:0;line-height:1.5;">Discover and book amazing events</p>
                    </div>
                  </td>
                  <td width="33%" style="padding:0 3px;vertical-align:top;">
                    <div style="background:#f8faff;border:1px solid #e2e8f0;border-radius:12px;padding:20px;text-align:center;">
                      <div style="font-size:28px;margin-bottom:8px;">⚡</div>
                      <p style="color:#1a1a2e;font-size:13px;font-weight:600;margin:0 0 4px;">Easy Payments</p>
                      <p style="color:#888;font-size:12px;margin:0;line-height:1.5;">Pay securely via M-Pesa</p>
                    </div>
                  </td>
                  <td width="33%" style="padding:0 0 0 6px;vertical-align:top;">
                    <div style="background:#f8faff;border:1px solid #e2e8f0;border-radius:12px;padding:20px;text-align:center;">
                      <div style="font-size:28px;margin-bottom:8px;">🏆</div>
                      <p style="color:#1a1a2e;font-size:13px;font-weight:600;margin:0 0 4px;">Pro Services</p>
                      <p style="color:#888;font-size:12px;margin:0;line-height:1.5;">Access premium event services</p>
                    </div>
                  </td>
                </tr>
              </table>
            </td>
          </tr>

          <!-- CTA -->
          <tr>
            <td style="padding:8px 40px 40px;text-align:center;">
              <p style="color:#555;font-size:14px;line-height:1.7;margin:0 0 24px;">
                Start exploring events near you and let us help make every occasion extraordinary.
              </p>
              <a href="mailto:erickkelwa9@gmail.com"
                 style="display:inline-block;background:linear-gradient(135deg,#e94560,#c0392b);color:#ffffff;font-size:15px;font-weight:700;padding:16px 40px;border-radius:10px;text-decoration:none;letter-spacing:0.5px;">
                Get Started 🚀
              </a>
            </td>
          </tr>

          <!-- Divider -->
          <tr>
            <td style="padding:0 40px;">
              <hr style="border:none;border-top:1px solid #e2e8f0;margin:0;"/>
            </td>
          </tr>

          <!-- Footer -->
          <tr>
            <td style="padding:24px 40px;text-align:center;">
              <p style="color:#aaa;font-size:12px;margin:0 0 4px;">© EventPro Agency. All rights reserved.</p>
              <p style="color:#ccc;font-size:11px;margin:0;">
                You received this email because you created an account with us.
              </p>
            </td>
          </tr>

        </table>
      </td>
    </tr>
  </table>

</body>
</html>
HTML;
    }

(string $name, string $amount, string $transactionId, string $date): string
    {
        return <<<HTML
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  <title>Payment Receipt</title>
</head>
<body style="margin:0;padding:0;background-color:#f0f4f8;font-family:'Segoe UI',Arial,sans-serif;">

  <!-- Wrapper -->
  <table width="100%" cellpadding="0" cellspacing="0" style="background:#f0f4f8;padding:40px 0;">
    <tr>
      <td align="center">
        <table width="600" cellpadding="0" cellspacing="0" style="max-width:600px;width:100%;background:#ffffff;border-radius:16px;overflow:hidden;box-shadow:0 4px 24px rgba(0,0,0,0.08);">

          <!-- Header -->
          <tr>
            <td style="background:linear-gradient(135deg,#1a1a2e 0%,#16213e 50%,#0f3460 100%);padding:40px 40px 32px;text-align:center;">
              <div style="display:inline-block;background:rgba(255,255,255,0.1);border-radius:12px;padding:10px 20px;margin-bottom:16px;">
                <span style="color:#e94560;font-size:22px;font-weight:800;letter-spacing:2px;">EVENT</span><span style="color:#ffffff;font-size:22px;font-weight:800;letter-spacing:2px;">PRO</span>
              </div>
              <p style="color:rgba(255,255,255,0.6);font-size:13px;margin:4px 0 0;letter-spacing:1px;text-transform:uppercase;">Agency</p>
              <div style="margin-top:24px;background:rgba(255,255,255,0.08);border-radius:50%;width:64px;height:64px;margin-left:auto;margin-right:auto;display:flex;align-items:center;justify-content:center;">
                <span style="font-size:32px;line-height:64px;">✅</span>
              </div>
              <h1 style="color:#ffffff;font-size:26px;font-weight:700;margin:16px 0 8px;">Payment Confirmed!</h1>
              <p style="color:rgba(255,255,255,0.7);font-size:14px;margin:0;">Your transaction was processed successfully.</p>
            </td>
          </tr>

          <!-- Greeting -->
          <tr>
            <td style="padding:32px 40px 0;">
              <p style="color:#1a1a2e;font-size:16px;margin:0 0 8px;">Hi <strong>{$name}</strong>,</p>
              <p style="color:#555;font-size:14px;line-height:1.6;margin:0;">
                Thank you for your payment. Below is your official receipt. Please keep it for your records.
              </p>
            </td>
          </tr>

          <!-- Receipt Card -->
          <tr>
            <td style="padding:24px 40px;">
              <table width="100%" cellpadding="0" cellspacing="0" style="background:#f8faff;border:1px solid #e2e8f0;border-radius:12px;overflow:hidden;">

                <!-- Amount highlight -->
                <tr>
                  <td colspan="2" style="background:linear-gradient(135deg,#e94560,#c0392b);padding:20px 24px;text-align:center;">
                    <p style="color:rgba(255,255,255,0.8);font-size:12px;margin:0 0 4px;text-transform:uppercase;letter-spacing:1px;">Amount Paid</p>
                    <p style="color:#ffffff;font-size:32px;font-weight:800;margin:0;">{$amount}</p>
                  </td>
                </tr>

                <!-- Details rows -->
                <tr>
                  <td style="padding:14px 24px;color:#888;font-size:13px;border-bottom:1px solid #e2e8f0;width:40%;">Transaction ID</td>
                  <td style="padding:14px 24px;color:#1a1a2e;font-size:13px;font-weight:600;border-bottom:1px solid #e2e8f0;font-family:monospace;">#{$transactionId}</td>
                </tr>
                <tr>
                  <td style="padding:14px 24px;color:#888;font-size:13px;border-bottom:1px solid #e2e8f0;">Date & Time</td>
                  <td style="padding:14px 24px;color:#1a1a2e;font-size:13px;font-weight:600;border-bottom:1px solid #e2e8f0;">{$date}</td>
                </tr>
                <tr>
                  <td style="padding:14px 24px;color:#888;font-size:13px;">Status</td>
                  <td style="padding:14px 24px;">
                    <span style="background:#dcfce7;color:#16a34a;font-size:12px;font-weight:700;padding:4px 12px;border-radius:20px;text-transform:uppercase;letter-spacing:0.5px;">✓ Paid</span>
                  </td>
                </tr>
              </table>
            </td>
          </tr>

          <!-- Message -->
          <tr>
            <td style="padding:0 40px 32px;">
              <p style="color:#555;font-size:14px;line-height:1.7;margin:0;">
                We're excited to work with you to make your event an unforgettable experience. 
                If you have any questions, feel free to reply to this email — we're always happy to help.
              </p>
            </td>
          </tr>

          <!-- CTA Button -->
          <tr>
            <td style="padding:0 40px 40px;text-align:center;">
              <a href="mailto:erickkelwa9@gmail.com"
                 style="display:inline-block;background:linear-gradient(135deg,#1a1a2e,#0f3460);color:#ffffff;font-size:14px;font-weight:600;padding:14px 32px;border-radius:8px;text-decoration:none;letter-spacing:0.5px;">
                Contact Us
              </a>
            </td>
          </tr>

          <!-- Divider -->
          <tr>
            <td style="padding:0 40px;">
              <hr style="border:none;border-top:1px solid #e2e8f0;margin:0;" />
            </td>
          </tr>

          <!-- Footer -->
          <tr>
            <td style="padding:24px 40px;text-align:center;">
              <p style="color:#aaa;font-size:12px;margin:0 0 4px;">
                © {$date} EventPro Agency. All rights reserved.
              </p>
              <p style="color:#ccc;font-size:11px;margin:0;">
                This is an automated receipt. Please do not reply directly to this message.
              </p>
            </td>
          </tr>

        </table>
      </td>
    </tr>
  </table>

</body>
</html>
HTML;
    }
}
