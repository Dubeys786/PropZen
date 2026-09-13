# PropZen Operations Runbook & Maintenance Manual

## 1. Routine Operations

### 1.1 Service Startup & Shutdown
- **Graceful Shutdown**: Enabled via `server.shutdown: graceful` (30-second drain period for in-flight requests).
- **Docker Compose Local Launch**:
  ```bash
  docker compose up -d
  ```
- **Kubernetes Scaling**:
  ```bash
  kubectl scale deployment/propzen-backend --replicas=4 -n production
  ```

---

## 2. Common Incident Response Scenarios

### 2.1 HTTP 500 Spike Detected
1. Check live logs for error stack traces filtered by `ERROR`:
   ```bash
   kubectl logs -l app=propzen-backend -n production --tail=200 | grep -i "ERROR"
   ```
2. Trace the originating request using `requestId` returned in user error report:
   ```bash
   grep "requestId: <UUID>" /var/log/propzen/app.log
   ```
3. Check database connectivity:
   ```bash
   curl -i https://api.propzen.ai/api/v1/health/readiness
   ```

### 2.2 HikariCP Pool Exhaustion
1. **Symptoms**: Request latency spikes, `HikariPool-1 - Connection is not available, request timed out after 30000ms`.
2. **Diagnosis**: Check for unclosed connections or long-running queries in PostgreSQL:
   ```sql
   SELECT pid, now() - pg_stat_activity.query_start AS duration, query, state
   FROM pg_stat_activity
   WHERE state != 'idle' ORDER BY duration DESC;
   ```
3. **Resolution**:
   - Terminate blocking query via `SELECT pg_terminate_backend(pid);`.
   - Scale application replicas or increase `maximum-pool-size` in environment configuration.

### 2.3 Meta WhatsApp API 429 Rate Limiting
1. The bulk campaign dispatcher employs a 20ms inter-message sleep (~50 msgs/second), well within Meta's 80 msg/second threshold.
2. If Meta returns 429:
   - Check Meta Developer App Dashboard for tier status.
   - The campaign engine records `FAILED` status on individual recipients and logs error reason without failing the whole batch.

---

## 3. Maintenance Procedures

### 3.1 Applying Schema Migrations
1. Add new versioned script: `src/main/resources/db/migration/V{X}__{description}.sql`.
2. Deploy new application image. Flyway automatically runs pending migrations on startup.
3. Validate schema integrity:
   ```bash
   mvn flyway:info
   ```
