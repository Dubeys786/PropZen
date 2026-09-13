-- ============================================================================
-- PROPZEN MASTER MIGRATION: SUPER DASHBOARD + SEO + VENDOR MONETIZATION +
-- LOAN + DESIGN STUDIO + REPORTER + NRI INVESTMENT SUITE
-- ============================================================================

-- 1. SEO & INDEXING LOGS
CREATE TABLE IF NOT EXISTS public.seo_indexing_logs (
    id TEXT PRIMARY KEY DEFAULT ('SEO-' || EXTRACT(EPOCH FROM NOW())::TEXT),
    entity_type TEXT NOT NULL DEFAULT 'property',
    entity_id TEXT NOT NULL,
    url TEXT NOT NULL,
    requested_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    status TEXT NOT NULL CHECK (status IN ('PENDING', 'SUBMITTED', 'DISCOVERED', 'INDEXED', 'ERROR')),
    response JSONB DEFAULT '{}'::jsonb,
    last_checked_at TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS public.property_seo_metadata (
    property_id TEXT PRIMARY KEY,
    slug TEXT UNIQUE NOT NULL,
    meta_title TEXT NOT NULL,
    meta_description TEXT NOT NULL,
    canonical_url TEXT NOT NULL,
    og_title TEXT NOT NULL,
    og_description TEXT NOT NULL,
    og_image_url TEXT NOT NULL,
    structured_data_json JSONB NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 2. VENDOR WALLETS & MONETIZATION
CREATE TABLE IF NOT EXISTS public.vendor_wallets (
    vendor_id TEXT PRIMARY KEY,
    balance_inr NUMERIC NOT NULL DEFAULT 0.0 CHECK (balance_inr >= 0),
    total_credited NUMERIC NOT NULL DEFAULT 0.0,
    total_debited NUMERIC NOT NULL DEFAULT 0.0,
    currency TEXT NOT NULL DEFAULT 'INR',
    status TEXT NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'FROZEN', 'SUSPENDED')),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.wallet_transactions (
    id TEXT PRIMARY KEY DEFAULT ('WTX-' || EXTRACT(EPOCH FROM NOW())::TEXT),
    vendor_id TEXT NOT NULL REFERENCES public.vendor_wallets(vendor_id) ON DELETE CASCADE,
    amount NUMERIC NOT NULL,
    type TEXT NOT NULL CHECK (type IN ('CREDIT', 'DEBIT', 'REFUND', 'BONUS', 'ADJUSTMENT')),
    reference_id TEXT,
    description TEXT NOT NULL,
    balance_after NUMERIC NOT NULL,
    status TEXT NOT NULL DEFAULT 'COMPLETED' CHECK (status IN ('PENDING', 'COMPLETED', 'FAILED', 'CANCELLED')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.wallet_ledger (
    id TEXT PRIMARY KEY DEFAULT ('LEDG-' || EXTRACT(EPOCH FROM NOW())::TEXT),
    transaction_id TEXT NOT NULL REFERENCES public.wallet_transactions(id) ON DELETE CASCADE,
    vendor_id TEXT NOT NULL,
    entry_type TEXT NOT NULL CHECK (entry_type IN ('DEBIT', 'CREDIT')),
    amount NUMERIC NOT NULL,
    balance_before NUMERIC NOT NULL,
    balance_after NUMERIC NOT NULL,
    recorded_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.lead_distribution_rules (
    id TEXT PRIMARY KEY DEFAULT 'active_rules',
    subscription_weight NUMERIC NOT NULL DEFAULT 0.25,
    location_weight NUMERIC NOT NULL DEFAULT 0.25,
    category_weight NUMERIC NOT NULL DEFAULT 0.20,
    verification_weight NUMERIC NOT NULL DEFAULT 0.10,
    response_rate_weight NUMERIC NOT NULL DEFAULT 0.10,
    rotation_weight NUMERIC NOT NULL DEFAULT 0.10,
    default_lead_cost_inr NUMERIC NOT NULL DEFAULT 350.0,
    lead_response_timeout_mins INTEGER NOT NULL DEFAULT 30,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.lead_assignments (
    id TEXT PRIMARY KEY DEFAULT ('ASN-' || EXTRACT(EPOCH FROM NOW())::TEXT),
    lead_id TEXT NOT NULL,
    vendor_id TEXT NOT NULL,
    assigned_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    assignment_type TEXT NOT NULL DEFAULT 'AUTO',
    cost_inr NUMERIC NOT NULL DEFAULT 350.0,
    status TEXT NOT NULL DEFAULT 'ASSIGNED' CHECK (status IN ('ASSIGNED', 'ACCEPTED', 'CONTACTED', 'CONVERTED', 'REJECTED', 'EXPIRED', 'CANCELLED')),
    accepted_at TIMESTAMPTZ,
    contacted_at TIMESTAMPTZ,
    converted_at TIMESTAMPTZ,
    rejected_at TIMESTAMPTZ,
    expired_at TIMESTAMPTZ,
    rejection_reason TEXT
);

-- 3. LOAN MODULE TABLES
CREATE TABLE IF NOT EXISTS public.loan_requests (
    id TEXT PRIMARY KEY DEFAULT ('LOAN-' || EXTRACT(EPOCH FROM NOW())::TEXT),
    user_id TEXT NOT NULL,
    property_id TEXT,
    property_title TEXT NOT NULL,
    property_price NUMERIC NOT NULL DEFAULT 0,
    down_payment NUMERIC NOT NULL DEFAULT 0,
    loan_amount NUMERIC NOT NULL,
    property_type TEXT NOT NULL DEFAULT 'Apartment',
    property_location TEXT NOT NULL DEFAULT 'Noida / NCR',
    name TEXT NOT NULL,
    phone TEXT NOT NULL,
    email TEXT NOT NULL,
    city TEXT NOT NULL DEFAULT 'Noida',
    employment_type TEXT NOT NULL DEFAULT 'Salaried',
    monthly_income NUMERIC NOT NULL,
    existing_emi NUMERIC NOT NULL DEFAULT 0,
    preferred_tenure_years INTEGER NOT NULL DEFAULT 20,
    preferred_lender TEXT,
    indicative_eligibility NUMERIC NOT NULL DEFAULT 0,
    status TEXT NOT NULL DEFAULT 'NEW' CHECK (status IN ('NEW', 'DOCUMENTS_PENDING', 'UNDER_REVIEW', 'MANUAL_PROCESSING', 'OFFER_AVAILABLE', 'CUSTOMER_REVIEW', 'APPROVED', 'REJECTED', 'CLOSED')),
    admin_remarks TEXT,
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.loan_documents (
    id TEXT PRIMARY KEY DEFAULT ('LDOC-' || EXTRACT(EPOCH FROM NOW())::TEXT),
    loan_request_id TEXT NOT NULL REFERENCES public.loan_requests(id) ON DELETE CASCADE,
    document_type TEXT NOT NULL,
    document_url TEXT NOT NULL,
    file_name TEXT NOT NULL,
    file_size_bytes INTEGER DEFAULT 0,
    uploaded_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.loan_status_history (
    id TEXT PRIMARY KEY DEFAULT ('LHIST-' || EXTRACT(EPOCH FROM NOW())::TEXT),
    loan_request_id TEXT NOT NULL REFERENCES public.loan_requests(id) ON DELETE CASCADE,
    from_status TEXT NOT NULL,
    to_status TEXT NOT NULL,
    updated_by TEXT NOT NULL,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.loan_offers (
    id TEXT PRIMARY KEY DEFAULT ('LOFR-' || EXTRACT(EPOCH FROM NOW())::TEXT),
    loan_request_id TEXT NOT NULL REFERENCES public.loan_requests(id) ON DELETE CASCADE,
    lender_name TEXT NOT NULL,
    sanctioned_amount NUMERIC NOT NULL,
    interest_rate NUMERIC NOT NULL,
    tenure_years INTEGER NOT NULL,
    monthly_emi NUMERIC NOT NULL,
    processing_fee NUMERIC NOT NULL DEFAULT 0,
    special_terms TEXT,
    valid_until TIMESTAMPTZ,
    status TEXT NOT NULL DEFAULT 'Offered',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 4. DESIGN STUDIO & JOBS
CREATE TABLE IF NOT EXISTS public.design_projects (
    id TEXT PRIMARY KEY DEFAULT ('PRJ-' || EXTRACT(EPOCH FROM NOW())::TEXT),
    user_id TEXT NOT NULL,
    property_id TEXT,
    title TEXT NOT NULL,
    project_type TEXT NOT NULL,
    plot_width NUMERIC NOT NULL,
    plot_length NUMERIC NOT NULL,
    plot_area NUMERIC NOT NULL,
    facing_direction TEXT NOT NULL,
    entrance_direction TEXT NOT NULL,
    vastu_analysis JSONB DEFAULT '{}'::jsonb,
    layout_data JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.design_rooms (
    id TEXT PRIMARY KEY DEFAULT ('RM-' || EXTRACT(EPOCH FROM NOW())::TEXT),
    project_id TEXT NOT NULL REFERENCES public.design_projects(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    room_type TEXT NOT NULL,
    width_ft NUMERIC NOT NULL,
    length_ft NUMERIC NOT NULL,
    x_pos NUMERIC NOT NULL,
    y_pos NUMERIC NOT NULL,
    doors_count INTEGER DEFAULT 1,
    windows_count INTEGER DEFAULT 1,
    vastu_zone TEXT NOT NULL,
    color_hex TEXT DEFAULT '#4F46E5',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.design_jobs (
    id TEXT PRIMARY KEY DEFAULT ('DJOB-' || EXTRACT(EPOCH FROM NOW())::TEXT),
    user_id TEXT NOT NULL,
    project_id TEXT,
    job_type TEXT NOT NULL,
    input_url TEXT,
    parameters JSONB DEFAULT '{}'::jsonb,
    status TEXT NOT NULL CHECK (status IN ('QUEUED', 'PROCESSING', 'COMPLETED', 'FAILED')),
    result_url TEXT,
    error_message TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    completed_at TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS public.design_results (
    id TEXT PRIMARY KEY DEFAULT ('DRES-' || EXTRACT(EPOCH FROM NOW())::TEXT),
    job_id TEXT NOT NULL REFERENCES public.design_jobs(id) ON DELETE CASCADE,
    user_id TEXT NOT NULL,
    image_url TEXT NOT NULL,
    style TEXT NOT NULL,
    room_type TEXT NOT NULL,
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 5. REPORTER VIDEOS & JOBS
CREATE TABLE IF NOT EXISTS public.reporter_videos (
    id TEXT PRIMARY KEY DEFAULT ('VID-REP-' || EXTRACT(EPOCH FROM NOW())::TEXT),
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    category TEXT NOT NULL,
    video_url TEXT NOT NULL,
    thumbnail_url TEXT NOT NULL,
    script JSONB DEFAULT '{}'::jsonb,
    source_information TEXT,
    status TEXT NOT NULL CHECK (status IN ('DRAFT', 'GENERATING', 'REVIEW', 'APPROVED', 'PUBLISHED', 'UNPUBLISHED', 'FAILED')),
    created_by TEXT,
    approved_by TEXT,
    published_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.reporter_jobs (
    id TEXT PRIMARY KEY DEFAULT ('RJOB-' || EXTRACT(EPOCH FROM NOW())::TEXT),
    video_id TEXT NOT NULL REFERENCES public.reporter_videos(id) ON DELETE CASCADE,
    provider TEXT NOT NULL,
    job_type TEXT NOT NULL,
    external_job_id TEXT,
    status TEXT NOT NULL CHECK (status IN ('QUEUED', 'PROCESSING', 'COMPLETED', 'FAILED')),
    error_message TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    completed_at TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS public.reporter_sources (
    id TEXT PRIMARY KEY DEFAULT ('RSRC-' || EXTRACT(EPOCH FROM NOW())::TEXT),
    title TEXT NOT NULL,
    source_url TEXT,
    category TEXT NOT NULL,
    verified BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.reporter_analytics (
    video_id TEXT PRIMARY KEY REFERENCES public.reporter_videos(id) ON DELETE CASCADE,
    view_count INTEGER DEFAULT 0,
    share_count INTEGER DEFAULT 0,
    save_count INTEGER DEFAULT 0,
    last_viewed_at TIMESTAMPTZ
);

-- 6. NRI VALUATION & LOCATION INTELLIGENCE
CREATE TABLE IF NOT EXISTS public.property_valuation_reports (
    id TEXT PRIMARY KEY DEFAULT ('PVR-' || EXTRACT(EPOCH FROM NOW())::TEXT),
    property_id TEXT NOT NULL,
    user_id TEXT,
    current_value NUMERIC NOT NULL,
    price_per_sqft NUMERIC NOT NULL,
    historical_trend JSONB NOT NULL DEFAULT '[]'::jsonb,
    conservative_1y NUMERIC NOT NULL,
    conservative_3y NUMERIC NOT NULL,
    conservative_5y NUMERIC NOT NULL,
    base_1y NUMERIC NOT NULL,
    base_3y NUMERIC NOT NULL,
    base_5y NUMERIC NOT NULL,
    optimistic_1y NUMERIC NOT NULL,
    optimistic_3y NUMERIC NOT NULL,
    optimistic_5y NUMERIC NOT NULL,
    rental_yield_projected NUMERIC NOT NULL DEFAULT 4.5,
    assumptions TEXT NOT NULL,
    source_data_timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    model_version TEXT NOT NULL DEFAULT 'v2.4-hybrid',
    confidence_score INTEGER NOT NULL DEFAULT 90,
    ai_explanation TEXT NOT NULL,
    generated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.valuation_data_sources (
    id TEXT PRIMARY KEY DEFAULT ('VDS-' || EXTRACT(EPOCH FROM NOW())::TEXT),
    property_id TEXT NOT NULL,
    source_name TEXT NOT NULL,
    data_type TEXT NOT NULL,
    source_url TEXT,
    recorded_price_sqft NUMERIC NOT NULL,
    transaction_date DATE,
    verified BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.location_intelligence (
    id TEXT PRIMARY KEY DEFAULT ('LOC-' || EXTRACT(EPOCH FROM NOW())::TEXT),
    property_id TEXT NOT NULL,
    hospital_distances JSONB NOT NULL DEFAULT '[]'::jsonb,
    school_distances JSONB NOT NULL DEFAULT '[]'::jsonb,
    mall_distances JSONB NOT NULL DEFAULT '[]'::jsonb,
    airport_distance_km NUMERIC NOT NULL DEFAULT 38.0,
    jewar_airport_km NUMERIC NOT NULL DEFAULT 28.0,
    metro_distance_km NUMERIC NOT NULL DEFAULT 0.6,
    major_roads JSONB NOT NULL DEFAULT '[]'::jsonb,
    last_updated TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.location_scores (
    id TEXT PRIMARY KEY DEFAULT ('LSCR-' || EXTRACT(EPOCH FROM NOW())::TEXT),
    property_id TEXT NOT NULL,
    connectivity_score NUMERIC NOT NULL DEFAULT 9.0,
    healthcare_score NUMERIC NOT NULL DEFAULT 8.5,
    education_score NUMERIC NOT NULL DEFAULT 8.8,
    retail_score NUMERIC NOT NULL DEFAULT 8.2,
    transport_score NUMERIC NOT NULL DEFAULT 9.1,
    airport_score NUMERIC NOT NULL DEFAULT 8.6,
    environment_score NUMERIC NOT NULL DEFAULT 8.0,
    overall_score NUMERIC NOT NULL DEFAULT 8.7,
    calculation_version TEXT NOT NULL DEFAULT 'v1.2-weighted',
    generated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.aqi_records (
    id TEXT PRIMARY KEY DEFAULT ('AQI-' || EXTRACT(EPOCH FROM NOW())::TEXT),
    sector TEXT NOT NULL,
    city TEXT NOT NULL,
    current_aqi INTEGER NOT NULL DEFAULT 135,
    aqi_category TEXT NOT NULL DEFAULT 'Moderate',
    dominant_pollutant TEXT NOT NULL DEFAULT 'PM2.5',
    data_provider TEXT NOT NULL DEFAULT 'Central Pollution Control Board (CPCB)',
    last_updated TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.neighborhood_data (
    id TEXT PRIMARY KEY DEFAULT ('NBD-' || EXTRACT(EPOCH FROM NOW())::TEXT),
    property_id TEXT NOT NULL,
    facility_name TEXT NOT NULL,
    facility_type TEXT NOT NULL,
    distance_km NUMERIC NOT NULL,
    travel_time_mins INTEGER NOT NULL,
    status TEXT NOT NULL CHECK (status IN ('OPERATIONAL', 'UNDER_CONSTRUCTION', 'ANNOUNCED', 'UNVERIFIED')),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 7. NRI AI ADVISOR CHAT TABLES
CREATE TABLE IF NOT EXISTS public.ai_advisor_sessions (
    id TEXT PRIMARY KEY DEFAULT ('SES-' || EXTRACT(EPOCH FROM NOW())::TEXT),
    user_id TEXT NOT NULL,
    title TEXT NOT NULL DEFAULT 'New Property Search',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.ai_advisor_messages (
    id TEXT PRIMARY KEY DEFAULT ('MSG-' || EXTRACT(EPOCH FROM NOW())::TEXT),
    session_id TEXT NOT NULL REFERENCES public.ai_advisor_sessions(id) ON DELETE CASCADE,
    sender TEXT NOT NULL CHECK (sender IN ('user', 'assistant')),
    content TEXT NOT NULL,
    extracted_criteria JSONB DEFAULT '{}'::jsonb,
    matched_property_ids TEXT[] DEFAULT ARRAY[]::TEXT[],
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 8. INTERNATIONAL PAYMENTS & AUDIT
CREATE TABLE IF NOT EXISTS public.international_payments (
    id TEXT PRIMARY KEY DEFAULT ('PAY-INT-' || EXTRACT(EPOCH FROM NOW())::TEXT),
    user_id TEXT NOT NULL,
    payment_category TEXT NOT NULL CHECK (payment_category IN ('service_fee', 'verification_fee', 'vendor_wallet', 'property_token')),
    amount_inr NUMERIC NOT NULL CHECK (amount_inr > 0),
    currency TEXT NOT NULL DEFAULT 'INR',
    amount_foreign NUMERIC NOT NULL CHECK (amount_foreign > 0),
    exchange_rate NUMERIC NOT NULL DEFAULT 1.0,
    provider TEXT NOT NULL DEFAULT 'razorpay_international',
    provider_order_id TEXT,
    provider_payment_id TEXT,
    provider_signature TEXT,
    idempotency_key TEXT UNIQUE NOT NULL,
    status TEXT NOT NULL CHECK (status IN ('CREATED', 'PENDING', 'SUCCESS', 'FAILED', 'CANCELLED', 'REFUNDED')),
    receipt_url TEXT,
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.payment_audit_logs (
    id TEXT PRIMARY KEY DEFAULT ('PAUD-' || EXTRACT(EPOCH FROM NOW())::TEXT),
    payment_id TEXT NOT NULL REFERENCES public.international_payments(id) ON DELETE CASCADE,
    event_type TEXT NOT NULL,
    signature_verified BOOLEAN NOT NULL,
    payload JSONB DEFAULT '{}'::jsonb,
    ip_address TEXT,
    timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 9. 3D VISUALIZATION TABLES
CREATE TABLE IF NOT EXISTS public.visualization_jobs (
    id TEXT PRIMARY KEY DEFAULT ('VJOB-' || EXTRACT(EPOCH FROM NOW())::TEXT),
    user_id TEXT NOT NULL,
    property_id TEXT,
    design_id TEXT,
    job_type TEXT NOT NULL,
    provider TEXT NOT NULL DEFAULT 'built_in_isometric',
    status TEXT NOT NULL CHECK (status IN ('QUEUED', 'PROCESSING', 'COMPLETED', 'FAILED')),
    parameters JSONB DEFAULT '{}'::jsonb,
    result_url TEXT,
    error_message TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    completed_at TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS public.visualization_results (
    id TEXT PRIMARY KEY DEFAULT ('VRES-' || EXTRACT(EPOCH FROM NOW())::TEXT),
    job_id TEXT NOT NULL REFERENCES public.visualization_jobs(id) ON DELETE CASCADE,
    user_id TEXT NOT NULL,
    property_id TEXT,
    model_url TEXT NOT NULL,
    thumbnail_url TEXT,
    scene_type TEXT NOT NULL DEFAULT 'isometric_architectural_twin',
    camera_positions JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Enable RLS on all newly created tables
ALTER TABLE public.seo_indexing_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.property_seo_metadata ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.vendor_wallets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.wallet_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.wallet_ledger ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.lead_distribution_rules ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.lead_assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.loan_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.loan_documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.loan_status_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.loan_offers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.design_projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.design_rooms ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.design_jobs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.design_results ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reporter_videos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reporter_jobs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reporter_sources ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reporter_analytics ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.property_valuation_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.valuation_data_sources ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.location_intelligence ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.location_scores ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.aqi_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.neighborhood_data ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ai_advisor_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ai_advisor_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.international_payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payment_audit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.visualization_jobs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.visualization_results ENABLE ROW LEVEL SECURITY;

-- Seed default distribution rules if not exists
INSERT INTO public.lead_distribution_rules (id, subscription_weight, location_weight, category_weight, verification_weight, response_rate_weight, rotation_weight, default_lead_cost_inr, lead_response_timeout_mins)
VALUES ('active_rules', 0.25, 0.25, 0.20, 0.10, 0.10, 0.10, 350.0, 30)
ON CONFLICT (id) DO NOTHING;
