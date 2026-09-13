# PropZen Notification Engine & Multi-Channel Communications (Phase 8)

The PropZen Notification Engine coordinates transactional and marketing communications across WhatsApp, SMS, Email, and in-app feeds while strictly honoring customer preferences.

---

## 1. Notification Architecture

```
  [ Business Event (Lead, Service, Milestone, Payment) ]
                            │
                            ▼
               [ Outbox Event Consumer ]
                            │
                            ▼
              [ Notification Router / Service ]
                            │
       ┌────────────────────┼────────────────────┐
       ▼                    ▼                    ▼
[ WhatsApp Channel ]   [ Email Channel ]    [ SMS Channel ]
 (Meta Cloud API)      (SMTP / Provider)    (SMS Gateway)
       │                    │                    │
       └────────────────────┼────────────────────┘
                            │
                            ▼
             [ public.crm_communications ]
       (Audit Log: Channel, Status, Message ID)
```

---

## 2. Supported Notification Channels

| Channel | Model Enum | Primary Use Cases | Provider |
|---|---|---|---|
| **WhatsApp** | `CommunicationChannel.WHATSAPP` | Instant welcome, site visit reminders, milestone alerts | Meta WhatsApp Cloud API |
| **Email** | `CommunicationChannel.EMAIL` | Formal invoices, inspection reports, contracts | SMTP / SendGrid / SES |
| **SMS** | `CommunicationChannel.SMS` | OTP verification, critical security alerts | Twilio / Gupshup |
| **Call** | `CommunicationChannel.CALL` | Direct telephonic call logging | Telephony CRM log |

---

## 3. Contact Preferences & Consent Management

To comply with regulatory standards (GDPR, TRAI DND, CAN-SPAM), PropZen implements granular opt-in checks via `public.crm_contact_preferences`:

### Schema
- `id` (UUID, PK)
- `customer_id` (UUID, nullable, references user)
- `phone` (VARCHAR, unique)
- `whatsapp_opt_in` (BOOLEAN, default TRUE)
- `marketing_opt_in` (BOOLEAN, default TRUE)
- `email_opt_in` (BOOLEAN, default TRUE)
- `sms_opt_in` (BOOLEAN, default TRUE)
- `updated_at` (TIMESTAMPTZ)

### Endpoints
- `GET /api/v1/communication/preferences?phone={phone}`: Fetch customer's current preferences.
- `PATCH /api/v1/communication/preferences`: Update preferences.
  ```json
  {
    "phone": "+919876543210",
    "whatsappOptIn": false,
    "marketingOptIn": false
  }
  ```

---

## 4. Communication History & Audit Trail

All outgoing and incoming messages are logged into `public.crm_communications`:
- `id`: Unique communication ID
- `lead_id` / `customer_id`: Associated entity
- `channel`: `WHATSAPP`, `EMAIL`, `SMS`, `CALL`
- `direction`: `INBOUND`, `OUTBOUND`
- `sender`, `recipient`: Identifiers (phone or email)
- `template_name`: Message template used
- `status`: `PENDING`, `SENT`, `DELIVERED`, `READ`, `FAILED`
- `provider_message_id`: External message ID (e.g. Meta `wamid.HBg...`)
- `error_message`: Failure details (if any)
- `created_at`: Timestamp
