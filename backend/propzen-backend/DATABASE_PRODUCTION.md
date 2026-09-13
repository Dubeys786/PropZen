# PropZen Production Database Architecture & Operations

## 1. Overview
The PropZen production database is hosted on **Supabase Managed PostgreSQL** (`eemxylswyvhsyzllcsnp.supabase.co`).
It serves as the single source of truth across all PropZen entities, services, CRM, and authentication records.

- **Engine**: PostgreSQL 15+
- **Connection Mode**: HikariCP Connection Pool over TLSv1.3 (port 5432 / pooler 6543)
- **Schema Management**: Flyway Automated Database Migrations
- **Primary Schema**: `public`

---

## 2. Migration History (Flyway)

| Version | Migration Script | Description |
|---|---|---|
| `V1` | `V1__init_schema.sql` | Users, roles, dealer profiles, basic property structures |
| `V2` | `V2__property_expansion.sql` | Detailed property attributes, media arrays, specs, location |
| `V3` | `V3__service_management_schema.sql` | Service categories, service partners, service requests |
| `V4` | `V4__service_milestones_and_payments.sql` | Milestones, payments, verification documents, feedback |
| `V5` | `V5__crm_and_automation_schema.sql` | CRM leads, tasks, follow-ups, message templates, outbox |
| `V6` | `V6__crm_indexes_and_optimizations.sql` | Performance indexes for CRM queries and deduplication |
| `V7` | `V7__production_hardening_and_indexes.sql` | Audit logs, in-app notifications, deliverables, composite B-tree indexes |

---

## 3. Production Indexing & Optimization Strategy

The following high-performance composite and partial B-Tree indexes are deployed via `V7__production_hardening_and_indexes.sql`:

```sql
-- Property query performance
CREATE INDEX IF NOT EXISTS idx_properties_status_city_price ON posted_properties (status, city, price_cr);
CREATE INDEX IF NOT EXISTS idx_properties_dealer_status ON posted_properties (dealer_id, status);

-- CRM Lead pipeline & deduplication
CREATE INDEX IF NOT EXISTS idx_crm_leads_phone_status ON crm_leads (phone, status);
CREATE INDEX IF NOT EXISTS idx_crm_leads_assigned_stage ON crm_leads (assigned_to, stage);

-- Scheduled tasks and follow-up worker efficiency
CREATE INDEX IF NOT EXISTS idx_crm_tasks_status_due ON crm_tasks (status, due_date);
CREATE INDEX IF NOT EXISTS idx_crm_followups_scheduled_status ON crm_followups (scheduled_at, status);

-- Service Management tracking & deliverables
CREATE INDEX IF NOT EXISTS idx_service_requests_customer_status ON service_requests (customer_id, status);
CREATE INDEX IF NOT EXISTS idx_service_requests_partner_status ON service_requests (partner_id, status);
CREATE INDEX IF NOT EXISTS idx_service_deliverables_req ON service_deliverables (service_request_id);

-- Payment status and gateway lookups
CREATE INDEX IF NOT EXISTS idx_service_payments_status_gateway ON service_payments (status, gateway_order_id);

-- In-App Notifications
CREATE INDEX IF NOT EXISTS idx_notifications_user_status ON notifications (user_id, status, sent_at DESC);

-- Audit Log compliance
CREATE INDEX IF NOT EXISTS idx_audit_logs_actor_timestamp ON audit_logs (actor_id, timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_audit_logs_action ON audit_logs (action, timestamp DESC);
```

---

## 4. Connection Pool Configuration (HikariCP)

Configured in `application.yml` and `application-prod.yml`:

| Parameter | Production Value | Description |
|---|---|---|
| `maximum-pool-size` | `20` | Max simultaneous connections per container instance |
| `minimum-idle` | `5` | Kept hot for low-latency request servicing |
| `idle-timeout` | `300000` (5 min) | Maximum time connection may sit idle |
| `connection-timeout` | `30000` (30 sec) | Max time client waits for pool connection |
| `max-lifetime` | `1800000` (30 min) | Max lifetime of connection before recycling |
| `leak-detection-threshold` | `60000` (1 min) | Emits warning if connection borrowed > 60s |

---

## 5. Security & Isolation
1. **Row Level Security (RLS)**: Supabase PostgreSQL tables utilize RLS for direct client queries where applicable, while Spring Boot acts as authoritative backend using service credentials.
2. **Data-at-Rest Encryption**: Encrypted with AES-256 in Supabase AWS/GCP infrastructure.
3. **Data-in-Transit Encryption**: All connections enforce `sslmode=require` with TLS 1.3.
