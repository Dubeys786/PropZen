# PropZen Campaign Engine & Idempotency Architecture (Phase 8)

The PropZen Campaign Engine facilitates bulk, segment-targeted, and multi-channel outreach campaigns across WhatsApp, Email, and SMS with strict idempotency and consent enforcement.

---

## 1. Multi-Channel Campaigns

PropZen supports structured marketing and informational campaigns (`crm_campaigns`):
- **Channels**: `WHATSAPP`, `EMAIL`, `SMS`.
- **Targeting**: Dynamic segments filtered by `city`, `sector`, `budgetMin`, `budgetMax`, `stage` (`NEW`, `QUALIFIED`, `DORMANT`), `leadType` (`BUYER`, `INVESTOR`), and `tags` (`HOT`, `NRI`, `INVESTOR`).
- **Scheduling**: Immediate (`DRAFT` -> `PROCESSING` -> `COMPLETED`) or scheduled future execution.
- **Templates**: Integrated with approved Meta WhatsApp templates (`whatsapp_templates`) and parameter mapping.

---

## 2. Idempotency & Duplicate Prevention

To prevent duplicate messages when jobs retry or network interruptions occur:
- Each campaign recipient entry in `crm_campaign_recipients` generates a deterministic idempotency key:
  `idempotencyKey = String.format("%s:%s:%s", campaignId, leadId, templateId)`
- Database-enforced `UNIQUE(idempotency_key)` constraint prevents inserting or dispatching the same message multiple times to the same lead.
- The transactional outbox engine further ensures at-least-once delivery with exponential backoff on transient errors.

---

## 3. Communication Preferences & Legal Compliance

- Opt-out state is checked per-recipient before sending via `ContactPreferenceService`.
- If a lead or customer has opted out of marketing (`marketing_opt_in = false` or `whatsapp_opt_in = false`), recipient status is marked `OPTED_OUT` without failing the parent campaign batch.
- Real-time campaign analytics track:
  - Total Target Recipients
  - Dispatched & Delivered Count
  - Read Count (via Meta status webhooks)
  - Opt-Out Rate & Unsubscribes
