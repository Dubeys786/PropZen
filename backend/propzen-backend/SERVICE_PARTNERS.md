# PropZen Service Partners & Partner Portal (Phase 7)

The Service Partner subsystem governs partner onboarding, verification, profile governance, intelligent matching, and partner CRM customer management.

---

## 1. Partner Lifecycle & Finite State Machine

```
              [ User Application ]
              (POST /service-partners/apply)
                       │
                       ▼
                 [ PENDING ] ──(Admin Rejection)──► [ REJECTED ]
                       │
             (Admin Approval via PATCH)
                       │
                       ▼
                 [ APPROVED ] ◄──(Admin Re-activation)
                       │                              ▲
             (Admin Suspension via PATCH)             │
                       │                              │
                       └──────────────────────────────┘
```

### Verification States:
* `PENDING`: Initial status after application submission.
* `UNDER_REVIEW`: Admin/Staff actively verifying business credentials, licenses, and KYC.
* `VERIFIED`: Partner passed business verification check; eligible for automated request recommendation.
* `REJECTED`: Partner business credentials failed verification check.

---

## 2. Multi-Criteria Partner Recommendation Engine

When an administrator reviews a service request, `ServiceAssignmentService.getRecommendations(requestId)` executes a deterministic, multi-criteria scoring algorithm across all verified and approved partners:

$$\text{Score} = \text{Rating Points} (35) + \text{Workload Points} (40) + \text{Experience Points} (25) + \text{City Match Bonus} (15)$$

1. **Category Match**: Partner must support the requested service category.
2. **Customer Rating (35 pts max)**: Scaled based on partner's historical 1-5 star customer review average.
3. **Workload Balance (40 pts max)**: Partners with fewer active services score higher, preventing bottlenecks ($40 - (\text{active} \times 4)$).
4. **Experience (25 pts max)**: Based on confirmed industry experience years ($2.5 \times \min(\text{years}, 10)$).
5. **Location Bonus (15 pts bonus)**: Partners located in or serving the specific customer city receive a 15-point proximity boost.

---

## 3. Partner CRM & Serviced Customer Privacy

Service partners can view only customers who have requested or been assigned services with them. Cross-partner access is strictly prohibited:

* **Customer Directory** (`GET /api/v1/partner/customers`): Returns list of distinct customers whose requests were assigned to the authenticated partner.
* **Customer Detail** (`GET /api/v1/partner/customers/{id}`): Verifies partnership relationship before displaying customer contact details.
* **CRM Notes** (`POST /api/v1/partner/customers/{id}/notes`): Allows partners to record internal customer preferences, measurements, site peculiarities, or scheduling notes.
* **CRM Note Retrieval** (`GET /api/v1/partner/customers/{id}/notes`): Only the partner who authored the notes (or an administrator) can read customer CRM notes.
