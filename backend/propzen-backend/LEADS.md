# PropZen Lead Management & Scoring Engine (Phase 6)

## 1. Lead Ingestion & Deduplication

Leads are ingested via:
1. **Direct CRM Creation**: `POST /api/v1/crm/leads` (Dealers / Admins).
2. **Property Enquiries**: `POST /api/v1/enquiries` (Buyers / Public).
3. **External Webhooks**: `POST /api/v1/webhooks/leads` (Aggregators, Google/Meta Ads).

### Deduplication Strategy
When a new enquiry or webhook lead arrives:
- The system checks for an existing lead with identical `phone` or `email`.
- If an existing active lead is found:
  - If linked to the **same property**, the enquiry is appended to the timeline as a `NOTE` / `ENQUIRY` activity, and `last_contacted_at` is updated without creating a duplicate record.
  - If linked to a **different property**, a new lead record is created for independent pipeline tracking, but linked via shared customer identity.

---

## 2. Deterministic Lead Scoring Model (0 - 100)

Every lead receives an automated deterministic score computed by `LeadScoringService`:

| Attribute / Behavior | Condition | Points Awarded |
|---|---|---|
| **Contact Data Completeness** | Valid Phone + Verified Email + Full Name | +20 |
| **Budget Defined** | Budget range (`budgetMin` or `budgetMax`) specified | +20 |
| **Location Explicit** | Preferred city and sector provided | +15 |
| **Property Interest** | Direct association with active property listing | +15 |
| **High Intent Source** | Source is `WHATSAPP` or `WEBSITE_DIRECT` | +10 |
| **Engagement** | Site visit scheduled or completed | +20 |
| **Total Max Score** | | **100** |

Leads with scores >= 70 are categorized as `HIGH` priority; 40–69 as `MEDIUM`; < 40 as `LOW`.

---

## 3. Auto-Assignment Strategies

`AutoAssignmentService` routes incoming unassigned leads across active verified dealers:

1. **`ROUND_ROBIN`**: Cycles systematically through eligible dealers in the preferred city/sector.
2. **`LOAD_BALANCED`**: Assigns lead to the eligible dealer with the lowest number of active open leads (`NEW`, `CONTACTED`, `QUALIFIED`).
3. **Property Direct Ownership**: If an enquiry is submitted against a property listed by an active dealer, the lead is automatically assigned directly to that listing dealer.
