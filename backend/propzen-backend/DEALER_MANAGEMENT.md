# PropZen Dealer Management Architecture

This document specifies the dealer onboarding, lifecycle state management, verification, server-side role activation, and authorization policies in the PropZen Java / Spring Boot 3.3.3 backend.

---

## 1. Core Principles

1. **Explicit Onboarding & Application Lifecycle**:
   - Any authenticated user (e.g. `ROLE_BUYER`) can submit a dealer application.
   - Applications start in `PENDING` state and require administrative review.
   - Dealers cannot self-approve or alter their own verification status.

2. **Server-Side Authoritative Role Activation**:
   - When an administrator approves a dealer application (`PATCH /api/v1/admin/dealers/{id}/status` -> `APPROVED`):
     1. `dealer_profiles.status` transitions to `APPROVED`.
     2. `dealer_profiles.verification_status` transitions to `VERIFIED`.
     3. `reviewed_by` and `reviewed_at` are recorded.
     4. **Database Role Activation**: The user's authoritative record in `public.users` is updated to `role = 'DEALER'`.
   - On future requests, `RoleMappingService` reads the database role and grants `ROLE_DEALER` server-side, enabling access to protected dealer modules.
   - When suspended (`SUSPENDED`), the user's role is demoted back to `Buyer`.

3. **Strict State Machine**:
   - `PENDING` -> `UNDER_REVIEW`, `APPROVED`, `REJECTED`
   - `UNDER_REVIEW` -> `APPROVED`, `REJECTED`, `PENDING`
   - `APPROVED` -> `SUSPENDED`, `UNDER_REVIEW`
   - `REJECTED` -> `UNDER_REVIEW`, `PENDING` (re-application)
   - `SUSPENDED` -> `APPROVED`, `UNDER_REVIEW`, `REJECTED`
   - Any invalid state transition is rejected with `400 Bad Request` (`INVALID_DEALER_STATUS_TRANSITION`).

4. **Ownership & Isolation**:
   - Dealers can only view and edit their own dealer profile (`/api/v1/dealers/me`).
   - Cross-dealer access to private resources is strictly forbidden by `ResourceAuthorizationService`.

---

## 2. Data Model: `public.dealer_profiles`

Created via Flyway migration `V2__create_dealer_profiles.sql`:

| Column | Type | Nullable | Description |
|---|---|---|---|
| `id` | `UUID` | No | Primary Key (Default: `gen_random_uuid()`) |
| `user_id` | `UUID` | No | Unique Foreign Key referencing `public.users(id)` |
| `business_name` | `VARCHAR(255)` | No | Legal or trade business name |
| `company_name` | `VARCHAR(255)` | Yes | Registered company name |
| `display_name` | `VARCHAR(255)` | Yes | Public marketing display name |
| `phone` | `VARCHAR(50)` | No | Primary business phone |
| `email` | `VARCHAR(255)` | No | Primary business email |
| `description` | `TEXT` | Yes | Agency overview and bio |
| `experience_years` | `INTEGER` | Yes | Years of real estate experience |
| `city` | `VARCHAR(100)` | Yes | Primary operating city / market |
| `verification_status` | `VARCHAR(50)` | No | `PENDING`, `UNDER_REVIEW`, `VERIFIED`, `REJECTED`, `SUSPENDED` |
| `status` | `VARCHAR(50)` | No | `PENDING`, `UNDER_REVIEW`, `APPROVED`, `REJECTED`, `SUSPENDED` |
| `admin_notes` | `TEXT` | Yes | Internal notes recorded by reviewing administrator |
| `reviewed_by` | `UUID` | Yes | User UUID of the reviewing administrator |
| `reviewed_at` | `TIMESTAMPTZ` | Yes | Timestamp of the review action |
| `created_at` | `TIMESTAMPTZ` | No | Record creation timestamp |
| `updated_at` | `TIMESTAMPTZ` | No | Last modification timestamp |

---

## 3. Endpoints

### A. Dealer Application
* **Method**: `POST`
* **Path**: `/api/v1/dealers/apply`
* **Authorization**: Any authenticated user
* **Request Body**:
```json
{
  "businessName": "Skyline Properties",
  "companyName": "Skyline Real Estate Pvt Ltd",
  "displayName": "Skyline Prime",
  "phone": "+91 9988776655",
  "email": "dealer@skylineproperties.in",
  "description": "Premium luxury properties in DLF Phase 5",
  "experienceYears": 8,
  "city": "Gurgaon"
}
```
* **Response Status**: `201 Created`
* **Duplicate Prevention**: If an application is already `PENDING`, `UNDER_REVIEW`, or `APPROVED`, returns `409 Conflict` (`DEALER_APPLICATION_PENDING` or `DEALER_ALREADY_EXISTS`).

### B. My Dealer Profile
* **Method**: `GET`
* **Path**: `/api/v1/dealers/me`
* **Authorization**: Authenticated user
* **Response Status**: `200 OK` (or `404 Not Found` if user has not applied)

### C. Update My Dealer Profile
* **Method**: `PATCH`
* **Path**: `/api/v1/dealers/me`
* **Authorization**: Authenticated user
* **Editable Fields**: `businessName`, `companyName`, `displayName`, `phone`, `description`, `experienceYears`, `city`.
* **Protected Fields**: `status`, `verificationStatus`, `adminNotes`, `reviewedBy`, `reviewedAt`, `userId` cannot be modified by the dealer.
* **Response Status**: `200 OK`

### D. Admin List Dealer Applications
* **Method**: `GET`
* **Path**: `/api/v1/admin/dealers`
* **Authorization**: `ROLE_ADMIN`
* **Query Parameters**:
  - `status`: optional filter by `DealerStatus`
  - `verificationStatus`: optional filter by `DealerVerificationStatus`
  - `search`: optional search term matching business name, company, email, or phone
  - `page`: page index (default: `0`)
  - `size`: page size (default: `20`)
  - `sort`: sort criteria (default: `createdAt,desc`)
* **Response Envelope**: Standardized `PageResponse<DealerProfileDto>`.

### E. Admin Get Dealer by ID
* **Method**: `GET`
* **Path**: `/api/v1/admin/dealers/{id}`
* **Authorization**: `ROLE_ADMIN`
* **Response Status**: `200 OK`

### F. Admin Update Dealer Status
* **Method**: `PATCH`
* **Path**: `/api/v1/admin/dealers/{id}/status`
* **Authorization**: `ROLE_ADMIN`
* **Request Body**:
```json
{
  "status": "APPROVED",
  "adminNotes": "RERA documents verified, physical address confirmed."
}
```
* **Response Status**: `200 OK`
* **Side Effects on Approval**:
  - Sets `status = APPROVED`, `verification_status = VERIFIED`.
  - Sets `reviewed_by = admin_uuid`, `reviewed_at = now`.
  - Upgrades `public.users.role = 'DEALER'`.
  - Logs `DEALER_STATUS_CHANGED` in structured audit log.
