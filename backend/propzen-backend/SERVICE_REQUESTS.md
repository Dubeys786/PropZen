# PropZen Service Requests & Lifecycle Management (Phase 7)

The Service Request subsystem manages the complete customer service request lifecycle from creation to milestone delivery, payment settlement, and verified review.

---

## 1. Service Request Lifecycle

```
    [ Customer Submission ]
    (POST /api/v1/services/requests)
              │
              ▼
           [ NEW ]
              │
    (Admin Assignment)
              │
              ▼
        [ ASSIGNED ]
         /         \
(Partner Accept)  (Partner Decline / Timeout)
       /             \
      ▼               ▼
 [ ACCEPTED ]   [ PENDING_ASSIGNMENT ] ──► (Re-assign)
      │
(Partner Starts)
      │
      ▼
[ IN_PROGRESS ] ◄──► [ ON_HOLD ]
      │
(Partner Finishes)
      │
      ▼
 [ COMPLETED ]
```

* Customers can cancel their request while in `NEW` or `ASSIGNED` status (`PATCH /api/v1/services/requests/{id}/cancel`).
* When partner accepts, customer receives a real-time notification with partner details.

---

## 2. Service Journey Audit Timeline

Every critical lifecycle event automatically appends an immutable audit entry to `public.service_journey_events`:

* `REQUEST_CREATED`: Customer submitted request with location and budget.
* `PARTNER_ASSIGNED`: Admin matched and assigned candidate service partner.
* `PARTNER_ACCEPTED`: Partner accepted request and committed to service turnaround.
* `PARTNER_REJECTED`: Partner declined assignment with recorded reason.
* `WORK_STARTED`: Partner initiated physical site work or document drafting.
* `MILESTONE_CREATED`: Partner broke down deliverables into measurable phases.
* `MILESTONE_COMPLETED`: Customer signed off on milestone deliverable.
* `DOCUMENT_UPLOADED`: Customer or partner uploaded architectural plan, deed, or KYC document.
* `DOCUMENT_VERIFIED`: PropZen compliance team verified legal authenticity.
* `PAYMENT_RECEIVED`: Escrow/gateway settlement confirmed via webhook.
* `SERVICE_COMPLETED`: Final deliverable handed over to customer.
* `SERVICE_CANCELLED`: Request cancelled by customer or administrator.

---

## 3. Milestones & Progress Calculation

Large real-estate services (renovations, construction, architectural planning) use stage-gated milestone delivery:

* **Creation**: Partner adds milestones with title, description, and amount (`POST /api/v1/partner/service-requests/{id}/milestones`).
* **Progress Formula**:
  $$\text{Progress \%} = \frac{\text{Count of APPROVED Milestones}}{\text{Total Milestones}} \times 100$$
* **Zero Self-Approval**: Service partners **cannot** approve their own milestones (HTTP 403 Forbidden). Milestone sign-off must be performed by the paying customer (`PATCH /api/v1/services/milestones/{id}/approve`) or an administrator.

---

## 4. Customer Feedback & Review Aggregation

Once a service transitions to `COMPLETED`:
* Customer submits 1-5 star rating and comment (`POST /api/v1/services/requests/{id}/feedback`).
* Duplicate reviews for the same service request are rejected with `HTTP 400 DUPLICATE_RESOURCE`.
* Submitting feedback atomically recalculates and updates the partner profile's `rating` in `public.service_partner_profiles`.
