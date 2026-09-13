# PropZen REST API Reference (Phases 1–4)

All PropZen APIs return a standardized `ApiResponse<T>` envelope:
```json
{
  "success": true,
  "data": { ... },
  "message": "Request successful",
  "timestamp": "2026-09-08T15:20:00.000Z",
  "requestId": "a67bcf12-58e1-4bf1-a477-d352ce66d210"
}
```

---

## 1. System & Health

### `GET /api/v1/health`
* **Access**: Public (No auth required)
* **Description**: Returns server health and operational status.

---

## 2. Authentication & Identity Context

### `GET /api/v1/auth/me`
* **Access**: Authenticated (Bearer JWT)
* **Description**: Returns validated cryptographic JWT claims and mapped GrantedAuthorities.

---

## 3. User Profile Management

### `GET /api/v1/users/me`
* **Access**: Authenticated (Bearer JWT)
* **Description**: Retrieves current authenticated user's profile from `public.users`.

### `PATCH /api/v1/users/me`
* **Access**: Authenticated (Bearer JWT)
* **Description**: Safely updates `fullName` and `phone`. Ignores role, email, or identity override attempts.

---

## 4. Dealer Portal

### `POST /api/v1/dealers/apply`
* **Access**: Authenticated (Bearer JWT)
* **Description**: Submits a new dealer application in `PENDING` state. Prevents duplicate active applications.

### `GET /api/v1/dealers/me`
* **Access**: Authenticated (Bearer JWT)
* **Description**: Retrieves current user's dealer profile.

### `PATCH /api/v1/dealers/me`
* **Access**: Authenticated (Bearer JWT)
* **Description**: Updates dealer business details (`businessName`, `companyName`, `displayName`, `phone`, `description`, `experienceYears`, `city`).

---

## 5. Administrative Dealer Review

### `GET /api/v1/admin/dealers`
* **Access**: `ROLE_ADMIN`
* **Description**: Returns paginated list of dealer applications supporting status and keyword filters.

### `GET /api/v1/admin/dealers/{id}`
* **Access**: `ROLE_ADMIN`
* **Description**: Returns complete details of a specific dealer profile.

### `PATCH /api/v1/admin/dealers/{id}/status`
* **Access**: `ROLE_ADMIN`
* **Description**: Updates dealer status (`UNDER_REVIEW`, `APPROVED`, `REJECTED`, `SUSPENDED`). Approving a dealer activates `ROLE_DEALER` server-side in `public.users`.

---

## 6. Property Management & Search Engine (Phase 5)

### `GET /api/v1/properties`
* **Access**: Public
* **Description**: Database-level exact search and filtering for published properties.
* **Parameters**: `q`, `city`, `sector`, `locality`, `propertyType`, `bhk`, `minPrice`, `maxPrice`, `minPriceCr`, `maxPriceCr`, `minSqft`, `maxSqft`, `amenities`, `sort`, `page`, `size`.

### `GET /api/v1/properties/{id}`
* **Access**: Public (Published properties) / Authenticated (Owner or Admin for non-published)
* **Description**: Retrieves role-aware property details. Omits sensitive owner phone and internal notes for public visitors.

### `POST /api/v1/properties`
* **Access**: `ROLE_DEALER` or `ROLE_ADMIN`
* **Description**: Creates a new property with server-assigned ownership (`dealer_id`, `owner_id`).

### `PATCH /api/v1/properties/{id}`
* **Access**: Property Owner (`ROLE_DEALER`) or `ROLE_ADMIN`
* **Description**: Updates permitted property fields. Prevents overriding protected ownership or verification fields.

### `GET /api/v1/dealers/me/properties`
* **Access**: Authenticated Dealer (`ROLE_DEALER`)
* **Description**: Retrieves all properties owned by the authenticated dealer. Enforces server-side dealer isolation.

### `GET /api/v1/admin/properties`
* **Access**: `ROLE_ADMIN`
* **Description**: Unfiltered search across all properties and lifecycle states.

### `GET /api/v1/admin/properties/{id}`
* **Access**: `ROLE_ADMIN`
* **Description**: Retrieves full property details including owner phone, dealer ID, and internal review notes.

### `PATCH /api/v1/admin/properties/{id}/status`
* **Access**: `ROLE_ADMIN`
* **Description**: Administrative moderation and status workflow (`APPROVED`, `PUBLISHED`, `REJECTED`, `ARCHIVED`) with optional review notes.

---

## 7. Enquiries & Lead Ingestion (Phase 6)

### `POST /api/v1/enquiries`
* **Access**: Public / Authenticated
* **Description**: Submits property enquiry, creates or associates lead, computes initial lead score, schedules auto-assignment, and sends confirmation notification.

### `GET /api/v1/dealers/me/enquiries`
* **Access**: `ROLE_DEALER`
* **Description**: Retrieves all property enquiries directed to properties owned by the authenticated dealer.

---

## 8. CRM Lead Pipeline (Phase 6)

### `GET /api/v1/crm/leads`
* **Access**: `ROLE_DEALER` or `ROLE_ADMIN` (Dealers restricted to assigned leads)
* **Description**: Advanced search and filtering across lead pipeline (`q`, `status`, `priority`, `source`, `city`, `sector`, `propertyId`).

### `POST /api/v1/crm/leads`
* **Access**: `ROLE_DEALER` or `ROLE_ADMIN`
* **Description**: Creates a new CRM lead with scoring and automated assignment.

### `GET /api/v1/crm/leads/{id}`
* **Access**: Assigned Dealer or `ROLE_ADMIN`
* **Description**: Retrieves full lead profile details and scoring breakdown.

### `PATCH /api/v1/crm/leads/{id}`
* **Access**: Assigned Dealer or `ROLE_ADMIN`
* **Description**: Updates lead contact info, budget range, and property preferences.

### `PATCH /api/v1/crm/leads/{id}/status`
* **Access**: Assigned Dealer or `ROLE_ADMIN`
* **Description**: Updates lead lifecycle status (`NEW`, `CONTACTED`, `QUALIFIED`, `SITE_VISIT_SCHEDULED`, `NEGOTIATION`, `CONVERTED`, `LOST`).

### `PATCH /api/v1/crm/leads/{id}/priority`
* **Access**: Assigned Dealer or `ROLE_ADMIN`
* **Description**: Overrides lead priority (`LOW`, `MEDIUM`, `HIGH`, `URGENT`).

### `PATCH /api/v1/crm/leads/{id}/assign`
* **Access**: `ROLE_ADMIN`
* **Description**: Reassigns lead to a specific user or dealer.

---

## 9. Lead Activities & Follow-Ups (Phase 6)

### `GET /api/v1/crm/leads/{id}/activities`
* **Access**: Assigned Dealer or `ROLE_ADMIN`
* **Description**: Retrieves historical chronological timeline of lead notes, calls, messages, and state transitions.

### `POST /api/v1/crm/leads/{id}/activities`
* **Access**: Assigned Dealer or `ROLE_ADMIN`
* **Description**: Logs a new activity (note, call, message) on the lead timeline.

### `POST /api/v1/crm/leads/{id}/follow-up`
* **Access**: Assigned Dealer or `ROLE_ADMIN`
* **Description**: Schedules a next follow-up date/time, updates lead record, and creates timeline entry.

---

## 10. Campaigns & Mass Outreach (Phase 6)

### `GET /api/v1/crm/campaigns`
* **Access**: `ROLE_ADMIN`
* **Description**: Lists marketing/promotional campaigns with status and delivery counts.

### `POST /api/v1/crm/campaigns`
* **Access**: `ROLE_ADMIN`
* **Description**: Creates a campaign draft with channel, template ID, and target filters.

### `POST /api/v1/crm/campaigns/{id}/execute`
* **Access**: `ROLE_ADMIN`
* **Description**: Dispatches campaign to matching leads with opt-out checks and idempotency keys.

---

## 11. CRM Analytics & Preferences (Phase 6)

### `GET /api/v1/crm/dashboard`
* **Access**: `ROLE_DEALER` or `ROLE_ADMIN`
* **Description**: Live, database-calculated CRM KPIs (`totalLeads`, `newLeads`, `contactedLeads`, `qualifiedLeads`, `followUpsDue`, `siteVisits`, `conversionRate`). Dealers view only their scoped metrics; Admins view platform-wide aggregates.

### `GET /api/v1/communication-preferences`
* **Access**: Authenticated User
* **Description**: Retrieves communication channels and opt-in/opt-out status for caller.

### `PATCH /api/v1/communication-preferences`
* **Access**: Authenticated User
* **Description**: Updates WhatsApp/Email/SMS communication consent preferences.

---

## 12. External Webhooks (Phase 6)

### `POST /api/v1/webhooks/whatsapp`
* **Access**: Public (Signed with webhook verify token)
* **Description**: Inbound webhook processing delivery receipts, message status, and opt-out keywords.

### `POST /api/v1/webhooks/leads`
* **Access**: Public / API Key
* **Description**: Ingests external leads from marketing funnels or third-party aggregators.

---

## 13. Service Categories (Phase 7)

### `GET /api/v1/services/categories`
* **Access**: Public (No auth required)
* **Description**: Lists all active service categories ordered by `sortOrder`.

### `POST /api/v1/admin/services/categories`
* **Access**: `ROLE_ADMIN`
* **Description**: Creates a new service category (`name`, `slug`, `icon`, `description`, `sortOrder`).

### `PATCH /api/v1/admin/services/categories/{id}`
* **Access**: `ROLE_ADMIN`
* **Description**: Updates an existing service category's configuration.

### `DELETE /api/v1/admin/services/categories/{id}`
* **Access**: `ROLE_ADMIN`
* **Description**: Deletes a service category.

---

## 14. Service Partner Management (Phase 7)

### `POST /api/v1/service-partners/apply`
* **Access**: Authenticated User
* **Description**: Submits a service partner application in `PENDING` status. Prevents duplicate profiles.

### `GET /api/v1/service-partners/me`
* **Access**: Authenticated User (`ROLE_SERVICE_PARTNER` or applicant)
* **Description**: Retrieves current authenticated partner's profile.

### `PATCH /api/v1/service-partners/me`
* **Access**: Authenticated User (`ROLE_SERVICE_PARTNER` or applicant)
* **Description**: Updates partner contact information, description, and service area.

### `GET /api/v1/admin/service-partners`
* **Access**: `ROLE_ADMIN`
* **Description**: Paginated search and filtering of all service partners by category, status, and verification.

### `PATCH /api/v1/admin/service-partners/{id}/status`
* **Access**: `ROLE_ADMIN`
* **Description**: Approves, suspends, or rejects a service partner.

### `PATCH /api/v1/admin/service-partners/{id}/verification`
* **Access**: `ROLE_ADMIN`
* **Description**: Updates a service partner's KYC verification status (`PENDING`, `UNDER_REVIEW`, `VERIFIED`, `REJECTED`).

---

## 15. Service Requests & Fulfillment (Phase 7)

### `POST /api/v1/services/requests`
* **Access**: Authenticated Customer
* **Description**: Submits a new service request in `NEW` status, triggers automatic journey event and notification.

### `GET /api/v1/services/requests/{id}`
* **Access**: Customer Owner, Assigned Partner, or `ROLE_ADMIN`
* **Description**: Retrieves complete service request details including milestones, documents, feedback, and calculated progress %.

### `GET /api/v1/services/requests/my`
* **Access**: Authenticated Customer
* **Description**: Paginated list of service requests submitted by the authenticated customer.

### `PATCH /api/v1/services/requests/{id}/cancel`
* **Access**: Customer Owner or `ROLE_ADMIN`
* **Description**: Cancels a service request in `NEW` or `ASSIGNED` status.

### `GET /api/v1/admin/service-requests`
* **Access**: `ROLE_ADMIN`
* **Description**: Platform-wide paginated search across all service requests with multi-attribute filtering.

### `GET /api/v1/admin/service-requests/{id}/recommendations`
* **Access**: `ROLE_ADMIN`
* **Description**: Returns weighted, scored partner recommendations based on rating, workload balance, experience, and location.

### `POST /api/v1/admin/service-requests/{id}/assign`
* **Access**: `ROLE_ADMIN`
* **Description**: Assigns a recommended service partner to the request and notifies partner.

### `GET /api/v1/partner/service-requests`
* **Access**: `ROLE_SERVICE_PARTNER`
* **Description**: Lists all service requests assigned to the authenticated partner.

### `PATCH /api/v1/partner/service-requests/{id}/accept`
* **Access**: Assigned `ROLE_SERVICE_PARTNER`
* **Description**: Accepts an assigned service request; transitions status to `ACCEPTED`.

### `PATCH /api/v1/partner/service-requests/{id}/reject`
* **Access**: Assigned `ROLE_SERVICE_PARTNER`
* **Description**: Declines an assigned service request with reason; returns request to unassigned pool.

### `PATCH /api/v1/partner/service-requests/{id}/start`
* **Access**: Assigned `ROLE_SERVICE_PARTNER`
* **Description**: Starts work on the service request; transitions status to `IN_PROGRESS`.

### `PATCH /api/v1/partner/service-requests/{id}/complete`
* **Access**: Assigned `ROLE_SERVICE_PARTNER`
* **Description**: Completes the service request; transitions status to `COMPLETED`.

---

## 16. Journey, Documents & Milestones (Phase 7)

### `GET /api/v1/services/requests/{id}/journey`
* **Access**: Customer Owner, Assigned Partner, or `ROLE_ADMIN`
* **Description**: Returns chronological audit timeline of all lifecycle events.

### `POST /api/v1/services/requests/{id}/documents`
* **Access**: Customer Owner, Assigned Partner, or `ROLE_ADMIN`
* **Description**: Uploads a service document (CAD, deed, receipt, report).

### `GET /api/v1/services/requests/{id}/documents`
* **Access**: Customer Owner, Assigned Partner, or `ROLE_ADMIN`
* **Description**: Lists all documents linked to the service request.

### `PATCH /api/v1/services/documents/{id}/verify`
* **Access**: `ROLE_ADMIN` or `ROLE_STAFF`
* **Description**: Verifies a legal or technical service document.

### `POST /api/v1/partner/service-requests/{id}/milestones`
* **Access**: Assigned `ROLE_SERVICE_PARTNER`
* **Description**: Adds a deliverable milestone with target amount and sequence.

### `PATCH /api/v1/services/milestones/{id}/approve`
* **Access**: Customer Owner or `ROLE_ADMIN` (Partners blocked)
* **Description**: Signs off on and approves a milestone deliverable.

---

## 17. Payments Ledger & Webhooks (Phase 7)

### `POST /api/v1/services/payments/create`
* **Access**: Customer Owner
* **Description**: Initiates a payment order via provider abstraction (`MOCK`, `RAZORPAY`).

### `GET /api/v1/services/payments/{id}`
* **Access**: Customer Owner, Assigned Partner, or `ROLE_ADMIN`
* **Description**: Retrieves payment transaction ledger details.

### `POST /api/v1/services/payments/webhook`
* **Access**: Public / Gateway Webhook (Cryptographically Verified)
* **Description**: Processes gateway settlement callbacks, verifies HMAC signature, marks payment `PAID`, updates request balance, and notifies customer.

---

## 18. Feedback & Partner CRM (Phase 7)

### `POST /api/v1/services/requests/{id}/feedback`
* **Access**: Customer Owner
* **Description**: Submits 1-5 star rating and comment for completed service. Blocks duplicate reviews.

### `GET /api/v1/partner/customers`
* **Access**: `ROLE_SERVICE_PARTNER`
* **Description**: Lists distinct customers serviced by the partner.

### `POST /api/v1/partner/customers/{id}/notes`
* **Access**: `ROLE_SERVICE_PARTNER`
* **Description**: Adds internal partner CRM notes for a serviced customer.

---

## 19. Service Dashboards (Phase 7)

### `GET /api/v1/partner/dashboard`
* **Access**: `ROLE_SERVICE_PARTNER`
* **Description**: Live, dynamic KPIs for the partner (`newRequests`, `activeServices`, `completedServices`, `totalEarnings`, `averageRating`).

### `GET /api/v1/admin/services/dashboard`
* **Access**: `ROLE_ADMIN`
* **Description**: Platform-wide dynamic service KPIs (`totalPartners`, `activePartners`, `totalRequests`, `totalRevenue`, `averageRating`).

---

## 20. Centralized CRM Lead Lifecycle (Phase 8)

### `PATCH /api/v1/crm/leads/{id}/stage`
* **Access**: Dealer Owner or `ROLE_ADMIN`
* **Description**: Transitions lead stage (`NEW`, `CONTACTED`, `QUALIFIED`, `SITE_VISIT_SCHEDULED`, `NEGOTIATION`, `CONVERTED`, `LOST`, `DORMANT`). Emits `LEAD_STAGE_CHANGED` outbox event.

### `PATCH /api/v1/crm/leads/{id}/convert`
* **Access**: Dealer Owner or `ROLE_ADMIN`
* **Description**: Converts qualified lead to won sale / active customer. Emits `LEAD_CONVERTED` outbox event.

### `DELETE /api/v1/crm/leads/{id}`
* **Access**: `ROLE_ADMIN` only
* **Description**: Permanently deletes or archives lead record.

---

## 21. Customer 360 API (Phase 8)

### `GET /api/v1/crm/customers/{id}/360`
* **Access**: `ROLE_DEALER`, `ROLE_ADMIN`
* **Description**: Unifies buyer/dealer profiles, property inquiries, site visits, service journeys, activities, notes, tasks, and contact preferences into a single response.

### `GET /api/v1/crm/customers/by-phone/360`
* **Access**: `ROLE_DEALER`, `ROLE_ADMIN`
* **Description**: Lookup customer 360 dossier directly by normalized phone number.

---

## 22. CRM Notes, Tasks & Follow-ups (Phase 8)

### `POST /api/v1/crm/notes` & `POST /api/v1/crm/leads/{id}/notes`
* **Access**: Dealer Owner or `ROLE_ADMIN`
* **Description**: Attaches internal collaboration notes to a lead.

### `PATCH /api/v1/crm/notes/{id}` & `DELETE /api/v1/crm/notes/{id}`
* **Access**: Author or `ROLE_ADMIN`
* **Description**: Updates or removes CRM note.

### `POST /api/v1/crm/tasks` & `POST /api/v1/crm/leads/{id}/tasks`
* **Access**: Dealer or `ROLE_ADMIN`
* **Description**: Creates actionable task with deadline and priority.

### `PATCH /api/v1/crm/tasks/{id}/complete`
* **Access**: Assignee or `ROLE_ADMIN`
* **Description**: Marks task completed with completion timestamp.

---

## 23. Meta WhatsApp Business Cloud API (Phase 8)

### `POST /api/v1/whatsapp/send`
* **Access**: Authenticated Staff, Dealer, or `ROLE_ADMIN`
* **Description**: Dispatches approved template message via Meta Graph API v18.0. Enforces customer opt-in check.

### `GET /api/v1/whatsapp/templates`
* **Access**: Authenticated
* **Description**: Lists registered and approved Meta WhatsApp templates.

### `POST /api/v1/whatsapp/templates`
* **Access**: `ROLE_ADMIN`
* **Description**: Registers new message template.

### `GET /api/v1/whatsapp/webhook`
* **Access**: Public / Meta Handshake
* **Description**: Meta webhook subscription challenge verification (`hub.verify_token`).

### `POST /api/v1/whatsapp/webhook`
* **Access**: Public / Meta Webhook
* **Description**: Delivery receipts and read status ingestion.

---

## 24. Contact Preferences & Consent (Phase 8)

### `GET /api/v1/communication/preferences?phone={phone}`
* **Access**: Authenticated User or `ROLE_ADMIN`
* **Description**: Retrieves current multi-channel opt-in preferences.

### `PATCH /api/v1/communication/preferences`
* **Access**: Authenticated User or `ROLE_ADMIN`
* **Description**: Updates WhatsApp, Email, SMS, and Marketing consent flags.

---

## 25. CRM Search & Real-Time Analytics (Phase 8)

### `GET /api/v1/crm/search?q={query}`
* **Access**: `ROLE_DEALER`, `ROLE_ADMIN`
* **Description**: Fast multi-entity search across leads, customer names, phone numbers, and properties.

### `GET /api/v1/crm/analytics`
* **Access**: `ROLE_DEALER`, `ROLE_ADMIN`
* **Description**: Live, dynamic KPIs computed from PostgreSQL (total leads, conversion rate, leads by stage, leads by source). Zero hardcoded or mock metrics.



