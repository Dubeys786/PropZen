# PropZen Database Architecture & Integration Guide

This document establishes the official database connection, schema mapping, migration management, and security strategy for the PropZen Java / Spring Boot 3.3.3 backend connecting to the live Supabase PostgreSQL database.

---

## 1. Authoritative Database Architecture

* **Database Engine**: PostgreSQL 15+ hosted on Supabase.
* **Project Identifier**: `eemxylswyvhsyzllcsnp`
* **Canonical Host**: `db.eemxylswyvhsyzllcsnp.supabase.co:5432/postgres`
* **Connection Protocol**: Standard JDBC via `org.postgresql.Driver` with SSL enabled (`sslmode=require`).
* **Multi-Client Topology**:
  - **Flutter & Web Frontend**: Read/Write via Supabase Client / PostgREST using anonymous publishable key and user JWT tokens.
  - **Java Spring Boot Backend**: Direct transactional connection via JDBC connection pool using server-side database credentials.
  - **Python Verification & AI Services**: Read/Write via HTTPS PostgREST / Supabase Python SDK.

---

## 2. Environment Configuration

All database credentials must be supplied via environment variables. Under no circumstances should database passwords or privileged keys be committed to Git.

### Environment Variables Template
```properties
# Primary JDBC Connection URL
DATABASE_URL=jdbc:postgresql://db.eemxylswyvhsyzllcsnp.supabase.co:5432/postgres?sslmode=require

# Database Authentication
DATABASE_USERNAME=postgres
DATABASE_PASSWORD=your_supabase_db_password_here

# Connection Pool (HikariCP)
DB_POOL_MAX_SIZE=10
DB_POOL_MIN_IDLE=2
DB_CONNECTION_TIMEOUT=30000
DB_IDLE_TIMEOUT=600000
DB_MAX_LIFETIME=1800000
DB_KEEPALIVE_TIME=30000

# Hibernate / JPA Schema Strategy
HIBERNATE_DDL_AUTO=validate
```

---

## 3. HikariCP Connection Pool Guidelines

Supabase instances have finite database connection limits (often 60–100 total connections on standard tiers shared with PostgREST, Auth, and Realtime).

To prevent connection exhaustion:
1. **Conservative Pool Size**: Set `maximum-pool-size=10` per backend instance.
2. **Aggressive Keepalive**: Set `keepalive-time=30000` (30s) to prevent cloud firewalls and NAT gateways from silently terminating idle connections.
3. **Lifetime Safety**: Set `max-lifetime=1800000` (30m) ensuring connections are cycled before Supabase pooler timeouts.
4. **Connection Timeout**: Set `connection-timeout=30000` (30s) to fail cleanly with sanitized errors if pool is saturated.

---

## 4. Live Schema Discovery & Ground Truth (Phase 2 Findings)

Direct inspection of the live Supabase database revealed the following active tables and verified schemas:

### A. `public.users` (Verified Live Data)
* **Primary Key**: `id` (`UUID`)
* **Live Record Discovered**: `id`, `full_name`, `email`, `phone`, `role` (`Buyer/Owner/Tenant`), `is_email_verified` (`false`), `last_login_at`, `created_at`, `metadata`.
* **Constraints**: Unique index on `email`, unique index on `phone`.

### B. `public.posted_properties` (Verified Live Table/View)
* **Primary Key**: `id` (`TEXT`)
* **Columns**: `id`, `title`, `city`, `sector`, `property_type`, `bhk`, `price_cr`, `sqft`, `owner_name`, `owner_phone`, `status`, `created_at`, `metadata`.

### C. `public.enquiries` (Verified Live Table)
* **Primary Key**: `id` (`TEXT`)
* **Verified Columns**: `id`, `property_id`, `property_title`, `user_name`, `user_email`, `user_phone`, `message`, `status`, `enquiry_type`, `created_at`, `metadata`.
* **Critical Finding**: Column naming uses `user_name`, `user_email`, and `user_phone` (not `client_name`).

### D. `public.site_visits` (Verified Live Data)
* **Primary Key**: `id` (`TEXT`)
* **Live Record Discovered**: `id`, `property_id`, `property_title`, `user_name`, `user_email`, `user_phone`, `visit_date`, `time_slot`, `visitor_count`, `cab_required`, `status`, `created_at`, `metadata`.

### E. `public.profiles`, `conversations`, `conversation_members`, `messages`
* Active supporting tables for user accounts and messaging channels.

---

## 5. Flyway Migration Strategy

### Baseline Versioning
Because the live Supabase database already contains active production tables and user records, Flyway is configured with **safe baseline mode**:
* `spring.flyway.baseline-on-migrate=true`
* `spring.flyway.baseline-version=0`
* `spring.flyway.baseline-description="Supabase Live Baseline"`
* Location: `classpath:db/migration/`

### Migration Rules
1. **Never Recreate Existing Tables**: Do not write migrations that attempt to `CREATE TABLE users` or `CREATE TABLE properties` over existing live tables.
2. **No Destructive DDL**: `DROP TABLE`, `DROP COLUMN`, and `TRUNCATE` are strictly forbidden.
3. **Forward-Only Incremental Changes**: Any new tables or columns required by the Java backend must be added in forward-only numbered migration scripts (`V2__add_dealer_tax_reference.sql`, `V3__...`).
4. **Idempotency & IF NOT EXISTS**: All scripts must use `IF NOT EXISTS` guards.

---

## 6. Hibernate & JPA Safety Rules

* **Production Profile**: `spring.jpa.hibernate.ddl-auto=validate`
  - Hibernate only verifies that entity mappings match the physical database columns.
  - It will **never** alter, drop, or create tables on Supabase.
* **Test Profile**: `spring.jpa.hibernate.ddl-auto=create-drop`
  - Active only during automated tests running against the in-memory H2 database (`application-test.yml`).
* **Open-In-View**: Disabled (`open-in-view=false`) across all environments to eliminate unclosed connection warnings and prevent N+1 queries during serialization.

---

## 7. Row Level Security (RLS) Awareness

* Existing Supabase tables (`users`, `saved_properties`, `compared_properties`, `site_visits`, etc.) have Row Level Security enabled (`ALTER TABLE ... ENABLE ROW LEVEL SECURITY`).
* When Java Spring Boot connects via JDBC using the `postgres` user, it operates with superuser / table owner privileges, bypassing PostgreSQL RLS policies.
* **Security Mandate**: Because the Java backend bypasses RLS at the database layer, **all user authorization, tenant ownership, and resource permissions must be strictly enforced in the Java Service Layer** via Spring Security `@PreAuthorize` and ownership validation before querying or modifying records.

---

## 8. Backup & Production Migration Protocol

Before applying any schema-altering migration to the live Supabase environment:
1. **Trigger Supabase Backup**: Request a manual snapshot via the Supabase Dashboard (`Project Settings -> Database -> Backups -> Create Backup`).
2. **Review Execution Plan**: Run the SQL script manually on a staging database branch or review with the database administrator.
3. **Deploy Migration**: Start the Java backend with Flyway enabled to automatically apply pending migrations in a transactional block.
