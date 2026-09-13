# PropZen Disaster Recovery (DR) & Business Continuity Plan

## 1. Objectives & Metrics
- **RPO (Recovery Point Objective)**: <= 1 Hour (maximum data loss acceptable)
- **RTO (Recovery Time Objective)**: <= 30 Minutes (maximum downtime for complete service restoration)

---

## 2. Backup Strategy

### 2.1 Database (Supabase Managed PostgreSQL)
1. **Automated Continuous WAL Archiving**:
   - Write-Ahead Logs (WAL) continuously streamed to S3-compatible cloud storage.
   - Enables Point-in-Time Recovery (PITR) up to the minute within the last 7 days.
2. **Daily Physical Backups**:
   - Automated full snapshot taken daily at 02:00 UTC.
   - Retained for 30 days in geographically separated storage tier.
3. **Weekly Logical Dumps**:
   - `pg_dump` automated job executes every Sunday at 03:00 UTC:
     ```bash
     pg_dump -h eemxylswyvhsyzllcsnp.supabase.co -U postgres -d postgres -F c -b -v -f /backups/propzen_$(date +%Y%m%d).dump
     ```

### 2.2 Storage Assets (Supabase Storage)
- User documents, contracts, deliverables, and inspection files stored in S3 object storage with versioning enabled.
- Cross-region replication enabled to secondary failover region.

---

## 3. Disaster Recovery Scenarios & Execution

### Scenario A: Primary Database Regional Outage
1. **Detection**: Healthcheck probe `/api/v1/health/readiness` fails repeatedly, emitting P1 alert.
2. **Failover Execution**:
   - Switch DNS / connection string `SPRING_DATASOURCE_URL` to the secondary hot standby replica.
   - Trigger Spring Boot container rolling restart with updated credentials.
   - Verify connection pool health via Actuator `/actuator/health`.

### Scenario B: Application Node Failure
1. **Detection**: Container orchestrator (K8s/ECS) fails liveness probe `/api/v1/health/liveness`.
2. **Remediation**:
   - Orchestrator automatically restarts unhealthy pod/container within 10 seconds.
   - Zero customer impact due to minimum 2 active replicas behind reverse proxy load balancer.

### Scenario C: Unintended Schema Corruption / Malicious Deletion
1. Initiate Supabase Point-in-Time Recovery (PITR) to timestamp immediately preceding incident (T - 5 minutes).
2. Restore to isolated recovery database.
3. Run delta migration or sync to bring recovery database current.
4. Repoint application to recovered database instance.

---

## 4. DR Drills & Validation Schedule
- **Bi-Annual Simulated Failover Drill**: Scheduled in staging environment to validate RTO under 30 minutes.
- **Monthly Snapshot Restoration Test**: Automated validation script restores the latest `pg_dump` to an ephemeral container to test integrity.
