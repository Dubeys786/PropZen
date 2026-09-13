# PropZen Service Management Architecture (Phase 7)

The PropZen Service Management subsystem is a production-ready, multi-tenant marketplace platform that powers real-estate ancillary services across home loans, interior design, vastu consultation, construction, legal property verification, and 3D visualization.

---

## 1. Subsystem Architecture

```
                  [ Customer / Web / Mobile ]          [ Service Partner Portal ]
                               │                                    │
                               ▼                                    ▼
                 [ /api/v1/services/requests ]          [ /api/v1/partner/** ]
                               │                                    │
                               └──────────────┬─────────────────────┘
                                              ▼
                                 [ Spring Security RBAC ]
                          (ROLE_BUYER, ROLE_SERVICE_PARTNER, ROLE_ADMIN)
                                              │
                      ┌───────────────────────┼───────────────────────┐
                      ▼                       ▼                       ▼
            [ Service Requests ]     [ Partner Engine ]     [ Payments Ledger ]
            - Status FSM             - Weighted Matching    - Provider Agnostic
            - Journey Timeline       - Workload Balancing   - Webhook Settlement
            - Documents & Milestones - Rating & Reviews     - Zero Card Storage
                      │                       │                       │
                      └───────────────────────┼───────────────────────┘
                                              ▼
                                [ PostgreSQL / Supabase ]
                                (10 Tables, Indexed B-Tree)
```

---

## 2. Core Service Categories

Initial canonical categories seeded via migration `V5__create_service_management_schema.sql`:

| Slug | Category Name | Description | Default Icon |
|---|---|---|---|
| `loan-home-finance` | Home Loan & Finance | Bank loan origination, pre-approval, and mortgage advisory | `account_balance` |
| `home-design` | Home Design & Interiors | Premium interior architecture and 3D space planning | `design_services` |
| `vastu-consultation` | Vastu Consultation | Traditional spatial harmony and architectural energy analysis | `compass_calibration` |
| `construction` | Construction & Renovation | Civil construction, remodeling, and structural audits | `construction` |
| `property-verification` | Legal & Property Verification | Title deed search, encumbrance verification, and risk audit | `verified` |
| `virtual-3d-visualization` | 3D Visualization & VR | Architectural 3D rendering, walkthroughs, and VR staging | `view_in_ar` |

Categories can be managed dynamically by administrators via `/api/v1/admin/services/categories` without application redeployment or code modifications.

---

## 3. Dynamic Real-Time Dashboards

No dashboard metrics in PropZen are hardcoded. Both partner and administrative dashboards calculate statistics directly from transactional PostgreSQL tables.

### A. Partner Dashboard (`GET /api/v1/partner/dashboard`)
* `newRequests`: Count of assigned requests awaiting partner acceptance.
* `pendingRequests`: Count of unassigned pool requests in the partner's category.
* `activeServices`: Count of ongoing requests in `ACCEPTED`, `IN_PROGRESS`, or `ON_HOLD`.
* `completedServices`: Total completed requests handled by this partner.
* `pendingPayments`: Payments ledger entries awaiting customer settlement.
* `totalEarnings`: Sum of all settled (`PAID`) payments for this partner.
* `averageRating`: Aggregate customer rating (1.0 - 5.0) rounded to 1 decimal place.
* `customerCount`: Distinct customer IDs serviced by this partner.

### B. Admin Dashboard (`GET /api/v1/admin/services/dashboard`)
* `totalPartners`, `pendingPartners`, `verifiedPartners`, `activePartners`
* `totalRequests`, `newRequests`, `activeRequests`, `completedRequests`, `cancelledRequests`
* `totalRevenue`: Global sum of all settled service payments across all categories.
* `pendingPayments`: Total pending payments across the system.
* `averageRating`: System-wide customer satisfaction score.

---

## 4. Payment Subsystem Architecture

PropZen uses a **provider-agnostic payment ledger** designed for enterprise compliance and strict zero-card-storage security:

* **Payment Gateway Abstraction**: `PaymentProvider` interface supports pluggable payment processors (`MockPaymentProvider`, `RazorpayPaymentProvider`).
* **Security & Compliance**: Zero credit card numbers, CVVs, expiration dates, or bank passwords are ever transmitted to or stored on PropZen servers. All transactions utilize client-side tokenized checkout or secure redirect hosted pages.
* **Webhook Signature Validation**: Inbound payment provider callbacks (`POST /api/v1/services/payments/webhook`) cryptographically verify the provider's signature before recording settlement.
* **Double-Spending Prevention**: Each payment transaction has a unique `provider_order_id` index and idempotency protection in PostgreSQL.
