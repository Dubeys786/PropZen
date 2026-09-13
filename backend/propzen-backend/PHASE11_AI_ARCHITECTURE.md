# PropZen Java Backend — Phase 11 AI Architecture

## 1. Executive Summary & Design Principles

Phase 11 introduces a high-performance, enterprise-grade, provider-agnostic Artificial Intelligence (AI), Recommendation, and Business Intelligence engine directly into the PropZen Java/Spring Boot backend (`backend/propzen-backend`).

### Key Architectural Pillars:
1. **Zero Provider Lock-In (SPI Pattern):**
   A decoupled Service Provider Interface (`AiProvider`) abstracting local rule-based models, OpenAI-compatible APIs (vLLM, Ollama, OpenAI), and Google Gemini. Switching providers is a single configuration property change (`propzen.ai.provider`).
2. **Zero Fake/Synthetic Business Data:**
   All recommendations, scoring, matching, and analytics operate against live Supabase PostgreSQL entities (`posted_properties`, `crm_leads`, `site_visits`, `service_requests`, `dealer_profiles`).
3. **Resilience & Fault Tolerance:**
   `AiOrchestrator` implements bounded timeouts, circuit breaking, and automatic fallback to `LocalRuleBasedAiProvider`. The application never crashes or degrades when external AI services experience latency or outages.
4. **Zero Trust Tenant Isolation & Defense-in-Depth:**
   Strict tenant isolation for Dealers and Service Partners ensures actors only access intelligence generated from their own leads and jobs. All AI inputs are protected by regex-based prompt injection detection and automatic redaction of credentials/JWT tokens.
5. **Real-Time Auditing & Telemetry:**
   Every AI invocation asynchronously logs prompt tokens, completion tokens, latency, active provider, fallback status, and caller identity into the `ai_usage_logs` PostgreSQL table.

---

## 2. High-Level AI System Architecture

```mermaid
graph TD
    Client[Flutter Mobile / Web Frontend]
    
    subgraph SpringBootBackend["Java 17 / Spring Boot 3.3.3 Backend"]
        Controllers[AI REST Controllers\n/api/v1/ai/**, /admin/ai/**, /dealer/ai/**, /partner/ai/**]
        Security[Spring Security + Supabase JWT RBAC]
        
        subgraph AIServices["AI Domain Intelligence Layer"]
            LeadScoring[AiLeadScoringService]
            Recommendation[PropertyRecommendationService]
            CrmAssistant[CrmAiAssistantService]
            FollowUp[AiFollowUpService]
            Description[PropertyDescriptionService]
            EnquiryClassify[EnquiryClassificationService]
            DocIntel[DocumentIntelligenceService]
            MarketIntel[MarketIntelligenceService]
            AdminBI[AdminAiInsightsService]
            DealerBI[DealerAiInsightsService]
            PartnerBI[ServicePartnerAiInsightsService]
        end
        
        subgraph OrchestrationLayer["AI Orchestration Engine"]
            Orchestrator[AiOrchestrator]
            Safety[AiSafetyService\nPrompt Injection & Redaction]
            Cache[AiCacheService\nSHA-256 In-Memory TTL Cache]
            RateLimiter[Token Bucket Rate Limiter]
        end
        
        subgraph ProviderSPI["AI Provider Abstraction (SPI)"]
            Factory[AiProviderFactory]
            LocalProvider[LocalRuleBasedAiProvider\n(Deterministic Offline Fallback)]
            OpenAiProvider[OpenAiCompatibleProvider\n(REST / vLLM / OpenAI)]
            GeminiProvider[GeminiAiProvider\n(Google Gemini REST API)]
        end
        
        subgraph Persistence["Live Data & Audit Repositories"]
            DB[(PostgreSQL / Supabase)]
            UsageLogs[(ai_usage_logs)]
            Classifications[(ai_enquiry_classifications)]
            Scores[(ai_lead_scores)]
        end
    end

    Client -->|HTTP/REST with JWT| Security
    Security --> Controllers
    Controllers --> AIServices
    AIServices -->|Live Queries| DB
    AIServices -->|AiRequest<T>| Orchestrator
    Orchestrator --> Safety
    Orchestrator --> RateLimiter
    Orchestrator --> Cache
    Orchestrator --> Factory
    Factory --> LocalProvider
    Factory --> OpenAiProvider
    Factory --> GeminiProvider
    OpenAiProvider -.->|Fallback on Failure| LocalProvider
    GeminiProvider -.->|Fallback on Failure| LocalProvider
    Orchestrator -.->|Async Logging| UsageLogs
    AIServices -.-> Scores
    AIServices -.-> Classifications
```

---

## 3. Core Database Schema & Migrations (`V8__create_ai_intelligence_schema.sql`)

Phase 11 introduces three dedicated database tables with high-performance B-tree indexes:

### 3.1 `ai_usage_logs`
Tracks AI telemetry, token usage, latency, and cost control:
- `id` (UUID, Primary Key)
- `operation` (VARCHAR(64), e.g., `LEAD_SCORING`, `PROPERTY_RECOMMENDATION`)
- `provider` (VARCHAR(32), e.g., `LOCAL`, `OPENAI`, `GEMINI`)
- `model` (VARCHAR(64))
- `latency_ms` (BIGINT)
- `prompt_tokens` (INTEGER)
- `completion_tokens` (INTEGER)
- `total_tokens` (INTEGER)
- `is_cached` (BOOLEAN)
- `fallback_used` (BOOLEAN)
- `success` (BOOLEAN)
- `error_message` (TEXT)
- `user_id` (UUID, nullable)
- `created_at` (TIMESTAMPTZ)

### 3.2 `ai_enquiry_classifications`
Stores smart triage, intent analysis, and sentiment without modifying original raw customer messages:
- `id` (UUID, Primary Key)
- `enquiry_id` (UUID, Unique foreign key)
- `category` (VARCHAR(64))
- `priority` (VARCHAR(32))
- `sentiment` (VARCHAR(32))
- `suggested_department` (VARCHAR(64))
- `suggested_action` (TEXT)
- `confidence` (DOUBLE PRECISION)
- `classified_at` (TIMESTAMPTZ)

### 3.3 `ai_lead_scores`
Stores historical and current predictive scores for leads:
- `id` (UUID, Primary Key)
- `lead_id` (UUID, indexed)
- `score` (INTEGER, 0-100)
- `classification` (VARCHAR(32), `HOT`, `WARM`, `COLD`)
- `reasons` (TEXT)
- `next_action` (TEXT)
- `confidence` (DOUBLE PRECISION)
- `scored_at` (TIMESTAMPTZ)

---

## 4. Provider Strategy & Zero Downtime Fallback

1. **Configurable Runtime Selection:**
   Configure `propzen.ai.provider` in `application.yml` or via environment variable `PROPZEN_AI_PROVIDER`:
   - `LOCAL`: Zero-dependency, deterministic heuristic engine. 0ms network latency, 0 external cost, 100% offline capability.
   - `OPENAI`: Connects to OpenAI or any OpenAI-compatible server (vLLM, LocalAI, Ollama, DeepSeek).
   - `GEMINI`: Connects to Google Generative Language API.
2. **Circuit Breaking & Fallback Guarantee:**
   If an external provider throws a `ResourceAccessException`, `HttpServerErrorException`, or timeout exceeding `propzen.ai.timeout-ms`:
   - The error is logged and audited.
   - `AiOrchestrator` automatically reroutes the request to `LocalRuleBasedAiProvider`.
   - The response is marked with `fallbackUsed = true`.
   - The client experiences zero disruption or 500 internal errors.
