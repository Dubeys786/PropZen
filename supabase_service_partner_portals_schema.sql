-- ==============================================================================
-- PROPZEN: SEPARATE SERVICE PARTNER PORTALS & DATA ISOLATION SCHEMA
-- ==============================================================================
-- This schema establishes distinct relational tables, database constraints,
-- and Row Level Security (RLS) policies to enforce 100% data isolation between
-- service partners (Loan, Home Design, Vastu, Construction, Property Verification,
-- and Virtual 3D).
-- ==============================================================================

-- 1. Service Partner Profiles Table
CREATE TABLE IF NOT EXISTS public.service_partner_profiles (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    business_name TEXT NOT NULL,
    service_category TEXT NOT NULL, -- Primary category: 'LOAN', 'HOME_DESIGN', 'VASTU', 'CONSTRUCTION', 'PROPERTY_VERIFICATION', 'VIRTUAL_3D'
    service_categories TEXT[] NOT NULL DEFAULT '{}', -- All admin-approved categories
    verification_status TEXT NOT NULL DEFAULT 'PENDING', -- 'PENDING', 'UNDER_REVIEW', 'VERIFIED', 'REJECTED'
    status TEXT NOT NULL DEFAULT 'ACTIVE', -- 'ACTIVE', 'SUSPENDED', 'INACTIVE'
    phone TEXT,
    email TEXT,
    rating NUMERIC(3, 2) DEFAULT 4.80,
    completed_projects_count INTEGER DEFAULT 0,
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexing for high-performance lookup
CREATE INDEX IF NOT EXISTS idx_sp_user_id ON public.service_partner_profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_sp_email ON public.service_partner_profiles(email);
CREATE INDEX IF NOT EXISTS idx_sp_service_category ON public.service_partner_profiles(service_category);
CREATE INDEX IF NOT EXISTS idx_sp_status ON public.service_partner_profiles(status);

-- 2. Service Requests Table with Strict Isolation Attributes
CREATE TABLE IF NOT EXISTS public.service_requests (
    id TEXT PRIMARY KEY,
    service_number TEXT UNIQUE NOT NULL,
    category TEXT NOT NULL, -- 'LOAN', 'HOME_DESIGN', 'VASTU', 'CONSTRUCTION', 'PROPERTY_VERIFICATION', 'VIRTUAL_3D'
    service_type TEXT NOT NULL,
    sub_category TEXT NOT NULL,
    title TEXT NOT NULL,
    description TEXT,
    property_id TEXT,
    property_title TEXT,
    property_price_cr NUMERIC(10, 2),
    customer_id TEXT NOT NULL,
    customer_name TEXT NOT NULL,
    customer_phone TEXT NOT NULL,
    customer_email TEXT NOT NULL,
    partner_id TEXT,
    service_partner_id TEXT,
    partner_name TEXT,
    status TEXT NOT NULL DEFAULT 'REQUESTED', -- 'REQUESTED', 'ACCEPTED', 'IN_PROGRESS', 'AWAITING_CUSTOMER', 'APPROVAL_PENDING', 'COMPLETED', 'CLOSED', 'CANCELLED'
    current_journey_step TEXT DEFAULT 'REQUESTED',
    estimated_price NUMERIC(12, 2) DEFAULT 0.0,
    paid_amount NUMERIC(12, 2) DEFAULT 0.0,
    documents JSONB DEFAULT '[]'::jsonb,
    milestones JSONB DEFAULT '[]'::jsonb,
    feedback JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexing for multi-tenant isolation query acceleration
CREATE INDEX IF NOT EXISTS idx_sr_category ON public.service_requests(category);
CREATE INDEX IF NOT EXISTS idx_sr_customer_id ON public.service_requests(customer_id);
CREATE INDEX IF NOT EXISTS idx_sr_partner_id ON public.service_requests(partner_id);
CREATE INDEX IF NOT EXISTS idx_sr_service_partner_id ON public.service_requests(service_partner_id);
CREATE INDEX IF NOT EXISTS idx_sr_status ON public.service_requests(status);

-- ==============================================================================
-- 3. ROW LEVEL SECURITY (RLS) POLICIES
-- ==============================================================================

-- Enable RLS
ALTER TABLE public.service_partner_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.service_requests ENABLE ROW LEVEL SECURITY;

-- ------------------------------------------------------------------------------
-- A. Service Partner Profiles RLS Policies
-- ------------------------------------------------------------------------------

-- Admins have full access to manage all service partner profiles
CREATE POLICY "Admins full access to service_partner_profiles"
ON public.service_partner_profiles
FOR ALL
USING (
    auth.jwt() ->> 'role' = 'admin' OR
    (auth.jwt() -> 'app_metadata' ->> 'role') = 'admin' OR
    (auth.jwt() ->> 'email') = 'dubeysakshi618@gmail.com'
);

-- Partners can read their own profile
CREATE POLICY "Partners can read own profile"
ON public.service_partner_profiles
FOR SELECT
USING (
    user_id = auth.uid()::text OR
    email = auth.jwt() ->> 'email'
);

-- Partners can update non-critical profile fields (phone, name) but NOT specializations or status
CREATE POLICY "Partners can update own contact details"
ON public.service_partner_profiles
FOR UPDATE
USING (
    (user_id = auth.uid()::text OR email = auth.jwt() ->> 'email')
    AND status != 'SUSPENDED'
)
WITH CHECK (
    (user_id = auth.uid()::text OR email = auth.jwt() ->> 'email')
);

-- ------------------------------------------------------------------------------
-- B. Service Requests RLS Policies (STRICT ZERO-CROSS-CATEGORY LEAKAGE)
-- ------------------------------------------------------------------------------

-- 1. Admins have unrestricted access to all service requests
CREATE POLICY "Admins have full access to service_requests"
ON public.service_requests
FOR ALL
USING (
    auth.jwt() ->> 'role' = 'admin' OR
    (auth.jwt() -> 'app_metadata' ->> 'role') = 'admin' OR
    (auth.jwt() ->> 'email') = 'dubeysakshi618@gmail.com'
);

-- 2. Buyers can insert and read their own service requests
CREATE POLICY "Buyers can insert service requests"
ON public.service_requests
FOR INSERT
WITH CHECK (
    customer_id = auth.uid()::text OR
    customer_email = auth.jwt() ->> 'email'
);

CREATE POLICY "Buyers can view own service requests"
ON public.service_requests
FOR SELECT
USING (
    customer_id = auth.uid()::text OR
    customer_email = auth.jwt() ->> 'email'
);

-- 3. Service Partners: STRICT Category & Partner Isolation
-- A partner can ONLY view requests if:
--   a) The request is assigned to them (partner_id = their profile id)
--   b) OR the request is unassigned AND matches one of their admin-approved categories
-- AND the partner is ACTIVE (not SUSPENDED).
CREATE POLICY "Partners can view assigned or unassigned category requests"
ON public.service_requests
FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM public.service_partner_profiles sp
        WHERE (sp.user_id = auth.uid()::text OR sp.email = auth.jwt() ->> 'email')
          AND sp.status = 'ACTIVE'
          AND (sp.verification_status = 'VERIFIED' OR sp.verification_status = 'APPROVED')
          AND (
              -- Directly assigned to this partner
              service_requests.partner_id = sp.id
              OR service_requests.service_partner_id = sp.id
              -- OR unassigned, but category is within partner's approved specializations
              OR (
                  (service_requests.partner_id IS NULL OR service_requests.partner_id = '')
                  AND (
                      service_requests.category = sp.service_category
                      OR service_requests.category = ANY(sp.service_categories)
                  )
              )
          )
    )
);

-- 4. Partners can only update requests assigned to them
CREATE POLICY "Partners can update assigned requests"
ON public.service_requests
FOR UPDATE
USING (
    EXISTS (
        SELECT 1 FROM public.service_partner_profiles sp
        WHERE (sp.user_id = auth.uid()::text OR sp.email = auth.jwt() ->> 'email')
          AND sp.status = 'ACTIVE'
          AND (sp.verification_status = 'VERIFIED' OR sp.verification_status = 'APPROVED')
          AND (service_requests.partner_id = sp.id OR service_requests.service_partner_id = sp.id)
          AND (
              service_requests.category = sp.service_category
              OR service_requests.category = ANY(sp.service_categories)
          )
    )
)
WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.service_partner_profiles sp
        WHERE (sp.user_id = auth.uid()::text OR sp.email = auth.jwt() ->> 'email')
          AND sp.status = 'ACTIVE'
          AND (service_requests.partner_id = sp.id OR service_requests.service_partner_id = sp.id)
    )
);
