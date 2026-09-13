-- =============================================================================
-- PROPZEN FLYWAY MIGRATION V9: AI PROPERTY VERIFICATION WORKSPACE
-- =============================================================================
-- Target Database: Supabase PostgreSQL (Project eemxylswyvhsyzllcsnp)
-- Provides persistence for AI Property Verification Cases, Documents, Extracted OCR,
-- Consistency Checks, Risk Analysis, Findings, and Audit Milestones.
-- =============================================================================

-- 1. Property Verification Cases Table
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

-- 2. Property Verification Documents Table
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
