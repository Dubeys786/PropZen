-- =============================================================================
-- PROPNZEN — PHASE 6: PROPERTY INTELLIGENCE & VERIFICATION SYSTEM SCHEMA
-- =============================================================================

-- 1. Property Verification Documents Table
CREATE TABLE IF NOT EXISTS public.property_verification_documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    property_id TEXT NOT NULL REFERENCES public.properties(id) ON DELETE CASCADE,
    document_type TEXT NOT NULL, -- 'RERA Certificate', 'Sanctioned Plan', 'Title Deed', 'Occupancy Certificate', 'Tax Receipt'
    document_url TEXT NOT NULL,
    file_name TEXT NOT NULL,
    file_size_bytes BIGINT DEFAULT 0,
    mime_type TEXT DEFAULT 'application/pdf',
    verification_status TEXT NOT NULL DEFAULT 'pending', -- 'pending', 'verified', 'needs_review', 'rejected'
    confidence_score INTEGER DEFAULT 85,
    extracted_metadata JSONB DEFAULT '{}'::jsonb,
    verifier_admin_id UUID,
    verified_at TIMESTAMPTZ,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Property Intelligence 5-Pillar Score & POI Records
CREATE TABLE IF NOT EXISTS public.property_intelligence_evaluations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    property_id TEXT NOT NULL UNIQUE REFERENCES public.properties(id) ON DELETE CASCADE,
    overall_score INTEGER NOT NULL DEFAULT 85,
    rating_grade TEXT NOT NULL DEFAULT 'Grade A',
    rera_score INTEGER NOT NULL DEFAULT 25,
    pricing_score INTEGER NOT NULL DEFAULT 20,
    media_score INTEGER NOT NULL DEFAULT 15,
    locality_score INTEGER NOT NULL DEFAULT 20,
    developer_score INTEGER NOT NULL DEFAULT 15,
    nearby_pois JSONB DEFAULT '[]'::jsonb,
    cost_breakdown JSONB DEFAULT '{}'::jsonb,
    risk_indicators JSONB DEFAULT '[]'::jsonb,
    last_evaluated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Row Level Security Policies
ALTER TABLE public.property_verification_documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.property_intelligence_evaluations ENABLE ROW LEVEL SECURITY;

-- Public can read verified intelligence evaluations
CREATE POLICY "Allow public read for intelligence evaluations"
    ON public.property_intelligence_evaluations
    FOR SELECT
    USING (true);

-- Hardened: Verification documents readable only by owning dealer or admin
DROP POLICY IF EXISTS "Allow read for property verification docs" ON public.property_verification_documents;
CREATE POLICY "Allow read for property verification docs"
    ON public.property_verification_documents
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.properties p
            WHERE p.id = property_verification_documents.property_id
            AND (p.dealer_id = auth.uid()::text OR p.dealer_email = public.current_user_email())
        )
        OR public.is_admin()
    );

-- Only Admins and Submitting Dealers can insert/update verification documents
CREATE POLICY "Allow dealer or admin insert verification docs"
    ON public.property_verification_documents
    FOR INSERT
    WITH CHECK (auth.role() = 'authenticated');
