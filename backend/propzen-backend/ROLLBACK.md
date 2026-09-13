# PropZen Production Rollback Strategy & Procedures

## 1. Overview
In the event of an unrecoverable failure, critical performance regression, or severe bug introduced during deployment, the following runbook provides zero-downtime rollback procedures.

---

## 2. Fast Rollback: Container / Application Layer (< 5 Minutes)

Because our deployment strategy utilizes immutable Docker container tags (e.g. `propzen-backend:v1.0.0`):

### Kubernetes Rollback:
```bash
# Check rollout history
kubectl rollout history deployment/propzen-backend -n production

# Undo rollout to immediate previous revision
kubectl rollout undo deployment/propzen-backend -n production

# Monitor status until verified
kubectl rollout status deployment/propzen-backend -n production
```

### Docker Compose / ECS Rollback:
```bash
# Update .env to previous image tag
export APP_IMAGE_TAG=previous-stable-sha

# Re-deploy containers with zero downtime
docker compose pull
docker compose up -d --no-deps backend
```

---

## 3. Database Migration Rollback Strategy

Flyway manages migrations sequentially. To maintain backward compatibility and avoid breaking rollbacks:

### The "Expand-Contract" Architecture Rule:
1. **Never drop columns or tables in the same release as application changes.**
2. Schema migrations must be backward-compatible with at least $(N-1)$ application versions.
3. If a migration `V7` introduced new columns/tables (`audit_logs`, `notifications`, `service_deliverables`), rolling back to application `v6` continues functioning normally because the previous code simply ignores new tables and nullable columns.

### Emergency Schema Reversal:
If a migration script introduced a breaking lock or faulty constraint:
1. Create a forward rollback migration `V8__revert_problematic_change.sql`.
2. Apply migration via Flyway CLI or let application startup apply it:
   ```bash
   mvn flyway:migrate -Dflyway.configFiles=flyway.conf
   ```
3. If Flyway marks migration in error:
   ```bash
   mvn flyway:repair
   ```

---

## 4. Verification After Rollback
1. Run Health Probe:
   ```bash
   curl -i https://api.propzen.ai/api/v1/health/readiness
   ```
   Must return HTTP 200 with status `"READY"` and database `"UP"`.
2. Check Error Rates in Monitoring:
   Ensure HTTP 5xx rate drops back to baseline `< 0.05%`.
3. Check HikariCP Connection Pool:
   Ensure active connections stabilize within nominal bounds (5–10).
