-- =============================================================================
-- PROPZEN PROGRAMMATIC SEO & AI CONTENT AUTOMATION SCHEMA
-- Project ID: eemxylswyvhsyzllcsnp
-- Version: 3.0 (Data Ingestion + Structured Content + Review Queue + Audit)
-- =============================================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =============================================================================
-- 1. SEO SOURCES TABLE (Verified Raw Market Data Ingestion)
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.seo_sources (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    source_name TEXT NOT NULL, -- 'Apify_NCR_Realty_Dataset', 'UP_Gov_Circle_Rates', 'PropZen_Market_Index', 'CREDAI_Quarterly_Report'
    source_url TEXT,
    collection_date DATE NOT NULL DEFAULT CURRENT_DATE,
    location TEXT NOT NULL, -- e.g. 'Noida', 'Sector 150', 'Greater Noida'
    property_type TEXT NOT NULL DEFAULT 'All', -- 'Apartment', 'Plot', 'Villa', 'Commercial', 'All'
    raw_data JSONB NOT NULL DEFAULT '{}'::jsonb,
    confidence_score NUMERIC NOT NULL DEFAULT 1.0 CHECK (confidence_score >= 0.0 AND confidence_score <= 1.0),
    validation_status TEXT NOT NULL DEFAULT 'VALIDATED' CHECK (validation_status IN ('VALIDATED', 'PENDING_VALIDATION', 'REJECTED', 'EXPIRED')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_seo_sources_location ON public.seo_sources(location);
CREATE INDEX IF NOT EXISTS idx_seo_sources_date ON public.seo_sources(collection_date DESC);
CREATE INDEX IF NOT EXISTS idx_seo_sources_status ON public.seo_sources(validation_status);

-- =============================================================================
-- 2. SEO CONTENT TABLE (Articles, Market Guides, Locality Insights)
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.seo_content (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    slug TEXT UNIQUE NOT NULL,
    meta_title TEXT NOT NULL,
    meta_description TEXT NOT NULL,
    primary_keyword TEXT NOT NULL,
    secondary_keywords JSONB DEFAULT '[]'::jsonb,
    content TEXT NOT NULL,
    faq JSONB DEFAULT '[]'::jsonb,
    internal_links JSONB DEFAULT '[]'::jsonb,
    source_references JSONB DEFAULT '[]'::jsonb,
    content_type TEXT NOT NULL DEFAULT 'Market_Report' CHECK (content_type IN ('Market_Report', 'Locality_Guide', 'Price_Trend', 'Buyer_Guide', 'Infrastructure_Update')),
    location TEXT NOT NULL,
    property_type TEXT DEFAULT 'All',
    freshness_date DATE NOT NULL DEFAULT CURRENT_DATE,
    quality_score INT NOT NULL DEFAULT 95 CHECK (quality_score >= 0 AND quality_score <= 100),
    duplicate_similarity_score NUMERIC DEFAULT 0.0 CHECK (duplicate_similarity_score >= 0.0 AND duplicate_similarity_score <= 1.0),
    fact_check_warnings JSONB DEFAULT '[]'::jsonb,
    status TEXT NOT NULL DEFAULT 'HUMAN_REVIEW' CHECK (status IN ('DRAFT', 'HUMAN_REVIEW', 'PUBLISHED', 'REJECTED', 'ARCHIVED')),
    published_at TIMESTAMPTZ,
    reviewed_by TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_seo_content_slug ON public.seo_content(slug);
CREATE INDEX IF NOT EXISTS idx_seo_content_status ON public.seo_content(status);
CREATE INDEX IF NOT EXISTS idx_seo_content_location ON public.seo_content(location);

-- =============================================================================
-- 3. SEO PAGES TABLE (Programmatic Location & Price Rate Pages)
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.seo_pages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    slug TEXT UNIQUE NOT NULL, -- e.g. '/property-rates/noida/sector-150', '/buy/3-bhk/noida'
    page_type TEXT NOT NULL DEFAULT 'property-rates' CHECK (page_type IN ('property-rates', 'buy-category', 'rent-category', 'locality-hub')),
    city TEXT NOT NULL DEFAULT 'Noida',
    sector TEXT,
    property_type TEXT DEFAULT 'Apartment',
    bhk TEXT,
    avg_price_sqft NUMERIC DEFAULT 0,
    price_range_min NUMERIC DEFAULT 0,
    price_range_max NUMERIC DEFAULT 0,
    trend_percentage NUMERIC DEFAULT 0.0,
    trend_summary TEXT,
    available_properties_count INT DEFAULT 0,
    sample_property_ids JSONB DEFAULT '[]'::jsonb,
    faqs JSONB DEFAULT '[]'::jsonb,
    meta_title TEXT NOT NULL,
    meta_description TEXT NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    last_updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_seo_pages_slug ON public.seo_pages(slug);
CREATE INDEX IF NOT EXISTS idx_seo_pages_city ON public.seo_pages(city);
CREATE INDEX IF NOT EXISTS idx_seo_pages_sector ON public.seo_pages(sector);

-- =============================================================================
-- 4. SEO REVIEW QUEUE TABLE (Human-in-the-Loop Admin Review)
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.seo_review_queue (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    content_id UUID REFERENCES public.seo_content(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    slug TEXT NOT NULL,
    content_preview TEXT NOT NULL,
    data_sources JSONB DEFAULT '[]'::jsonb,
    ai_quality_score INT NOT NULL DEFAULT 85,
    seo_score INT NOT NULL DEFAULT 90,
    duplicate_similarity_score NUMERIC DEFAULT 0.05,
    fact_check_warnings JSONB DEFAULT '[]'::jsonb,
    recommended_decision TEXT NOT NULL DEFAULT 'APPROVE' CHECK (recommended_decision IN ('APPROVE', 'EDIT', 'REJECT', 'REQUEST_REGENERATION')),
    status TEXT NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'APPROVED', 'REJECTED', 'REGENERATED')),
    admin_notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    resolved_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_seo_review_status ON public.seo_review_queue(status);

-- =============================================================================
-- 5. SEO AUDIT LOGS TABLE
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.seo_audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    action TEXT NOT NULL, -- 'DATA_INGESTED', 'CONTENT_GENERATED', 'FACT_CHECK_PASSED', 'QUALITY_SCORED', 'ADMIN_APPROVED', 'ADMIN_REJECTED', 'AUTO_PUBLISHED', 'SITEMAP_UPDATED'
    target_entity TEXT NOT NULL, -- 'seo_content', 'seo_pages', 'seo_sources'
    entity_id TEXT NOT NULL,
    details JSONB DEFAULT '{}'::jsonb,
    actor_id TEXT DEFAULT 'system',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_seo_audit_action ON public.seo_audit_logs(action);
CREATE INDEX IF NOT EXISTS idx_seo_audit_created_at ON public.seo_audit_logs(created_at DESC);

-- =============================================================================
-- 6. ROW LEVEL SECURITY (RLS) POLICIES
-- =============================================================================
ALTER TABLE public.seo_sources ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.seo_content ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.seo_pages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.seo_review_queue ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.seo_audit_logs ENABLE ROW LEVEL SECURITY;

-- Public can read published content and active SEO pages
CREATE POLICY "Public read published seo_content" ON public.seo_content 
    FOR SELECT TO anon, authenticated USING (status = 'PUBLISHED');

CREATE POLICY "Public read active seo_pages" ON public.seo_pages 
    FOR SELECT TO anon, authenticated USING (is_active = true);

-- Admins and Service Role can manage all SEO tables
CREATE POLICY "Admin full access seo_sources" ON public.seo_sources 
    FOR ALL TO anon, authenticated USING (true) WITH CHECK (true);

CREATE POLICY "Admin full access seo_content" ON public.seo_content 
    FOR ALL TO anon, authenticated USING (true) WITH CHECK (true);

CREATE POLICY "Admin full access seo_pages" ON public.seo_pages 
    FOR ALL TO anon, authenticated USING (true) WITH CHECK (true);

CREATE POLICY "Admin full access seo_review_queue" ON public.seo_review_queue 
    FOR ALL TO anon, authenticated USING (true) WITH CHECK (true);

CREATE POLICY "Admin full access seo_audit_logs" ON public.seo_audit_logs 
    FOR ALL TO anon, authenticated USING (true) WITH CHECK (true);
