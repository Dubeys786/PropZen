# PropZen Security & Hardening Policy

This document outlines the security controls, validation rules, cryptographic standards, and hardening measures implemented in the PropZen Java backend.

---

## 1. Authentication Security

* **Token Format**: Standard RFC 7519 JSON Web Token (JWT) issued by Supabase Auth.
* **Signature Verification**: Validated cryptographically on every request using Nimbus JOSE/JWT. Unsigned tokens, altered payloads, or mismatched signatures are rejected immediately.
* **Algorithm Support**:
  - `ES256` (ECDSA using P-256 curve and SHA-256) — Primary algorithm used by live Supabase project `eemxylswyvhsyzllcsnp` with public JWKS key rotation.
  - `RS256` (RSA signature using SHA-256) — Supported via JWKS.
  - `HS256` (HMAC using SHA-256) — Supported via `SUPABASE_JWT_SECRET` when configured.
* **Temporal Validation**:
  - Expiration (`exp`): Rejects tokens whose expiration timestamp has passed.
  - Not Before (`nbf`): Rejects tokens presented before their active validity timestamp.
* **Issuer & Audience Validation**:
  - Issuer: `https://eemxylswyvhsyzllcsnp.supabase.co/auth/v1`
  - Audience: `authenticated`

---

## 2. Authorization & Privilege Escalation Prevention

1. **Zero Client Trust**: User ID, email, and roles provided in HTTP request bodies or query parameters are **never** trusted as the caller's identity. All identity resolution queries `SecurityContextHolder` via `CurrentUserService.getRequiredCurrentUser()`.
2. **Server-Side Admin Enforcement**:
   - Administrative endpoints (`/api/v1/admin/**`) strictly require the caller to possess `ROLE_ADMIN`.
   - **Primary Authority**: `ROLE_ADMIN` is derived strictly from server-side trusted sources:
     - Cryptographically verified Supabase claims (`app_metadata.role` or `app_metadata.roles` contains `admin` / `super_admin` / `administrator`). Client-writable claims such as `user_metadata` are strictly ignored for admin evaluation.
     - Authoritative database records (`public.users.role = 'ADMIN'`).
   - **Optional Bootstrap Allowlist**: Environment variable `PROPZEN_BOOTSTRAP_ADMIN_EMAILS` (`propzen.security.bootstrap-admin-emails`) allows bootstrap administrator provisioning during initial cluster deployment without hardcoding email strings in Java source code.
   - Attackers attempting to forge an admin role string in their client profile or request body receive HTTP 403 Forbidden.
3. **Dealer Protection & Server-Side Role Activation**:
   - Protected dealer endpoints (`/api/v1/dealers/**`) strictly require `ROLE_DEALER` or `ROLE_ADMIN`.
   - Any authenticated user may apply via `POST /api/v1/dealers/apply` or check their own status via `GET /api/v1/dealers/me`.
   - Dealers cannot self-approve; only an administrator can approve an application, which atomically upgrades `public.users.role = 'DEALER'`.
4. **Resource Ownership Verification**:
   - `ResourceAuthorizationService.assertOwnership(resourceOwnerUserId, resourceType)` verifies that the authenticated caller owns the requested resource before allowing modification. Admins bypass ownership checks for operational management.

---

## 3. Password & Credential Handling

* **Zero Password Storage**: The Java backend does not store, verify, or transmit user passwords. Authentication is delegated exclusively to Supabase Auth.
* **Stateless REST**: REST endpoints do not use HTTP session cookies or server-side session state, eliminating session fixation vulnerabilities.

---

## 4. Network & Transport Security

* **CORS Restrictions**: `PROPZEN_ALLOWED_ORIGINS` strictly limits allowed origins to authorized domains (e.g., `https://propzen.ai`, `http://localhost:3000`). Wildcard CORS (`*`) is disabled in production.
* **Security Headers**:
  - `X-Frame-Options: SAMEORIGIN`
  - `Content-Security-Policy: default-src 'self'; frame-ancestors 'self';`
  - `Strict-Transport-Security` configured for HTTPS deployments.

---

## 5. Audit Logging & Leak Prevention

* **Credential Scrubbing**: `RequestLoggingFilter` logs only HTTP method, sanitized URI, response status, duration, and correlation ID.
* **Forbidden in Logs**:
  - `Authorization` headers
  - JWT strings
  - Passwords
  - Supabase service role keys
  - API keys
* **Error Sanitization**: `GlobalExceptionHandler` masks internal database errors, SQL syntax errors, and stack traces from API responses, returning only standardized `ErrorCode` identifiers.

---

## 6. CRM & Multi-Tenant Lead Isolation (Phase 6)

1. **Buyer Role Isolation**:
   - Buyers (`ROLE_USER`) have zero access to CRM APIs (`/api/v1/crm/**`).
   - Attempted access by buyers results in HTTP 403 Forbidden.
2. **Dealer Lead Isolation (IDOR Prevention)**:
   - Dealers (`ROLE_DEALER`) can query, inspect, and update **only** leads assigned to their `dealer_id`.
   - Any query or search by a dealer automatically applies a server-enforced `dealer_id = ?` predicate at the database level (`LeadSpecifications`).
   - Querying or mutating a lead belonging to another dealer triggers HTTP 403 Forbidden with `ErrorCode.FORBIDDEN`.
3. **Admin CRM Oversight**:
   - Administrators (`ROLE_ADMIN`) have global cross-dealer visibility and can override assignment, view global metrics, and configure automation rules.
4. **Communication Consent & Idempotency**:
   - Outbound marketing campaigns enforce strict consent checking against `crm_communication_preferences`.
   - Every campaign recipient delivery uses an idempotency key `campaignId:leadId:templateId` with a database unique index to prevent duplicate messaging.

---

## 7. Service Management Security & Hardening (Phase 7)

1. **Role Separation & Authority (`ROLE_SERVICE_PARTNER`)**:
   - Distinct role granted only upon administrative approval of a service partner application.
   - Standard buyers (`ROLE_BUYER`) and dealers (`ROLE_DEALER`) cannot execute partner fulfillment endpoints (`/api/v1/partner/**`).
2. **Prevention of Partner Self-Approval**:
   - Service partners **cannot** approve or activate their own partner profile or update their KYC verification status. Attempts return HTTP 403 Forbidden.
   - Service partners **cannot** approve their own milestones. Milestone completion sign-off is restricted to the paying customer or an administrator (`HTTP 403 Forbidden`).
3. **IDOR & Multi-Tenant Request Isolation**:
   - **Customer Scoping**: Customers can view only their own service requests, documents, payments, and timeline events (`customerId = authenticatedUser.id`). Cross-customer inspection returns HTTP 403 Forbidden.
   - **Partner Scoping**: Service partners can access only service requests explicitly assigned to their `partnerId`. Attempts to inspect or modify other partners' service requests return HTTP 403 Forbidden.
   - **Customer Privacy**: Service partners can view customer CRM details and notes **only** for customers with whom they have an active or completed service assignment.
4. **Zero-Card Payment Compliance & Gateway Security**:
   - Zero payment credentials (PAN, CVV, expiry, PIN, net banking credentials) are accepted, transmitted, or persisted on PropZen infrastructure.
   - All checkouts leverage client-side secure tokens or hosted gateway redirects.
   - Webhook endpoints (`/api/v1/services/payments/webhook`) enforce cryptographic HMAC SHA-256 signature verification before processing payment settlement.
   - Idempotency guards prevent double-crediting of payments.
5. **Review Integrity**:
   - Customers can submit feedback **only** on completed service requests (`status = COMPLETED`).
   - Duplicate reviews for the same service request are rejected with `HTTP 400 DUPLICATE_RESOURCE`.
   - Partner ratings are dynamically recalculated from aggregate verified feedback.

---

## 8. Centralized CRM, Outbox & WhatsApp Security Hardening (Phase 8)

1. **Meta WhatsApp Business API Protection**:
   - Permanent System User Access Token injected via `PROPZEN_WHATSAPP_ACCESS_TOKEN`; never committed to VCS.
   - Meta webhook challenge handshake authenticated with `PROPZEN_WHATSAPP_WEBHOOK_VERIFY_TOKEN`.
   - Public webhook endpoints run behind rate limiting and validate incoming payload schemas before processing.
2. **Consent & Privacy Compliance (Opt-in Verification)**:
   - Mandatory consent checks (`whatsapp_opt_in = true`) evaluated at the database level before any outbound communication is dispatched.
   - Instant unsubscription and opt-out support via `PATCH /api/v1/communication/preferences`.
3. **Transactional Outbox Fault Isolation**:
   - Asynchronous worker isolates messaging errors from core transaction workflows.
   - Poison messages automatically routed to `DEAD_LETTER` state after 5 retries to prevent queue stalling.
4. **Lead Deletion & Destructive Operation Guard**:
   - Lead deletion (`DELETE /api/v1/crm/leads/{id}`) is strictly restricted to `ROLE_ADMIN`. Dealers and unassigned staff attempting lead deletion receive HTTP 403 Forbidden.
5. **Customer 360 Privacy & Multi-Tenant Boundaries**:
   - Customer 360 dossier retrieval requires active dealer or admin authority.
   - Cross-dealer lead inspection is prohibited by server-side query filters.



