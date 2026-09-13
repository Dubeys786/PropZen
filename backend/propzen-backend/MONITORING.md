# PropZen Production Monitoring, Alerting & Observability

## 1. Overview
The PropZen backend includes full observability via **Spring Boot Actuator**, **Micrometer**, structured JSON logging, and dedicated HTTP probes.

---

## 2. Health & Readiness Probes

| Endpoint | Target Consumer | Purpose | Expected Status |
|---|---|---|---|
| `GET /api/v1/health` | Load Balancer | Verifies basic application and DB connection | `200 OK`, `{"status":"UP"}` |
| `GET /api/v1/health/liveness` | Kubernetes / Container Engine | Verifies JVM process is responsive and not deadlocked | `200 OK`, `{"status":"ALIVE"}` |
| `GET /api/v1/health/readiness` | Ingress / Service Mesh | Verifies DB, Flyway, and subsystems are ready to accept traffic | `200 OK`, `{"status":"READY"}` |
| `GET /actuator/health` | Prometheus / Datadog | Deep subsystem health check (Disk, DB, Hikari) | `200 OK`, `{"status":"UP"}` |
| `GET /actuator/prometheus` | Prometheus Scraper | OpenMetrics Prometheus metric scrape endpoint | Metrics stream |

---

## 3. Key Operational Metrics & Thresholds

| Metric | PromQL / Indicator | Normal Baseline | Alert Trigger (Warning / P1) |
|---|---|---|---|
| **JVM Heap Utilization** | `jvm_memory_used_bytes{area="heap"} / jvm_memory_max_bytes{area="heap"}` | 40% – 60% | > 80% (Warning) / > 90% (P1) |
| **HTTP Error Rate** | `sum(rate(http_server_requests_seconds_count{status=~"5.."}[5m])) / sum(rate(http_server_requests_seconds_count[5m]))` | < 0.1% | > 1% (Warning) / > 5% (P1) |
| **P99 API Latency** | `histogram_quantile(0.99, sum(rate(http_server_requests_seconds_bucket[5m])) by (le))` | < 250ms | > 500ms (Warning) / > 1500ms (P1) |
| **DB Connection Pool Usage** | `hikaricp_connections_active / hikaricp_connections_max` | 15% – 35% | > 75% (Warning) / > 90% (P1) |
| **Connection Acquire Time** | `hikaricp_connections_acquire_seconds` | < 10ms | > 100ms (Warning) / > 500ms (P1) |

---

## 4. Structured Logging & Correlation IDs
- Every HTTP request passes through `CorrelationIdFilter` and receives a unique UUID `X-Request-Id`.
- The Request ID is bound to `MDC` (Mapped Diagnostic Context) and returned in the HTTP response headers.
- Logs format:
  ```json
  {
    "timestamp": "2026-09-08T17:28:44.566Z",
    "level": "INFO",
    "thread": "http-nio-8080-exec-1",
    "requestId": "07521856-8532-4315-925c-072a73c7b516",
    "logger": "com.propzen.common.logging.RequestLoggingFilter",
    "message": "HTTP GET /api/v1/partner/dashboard - Status: 200 - Duration: 22ms"
  }
  ```
- Ingested directly into cloud log collectors (AWS CloudWatch, Datadog, or Grafana Loki).
