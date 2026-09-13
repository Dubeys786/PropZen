-- =============================================================================
-- PROPZEN GLOBAL VERIFICATION ENGINE - SUPABASE POSTGRESQL SCHEMA
-- =============================================================================
-- Author: PropZen Engineering Team
-- Purpose: Schema for AI-Assisted Real Estate Document Verification Backend
-- =============================================================================

-- Enable pgcrypto for UUID generation
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- 1. Verification Cases Table
CREATE TABLE IF NOT EXISTS public.verification_cases (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id TEXT NOT NULL DEFAULT 'anonymous_user',
    property_id TEXT,
    document_type TEXT NOT NULL DEFAULT 'GENERIC_PROPERTY_DOCUMENT',
    status TEXT NOT NULL DEFAULT 'PENDING', 
    -- Statuses: 'PENDING', 'PASS', 'REVIEW_REQUIRED', 'HIGH_RISK', 'INSUFFICIENT_DATA'
    risk_score INTEGER DEFAULT 0 CHECK (risk_score >= 0 AND risk_score <= 100),
    risk_level TEXT DEFAULT 'LOW', 
    -- Risk Levels: 'LOW', 'MEDIUM', 'HIGH', 'CRITICAL'
    recommended_action TEXT DEFAULT 'Manual/legal verification recommended upon document upload.',
    disclaimer TEXT NOT NULL DEFAULT 'AI-assisted analysis. This result does not constitute legal title certification.',
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Verification Documents Table
CREATE TABLE IF NOT EXISTS public.verification_documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    case_id UUID NOT NULL REFERENCES public.verification_cases(id) ON DELETE CASCADE,
    file_name TEXT NOT NULL,
    document_type TEXT NOT NULL, 
    -- Document Types: 'SALE_DEED', 'REGISTRY_DOCUMENT', 'KHATAUNI_LAND_RECORD',
    -- 'PROPERTY_TAX_DOCUMENT', 'ENCUMBRANCE_CERTIFICATE', 'ALLOTMENT_LETTER',
    -- 'POSSESSION_LETTER', 'GENERIC_PROPERTY_DOCUMENT'
    storage_path TEXT NOT NULL,
    mime_type TEXT DEFAULT 'application/pdf',
    file_size_bytes BIGINT DEFAULT 0,
    page_count INTEGER DEFAULT 1,
    checksum_sha256 TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Extracted Fields Table
CREATE TABLE IF NOT EXISTS public.extracted_fields (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    case_id UUID NOT NULL REFERENCES public.verification_cases(id) ON DELETE CASCADE,
    document_id UUID REFERENCES public.verification_documents(id) ON DELETE CASCADE,
    field_name TEXT NOT NULL,
    field_value TEXT,
    confidence NUMERIC(4, 3) DEFAULT 0.950 CHECK (confidence >= 0.000 AND confidence <= 1.000),
    source_page INTEGER DEFAULT 1,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. Verification Findings Table
CREATE TABLE IF NOT EXISTS public.verification_findings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    case_id UUID NOT NULL REFERENCES public.verification_cases(id) ON DELETE CASCADE,
    finding_type TEXT NOT NULL,
    -- Types: 'FIELD_MISMATCH', 'INVALID_DATE_RELATIONSHIP', 'INVALID_NUMERIC_VALUE',
    -- 'SUSPICIOUS_NAME_VARIATION', 'MISSING_CRITICAL_FIELD', 'OCR_UNCERTAINTY',
    -- 'UNSUPPORTED_FORMAT', 'DUPLICATE_RECORD'
    severity TEXT NOT NULL DEFAULT 'MEDIUM',
    -- Severities: 'LOW', 'MEDIUM', 'HIGH', 'CRITICAL'
    field TEXT,
    description TEXT NOT NULL,
    evidence JSONB DEFAULT '{}'::jsonb,
    recommended_action TEXT DEFAULT 'Manual verification required.',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. Verification Audit Logs Table
CREATE TABLE IF NOT EXISTS public.verification_audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    case_id UUID REFERENCES public.verification_cases(id) ON DELETE CASCADE,
    action TEXT NOT NULL, 
    -- Actions: 'CASE_CREATED', 'DOCUMENT_UPLOADED', 'ANALYSIS_STARTED',
    -- 'ANALYSIS_COMPLETED', 'REPORT_VIEWED'
    actor TEXT NOT NULL DEFAULT 'system',
    details JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for high-performance querying
CREATE INDEX IF NOT EXISTS idx_verification_cases_user_id ON public.verification_cases(user_id);
CREATE INDEX IF NOT EXISTS idx_verification_cases_status ON public.verification_cases(status);
CREATE INDEX IF NOT EXISTS idx_verification_documents_case_id ON public.verification_documents(case_id);
CREATE INDEX IF NOT EXISTS idx_extracted_fields_case_id ON public.extracted_fields(case_id);
CREATE INDEX IF NOT EXISTS idx_extracted_fields_name ON public.extracted_fields(field_name);
CREATE INDEX IF NOT EXISTS idx_verification_findings_case_id ON public.verification_findings(case_id);
CREATE INDEX IF NOT EXISTS idx_verification_audit_logs_case_id ON public.verification_audit_logs(case_id);

-- Auto-update updated_at trigger on verification_cases
CREATE OR REPLACE FUNCTION public.trigger_set_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS set_timestamp_verification_cases ON public.verification_cases;
CREATE TRIGGER set_timestamp_verification_cases
BEFORE UPDATE ON public.verification_cases
FOR EACH ROW
EXECUTE FUNCTION public.trigger_set_timestamp();

-- Row Level Security (RLS)
ALTER TABLE public.verification_cases ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.verification_documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.extracted_fields ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.verification_findings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.verification_audit_logs ENABLE ROW LEVEL SECURITY;

-- Base Policies (authenticated user or service role)
DROP POLICY IF EXISTS "Allow user to read own verification cases" ON public.verification_cases;
CREATE POLICY "Allow user to read own verification cases"
    ON public.verification_cases FOR SELECT
    USING (auth.uid()::text = user_id OR auth.role() = 'service_role' OR user_id = 'anonymous_user');

DROP POLICY IF EXISTS "Allow user to insert verification cases" ON public.verification_cases;
CREATE POLICY "Allow user to insert verification cases"
    ON public.verification_cases FOR INSERT
    WITH CHECK (auth.role() = 'authenticated' OR auth.role() = 'service_role' OR auth.role() = 'anon');

DROP POLICY IF EXISTS "Allow read verification docs for authorized case" ON public.verification_documents;
CREATE POLICY "Allow read verification docs for authorized case"
    ON public.verification_documents FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.verification_cases c
            WHERE c.id = verification_documents.case_id
            AND (c.user_id = auth.uid()::text OR auth.role() = 'service_role' OR c.user_id = 'anonymous_user')
        )
    );

DROP POLICY IF EXISTS "Allow read findings for authorized case" ON public.verification_findings;
CREATE POLICY "Allow read findings for authorized case"
    ON public.verification_findings FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.verification_cases c
            WHERE c.id = verification_findings.case_id
            AND (c.user_id = auth.uid()::text OR auth.role() = 'service_role' OR c.user_id = 'anonymous_user')
        )
    );
