# PropZen Automation & Event Processing Engine (Phase 8)

The PropZen automation engine implements the **Transactional Outbox Pattern** to reliably decouple business events from asynchronous side effects, multi-channel notifications, third-party webhooks, and background processing.

---

## 1. Transactional Outbox Pattern

```
  [ Spring Boot Business Transaction ]
  ┌──────────────────────────────────────────────────────────┐
  │ 1. Modify domain entity (Lead, ServiceRequest, Payment)   │
  │ 2. Save Outbox Event to `crm_outbox_events`              │
  │ 3. COMMIT Database Transaction                           │
  └──────────────────────────────────────────────────────────┘
                               │ (Guaranteed zero lost events)
                               ▼
                   [ OutboxProcessor Worker ]
                    (Scheduled every 5000ms)
                               │
            ┌──────────────────┴──────────────────┐
            │ Poll `findProcessableEvents`        │
            │ (status = PENDING & available_at)   │
            └──────────────────┬──────────────────┘
                               │
                               ▼
                    [ Dispatch Event Handler ]
               ├── AutomationEngine / Rule Evaluator
               ├── WhatsApp / Email / SMS Dispatchers
               └── CRM Activity Logger
                               │
            ┌──────────────────┴──────────────────┐
            ▼                                     ▼
        [ Success ]                          [ Failure ]
    Set status = SENT                    Increment attemptCount
    Record processed_at                  Calculate exponential backoff:
                                         available_at = now + 2^attempts mins
                                         If attempts >= 5:
                                         Set status = DEAD_LETTER
```

---

## 2. Supported Domain Events (`AutomationEventType`)

1. **`LEAD_CREATED`**: A new lead is created or ingested.
2. **`LEAD_ASSIGNED`**: Lead assigned to a sales agent or dealer.
3. **`LEAD_STAGE_CHANGED`**: Lead moved to a new stage (e.g. `CONTACTED`, `QUALIFIED`).
4. **`LEAD_CONVERTED`**: Lead converted to closed deal.
5. **`LEAD_LOST`**: Lead marked lost with reason.
6. **`ENQUIRY_RECEIVED`**: Property inquiry submitted by buyer.
7. **`SITE_VISIT_REQUESTED`**: Buyer requests a property tour.
8. **`SITE_VISIT_CONFIRMED`**: Dealer or admin confirms time slot.
9. **`SITE_VISIT_COMPLETED`**: Tour completed and feedback gathered.
10. **`SERVICE_REQUEST_CREATED`**: New customer service journey initialized.
11. **`SERVICE_PARTNER_ASSIGNED`**: Verified partner assigned to service ticket.
12. **`SERVICE_STATUS_UPDATED`**: Request progresses to in-progress or completed.
13. **`MILESTONE_APPROVED`**: Customer approves milestone work.
14. **`PAYMENT_COMPLETED`**: Milestone payment captured and verified.

---

## 3. Reliability & Fault Tolerance

- **Zero Lost Messages**: The event is persisted within the identical ACID transaction as the primary entity mutation. If the database rolls back, no event is published. If the app crashes, the uncommitted outbox record will be processed on recovery.
- **Exponential Backoff**: Transient errors (network blips, third-party API rate limits) trigger exponential backoff retry:
  - Attempt 1: 2 minutes delay
  - Attempt 2: 4 minutes delay
  - Attempt 3: 8 minutes delay
  - Attempt 4: 16 minutes delay
  - Attempt 5: Dead-letter queue transition
- **Dead-Letter Queue (`DEAD_LETTER`)**: Permanently failed events are quarantined for administrative inspection and replay without stalling the processing queue.
- **Idempotency**: Downstream handlers verify deduplication keys or event IDs before taking irreversible action.
