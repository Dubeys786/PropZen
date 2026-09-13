-- =============================================================================
-- PROPZEN — SERVICE PARTNER IDENTITY, PROFILES & SPECIALIZATION RLS SCHEMA
-- =============================================================================

-- 1. Create table service_partner_profiles if not exists
CREATE TABLE IF NOT EXISTS public.service_partner_profiles (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL UNIQUE,
    business_name TEXT NOT NULL,
    service_category TEXT NOT NULL CHECK (
        service_category IN (
            'LOAN',
            'HOME_DESIGN',
            'VASTU',
            'CONSTRUCTION',
            'PROPERTY_VERIFICATION',
            'VIRTUAL_3D'
        )
    ),
    service_categories TEXT[] NOT NULL DEFAULT '{}',
    verification_status TEXT NOT NULL DEFAULT 'PENDING' CHECK (
        verification_status IN (
            'PENDING',
            'UNDER_REVIEW',
            'VERIFIED',
            'APPROVED',
            'REJECTED',
            'SUSPENDED'
        )
    ),
    status TEXT NOT NULL DEFAULT 'PENDING' CHECK (
        status IN (
            'PENDING',
            'ACTIVE',
            'SUSPENDED',
            'INACTIVE'
        )
    ),
    phone TEXT DEFAULT '',
    email TEXT DEFAULT '',
    rating NUMERIC(3, 2) DEFAULT 4.80,
    completed_projects_count INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 2. Indexes for high-throughput lookup & tenant isolation
CREATE INDEX IF NOT EXISTS idx_sp_profiles_user_id ON public.service_partner_profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_sp_profiles_category ON public.service_partner_profiles(service_category);
CREATE INDEX IF NOT EXISTS idx_sp_profiles_status ON public.service_partner_profiles(status);
CREATE INDEX IF NOT EXISTS idx_sp_profiles_verification ON public.service_partner_profiles(verification_status);

-- 3. Row Level Security (RLS)
ALTER TABLE public.service_partner_profiles ENABLE ROW LEVEL SECURITY;

-- 3.1 Service Partners can read and update their own profile
DROP POLICY IF EXISTS "Service partners can view own profile" ON public.service_partner_profiles;
CREATE POLICY "Service partners can view own profile"
    ON public.service_partner_profiles
    FOR SELECT
    USING (
        auth.uid()::text = user_id
        OR auth.jwt() ->> 'email' = 'dubeysakshi618@gmail.com'
    );

DROP POLICY IF EXISTS "Service partners can update own profile" ON public.service_partner_profiles;
CREATE POLICY "Service partners can update own profile"
    ON public.service_partner_profiles
    FOR UPDATE
    USING (
        auth.uid()::text = user_id
        OR auth.jwt() ->> 'email' = 'dubeysakshi618@gmail.com'
    );

DROP POLICY IF EXISTS "Service partners can insert own profile" ON public.service_partner_profiles;
CREATE POLICY "Service partners can insert own profile"
    ON public.service_partner_profiles
    FOR INSERT
    WITH CHECK (
        auth.uid()::text = user_id
        OR auth.jwt() ->> 'email' = 'dubeysakshi618@gmail.com'
    );

-- 3.2 Admin has full governance over all service partner profiles
DROP POLICY IF EXISTS "Admin full access on service_partner_profiles" ON public.service_partner_profiles;
CREATE POLICY "Admin full access on service_partner_profiles"
    ON public.service_partner_profiles
    FOR ALL
    USING (
        auth.jwt() ->> 'email' = 'dubeysakshi618@gmail.com'
    );

-- 4. Seed Reference Records (For Testing & Staging)
INSERT INTO public.service_partner_profiles (
    id, user_id, business_name, service_category, service_categories, verification_status, status, phone, email, rating, completed_projects_count
) VALUES
    ('SP-LOAN-001', 'usr_loan_01', 'FinEase Capital Advisors', 'LOAN', ARRAY['LOAN'], 'VERIFIED', 'ACTIVE', '9822003344', 'loans@finease.com', 4.8, 62),
    ('SP-DESIGN-001', 'usr_design_01', 'Aura Studio & Interior Architects', 'HOME_DESIGN', ARRAY['HOME_DESIGN'], 'VERIFIED', 'ACTIVE', '9811002233', 'contact@aurastudio.com', 4.9, 38),
    ('SP-VASTU-001', 'usr_vastu_01', 'Vedic Living & Energy Sciences', 'VASTU', ARRAY['VASTU'], 'VERIFIED', 'ACTIVE', '9833004455', 'consult@vedicliving.com', 4.9, 41),
    ('SP-CONST-001', 'usr_construction_01', 'Apex Infra & BuildTech', 'CONSTRUCTION', ARRAY['CONSTRUCTION'], 'VERIFIED', 'ACTIVE', '9844005566', 'projects@apexinfra.com', 4.7, 28),
    ('SP-VERIF-001', 'usr_verification_01', 'JurisShield Legal & Title Verification', 'PROPERTY_VERIFICATION', ARRAY['PROPERTY_VERIFICATION'], 'VERIFIED', 'ACTIVE', '9855006677', 'verify@jurisshield.com', 5.0, 85),
    ('SP-VIRT-001', 'usr_virtual3d_01', 'Immerse3D Visuals & Drone Labs', 'VIRTUAL_3D', ARRAY['VIRTUAL_3D'], 'VERIFIED', 'ACTIVE', '9866007788', 'tours@immerse3d.com', 4.9, 53),
    ('SP-MULTI-001', 'usr_multi_01', 'Prime Design & Construction Consortium', 'HOME_DESIGN', ARRAY['HOME_DESIGN', 'CONSTRUCTION'], 'VERIFIED', 'ACTIVE', '9877008899', 'multi@primeconsortium.com', 4.9, 49)
ON CONFLICT (user_id) DO UPDATE SET
    business_name = EXCLUDED.business_name,
    service_category = EXCLUDED.service_category,
    service_categories = EXCLUDED.service_categories,
    verification_status = EXCLUDED.verification_status,
    status = EXCLUDED.status,
    phone = EXCLUDED.phone,
    email = EXCLUDED.email,
    updated_at = NOW();
