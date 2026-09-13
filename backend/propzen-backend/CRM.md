# PropZen Centralized CRM & Customer 360 Architecture (Phase 8)

The PropZen CRM is a multi-tenant, enterprise-grade Customer Relationship Management, Pipeline Management, and Customer 360 platform integrated into the core Spring Boot backend and Supabase PostgreSQL.

It unifies **Buyers, Dealers, Service Partners, Inquiries, Properties, Site Visits, and Service Journeys** into a single authoritative relationship engine.

---

## 1. Unified Architecture & Customer 360 Pipeline

```
 [ Buyer App / Web / Inquiries / Service Requests / WhatsApp / Manual CRM ]
                                    │
                                    ▼
                      [ Lead Deduplication Engine ]
                   (Lookup by Phone, Email, User ID)
                                    │
                   ┌────────────────┴────────────────┐
                   ▼                                 ▼
             [ New Lead ]                  [ Existing Lead Enriched ]
                   │                                 │
                   └────────────────┬────────────────┘
                                    │
                                    ▼
                         [ Customer 360 Engine ]
               ├── Contact Details & Identity (Buyer/Dealer/Partner)
               ├── Lifecycle Stage (NEW → CONTACTED → QUALIFIED → ...)
               ├── Property Inquiries & Viewed Units
               ├── Site Visits & Scheduled Tours
               ├── Service Requests & Milestone Journeys
               ├── Unified Activity Timeline (System + Manual)
               ├── Staff Assignment & Historical Audit Trail
               └── Tags & Preferences (HOT, NRI, WhatsApp Opt-in)
                                    │
                                    ▼
                      [ Transactional Outbox Engine ]
                    (At-least-once Guaranteed Delivery)
                                    │
                                    ▼
                       [ WhatsApp & Communications ]
                 (Meta Cloud API + Delivery Status Webhooks)
```

---

## 2. Lead Lifecycle Stages & Types

### 2.1 Lead Stages (`com.propzen.crm.model.LeadStage`)
1. **`NEW`**: Ingested from inquiry, web form, service request, or manual entry.
2. **`CONTACTED`**: Outreach completed by sales staff or automated WhatsApp message.
3. **`QUALIFIED`**: Verified budget, location requirements, and purchasing timeline.
4. **`SITE_VISIT_SCHEDULED`**: Physical or drone-assisted property visit booked.
5. **`SITE_VISIT_COMPLETED`**: Tour completed; feedback and objections captured.
6. **`NEGOTIATION`**: Pricing, token payments, and commercial terms under discussion.
7. **`CONVERTED`**: Deal successfully finalized (Property booked / Service contract signed).
8. **`LOST`**: Unqualified, dropped out, or opted for a competitor.
9. **`DORMANT`**: Cold lead scheduled for periodic re-engagement campaigns.

### 2.2 Lead Types (`com.propzen.crm.model.LeadType`)
- `BUYER`: Prospective property buyer.
- `INVESTOR`: High-net-worth individual or institutional capital allocator.
- `SELLER`: Property owner or dealer listing units for sale.
- `TENANT`: Rental prospective occupant.
- `SERVICE_SEEKER`: Customer requesting home inspection, legal verification, or loan assistance.

---

## 3. Database Schema (`V6__create_centralized_crm_automation_schema.sql`)

1. **`public.crm_leads`**:
   - `id`, `lead_number`, `user_id`, `dealer_id`, `property_id`, `name`, `phone`, `email`
   - `status`, `stage` (NEW..DORMANT), `lead_type` (BUYER..SERVICE_SEEKER)
   - `score`, `source`, `priority`, `budget_min`, `budget_max`, `assigned_to`, `notes`
2. **`public.crm_activities`**: Unified timeline logging calls, emails, notes, visits, stage changes, and communications.
3. **`public.crm_notes`**: Internal team notes and comments attached to leads.
4. **`public.crm_followups`**: Scheduled follow-up reminders with status (`PENDING`, `COMPLETED`, `OVERDUE`).
5. **`public.crm_tasks`**: Staff and dealer action items with deadlines, priority, and completion status.
6. **`public.crm_communications`**: Multi-channel communication records (WhatsApp, SMS, Email, Call).
7. **`public.whatsapp_templates`**: Pre-approved Meta WhatsApp Business Cloud API message templates.
8. **`public.crm_contact_preferences`**: Consent management (`whatsapp_opt_in`, `email_opt_in`, `sms_opt_in`, `marketing_opt_in`).
9. **`public.crm_outbox_events`**: Transactional outbox event store for asynchronous automation.
10. **`public.crm_tags` & `public.crm_lead_tags`**: Dynamic segmentation tags (`HOT`, `NRI`, `INVESTOR`, `URGENT`, etc.).
11. **`public.crm_assignment_history`**: Audit trail of lead assignment changes between staff members and dealers.

---

## 4. REST API Reference

### 4.1 Leads & Pipeline Management
- `GET /api/v1/crm/leads`: Filtered lead search (by stage, type, dealer, assigned user, date range).
- `POST /api/v1/crm/leads`: Ingest lead with automated deduplication on phone/email/user.
- `GET /api/v1/crm/leads/{id}`: Fetch lead details.
- `PATCH /api/v1/crm/leads/{id}`: Update lead attributes.
- `PATCH /api/v1/crm/leads/{id}/stage`: Transition stage (e.g. `NEW` → `QUALIFIED`).
- `PATCH /api/v1/crm/leads/{id}/assign`: Assign or reassign lead to agent/dealer.
- `PATCH /api/v1/crm/leads/{id}/convert`: Convert lead to customer/sale.
- `DELETE /api/v1/crm/leads/{id}`: Delete or archive lead (Admin only).

### 4.2 Customer 360
- `GET /api/v1/crm/customers/{id}/360`: 360-degree overview of a user's leads, properties, service requests, activities, and communication preferences.
- `GET /api/v1/crm/customers/by-phone/360?phone={phone}`: 360 lookup by customer phone number.

### 4.3 Notes & Tasks
- `GET /api/v1/crm/leads/{id}/notes`: List all internal notes for a lead.
- `POST /api/v1/crm/leads/{id}/notes` or `POST /api/v1/crm/notes`: Create note.
- `PATCH /api/v1/crm/notes/{id}`: Edit note.
- `DELETE /api/v1/crm/notes/{id}`: Delete note.
- `GET /api/v1/crm/leads/{id}/tasks`: List tasks associated with lead.
- `POST /api/v1/crm/tasks`: Create staff task.
- `PATCH /api/v1/crm/tasks/{id}`: Update task.
- `PATCH /api/v1/crm/tasks/{id}/complete`: Mark task completed.

### 4.4 Follow-Ups & Timeline
- `POST /api/v1/crm/follow-ups`: Schedule follow-up.
- `GET /api/v1/crm/follow-ups/pending`: List upcoming and pending follow-ups.
- `PATCH /api/v1/crm/follow-ups/{id}/complete`: Complete follow-up with remarks.
- `GET /api/v1/crm/activities/lead/{leadId}`: Retrieve chronological timeline of all activities.

### 4.5 Search & Analytics
- `GET /api/v1/crm/search?q={query}`: Unified fuzzy search across leads, customers, and properties.
- `GET /api/v1/crm/analytics`: Real-time KPI aggregation computed directly from PostgreSQL (total leads, conversion rates, leads by stage, leads by source).

---

## 5. Security & Isolation

- **Role-Based Access Control (RBAC)**:
  - `ADMIN`: Full visibility across all leads, reassignments, template management, and system-wide analytics.
  - `DEALER`: Strict multi-tenant isolation. Dealers can access only leads assigned to their profile (`dealer_id` / `assigned_to`).
  - `SERVICE_PARTNER`: Access restricted to service requests and assigned service leads.
  - `BUYER`: Inquiries and personal contact preferences only; cannot access internal CRM data.
