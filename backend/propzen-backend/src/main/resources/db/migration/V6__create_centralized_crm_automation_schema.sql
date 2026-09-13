-- =============================================================================
-- PROPZEN FLYWAY MIGRATION V6: CENTRALIZED CRM, AUTOMATION & NOTIFICATIONS
-- =============================================================================
-- Target Database: Supabase PostgreSQL (Project eemxylswyvhsyzllcsnp)
--
-- Safely enhances crm_leads and creates tables for activities, notes, followups,
-- tasks, communications, whatsapp_templates, contact preferences, outbox events,
-- tags, and staff assignment history.
-- =============================================================================

-- 1. Enhance crm_leads table
ALTER TABLE public.crm_leads ADD COLUMN IF NOT EXISTS stage VARCHAR(50) NOT NULL DEFAULT 'NEW_LEAD';
ALTER TABLE public.crm_leads ADD COLUMN IF NOT EXISTS lead_type VARCHAR(50) DEFAULT 'BUYER';
ALTER TABLE public.crm_leads ADD COLUMN IF NOT EXISTS notes TEXT;

CREATE INDEX IF NOT EXISTS idx_crm_leads_stage ON public.crm_leads(stage);
CREATE INDEX IF NOT EXISTS idx_crm_leads_lead_type ON public.crm_leads(lead_type);

-- 2. CRM Activities Table
CREATE TABLE IF NOT EXISTS public.crm_activities (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    lead_id UUID REFERENCES public.crm_leads(id) ON DELETE CASCADE,
    customer_id UUID,
    activity_type VARCHAR(50) NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    performed_by UUID,
    metadata TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_crm_activities_lead_id ON public.crm_activities(lead_id);
CREATE INDEX IF NOT EXISTS idx_crm_activities_customer_id ON public.crm_activities(customer_id);
CREATE INDEX IF NOT EXISTS idx_crm_activities_type ON public.crm_activities(activity_type);
CREATE INDEX IF NOT EXISTS idx_crm_activities_created_at ON public.crm_activities(created_at);

-- 3. CRM Notes Table
CREATE TABLE IF NOT EXISTS public.crm_notes (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    lead_id UUID REFERENCES public.crm_leads(id) ON DELETE CASCADE,
    customer_id UUID,
    created_by UUID NOT NULL,
    note TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_crm_notes_lead_id ON public.crm_notes(lead_id);
CREATE INDEX IF NOT EXISTS idx_crm_notes_customer_id ON public.crm_notes(customer_id);
CREATE INDEX IF NOT EXISTS idx_crm_notes_created_by ON public.crm_notes(created_by);

-- 4. CRM Follow-ups Table
CREATE TABLE IF NOT EXISTS public.crm_followups (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    lead_id UUID REFERENCES public.crm_leads(id) ON DELETE CASCADE,
    assigned_to UUID,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    followup_at TIMESTAMPTZ NOT NULL,
    priority VARCHAR(20) NOT NULL DEFAULT 'MEDIUM',
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_crm_followups_lead_id ON public.crm_followups(lead_id);
CREATE INDEX IF NOT EXISTS idx_crm_followups_assigned_to ON public.crm_followups(assigned_to);
CREATE INDEX IF NOT EXISTS idx_crm_followups_status ON public.crm_followups(status);
CREATE INDEX IF NOT EXISTS idx_crm_followups_followup_at ON public.crm_followups(followup_at);

-- 5. CRM Tasks Table
CREATE TABLE IF NOT EXISTS public.crm_tasks (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    assigned_to UUID,
    lead_id UUID REFERENCES public.crm_leads(id) ON DELETE SET NULL,
    customer_id UUID,
    priority VARCHAR(20) NOT NULL DEFAULT 'MEDIUM',
    status VARCHAR(20) NOT NULL DEFAULT 'TODO',
    due_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_crm_tasks_assigned_to ON public.crm_tasks(assigned_to);
CREATE INDEX IF NOT EXISTS idx_crm_tasks_status ON public.crm_tasks(status);
CREATE INDEX IF NOT EXISTS idx_crm_tasks_due_at ON public.crm_tasks(due_at);
CREATE INDEX IF NOT EXISTS idx_crm_tasks_lead_id ON public.crm_tasks(lead_id);
CREATE INDEX IF NOT EXISTS idx_crm_tasks_customer_id ON public.crm_tasks(customer_id);

-- 6. Centralized Communications History Table
CREATE TABLE IF NOT EXISTS public.crm_communications (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    lead_id UUID REFERENCES public.crm_leads(id) ON DELETE SET NULL,
    customer_id UUID,
    channel VARCHAR(20) NOT NULL DEFAULT 'WHATSAPP',
    direction VARCHAR(10) NOT NULL DEFAULT 'OUTBOUND',
    template_id UUID,
    provider_message_id VARCHAR(255),
    message_preview VARCHAR(500),
    status VARCHAR(20) NOT NULL DEFAULT 'QUEUED',
    sent_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_crm_comm_lead_id ON public.crm_communications(lead_id);
CREATE INDEX IF NOT EXISTS idx_crm_comm_customer_id ON public.crm_communications(customer_id);
CREATE INDEX IF NOT EXISTS idx_crm_comm_channel ON public.crm_communications(channel);
CREATE INDEX IF NOT EXISTS idx_crm_comm_provider_msg_id ON public.crm_communications(provider_message_id);
CREATE INDEX IF NOT EXISTS idx_crm_comm_status ON public.crm_communications(status);
CREATE INDEX IF NOT EXISTS idx_crm_comm_created_at ON public.crm_communications(created_at);

-- 7. WhatsApp Templates Table
CREATE TABLE IF NOT EXISTS public.whatsapp_templates (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL,
    template_name VARCHAR(100) NOT NULL,
    language VARCHAR(10) NOT NULL DEFAULT 'en',
    category VARCHAR(30) NOT NULL DEFAULT 'UTILITY',
    content TEXT NOT NULL,
    provider_template_id VARCHAR(100),
    status VARCHAR(30) NOT NULL DEFAULT 'APPROVED',
    variables TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_whatsapp_templates_name ON public.whatsapp_templates(template_name);

-- 8. Contact Preferences (Opt-in / Consent)
CREATE TABLE IF NOT EXISTS public.crm_contact_preferences (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    customer_id UUID,
    phone VARCHAR(50) UNIQUE NOT NULL,
    whatsapp_opt_in BOOLEAN NOT NULL DEFAULT TRUE,
    marketing_opt_in BOOLEAN NOT NULL DEFAULT TRUE,
    email_opt_in BOOLEAN NOT NULL DEFAULT TRUE,
    sms_opt_in BOOLEAN NOT NULL DEFAULT TRUE,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_crm_contact_pref_phone ON public.crm_contact_preferences(phone);
CREATE INDEX IF NOT EXISTS idx_crm_contact_pref_customer ON public.crm_contact_preferences(customer_id);

-- 9. Transactional Outbox Events Table
CREATE TABLE IF NOT EXISTS public.crm_outbox_events (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    event_type VARCHAR(100) NOT NULL,
    aggregate_type VARCHAR(100) NOT NULL,
    aggregate_id UUID,
    payload TEXT NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    attempt_count INTEGER NOT NULL DEFAULT 0,
    available_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    processed_at TIMESTAMPTZ,
    last_error TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_crm_outbox_status_avail ON public.crm_outbox_events(status, available_at);

-- 10. Tags & Lead Tags
CREATE TABLE IF NOT EXISTS public.crm_tags (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name VARCHAR(50) UNIQUE NOT NULL,
    description TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS public.crm_lead_tags (
    lead_id UUID NOT NULL REFERENCES public.crm_leads(id) ON DELETE CASCADE,
    tag_id UUID NOT NULL REFERENCES public.crm_tags(id) ON DELETE CASCADE,
    PRIMARY KEY (lead_id, tag_id)
);

-- 11. Staff Lead Assignment History
CREATE TABLE IF NOT EXISTS public.crm_assignment_history (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    lead_id UUID NOT NULL REFERENCES public.crm_leads(id) ON DELETE CASCADE,
    from_user UUID,
    to_user UUID NOT NULL,
    assigned_by UUID NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_crm_assign_hist_lead ON public.crm_assignment_history(lead_id);

-- 12. Seed default tags
INSERT INTO public.crm_tags (name, description) VALUES
    ('HOT', 'High urgency / immediate purchase intent'),
    ('URGENT', 'Immediate follow-up required'),
    ('NRI', 'Non-Resident Indian investor / buyer'),
    ('INVESTOR', 'Commercial or multi-unit investment buyer'),
    ('HOME_BUYER', 'End-user residential home buyer'),
    ('LOAN_REQUIRED', 'Customer requested home financing support'),
    ('SITE_VISIT_REQUIRED', 'Customer requested physical property walkthrough'),
    ('HIGH_VALUE', 'High budget / luxury segment lead'),
    ('FOLLOWUP_PENDING', 'Pending scheduled outreach action')
ON CONFLICT DO NOTHING;

-- 13. Seed official default WhatsApp templates
INSERT INTO public.whatsapp_templates (name, template_name, language, category, content, status, variables) VALUES
    ('lead_welcome', 'lead_welcome_v1', 'en', 'UTILITY', 'Hello {{customer_name}}, thank you for your enquiry regarding {{property_title}} on PropZen. Our property advisor will reach out shortly.', 'APPROVED', 'customer_name,property_title'),
    ('site_visit_confirmation', 'site_visit_confirm_v1', 'en', 'UTILITY', 'Dear {{customer_name}}, your site visit for {{property_title}} is confirmed for {{appointment_date}} at {{time_slot}}.', 'APPROVED', 'customer_name,property_title,appointment_date,time_slot'),
    ('service_request_update', 'service_update_v1', 'en', 'UTILITY', 'Hello {{customer_name}}, your service request #{{request_id}} for {{service_name}} is now {{status}}.', 'APPROVED', 'customer_name,request_id,service_name,status'),
    ('payment_confirmation', 'payment_confirm_v1', 'en', 'UTILITY', 'Dear {{customer_name}}, payment of INR {{amount}} for request #{{request_id}} has been received successfully.', 'APPROVED', 'customer_name,amount,request_id')
ON CONFLICT DO NOTHING;
