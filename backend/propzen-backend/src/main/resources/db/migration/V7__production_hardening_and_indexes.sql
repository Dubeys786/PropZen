-- PropZen Flyway Migration V7: Production Hardening, Audit Logs, In-App Notifications, Deliverables & High-Performance Indexes

-- 1. Persistent Audit Logs Table
CREATE TABLE IF NOT EXISTS public.audit_logs (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    actor_id UUID,
    action VARCHAR(100) NOT NULL,
    target_type VARCHAR(100),
    target_id VARCHAR(100),
    request_id VARCHAR(100),
    timestamp TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    metadata TEXT
);

CREATE INDEX IF NOT EXISTS idx_audit_logs_actor ON public.audit_logs(actor_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_action ON public.audit_logs(action);
CREATE INDEX IF NOT EXISTS idx_audit_logs_timestamp ON public.audit_logs(timestamp DESC);

-- 2. Unified In-App Notifications Table
CREATE TABLE IF NOT EXISTS public.notifications (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL,
    type VARCHAR(50) NOT NULL,
    channel VARCHAR(20) NOT NULL DEFAULT 'IN_APP',
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'SENT',
    sent_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    read_at TIMESTAMPTZ,
    metadata TEXT
);

CREATE INDEX IF NOT EXISTS idx_notifications_user_status ON public.notifications(user_id, status);
CREATE INDEX IF NOT EXISTS idx_notifications_sent_at ON public.notifications(sent_at DESC);

-- 3. Service Deliverables Table
CREATE TABLE IF NOT EXISTS public.service_deliverables (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    service_request_id UUID NOT NULL REFERENCES public.service_requests(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    file_url TEXT,
    status VARCHAR(50) NOT NULL DEFAULT 'SUBMITTED',
    submitted_by UUID,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_service_deliverables_request ON public.service_deliverables(service_request_id);

-- 4. Enhance Contact Preferences with Timestamps & Specific Preference
ALTER TABLE public.crm_contact_preferences ADD COLUMN IF NOT EXISTS whatsapp_opt_in_at TIMESTAMPTZ;
ALTER TABLE public.crm_contact_preferences ADD COLUMN IF NOT EXISTS whatsapp_opt_out_at TIMESTAMPTZ;
ALTER TABLE public.crm_contact_preferences ADD COLUMN IF NOT EXISTS communication_preference VARCHAR(50) DEFAULT 'ALL';

-- 5. Enhance CRM Leads with Property Title
ALTER TABLE public.crm_leads
ADD COLUMN IF NOT EXISTS property_title VARCHAR(255);

-- 6. Production High-Performance B-Tree Indexes
CREATE INDEX IF NOT EXISTS idx_properties_status_city_price ON public.posted_properties(status, city, price_cr);
CREATE INDEX IF NOT EXISTS idx_properties_bhk_type ON public.posted_properties(bhk, property_type);
CREATE INDEX IF NOT EXISTS idx_crm_leads_status_stage ON public.crm_leads(status, stage);
CREATE INDEX IF NOT EXISTS idx_crm_leads_assigned ON public.crm_leads(assigned_to, dealer_id);
CREATE INDEX IF NOT EXISTS idx_crm_leads_phone ON public.crm_leads(phone);
CREATE INDEX IF NOT EXISTS idx_crm_tasks_assigned_status ON public.crm_tasks(assigned_to, status);
CREATE INDEX IF NOT EXISTS idx_crm_followups_lead_status ON public.crm_followups(lead_id, status);
CREATE INDEX IF NOT EXISTS idx_service_requests_customer_status ON public.service_requests(customer_id, status);
CREATE INDEX IF NOT EXISTS idx_service_requests_partner_status ON public.service_requests(partner_id, status);
CREATE INDEX IF NOT EXISTS idx_service_payments_req_status ON public.service_payments(service_request_id, status);
CREATE INDEX IF NOT EXISTS idx_service_feedback_req ON public.service_feedback(service_request_id, partner_id);
CREATE INDEX IF NOT EXISTS idx_crm_communications_lead_cust ON public.crm_communications(lead_id, customer_id, channel);
