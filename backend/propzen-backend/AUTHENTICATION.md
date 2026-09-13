# PropZen Authentication Architecture & Integration Guide

This document describes the end-to-end authentication flow between the PropZen Flutter/Web frontend, Supabase Auth, and the Java Spring Boot 3.3.3 backend.

---

## 1. Architectural Overview

PropZen employs a **Stateless Bearer JWT Trust Architecture**. The Java backend does not manage user passwords or duplicate Supabase authentication state. Instead, Supabase Auth acts as the authoritative Identity Provider (IdP), and Spring Boot acts as a secured Resource Server validating cryptographic JWT signatures.

```
PropZen Flutter / Web App
        │
        ▼ (Email / Password or OTP)
Supabase Auth (https://eemxylswyvhsyzllcsnp.supabase.co/auth/v1)
        │
        ▼ (Issues RS256/ES256/HS256 Bearer JWT)
Client saves 'propzen_supabase_access_token'
        │
        ▼ HTTP Request with header:
        ▼ Authorization: Bearer <SUPABASE_ACCESS_TOKEN>
Java Spring Boot 3.3.3 Backend (port 8080)
        │
        ├─► [SupabaseJwtAuthenticationFilter]
        │   └─► Extracts token from 'Authorization' header
        │
        ├─► [SupabaseJwtValidator]
        │   ├─► Verifies cryptographic signature (ES256 via Supabase JWKS or HS256)
        │   ├─► Validates token expiration ('exp')
        │   ├─► Validates audience ('aud: authenticated')
        │   └─► Extracts subject UUID ('sub') & metadata
        │
        ├─► [RoleMappingService]
        │   └─► Maps claims + DB state to GrantedAuthorities (ROLE_BUYER, ROLE_DEALER, ROLE_ADMIN, ROLE_STAFF)
        │
        ├─► [SecurityContextHolder]
        │   └─► Sets UsernamePasswordAuthenticationToken with AuthenticatedUser principal
        │
        └─► Controller / Service execution with @PreAuthorize protection
```

---

## 2. Token Flow & Frontend Integration Contract

### Step 1: User Signs In
The user logs in via the existing Flutter or Web application using Supabase Auth (`lib/services/auth_service.dart`):
```dart
final response = await supabase.auth.signInWithPassword(
  email: 'user@example.com',
  password: 'userpassword'
);
final accessToken = response.session?.accessToken;
```

### Step 2: Calling Java Backend APIs
Whenever the frontend communicates with the Java backend (`http://localhost:8080` or `https://api.propzen.ai`), it passes the retrieved access token:

```http
GET /api/v1/auth/me HTTP/1.1
Host: api.propzen.ai
Authorization: Bearer eyJhbGciOiJFUzI1NiIsImtpZCI6ImUwM2Q3NGFk...
Accept: application/json
```

### Step 3: Standard Response Envelope (HTTP 200)
```json
{
  "success": true,
  "data": {
    "authenticated": true,
    "userId": "1760d4f8-e0c7-4abf-96cf-01d83c368419",
    "email": "dubeysakshi618@gmail.com",
    "phone": "9810394068",
    "roles": [
      "ROLE_ADMIN",
      "ROLE_BUYER",
      "ROLE_DEALER",
      "ROLE_STAFF"
    ]
  },
  "message": "Authenticated user context retrieved successfully",
  "timestamp": "2026-09-08T15:03:00Z",
  "requestId": "a90fa7bb-9973-4555-83aa-6c04f9810f6e"
}
```

---

## 3. Server-Side Role-Based Access Control (RBAC)

The backend never trusts a role or user ID supplied in the request body, query parameters, or client headers. Role mapping follows strict server-side rules in `RoleMappingService`:

| Client / Database Role | Granted Authorities | Permitted Scope |
| :--- | :--- | :--- |
| `Buyer`, `customer`, `Owner`, `Tenant`, `Buyer/Owner/Tenant` | `ROLE_BUYER` | Property discovery, booking visits, creating enquiries, submitting verification cases. |
| `Dealer`, `verified_dealer`, `approved_dealer` | `ROLE_DEALER`, `ROLE_BUYER` | Dealer portal, listing properties, viewing incoming leads and visits. |
| `Staff`, `verification_agent`, `service_partner` | `ROLE_STAFF`, `ROLE_BUYER` | Operational tasks, assigned verifications, service fulfillments. |
| `Admin`, `super_admin` (Cryptographically verified) | `ROLE_ADMIN`, `ROLE_DEALER`, `ROLE_STAFF`, `ROLE_BUYER` | Platform administration, dealer verifications, audit logs, global configuration. |

### Strict Admin Governance
Admin authority is **never** granted merely because a user sets a role string in their client profile or request body:
* Admin authority is derived from trusted server-side sources:
  1. Cryptographically verified Supabase claims (`app_metadata.role` contains `admin`/`super_admin`/`administrator`). Client-writable claims (`user_metadata`) are strictly rejected for administrative access.
  2. Authoritative database records (`public.users.role = 'ADMIN'`).
* Optional Bootstrap Allowlist: `PROPZEN_BOOTSTRAP_ADMIN_EMAILS` environment variable allows setup allowlists during initial provisioning without hardcoding production emails in code.

---

## 4. Error Handling (401 vs 403)

All authentication and authorization errors return the standardized PropZen `ApiResponse` without leaking stack traces or cryptographic validation internals:

### Missing or Invalid Token (HTTP 401 Unauthorized)
```json
{
  "success": false,
  "error": {
    "code": "UNAUTHORIZED",
    "message": "Authentication required. Please provide a valid Supabase Bearer token."
  },
  "timestamp": "2026-09-08T15:03:00Z",
  "requestId": "6ec6daeb-6548-433b-8534-c7df0e7fc239"
}
```

### Insufficient Privileges (HTTP 403 Forbidden)
```json
{
  "success": false,
  "error": {
    "code": "FORBIDDEN",
    "message": "Access denied: Insufficient role permissions to access this resource."
  },
  "timestamp": "2026-09-08T15:03:00Z",
  "requestId": "6ec6daeb-6548-433b-8534-c7df0e7fc239"
}
```

---

## 5. Security & Secret Management

1. **No Secret Tokens in Logs**: `RequestLoggingFilter` strictly omits `Authorization` headers, JWT strings, and credentials from log output.
2. **Asymmetric Public Verification**: In production, Supabase public keys are fetched from the live JWKS endpoint (`https://eemxylswyvhsyzllcsnp.supabase.co/auth/v1/.well-known/jwks.json`), meaning the application does not need to store sensitive private keys.
3. **No User Spoofing**: Service layer methods use `CurrentUserService.getRequiredCurrentUser().getId()` to obtain user identity rather than accepting `userId` from request bodies.
