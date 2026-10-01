const functions = require("firebase-functions");
const admin = require("firebase-admin");
const axios = require("axios");
const SibApiV3Sdk = require("@getbrevo/brevo");

admin.initializeApp();

// ─────────────────────────────────────────────
// Helper: Create a configured Brevo API instance
// ─────────────────────────────────────────────
function getBrevoClient() {
  const apiInstance = new SibApiV3Sdk.TransactionalEmailsApi();
  apiInstance.authentications["api-key"].apiKey = process.env.BREVO_API_KEY;
  return apiInstance;
}

// ─────────────────────────────────────────────
// Cloud Function: Generic transactional email
// ─────────────────────────────────────────────
// POST /sendEmail
// Body: {
//   to: [{ email: "user@example.com", name: "User Name" }],
//   subject: "Booking Confirmed!",
//   htmlContent: "<h1>Hello</h1>",
//   textContent: "Hello",          // optional plain-text fallback
//   templateId: 5,                 // optional: use a Brevo template instead of htmlContent
//   params: { name: "Alice" }      // optional: template variables
// }
exports.sendEmail = functions.https.onRequest(async (req, res) => {
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Methods", "POST, OPTIONS");
  res.set("Access-Control-Allow-Headers", "Content-Type, Authorization");

  if (req.method === "OPTIONS") {
    res.status(204).send("");
    return;
  }

  if (req.method !== "POST") {
    res.status(405).send({ error: "Method not allowed. Use POST." });
    return;
  }

  const { to, subject, htmlContent, textContent, templateId, params } = req.body;

  if (!to || !Array.isArray(to) || to.length === 0) {
    res.status(400).send({ error: "Missing or invalid 'to' field. Must be an array of {email, name} objects." });
    return;
  }
  if (!templateId && !htmlContent) {
    res.status(400).send({ error: "Provide either 'templateId' or 'htmlContent'." });
    return;
  }

  try {
    const apiInstance = getBrevoClient();
    const sendSmtpEmail = new SibApiV3Sdk.SendSmtpEmail();
    sendSmtpEmail.to = to;
    sendSmtpEmail.sender = {
      name: process.env.BREVO_SENDER_NAME || "EventPro Agency",
      email: process.env.BREVO_SENDER_EMAIL || "noreply@eventproagency.com",
    };

    if (templateId) {
      sendSmtpEmail.templateId = templateId;
      sendSmtpEmail.params = params || {};
    } else {
      sendSmtpEmail.subject = subject;
      sendSmtpEmail.htmlContent = htmlContent;
      if (textContent) sendSmtpEmail.textContent = textContent;
    }

    const result = await apiInstance.sendTransacEmail(sendSmtpEmail);
    res.status(200).send({ success: true, messageId: result.body.messageId });
  } catch (error) {
    console.error("Brevo email error:", error);
    res.status(500).send({ error: "Failed to send email", details: error.message });
  }
});

// ─────────────────────────────────────────────
// Cloud Function: Booking confirmation email
// ─────────────────────────────────────────────
// POST /sendBookingConfirmation
// Body: {
//   customerEmail: "user@example.com",
//   customerName: "Alice",
//   bookingId: "BK-12345",
//   eventName: "Corporate Gala",
//   eventDate: "2026-12-01",
//   amount: "KES 50,000"
// }
exports.sendBookingConfirmation = functions.https.onRequest(async (req, res) => {
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Methods", "POST, OPTIONS");
  res.set("Access-Control-Allow-Headers", "Content-Type, Authorization");

  if (req.method === "OPTIONS") {
    res.status(204).send("");
    return;
  }

  const { customerEmail, customerName, bookingId, eventName, eventDate, amount } = req.body;

  if (!customerEmail || !bookingId) {
    res.status(400).send({ error: "Missing required fields: customerEmail, bookingId" });
    return;
  }

  try {
    const apiInstance = getBrevoClient();
    const sendSmtpEmail = new SibApiV3Sdk.SendSmtpEmail();
    sendSmtpEmail.to = [{ email: customerEmail, name: customerName || "Valued Client" }];
    sendSmtpEmail.sender = {
      name: functions.config().brevo.sender_name || "EventPro Agency",
      email: functions.config().brevo.sender_email || "noreply@eventproagency.com",
    };
    sendSmtpEmail.subject = `Booking Confirmed — ${eventName || "Your Event"} (#${bookingId})`;
    sendSmtpEmail.htmlContent = `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: auto; padding: 24px; border: 1px solid #eee; border-radius: 8px;">
        <h2 style="color: #2563EB;">Booking Confirmed! 🎉</h2>
        <p>Hi <strong>${customerName || "there"}</strong>,</p>
        <p>Your booking has been confirmed. Here are your details:</p>
        <table style="width:100%; border-collapse:collapse; margin-top:16px;">
          <tr><td style="padding:8px; background:#f9f9f9; font-weight:bold;">Booking ID</td><td style="padding:8px;">#${bookingId}</td></tr>
          <tr><td style="padding:8px; font-weight:bold;">Event</td><td style="padding:8px;">${eventName || "—"}</td></tr>
          <tr><td style="padding:8px; background:#f9f9f9; font-weight:bold;">Date</td><td style="padding:8px;">${eventDate || "—"}</td></tr>
          <tr><td style="padding:8px; font-weight:bold;">Amount</td><td style="padding:8px;">${amount || "—"}</td></tr>
        </table>
        <p style="margin-top:24px;">Thank you for choosing <strong>EventPro Agency</strong>. We look forward to making your event unforgettable!</p>
        <p style="color:#888; font-size:12px; margin-top:32px;">If you have any questions, reply to this email or contact our support team.</p>
      </div>
    `;

    const result = await apiInstance.sendTransacEmail(sendSmtpEmail);
    res.status(200).send({ success: true, messageId: result.body.messageId });
  } catch (error) {
    console.error("Booking confirmation email error:", error);
    res.status(500).send({ error: "Failed to send confirmation email", details: error.message });
  }
});

// ─────────────────────────────────────────────
// Existing: Proxy to Laravel backend
// ─────────────────────────────────────────────
exports.api = functions.https.onRequest(async (req, res) => {
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS");
  res.set("Access-Control-Allow-Headers", "Content-Type, Authorization");

  if (req.method === "OPTIONS") {
    res.status(204).send("");
    return;
  }

  const LARAVEL_API_URL = process.env.LARAVEL_API_URL || "http://your-laravel-app.com/api";

  const endpoint = req.path;
  const targetUrl = `${LARAVEL_API_URL}${endpoint}`;

  try {
    const headers = { ...req.headers };
    delete headers.host;

    const response = await axios({
      method: req.method,
      url: targetUrl,
      data: req.body,
      headers: headers,
      params: req.query,
    });

    res.status(response.status).send(response.data);
  } catch (error) {
    if (error.response) {
      res.status(error.response.status).send(error.response.data);
    } else {
      res.status(500).send({ error: "Proxy Error", details: error.message });
    }
  }
});
