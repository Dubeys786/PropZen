# PropZen Java Enterprise Backend

Enterprise-grade Spring Boot 3.x backend for the PropZen real-estate discovery, intelligence, and verification platform.

---

## 1. Overview & Architecture

The PropZen Java backend provides high-performance REST APIs designed to support:
* **Property Discovery & Search**: Multi-criteria indexing, dynamic filtering (BHK, price, locality, amenities).
* **Dealer Operations**: Secure profile management, listing lifecycles, enquiry tracking, and site visit scheduling.
* **Customer Services**: Property inquiries, site visit bookings with cab requests, service hub requests.
* **AI-Assisted Verification**: Deterministic document checks, cross-document reconciliation, and explainable risk scoring.
* **Admin Operations**: Multi-role governance, verification audits, property approvals, and system metrics.

### Architecture Highlights
* **Clean Layered Architecture**: Strict separation of concern across `controller`, `service`, `repository`, `entity`, and `dto`.
* **Zero Database Duplication**: Connects directly to the existing PropZen Supabase PostgreSQL instance (`eemxylswyvhsyzllcsnp`).
* **Supabase JWT Trust Model**: Validates Supabase-issued Bearer JWTs via Spring Security without storing duplicate plaintext credentials.
* **Standardized JSON Envelope**: Every response adheres to the `{ success, data, message, timestamp, requestId }` contract.
* **OpenAPI 3 / Swagger Documentation**: Full interactive documentation at `/swagger-ui.html`.

---

## 2. Prerequisites

* **Java**: JDK 17 or JDK 21
* **Build Tool**: Apache Maven 3.8+ (or included Maven wrapper `mvnw` / `mvnw.cmd`)
* **Database**: PostgreSQL 14+ or Supabase project access
* **Docker** *(Optional)*: Docker 24+ and Docker Compose v2+

---

## 3. Environment Configuration

1. Copy `.env.example` to `.env` or configure system environment variables:
   ```bash
   cp .env.example .env
   ```

2. Key Configuration Variables:
   | Variable | Description | Example Default |
   | :--- | :--- | :--- |
   | `PORT` | HTTP Server port | `8080` |
   | `SPRING_PROFILES_ACTIVE` | Active profile (`dev`, `prod`, `test`) | `dev` |
   | `DATABASE_URL` | JDBC PostgreSQL connection string | `jdbc:postgresql://db...supabase.co:5432/postgres` |
   | `DATABASE_USERNAME` | Database username | `postgres` |
   | `DATABASE_PASSWORD` | Database password | `your_secret_password` |
   | `SUPABASE_URL` | Supabase endpoint | `https://eemxylswyvhsyzllcsnp.supabase.co` |
   | `SUPABASE_ANON_KEY` | Public Supabase anon key | `sb_publishable_...` |
   | `PROPZEN_ALLOWED_ORIGINS` | Comma-separated CORS whitelist | `http://localhost:3000,https://propzen.ai` |

---

## 4. Local Development & Running

### Using Maven Wrapper (Windows PowerShell)
```powershell
# Run backend locally in dev profile
.\mvnw.cmd spring-boot:run
```

### Using Maven (Linux / macOS)
```bash
./mvnw spring-boot:run
```

Once started:
* **Health Check**: [http://localhost:8080/api/v1/health](http://localhost:8080/api/v1/health)
* **Swagger UI**: [http://localhost:8080/swagger-ui.html](http://localhost:8080/swagger-ui.html)
* **OpenAPI Specs**: [http://localhost:8080/v3/api-docs](http://localhost:8080/v3/api-docs)

---

## 5. Testing

The project includes unit and integration tests covering the application context, standardized responses, global exception mapping, and health check probes.

```powershell
# Run the complete test suite
.\mvnw.cmd clean test
```

Tests execute against an in-memory PostgreSQL-compatible H2 instance (`application-test.yml`) to guarantee fast, zero-network, reproducible test runs.

---

## 6. Docker Deployment

### Build and Run with Docker
```bash
docker build -t propzen-backend:1.0.0 .
docker run -p 8080:8080 --env-file .env propzen-backend:1.0.0
```

### Run with Docker Compose
```bash
docker compose up -d
```

---

## 7. Standardized API Response Specification

### Success Envelope (HTTP 200 / 201)
```json
{
  "success": true,
  "data": {
    "status": "UP",
    "database": "UP",
    "version": "1.0.0",
    "environment": "[dev]"
  },
  "message": "PropZen Backend is healthy and operational",
  "timestamp": "2026-09-08T14:40:00Z",
  "requestId": "6a62f558-81fa-4f51-a548-26f5717ef745"
}
```

### Error Envelope (HTTP 4xx / 5xx)
```json
{
  "success": false,
  "error": {
    "code": "RESOURCE_NOT_FOUND",
    "message": "Property with identifier 'prop-999' was not found",
    "details": null
  },
  "timestamp": "2026-09-08T14:40:00Z",
  "requestId": "6a62f558-81fa-4f51-a548-26f5717ef745"
}
```

---

## 8. Frontend Integration Strategy

* **Current Architecture**: Flutter/Web -> Supabase REST / PostgREST.
* **Target Architecture**: Flutter/Web -> Java Spring Boot -> Supabase PostgreSQL.
* **Migration Plan**: Modules migrate incrementally (`/api/v1/properties`, `/api/v1/enquiries`, `/api/v1/site-visits`, `/api/v1/dealers`) without breaking existing direct Supabase queries during transition.
