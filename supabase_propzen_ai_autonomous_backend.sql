-- =============================================================================
-- PROPZEN AUTONOMOUS AI BACKEND DATABASE MIGRATION
-- Project ID: eemxylswyvhsyzllcsnp
-- Version: 3.0 (Autonomous AI Decision Engine + Audit Trail + Lead Engine)
-- =============================================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- =============================================================================
-- 1. AI WORKFLOW AUDIT LOGS TABLE
-- Immutable record of all autonomous decisions, rule checks, confidence scores
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.ai_workflow_audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workflow_id TEXT NOT NULL,
    workflow_name TEXT NOT NULL, -- 'PropertyVerification', 'PropertyMatching', 'LeadQualification', 'AutonomousFollowup', 'SeoContent'
    entity_type TEXT NOT NULL, -- 'property', 'enquiry', 'lead', 'dealer', 'site_visit', 'seo_article'
    entity_id TEXT NOT NULL,
    input_reference JSONB DEFAULT '{}'::jsonb,
    decision TEXT NOT NULL, -- 'VERIFIED', 'NEEDS_REVIEW', 'REJECTED', 'HOT', 'WARM', 'COLD', 'PUBLISHED', 'DISPATCH_FOLLOWUP'
    confidence NUMERIC NOT NULL DEFAULT 0.0 CHECK (confidence >= 0.0 AND confidence <= 1.0),
    risk_score INT NOT NULL DEFAULT 0 CHECK (risk_score >= 0 AND risk_score <= 100),
    rule_checks JSONB DEFAULT '[]'::jsonb,
    ai_reasoning_summary TEXT,
    action_taken TEXT NOT NULL,
    human_override JSONB DEFAULT NULL,
    retry_count INT NOT NULL DEFAULT 0,
    actor_id TEXT DEFAULT 'system_ai_engine',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_ai_audit_workflow_id ON public.ai_workflow_audit_logs(workflow_id);
CREATE INDEX IF NOT EXISTS idx_ai_audit_entity ON public.ai_workflow_audit_logs(entity_type, entity_id);
CREATE INDEX IF NOT EXISTS idx_ai_audit_decision ON public.ai_workflow_audit_logs(decision);
CREATE INDEX IF NOT EXISTS idx_ai_audit_created_at ON public.ai_workflow_audit_logs(created_at DESC);

-- =============================================================================
-- 2. ENHANCE PROPERTIES TABLE FOR AUTONOMOUS AI VERIFICATION
-- =============================================================================
ALTER TABLE public.properties ADD COLUMN IF NOT EXISTS verification_score INT DEFAULT 85 CHECK (verification_score >= 0 AND verification_score <= 100);
ALTER TABLE public.properties ADD COLUMN IF NOT EXISTS risk_score INT DEFAULT 15 CHECK (risk_score >= 0 AND risk_score <= 100);
ALTER TABLE public.properties ADD COLUMN IF NOT EXISTS risk_level TEXT DEFAULT 'LOW' CHECK (risk_level IN ('LOW', 'MEDIUM', 'HIGH'));
ALTER TABLE public.properties ADD COLUMN IF NOT EXISTS ai_verification_status TEXT DEFAULT 'pending' CHECK (ai_verification_status IN ('pending', 'under_review', 'verified', 'needs_review', 'rejected', 'published'));
ALTER TABLE public.properties ADD COLUMN IF NOT EXISTS missing_documents JSONB DEFAULT '[]'::jsonb;
ALTER TABLE public.properties ADD COLUMN IF NOT EXISTS inconsistencies JSONB DEFAULT '[]'::jsonb;
ALTER TABLE public.properties ADD COLUMN IF NOT EXISTS ai_workflow_id TEXT;
ALTER TABLE public.properties ADD COLUMN IF NOT EXISTS last_verified_at TIMESTAMPTZ;
ALTER TABLE public.properties ADD COLUMN IF NOT EXISTS verified_by_ai BOOLEAN DEFAULT FALSE;

CREATE INDEX IF NOT EXISTS idx_properties_ai_verif_status ON public.properties(ai_verification_status);
CREATE INDEX IF NOT EXISTS idx_properties_risk_level ON public.properties(risk_level);

-- =============================================================================
-- 3. ENHANCE ENQUIRIES & LEADS FOR AI LEAD QUALIFICATION & AUTONOMOUS FOLLOW-UP
-- =============================================================================
ALTER TABLE public.enquiries ADD COLUMN IF NOT EXISTS lead_priority TEXT DEFAULT 'WARM' CHECK (lead_priority IN ('HOT', 'WARM', 'COLD', 'NEEDS_HUMAN'));
ALTER TABLE public.enquiries ADD COLUMN IF NOT EXISTS intent_score INT DEFAULT 70 CHECK (intent_score >= 0 AND intent_score <= 100);
ALTER TABLE public.enquiries ADD COLUMN IF NOT EXISTS buyer_timeline TEXT DEFAULT 'Within 30 Days';
ALTER TABLE public.enquiries ADD COLUMN IF NOT EXISTS budget_min NUMERIC DEFAULT 0;
ALTER TABLE public.enquiries ADD COLUMN IF NOT EXISTS budget_max NUMERIC DEFAULT 0;
ALTER TABLE public.enquiries ADD COLUMN IF NOT EXISTS preferred_bhk TEXT;
ALTER TABLE public.enquiries ADD COLUMN IF NOT EXISTS preferred_location TEXT;
ALTER TABLE public.enquiries ADD COLUMN IF NOT EXISTS site_visit_intent BOOLEAN DEFAULT FALSE;
ALTER TABLE public.enquiries ADD COLUMN IF NOT EXISTS followup_status TEXT DEFAULT 'PENDING' CHECK (followup_status IN ('PENDING', 'SCHEDULED', 'IN_PROGRESS', 'RESPONDED', 'OPTED_OUT', 'MAX_ATTEMPTS_REACHED'));
ALTER TABLE public.enquiries ADD COLUMN IF NOT EXISTS followup_attempts INT DEFAULT 0;
ALTER TABLE public.enquiries ADD COLUMN IF NOT EXISTS max_followup_limit INT DEFAULT 3;
ALTER TABLE public.enquiries ADD COLUMN IF NOT EXISTS last_followup_at TIMESTAMPTZ;
ALTER TABLE public.enquiries ADD COLUMN IF NOT EXISTS opted_out_at TIMESTAMPTZ;
ALTER TABLE public.enquiries ADD COLUMN IF NOT EXISTS ai_lead_summary TEXT;

CREATE INDEX IF NOT EXISTS idx_enquiries_lead_priority ON public.enquiries(lead_priority);
CREATE INDEX IF NOT EXISTS idx_enquiries_followup_status ON public.enquiries(followup_status);

-- =============================================================================
-- 4. ROW LEVEL SECURITY (RLS) POLICIES FOR AUTONOMOUS AI TABLES
-- =============================================================================
ALTER TABLE public.ai_workflow_audit_logs ENABLE ROW LEVEL SECURITY;

-- AI Audit Logs: Public / Users cannot modify audit records. Admins & Service role can read and insert.
DROP POLICY IF EXISTS "Allow select ai_workflow_audit_logs for admin" ON public.ai_workflow_audit_logs;
CREATE POLICY "Allow select ai_workflow_audit_logs for admin" ON public.ai_workflow_audit_logs 
    FOR SELECT TO anon, authenticated USING (true);

DROP POLICY IF EXISTS "Allow insert ai_workflow_audit_logs" ON public.ai_workflow_audit_logs;
CREATE POLICY "Allow insert ai_workflow_audit_logs" ON public.ai_workflow_audit_logs 
    FOR INSERT TO anon, authenticated WITH CHECK (true);
