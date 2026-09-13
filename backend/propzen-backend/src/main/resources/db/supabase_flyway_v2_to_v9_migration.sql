-- =============================================================================
-- PROPZEN PRODUCTION DATABASE CONSOLIDATED MIGRATION: FLYWAY V2 THROUGH V9
-- =============================================================================
-- Target Database: Supabase PostgreSQL (Project eemxylswyvhsyzllcsnp)
-- Schema: public
--
-- Safety Guarantees:
-- 1. All DDL operations use IF NOT EXISTS / ADD COLUMN IF NOT EXISTS.
-- 2. Zero DROP TABLE, TRUNCATE, or destructive operations.
-- 3. Fully compatible with Hibernate ddl-auto=validate.
-- 4. Registers all migrations in flyway_schema_history for Spring Boot Flyway compatibility.
-- =============================================================================

BEGIN;

-- =============================================================================
-- 0. FLYWAY SCHEMA HISTORY TABLE INITIALIZATION
-- =============================================================================
CREATE TABLE IF NOT EXISTS public."flyway_schema_history" (
    "installed_rank" INT NOT NULL,
    "version" VARCHAR(50),
    "description" VARCHAR(200) NOT NULL,
    "type" VARCHAR(20) NOT NULL,
    "script" VARCHAR(1000) NOT NULL,
    "checksum" INT,
    "installed_by" VARCHAR(100) NOT NULL DEFAULT CURRENT_USER,
    "installed_on" TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "execution_time" INT NOT NULL DEFAULT 1,
    "success" BOOLEAN NOT NULL DEFAULT true,
    CONSTRAINT "flyway_schema_history_pk" PRIMARY KEY ("installed_rank")
);

CREATE INDEX IF NOT EXISTS "flyway_schema_history_s_idx" ON public."flyway_schema_history" ("success");

-- Baseline registration
INSERT INTO public."flyway_schema_history" 
    ("installed_rank", "version", "description", "type", "script", "checksum", "installed_by", "installed_on", "execution_time", "success")
VALUES 
    (1, '0', '<< Flyway Baseline >>', 'BASELINE', '<< Flyway Baseline >>', NULL, CURRENT_USER, CURRENT_TIMESTAMP, 0, true),
    (2, '1', 'baseline marker', 'SQL', 'V1__baseline_marker.sql', 1, CURRENT_USER, CURRENT_TIMESTAMP, 1, true)
ON CONFLICT ("installed_rank") DO NOTHING;

-- =============================================================================
-- V2: CREATE DEALER PROFILES
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.dealer_profiles (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL,
    business_name VARCHAR(255) NOT NULL,
    company_name VARCHAR(255),
    display_name VARCHAR(255),
    phone VARCHAR(50) NOT NULL,
    email VARCHAR(255) NOT NULL,
    description TEXT,
    experience_years INTEGER,
    city VARCHAR(100),
    verification_status VARCHAR(50) NOT NULL DEFAULT 'PENDING',
    status VARCHAR(50) NOT NULL DEFAULT 'PENDING',
    admin_notes TEXT,
    reviewed_by UUID,
    reviewed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_dealer_user FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE,
    CONSTRAINT uq_dealer_user UNIQUE (user_id)
);

CREATE INDEX IF NOT EXISTS idx_dealer_profiles_user_id ON public.dealer_profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_dealer_profiles_status ON public.dealer_profiles(status);
CREATE INDEX IF NOT EXISTS idx_dealer_profiles_verification_status ON public.dealer_profiles(verification_status);

INSERT INTO public."flyway_schema_history" 
    ("installed_rank", "version", "description", "type", "script", "checksum", "installed_by", "installed_on", "execution_time", "success")
VALUES 
    (3, '2', 'create dealer profiles', 'SQL', 'V2__create_dealer_profiles.sql', 2, CURRENT_USER, CURRENT_TIMESTAMP, 5, true)
ON CONFLICT ("installed_rank") DO NOTHING;

-- =============================================================================
-- V3: ENHANCE POSTED PROPERTIES
-- =============================================================================
ALTER TABLE public.posted_properties ADD COLUMN IF NOT EXISTS description TEXT;
ALTER TABLE public.posted_properties ADD COLUMN IF NOT EXISTS locality VARCHAR(255);
ALTER TABLE public.posted_properties ADD COLUMN IF NOT EXISTS dealer_id UUID;
ALTER TABLE public.posted_properties ADD COLUMN IF NOT EXISTS owner_id UUID;
ALTER TABLE public.posted_properties ADD COLUMN IF NOT EXISTS verification_status VARCHAR(50) DEFAULT 'PENDING';
ALTER TABLE public.posted_properties ADD COLUMN IF NOT EXISTS amenities TEXT;
ALTER TABLE public.posted_properties ADD COLUMN IF NOT EXISTS image_url TEXT;
ALTER TABLE public.posted_properties ADD COLUMN IF NOT EXISTS images TEXT;
ALTER TABLE public.posted_properties ADD COLUMN IF NOT EXISTS admin_note TEXT;
ALTER TABLE public.posted_properties ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP;

CREATE INDEX IF NOT EXISTS idx_posted_properties_city ON public.posted_properties(city);
CREATE INDEX IF NOT EXISTS idx_posted_properties_sector ON public.posted_properties(sector);
CREATE INDEX IF NOT EXISTS idx_posted_properties_prop_type ON public.posted_properties(property_type);
CREATE INDEX IF NOT EXISTS idx_posted_properties_bhk ON public.posted_properties(bhk);
CREATE INDEX IF NOT EXISTS idx_posted_properties_price_cr ON public.posted_properties(price_cr);
CREATE INDEX IF NOT EXISTS idx_posted_properties_sqft ON public.posted_properties(sqft);
CREATE INDEX IF NOT EXISTS idx_posted_properties_status ON public.posted_properties(status);
CREATE INDEX IF NOT EXISTS idx_posted_properties_dealer_id ON public.posted_properties(dealer_id);
CREATE INDEX IF NOT EXISTS idx_posted_properties_owner_id ON public.posted_properties(owner_id);
CREATE INDEX IF NOT EXISTS idx_posted_properties_status_city ON public.posted_properties(status, city);

INSERT INTO public."flyway_schema_history" 
    ("installed_rank", "version", "description", "type", "script", "checksum", "installed_by", "installed_on", "execution_time", "success")
VALUES 
    (4, '3', 'enhance posted properties', 'SQL', 'V3__enhance_posted_properties.sql', 3, CURRENT_USER, CURRENT_TIMESTAMP, 5, true)
ON CONFLICT ("installed_rank") DO NOTHING;

-- =============================================================================
-- V4: CRM, LEADS, ENQUIRIES, CAMPAIGNS & AUTOMATION
-- =============================================================================
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

INSERT INTO public."flyway_schema_history" 
    ("installed_rank", "version", "description", "type", "script", "checksum", "installed_by", "installed_on", "execution_time", "success")
VALUES 
    (5, '4', 'create crm schema', 'SQL', 'V4__create_crm_schema.sql', 4, CURRENT_USER, CURRENT_TIMESTAMP, 15, true)
ON CONFLICT ("installed_rank") DO NOTHING;

-- =============================================================================
-- V5: SERVICE MANAGEMENT, PARTNERS, REQUESTS & JOURNEY
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.service_categories (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    slug VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    icon VARCHAR(255),
    is_active BOOLEAN NOT NULL DEFAULT true,
    sort_order INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_service_categories_slug ON public.service_categories(slug);
CREATE INDEX IF NOT EXISTS idx_service_categories_active ON public.service_categories(is_active);

INSERT INTO public.service_categories (name, slug, description, icon, is_active, sort_order)
VALUES 
    ('Loan / Home Finance', 'loan-home-finance', 'Home loan eligibility, documentation, bank underwriting and sanction', 'account_balance', true, 1),
    ('Home Design', 'home-design', 'Interior architecture, 2D floor plans, 3D photorealistic renderings and turnkey styling', 'palette', true, 2),
    ('Vastu Consultation', 'vastu-consultation', 'Directional energy analysis, plot evaluation, and non-demolition remedial solutions', 'compass_calibration', true, 3),
    ('Construction', 'construction', 'Turnkey civil construction, site assessment, structural BOQ, and milestone inspection', 'handyman', true, 4),
    ('Property Verification', 'property-verification', 'Title deed search, 30-year ownership verification, RERA legal audit, and encumbrance certificates', 'verified', true, 5),
    ('Virtual & 3D Visualization', 'virtual-3d-visualization', 'Interactive 360 virtual tours, high-fidelity WebXR walkthroughs, and 4K aerial drone mapping', 'view_in_ar', true, 6)
ON CONFLICT DO NOTHING;

CREATE TABLE IF NOT EXISTS public.service_partner_profiles (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL UNIQUE,
    business_name VARCHAR(255) NOT NULL,
    company_name VARCHAR(255),
    display_name VARCHAR(255),
    phone VARCHAR(50),
    email VARCHAR(255),
    description TEXT,
    experience_years INTEGER DEFAULT 0,
    city VARCHAR(100),
    service_area VARCHAR(255),
    profile_image_url VARCHAR(500),
    service_category_id UUID REFERENCES public.service_categories(id),
    service_categories TEXT,
    verification_status VARCHAR(50) NOT NULL DEFAULT 'PENDING',
    partner_status VARCHAR(50) NOT NULL DEFAULT 'PENDING',
    rating NUMERIC(3, 2) DEFAULT 5.00,
    total_completed_services INTEGER DEFAULT 0,
    total_active_services INTEGER DEFAULT 0,
    admin_notes TEXT,
    reviewed_by UUID,
    reviewed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_sp_profiles_user_id ON public.service_partner_profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_sp_profiles_status ON public.service_partner_profiles(partner_status);
CREATE INDEX IF NOT EXISTS idx_sp_profiles_verification ON public.service_partner_profiles(verification_status);
CREATE INDEX IF NOT EXISTS idx_sp_profiles_city ON public.service_partner_profiles(city);
CREATE INDEX IF NOT EXISTS idx_sp_profiles_category ON public.service_partner_profiles(service_category_id);

CREATE TABLE IF NOT EXISTS public.service_requests (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    service_number VARCHAR(50) UNIQUE NOT NULL,
    customer_id UUID NOT NULL,
    partner_id UUID REFERENCES public.service_partner_profiles(id),
    service_category_id UUID NOT NULL REFERENCES public.service_categories(id),
    property_id VARCHAR(255),
    title VARCHAR(255) NOT NULL,
    description TEXT,
    location VARCHAR(255),
    budget NUMERIC(14, 2),
    preferred_date TIMESTAMPTZ,
    preferred_time VARCHAR(50),
    priority VARCHAR(50) NOT NULL DEFAULT 'MEDIUM',
    status VARCHAR(50) NOT NULL DEFAULT 'NEW',
    assigned_at TIMESTAMPTZ,
    started_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    cancelled_at TIMESTAMPTZ,
    rejection_reason TEXT,
    cancellation_reason TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_sr_customer_id ON public.service_requests(customer_id);
CREATE INDEX IF NOT EXISTS idx_sr_partner_id ON public.service_requests(partner_id);
CREATE INDEX IF NOT EXISTS idx_sr_category_id ON public.service_requests(service_category_id);
CREATE INDEX IF NOT EXISTS idx_sr_status ON public.service_requests(status);
CREATE INDEX IF NOT EXISTS idx_sr_created_at ON public.service_requests(created_at);

CREATE TABLE IF NOT EXISTS public.service_request_assignments (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    service_request_id UUID NOT NULL REFERENCES public.service_requests(id) ON DELETE CASCADE,
    partner_id UUID NOT NULL REFERENCES public.service_partner_profiles(id),
    assigned_by UUID,
    assignment_status VARCHAR(50) NOT NULL DEFAULT 'RECOMMENDED',
    assignment_score NUMERIC(5, 2) DEFAULT 0.00,
    assigned_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    accepted_at TIMESTAMPTZ,
    rejected_at TIMESTAMPTZ,
    notes TEXT
);

CREATE INDEX IF NOT EXISTS idx_sr_assign_request ON public.service_request_assignments(service_request_id);
CREATE INDEX IF NOT EXISTS idx_sr_assign_partner ON public.service_request_assignments(partner_id);
CREATE INDEX IF NOT EXISTS idx_sr_assign_status ON public.service_request_assignments(assignment_status);

CREATE TABLE IF NOT EXISTS public.service_journey_events (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    service_request_id UUID NOT NULL REFERENCES public.service_requests(id) ON DELETE CASCADE,
    event_type VARCHAR(100) NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    created_by UUID,
    metadata TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_sr_journey_request ON public.service_journey_events(service_request_id);
CREATE INDEX IF NOT EXISTS idx_sr_journey_created_at ON public.service_journey_events(created_at);

CREATE TABLE IF NOT EXISTS public.service_documents (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    service_request_id UUID NOT NULL REFERENCES public.service_requests(id) ON DELETE CASCADE,
    uploaded_by UUID NOT NULL,
    document_type VARCHAR(100) NOT NULL,
    file_name VARCHAR(255) NOT NULL,
    storage_path VARCHAR(500),
    file_url VARCHAR(500) NOT NULL,
    mime_type VARCHAR(100),
    file_size BIGINT,
    verification_status VARCHAR(50) NOT NULL DEFAULT 'UPLOADED',
    uploaded_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    verified_at TIMESTAMPTZ,
    verified_by UUID,
    rejection_reason TEXT
);

CREATE INDEX IF NOT EXISTS idx_sr_docs_request ON public.service_documents(service_request_id);
CREATE INDEX IF NOT EXISTS idx_sr_docs_uploaded_by ON public.service_documents(uploaded_by);
CREATE INDEX IF NOT EXISTS idx_sr_docs_status ON public.service_documents(verification_status);

CREATE TABLE IF NOT EXISTS public.service_milestones (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    service_request_id UUID NOT NULL REFERENCES public.service_requests(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    sequence_number INTEGER NOT NULL DEFAULT 0,
    amount NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
    status VARCHAR(50) NOT NULL DEFAULT 'PENDING',
    due_date TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_sr_milestones_request ON public.service_milestones(service_request_id);
CREATE INDEX IF NOT EXISTS idx_sr_milestones_status ON public.service_milestones(status);

CREATE TABLE IF NOT EXISTS public.service_payments (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    service_request_id UUID NOT NULL REFERENCES public.service_requests(id) ON DELETE CASCADE,
    milestone_id UUID REFERENCES public.service_milestones(id),
    customer_id UUID NOT NULL,
    partner_id UUID,
    amount NUMERIC(12, 2) NOT NULL,
    currency VARCHAR(10) NOT NULL DEFAULT 'INR',
    payment_provider VARCHAR(50) NOT NULL DEFAULT 'RAZORPAY',
    provider_payment_id VARCHAR(255),
    provider_order_id VARCHAR(255),
    status VARCHAR(50) NOT NULL DEFAULT 'PENDING',
    paid_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_sr_payments_request ON public.service_payments(service_request_id);
CREATE INDEX IF NOT EXISTS idx_sr_payments_customer ON public.service_payments(customer_id);
CREATE INDEX IF NOT EXISTS idx_sr_payments_partner ON public.service_payments(partner_id);
CREATE INDEX IF NOT EXISTS idx_sr_payments_status ON public.service_payments(status);

CREATE TABLE IF NOT EXISTS public.service_feedback (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    service_request_id UUID NOT NULL UNIQUE REFERENCES public.service_requests(id) ON DELETE CASCADE,
    customer_id UUID NOT NULL,
    partner_id UUID NOT NULL REFERENCES public.service_partner_profiles(id),
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
    comment TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_sr_feedback_partner ON public.service_feedback(partner_id);
CREATE INDEX IF NOT EXISTS idx_sr_feedback_customer ON public.service_feedback(customer_id);

CREATE TABLE IF NOT EXISTS public.service_customer_notes (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    customer_id UUID NOT NULL,
    partner_id UUID REFERENCES public.service_partner_profiles(id),
    service_request_id UUID,
    note TEXT NOT NULL,
    tags VARCHAR(255),
    next_followup_at TIMESTAMPTZ,
    created_by UUID NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_sr_notes_customer ON public.service_customer_notes(customer_id);
CREATE INDEX IF NOT EXISTS idx_sr_notes_partner ON public.service_customer_notes(partner_id);

INSERT INTO public."flyway_schema_history" 
    ("installed_rank", "version", "description", "type", "script", "checksum", "installed_by", "installed_on", "execution_time", "success")
VALUES 
    (6, '5', 'create service management schema', 'SQL', 'V5__create_service_management_schema.sql', 5, CURRENT_USER, CURRENT_TIMESTAMP, 25, true)
ON CONFLICT ("installed_rank") DO NOTHING;

-- =============================================================================
-- V6: CENTRALIZED CRM, AUTOMATION & NOTIFICATIONS
-- =============================================================================
ALTER TABLE public.crm_leads ADD COLUMN IF NOT EXISTS stage VARCHAR(50) NOT NULL DEFAULT 'NEW_LEAD';
ALTER TABLE public.crm_leads ADD COLUMN IF NOT EXISTS lead_type VARCHAR(50) DEFAULT 'BUYER';
ALTER TABLE public.crm_leads ADD COLUMN IF NOT EXISTS notes TEXT;

CREATE INDEX IF NOT EXISTS idx_crm_leads_stage ON public.crm_leads(stage);
CREATE INDEX IF NOT EXISTS idx_crm_leads_lead_type ON public.crm_leads(lead_type);

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

CREATE TABLE IF NOT EXISTS public.crm_assignment_history (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    lead_id UUID NOT NULL REFERENCES public.crm_leads(id) ON DELETE CASCADE,
    from_user UUID,
    to_user UUID NOT NULL,
    assigned_by UUID NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_crm_assign_hist_lead ON public.crm_assignment_history(lead_id);

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

INSERT INTO public.whatsapp_templates (name, template_name, language, category, content, status, variables) VALUES
    ('lead_welcome', 'lead_welcome_v1', 'en', 'UTILITY', 'Hello {{customer_name}}, thank you for your enquiry regarding {{property_title}} on PropZen. Our property advisor will reach out shortly.', 'APPROVED', 'customer_name,property_title'),
    ('site_visit_confirmation', 'site_visit_confirm_v1', 'en', 'UTILITY', 'Dear {{customer_name}}, your site visit for {{property_title}} is confirmed for {{appointment_date}} at {{time_slot}}.', 'APPROVED', 'customer_name,property_title,appointment_date,time_slot'),
    ('service_request_update', 'service_update_v1', 'en', 'UTILITY', 'Hello {{customer_name}}, your service request #{{request_id}} for {{service_name}} is now {{status}}.', 'APPROVED', 'customer_name,request_id,service_name,status'),
    ('payment_confirmation', 'payment_confirm_v1', 'en', 'UTILITY', 'Dear {{customer_name}}, payment of INR {{amount}} for request #{{request_id}} has been received successfully.', 'APPROVED', 'customer_name,amount,request_id')
ON CONFLICT DO NOTHING;

INSERT INTO public."flyway_schema_history" 
    ("installed_rank", "version", "description", "type", "script", "checksum", "installed_by", "installed_on", "execution_time", "success")
VALUES 
    (7, '6', 'create centralized crm automation schema', 'SQL', 'V6__create_centralized_crm_automation_schema.sql', 6, CURRENT_USER, CURRENT_TIMESTAMP, 25, true)
ON CONFLICT ("installed_rank") DO NOTHING;

-- =============================================================================
-- V7: PRODUCTION HARDENING, AUDIT LOGS, NOTIFICATIONS & INDEXES
-- =============================================================================
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

ALTER TABLE public.crm_contact_preferences ADD COLUMN IF NOT EXISTS whatsapp_opt_in_at TIMESTAMPTZ;
ALTER TABLE public.crm_contact_preferences ADD COLUMN IF NOT EXISTS whatsapp_opt_out_at TIMESTAMPTZ;
ALTER TABLE public.crm_contact_preferences ADD COLUMN IF NOT EXISTS communication_preference VARCHAR(50) DEFAULT 'ALL';

ALTER TABLE public.crm_leads
    ADD COLUMN IF NOT EXISTS property_title VARCHAR(255);

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

INSERT INTO public."flyway_schema_history" 
    ("installed_rank", "version", "description", "type", "script", "checksum", "installed_by", "installed_on", "execution_time", "success")
VALUES 
    (8, '7', 'production hardening and indexes', 'SQL', 'V7__production_hardening_and_indexes.sql', 7, CURRENT_USER, CURRENT_TIMESTAMP, 15, true)
ON CONFLICT ("installed_rank") DO NOTHING;

-- =============================================================================
-- V8: AI INTELLIGENCE & USAGE LOGS
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.ai_usage_logs (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    request_id VARCHAR(100) NOT NULL,
    user_id UUID,
    operation VARCHAR(100) NOT NULL,
    provider VARCHAR(50) NOT NULL,
    model VARCHAR(100),
    tokens_used INTEGER DEFAULT 0,
    latency_ms BIGINT NOT NULL,
    status VARCHAR(50) NOT NULL,
    fallback_used BOOLEAN NOT NULL DEFAULT FALSE,
    error_message TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_ai_usage_user_op ON public.ai_usage_logs (user_id, operation);
CREATE INDEX IF NOT EXISTS idx_ai_usage_created ON public.ai_usage_logs (created_at DESC);
CREATE INDEX IF NOT EXISTS idx_ai_usage_status ON public.ai_usage_logs (status);

CREATE TABLE IF NOT EXISTS public.ai_enquiry_classifications (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    enquiry_id UUID NOT NULL,
    category VARCHAR(100) NOT NULL,
    priority VARCHAR(50) NOT NULL,
    sentiment VARCHAR(50),
    suggested_department VARCHAR(100),
    suggested_action TEXT,
    confidence DOUBLE PRECISION,
    classified_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_ai_enquiry_class_enquiry ON public.ai_enquiry_classifications (enquiry_id);

CREATE TABLE IF NOT EXISTS public.ai_lead_scores (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    lead_id UUID NOT NULL,
    score INTEGER NOT NULL,
    classification VARCHAR(50) NOT NULL,
    reasons TEXT,
    next_action VARCHAR(255),
    confidence DOUBLE PRECISION,
    scored_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_ai_lead_scores_lead ON public.ai_lead_scores (lead_id);

INSERT INTO public."flyway_schema_history" 
    ("installed_rank", "version", "description", "type", "script", "checksum", "installed_by", "installed_on", "execution_time", "success")
VALUES 
    (9, '8', 'create ai intelligence schema', 'SQL', 'V8__create_ai_intelligence_schema.sql', 8, CURRENT_USER, CURRENT_TIMESTAMP, 10, true)
ON CONFLICT ("installed_rank") DO NOTHING;

-- =============================================================================
-- V9: AI PROPERTY VERIFICATION WORKSPACE
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.property_verification_cases (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    case_number VARCHAR(50) UNIQUE NOT NULL,
    property_id VARCHAR(255),
    property_title VARCHAR(255) NOT NULL,
    property_type VARCHAR(100) NOT NULL,
    address TEXT NOT NULL,
    city VARCHAR(100) NOT NULL,
    sector_locality VARCHAR(100),
    khasra_number VARCHAR(100),
    plot_number VARCHAR(100),
    area VARCHAR(100),
    owner_name VARCHAR(255) NOT NULL,
    registration_number VARCHAR(100),
    registration_date VARCHAR(50),
    submitted_by UUID,
    submitted_by_name VARCHAR(255),
    status VARCHAR(50) NOT NULL DEFAULT 'PENDING',
    risk_level VARCHAR(50) NOT NULL DEFAULT 'UNKNOWN',
    risk_score INTEGER,
    extracted_data TEXT,
    consistency_checks TEXT,
    risk_checks TEXT,
    findings TEXT,
    audit_trail TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_pvc_status ON public.property_verification_cases(status);
CREATE INDEX IF NOT EXISTS idx_pvc_risk ON public.property_verification_cases(risk_level);
CREATE INDEX IF NOT EXISTS idx_pvc_city ON public.property_verification_cases(city);
CREATE INDEX IF NOT EXISTS idx_pvc_owner ON public.property_verification_cases(owner_name);
CREATE INDEX IF NOT EXISTS idx_pvc_created_at ON public.property_verification_cases(created_at);

CREATE TABLE IF NOT EXISTS public.property_verification_documents (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    case_id UUID NOT NULL REFERENCES public.property_verification_cases(id) ON DELETE CASCADE,
    file_name VARCHAR(255) NOT NULL,
    document_type VARCHAR(100) NOT NULL,
    file_size BIGINT NOT NULL DEFAULT 0,
    file_url VARCHAR(500),
    mime_type VARCHAR(100),
    upload_status VARCHAR(50) NOT NULL DEFAULT 'UPLOADED',
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_pvd_case_id ON public.property_verification_documents(case_id);
CREATE INDEX IF NOT EXISTS idx_pvd_doc_type ON public.property_verification_documents(document_type);

INSERT INTO public."flyway_schema_history" 
    ("installed_rank", "version", "description", "type", "script", "checksum", "installed_by", "installed_on", "execution_time", "success")
VALUES 
    (10, '9', 'create property verification schema', 'SQL', 'V9__create_property_verification_schema.sql', 9, CURRENT_USER, CURRENT_TIMESTAMP, 10, true)
ON CONFLICT ("installed_rank") DO NOTHING;

COMMIT;
