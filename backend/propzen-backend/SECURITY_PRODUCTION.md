# PropZen Production Security & Secrets Architecture

## 1. Zero Trust & Security Principles
- **Authoritative JWT Validation**: All requests are validated against Supabase Auth HMAC-SHA256 / Ed25519 signatures.
- **Strict Role-Based Access Control (RBAC)**: Enforced through `RoleMappingService`, `AdminCheckFilter`, `@PreAuthorize`, and entity-level ownership validation.
- **Defense in Depth**: IP-level rate limiting, strict CORS allowlisting, CSP headers, and parameter tamper-proofing.

---

## 2. Secrets Management

### 2.1 Principle of No Committed Secrets
- No production database credentials, API keys, webhook secrets, or private tokens are stored in the git repository.
- `.env` and `.env.prod` are strictly ignored by git (`.gitignore`).
- Production secrets are injected at runtime via Kubernetes Secrets, AWS Secrets Manager, or Doppler.

### 2.2 Critical Production Secret Matrix

| Secret Key | Source / Provider | Rotation Frequency | Purpose |
|---|---|---|---|
| `SUPABASE_JWT_SECRET` | Supabase Project Settings | Annual / Incident | Verification of Bearer tokens |
| `SPRING_DATASOURCE_PASSWORD` | Supabase DB Password | Bi-annual | High-performance DB connection pool |
| `META_WHATSAPP_ACCESS_TOKEN` | Meta Graph API Developer Portal | 60 Days / System User Token | Official WhatsApp Cloud API messages |
| `RAZORPAY_KEY_SECRET` | Razorpay Dashboard | Annual | Payment signature verification |
| `CASHFREE_CLIENT_SECRET` | Cashfree Dashboard | Annual | PG order creation & signature verification |
| `PAYU_MERCHANT_SALT` | PayU Merchant Portal | Annual | Reverse hash verification |
| `STORAGE_SIGNING_KEY` | PropZen IAM / KMS | Annual | Signed document upload authorization |

---

## 3. Network & Transport Security
1. **TLS / SSL**: Enforce TLS 1.3 only; cipher suites restricted to AES-GCM / ChaCha20-Poly1305.
2. **Reverse Proxy Rate Limiting**:
   - Application-level: `RateLimitingFilter` enforces 100 req/min per client IP.
   - Gateway-level: Cloudflare / AWS WAF protects against volumetric DDoS and Layer 7 attacks.
3. **HTTP Security Headers**:
   ```http
   Strict-Transport-Security: max-age=31536000; includeSubDomains; preload
   X-Content-Type-Options: nosniff
   X-Frame-Options: SAMEORIGIN
   Content-Security-Policy: default-src 'self'; frame-ancestors 'self';
   Cache-Control: no-cache, no-store, max-age=0, must-revalidate
   ```

---

## 4. Audit & Compliance
- All sensitive admin actions, campaign dispatches, milestone approvals, and security modifications are permanently logged to PostgreSQL table `audit_logs`.
- Logs include: `actor_id`, `action`, `target_type`, `target_id`, `details`, `ip_address`, and ISO-8601 timestamp.
