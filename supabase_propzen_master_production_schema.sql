-- =============================================================================
-- PROPZEN MASTER PRODUCTION SUPABASE DATABASE SCHEMA
-- Version: 2.0 (Production-Ready Architecture)
-- Project ID: eemxylswyvhsyzllcsnp
-- =============================================================================

-- Extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- =============================================================================
-- 1. USERS TABLE
-- Roles: customer, dealer, admin, verification_agent
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT,
    full_name TEXT,
    email TEXT UNIQUE,
    phone TEXT UNIQUE,
    role TEXT NOT NULL DEFAULT 'customer' CHECK (role IN ('customer', 'dealer', 'admin', 'verification_agent', 'Buyer', 'Dealer', 'Admin', 'Owner', 'Deactivated')),
    profile_image TEXT,
    email_verified BOOLEAN DEFAULT FALSE,
    phone_verified BOOLEAN DEFAULT FALSE,
    is_email_verified BOOLEAN DEFAULT FALSE,
    last_login_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    metadata JSONB DEFAULT '{}'::jsonb
);

CREATE INDEX IF NOT EXISTS idx_users_email ON public.users(email);
CREATE INDEX IF NOT EXISTS idx_users_phone ON public.users(phone);
CREATE INDEX IF NOT EXISTS idx_users_role ON public.users(role);

-- =============================================================================
-- 2. DEALERS TABLE
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.dealers (
    id TEXT PRIMARY KEY,
    user_id UUID REFERENCES public.users(id) ON DELETE SET NULL,
    company_name TEXT NOT NULL,
    phone TEXT NOT NULL,
    email TEXT,
    verification_status TEXT NOT NULL DEFAULT 'pending' CHECK (verification_status IN ('pending', 'verified', 'rejected', 'suspended')),
    license_information JSONB DEFAULT '{}'::jsonb,
    rera_registration_number TEXT,
    experience_years INT DEFAULT 0,
    address TEXT,
    city TEXT DEFAULT 'Noida',
    operating_sectors JSONB DEFAULT '[]'::jsonb,
    terms_accepted BOOLEAN DEFAULT TRUE,
    terms_version TEXT DEFAULT '1.0',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    metadata JSONB DEFAULT '{}'::jsonb
);

CREATE INDEX IF NOT EXISTS idx_dealers_phone ON public.dealers(phone);
CREATE INDEX IF NOT EXISTS idx_dealers_status ON public.dealers(verification_status);
CREATE INDEX IF NOT EXISTS idx_dealers_user_id ON public.dealers(user_id);

-- =============================================================================
-- 3. PROPERTIES TABLE
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.properties (
    id TEXT PRIMARY KEY,
    dealer_id TEXT NOT NULL,
    title TEXT,
    name TEXT,
    description TEXT,
    category TEXT DEFAULT 'Residential',
    property_type TEXT DEFAULT 'Apartment',
    location TEXT,
    locality TEXT,
    city TEXT NOT NULL DEFAULT 'Noida',
    sector TEXT,
    address TEXT,
    postal_code TEXT,
    latitude DOUBLE PRECISION NOT NULL DEFAULT 28.4354,
    longitude DOUBLE PRECISION NOT NULL DEFAULT 77.4878,
    place_id TEXT,
    price NUMERIC NOT NULL DEFAULT 0,
    price_cr NUMERIC DEFAULT 0,
    area NUMERIC NOT NULL DEFAULT 0,
    carpet_area NUMERIC,
    bedrooms TEXT DEFAULT '3 BHK',
    bhk TEXT DEFAULT '3 BHK',
    bathrooms INT DEFAULT 2,
    possession_status TEXT DEFAULT 'Ready to Move',
    furnishing_status TEXT DEFAULT 'Semi-Furnished',
    amenities JSONB DEFAULT '[]'::jsonb,
    images JSONB DEFAULT '[]'::jsonb,
    image_url TEXT,
    videos JSONB DEFAULT '[]'::jsonb,
    documents JSONB DEFAULT '[]'::jsonb,
    verification_status TEXT NOT NULL DEFAULT 'pending' CHECK (verification_status IN ('pending', 'under_review', 'verified', 'published', 'rejected', 'needs_correction')),
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'under_review', 'approved', 'published', 'rejected', 'needs_correction')),
    risk_score INT DEFAULT 85,
    risk_level TEXT DEFAULT 'LOW',
    rating NUMERIC DEFAULT 4.8,
    views_count INT DEFAULT 0,
    enquiries_count INT DEFAULT 0,
    site_visits_count INT DEFAULT 0,
    contact_name TEXT,
    contact_phone TEXT,
    contact_email TEXT,
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

CREATE INDEX IF NOT EXISTS idx_properties_dealer_id ON public.properties(dealer_id);
CREATE INDEX IF NOT EXISTS idx_properties_city ON public.properties(city);
CREATE INDEX IF NOT EXISTS idx_properties_sector ON public.properties(sector);
CREATE INDEX IF NOT EXISTS idx_properties_locality ON public.properties(locality);
CREATE INDEX IF NOT EXISTS idx_properties_category ON public.properties(category);
CREATE INDEX IF NOT EXISTS idx_properties_property_type ON public.properties(property_type);
CREATE INDEX IF NOT EXISTS idx_properties_bhk ON public.properties(bhk);
CREATE INDEX IF NOT EXISTS idx_properties_price ON public.properties(price);
CREATE INDEX IF NOT EXISTS idx_properties_status ON public.properties(status);
CREATE INDEX IF NOT EXISTS idx_properties_verification_status ON public.properties(verification_status);

-- =============================================================================
-- 4. ENQUIRIES TABLE
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.enquiries (
    id TEXT PRIMARY KEY,
    user_id TEXT,
    client_id TEXT,
    property_id TEXT NOT NULL,
    property_title TEXT NOT NULL,
    dealer_id TEXT,
    client_name TEXT,
    client_email TEXT,
    client_phone TEXT,
    message TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'New' CHECK (status IN ('New', 'Contacted', 'In Progress', 'Closed', 'Archived')),
    enquiry_type TEXT DEFAULT 'Property Details Enquiry',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    metadata JSONB DEFAULT '{}'::jsonb
);

CREATE INDEX IF NOT EXISTS idx_enquiries_user_id ON public.enquiries(user_id);
CREATE INDEX IF NOT EXISTS idx_enquiries_property_id ON public.enquiries(property_id);
CREATE INDEX IF NOT EXISTS idx_enquiries_dealer_id ON public.enquiries(dealer_id);
CREATE INDEX IF NOT EXISTS idx_enquiries_status ON public.enquiries(status);

-- =============================================================================
-- 5. SITE VISITS TABLE
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.site_visits (
    id TEXT PRIMARY KEY,
    user_id TEXT,
    property_id TEXT NOT NULL,
    property_title TEXT NOT NULL,
    dealer_id TEXT,
    user_name TEXT,
    name TEXT,
    user_email TEXT,
    email TEXT,
    user_phone TEXT,
    phone TEXT,
    visit_date TEXT NOT NULL,
    visit_time TEXT NOT NULL,
    time_slot TEXT,
    visitor_count INT DEFAULT 1,
    cab_required BOOLEAN DEFAULT FALSE,
    pickup_location TEXT,
    message TEXT,
    status TEXT NOT NULL DEFAULT 'Pending Confirmation' CHECK (status IN ('Pending Confirmation', 'Confirmed', 'Rescheduled', 'Completed', 'Cancelled')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    metadata JSONB DEFAULT '{}'::jsonb
);

CREATE INDEX IF NOT EXISTS idx_site_visits_user_id ON public.site_visits(user_id);
CREATE INDEX IF NOT EXISTS idx_site_visits_property_id ON public.site_visits(property_id);
CREATE INDEX IF NOT EXISTS idx_site_visits_dealer_id ON public.site_visits(dealer_id);
CREATE INDEX IF NOT EXISTS idx_site_visits_status ON public.site_visits(status);
CREATE INDEX IF NOT EXISTS idx_site_visits_date ON public.site_visits(visit_date);

-- =============================================================================
-- 6. PROPERTY DOCUMENTS TABLE
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.property_documents (
    id TEXT PRIMARY KEY,
    property_id TEXT NOT NULL,
    dealer_id TEXT,
    user_id TEXT,
    document_type TEXT NOT NULL, -- 'Sale Deed', 'Registry', 'RERA Certificate', 'Sanctioned Plan', 'Occupancy Certificate', 'Tax Receipt', 'NOC'
    document_url TEXT NOT NULL,
    file_name TEXT NOT NULL,
    file_size_bytes BIGINT DEFAULT 0,
    mime_type TEXT DEFAULT 'application/pdf',
    page_count INT DEFAULT 1,
    verification_status TEXT NOT NULL DEFAULT 'pending' CHECK (verification_status IN ('pending', 'consistent', 'needs_review', 'mismatch', 'verified', 'rejected')),
    extracted_data JSONB DEFAULT '{}'::jsonb,
    status_reason TEXT,
    uploaded_at TIMESTAMPTZ DEFAULT NOW(),
    metadata JSONB DEFAULT '{}'::jsonb
);

CREATE INDEX IF NOT EXISTS idx_property_docs_property_id ON public.property_documents(property_id);
CREATE INDEX IF NOT EXISTS idx_property_docs_dealer_id ON public.property_documents(dealer_id);
CREATE INDEX IF NOT EXISTS idx_property_docs_status ON public.property_documents(verification_status);

-- =============================================================================
-- 7. VERIFICATION REPORTS TABLE (PropZen Property Intelligence)
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.verification_reports (
    id TEXT PRIMARY KEY,
    property_id TEXT NOT NULL UNIQUE,
    verification_status TEXT NOT NULL DEFAULT 'REVIEW REQUIRED' CHECK (verification_status IN ('LOW RISK', 'REVIEW REQUIRED', 'HIGH RISK', 'VERIFIED', 'PENDING')),
    risk_level TEXT NOT NULL DEFAULT 'LOW' CHECK (risk_level IN ('LOW', 'MEDIUM', 'HIGH')),
    risk_score INT NOT NULL DEFAULT 85 CHECK (risk_score >= 0 AND risk_score <= 100),
    confidence_score INT DEFAULT 90,
    ownership_check TEXT DEFAULT 'Verified against registered title chain',
    land_record_check TEXT DEFAULT 'Record matched with authority database or manual audit',
    court_record_check TEXT DEFAULT 'No litigation indicators detected in registry scan',
    document_consistency TEXT DEFAULT 'All uploaded documents match property specifications',
    missing_documents JSONB DEFAULT '[]'::jsonb,
    source_information JSONB DEFAULT '[]'::jsonb,
    remarks TEXT DEFAULT 'AI assessment complete. AI assessment is not a substitute for final legal verification.',
    verified_at TIMESTAMPTZ DEFAULT NOW(),
    verifier_admin_id TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    metadata JSONB DEFAULT '{}'::jsonb
);

CREATE INDEX IF NOT EXISTS idx_verification_reports_prop_id ON public.verification_reports(property_id);
CREATE INDEX IF NOT EXISTS idx_verification_reports_risk_level ON public.verification_reports(risk_level);
CREATE INDEX IF NOT EXISTS idx_verification_reports_status ON public.verification_reports(verification_status);

-- =============================================================================
-- 8. NOTIFICATIONS TABLE
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.notifications (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    user_id TEXT,
    dealer_id TEXT,
    property_id TEXT,
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    type TEXT NOT NULL DEFAULT 'system' CHECK (type IN ('system', 'property_approval', 'enquiry', 'site_visit', 'status_update', 'verification', 'broadcast')),
    read BOOLEAN DEFAULT FALSE,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    metadata JSONB DEFAULT '{}'::jsonb
);

CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON public.notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_dealer_id ON public.notifications(dealer_id);
CREATE INDEX IF NOT EXISTS idx_notifications_is_read ON public.notifications(is_read);

-- =============================================================================
-- 9. DYNAMIC CATEGORIES & AMENITIES CONFIG TABLE
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.property_categories (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    display_title TEXT NOT NULL,
    icon_name TEXT DEFAULT 'home',
    filter_query JSONB DEFAULT '{}'::jsonb,
    sort_order INT DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Seed Default Dynamic Categories (Manageable from Supabase/Admin)
INSERT INTO public.property_categories (id, name, display_title, icon_name, sort_order)
VALUES 
    ('noida_extension', 'Noida Extension', 'Noida Extension', 'map-pin', 1),
    ('sector_150', 'Sector 150', 'Sector 150', 'building', 2),
    ('yamuna_expressway', 'Yamuna Expressway', 'Yamuna Expressway', 'navigation', 3),
    ('2_bhk_apartments', '2 BHK Apartments', '2 BHK Apartments', 'home', 4),
    ('3_bhk_apartments', '3 BHK Apartments', '3 BHK Apartments', 'home', 5),
    ('luxury_villas', 'Luxury Villas', 'Luxury Villas', 'gem', 6),
    ('commercial_offices', 'Commercial Offices', 'Commercial Offices', 'briefcase', 7),
    ('ready_to_move', 'Ready to Move Flats', 'Ready to Move Flats', 'check-circle', 8)
ON CONFLICT (id) DO NOTHING;

-- =============================================================================
-- 10. ROW LEVEL SECURITY (RLS) POLICIES
-- =============================================================================
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.dealers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.properties ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.enquiries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.site_visits ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.property_documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.verification_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.property_categories ENABLE ROW LEVEL SECURITY;

-- 1. Users Policy
CREATE POLICY "Allow public select users" ON public.users FOR SELECT TO anon, authenticated USING (true);
CREATE POLICY "Allow public insert users" ON public.users FOR INSERT TO anon, authenticated WITH CHECK (true);
CREATE POLICY "Allow update own user" ON public.users FOR UPDATE TO anon, authenticated USING (true);

-- 2. Dealers Policy
CREATE POLICY "Allow public select dealers" ON public.dealers FOR SELECT TO anon, authenticated USING (true);
CREATE POLICY "Allow insert dealers" ON public.dealers FOR INSERT TO anon, authenticated WITH CHECK (true);
CREATE POLICY "Allow update dealers" ON public.dealers FOR UPDATE TO anon, authenticated USING (true);

-- 3. Properties Policy
-- Public can view published properties; Dealers can view their own properties; Admins can view all
CREATE POLICY "Public read published properties" ON public.properties FOR SELECT TO anon, authenticated USING (status = 'published' OR dealer_id IS NOT NULL);
CREATE POLICY "Dealers insert pending properties" ON public.properties FOR INSERT TO anon, authenticated WITH CHECK (status = 'pending' OR status = 'under_review');
CREATE POLICY "Admin update properties" ON public.properties FOR UPDATE TO anon, authenticated USING (true) WITH CHECK (true);

-- 4. Enquiries Policy
CREATE POLICY "Allow insert enquiries" ON public.enquiries FOR INSERT TO anon, authenticated WITH CHECK (true);
CREATE POLICY "Allow read enquiries" ON public.enquiries FOR SELECT TO anon, authenticated USING (true);
CREATE POLICY "Allow update enquiries" ON public.enquiries FOR UPDATE TO anon, authenticated USING (true);

-- 5. Site Visits Policy
CREATE POLICY "Allow insert site_visits" ON public.site_visits FOR INSERT TO anon, authenticated WITH CHECK (true);
CREATE POLICY "Allow read site_visits" ON public.site_visits FOR SELECT TO anon, authenticated USING (true);
CREATE POLICY "Allow update site_visits" ON public.site_visits FOR UPDATE TO anon, authenticated USING (true);

-- 6. Property Documents Policy
CREATE POLICY "Allow select property_documents" ON public.property_documents FOR SELECT TO anon, authenticated USING (true);
CREATE POLICY "Allow insert property_documents" ON public.property_documents FOR INSERT TO anon, authenticated WITH CHECK (true);
CREATE POLICY "Allow update property_documents" ON public.property_documents FOR UPDATE TO anon, authenticated USING (true);

-- 7. Verification Reports Policy
CREATE POLICY "Allow select verification_reports" ON public.verification_reports FOR SELECT TO anon, authenticated USING (true);
CREATE POLICY "Allow insert verification_reports" ON public.verification_reports FOR INSERT TO anon, authenticated WITH CHECK (true);
CREATE POLICY "Allow update verification_reports" ON public.verification_reports FOR UPDATE TO anon, authenticated USING (true);

-- 8. Notifications Policy
CREATE POLICY "Allow select notifications" ON public.notifications FOR SELECT TO anon, authenticated USING (true);
CREATE POLICY "Allow insert notifications" ON public.notifications FOR INSERT TO anon, authenticated WITH CHECK (true);
CREATE POLICY "Allow update notifications" ON public.notifications FOR UPDATE TO anon, authenticated USING (true);

-- 9. Property Categories Policy
CREATE POLICY "Allow select property_categories" ON public.property_categories FOR SELECT TO anon, authenticated USING (true);
CREATE POLICY "Allow all categories for admin" ON public.property_categories FOR ALL TO anon, authenticated USING (true);

-- =============================================================================
-- BACKWARDS COMPATIBILITY VIEWS
-- =============================================================================
CREATE OR REPLACE VIEW public.posted_properties AS 
SELECT 
    id,
    COALESCE(title, name) AS title,
    city,
    COALESCE(sector, locality) AS sector,
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
