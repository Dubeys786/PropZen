# PropZen AI Intelligence — Security Architecture & Guidelines

## 1. Zero Trust AI Security Model

Phase 11 implements comprehensive defense-in-depth mechanisms to protect user data, property listings, and platform integrity when interacting with AI systems.

---

## 2. Prompt Injection Defense

All user-supplied text inputs pass through `AiSafetyService` before reaching any AI provider (both local rules and LLM providers).

### 2.1 Pattern Matching & Blocklist
The regex engine detects and immediately blocks prompt hijacking attempts, including:
- Direct override commands: `"ignore (all) previous/prior instructions"`, `"disregard instructions"`.
- Role impersonation: `"you are now in dan mode"`, `"jailbreak"`.
- System prompt extraction: `"system prompt"`, `"show me your system instructions"`.
- Rule bypassing: `"bypass rules"`.

### 2.2 Rejection Behavior
When an injection attempt is detected:
- The system logs a security alert with `AiSafetyService` at `WARN` level.
- The request is immediately rejected with HTTP `400 Bad Request` (`VALIDATION_FAILED` or `BAD_REQUEST`).
- The payload is prevented from ever reaching external API endpoints or database storage.

---

## 3. PII & Credential Redaction

The sanitization pipeline protects sensitive credentials from accidental leakage into AI prompts or logs:
- **API Keys & Passwords:** Matches patterns such as `password=...`, `secret=...`, `apikey=...`, `bearer ...` and replaces them with `[REDACTED]`.
- **JWT Tokens:** Detects JSON Web Tokens (`eyJ...`) and redacts them prior to AI processing.
- **Phone Numbers & Private Emails:** Masked in shared or multi-tenant analytics views.

---

## 4. Tenant Isolation & IDOR Protection

1. **Dealer Isolation:**
   - Dealers querying `/api/v1/dealer/ai/insights` are strictly scoped to their own dealer record via `CurrentUser.getUserId()`.
   - Any attempt by a Dealer to pass a foreign `dealerId` query parameter throws `ForbiddenException` (HTTP 403) unless the caller has `ROLE_ADMIN`.
2. **Service Partner Isolation:**
   - Partners querying `/api/v1/partner/ai/insights` are strictly scoped to their own partner profile via `CurrentUser.getUserId()`.
   - Access to foreign partner IDs is blocked with HTTP 403.
3. **Role-Based Access Control:**
   - Buyers are strictly forbidden from accessing CRM AI, Dealer AI, and Admin AI endpoints.
   - Admin routes (`/api/v1/admin/ai/**`) are strictly guarded by `@PreAuthorize("hasRole('ADMIN')")`.

---

## 5. Document Privacy & Safe Processing

In compliance with the Phase 11 charter:
- **No Document File Uploads to Third Parties:**
  PropZen does NOT transmit raw PDF files, scanned deeds, or customer identity documents to external cloud AI providers.
- **Local Metadata Analysis:**
  Document validation (`AiDocumentController`) operates purely on structural metadata (file name, MIME type, file size, header signatures) and deterministic legal document classifiers.
