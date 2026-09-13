# PropZen Red Team Reconnaissance & Attack Surface Report

**Target Application:** PropZen Real Estate Platform (Web, Android, iOS)  
**Date of Assessment:** September 13, 2026  
**Environment:** Local / Staging & Test Suite  
**Classification:** STRICTLY CONFIDENTIAL — PROPZEN SECURITY TEAM  

---

## 1. Executive Reconnaissance Summary

A systematic black-box reconnaissance of the PropZen application attack surface was conducted across the Flutter client, Java Spring Boot 3.3.3 backend API, Supabase PostgreSQL database, and external microservices/integrations.

---

## 2. Discovered Architecture & Endpoints

### 2.1 Backend API Architecture
* **Framework:** Spring Boot 3.3.3 (Java 21)
* **Base Path:** `/api/v1`
* **Authentication:** Stateless Supabase Bearer JWT (`RS256` JWKS / `HS256` Shared Secret)
* **Session Strategy:** Stateless (`SessionCreationPolicy.STATELESS`)

### 2.2 Endpoint Catalog & Access Matrix

| Category | Endpoint Pattern | HTTP Method | Expected Role | Auth Required |
| :--- | :--- | :--- | :--- | :--- |
| **Health / Metrics** | `/api/v1/health` | GET | Anonymous | No |
| **OpenAPI Docs** | `/v3/api-docs`, `/swagger-ui.html` | GET | Anonymous | No |
| **Property Browsing** | `/api/v1/properties`, `/api/v1/properties/{id}` | GET | Anonymous | No |
| **Public Enquiries** | `/api/v1/enquiries` | POST | Anonymous | No (Rate Limited) |
| **Site Visits** | `/api/v1/site-visits` | POST | Anonymous | No (Rate Limited) |
| **Webhooks (WhatsApp)**| `/api/v1/webhooks/whatsapp` | GET, POST | Anonymous / Meta Signature | Verified Signature |
| **Webhooks (Payments)**| `/api/v1/services/payments/webhook`| POST | Anonymous / Razorpay Signature | Verified Signature |
| **Storage Authorization**| `/api/v1/storage/authorize-upload` | POST | Authenticated | Yes (Valid JWT) |
| **Storage Download URL** | `/api/v1/storage/signed-download-url` | GET | Authenticated (Owner/Admin) | Yes (Valid JWT) |
| **Notifications** | `/api/v1/notifications` | GET, PATCH | Authenticated (Owner) | Yes (Valid JWT) |
| **CRM Leads** | `/api/v1/crm/leads/**` | GET, POST, PATCH, DELETE | Dealer, Staff, Admin | Yes (Valid JWT) |
| **AI CRM Intelligence**| `/api/v1/ai/crm/**` | POST | Dealer, Admin | Yes (Valid JWT) |
| **WhatsApp Messaging** | `/api/v1/whatsapp/send` | POST | Dealer, Admin | Yes (Valid JWT) |
| **WhatsApp Templates** | `/api/v1/whatsapp/template` | POST | Admin | Yes (Valid JWT) |
| **Admin Control** | `/api/v1/admin/**` | GET, POST, PUT, DELETE | Admin | Yes (Valid JWT) |
| **Dealer Registration**| `/api/v1/dealers/register` | POST | Authenticated | Yes (Valid JWT) |
| **Partner Registration**| `/api/v1/partners/register` | POST | Authenticated | Yes (Valid JWT) |
| **Service Payments** | `/api/v1/services/payments/create` | POST | Customer (Owner), Admin | Yes (Valid JWT) |

---

## 3. Parameter, Identifier & Data Model Analysis

* **Primary Key Schema:** UUID v4 across all entities (`users`, `crm_leads`, `dealer_profiles`, `service_requests`, `service_payments`). Random UUIDs prevent sequential integer enumeration but require strict server-side ownership checks to prevent IDOR/BOLA.
* **Sensitive Request Body Fields Inspected:**
  * `role`, `roles`, `is_admin`, `isAdmin`
  * `status`, `verificationStatus`, `approvalStatus`
  * `amount`, `payment_status`, `signature`
  * `userId`, `customerId`, `dealerId`, `ownerId`
* **Static Assets & Public Files:**
  * `serve.dart` / `web/` static build serving Flutter Web bundles (`main.dart.js`, `assets/FontManifest.json`, `favicon.png`).
  * Supabase Public Storage buckets: `property-photos`, `profile-photos`, `public-assets`.
  * Supabase Private Storage buckets: `verification-docs`, `deal-documents`.

---

## 4. Potential Vulnerability Areas Identified for Red Team Probing

1. **Backdoor Tokens / Static Admin Bypasses:** Legacy development session tokens and hardcoded emails in client-side routing.
2. **Client-Side Role Promotion:** Checking if changing client local storage or JWT `user_metadata` bypasses backend access control.
3. **IDOR / BOLA in CRM & AI:** Verifying if Dealer A can query AI lead summaries or lead scores for Dealer B's leads using raw UUIDs.
4. **Payment Gateway Tampering:** Sending fake webhooks or selecting `MOCK` payment provider in production.
5. **Private Storage Exfiltration:** Attempting direct downloads of Aadhaar cards and deal documents across user boundaries.
6. **Rate Limit Bypass:** Testing IP spoofing via `X-Forwarded-For` header.
