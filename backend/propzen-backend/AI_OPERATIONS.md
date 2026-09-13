# PropZen AI Intelligence — Operations & Runbook

## 1. Operational Configuration

PropZen AI parameters are defined under the `propzen.ai` namespace in `application.yml` and can be overridden via environment variables.

| Environment Variable | Default Value | Description |
|---|---|---|
| `PROPZEN_AI_PROVIDER` | `LOCAL` | Active provider: `LOCAL`, `OPENAI`, `GEMINI` |
| `PROPZEN_AI_API_KEY` | `""` | API Key for external model providers |
| `PROPZEN_AI_MODEL` | `gpt-4o-mini` | Model name (e.g. `gpt-4o`, `gemini-1.5-flash`) |
| `PROPZEN_AI_BASE_URL` | `https://api.openai.com/v1` | Base URL for OpenAI-compatible endpoint |
| `PROPZEN_AI_TIMEOUT_MS` | `10000` | HTTP timeout (ms) before triggering fallback |
| `PROPZEN_AI_MAX_TOKENS` | `1000` | Maximum completion tokens per request |
| `PROPZEN_AI_TEMPERATURE` | `0.7` | Model sampling temperature (0.0 - 1.0) |
| `PROPZEN_AI_CACHE_ENABLED` | `true` | Enables SHA-256 in-memory caching |
| `PROPZEN_AI_RATE_LIMIT_PER_MINUTE` | `60` | Max AI requests allowed per minute |
| `PROPZEN_AI_SAFETY_CHECKS_ENABLED` | `true` | Enforces prompt injection filtering |

---

## 2. Production Runbook

### 2.1 Switching AI Providers Without Restarts
To switch from local rule-based models to an external LLM (e.g., OpenAI or self-hosted vLLM):
```bash
export PROPZEN_AI_PROVIDER=OPENAI
export PROPZEN_AI_API_KEY=sk-...
export PROPZEN_AI_MODEL=gpt-4o-mini
```

To switch to Google Gemini:
```bash
export PROPZEN_AI_PROVIDER=GEMINI
export PROPZEN_AI_API_KEY=AIzaSy...
export PROPZEN_AI_MODEL=gemini-1.5-flash
```

### 2.2 Handling Provider Outages
- If an external provider experiences network failures, invalid keys, or rate limits:
  1. `AiOrchestrator` logs an error at `WARN` level.
  2. The system automatically switches execution to `LocalRuleBasedAiProvider`.
  3. Responses are returned to the user with `fallbackUsed = true`.
  4. The audit record is logged with `fallback_used = true` in `ai_usage_logs`.
- To forcibly revert to offline mode in an emergency:
  Set `PROPZEN_AI_PROVIDER=LOCAL`.

### 2.3 Monitoring AI Telemetry
- Check usage and latency: `GET /api/v1/admin/ai/usage` (Admin role required).
- Check health status: `GET /api/v1/health` and `GET /api/v1/admin/ai/insights`.
