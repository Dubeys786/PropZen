# PROPZEN PRODUCTION SECURITY AUDIT REPORT
**Target System:** PropZen Real Estate Intelligence Platform  
**Scope:** Flutter Frontend, Spring Boot Java Backend, Supabase PostgreSQL, Storage Buckets, RLS, APIs, Auth, Payments, Webhooks, CRM, AI Engine  
**Audit Date:** September 2026  
**Auditor:** Application Security, DevSecOps & Database Security Engineering  

---

## EXECUTIVE SUMMARY

A comprehensive security audit of the PropZen repository was performed across 115+ Flutter test suites, 86 Flutter services, 44+ Spring Boot backend components, 24 CRM services, 10 Flyway database migrations, 20+ Supabase SQL schemas, and environment/configuration files.

Multiple critical vulnerabilities were discovered that must be remediated before production deployment:
1. **Hardcoded Master Backdoor Tokens & Unverified JWT Parsing in `serve.dart`**
2. **Client-Side Admin Role & Identity Assignment via Hardcoded Email (`dubeysakshi618@gmail.com`)**
3. **Missing Row Level Security (RLS) on Flyway Migrations (V1-V10) & Permissive `USING (true)` in Supabase Schemas**
4. **Unauthenticated / Insecure Payment Verification & Mock Payment Provider Exposure**
5. **Unverified Webhook Signatures on WhatsApp and Payment Webhooks**
6. **Insecure Storage Authorization & BOLA on Private Document Downloads**
7. **BOLA/IDOR on AI CRM Intelligence Endpoints and WhatsApp Communications**
8. **Permissive CORS Allowing Arbitrary `.trycloudflare.com` Subdomains and Localhost in Production**
9. **Exposed Secrets and API Keys in `.env`, Dart Server Files, and Annotations**

---

## 1. CRITICAL VULNERABILITIES (SEVERITY: CRITICAL)

### [CRIT-01] Master Admin Backdoor Tokens & Unsigned JWT Parsing in `serve.dart`
- **Location:** `serve.dart:375-416`
- **Impact:** Complete administrative compromise of the server and database.
- **Details:**
  - Lines 404-413 grant instant super-admin access (`adm_sakshi_dubey_master`, role `admin`) if an incoming token is `'master_admin_session_token'` or `'dubeysakshi618_admin'`.
  - Lines 375-397 parse Supabase JWTs by merely decoding base64 payload *without cryptographic signature verification*. Anyone can forge a JWT with `{ "role": "admin", "email": "dubeysakshi618@gmail.com" }` and gain full admin powers.
  - Line 387 checks if `email.contains('dealer') || email.contains('broker')` to assign `isDealer = true`.
- **Remediation:** Remove backdoor tokens completely. Implement strict cryptographic JWKS / RSA / HMAC signature verification. Do not grant roles based on substring matches.

---

### [CRIT-02] Client-Side Role & Admin Flag Derivation from Hardcoded Email
- **Location:** 
  - `lib/screens/user_profile_screen.dart:118, 273, 423`
  - `lib/widgets/admin_route_guard.dart:57, 105`
  - `lib/services/supabase_service.dart:1019, 1664, 1690, 1705, 1727, 1759`
  - `lib/services/auth_service.dart:192, 208`
  - `lib/services/admin_service.dart:24, 42, 87, 299, 324`
- **Impact:** Privilege escalation to Administrator via client-side state manipulation or localStorage modification.
- **Details:**
  - The client defines `static const String designatedAdminEmail = 'dubeysakshi618@gmail.com';`.
  - If a user registers or logs in with this email, or modifies `propzen_email` in browser `SharedPreferences` / localStorage, `UserSession.roleTierNotifier.value` is set to `'ADMIN'`.
  - `SupabaseService.verifyAdminAccessInBackend` and `fetchUserProfileRole` automatically return `true` and `'admin'` whenever the email matches, even when database queries fail.
- **Remediation:**
  - Remove all client-side hardcoded admin emails.
  - Role authorization must come strictly from cryptographically verified backend tokens (`app_metadata.role` or authoritative `/api/v1/auth/me` profile fetched from backend).
  - Admin Route Guard and Admin Service must verify backend clearance before unlocking the Command Center.

---

### [CRIT-03] Missing RLS on Flyway Database Migrations & Insecure `USING (true)` Policies
- **Location:**
  - `backend/propzen-backend/src/main/resources/db/migration/V1__baseline_marker.sql` through `V10__add_service_partner_fields_to_crm_leads.sql`
  - `supabase_schema.sql:215-243, 339-353, 534-568, 730-747`
- **Impact:** Mass data exposure, tenant cross-talk, unauthorized reading/writing of CRM leads, private documents, payments, and users via Supabase PostgREST.
- **Details:**
  - Flyway migrations create tables (`crm_leads`, `dealer_profiles`, `service_partner_profiles`, `service_requests`, `service_payments`, `audit_logs`, `notifications`, `property_verification_cases`) without executing `ALTER TABLE ... ENABLE ROW LEVEL SECURITY;`.
  - Older SQL schemas contain `USING (true)` and `WITH CHECK (true)` policies for `public.users`, `public.enquiries`, `public.site_visits`, `public.dealer_leads`, `public.deal_documents`, and `public.deal_messages`.
- **Remediation:**
  - Create a new authoritative Flyway migration (`V11__enforce_strict_rls_and_tenant_isolation.sql`) enabling RLS across every public table.
  - Revoke `USING (true)` policies and implement strict ownership: Buyers see only their data, Dealers see only their assigned inventory and leads, Service Partners see only their assigned service requests, and Admins have authorized access.

---

### [CRIT-04] Production Payment Gateway Bypass & Mock Payment Provider in Production
- **Location:**
  - `backend/propzen-backend/src/main/java/com/propzen/service/payment/MockPaymentProvider.java:33`
  - `backend/propzen-backend/src/main/java/com/propzen/service/payment/PaymentService.java:77-78`
  - `backend/propzen-backend/src/main/java/com/propzen/service/payment/RazorpayPaymentProvider.java:22-26`
  - `backend/propzen-backend/src/main/java/com/propzen/service/controller/ServicePaymentController.java:63-67`
- **Impact:** Financial fraud, free order settlements, fake payment completion.
- **Details:**
  - `MockPaymentProvider` returns `true` for signature verification as long as the signature is non-blank.
  - `PaymentService.createPayment` falls back to `PaymentProviderType.MOCK` if unspecified.
  - `RazorpayPaymentProvider` hardcodes default test credentials in `@Value` annotations (`rzp_test_propzen_remote_2026` and `rzp_secret_propzen_test_key_8849`).
  - Webhook endpoint `/api/v1/services/payments/webhook` accepts payloads without requiring or verifying provider HMAC signatures (`X-Razorpay-Signature`) in request headers.
- **Remediation:**
  - Disable `MockPaymentProvider` in production profile (require active profile check or fail closed).
  - Enforce mandatory HMAC-SHA256 signature verification for Razorpay webhooks.
  - Validate payment order ID, payment ID, amount, currency, and idempotency key before updating payment status to `PAID`.

---

### [CRIT-05] Unauthenticated WhatsApp Webhook Delivery Status Manipulation
- **Location:** `backend/propzen-backend/src/main/java/com/propzen/crm/controller/WebhookController.java:65`
- **Impact:** Spoofed CRM communications, false delivery confirmations, and message log tampering.
- **Details:**
  - `WebhookController.handleCallback` sets `X-Hub-Signature-256` as optional (`required = false`) and never validates the signature against `PROPZEN_WHATSAPP_APP_SECRET`.
  - Anyone can send arbitrary JSON to mutate campaign recipient statuses (`DELIVERED`, `READ`, `FAILED`).
- **Remediation:** Validate the HMAC-SHA256 signature over raw request body using Meta app secret. Reject unverified requests with HTTP 401/403.

---

## 2. HIGH VULNERABILITIES (SEVERITY: HIGH)

### [HIGH-01] BOLA / IDOR on AI CRM Intelligence Endpoints
- **Location:** `backend/propzen-backend/src/main/java/com/propzen/ai/service/AiLeadScoringService.java:45-60`, `CrmAiAssistantService.java`, `AiFollowUpService.java`
- **Impact:** Competitor lead data leakage between rival dealers.
- **Details:**
  - Endpoints `/api/v1/ai/crm/lead-score/{leadId}`, `/api/v1/ai/crm/lead-summary/{leadId}`, `/api/v1/ai/crm/next-action/{leadId}`, `/api/v1/ai/crm/follow-up/{leadId}` receive `AuthenticatedUser actor`, but **do not check whether the calling dealer owns or is assigned to `leadId`**.
  - Any authenticated dealer can probe another dealer's lead ID to extract confidential lead details, notes, budget, and AI summaries.
- **Remediation:** Call `assertLeadAccess(lead, actor)` in all AI CRM services before computing or returning lead intelligence.

---

### [HIGH-02] Broken Object Level Authorization (BOLA) on Private Document Downloads
- **Location:** `backend/propzen-backend/src/main/java/com/propzen/service/storage/StorageController.java:47` & `StorageService.java:49-59`
- **Impact:** Unauthorized access to confidential verification documents, Aadhaar/PAN cards, property deeds, and financial statements.
- **Details:**
  - `/api/v1/storage/signed-download-url?storagePath=...` generates a signed download URL for any path supplied in the query parameter without checking whether the caller is the owner or an authorized admin.
  - `StorageService.java` generates pseudo-tokens (`?token=` + UUID.randomUUID()) and exposes public access URLs for all buckets, compromising private verification docs.
- **Remediation:**
  - Verify document ownership from the database (`service_deliverables`, `property_verification_documents`, `deal_documents`) before signing download URLs.
  - Keep `verification-docs` and `deal-documents` private.

---

### [HIGH-03] Dangerous CORS Permitting Arbitrary Cloudflare Tunnels & Localhost in Production
- **Location:** 
  - `serve.dart:471`
  - `backend/propzen-backend/src/main/java/com/propzen/config/CorsConfig.java:43-47`
- **Impact:** Cross-Origin Request Forgery / credential theft from malicious web pages.
- **Details:**
  - `serve.dart:471` allows any origin ending with `.trycloudflare.com` with `Access-Control-Allow-Credentials: true`. Anyone can start a free Cloudflare tunnel and send authenticated requests to users' sessions.
  - `CorsConfig.java` allows `http://localhost:[*]` and `http://127.0.0.1:[*]` across all environments.
- **Remediation:** Restrict allowed origins strictly to `https://propzen.ai`, `https://www.propzen.ai`, and designated staging domains. Allow localhost only when active profile is `dev` or `test`.

---

### [HIGH-04] Exposed Secrets and Hardcoded API Keys
- **Location:**
  - `.env` in root: `N8N_API_KEY=Sakshi@123`, `RAZORPAY_KEY_SECRET`, `RAZORPAY_WEBHOOK_SECRET`, `AI_ENGINE_API_KEY`, `MASTER_KEK_SECRET`
  - `server.dart:13`: `static String apiKey = 'Sakshi@123';`
  - `serve.dart:78-80`: Hardcoded Razorpay secret and webhook secret
  - `backend/propzen-backend/src/main/resources/application.yml:44`: Fallback `bootstrap-admin-emails: admin@propzen.ai,dubeysakshi618@gmail.com`
- **Impact:** Secret compromise; unauthorized webhook triggering and payment tampering.
- **Remediation:**
  - Move all secrets to secure environment variables.
  - Strip hardcoded fallback secrets from `.env`, `.dart`, and `.java` source files.
  - Document that previously exposed test secrets must be rotated before go-live.

---

## 3. MEDIUM VULNERABILITIES (SEVERITY: MEDIUM)

### [MED-01] Missing Role Restriction on WhatsApp Template Creation & IDOR on Message History
- **Location:** `backend/propzen-backend/src/main/java/com/propzen/crm/controller/WhatsAppController.java:60, 77`
- **Impact:** Dealers can create unapproved message templates and read communications of other dealers' leads.
- **Remediation:** Add `@PreAuthorize("hasRole('ADMIN')")` to `createTemplate`. Add ownership verification to `getMessages`.

---

### [MED-02] Rate Limiting Client IP Spoofing & Missing Tiered Limits
- **Location:** `backend/propzen-backend/src/main/java/com/propzen/config/RateLimitingFilter.java:93-98`
- **Impact:** Rate limit bypass via forged `X-Forwarded-For` header; potential brute-force attacks on sensitive endpoints.
- **Remediation:** Trust `X-Forwarded-For` only from verified reverse proxy CIDRs. Implement endpoint-specific and role-based rate limits (anonymous vs user vs dealer vs admin).

---

### [MED-03] Unvalidated Dealer and Partner Self-Approval via Direct Client REST Calls
- **Location:** `lib/services/supabase_service.dart:2782`
- **Impact:** Client could attempt to patch dealer/partner status to `APPROVED`.
- **Remediation:** Ensure all dealer and partner approvals occur exclusively through backend endpoints `/api/v1/admin/dealers/{id}/status` and `/api/v1/admin/service-partners/{id}/status`. Enforce DB RLS disallowing non-admins from modifying `status` or `verification_status`.

---

## 4. LOW VULNERABILITIES (SEVERITY: LOW)

### [LOW-01] Hardcoded Localhost Dependencies in Default Configs
- **Location:** `.env:26`, `lib/config/env_config.dart:95`
- **Impact:** Inadvertent connectivity failures in production.
- **Remediation:** In production builds, default to secure HTTPS canonical base URLs.

### [LOW-02] Missing Security Headers
- **Location:** `backend/propzen-backend/src/main/java/com/propzen/config/SecurityConfig.java:61-65`
- **Impact:** Lack of strict `X-Content-Type-Options: nosniff`, `Referrer-Policy: strict-origin-when-cross-origin`, and `Permissions-Policy`.
- **Remediation:** Configure complete security headers in Spring Security `HeadersConfigurer`.

---

## 5. EXISTING PROTECTIONS
1. Spring Boot `SecurityConfig.java` enforces stateless JWT authentication via `SupabaseJwtAuthenticationFilter`.
2. `SupabaseJwtValidator.java` verifies ES256/RS256 asymmetric cryptographic signatures using Supabase JWKS with key caching.
3. Spring Security method security (`@PreAuthorize`) is active and used in several admin controllers.
4. `GlobalExceptionHandler.java` sanitizes error responses, preventing SQL query leaks or internal stack traces from reaching clients.
5. `RoleMappingService.java` maps authoritative database roles (`DEALER`, `SERVICE_PARTNER`, `ADMIN`) and cryptographically signed `app_metadata` claims into Spring Security authorities.
6. `LeadService.java` implements dealer and service partner isolation checks (`assertLeadAccess`).
7. `PropertyService.java` isolates dealer property edits and blocks updating unapproved statuses or admin notes by non-admins.
8. Sensitive files (`.env`, `.env.*`) are included in `.gitignore`.

---

## 6. MISSING PROTECTIONS
1. RLS enforcement in Flyway migrations (V1-V10) for Supabase PostgreSQL.
2. Webhook HMAC-SHA256 signature verification for both WhatsApp Business and Payment Provider callbacks.
3. Ownership assertion on private file download endpoints (`/api/v1/storage/signed-download-url`).
4. Lead ownership check in AI CRM intelligence services (`AiLeadScoringService`, `CrmAiAssistantService`, `AiFollowUpService`).
5. Server-side authoritative admin check in Flutter route guards instead of hardcoded email comparison.
6. Elimination of mock payment provider verification in non-dev environments.
7. Disabling of wildcard localhost CORS and Cloudflare tunnel wildcards in production.

---

## 7. RECOMMENDED FIXES
1. **Phase 1 & 3:** Remove `master_admin_session_token` and `dubeysakshi618@gmail.com` hardcoding from `serve.dart`, `user_profile_screen.dart`, `admin_route_guard.dart`, `supabase_service.dart`, and `RoleMappingService.java`. Make admin authorization depend strictly on authoritative backend verification (`/api/v1/auth/me` or signed `app_metadata`).
2. **Phase 4:** Ensure dealer and service partner approval is strictly handled by `/api/v1/admin/dealers/{id}/status` and `/api/v1/admin/service-partners/{id}/status`, updating the database user role server-side.
3. **Phase 5 & 9:** Add Flyway migration `V11__enforce_strict_rls_and_tenant_isolation.sql` enabling RLS and tenant policies for all tables.
4. **Phase 7 & 8:** Add ownership validation to `StorageService.getSignedDownloadUrl`, `AiLeadScoringService`, `CrmAiAssistantService`, `AiFollowUpService`, and `WhatsAppController.getMessages`.
5. **Phase 13 & 14:** Implement HMAC-SHA256 signature verification for Razorpay (`X-Razorpay-Signature`) and WhatsApp (`X-Hub-Signature-256`), disabling `MockPaymentProvider` in production.
6. **Phase 18:** Tighten CORS allowlist, remove `.trycloudflare.com` and production localhost wildcards, and configure strict security headers.
7. **Phase 20 & 28:** Write comprehensive automated security tests for authentication, authorization, IDOR, payment signatures, and rate limiting.

---

## 8. REMAINING RISKS (TO BE ADDRESSED IN IMPLEMENTATION)
- Any active credentials previously exposed in `.env` (Razorpay secret, n8n API key, AI Engine key, master KEK) must be rotated with their respective providers prior to public production release.
