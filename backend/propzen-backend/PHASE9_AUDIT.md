# PropZen Project Comprehensive Audit — Phase 9
**Audit Date**: September 2026  
**System**: PropZen Java Spring Boot Backend & Cross-Platform Integration  
**Target Database**: Supabase PostgreSQL (`eemxylswyvhsyzllcsnp`)  
**Scope**: Final Production Hardening, Anti-Mock Verification, API & Frontend Integration

---

## 1. Executive Summary

PropZen has completed Phases 0 through 8, delivering a verified foundation across:
- **Phase 0–3**: Spring Boot 3.3.3 Architecture, Supabase/PostgreSQL live connection, cryptographic JWT validation, and RBAC (`ROLE_BUYER`, `ROLE_DEALER`, `ROLE_SERVICE_PARTNER`, `ROLE_ADMIN`).
- **Phase 4**: User profile management, dealer onboarding, KYC, and dealer administrative review.
- **Phase 5**: Property inventory, exact multi-criteria PostgreSQL search/filter engine.
- **Phase 6**: Initial CRM leads, activities, parametric message templates, and campaign models.
- **Phase 7**: Comprehensive Service Partner management, request lifecycle, stage-gate milestones, and payment webhook verification.
- **Phase 8**: Centralized CRM, Customer 360 dossier, transactional outbox pattern, Meta WhatsApp Business Cloud API, notes, tasks, and follow-ups.
- **Test Baseline**: 118 automated integration tests currently passing (100% green).

This Phase 9 audit identifies remaining gaps, mock implementations, hardcoded demo data, security hardening opportunities, and missing production integrations required for full go-live readiness.

---

## 2. Status of Completed Modules

| Module | Core Entity / Package | Database Tables | Completed Features |
|---|---|---|---|
| **Authentication & RBAC** | `com.propzen.security`, `auth` | `public.users` | Supabase ES256/RS256 JWT validation, cryptographic signature check, role mapping (`ADMIN`, `DEALER`, `SERVICE_PARTNER`, `BUYER`). |
| **User & Dealer Management** | `com.propzen.user`, `dealer` | `public.users`, `dealer_profiles` | User profile self-management, dealer application, admin review/approval, dealer metrics. |
| **Property Inventory & Filter Engine** | `com.propzen.property` | `public.posted_properties` | Exact DB-level filtering (BHK, price min/max, city, sector, status, propertyType), sorting, pagination. |
| **Service Partner Management** | `com.propzen.service` | `service_categories`, `service_partner_profiles`, `service_requests`, `service_milestones`, `service_documents`, `service_payments`, `service_feedback` | Partner application, approval, category discovery, request lifecycle, milestone sign-off, provider-agnostic payments, customer reviews. |
| **Centralized CRM & Customer 360** | `com.propzen.crm` | `crm_leads`, `crm_activities`, `crm_notes`, `crm_followups`, `crm_tasks`, `crm_communications`, `crm_outbox_events`, `crm_tags` | Customer 360 dossier, lead deduplication on phone/email/userId, stage funnel progression, staff task delegation, follow-ups. |
| **Automation & Outbox Worker** | `com.propzen.crm.automation` | `crm_outbox_events` | Atomic outbox event publishing, scheduled background poll, exponential retry backoff, dead-letter queue. |

---

## 3. Incomplete Modules & Feature Gaps

### 3.1 WhatsApp Meta Cloud API Real HTTP Transport
- **Current State**: `MetaWhatsAppProvider.java` checks configuration but returns `"wamid_meta_mock"` rather than dispatching real HTTP POST requests to `https://graph.facebook.com/v18.0/{phone_number_id}/messages`.
- **Requirement**: Full REST transport integration using Spring `RestTemplate` / `HttpClient`, sending official Meta JSON payloads with Bearer token authentication, handling Meta error codes (rate limits, template mismatch).

### 3.2 Asynchronous Bulk Campaign Queue & Rate Limiting
- **Current State**: `CampaignService.sendCampaign()` iterates through campaign recipients synchronously within the HTTP thread.
- **Requirement**: Asynchronous background job dispatch via `OutboxService` or scheduled batch executor, with configurable rate limiting (e.g. 50 msgs/sec), individual recipient state tracking (`SENT`, `DELIVERED`, `READ`, `FAILED`), failure reason logging, and retry backoff.

### 3.3 Unified In-App Notification System
- **Current State**: Phase 8 introduced `public.crm_communications` for external channels (WhatsApp, Email, SMS), but lacks a unified `Notification` entity for persistent in-app notifications.
- **Requirement**: Dedicated `public.notifications` table with APIs:
  - `GET /api/v1/notifications`
  - `PATCH /api/v1/notifications/{id}/read`
  - `PATCH /api/v1/notifications/read-all`

### 3.4 Admin Command Center Dashboard
- **Current State**: Existing endpoints provide CRM analytics (`/api/v1/crm/analytics`) and service dashboard (`/api/v1/admin/services/dashboard`), but lack a centralized command center covering platform-wide metrics.
- **Requirement**: Dedicated `AdminDashboardController` with live database aggregations:
  - `GET /api/v1/admin/dashboard/summary`
  - `GET /api/v1/admin/dashboard/leads`
  - `GET /api/v1/admin/dashboard/revenue`
  - `GET /api/v1/admin/dashboard/services`
  - `GET /api/v1/admin/dashboard/properties`

### 3.5 Persistent Audit Log Store
- **Current State**: `AuditLogService` currently writes structured log messages to the SLF4J logger named `"AUDIT"`.
- **Requirement**: Dedicated `public.audit_logs` table in PostgreSQL storing `actorId`, `action`, `targetType`, `targetId`, `requestId`, `timestamp`, `metadata`.

### 3.6 Service Deliverables & Alternate API Path Mappings
- **Current State**: Service requests currently manage documents through `ServiceDocumentController` (`/api/v1/services/requests/{id}/documents`).
- **Requirement**: Support explicit `ServiceDeliverable` entity and endpoints:
  - `POST /api/v1/service-requests/{id}/deliverables`
  - `GET /api/v1/service-requests/{id}/deliverables`
  - Aliases for `/api/v1/service-requests/**` alongside `/api/v1/services/requests/**`.

### 3.7 Observability Probes
- **Current State**: `HealthController` provides `GET /api/v1/health` with DB check.
- **Requirement**: Add dedicated Kubernetes/container liveness and readiness probes:
  - `GET /api/v1/health/readiness`
  - `GET /api/v1/health/liveness`

---

## 4. Hardcoded Data Locations & Anti-Mock Findings

1. **`MetaWhatsAppProvider.java`**: Hardcoded return value `"wamid_meta_mock"` when credentials are set. Must execute real HTTP request against Graph API when enabled.
2. **`MockPaymentProvider.java`**: Used for testing/offline scenarios. Production must route through `RazorpayPaymentProvider` or configurable provider abstraction (`PAYMENT_PROVIDER=RAZORPAY`).
3. **`PaymentProviderType`**: Needs extensions for `CASHFREE` and `PAYU` alongside `RAZORPAY` and `MOCK`.
4. **Flutter Client Fallbacks (`lib/services/`)**: Multiple Flutter services (e.g. `property_service.dart`, `service_partner_service.dart`) contain local fallback lists when Supabase or backend queries return empty. In production, empty results must display valid empty-state UI rather than injecting dummy records.

---

## 5. Security & Isolation Risks

1. **CORS Configuration**: Wildcard CORS must be strictly avoided; `PROPZEN_ALLOWED_ORIGINS` must restrict browser calls to trusted frontends.
2. **Meta Webhook Verification**: Ensure secret verify token (`PROPZEN_WHATSAPP_WEBHOOK_VERIFY_TOKEN`) is validated during subscription setup, and incoming webhooks are shielded against spoofing.
3. **Error Leakage**: Verified that `GlobalExceptionHandler` masks internal server errors without leaking stack traces or SQL details to callers.
4. **Consent & Regulatory Compliance**: `ContactPreferenceService` must strictly guard both one-off messages and bulk campaigns against sending to opted-out recipients.

---

## 6. Database Dependencies & Flyway Migrations

Existing migrations:
- `V1__baseline_marker.sql`
- `V2__create_dealer_profiles.sql`
- `V3__enhance_posted_properties.sql`
- `V4__create_crm_schema.sql`
- `V5__create_service_management_schema.sql`
- `V6__create_centralized_crm_automation_schema.sql`

**New Migration Required for Phase 9**:
- `V7__phase9_production_hardening_schema.sql`:
  - `public.audit_logs`: Persistent security and operational audit trail.
  - `public.notifications`: Unified in-app customer and partner notifications.
  - `public.service_deliverables`: Formal deliverable deliverables tracking.
  - Add `whatsapp_opt_in_at`, `whatsapp_opt_out_at`, and `communication_preference` to `crm_contact_preferences`.
  - Add `property_title` to `crm_leads`.

---

## 7. Production Blockers & Remediation Roadmap

| Blocker / Gap | Priority | Remediation Action |
|---|---|---|
| Missing Admin Command Center APIs | High | Implement `AdminDashboardController` with live SQL aggregations. |
| Missing In-App Notification System | High | Create `Notification` entity, repo, service, and `/api/v1/notifications` endpoints. |
| Missing Persistent Audit Trail | High | Create `AuditLog` entity and update `AuditLogService` to persist to database. |
| Meta WhatsApp HTTP Client | High | Implement real Graph API v18.0 REST client in `MetaWhatsAppProvider`. |
| Async Bulk Campaign Engine | High | Decouple campaign execution from HTTP thread using transactional outbox / worker. |
| Observability Probes | Medium | Add `/api/v1/health/readiness` and `/api/v1/health/liveness`. |
| Deliverables & Service Request Aliases | Medium | Add `ServiceDeliverable` and map `/api/v1/service-requests/**`. |
| Complete End-to-End Test Suite | High | Ensure all previous 118 tests remain green plus Phase 9 comprehensive integration tests. |
