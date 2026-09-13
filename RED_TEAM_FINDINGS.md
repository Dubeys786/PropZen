# PropZen Red Team Security Findings & Vulnerability Matrix

**Project:** PropZen Real Estate Enterprise Platform  
**Assessment Period:** September 13, 2026  
**Auditor:** PropZen Red Team & DevSecOps Engineering Group  
**Classification:** RESTRICTED — INTERNAL SECURITY DISTRIBUTION ONLY  

---

## 1. Summary of Vulnerabilities

Total Verified Vulnerabilities: **14** (5 Critical, 4 High, 3 Medium, 2 Low)  
All 14 vulnerabilities have been verified, remediated in code/schema, re-attacked, and confirmed resolved.

| Finding ID | Severity | Category | Affected Component | Status |
| :--- | :--- | :--- | :--- | :--- |
| **VULN-001** | **CRITICAL** | Auth Bypass | `serve.dart` Web Server Backdoor Tokens | **REMEDIATED** |
| **VULN-002** | **CRITICAL** | Privilege Escalation | Client-Side Admin Promotion & Hardcoded Email Bypass | **REMEDIATED** |
| **VULN-003** | **CRITICAL** | Broken Object Level Auth | Supabase PostgreSQL Schema (Missing RLS on 11 Tables) | **REMEDIATED** |
| **VULN-004** | **CRITICAL** | IDOR / BOLA | Java Backend AI CRM Intelligence Endpoints | **REMEDIATED** |
| **VULN-005** | **CRITICAL** | Forgery / Data Tampering | Unauthenticated WhatsApp Webhook Status Manipulation | **REMEDIATED** |
| **VULN-006** | **HIGH** | Data Exfiltration | `StorageService.java` & Private Document Downloads | **REMEDIATED** |
| **VULN-007** | **HIGH** | Webhook Forgery | Missing HMAC-SHA256 Signature Verification on Razorpay | **REMEDIATED** |
| **VULN-008** | **HIGH** | Business Logic Flaw | `PaymentService.java` (Production MOCK Gateway Bypass) | **REMEDIATED** |
| **VULN-009** | **HIGH** | Network / CORS Exposure | `CorsConfig.java` & `serve.dart` (Permissive Origins) | **REMEDIATED** |
| **VULN-010** | **MEDIUM** | Authorization / IDOR | WhatsApp Template Creation & Message History BOLA | **REMEDIATED** |
| **VULN-011** | **MEDIUM** | Rate Limiting Bypass | `RateLimitingFilter.java` (IP Header Spoofing) | **REMEDIATED** |
| **VULN-012** | **MEDIUM** | Authorization Flaw | Dealer & Partner Self-Approval via Direct Client Calls | **REMEDIATED** |
| **VULN-013** | **LOW** | Configuration | Hardcoded Localhost Dependencies in Default Configs | **REMEDIATED** |
| **VULN-014** | **LOW** | Security Headers | Missing Strict Enterprise HTTP Headers (CSP, nosniff) | **REMEDIATED** |

---

## 2. Detailed Vulnerability Analyses

### Finding VULN-001: Hardcoded Master Admin Session Tokens & Dev Backdoors in Static Server
* **Severity:** CRITICAL
* **Affected Component:** `serve.dart`
* **Attack Scenario:** An anonymous remote attacker sends an HTTP request with header `Authorization: Bearer master_admin_session_token` or `Authorization: Bearer dubeysakshi618_admin`. The static server previously decoded the token via basic string equality and granted full Command Center administrator privileges.
* **Reproduction Steps:**
  1. `curl -H "Authorization: Bearer master_admin_session_token" http://localhost:8080/admin`
  2. Server returns admin dashboard index with administrative credentials.
* **Impact:** Complete compromise of PropZen platform; unauthorized full admin access.
* **Remediation:** Removed static tokens. Enforced cryptographic verification of JWT claims (`app_metadata.role == 'ADMIN'`).

---

### Finding VULN-002: Client-Controlled Admin Promotion & Hardcoded Email Bypass
* **Severity:** CRITICAL
* **Affected Component:** `UserSession.isAdmin` / `lib/services/supabase_service.dart` / `lib/services/auth_service.dart`
* **Attack Scenario:** Any user signing in with or claiming email equality with `dubeysakshi618@gmail.com` or `admin@propzen.ai` was instantly promoted to `ADMIN` on the client side without database verification.
* **Reproduction Steps:**
  1. User registers or supplies `dubeysakshi618@gmail.com`.
  2. Client-side routing guard allowed entry to Command Center.
* **Impact:** Unauthorized admin access via forged email input.
* **Remediation:** Removed all hardcoded email checks across Dart files and `application.yml`. Admin role is authoritatively verified via database/JWT claims.

---

### Finding VULN-003: Missing Row Level Security (RLS) on Supabase PostgreSQL Tables
* **Severity:** CRITICAL
* **Affected Component:** PostgreSQL Database (Supabase schema)
* **Attack Scenario:** Prior to Flyway migration V11, tables `crm_leads`, `dealer_profiles`, `service_payments`, etc., were created without `ENABLE ROW LEVEL SECURITY`. Using the Supabase public anon key, an attacker could directly query `/rest/v1/crm_leads` and exfiltrate all leads across all dealers.
* **Reproduction Steps:**
  1. Send REST request to Supabase PostgREST endpoint with `anon` key.
  2. Database returned all rows without tenant isolation.
* **Impact:** Total customer PII leak, financial data leak, cross-dealer lead espionage.
* **Remediation:** Created Flyway migration `V11__enforce_strict_rls_and_tenant_isolation.sql` and `supabase_production_security_hardening_v2.sql`, enabling RLS on all 11 tables with strict tenant-isolation policies and dynamic `is_admin()` evaluation.

---

### Finding VULN-004: IDOR in AI CRM Intelligence Endpoints
* **Severity:** CRITICAL
* **Affected Component:** `AiCrmController.java`, `AiLeadScoringService.java`, `CrmAiAssistantService.java`, `AiFollowUpService.java`
* **Attack Scenario:** Dealer A authenticated with a valid JWT. Dealer A called `/api/v1/ai/crm/lead-score/{leadB_UUID}` or `/lead-summary/{leadB_UUID}`. The backend fetched the lead by UUID and computed AI scores without verifying whether the requesting dealer was assigned to that lead.
* **Reproduction Steps:**
  1. Authenticate as Dealer A.
  2. POST `/api/v1/ai/crm/lead-score/{leadB.id}`.
  3. Server previously returned full AI profile and conversion probability.
* **Impact:** Cross-tenant intelligence theft, competitor lead evaluation.
* **Remediation:** Injected `LeadService` into all AI services and enforced `leadService.assertLeadAccess(lead, actor);`, throwing 403 Forbidden on unauthorized access.

---

### Finding VULN-005: Unauthenticated WhatsApp Webhook Delivery Status Manipulation
* **Severity:** CRITICAL
* **Affected Component:** `backend/propzen-backend/src/main/java/com/propzen/crm/controller/WebhookController.java`
* **Attack Scenario:** `WebhookController.handleCallback` previously treated `X-Hub-Signature-256` as optional and skipped validation in production, allowing attackers to forge delivery and read receipts for WhatsApp CRM campaigns.
* **Reproduction Steps:**
  1. POST `/api/v1/webhooks/whatsapp` with forged delivery receipts without signature.
  2. Server processed callback and mutated campaign recipient logs.
* **Impact:** Forged communication logs, sabotaged CRM tracking, false delivery status reporting.
* **Remediation:** Enforced HMAC-SHA256 signature verification in `WebhookController.verifyHubSignature`. Invalid signatures return 403 Forbidden immediately.

---

### Finding VULN-006: IDOR & Public Exposure of Sensitive Private Storage Documents
* **Severity:** HIGH
* **Affected Component:** `StorageService.java`, `StorageController.java`
* **Attack Scenario:** `StorageService.authorizeUpload` generated public URLs for private buckets (`verification-docs`, `deal-documents`). Furthermore, `getSignedDownloadUrl` did not assert ownership of the document path.
* **Reproduction Steps:**
  1. Authenticate as Buyer A.
  2. GET `/api/v1/storage/signed-download-url?storagePath=verification-docs/{buyerB_UUID}/aadhaar.pdf`.
  3. Signed URL was returned without ownership validation.
* **Impact:** Direct access to confidential government identity documents (Aadhaar cards, PAN, property deeds).
* **Remediation:** Implemented `assertStorageAccess(storagePath, actor)` checking user UUID against path owner or requiring ADMIN role; restricted public URL generation exclusively to public buckets (`property-photos`, `profile-photos`, `public-assets`).

---

### Finding VULN-007: Missing Razorpay Webhook Signature Verification
* **Severity:** HIGH
* **Affected Component:** `ServicePaymentController.java`, `PaymentService.java`
* **Attack Scenario:** An attacker posts forged webhook payloads to `/api/v1/services/payments/webhook` without valid Razorpay HMAC signatures.
* **Reproduction Steps:**
  1. POST JSON with forged payment status to `/api/v1/services/payments/webhook`.
  2. Request was processed without signature header verification.
* **Impact:** Fraudulent order completion, fake milestone payments, forged delivery status receipts.
* **Remediation:** Required `X-Razorpay-Signature`, verifying constant-time HMAC-SHA256 digests against backend secrets; returning 400/403 on failure.

---

### Finding VULN-008: MOCK Payment Provider Allowed in Production Mode
* **Severity:** HIGH
* **Affected Component:** `PaymentService.java`, `MockPaymentProvider.java`
* **Attack Scenario:** If `provider: MOCK` was passed or defaulted in `createPayment`, the backend generated simulated orders and automatically verified signatures.
* **Reproduction Steps:**
  1. POST `/api/v1/services/payments/create` with `provider: "MOCK"`.
  2. Order was created with instant verification.
* **Impact:** Bypassing real payment processing to obtain free services.
* **Remediation:** Defaulted provider to `RAZORPAY`. Strictly blocked `MOCK` provider when `propzen.environment` is `production` or `prod`.

---

### Finding VULN-009: Wildcard Localhost & Cloudflare CORS Origin Patterns in Production
* **Severity:** HIGH
* **Affected Component:** `CorsConfig.java`, `serve.dart`
* **Attack Scenario:** In production, `http://localhost:[*]` and `*.trycloudflare.com` were permitted in `allowedOriginPatterns`, allowing any local browser script or arbitrary tunnel to issue cross-origin requests with credentials.
* **Remediation:** Restricted production CORS patterns strictly to `https://propzen.ai` and `https://*.propzen.ai`.

---

### Finding VULN-010: Missing Role Restriction on WhatsApp Template Creation & IDOR on Messages
* **Severity:** MEDIUM
* **Affected Component:** `WhatsAppController.java`
* **Attack Scenario:** Non-admin dealers could invoke `/api/v1/whatsapp/template` to register arbitrary message templates or view message logs belonging to other dealers.
* **Remediation:** Added `@PreAuthorize("hasRole('ADMIN')")` to template creation endpoints and verified ownership on message retrieval.

---

### Finding VULN-011: Rate Limiting Header Spoofing
* **Severity:** MEDIUM
* **Affected Component:** `RateLimitingFilter.java`
* **Attack Scenario:** Attacker sent rotating `X-Forwarded-For` header values to evade rate limits.
* **Remediation:** Validated candidate IPs against regex format and integrated Cloudflare `CF-Connecting-IP` and `X-Real-IP`.

---

### Finding VULN-012: Dealer and Partner Self-Approval via Direct Client REST Calls
* **Severity:** MEDIUM
* **Affected Component:** `lib/services/supabase_service.dart`, `AdminApprovalWorkflowIntegrationTest`
* **Attack Scenario:** Clients could attempt to directly patch `dealer_profiles` or `service_partner_profiles` to status `APPROVED`.
* **Remediation:** Approvals are strictly restricted to authenticated `/api/v1/admin/**` backend routes. Supabase RLS disallows direct status elevation by non-admin identities.

---

### Finding VULN-013: Hardcoded Localhost Dependencies in Default Configs
* **Severity:** LOW
* **Affected Component:** `.env`, `lib/config/env_config.dart`
* **Attack Scenario:** Development fallback URLs could cause unexpected network routing if deployed to production without explicit environment overrides.
* **Remediation:** In `env_config.dart`, production mode explicitly returns empty or canonical paths rather than defaulting to `127.0.0.1`.

---

### Finding VULN-014: Missing Enterprise HTTP Security Headers
* **Severity:** LOW
* **Affected Component:** `SecurityConfig.java`
* **Attack Scenario:** Responses lacked explicit CSP, Referrer-Policy, nosniff, and Permissions-Policy headers.
* **Remediation:** Added `X-Content-Type-Options: nosniff`, `Referrer-Policy: strict-origin-when-cross-origin`, `Permissions-Policy: camera=(), microphone=(), geolocation=()`, and Content-Security-Policy directives.
