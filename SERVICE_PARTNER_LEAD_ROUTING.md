# Service Partner Lead Routing & Assignment System

## Executive Overview
The **PropZen Service Partner Lead Routing & Assignment System** is an end-to-end, production-grade service enquiry lifecycle engine. It connects customer service requests initiated from the PropZen Service Hub directly into the authoritative PostgreSQL CRM database (`crm_leads`), evaluates candidate service partners using a deterministic, multi-criteria scoring algorithm, assigns the optimal verified partner, enforces strict tenant isolation on partner dashboards, and gives both customers and PropZen administrators real-time tracking and control.

---

## 1. Architectural Blueprint & Workflow

```
CUSTOMER SERVICE INTAKE
  (Web/App Service Hub: Home Loan, Interior Design, Vastu, Legal Check, Construction, 3D Tour)
         │
         ▼
POST /api/v1/crm/leads/service-enquiry
  (Spring Boot LeadController: validates payload, binds customer identity, persists to crm_leads)
         │
         ▼
DETERMINISTIC MULTI-CRITERIA ROUTING ENGINE
  (ServicePartnerLeadRoutingService.java)
  ├── 1. Category Matching: partner.approved_categories CONTAINS lead.service_category
  ├── 2. Verification Gate: status == APPROVED && is_verified == TRUE && is_suspended == FALSE
  ├── 3. Multi-Criteria Scoring (0 - 100 points):
  │       ├── Proximity Match (+40 pts)
  │       ├── Workload Balancing (+35 pts)
  │       └── Partner Rating & Experience (+25 pts)
  └── 4. Deterministic Tie-Breaker: earliest verified_at, then UUID lexicographical sort
         │
    ┌────┴────────────────────────┐
    ▼                             ▼
[Optimal Partner Found]     [No Partner Eligible]
    │                             │
    ▼                             ▼
AUTO-ASSIGNED                 FALLBACK QUEUE
- assigned_partner_id set     - assigned_partner_id = NULL
- assignment_status = ASSIGNED - assignment_status = UNASSIGNED
- Audit event emitted         - Flagged in Admin Section 30
    │                             │
    ▼                             ▼
PARTNER DASHBOARD             ADMIN MANUAL OVERRIDE
(Tenant Isolation:            (Scored Candidate Dialog:
 assigned_partner_id == ID)    1-click assign or unassign)
```

---

## 2. Database Schema (`V10__add_service_partner_fields_to_crm_leads.sql`)

The `crm_leads` table was enriched with dedicated fields and high-performance indexes:

```sql
ALTER TABLE crm_leads
    ADD COLUMN IF NOT EXISTS service_category VARCHAR(64),
    ADD COLUMN IF NOT EXISTS assigned_partner_id UUID REFERENCES service_partner_profiles(id) ON DELETE SET NULL,
    ADD COLUMN IF NOT EXISTS assignment_status VARCHAR(32) NOT NULL DEFAULT 'UNASSIGNED';

-- Indexes for lightning-fast queries and dashboard isolation
CREATE INDEX IF NOT EXISTS idx_crm_leads_partner_assigned
    ON crm_leads(assigned_partner_id)
    WHERE assigned_partner_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_crm_leads_category_unassigned
    ON crm_leads(service_category, assignment_status)
    WHERE assignment_status = 'UNASSIGNED';

CREATE INDEX IF NOT EXISTS idx_crm_leads_service_category
    ON crm_leads(service_category);
```

---

## 3. Deterministic Multi-Criteria Routing Algorithm

The routing engine implemented in `ServicePartnerLeadRoutingService.java` is 100% deterministic, eliminating nondeterministic race conditions or random assignments.

### Eligibility Filter
Candidate partners must satisfy all prerequisites:
1. `service_category` matches one of the partner's approved specializations.
2. `partner_status == PartnerStatus.APPROVED`.
3. `is_verified == true`.
4. `is_suspended == false`.

### Scoring Rubric (Max Score = 100)

| Criterion | Max Weight | Logic / Formula |
|---|---|---|
| **Proximity Match** | **40 pts** | **40 pts**: Preferred sector/city match with operating city.<br>**25 pts**: Operating city match with lead city.<br>**10 pts**: NCR regional match.<br>**0 pts**: Out of area. |
| **Workload Balancing** | **35 pts** | Evaluates active assigned leads (`IN_PROGRESS` or `NEW`):<br>**35 pts**: 0–2 active leads (high capacity)<br>**25 pts**: 3–5 active leads<br>**15 pts**: 6–10 active leads<br>**0 pts**: >10 active leads (at capacity) |
| **Rating & Quality** | **25 pts** | `(rating / 5.0) * 25 pts`<br>A 5.0-star partner receives the full 25 points; a 4.0-star partner receives 20 points. |

### Tie-Breaker
In the event of an exact score tie:
1. Earliest `verified_at` timestamp takes priority.
2. If timestamps are identical, deterministic lexicographical order of partner `UUID` is used.

---

## 4. API Endpoints

| Method | Endpoint | Access | Description |
|---|---|---|---|
| `POST` | `/api/v1/crm/leads/service-enquiry` | Public / Authenticated | Submit new service enquiry lead |
| `GET` | `/api/v1/crm/leads/my` | Authenticated Customer | Retrieve logged-in customer's submitted service requests |
| `GET` | `/api/v1/crm/leads/{id}/eligible-partners` | Admin (`ROLE_ADMIN`) | Retrieve ranked candidate partners scored for this lead |
| `PATCH` | `/api/v1/crm/leads/{id}/assign-partner` | Admin (`ROLE_ADMIN`) | Manually assign lead to selected partner |
| `PATCH` | `/api/v1/crm/leads/{id}/unassign-partner` | Admin (`ROLE_ADMIN`) | Remove partner and return lead to unassigned queue |

---

## 5. Frontend Interfaces

### A. Admin Command Center — Section 30: Service Lead Routing
- Accessible via CRM navigation item **"Service Lead Routing"** with dynamic unassigned badge count.
- **KPI Metrics Cards**: Total Enquiries, Unassigned Queue (urgent attention), Assigned, In Progress, and Completed.
- **Category Filter Tabs**: All Categories, Home Loan, Interior Design, Vastu, Legal Check, Construction, 3D Tour.
- **Queue Filter Chips**: All, Unassigned Queue, Assigned, In Progress.
- **Candidate Scoring Modal**: Opens on clicking "Manual Assign" on any unassigned lead. Lists all eligible partners sorted by deterministic score (Workload, Rating, City) with a 1-click **Assign** button.
- **Unassign Action**: 1-click unassign with instant re-queueing to the fallback pool.

### B. Specialized Service Partner Portals
- Dashboards for all 6 verticals:
  1. `loan_partner_dashboard.dart`
  2. `home_design_partner_dashboard.dart`
  3. `vastu_partner_dashboard.dart`
  4. `construction_partner_dashboard.dart`
  5. `property_verification_partner_dashboard.dart`
  6. `virtual_3d_partner_dashboard.dart`
- **Tenant Isolation**: Only requests matching `assigned_partner_id == currentPartner.id` are retrieved and displayed.
- Hardcoded dummy IDs (`SP-LOAN-001`, `SP-DESIGN-001`, etc.) were completely eliminated.

### C. Customer Profile — "My Service Requests"
- Customer views service requests via **`MyServiceRequestsScreen`** accessed from `UserProfileScreen`.
- Features real-time status pills (`ASSIGNED`, `MATCHING`), assigned partner details, inquiry details modal, and progress tracker timeline:
  `Submitted → Partner Matched → In Progress → Completed`.

---

## 6. Automated Integration Tests
The routing engine is verified by comprehensive integration tests in `ServicePartnerLeadRoutingIntegrationTest.java`:
1. `testDeterministicRouting_HighestScoreWins`: Validates that the partner with higher rating, closer proximity, and lower workload receives the lead.
2. `testFallbackToUnassigned_WhenNoPartnerEligible`: Validates graceful fallback to `UNASSIGNED` queue when no partner provides the requested category.
3. `testAdminManualAssignmentAndUnassignWorkflow`: Validates manual assignment by admin and subsequent unassign back to queue.
4. `testCustomerCanRetrieveTheirOwnLeads`: Validates IDOR security and customer visibility via `/my`.
5. `testPartnerDashboardIsolation`: Validates tenant isolation so Partner A cannot see leads assigned to Partner B.
