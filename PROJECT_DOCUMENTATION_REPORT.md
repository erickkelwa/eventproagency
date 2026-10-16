# EVENTPRO AGENCY — PROJECT REPORT & DOCUMENTATION

---

## 1. Executive Summary
**EventPro Agency** is a comprehensive, multi-platform event and entertainment ticketing & management application developed using the **Flutter framework**, backed by a **Laravel RESTful API**, **Cloud Firestore**, and **Firebase Authentication**.

The platform bridges event organizers, service providers (sound, DJs, caterers, security), and attendees across East Africa with built-in payments via **Safaricom M-Pesa (Daraja API)**, **Airtel Money**, and **Paystack/Cards**.

---

## 2. Key System Architecture & Technology Stack

| Layer | Technologies & Tools |
|---|---|
| **Mobile & Web Client** | Flutter 3.x, Dart 3.x, Riverpod (State Management), GoRouter |
| **Authentication** | Firebase Auth (Email/Password, Google OAuth 2.0 with SHA-1 signatures) |
| **Database & Realtime Sync** | Cloud Firestore (Real-time NoSQL) + SQLite (Laravel Local/Render Storage) |
| **Backend REST API** | PHP 8.2, Laravel 10.x, Guzzle/Http Client, Brevo SMTP |
| **Cloud Hosting & Infrastructure** | Render.com Web Service (`eventpro-api-709n.onrender.com`), Docker, Firebase Cloud Messaging |
| **Payment Gateways** | Safaricom Daraja STK Push (M-Pesa), Airtel Money USSD, Paystack, Equity Bank |
| **Maps & Geo Services** | OpenStreetMap (flutter_map) + Google Maps SDK (Location Markers & Route Planning) |

---

## 3. Core Modules & Functionalities

### 3.1 Authentication & User Management
- **Google Sign-In & Sign-Up**: Direct authentication using Google OAuth 2.0 with registered SHA-1 fingerprint (`5F:74:C4:65:69:0E:0E:24:70:17:84:06:41:52:0D:6E:98:29:36:07`).
- **Email & Password Authentication**: Validated registration with encrypted passwords and automated welcome emails triggered via Brevo Mailer.
- **Role-Based Access Control (RBAC)**: Distinguishes between regular attendees and administrative staff (`admin` role with specialized dashboard routing).

### 3.2 Event Discovery & Booking Engine
- **Curated & Dynamic Events Feed**: Filterable by category (Conferences, Festivals, Tech Summits, Sports).
- **Interactive Geo-Map**: Visualizes nearby events in real time using geo-coordinates.
- **Seat & Ticket Allocation**: Manages available slots, tiered pricing, and sold-out states.

### 3.3 M-Pesa STK Push Payment Gateway
- **Safaricom Daraja API Integration**:
  - Implements `CustomerPayBillOnline` STK push via `https://sandbox.safaricom.co.ke/mpesa/stkpush/v1/processrequest`.
  - Realistic In-App SIM Toolkit prompt dialog capturing 4-digit PIN for demo and verification.
  - Generates verifiable transaction IDs (`EP...`) and M-Pesa receipt numbers (`MP...`).
  - Automatically issues digital tickets with cryptographically unique QR Codes upon payment confirmation.

### 3.4 Live Real-Time Admin Dashboard
- **Dynamic KPI Metrics**:
  - Real total revenue calculated from completed bookings and Firestore transactions.
  - Active event counts and verified registered users.
- **Revenue & Booking Visual Charts**:
  - Daily bar charts powered by `fl_chart` showing daily revenue and booking volume.
- **QR Code Ticket Scanner**:
  - Integrated with `mobile_scanner` to validate attendee tickets at venue entrances.

---

## 4. Deployment & Hosting

### Web & API Hosting
- **Live Web Application (Frontend)**: Hosted on Firebase at [https://eventproagency-aec59.web.app](https://eventproagency-aec59.web.app)
- **Backend API & Payment Engine**: Hosted on Render at [https://eventpro-api-709n.onrender.com/api](https://eventpro-api-709n.onrender.com/api)
- **Database**: SQLite with auto-running migrations on container deployment.

### Mobile Distribution (Android)
- **Standalone APK**: Built in release mode with ProGuard optimization and icon tree-shaking:
  `build\app\outputs\flutter-apk\app-release.apk` (82.3 MB).
- Ready for immediate distribution via WhatsApp, USB, or direct download.

---

## 5. Security & Reliability Measures
1. **Network Security**: Cleartext traffic control and HTTPS enforcement with SSL certificate pinning.
2. **Payment Resilience**: Dual-mode payment processing (Daraja API STK push with fallback simulation to ensure zero downtime during test presentations).
3. **Responsive UI**: Adaptive layouts with zero overflow across screen resolutions ranging from 720p mobile displays to 4K web desktops.
