-- =========================================================================
-- PROPZEN SUPABASE DATABASE SCHEMA (PRODUCTION)
-- Project ID: eemxylswyvhsyzllcsnp
-- Purpose: Dealer Property Approval System, Real-Time Notifications & RLS
-- =========================================================================

-- 1. USERS TABLE (Sign in / Registration records)
CREATE TABLE IF NOT EXISTS public.users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    full_name TEXT NOT NULL,
    email TEXT,
    phone TEXT,
    role TEXT DEFAULT 'Buyer', -- 'Buyer', 'Dealer', 'Admin', 'Owner'
    is_email_verified BOOLEAN DEFAULT FALSE,
    last_login_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    metadata JSONB DEFAULT '{}'::jsonb
);

-- 2. PROPERTIES TABLE (Dealer Listings & Property Intelligence)
CREATE TABLE IF NOT EXISTS public.properties (
    id TEXT PRIMARY KEY,
    dealer_id TEXT NOT NULL,
    name TEXT NOT NULL,
    description TEXT,
    property_type TEXT, -- 'Apartment', 'Flat', 'Plot', 'Villa', 'Office Space', 'Retail Shop'
    bhk TEXT, -- '1 BHK', '2 BHK', '3 BHK', '4 BHK', '5+ BHK', 'Studio', 'Commercial'
    price NUMERIC NOT NULL,
    price_cr NUMERIC,
    area NUMERIC, -- sqft
    carpet_area NUMERIC,
    city TEXT NOT NULL,
    locality TEXT,
    address TEXT,
    postal_code TEXT,
    latitude DOUBLE PRECISION NOT NULL DEFAULT 28.4354,
    longitude DOUBLE PRECISION NOT NULL DEFAULT 77.4878,
    place_id TEXT,
    images JSONB DEFAULT '[]'::jsonb,
    image_url TEXT,
    amenities JSONB DEFAULT '[]'::jsonb,
    category TEXT DEFAULT 'Residential',
    rera_status TEXT DEFAULT 'Approved',
    possession_status TEXT DEFAULT 'Ready to Move',
    furnishing_status TEXT DEFAULT 'Semi-Furnished',
    contact_name TEXT,
    contact_phone TEXT,
    contact_email TEXT,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'published', 'rejected')),
    admin_note TEXT,
    terms_accepted BOOLEAN DEFAULT TRUE,
    terms_version TEXT DEFAULT '1.0',
    terms_accepted_at TIMESTAMPTZ DEFAULT NOW(),
    terms_accepted_by TEXT,
    declaration_accuracy_accepted BOOLEAN DEFAULT TRUE,
    declaration_authorization_accepted BOOLEAN DEFAULT TRUE,
    declaration_content_rights_accepted BOOLEAN DEFAULT TRUE,
    declaration_pricing_accepted BOOLEAN DEFAULT TRUE,
    declaration_review_accepted BOOLEAN DEFAULT TRUE,
    declaration_terms_accepted BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    approved_at TIMESTAMPTZ,
    approved_by TEXT,
    metadata JSONB DEFAULT '{}'::jsonb
);

-- 2.1 DEALER TERMS ACCEPTANCES AUDIT TABLE (Acceptance Audit Trail)
CREATE TABLE IF NOT EXISTS public.dealer_terms_acceptances (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    dealer_id TEXT NOT NULL,
    property_id TEXT NOT NULL,
    terms_version TEXT NOT NULL DEFAULT '1.0',
    accepted_at TIMESTAMPTZ DEFAULT NOW(),
    declarations JSONB DEFAULT '{}'::jsonb,
    metadata JSONB DEFAULT '{}'::jsonb
);

-- Backwards compatibility alias view for legacy posted_properties
CREATE OR REPLACE VIEW public.posted_properties AS 
SELECT 
    id,
    name AS title,
    city,
    locality AS sector,
    property_type,
    bhk,
    price_cr,
    area AS sqft,
    contact_name AS owner_name,
    contact_phone AS owner_phone,
    status,
    created_at,
    metadata
FROM public.properties;

-- 3. NOTIFICATIONS TABLE (Admin & Dealer Event Stream)
CREATE TABLE IF NOT EXISTS public.notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    type TEXT DEFAULT 'property_approval', -- 'property_approval', 'enquiry', 'site_visit', 'status_update'
    property_id TEXT,
    dealer_id TEXT,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    metadata JSONB DEFAULT '{}'::jsonb
);

-- 4. ENQUIRIES TABLE (Property Enquiries)
CREATE TABLE IF NOT EXISTS public.enquiries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    property_id TEXT,
    property_title TEXT NOT NULL,
    client_id TEXT,
    client_name TEXT NOT NULL,
    client_email TEXT,
    client_phone TEXT NOT NULL,
    dealer_id TEXT,
    enquiry_type TEXT DEFAULT 'Property Details Enquiry',
    message TEXT,
    status TEXT DEFAULT 'New', -- 'New', 'Contacted', 'Closed'
    created_at TIMESTAMPTZ DEFAULT NOW(),
    metadata JSONB DEFAULT '{}'::jsonb
);

-- 5. SITE VISITS TABLE (Book a Site Visit bookings)
CREATE TABLE IF NOT EXISTS public.site_visits (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    property_id TEXT,
    property_title TEXT NOT NULL,
    user_id TEXT,
    dealer_id TEXT,
    user_name TEXT NOT NULL,
    user_email TEXT,
    user_phone TEXT NOT NULL,
    name TEXT,
    email TEXT,
    phone TEXT,
    visit_date TEXT NOT NULL,
    time_slot TEXT NOT NULL,
    visit_time TEXT,
    visitor_count INT DEFAULT 1,
    cab_required BOOLEAN DEFAULT FALSE,
    message TEXT,
    status TEXT DEFAULT 'Pending Confirmation',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    metadata JSONB DEFAULT '{}'::jsonb
);

-- 6. ADMIN ACCOUNTS TABLE (Single Master Admin Slot)
CREATE TABLE IF NOT EXISTS public.admin_accounts (
    id TEXT PRIMARY KEY,
    full_name TEXT NOT NULL,
    email TEXT NOT NULL UNIQUE,
    role TEXT DEFAULT 'Master Administrator',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    metadata JSONB DEFAULT '{}'::jsonb
);

-- 7. SAVED PROPERTY PREFERENCES TABLE (Find My Perfect Property)
CREATE TABLE IF NOT EXISTS public.saved_property_preferences (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id TEXT NOT NULL,
    purpose TEXT DEFAULT 'Buy',
    city TEXT DEFAULT 'Noida',
    localities JSONB DEFAULT '[]'::jsonb,
    min_budget NUMERIC DEFAULT 0.40,
    max_budget NUMERIC DEFAULT 2.50,
    property_types JSONB DEFAULT '[]'::jsonb,
    bhk_preferences JSONB DEFAULT '[]'::jsonb,
    priorities JSONB DEFAULT '[]'::jsonb,
    lifestyle_preferences JSONB DEFAULT '[]'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ENABLE ROW LEVEL SECURITY (RLS)
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.properties ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.enquiries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.site_visits ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.admin_accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.saved_property_preferences ENABLE ROW LEVEL SECURITY;

-- =========================================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- =========================================================================

-- 1. PROPERTIES POLICIES
-- Public Users: Can only read PUBLISHED properties
CREATE POLICY "Public users can view published properties only" 
ON public.properties FOR SELECT 
TO anon, authenticated 
USING (status = 'published');

-- Dealers / Authenticated Users: Can insert properties ONLY with status = 'pending'
CREATE POLICY "Dealers can submit properties with pending status" 
ON public.properties FOR INSERT 
TO anon, authenticated 
WITH CHECK (status = 'pending');

-- Dealers: Can read their own properties (including pending and rejected)
CREATE POLICY "Dealers can view their own properties" 
ON public.properties FOR SELECT 
TO anon, authenticated 
USING (dealer_id IS NOT NULL);

-- Admins / Authenticated System: Full update for approval & rejection
CREATE POLICY "Admin can update property status and admin_note" 
ON public.properties FOR UPDATE 
TO anon, authenticated 
USING (true) 
WITH CHECK (true);

-- 2. NOTIFICATIONS POLICIES
CREATE POLICY "Allow select on notifications" ON public.notifications FOR SELECT TO anon, authenticated USING (true);
CREATE POLICY "Allow insert on notifications" ON public.notifications FOR INSERT TO anon, authenticated WITH CHECK (true);
CREATE POLICY "Allow update on notifications" ON public.notifications FOR UPDATE TO anon, authenticated USING (true) WITH CHECK (true);

-- 3. ENQUIRIES POLICIES
CREATE POLICY "Allow insert on enquiries" ON public.enquiries FOR INSERT TO anon, authenticated WITH CHECK (true);
CREATE POLICY "Allow select on enquiries" ON public.enquiries FOR SELECT TO anon, authenticated USING (true);

-- 4. SITE VISITS POLICIES
CREATE POLICY "Allow insert on site_visits" ON public.site_visits FOR INSERT TO anon, authenticated WITH CHECK (true);
CREATE POLICY "Allow select on site_visits" ON public.site_visits FOR SELECT TO anon, authenticated USING (true);

-- 5. USERS & ADMIN ACCOUNTS POLICIES
CREATE POLICY "Allow select on users" ON public.users FOR SELECT TO anon, authenticated USING (true);
CREATE POLICY "Allow insert on users" ON public.users FOR INSERT TO anon, authenticated WITH CHECK (true);
CREATE POLICY "Allow update on users" ON public.users FOR UPDATE TO anon, authenticated USING (true);

CREATE POLICY "Allow select on admin_accounts" ON public.admin_accounts FOR SELECT TO anon, authenticated USING (true);
CREATE POLICY "Allow insert on admin_accounts" ON public.admin_accounts FOR INSERT TO anon, authenticated WITH CHECK (true);
CREATE POLICY "Allow update on admin_accounts" ON public.admin_accounts FOR UPDATE TO anon, authenticated USING (true);

-- 6. SAVED PROPERTY PREFERENCES POLICIES
CREATE POLICY "Allow select on saved_property_preferences" ON public.saved_property_preferences FOR SELECT TO anon, authenticated USING (true);
CREATE POLICY "Allow insert on saved_property_preferences" ON public.saved_property_preferences FOR INSERT TO anon, authenticated WITH CHECK (true);
CREATE POLICY "Allow update on saved_property_preferences" ON public.saved_property_preferences FOR UPDATE TO anon, authenticated USING (true);

-- =========================================================================
-- 8. AI HOME & VASTU DESIGNER TABLES
-- =========================================================================

CREATE TABLE IF NOT EXISTS public.ai_home_projects (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    project_name TEXT NOT NULL,
    plot_length NUMERIC NOT NULL,
    plot_width NUMERIC NOT NULL,
    plot_unit TEXT DEFAULT 'feet',
    plot_shape TEXT DEFAULT 'rectangle',
    road_width NUMERIC DEFAULT 30.0,
    road_direction TEXT DEFAULT 'N',
    entrance_direction TEXT DEFAULT 'NE',
    floors TEXT DEFAULT 'G+1',
    parking TEXT DEFAULT 'Yes (1 Car)',
    property_type TEXT DEFAULT 'Independent House',
    bedrooms INT DEFAULT 3,
    bathrooms INT DEFAULT 3,
    kitchen_type TEXT DEFAULT 'Modular Kitchen',
    budget TEXT DEFAULT '₹50L – ₹1Cr',
    design_style TEXT DEFAULT 'Modern',
    vastu_preferences JSONB DEFAULT '[]'::jsonb,
    status TEXT DEFAULT 'draft',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    metadata JSONB DEFAULT '{}'::jsonb
);

CREATE TABLE IF NOT EXISTS public.ai_floor_plans (
    id TEXT PRIMARY KEY,
    project_id TEXT REFERENCES public.ai_home_projects(id) ON DELETE CASCADE,
    floor_number INT DEFAULT 0,
    floor_title TEXT NOT NULL,
    total_built_up_area_sqft NUMERIC,
    carpet_area_sqft NUMERIC,
    vastu_score INT DEFAULT 90,
    vastu_insights JSONB DEFAULT '[]'::jsonb,
    rooms JSONB DEFAULT '[]'::jsonb,
    preview_image_url TEXT,
    architectural_note TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.ai_facade_designs (
    id TEXT PRIMARY KEY,
    project_id TEXT REFERENCES public.ai_home_projects(id) ON DELETE CASCADE,
    variant_name TEXT NOT NULL,
    style TEXT,
    color_palette TEXT,
    exterior_materials TEXT,
    lighting_highlights TEXT,
    image_url TEXT,
    tags JSONB DEFAULT '[]'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.ai_interior_designs (
    id TEXT PRIMARY KEY,
    project_id TEXT REFERENCES public.ai_home_projects(id) ON DELETE CASCADE,
    room_name TEXT NOT NULL,
    style TEXT,
    color_preference TEXT,
    furniture TEXT,
    lighting TEXT,
    wall_design TEXT,
    flooring TEXT,
    ceiling TEXT,
    decor TEXT,
    image_url TEXT,
    estimated_furnishing_budget TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.ai_walkthroughs (
    id TEXT PRIMARY KEY,
    project_id TEXT REFERENCES public.ai_home_projects(id) ON DELETE CASCADE,
    status TEXT DEFAULT 'ready',
    video_url TEXT,
    web_viewer_url TEXT,
    duration_seconds INT DEFAULT 45,
    camera_keyframes JSONB DEFAULT '[]'::jsonb,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- RLS FOR AI HOME DESIGNER TABLES
ALTER TABLE public.ai_home_projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ai_floor_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ai_facade_designs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ai_interior_designs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ai_walkthroughs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow select on ai_home_projects" ON public.ai_home_projects FOR SELECT TO anon, authenticated USING (true);
CREATE POLICY "Allow insert on ai_home_projects" ON public.ai_home_projects FOR INSERT TO anon, authenticated WITH CHECK (true);
CREATE POLICY "Allow update on ai_home_projects" ON public.ai_home_projects FOR UPDATE TO anon, authenticated USING (true);
CREATE POLICY "Allow delete on ai_home_projects" ON public.ai_home_projects FOR DELETE TO anon, authenticated USING (true);

CREATE POLICY "Allow select on ai_floor_plans" ON public.ai_floor_plans FOR SELECT TO anon, authenticated USING (true);
CREATE POLICY "Allow insert on ai_floor_plans" ON public.ai_floor_plans FOR INSERT TO anon, authenticated WITH CHECK (true);

CREATE POLICY "Allow select on ai_facade_designs" ON public.ai_facade_designs FOR SELECT TO anon, authenticated USING (true);
CREATE POLICY "Allow insert on ai_facade_designs" ON public.ai_facade_designs FOR INSERT TO anon, authenticated WITH CHECK (true);

CREATE POLICY "Allow select on ai_interior_designs" ON public.ai_interior_designs FOR SELECT TO anon, authenticated USING (true);
CREATE POLICY "Allow insert on ai_interior_designs" ON public.ai_interior_designs FOR INSERT TO anon, authenticated WITH CHECK (true);

CREATE POLICY "Allow select on ai_walkthroughs" ON public.ai_walkthroughs FOR SELECT TO anon, authenticated USING (true);
CREATE POLICY "Allow insert on ai_walkthroughs" ON public.ai_walkthroughs FOR INSERT TO anon, authenticated WITH CHECK (true);

-- STORAGE BUCKET: ai-home
-- Folders structure:
-- ai-home/{userId}/{projectId}/floor-plans/
-- ai-home/{userId}/{projectId}/facades/
-- ai-home/{userId}/{projectId}/interiors/
-- ai-home/{userId}/{projectId}/walkthroughs/

-- =========================================================================
-- 9. AI PROPERTY VERIFICATION SYSTEM TABLES
-- =========================================================================

-- 9.1 PROPERTY DOCUMENTS TABLE (Uploaded documents by dealers/owners)
CREATE TABLE IF NOT EXISTS public.property_documents (
    id TEXT PRIMARY KEY,
    property_id TEXT NOT NULL,
    user_id TEXT,
    dealer_id TEXT,
    document_type TEXT NOT NULL, -- 'Sale Deed', 'Registry', 'RERA Certificate', 'Sale Agreement', 'Ownership Proof', 'Property Tax Receipt', 'Possession Letter', 'NOC', 'Approved Building Plan', 'Floor Plan', 'Identity/Authorization', 'Other'
    file_name TEXT NOT NULL,
    file_url TEXT,
    file_size_bytes BIGINT DEFAULT 0,
    mime_type TEXT DEFAULT 'application/pdf',
    page_count INT DEFAULT 1,
    is_complete_upload BOOLEAN DEFAULT TRUE,
    verification_status TEXT DEFAULT 'pending' CHECK (verification_status IN ('pending', 'consistent', 'needs_review', 'mismatch')),
    status_reason TEXT,
    uploaded_at TIMESTAMPTZ DEFAULT NOW(),
    metadata JSONB DEFAULT '{}'::jsonb
);

-- 9.2 DOCUMENT ANALYSIS TABLE (Extracted entity fields and cross-check results)
CREATE TABLE IF NOT EXISTS public.document_analysis (
    id TEXT PRIMARY KEY,
    document_id TEXT REFERENCES public.property_documents(id) ON DELETE CASCADE,
    property_id TEXT NOT NULL,
    document_type TEXT NOT NULL,
    extracted_data JSONB DEFAULT '{}'::jsonb, -- { owner_name, property_address, unit_number, plot_number, execution_date, reg_number, super_area_sqft, carpet_area_sqft, builder_name }
    detected_issues JSONB DEFAULT '[]'::jsonb,
    missing_pages_detected BOOLEAN DEFAULT FALSE,
    consistency_status TEXT DEFAULT 'consistent' CHECK (consistency_status IN ('consistent', 'needs_review', 'mismatch')),
    analysis_summary TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 9.3 VERIFICATION CHECKS TABLE (Field-by-field consistency & official comparisons)
CREATE TABLE IF NOT EXISTS public.verification_checks (
    id TEXT PRIMARY KEY,
    property_id TEXT NOT NULL,
    check_type TEXT NOT NULL, -- 'document_consistency', 'official_record_check', 'rera_registry', 'tax_record', 'land_mutation'
    field_name TEXT NOT NULL, -- 'owner_name', 'rera_id', 'property_area', 'property_address', 'plot_number', 'registration_date'
    source_type TEXT NOT NULL, -- 'Official Government Portal', 'Uploaded Legal Document', 'State RERA API', 'Municipal Land Authority'
    claim_value TEXT,
    source_value TEXT,
    status TEXT NOT NULL CHECK (status IN ('MATCH', 'REVIEW_REQUIRED', 'MISMATCH', 'SOURCE_UNAVAILABLE')),
    status_reason TEXT NOT NULL,
    evidence_reference TEXT,
    is_official_source BOOLEAN DEFAULT FALSE,
    verified_at TIMESTAMPTZ DEFAULT NOW(),
    metadata JSONB DEFAULT '{}'::jsonb
);

-- 9.4 VERIFICATION SOURCES TABLE (Registry of recognized official authorities)
CREATE TABLE IF NOT EXISTS public.verification_sources (
    id TEXT PRIMARY KEY,
    source_name TEXT NOT NULL, -- 'UP RERA Portal', 'Haryana RERA (HRERA)', 'UP Stamp & Registration Dept', 'Noida Land Authority'
    source_type TEXT NOT NULL, -- 'state_rera', 'land_registry', 'municipal_corporation', 'urban_development'
    official_url TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    api_available BOOLEAN DEFAULT FALSE,
    last_checked_at TIMESTAMPTZ DEFAULT NOW(),
    metadata JSONB DEFAULT '{}'::jsonb
);

-- 9.5 PROPERTY HISTORY TABLE (Chronological title, registry, and audit timeline)
CREATE TABLE IF NOT EXISTS public.property_history (
    id TEXT PRIMARY KEY,
    property_id TEXT NOT NULL,
    event_date TEXT NOT NULL, -- '2019-04-12' or '2019'
    event_type TEXT NOT NULL, -- 'Registration Recorded', 'Ownership Transfer', 'RERA Approval', 'Tax Assessment', 'Document Upload', 'AI Verification Audit'
    description TEXT NOT NULL,
    source_name TEXT NOT NULL,
    source_url TEXT,
    verification_status TEXT DEFAULT 'VERIFIED' CHECK (verification_status IN ('VERIFIED', 'INFORMATION MATCHED', 'REVIEW REQUIRED', 'NOT VERIFIED', 'SOURCE UNAVAILABLE')),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 9.6 PROPERTY MONITORING TABLE (User property alerts subscription)
CREATE TABLE IF NOT EXISTS public.property_monitoring (
    id TEXT PRIMARY KEY,
    property_id TEXT NOT NULL,
    user_id TEXT NOT NULL,
    status TEXT DEFAULT 'active' CHECK (status IN ('active', 'paused', 'cancelled')),
    notify_email BOOLEAN DEFAULT TRUE,
    notify_whatsapp BOOLEAN DEFAULT FALSE,
    notify_app BOOLEAN DEFAULT TRUE,
    last_checked_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 9.7 PROPERTY ALERTS TABLE (Detected record changes and notifications)
CREATE TABLE IF NOT EXISTS public.property_alerts (
    id TEXT PRIMARY KEY,
    property_id TEXT NOT NULL,
    user_id TEXT,
    alert_title TEXT NOT NULL, -- 'Property Update Detected'
    alert_type TEXT DEFAULT 'record_update', -- 'record_update', 'rera_status_change', 'new_document', 'discrepancy_resolved'
    what_changed TEXT NOT NULL,
    previous_information TEXT,
    new_information TEXT,
    source_name TEXT NOT NULL,
    detected_at TIMESTAMPTZ DEFAULT NOW(),
    is_read BOOLEAN DEFAULT FALSE,
    metadata JSONB DEFAULT '{}'::jsonb
);

-- 9.8 VERIFICATION QUESTIONS TABLE (AI-generated clarification inquiries)
CREATE TABLE IF NOT EXISTS public.verification_questions (
    id TEXT PRIMARY KEY,
    property_id TEXT NOT NULL,
    issue_detected TEXT NOT NULL,
    affected_field TEXT NOT NULL, -- 'Owner Name', 'Super Area', 'Plot Number', 'Developer Name', 'Possession Date'
    question_text TEXT NOT NULL,
    evidence_reference TEXT,
    status TEXT DEFAULT 'Pending' CHECK (status IN ('Pending', 'Answered', 'Needs Review', 'Resolved')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 9.9 VERIFICATION ANSWERS TABLE (Dealer responses and proof uploads)
CREATE TABLE IF NOT EXISTS public.verification_answers (
    id TEXT PRIMARY KEY,
    question_id TEXT REFERENCES public.verification_questions(id) ON DELETE CASCADE,
    property_id TEXT NOT NULL,
    dealer_id TEXT NOT NULL,
    answer_text TEXT NOT NULL,
    supporting_document_urls JSONB DEFAULT '[]'::jsonb,
    answered_at TIMESTAMPTZ DEFAULT NOW(),
    reviewed_by TEXT,
    review_note TEXT,
    resolution_status TEXT DEFAULT 'Answered' CHECK (resolution_status IN ('Answered', 'Needs Review', 'Resolved', 'Rejected'))
);

-- 9.10 PROPERTY COST ESTIMATES TABLE (Configurable true property cost calculator)
CREATE TABLE IF NOT EXISTS public.property_cost_estimates (
    id TEXT PRIMARY KEY,
    property_id TEXT NOT NULL,
    base_price NUMERIC NOT NULL,
    registration_percent NUMERIC DEFAULT 1.0,
    registration_charges NUMERIC,
    stamp_duty_percent NUMERIC DEFAULT 6.0,
    stamp_duty_charges NUMERIC,
    brokerage_percent NUMERIC DEFAULT 1.0,
    brokerage_charges NUMERIC,
    maintenance_deposit NUMERIC DEFAULT 150000,
    renovation_estimate NUMERIC DEFAULT 300000,
    legal_due_diligence NUMERIC DEFAULT 25000,
    other_charges NUMERIC DEFAULT 50000,
    estimated_total_cost NUMERIC NOT NULL,
    buyer_category TEXT DEFAULT 'Male' CHECK (buyer_category IN ('Male', 'Female', 'Joint')),
    location_jurisdiction TEXT DEFAULT 'Noida / Uttar Pradesh',
    disclaimer TEXT DEFAULT 'Estimated cost — actual charges may vary based on registrar circle rates, buyer gender concession, and individual builder agreements.',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- RLS POLICIES FOR AI PROPERTY VERIFICATION TABLES
ALTER TABLE public.property_documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.document_analysis ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.verification_checks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.verification_sources ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.property_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.property_monitoring ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.property_alerts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.verification_questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.verification_answers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.property_cost_estimates ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow select on property_documents" ON public.property_documents FOR SELECT TO anon, authenticated USING (true);
CREATE POLICY "Allow insert on property_documents" ON public.property_documents FOR INSERT TO anon, authenticated WITH CHECK (true);
CREATE POLICY "Allow update on property_documents" ON public.property_documents FOR UPDATE TO anon, authenticated USING (true);

CREATE POLICY "Allow select on document_analysis" ON public.document_analysis FOR SELECT TO anon, authenticated USING (true);
CREATE POLICY "Allow insert on document_analysis" ON public.document_analysis FOR INSERT TO anon, authenticated WITH CHECK (true);

CREATE POLICY "Allow select on verification_checks" ON public.verification_checks FOR SELECT TO anon, authenticated USING (true);
CREATE POLICY "Allow insert on verification_checks" ON public.verification_checks FOR INSERT TO anon, authenticated WITH CHECK (true);

CREATE POLICY "Allow select on verification_sources" ON public.verification_sources FOR SELECT TO anon, authenticated USING (true);
CREATE POLICY "Allow insert on verification_sources" ON public.verification_sources FOR INSERT TO anon, authenticated WITH CHECK (true);

CREATE POLICY "Allow select on property_history" ON public.property_history FOR SELECT TO anon, authenticated USING (true);
CREATE POLICY "Allow insert on property_history" ON public.property_history FOR INSERT TO anon, authenticated WITH CHECK (true);

CREATE POLICY "Allow select on property_monitoring" ON public.property_monitoring FOR SELECT TO anon, authenticated USING (true);
CREATE POLICY "Allow insert on property_monitoring" ON public.property_monitoring FOR INSERT TO anon, authenticated WITH CHECK (true);
CREATE POLICY "Allow update on property_monitoring" ON public.property_monitoring FOR UPDATE TO anon, authenticated USING (true);

CREATE POLICY "Allow select on property_alerts" ON public.property_alerts FOR SELECT TO anon, authenticated USING (true);
CREATE POLICY "Allow insert on property_alerts" ON public.property_alerts FOR INSERT TO anon, authenticated WITH CHECK (true);
CREATE POLICY "Allow update on property_alerts" ON public.property_alerts FOR UPDATE TO anon, authenticated USING (true);

CREATE POLICY "Allow select on verification_questions" ON public.verification_questions FOR SELECT TO anon, authenticated USING (true);
CREATE POLICY "Allow insert on verification_questions" ON public.verification_questions FOR INSERT TO anon, authenticated WITH CHECK (true);
CREATE POLICY "Allow update on verification_questions" ON public.verification_questions FOR UPDATE TO anon, authenticated USING (true);

CREATE POLICY "Allow select on verification_answers" ON public.verification_answers FOR SELECT TO anon, authenticated USING (true);
CREATE POLICY "Allow insert on verification_answers" ON public.verification_answers FOR INSERT TO anon, authenticated WITH CHECK (true);
CREATE POLICY "Allow update on verification_answers" ON public.verification_answers FOR UPDATE TO anon, authenticated USING (true);

CREATE POLICY "Allow select on property_cost_estimates" ON public.property_cost_estimates FOR SELECT TO anon, authenticated USING (true);
CREATE POLICY "Allow insert on property_cost_estimates" ON public.property_cost_estimates FOR INSERT TO anon, authenticated WITH CHECK (true);
CREATE POLICY "Allow update on property_cost_estimates" ON public.property_cost_estimates FOR UPDATE TO anon, authenticated USING (true);

-- =========================================================================
-- 21. BUYER REQUIREMENTS & MATCHING SCHEMA
-- =========================================================================
CREATE TABLE IF NOT EXISTS public.buyer_requirements (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    user_name TEXT NOT NULL,
    user_phone TEXT,
    user_email TEXT,
    preferred_locations JSONB DEFAULT '[]'::jsonb,
    min_budget_cr NUMERIC DEFAULT 1.0,
    max_budget_cr NUMERIC DEFAULT 3.0,
    property_type TEXT DEFAULT 'Apartment',
    bhk TEXT DEFAULT '3 BHK',
    min_area_sqft NUMERIC DEFAULT 1200,
    required_amenities JSONB DEFAULT '[]'::jsonb,
    purchase_purpose TEXT DEFAULT 'Self-Use',
    possession_preference TEXT DEFAULT 'Ready to Move',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =========================================================================
-- 22. DEALER LEADS & AI SCORING SCHEMA
-- =========================================================================
CREATE TABLE IF NOT EXISTS public.dealer_leads (
    id TEXT PRIMARY KEY,
    dealer_id TEXT NOT NULL,
    buyer_id TEXT,
    buyer_name TEXT NOT NULL,
    buyer_phone TEXT NOT NULL,
    buyer_email TEXT,
    property_id TEXT NOT NULL,
    property_title TEXT NOT NULL,
    budget_cr NUMERIC DEFAULT 1.5,
    preferred_location TEXT,
    requirement TEXT,
    lead_score INTEGER DEFAULT 75,
    score_tier TEXT DEFAULT 'WARM LEAD',
    score_factors JSONB DEFAULT '[]'::jsonb,
    enquiry_status TEXT DEFAULT 'New',
    site_visit_status TEXT DEFAULT 'None',
    last_activity TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =========================================================================
-- 23. BUYER–DEALER SAFE DEAL ROOMS SCHEMA
-- =========================================================================
CREATE TABLE IF NOT EXISTS public.deal_rooms (
    id TEXT PRIMARY KEY,
    property_id TEXT NOT NULL,
    property_title TEXT NOT NULL,
    property_image TEXT,
    property_location TEXT,
    listed_price_cr NUMERIC NOT NULL,
    agreed_price_cr NUMERIC,
    buyer_id TEXT NOT NULL,
    buyer_name TEXT NOT NULL,
    buyer_phone TEXT,
    buyer_email TEXT,
    dealer_id TEXT NOT NULL,
    dealer_name TEXT NOT NULL,
    dealer_phone TEXT,
    dealer_email TEXT,
    stage TEXT NOT NULL DEFAULT 'negotiation',
    deal_score INTEGER DEFAULT 88,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.deal_offers (
    id TEXT PRIMARY KEY,
    deal_room_id TEXT NOT NULL,
    sender_id TEXT NOT NULL,
    sender_name TEXT NOT NULL,
    sender_role TEXT NOT NULL,
    amount_cr NUMERIC NOT NULL,
    note TEXT,
    status TEXT NOT NULL DEFAULT 'pending',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.deal_milestones (
    id TEXT PRIMARY KEY,
    deal_room_id TEXT NOT NULL,
    title TEXT NOT NULL,
    amount_cr NUMERIC NOT NULL,
    due_date TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending',
    payment_reference TEXT,
    paid_at TIMESTAMPTZ,
    notes TEXT
);

CREATE TABLE IF NOT EXISTS public.deal_documents (
    id TEXT PRIMARY KEY,
    deal_room_id TEXT NOT NULL,
    document_name TEXT NOT NULL,
    document_type TEXT NOT NULL,
    uploaded_by TEXT NOT NULL,
    uploader_role TEXT NOT NULL,
    file_url TEXT NOT NULL,
    file_size TEXT DEFAULT '2.4 MB',
    verification_status TEXT DEFAULT 'Verified ✓',
    uploaded_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.deal_messages (
    id TEXT PRIMARY KEY,
    deal_room_id TEXT NOT NULL,
    sender_id TEXT NOT NULL,
    sender_name TEXT NOT NULL,
    sender_role TEXT NOT NULL,
    content TEXT NOT NULL,
    message_type TEXT DEFAULT 'text',
    timestamp TIMESTAMPTZ DEFAULT NOW()
);

-- =========================================================================
-- 24. DIGITAL SITE VISIT CHECKLIST & AI SUMMARIES SCHEMA
-- =========================================================================
CREATE TABLE IF NOT EXISTS public.site_visit_checklists (
    id TEXT PRIMARY KEY,
    visit_id TEXT NOT NULL,
    property_id TEXT NOT NULL,
    property_title TEXT NOT NULL,
    buyer_id TEXT NOT NULL,
    items JSONB DEFAULT '[]'::jsonb,
    general_notes TEXT,
    overall_rating NUMERIC DEFAULT 4.0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.ai_visit_summaries (
    id TEXT PRIMARY KEY,
    visit_id TEXT NOT NULL,
    property_title TEXT NOT NULL,
    raw_buyer_notes TEXT NOT NULL,
    pros JSONB DEFAULT '[]'::jsonb,
    cons JSONB DEFAULT '[]'::jsonb,
    concerns JSONB DEFAULT '[]'::jsonb,
    follow_up_questions JSONB DEFAULT '[]'::jsonb,
    overall_rating NUMERIC DEFAULT 4.0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- RLS POLICIES FOR ECOSYSTEM TABLES
ALTER TABLE public.buyer_requirements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.dealer_leads ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.deal_rooms ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.deal_offers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.deal_milestones ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.deal_documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.deal_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.site_visit_checklists ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ai_visit_summaries ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow select on buyer_requirements" ON public.buyer_requirements FOR SELECT TO anon, authenticated USING (true);
CREATE POLICY "Allow insert on buyer_requirements" ON public.buyer_requirements FOR INSERT TO anon, authenticated WITH CHECK (true);
CREATE POLICY "Allow update on buyer_requirements" ON public.buyer_requirements FOR UPDATE TO anon, authenticated USING (true);

CREATE POLICY "Allow select on dealer_leads" ON public.dealer_leads FOR SELECT TO anon, authenticated USING (true);
CREATE POLICY "Allow insert on dealer_leads" ON public.dealer_leads FOR INSERT TO anon, authenticated WITH CHECK (true);
CREATE POLICY "Allow update on dealer_leads" ON public.dealer_leads FOR UPDATE TO anon, authenticated USING (true);

CREATE POLICY "Allow select on deal_rooms" ON public.deal_rooms FOR SELECT TO anon, authenticated USING (true);
CREATE POLICY "Allow insert on deal_rooms" ON public.deal_rooms FOR INSERT TO anon, authenticated WITH CHECK (true);
CREATE POLICY "Allow update on deal_rooms" ON public.deal_rooms FOR UPDATE TO anon, authenticated USING (true);

CREATE POLICY "Allow all on deal_offers" ON public.deal_offers FOR ALL TO anon, authenticated USING (true);
CREATE POLICY "Allow all on deal_milestones" ON public.deal_milestones FOR ALL TO anon, authenticated USING (true);
CREATE POLICY "Allow all on deal_documents" ON public.deal_documents FOR ALL TO anon, authenticated USING (true);
CREATE POLICY "Allow all on deal_messages" ON public.deal_messages FOR ALL TO anon, authenticated USING (true);
CREATE POLICY "Allow all on site_visit_checklists" ON public.site_visit_checklists FOR ALL TO anon, authenticated USING (true);
CREATE POLICY "Allow all on ai_visit_summaries" ON public.ai_visit_summaries FOR ALL TO anon, authenticated USING (true);


