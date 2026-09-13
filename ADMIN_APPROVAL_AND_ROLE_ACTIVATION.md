# Admin Approval → Immediate Account Activation → Role-Based Login

## 1. Executive Summary & Core Objective
This architecture delivers a production-grade, zero-password-leakage approval workflow for **Dealers** and **Service Partners** within PropZen. When an Administrator approves an application from the Command Center, the user's account is activated immediately, authoritative backend role-based access control (`ROLE_DEALER` or `ROLE_SERVICE_PARTNER`) is enabled without token latency, and the user is routed directly into their dedicated portal upon login—with **zero "As Buyer" fallback regression**.

---

## 2. End-to-End Workflow

```
                        ┌────────────────────────┐
                        │      USER SIGNUP       │
                        │  (Supabase Auth User)  │
                        └───────────┬────────────┘
                                    │
                                    ▼
                        ┌────────────────────────┐
                        │  APPLICATION CREATED   │
                        │ dealer_profiles /      │
                        │ service_partner_profiles│
                        └───────────┬────────────┘
                                    │
                                    ▼
                        ┌────────────────────────┐
                        │     PENDING STATUS     │
                        │ status: 'PENDING'      │
                        │ partner_status:'PENDING'│
                        └───────────┬────────────┘
                                    │
                                    ▼
                        ┌────────────────────────┐
                        │  ADMIN COMMAND CENTER  │
                        │  (Admin Panel Sec 2-5) │
                        └───────────┬────────────┘
                                    │
                                    ▼
                        ┌────────────────────────┐
                        │ ADMIN VIEWS PROFILE    │
                        │ License, RERA, Agency, │
                        │ Categories, Experience │
                        └───────────┬────────────┘
                                    │
                                    ▼
                        ┌────────────────────────┐
                        │  ADMIN CLICKS APPROVE  │
                        │ PATCH /admin/{type}/status
                        └───────────┬────────────┘
                                    │
                                    ▼
                        ┌────────────────────────┐
                        │ ACCOUNT BECOMES ACTIVE │
                        │ status: 'APPROVED'     │
                        │ is_verified: true      │
                        └───────────┬────────────┘
                                    │
                                    ▼
                        ┌────────────────────────┐
                        │ CORRECT ROLE ENABLED   │
                        │ Dynamic RoleMapping    │
                        │ Injects ROLE_DEALER /  │
                        │ ROLE_SERVICE_PARTNER   │
                        └───────────┬────────────┘
                                    │
                                    ▼
                        ┌────────────────────────┐
                        │ USER LOGS IN DIRECTLY  │
                        │ (Existing Credentials) │
                        └───────────┬────────────┘
                                    │
                                    ▼
                        ┌────────────────────────┐
                        │ CORRECT DASHBOARD OPENS│
                        ├────────────────────────┤
                        │ Dealer  -> Dealer Portal
                        │ Partner -> Partner Portal
                        └────────────────────────┘
```

---

## 3. Strict Architectural Guarantees & Constraints

1. **No Duplicate Authentication System**:
   Authentication relies exclusively on standard **Supabase Auth** (email/password or OTP). No secondary auth system or custom credential database is used.
2. **Zero Password Storage or Exposure**:
   Passwords are cryptographically secured by Supabase Auth (Argon2/bcrypt). Neither the Spring Boot database nor the Admin Command Center ever stores, transmits, or exposes user passwords.
3. **No Hardcoded Roles or Users**:
   All role determinations are dynamic and backed by authoritative database tables (`dealer_profiles` and `service_partner_profiles`). Hardcoded IDs (`SP-LOAN-001`, etc.) are eliminated.
4. **Instant Role Activation (Zero Token Lag)**:
   In standard Supabase setups, JWT claims do not update until token expiration (up to 1 hour) or manual signout. PropZen solves this via backend **Authoritative Role Mapping** (`RoleMappingService.java`), which checks the database status on every incoming request and promotes the principal's authorities dynamically to `ROLE_DEALER` or `ROLE_SERVICE_PARTNER`.

---

## 4. Backend Implementation Details

### A. Authoritative Role Promotion (`RoleMappingService.java`)
```java
// On each authenticated request:
if (dealerProfileRepository.existsByUserIdAndStatus(userId, "APPROVED")) {
    authorities.add(new SimpleGrantedAuthority("ROLE_DEALER"));
}
if (servicePartnerProfileRepository.existsByUserIdAndPartnerStatus(userId, PartnerStatus.APPROVED)) {
    authorities.add(new SimpleGrantedAuthority("ROLE_SERVICE_PARTNER"));
}
```
This guarantees that the exact millisecond an Admin approves an application, any subsequent API request made by the user receives the authoritative role.

### B. Admin Endpoints (`AdminDealerController` & `AdminServicePartnerController`)
- `PATCH /api/v1/admin/dealers/{dealerId}/status`
  - Body: `{"status": "APPROVED", "verificationNotes": "..."}`
  - Updates `dealer_profiles.status = 'APPROVED'` and `is_verified = true`.
- `PATCH /api/v1/admin/service-partners/{partnerId}/status`
  - Body: `{"status": "APPROVED", "notes": "..."}`
  - Updates `service_partner_profiles.partner_status = 'APPROVED'` and `is_verified = true`.

---

## 5. Frontend Implementation Details

### A. Database Alignment (`SupabaseService.dart`)
- Updated table targets from deprecated `'dealers'` to PostgreSQL schema `'dealer_profiles'`:
  - `saveDealer`: saves to `'dealer_profiles'` with fields `agency_name`, `license_number`, `status: 'PENDING'`.
  - `fetchDealers`: queries `'dealer_profiles'` ordered by `created_at desc`.
  - `updateDealerStatus`: updates `'dealer_profiles.status'`.
  - `checkDealerAuthorization`: queries `'dealer_profiles'` to verify active status.

### B. Admin Service Integration (`AdminCommandService.dart`)
- Direct Spring Boot REST integration with automated rollback:
  - `updateDealerVerificationStatus`: calls `PATCH /api/v1/admin/dealers/{dealerId}/status`.
  - `verifyServicePartner`, `rejectServicePartner`, `suspendServicePartner`: call `PATCH /api/v1/admin/service-partners/{partnerId}/status`.

### C. Login Role Redirection (`DualAuthScreen` & `AuthService`)
- On user authentication:
  1. Checks if user email matches designated admin (`dubeysakshi618@gmail.com`) -> Admin Panel.
  2. Queries `dealer_profiles` where `user_id == currentUserId` and `status == 'APPROVED'` -> **Dealer Dashboard** (`DealerDashboardScreen`).
  3. Queries `service_partner_profiles` where `user_id == currentUserId` and `partner_status == 'APPROVED'` -> **Specialized Service Partner Dashboard**.
  4. Only standard buyers without approved partner/dealer status open the standard consumer feed.

---

## 6. Automated Integration Tests
The complete workflow is verified via `AdminApprovalWorkflowIntegrationTest.java`:
1. `testDealerApproval_EnablesDealerRoleImmediately`:
   - Creates dealer profile in `PENDING` status.
   - Verifies user initially lacks `ROLE_DEALER`.
   - Admin approves via `PATCH /api/v1/admin/dealers/{id}/status`.
   - Role mapping dynamically promotes user authorities to `ROLE_DEALER`.
2. `testServicePartnerApproval_EnablesServicePartnerRoleImmediately`:
   - Creates service partner profile in `PENDING` status.
   - Admin approves via `PATCH /api/v1/admin/service-partners/{id}/status`.
   - Role mapping dynamically promotes user authorities to `ROLE_SERVICE_PARTNER`.
3. `testRejectionAndSuspension_RevokesAuthoritiesImmediately`:
   - Admin rejects or suspends profile.
   - Verified that elevated role authorities are instantly revoked.
