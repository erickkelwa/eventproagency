<?php

namespace App\Services;

use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Facades\Log;

class BrevoMailService
{
    protected string $fromEmail;
    protected string $fromName;

    public function __construct()
    {
        $this->fromEmail = config('mail.from.address', 'erickkelwa9@gmail.com');
        $this->fromName  = config('mail.from.name', 'EventPro Agency');
    }

    // ── Payment Receipt ──────────────────────────────────────
    /**
     * @param string      $email         Recipient email
     * @param string      $name          Recipient display name
     * @param float       $amount        Amount paid (numeric)
     * @param string      $transactionId Transaction / EP reference ID
     * @param string|null $eventName     Optional event / service name
     * @param string|null $receiptUrl    Full URL to the printable HTML receipt page
     */
    public function sendReceipt($email, $name, $amount, $transactionId, $eventName = null, $receiptUrl = null)
    {
        $displayName  = $name ?: 'Valued Customer';
        $formattedAmt = 'KES ' . number_format((float) $amount, 2);
        $date         = now()->format('F j, Y \a\t g:i A');
        $html         = $this->buildReceiptHtml($displayName, $formattedAmt, $transactionId, $date, $eventName, $receiptUrl);
        $subject      = $eventName
            ? '🎟️ Ticket Confirmed — ' . $eventName . ' (#' . $transactionId . ')'
            : '✅ Payment Confirmed — EventPro Agency (#' . $transactionId . ')';

        try {
            Mail::html($html, function ($message) use ($email, $displayName, $subject) {
                $message->to($email, $displayName)
                        ->subject($subject)
                        ->from($this->fromEmail, $this->fromName);
            });
            Log::info('Receipt email sent to ' . $email);
            return true;
        } catch (\Exception $e) {
            Log::error('SMTP Receipt Email Error: ' . $e->getMessage());
            return false;
        }
    }

    // ── Booking Confirmation (🎉 Congratulations + soft-copy ticket) ──
    /**
     * Sent the moment an EVENT payment completes: congratulates the buyer,
     * confirms the ticket and links a downloadable/printable soft copy.
     *
     * @param string      $email         Buyer email (captured at checkout)
     * @param string      $name          Buyer display name
     * @param string|null $eventName     Event / ticket title
     * @param float       $amount        Amount paid
     * @param string      $transactionId EP transaction reference (ticket number)
     * @param int         $quantity      Number of tickets bought
     * @param string|null $softCopyUrl   Printable ticket/receipt page
     */
    public function sendBookingConfirmation(
        $email,
        $name,
        $eventName,
        $amount,
        $transactionId,
        $quantity = 1,
        $softCopyUrl = null
    ) {
        $displayName = $name ?: 'Valued Customer';
        $eventLabel  = $eventName ?: 'your event';
        $formattedAmt = 'KES ' . number_format((float) $amount, 2);
        $ticketCount  = max(1, (int) $quantity);
        $date         = now()->format('F j, Y \a\t g:i A');
        $html         = $this->buildBookingConfirmationHtml(
            $displayName, $eventLabel, $formattedAmt, $transactionId, $ticketCount, $date, $softCopyUrl
        );
        $subject = '🎉 Congratulations! Your ticket for ' . $eventLabel . ' is confirmed (#' . $transactionId . ')';

        try {
            Mail::html($html, function ($message) use ($email, $displayName, $subject) {
                $message->to($email, $displayName)
                        ->subject($subject)
                        ->from($this->fromEmail, $this->fromName);
            });
            Log::info('Booking confirmation email sent to ' . $email);
            return true;
        } catch (\Exception $e) {
            Log::error('SMTP Booking Confirmation Email Error: ' . $e->getMessage());
            return false;
        }
    }

    // ── Welcome Email ────────────────────────────────────────
    public function sendWelcome($email, $name)
    {
        $displayName = $name ?: 'there';
        $html        = $this->buildWelcomeHtml($displayName);
        $subject     = '🎉 Welcome to EventPro Agency!';

        try {
            Mail::html($html, function ($message) use ($email, $displayName, $subject) {
                $message->to($email, $displayName)
                        ->subject($subject)
                        ->from($this->fromEmail, $this->fromName);
            });
            Log::info('Welcome email sent to ' . $email);
            return true;
        } catch (\Exception $e) {
            Log::error('SMTP Welcome Email Error: ' . $e->getMessage());
            return false;
        }
    }

    // ── HTML Templates ───────────────────────────────────────
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
              <a href="mailto:{$this->fromEmail}"
                 style="display:inline-block;background:linear-gradient(135deg,#e94560,#c0392b);color:#ffffff;font-size:15px;font-weight:700;padding:16px 40px;border-radius:10px;text-decoration:none;letter-spacing:0.5px;">
                Get Started 🚀
              </a>
            </td>
          </tr>

          <!-- Divider -->
          <tr><td style="padding:0 40px;"><hr style="border:none;border-top:1px solid #e2e8f0;margin:0;"/></td></tr>

          <!-- Footer -->
          <tr>
            <td style="padding:24px 40px;text-align:center;">
              <p style="color:#aaa;font-size:12px;margin:0 0 4px;">© EventPro Agency. All rights reserved.</p>
              <p style="color:#ccc;font-size:11px;margin:0;">You received this email because you created an account with us.</p>
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

    private function buildReceiptHtml(string $name, string $amount, string $transactionId, string $date, ?string $eventName = null, ?string $receiptUrl = null): string
    {
        $eventRow = '';
        if ($eventName) {
            $safeEvent = htmlspecialchars($eventName, ENT_QUOTES, 'UTF-8');
            $eventRow = <<<ROW
                <tr>
                  <td style="padding:14px 24px;color:#888;font-size:13px;border-bottom:1px solid #e2e8f0;">Event / Ticket</td>
                  <td style="padding:14px 24px;color:#1a1a2e;font-size:13px;font-weight:600;border-bottom:1px solid #e2e8f0;">{$safeEvent}</td>
                </tr>
ROW;
        }

        $mainHeading = $eventName ? '🎟️ Ticket Confirmed!' : 'Payment Confirmed!';

        // ── Download Receipt Button (only shown when a URL is provided) ──
        $downloadBtn = '';
        if ($receiptUrl) {
            $safeUrl    = htmlspecialchars($receiptUrl, ENT_QUOTES, 'UTF-8');
            $downloadBtn = <<<BTN
          <!-- Download Receipt CTA -->
          <tr>
            <td style="padding:8px 40px 32px;text-align:center;">
              <a href="{$safeUrl}" target="_blank"
                 style="display:inline-block;background:linear-gradient(135deg,#e94560,#c0392b);color:#ffffff;font-size:15px;font-weight:700;padding:16px 40px;border-radius:10px;text-decoration:none;letter-spacing:0.5px;box-shadow:0 4px 14px rgba(233,69,96,0.4);">
                📥 &nbsp;Download / View Receipt
              </a>
              <p style="color:#999;font-size:11px;margin:10px 0 0;">Opens in your browser. You can print or save as PDF from there.</p>
            </td>
          </tr>
BTN;
        }

        return <<<HTML
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  <title>Payment Receipt — EventPro Agency</title>
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
              <div style="margin-top:24px;width:72px;height:72px;margin-left:auto;margin-right:auto;background:rgba(255,255,255,0.12);border-radius:50%;line-height:72px;text-align:center;">
                <span style="font-size:36px;">✅</span>
              </div>
              <h1 style="color:#ffffff;font-size:26px;font-weight:700;margin:16px 0 8px;">{$mainHeading}</h1>
              <p style="color:rgba(255,255,255,0.75);font-size:14px;margin:0;">Your payment was processed successfully.</p>
            </td>
          </tr>

          <!-- Greeting -->
          <tr>
            <td style="padding:32px 40px 0;">
              <p style="color:#1a1a2e;font-size:16px;margin:0 0 8px;">Hi <strong>{$name}</strong>,</p>
              <p style="color:#555;font-size:14px;line-height:1.6;margin:0;">
                Thank you for your payment! Your booking is now confirmed. Here is your official receipt — please keep it for your records.
              </p>
            </td>
          </tr>

          <!-- Receipt Card -->
          <tr>
            <td style="padding:24px 40px 16px;">
              <table width="100%" cellpadding="0" cellspacing="0" style="background:#f8faff;border:1px solid #e2e8f0;border-radius:12px;overflow:hidden;">

                <!-- Amount highlight -->
                <tr>
                  <td colspan="2" style="background:linear-gradient(135deg,#e94560,#c0392b);padding:22px 24px;text-align:center;">
                    <p style="color:rgba(255,255,255,0.85);font-size:12px;margin:0 0 4px;text-transform:uppercase;letter-spacing:1.5px;">Amount Paid</p>
                    <p style="color:#ffffff;font-size:34px;font-weight:800;margin:0;">{$amount}</p>
                  </td>
                </tr>

                <!-- Details rows -->
                {$eventRow}
                <tr>
                  <td style="padding:14px 24px;color:#888;font-size:13px;border-bottom:1px solid #e2e8f0;width:42%;">Transaction ID</td>
                  <td style="padding:14px 24px;color:#1a1a2e;font-size:13px;font-weight:700;border-bottom:1px solid #e2e8f0;font-family:monospace;">#{$transactionId}</td>
                </tr>
                <tr>
                  <td style="padding:14px 24px;color:#888;font-size:13px;border-bottom:1px solid #e2e8f0;">Date &amp; Time</td>
                  <td style="padding:14px 24px;color:#1a1a2e;font-size:13px;font-weight:600;border-bottom:1px solid #e2e8f0;">{$date}</td>
                </tr>
                <tr>
                  <td style="padding:14px 24px;color:#888;font-size:13px;">Payment Status</td>
                  <td style="padding:14px 24px;">
                    <span style="background:#dcfce7;color:#16a34a;font-size:12px;font-weight:700;padding:5px 14px;border-radius:20px;text-transform:uppercase;letter-spacing:0.5px;">✓ Paid &amp; Confirmed</span>
                  </td>
                </tr>
              </table>
            </td>
          </tr>

          {$downloadBtn}

          <!-- Divider -->
          <tr><td style="padding:0 40px;"><hr style="border:none;border-top:1px solid #e2e8f0;margin:0;" /></td></tr>

          <!-- What's next section -->
          <tr>
            <td style="padding:28px 40px;">
              <p style="color:#1a1a2e;font-size:15px;font-weight:700;margin:0 0 12px;">What's next?</p>
              <table width="100%" cellpadding="0" cellspacing="0">
                <tr>
                  <td style="padding:8px 0;vertical-align:top;">
                    <span style="display:inline-block;background:#e94560;color:#fff;border-radius:50%;width:22px;height:22px;line-height:22px;text-align:center;font-size:12px;font-weight:700;margin-right:10px;">1</span>
                    <span style="color:#555;font-size:13px;">Open the <strong>EventPro app</strong> and go to <em>My Tickets</em>.</span>
                  </td>
                </tr>
                <tr>
                  <td style="padding:8px 0;vertical-align:top;">
                    <span style="display:inline-block;background:#e94560;color:#fff;border-radius:50%;width:22px;height:22px;line-height:22px;text-align:center;font-size:12px;font-weight:700;margin-right:10px;">2</span>
                    <span style="color:#555;font-size:13px;">Show your <strong>QR code ticket</strong> at the venue entrance for fast check-in.</span>
                  </td>
                </tr>
                <tr>
                  <td style="padding:8px 0;vertical-align:top;">
                    <span style="display:inline-block;background:#e94560;color:#fff;border-radius:50%;width:22px;height:22px;line-height:22px;text-align:center;font-size:12px;font-weight:700;margin-right:10px;">3</span>
                    <span style="color:#555;font-size:13px;">Download and keep this receipt for your personal records.</span>
                  </td>
                </tr>
              </table>
            </td>
          </tr>

          <!-- Divider -->
          <tr><td style="padding:0 40px;"><hr style="border:none;border-top:1px solid #e2e8f0;margin:0;" /></td></tr>

          <!-- Contact CTA -->
          <tr>
            <td style="padding:24px 40px;text-align:center;">
              <p style="color:#555;font-size:13px;margin:0 0 14px;">Have questions about your booking?</p>
              <a href="mailto:{$this->fromEmail}"
                 style="display:inline-block;background:linear-gradient(135deg,#1a1a2e,#0f3460);color:#ffffff;font-size:13px;font-weight:600;padding:12px 28px;border-radius:8px;text-decoration:none;">
                ✉️ &nbsp;Contact Support
              </a>
            </td>
          </tr>

          <!-- Footer -->
          <tr>
            <td style="padding:20px 40px 32px;text-align:center;background:#f8faff;border-top:1px solid #e2e8f0;">
              <p style="color:#aaa;font-size:12px;margin:0 0 4px;">© EventPro Agency. All rights reserved.</p>
              <p style="color:#ccc;font-size:11px;margin:0;">This is an automated receipt. Please do not reply directly to this message.</p>
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

    private function buildBookingConfirmationHtml(
        string $name,
        string $eventName,
        string $amount,
        string $transactionId,
        int $quantity,
        string $date,
        ?string $softCopyUrl = null
    ): string {
        $safeEvent = htmlspecialchars($eventName, ENT_QUOTES, 'UTF-8');
        $safeName  = htmlspecialchars($name, ENT_QUOTES, 'UTF-8');
        $safeRef   = htmlspecialchars($transactionId, ENT_QUOTES, 'UTF-8');

        $ticketLine = $quantity > 1
            ? '<strong>' . $quantity . ' tickets</strong> are confirmed for this event. Show one QR code per entry, or split them with your group.'
            : 'Your <strong>1 ticket</strong> is confirmed. Show the QR code at the venue entrance for fast check-in.';

        $softCopyBtn = '';
        if ($softCopyUrl) {
            $safeUrl   = htmlspecialchars($softCopyUrl, ENT_QUOTES, 'UTF-8');
            $softCopyBtn = <<<BTN
          <!-- Soft copy CTA -->
          <tr>
            <td style="padding:8px 40px 12px;text-align:center;">
              <a href="{$safeUrl}" target="_blank"
                 style="display:inline-block;background:linear-gradient(135deg,#e94560,#c0392b);color:#ffffff;font-size:15px;font-weight:700;padding:16px 40px;border-radius:10px;text-decoration:none;letter-spacing:0.5px;box-shadow:0 4px 14px rgba(233,69,96,0.4);">
                🎟️ &nbsp;Download My Ticket (Soft Copy)
              </a>
              <p style="color:#999;font-size:11px;margin:10px 0 0;">Opens in your browser &mdash; print it or save it as a PDF.</p>
            </td>
          </tr>
BTN;
        }

        return <<<HTML
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  <title>Ticket Confirmed — EventPro Agency</title>
</head>
<body style="margin:0;padding:0;background-color:#f0f4f8;font-family:'Segoe UI',Arial,sans-serif;">

  <table width="100%" cellpadding="0" cellspacing="0" style="background:#f0f4f8;padding:40px 0;">
    <tr>
      <td align="center">
        <table width="600" cellpadding="0" cellspacing="0" style="max-width:600px;width:100%;background:#ffffff;border-radius:16px;overflow:hidden;box-shadow:0 4px 24px rgba(0,0,0,0.08);">

          <!-- Header -->
          <tr>
            <td style="background:linear-gradient(135deg,#1a1a2e 0%,#16213e 50%,#0f3460 100%);padding:44px 40px 36px;text-align:center;">
              <div style="display:inline-block;background:rgba(255,255,255,0.1);border-radius:12px;padding:10px 20px;margin-bottom:16px;">
                <span style="color:#e94560;font-size:22px;font-weight:800;letter-spacing:2px;">EVENT</span><span style="color:#ffffff;font-size:22px;font-weight:800;letter-spacing:2px;">PRO</span>
              </div>
              <p style="color:rgba(255,255,255,0.6);font-size:13px;margin:4px 0 20px;letter-spacing:1px;text-transform:uppercase;">Agency</p>
              <div style="font-size:54px;margin-bottom:10px;">🎉</div>
              <h1 style="color:#ffffff;font-size:28px;font-weight:800;margin:0 0 10px;">Congratulations, you're in!</h1>
              <p style="color:rgba(255,255,255,0.8);font-size:15px;margin:0;line-height:1.6;">
                Your ticket for <strong style="color:#ffffff;">{$safeEvent}</strong> has been booked successfully.
              </p>
            </td>
          </tr>

          <!-- Greeting -->
          <tr>
            <td style="padding:32px 40px 0;">
              <p style="color:#1a1a2e;font-size:16px;margin:0 0 8px;">Hi <strong>{$safeName}</strong>,</p>
              <p style="color:#555;font-size:14px;line-height:1.7;margin:0;">
                Thank you for booking with EventPro Agency. Payment is confirmed and your spot is reserved.
                {$ticketLine}
              </p>
            </td>
          </tr>

          <!-- Ticket card -->
          <tr>
            <td style="padding:24px 40px 16px;">
              <table width="100%" cellpadding="0" cellspacing="0" style="background:#f8faff;border:1px solid #e2e8f0;border-radius:12px;overflow:hidden;">
                <tr>
                  <td colspan="2" style="background:linear-gradient(135deg,#e94560,#c0392b);padding:22px 24px;text-align:center;">
                    <p style="color:rgba(255,255,255,0.85);font-size:12px;margin:0 0 4px;text-transform:uppercase;letter-spacing:1.5px;">Amount Paid</p>
                    <p style="color:#ffffff;font-size:34px;font-weight:800;margin:0;">{$amount}</p>
                  </td>
                </tr>
                <tr>
                  <td style="padding:14px 24px;color:#888;font-size:13px;border-bottom:1px solid #e2e8f0;width:42%;">Event / Ticket</td>
                  <td style="padding:14px 24px;color:#1a1a2e;font-size:13px;font-weight:600;border-bottom:1px solid #e2e8f0;">{$safeEvent}</td>
                </tr>
                <tr>
                  <td style="padding:14px 24px;color:#888;font-size:13px;border-bottom:1px solid #e2e8f0;">Tickets</td>
                  <td style="padding:14px 24px;color:#1a1a2e;font-size:13px;font-weight:600;border-bottom:1px solid #e2e8f0;">{$quantity}</td>
                </tr>
                <tr>
                  <td style="padding:14px 24px;color:#888;font-size:13px;border-bottom:1px solid #e2e8f0;">Booking Ref</td>
                  <td style="padding:14px 24px;color:#1a1a2e;font-size:13px;font-weight:700;border-bottom:1px solid #e2e8f0;font-family:monospace;">#{$safeRef}</td>
                </tr>
                <tr>
                  <td style="padding:14px 24px;color:#888;font-size:13px;border-bottom:1px solid #e2e8f0;">Date &amp; Time</td>
                  <td style="padding:14px 24px;color:#1a1a2e;font-size:13px;font-weight:600;border-bottom:1px solid #e2e8f0;">{$date}</td>
                </tr>
                <tr>
                  <td style="padding:14px 24px;color:#888;font-size:13px;">Status</td>
                  <td style="padding:14px 24px;">
                    <span style="background:#dcfce7;color:#16a34a;font-size:12px;font-weight:700;padding:5px 14px;border-radius:20px;text-transform:uppercase;letter-spacing:0.5px;">✓ Confirmed</span>
                  </td>
                </tr>
              </table>
            </td>
          </tr>

          {$softCopyBtn}

          <!-- Divider -->
          <tr><td style="padding:0 40px;"><hr style="border:none;border-top:1px solid #e2e8f0;margin:16px 0 0;" /></td></tr>

          <!-- What's next -->
          <tr>
            <td style="padding:26px 40px;">
              <p style="color:#1a1a2e;font-size:15px;font-weight:700;margin:0 0 12px;">What happens next?</p>
              <table width="100%" cellpadding="0" cellspacing="0">
                <tr>
                  <td style="padding:8px 0;vertical-align:top;">
                    <span style="display:inline-block;background:#e94560;color:#fff;border-radius:50%;width:22px;height:22px;line-height:22px;text-align:center;font-size:12px;font-weight:700;margin-right:10px;">1</span>
                    <span style="color:#555;font-size:13px;">Open the <strong>EventPro app</strong> and tap <em>My Tickets</em> to see your digital pass.</span>
                  </td>
                </tr>
                <tr>
                  <td style="padding:8px 0;vertical-align:top;">
                    <span style="display:inline-block;background:#e94560;color:#fff;border-radius:50%;width:22px;height:22px;line-height:22px;text-align:center;font-size:12px;font-weight:700;margin-right:10px;">2</span>
                    <span style="color:#555;font-size:13px;">Download this ticket's soft copy or print it &mdash; it works as your entry pass.</span>
                  </td>
                </tr>
                <tr>
                  <td style="padding:8px 0;vertical-align:top;">
                    <span style="display:inline-block;background:#e94560;color:#fff;border-radius:50%;width:22px;height:22px;line-height:22px;text-align:center;font-size:12px;font-weight:700;margin-right:10px;">3</span>
                    <span style="color:#555;font-size:13px;">Arrive a little early and show your QR code at the door. See you there! 🎊</span>
                  </td>
                </tr>
              </table>
            </td>
          </tr>

          <!-- Divider -->
          <tr><td style="padding:0 40px;"><hr style="border:none;border-top:1px solid #e2e8f0;margin:0;" /></td></tr>

          <!-- Contact -->
          <tr>
            <td style="padding:24px 40px;text-align:center;">
              <p style="color:#555;font-size:13px;margin:0 0 14px;">Need help with your booking?</p>
              <a href="mailto:{$this->fromEmail}"
                 style="display:inline-block;background:linear-gradient(135deg,#1a1a2e,#0f3460);color:#ffffff;font-size:13px;font-weight:600;padding:12px 28px;border-radius:8px;text-decoration:none;">
                ✉️ &nbsp;Contact Support
              </a>
            </td>
          </tr>

          <!-- Footer -->
          <tr>
            <td style="padding:20px 40px 32px;text-align:center;background:#f8faff;border-top:1px solid #e2e8f0;">
              <p style="color:#aaa;font-size:12px;margin:0 0 4px;">© EventPro Agency. All rights reserved.</p>
              <p style="color:#ccc;font-size:11px;margin:0;">This is an automated booking confirmation. Please do not reply directly to this message.</p>
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
