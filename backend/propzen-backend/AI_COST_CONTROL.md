# PropZen AI Intelligence — Cost Control & Token Telemetry

## 1. Cost Control Architecture

PropZen integrates multi-tier cost management mechanisms in `AiOrchestrator` to ensure high operational efficiency and avoid unexpected token consumption spikes.

---

## 2. In-Memory Response Caching (`AiCacheService`)

Repeated queries for static and semi-static operations are automatically cached using cryptographic hashing.

### 2.1 Cache Mechanics
- **Key Generation:** SHA-256 hash computed over `operation + canonical JSON payload`.
- **TTL:** 15-minute time-to-live with sliding window eviction.
- **Cacheable Operations:**
  - `MARKET_INTELLIGENCE` (Sector prices, market trends)
  - `PROPERTY_DESCRIPTION_GENERATION` (Identical property spec descriptions)
  - `DOCUMENT_INTELLIGENCE` (Metadata verification checks)
- **Non-Cacheable Operations:**
  - `LEAD_SCORING` (Real-time dynamic recalculations)
  - `CRM_NEXT_ACTION` (Real-time urgent tasks)

---

## 3. Rate Limiting & Quota Management

- **Token Bucket Limiter:**
  Configured via `propzen.ai.rate-limit-per-minute` (default: 60 requests/minute per caller).
- **Excess Traffic Handling:**
  Exceeded requests return HTTP `429 Too Many Requests` or gracefully route through the zero-cost `LocalRuleBasedAiProvider`.

---

## 4. Usage Auditing & Cost Estimation

Every request writes an audit record to the `ai_usage_logs` table:
- Total Prompt Tokens
- Total Completion Tokens
- Response Latency (ms)
- Cache Hit / Miss
- Fallback Triggered

### Real-Time Admin Telemetry
Admins can monitor platform-wide AI usage in real time via `GET /api/v1/admin/ai/usage`:
- Total AI API calls
- Breakdown by provider (`LOCAL`, `OPENAI`, `GEMINI`)
- Average latency
- Cumulative estimated cost
