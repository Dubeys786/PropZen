# PropZen Environment Variables Reference

This document provides a comprehensive reference of all environment variables required or supported by the PropZen Java Spring Boot backend across environments (`dev`, `staging`, `prod`).

---

## 1. Core Server & Profile

| Variable | Default Value | Production Example | Description |
|---|---|---|---|
| `SERVER_PORT` | `8080` | `8080` | Port on which the Spring Boot HTTP server listens |
| `SPRING_PROFILES_ACTIVE` | `dev` | `prod` | Active Spring profile (`dev`, `staging`, `prod`, `test`) |

---

## 2. Supabase PostgreSQL Database

| Variable | Required | Production Example | Description |
|---|---|---|---|
| `SPRING_DATASOURCE_URL` | **Yes** | `jdbc:postgresql://eemxylswyvhsyzllcsnp.supabase.co:5432/postgres?sslmode=require` | JDBC connection URL with SSL |
| `SPRING_DATASOURCE_USERNAME` | **Yes** | `postgres` | Database superuser/service account |
| `SPRING_DATASOURCE_PASSWORD` | **Yes** | `[SECURE_DB_PASSWORD]` | Database password |
| `SPRING_DATASOURCE_HIKARI_MAXIMUM_POOL_SIZE` | No | `20` | Max pooled JDBC connections per node |
| `SPRING_DATASOURCE_HIKARI_MINIMUM_IDLE` | No | `5` | Min idle connections maintained |

---

## 3. Authentication & Security (Supabase JWT)

| Variable | Required | Production Example | Description |
|---|---|---|---|
| `SUPABASE_JWT_SECRET` | **Yes** | `[SECURE_MIN_32_CHAR_SECRET]` | Secret used to sign and verify Supabase JWTs |
| `SUPABASE_URL` | **Yes** | `https://eemxylswyvhsyzllcsnp.supabase.co` | Base URL of Supabase project |
| `SUPABASE_SERVICE_ROLE_KEY` | **Yes** | `eyJhbGciOiJIUzI1Ni...` | Service role key for administrative tasks |
| `CORS_ALLOWED_ORIGINS` | No | `https://app.propzen.ai,https://admin.propzen.ai` | Comma-separated CORS allowed origins |

---

## 4. Meta WhatsApp Business Cloud API

| Variable | Required | Production Example | Description |
|---|---|---|---|
| `META_WHATSAPP_PHONE_NUMBER_ID` | Yes | `102938475619283` | Meta WhatsApp Phone Number ID |
| `META_WHATSAPP_ACCESS_TOKEN` | Yes | `EAAG...` | Meta Graph API permanent system user token |
| `META_WHATSAPP_API_VERSION` | No | `v18.0` | Meta Graph API version |

---

## 5. Payment Gateways

| Variable | Required | Production Example | Description |
|---|---|---|---|
| `RAZORPAY_KEY_ID` | Yes | `rzp_live_...` | Razorpay Merchant Key ID |
| `RAZORPAY_KEY_SECRET` | Yes | `[SECURE_SECRET]` | Razorpay Key Secret |
| `CASHFREE_CLIENT_ID` | Optional | `CF_APP_...` | Cashfree Client ID |
| `CASHFREE_CLIENT_SECRET` | Optional | `[SECURE_SECRET]` | Cashfree Secret |
| `PAYU_MERCHANT_KEY` | Optional | `merchant_key_...` | PayU Merchant Key |
| `PAYU_MERCHANT_SALT` | Optional | `[SECURE_SALT]` | PayU Merchant Salt |

---

## 6. Document Storage & Upload Signing

| Variable | Required | Production Example | Description |
|---|---|---|---|
| `STORAGE_BUCKET_NAME` | No | `service-documents` | Default Supabase storage bucket |
| `STORAGE_SIGNING_KEY` | Yes | `[SECURE_HMAC_KEY]` | Key used to generate tamper-proof upload URLs |
| `STORAGE_URL_EXPIRY_SECONDS` | No | `3600` | Expiry duration for signed download/upload URLs |
