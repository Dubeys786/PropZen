# PropZen User Management Architecture

This document details the user management architecture, data models, endpoints, and security constraints in the PropZen Java / Spring Boot 3.3.3 backend.

---

## 1. Core Principles

1. **Supabase Auth is Authoritative for Identity**:
   - Supabase Auth manages credentials, password resets, and session issuance.
   - The Java backend consumes Supabase-issued Bearer JWTs and cryptographically validates the token.
   - The authoritative user identifier is the UUID stored in the JWT `sub` claim.

2. **Zero-Trust User Identity**:
   - No request body or query parameter (e.g. `{"userId": "..."}`) is trusted to establish user identity.
   - Operations on the current user resolve `userId` exclusively from the validated `SecurityContext`.

3. **Restricted Profile Mutability**:
   - Users can update only safe, non-privileged fields: `fullName` and `phone`.
   - Security-critical attributes (`id`, `email`, `role`, `is_email_verified`, `created_at`, `metadata`) cannot be altered via user profile endpoints.

4. **Email Immutability in Profile API**:
   - The profile API cannot silently change the user's email.
   - Any email update must be executed through the Supabase Auth verification pipeline to maintain authentication consistency.

---

## 2. Data Model: `public.users`

Mapped via JPA Entity `com.propzen.user.entity.User` to the live database table:

| Column | Type | Nullable | Description |
|---|---|---|---|
| `id` | `UUID` | No | Primary Key, maps to Supabase `auth.users.id` |
| `full_name` | `VARCHAR(255)` | Yes | Display name of the user |
| `email` | `VARCHAR(255)` | Yes | Primary email address |
| `phone` | `VARCHAR(50)` | Yes | Contact phone number |
| `role` | `VARCHAR(50)` | Yes | Authoritative database role (`Buyer`, `DEALER`, `ADMIN`, etc.) |
| `is_email_verified` | `BOOLEAN` | Yes | Verification status from Supabase |
| `last_login_at` | `TIMESTAMPTZ` | Yes | Timestamp of last user login |
| `created_at` | `TIMESTAMPTZ` | No | Account creation timestamp |
| `metadata` | `TEXT/JSONB` | Yes | Supplemental user preferences and attributes |

---

## 3. Endpoints

### A. Get Current User Profile
* **Method**: `GET`
* **Path**: `/api/v1/users/me`
* **Authorization**: Bearer JWT (Any authenticated user)
* **Response Status**: `200 OK`
* **Response Envelope**:
```json
{
  "success": true,
  "data": {
    "id": "1760d4f8-e0c7-4abf-96cf-01d83c368419",
    "fullName": "Sakshi Dubey",
    "email": "dubeysakshi618@gmail.com",
    "phone": "+91 9810394068",
    "role": "Buyer",
    "roles": [
      "ROLE_BUYER"
    ],
    "emailVerified": true,
    "createdAt": "2026-08-18T14:01:13.102Z"
  },
  "message": "User profile retrieved successfully",
  "timestamp": "2026-09-08T15:20:00.000Z",
  "requestId": "a67bcf12-58e1-4bf1-a477-d352ce66d210"
}
```

### B. Update Current User Profile
* **Method**: `PATCH`
* **Path**: `/api/v1/users/me`
* **Authorization**: Bearer JWT (Any authenticated user)
* **Request Body**:
```json
{
  "fullName": "Sakshi Dubey",
  "phone": "+91 9810394068"
}
```
* **Validation**:
  - `fullName`: 2 to 100 characters.
  - `phone`: valid international phone number format (`^[+0-9\-\s()]{7,20}$`).
* **Response Status**: `200 OK`
* **Audit**: Records `USER_PROFILE_UPDATED` in structured audit log.

---

## 4. Frontend Integration Flow

1. Frontend initiates login via Supabase Auth client (`supabase.auth.signInWithPassword(...)`).
2. Supabase returns `session` containing `access_token` (JWT).
3. Frontend calls Java backend:
   ```http
   GET /api/v1/users/me HTTP/1.1
   Host: api.propzen.ai
   Authorization: Bearer <access_token>
   ```
4. Java backend extracts token, validates cryptographic signature via Supabase JWKS, extracts `userId`, loads `public.users` record, maps authorities, and returns the response.
