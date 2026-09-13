# PropZen WhatsApp Business Cloud API Architecture (Phase 8)

The PropZen backend provides a production-grade integration with the official **Meta WhatsApp Business Cloud API**, enabling automated alerts, milestone notifications, site visit confirmations, and dealer 1-click messaging.

---

## 1. Meta Cloud API Architecture

```
  [ Spring Boot Business Services / Automation Engine ]
                            │
                            ▼
               [ WhatsAppNotificationService ]
                            │
            ┌───────────────┴───────────────┐
            │ Check Consent (Opt-in)        │
            │ Load Approved Template        │
            │ Format Parameters             │
            └───────────────┬───────────────┘
                            │
                            ▼
                   [ WhatsAppProvider ]
                   (Interface Contract)
                            │
              ┌─────────────┴─────────────┐
              ▼                           ▼
    [ MetaWhatsAppProvider ]    [ MockWhatsAppProvider ]
      (Meta Graph API v18.0)      (Local Dev & CI Tests)
              │
              ▼
   [ Meta WhatsApp Graph API ]
    (graph.facebook.com/v18.0)
              │
              ▼
    [ Customer WhatsApp Client ]
              │
              ▼ (Delivery / Read Status Webhook)
   [ POST /api/v1/whatsapp/webhook ]
              │
              ▼
   [ CrmCommunicationService ]
  (Updates status to DELIVERED / READ)
```

---

## 2. Configuration & Secrets

All credentials are encrypted and injected via environment variables:

| Property | Environment Variable | Description |
|---|---|---|
| `propzen.whatsapp.provider` | `PROPZEN_WHATSAPP_PROVIDER` | `meta` for production, `mock` for local dev/testing |
| `propzen.whatsapp.api-url` | `PROPZEN_WHATSAPP_API_URL` | Base URL (default: `https://graph.facebook.com/v18.0`) |
| `propzen.whatsapp.phone-number-id` | `PROPZEN_WHATSAPP_PHONE_NUMBER_ID` | Meta WhatsApp Sender Phone Number ID |
| `propzen.whatsapp.access-token` | `PROPZEN_WHATSAPP_ACCESS_TOKEN` | System User Permanent Access Token |
| `propzen.whatsapp.business-account-id` | `PROPZEN_WHATSAPP_BUSINESS_ACCOUNT_ID` | Meta Business Manager Account ID |
| `propzen.whatsapp.webhook-verify-token` | `PROPZEN_WHATSAPP_WEBHOOK_VERIFY_TOKEN` | Secret verify token for Meta Webhook handshake |

---

## 3. Seeded Meta Approved Templates

The database table `public.whatsapp_templates` manages approved templates:

1. **`lead_welcome_v1`** (Category: `MARKETING`)
   - Text: `Hello {{customer_name}}, thank you for your inquiry about {{property_title}}. Our dedicated property advisor will assist you shortly.`
2. **`site_visit_confirmed_v1`** (Category: `UTILITY`)
   - Text: `Hi {{customer_name}}, your site visit for {{property_title}} is confirmed on {{scheduled_date}} at {{scheduled_time}}. Our representative {{agent_name}} ({{agent_phone}}) will meet you at the site.`
3. **`service_request_update_v1`** (Category: `UTILITY`)
   - Text: `Dear {{customer_name}}, your service request #{{request_number}} for {{service_category}} has been updated to: {{status}}. Partner assigned: {{partner_name}}.`
4. **`milestone_payment_received_v1`** (Category: `UTILITY`)
   - Text: `Payment of INR {{amount}} received for milestone '{{milestone_title}}' on request #{{request_number}}. Thank you for choosing PropZen!`

---

## 4. Endpoints Reference

### 4.1 Dispatching Messages
- **1-Click WhatsApp Direct Message**:
  - `POST /api/v1/whatsapp/send`
  - Body:
    ```json
    {
      "to": "+919876543210",
      "templateName": "lead_welcome_v1",
      "languageCode": "en",
      "parameters": {
        "customer_name": "Ananya Sharma",
        "property_title": "Zen Heights 3BHK"
      },
      "customerId": "uuid-here",
      "leadId": "uuid-here"
    }
    ```
- **Templates Administration**:
  - `GET /api/v1/whatsapp/templates`: List active templates.
  - `POST /api/v1/whatsapp/templates`: Register new template (Admin only).
  - `GET /api/v1/whatsapp/templates/{id}`: Template details.

### 4.2 Webhooks (Inbound Delivery & Read Receipts)
- **GET `/api/v1/whatsapp/webhook`**:
  - Verification endpoint called by Meta during webhook subscription setup. Validates `hub.verify_token` against `PROPZEN_WHATSAPP_WEBHOOK_VERIFY_TOKEN` and returns `hub.challenge`.
- **POST `/api/v1/whatsapp/webhook`**:
  - Ingestion endpoint receiving delivery receipts (`sent`, `delivered`, `read`, `failed`).
  - Automatically correlates message ID to `public.crm_communications` and records timestamps.

---

## 5. Opt-in Consent & Compliance

- Before any WhatsApp message is sent, `ContactPreferenceService` verifies `whatsapp_opt_in = true` for the phone number.
- If the customer has opted out (`whatsapp_opt_in = false`), the message is blocked and logged as `FAILED (Skipped: Opted out)`.
- Customers can manage preferences via `PATCH /api/v1/communication/preferences`.
