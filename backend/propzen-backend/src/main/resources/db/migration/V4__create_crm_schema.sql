-- =============================================================================
-- PROPZEN FLYWAY MIGRATION V4: CRM, LEADS, ENQUIRIES, CAMPAIGNS & AUTOMATION
-- =============================================================================
-- Target Database: Supabase PostgreSQL (Project eemxylswyvhsyzllcsnp)
--
-- Safely creates CRM tables and enhances existing enquiries & site_visits
-- =============================================================================

-- 1. Safely enhance existing enquiries and site_visits tables
ALTER TABLE public.enquiries ADD COLUMN IF NOT EXISTS user_id UUID;
ALTER TABLE public.enquiries ADD COLUMN IF NOT EXISTS dealer_id UUID;
ALTER TABLE public.enquiries ADD COLUMN IF NOT EXISTS enquiry_type VARCHAR(50);
ALTER TABLE public.enquiries ADD COLUMN IF NOT EXISTS property_title VARCHAR(255);
ALTER TABLE public.enquiries ADD COLUMN IF NOT EXISTS user_name VARCHAR(255);
ALTER TABLE public.enquiries ADD COLUMN IF NOT EXISTS user_email VARCHAR(255);
ALTER TABLE public.enquiries ADD COLUMN IF NOT EXISTS user_phone VARCHAR(50);
ALTER TABLE public.enquiries ADD COLUMN IF NOT EXISTS metadata TEXT;

ALTER TABLE public.site_visits ADD COLUMN IF NOT EXISTS user_id UUID;
ALTER TABLE public.site_visits ADD COLUMN IF NOT EXISTS dealer_id UUID;

-- 2. CRM Leads Table
CREATE TABLE IF NOT EXISTS public.crm_leads (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    lead_number VARCHAR(50) UNIQUE NOT NULL,
    user_id UUID,
    property_id VARCHAR(255),
    dealer_id UUID,
    assigned_to UUID,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255),
    phone VARCHAR(50) NOT NULL,
    message TEXT,
    source VARCHAR(50) NOT NULL DEFAULT 'PROPERTY_ENQUIRY',
    status VARCHAR(50) NOT NULL DEFAULT 'NEW',
    priority VARCHAR(50) NOT NULL DEFAULT 'MEDIUM',
    lead_score INTEGER NOT NULL DEFAULT 50,
    budget_min NUMERIC(12, 4),
    budget_max NUMERIC(12, 4),
    preferred_city VARCHAR(100),
    preferred_sector VARCHAR(100),
    preferred_property_type VARCHAR(100),
    preferred_bhk VARCHAR(50),
    next_follow_up_at TIMESTAMPTZ,
    last_contacted_at TIMESTAMPTZ,
    converted_at TIMESTAMPTZ,
    lost_at TIMESTAMPTZ,
    lost_reason TEXT,
    metadata TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_crm_leads_status ON public.crm_leads(status);
CREATE INDEX IF NOT EXISTS idx_crm_leads_assigned_to ON public.crm_leads(assigned_to);
CREATE INDEX IF NOT EXISTS idx_crm_leads_dealer_id ON public.crm_leads(dealer_id);
CREATE INDEX IF NOT EXISTS idx_crm_leads_user_id ON public.crm_leads(user_id);
CREATE INDEX IF NOT EXISTS idx_crm_leads_phone ON public.crm_leads(phone);
CREATE INDEX IF NOT EXISTS idx_crm_leads_email ON public.crm_leads(email);
CREATE INDEX IF NOT EXISTS idx_crm_leads_created_at ON public.crm_leads(created_at);
CREATE INDEX IF NOT EXISTS idx_crm_leads_next_follow_up ON public.crm_leads(next_follow_up_at);

-- 3. CRM Lead Activities & Follow-ups Table
CREATE TABLE IF NOT EXISTS public.crm_lead_activities (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    lead_id UUID NOT NULL REFERENCES public.crm_leads(id) ON DELETE CASCADE,
    actor_user_id UUID,
    type VARCHAR(50) NOT NULL,
    note TEXT NOT NULL,
    scheduled_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    metadata TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_crm_lead_activities_lead_id ON public.crm_lead_activities(lead_id);
CREATE INDEX IF NOT EXISTS idx_crm_lead_activities_type ON public.crm_lead_activities(type);
CREATE INDEX IF NOT EXISTS idx_crm_lead_activities_scheduled_at ON public.crm_lead_activities(scheduled_at);

-- 4. CRM Message Templates Table
CREATE TABLE IF NOT EXISTS public.crm_message_templates (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL,
    event_type VARCHAR(50) NOT NULL,
    channel VARCHAR(20) NOT NULL DEFAULT 'WHATSAPP',
    language VARCHAR(10) NOT NULL DEFAULT 'en',
    template_identifier VARCHAR(100) NOT NULL,
    body_text TEXT NOT NULL,
    variables TEXT,
    enabled BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_crm_msg_templates_event_type ON public.crm_message_templates(event_type);

-- 5. CRM Campaigns Table
CREATE TABLE IF NOT EXISTS public.crm_campaigns (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    type VARCHAR(50) NOT NULL DEFAULT 'PROMOTIONAL',
    channel VARCHAR(20) NOT NULL DEFAULT 'WHATSAPP',
    status VARCHAR(50) NOT NULL DEFAULT 'DRAFT',
    template_id UUID REFERENCES public.crm_message_templates(id),
    created_by UUID,
    scheduled_at TIMESTAMPTZ,
    started_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    total_recipients INTEGER NOT NULL DEFAULT 0,
    sent_count INTEGER NOT NULL DEFAULT 0,
    delivered_count INTEGER NOT NULL DEFAULT 0,
    read_count INTEGER NOT NULL DEFAULT 0,
    failed_count INTEGER NOT NULL DEFAULT 0,
    metadata TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_crm_campaigns_status ON public.crm_campaigns(status);

-- 6. CRM Campaign Recipients Table
CREATE TABLE IF NOT EXISTS public.crm_campaign_recipients (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    campaign_id UUID NOT NULL REFERENCES public.crm_campaigns(id) ON DELETE CASCADE,
    lead_id UUID REFERENCES public.crm_leads(id),
    phone VARCHAR(50) NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'PENDING',
    idempotency_key VARCHAR(255) UNIQUE,
    provider_message_id VARCHAR(255),
    failure_reason TEXT,
    sent_at TIMESTAMPTZ,
    delivered_at TIMESTAMPTZ,
    read_at TIMESTAMPTZ,
    failed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_crm_camp_recip_camp_status ON public.crm_campaign_recipients(campaign_id, status);
CREATE INDEX IF NOT EXISTS idx_crm_camp_recip_idempotency ON public.crm_campaign_recipients(idempotency_key);

-- 7. CRM Automation Rules Table
CREATE TABLE IF NOT EXISTS public.crm_automation_rules (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    event_type VARCHAR(50) NOT NULL,
    action_type VARCHAR(50) NOT NULL,
    template_id UUID REFERENCES public.crm_message_templates(id),
    conditions TEXT,
    enabled BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_crm_auto_rules_event ON public.crm_automation_rules(event_type);

-- 8. CRM Automation Executions Table
CREATE TABLE IF NOT EXISTS public.crm_automation_executions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    rule_id UUID REFERENCES public.crm_automation_rules(id) ON DELETE SET NULL,
    event_type VARCHAR(50) NOT NULL,
    lead_id UUID,
    status VARCHAR(50) NOT NULL DEFAULT 'SUCCESS',
    result TEXT,
    executed_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_crm_auto_exec_rule ON public.crm_automation_executions(rule_id);

-- 9. CRM Communication Preferences Table (Consent & Opt-out)
CREATE TABLE IF NOT EXISTS public.crm_communication_preferences (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID,
    phone VARCHAR(50) UNIQUE NOT NULL,
    whatsapp_opt_in BOOLEAN NOT NULL DEFAULT TRUE,
    email_opt_in BOOLEAN NOT NULL DEFAULT TRUE,
    sms_opt_in BOOLEAN NOT NULL DEFAULT TRUE,
    marketing_opt_in BOOLEAN NOT NULL DEFAULT TRUE,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_crm_comm_pref_phone ON public.crm_communication_preferences(phone);
CREATE INDEX IF NOT EXISTS idx_crm_comm_pref_user ON public.crm_communication_preferences(user_id);
