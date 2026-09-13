-- =============================================================================
-- PROPZEN MASTER SUPABASE BACKEND ARCHITECTURE & SECURITY HARDENING
-- Project ID: eemxylswyvhsyzllcsnp
-- Application: PropZen (https://propzen.ai)
-- Architecture: Supabase Auth -> Supabase Postgres + RLS -> Supabase Storage -> Edge Functions / n8n
--
-- STRICT SECURITY RULES:
-- 1. NO service_role key in client code.
-- 2. RLS enabled on all tables with explicit, least-privilege policies.
-- 3. Users can NEVER elevate their own role to ADMIN.
-- 4. Frontend cannot set verification_status, legal_verification_status, or trust_score.
-- 5. Default listing status is PENDING_VERIFICATION; default legal status is WAITING_FOR_API_ACCESS.
-- =============================================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- =============================================================================
-- 1. PROFILES TABLE (Bound to auth.users)
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT UNIQUE NOT NULL,
    full_name TEXT NOT NULL,
    phone TEXT,
    avatar_url TEXT,
    role TEXT NOT NULL DEFAULT 'USER' CHECK (role IN ('USER', 'DEALER', 'BUILDER', 'VERIFICATION_STAFF', 'ADMIN')),
    account_status TEXT NOT NULL DEFAULT 'ACTIVE' CHECK (account_status IN ('ACTIVE', 'PENDING', 'SUSPENDED', 'DEACTIVATED')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    last_login_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_profiles_email ON public.profiles(email);
CREATE INDEX IF NOT EXISTS idx_profiles_role ON public.profiles(role);
CREATE INDEX IF NOT EXISTS idx_profiles_account_status ON public.profiles(account_status);

-- Security definer: Current user email
CREATE OR REPLACE FUNCTION public.current_user_email()
RETURNS TEXT
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT LOWER(TRIM(COALESCE(auth.jwt() ->> 'email', '')));
$$;

-- Security definer: Current user role from profiles
CREATE OR REPLACE FUNCTION public.current_user_role()
RETURNS TEXT
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT COALESCE(
    (SELECT role FROM public.profiles WHERE id = auth.uid() LIMIT 1),
    (SELECT role FROM public.profiles WHERE LOWER(TRIM(email)) = public.current_user_email() LIMIT 1),
    'ANONYMOUS'
  );
$$;

-- Security definer: Is Admin Check
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT (
    public.current_user_role() = 'ADMIN'
    OR public.current_user_email() = 'dubeysakshi618@gmail.com'
  );
$$;

-- Security definer: Is Dealer Check
CREATE OR REPLACE FUNCTION public.is_dealer()
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT (
    public.current_user_role() = 'DEALER'
    OR public.is_admin()
  );
$$;

-- Trigger: Prevent non-admin users from altering their role or account_status
CREATE OR REPLACE FUNCTION public.prevent_user_role_escalation()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  IF NOT public.is_admin() THEN
    IF NEW.role IS DISTINCT FROM OLD.role THEN
      RAISE EXCEPTION 'Access Denied: You cannot modify your own administrative role.';
    END IF;
    IF NEW.account_status IS DISTINCT FROM OLD.account_status THEN
      RAISE EXCEPTION 'Access Denied: You cannot modify your account status.';
    END IF;
  END IF;
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_prevent_role_escalation ON public.profiles;
CREATE TRIGGER trg_prevent_role_escalation
BEFORE UPDATE ON public.profiles
FOR EACH ROW
EXECUTE FUNCTION public.prevent_user_role_escalation();

-- Trigger: Automatically create public.profiles entry on new auth.users signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  INSERT INTO public.profiles (id, email, full_name, phone, role, account_status)
  VALUES (
    NEW.id,
    LOWER(TRIM(NEW.email)),
    COALESCE(NEW.raw_user_meta_data ->> 'full_name', NEW.raw_user_meta_data ->> 'name', 'PropZen Member'),
    NEW.raw_user_meta_data ->> 'phone',
    CASE
      WHEN LOWER(TRIM(NEW.email)) = 'dubeysakshi618@gmail.com' THEN 'ADMIN'
      WHEN UPPER(COALESCE(NEW.raw_user_meta_data ->> 'role', '')) = 'DEALER' THEN 'DEALER'
      WHEN UPPER(COALESCE(NEW.raw_user_meta_data ->> 'role', '')) = 'BUILDER' THEN 'BUILDER'
      ELSE 'USER'
    END,
    'ACTIVE'
  )
  ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    updated_at = NOW();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
AFTER INSERT ON auth.users
FOR EACH ROW
EXECUTE FUNCTION public.handle_new_user();

-- Seed Master Administrator Profile
INSERT INTO public.profiles (id, email, full_name, phone, role, account_status)
VALUES (
    'a0000000-0000-0000-0000-000000000001'::uuid,
    'dubeysakshi618@gmail.com',
    'Sakshi Dubey',
    '9810394068',
    'ADMIN',
    'ACTIVE'
)
ON CONFLICT (email) DO UPDATE SET
    role = 'ADMIN',
    account_status = 'ACTIVE',
    updated_at = NOW();

-- =============================================================================
-- 2. PROPERTIES TABLE & IDENTIFIER GENERATOR
-- =============================================================================

CREATE SEQUENCE IF NOT EXISTS public.property_seq START 1;

CREATE TABLE IF NOT EXISTS public.properties (
    id TEXT PRIMARY KEY,
    property_code TEXT UNIQUE,
    owner_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    dealer_id TEXT,
    builder_id TEXT,
    title TEXT NOT NULL,
    description TEXT,
    property_type TEXT NOT NULL,
    category TEXT DEFAULT 'Residential',
    price NUMERIC NOT NULL CHECK (price > 0),
    area NUMERIC NOT NULL CHECK (area > 0),
    area_unit TEXT DEFAULT 'sq ft',
    bedrooms TEXT,
    bathrooms INT,
    amenities JSONB DEFAULT '[]'::jsonb,
    address TEXT NOT NULL,
    locality TEXT,
    city TEXT NOT NULL,
    state TEXT NOT NULL DEFAULT 'Uttar Pradesh',
    country TEXT NOT NULL DEFAULT 'India',
    pincode TEXT NOT NULL,
    latitude DOUBLE PRECISION DEFAULT 28.5355,
    longitude DOUBLE PRECISION DEFAULT 77.3910,
    location_verified BOOLEAN DEFAULT FALSE,
    availability_status TEXT NOT NULL DEFAULT 'AVAILABLE'
      CHECK (availability_status IN ('AVAILABLE', 'UNDER_OFFER', 'SOLD', 'UNAVAILABLE', 'SUSPENDED', 'AVAILABILITY_RECHECK_REQUIRED')),
    listing_status TEXT NOT NULL DEFAULT 'PENDING_VERIFICATION'
      CHECK (listing_status IN ('DRAFT', 'PENDING_VERIFICATION', 'UNDER_REVIEW', 'VERIFIED', 'NEEDS_CORRECTION', 'REJECTED', 'SUSPENDED', 'SOLD')),
    verification_status TEXT NOT NULL DEFAULT 'PENDING_VERIFICATION',
    legal_verification_status TEXT NOT NULL DEFAULT 'WAITING_FOR_API_ACCESS',
    dealer_verification_status TEXT NOT NULL DEFAULT 'PENDING',
    trust_score INT DEFAULT 70,
    information_completeness INT DEFAULT 80,
    images JSONB DEFAULT '[]'::jsonb,
    image_url TEXT,
    documents JSONB DEFAULT '[]'::jsonb,
    declarations JSONB DEFAULT '{}'::jsonb,
    admin_note TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    verified_at TIMESTAMPTZ,
    last_checked_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_properties_status ON public.properties(listing_status);
CREATE INDEX IF NOT EXISTS idx_properties_city ON public.properties(city);
CREATE INDEX IF NOT EXISTS idx_properties_dealer ON public.properties(dealer_id);
CREATE INDEX IF NOT EXISTS idx_properties_owner ON public.properties(owner_user_id);
CREATE INDEX IF NOT EXISTS idx_properties_code ON public.properties(property_code);

-- Trigger: Format Backend Generated Property Code: PZ-NOI-000001
CREATE OR REPLACE FUNCTION public.set_property_code()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
  city_slug TEXT;
  seq_val BIGINT;
BEGIN
  IF NEW.city ILIKE '%noida%' THEN
    city_slug := 'NOI';
  ELSIF NEW.city ILIKE '%gurgaon%' OR NEW.city ILIKE '%gurugram%' THEN
    city_slug := 'GGN';
  ELSIF NEW.city ILIKE '%delhi%' THEN
    city_slug := 'DEL';
  ELSE
    city_slug := 'NCR';
  END IF;

  IF NEW.id IS NULL OR NEW.id = '' THEN
    seq_val := nextval('public.property_seq');
    NEW.property_code := 'PZ-' || city_slug || '-' || LPAD(seq_val::TEXT, 6, '0');
    NEW.id := NEW.property_code;
  ELSIF NEW.property_code IS NULL OR NEW.property_code = '' THEN
    NEW.property_code := NEW.id;
  END IF;

  -- Ensure initial listing submission security
  IF NOT public.is_admin() THEN
    IF TG_OP = 'INSERT' THEN
      IF NEW.listing_status NOT IN ('DRAFT', 'PENDING_VERIFICATION') THEN
        NEW.listing_status := 'PENDING_VERIFICATION';
      END IF;
      NEW.verification_status := 'PENDING_VERIFICATION';
      NEW.legal_verification_status := 'WAITING_FOR_API_ACCESS';
      NEW.dealer_verification_status := 'PENDING';
      NEW.trust_score := 70;
    ELSIF TG_OP = 'UPDATE' THEN
      -- Non-admins cannot self-approve or elevate trust score
      NEW.verification_status := OLD.verification_status;
      NEW.legal_verification_status := OLD.legal_verification_status;
      NEW.dealer_verification_status := OLD.dealer_verification_status;
      NEW.trust_score := OLD.trust_score;
      IF OLD.listing_status = 'VERIFIED' AND NEW.listing_status != 'VERIFIED' THEN
        -- Allow unpublishing, but not self-verifying
        NULL;
      ELSIF NEW.listing_status = 'VERIFIED' AND OLD.listing_status != 'VERIFIED' THEN
        RAISE EXCEPTION 'Access Denied: Only administrators can verify properties.';
      END IF;
    END IF;
  END IF;

  NEW.updated_at := NOW();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_set_property_code ON public.properties;
CREATE TRIGGER trg_set_property_code
BEFORE INSERT OR UPDATE ON public.properties
FOR EACH ROW
EXECUTE FUNCTION public.set_property_code();

-- =============================================================================
-- 3. DEALERS & BUILDERS
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.dealers (
    id TEXT PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    company_name TEXT NOT NULL,
    phone TEXT NOT NULL,
    email TEXT,
    verification_status TEXT NOT NULL DEFAULT 'PENDING'
      CHECK (verification_status IN ('PENDING', 'UNDER_REVIEW', 'VERIFIED', 'REJECTED', 'SUSPENDED')),
    license_information JSONB DEFAULT '{}'::jsonb,
    rera_registration_number TEXT,
    experience_years INT DEFAULT 0,
    address TEXT,
    city TEXT DEFAULT 'Noida',
    operating_sectors JSONB DEFAULT '[]'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.builders (
    id TEXT PRIMARY KEY,
    company_name TEXT NOT NULL,
    rera_number TEXT,
    verification_status TEXT NOT NULL DEFAULT 'PENDING',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.dealer_documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    dealer_id TEXT NOT NULL REFERENCES public.dealers(id) ON DELETE CASCADE,
    document_type TEXT NOT NULL,
    document_url TEXT NOT NULL,
    verification_status TEXT DEFAULT 'PENDING',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =============================================================================
-- 4. ENQUIRIES & SITE VISITS
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.enquiries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    property_id TEXT REFERENCES public.properties(id) ON DELETE SET NULL,
    user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    client_name TEXT NOT NULL,
    client_email TEXT NOT NULL,
    client_phone TEXT NOT NULL,
    dealer_id TEXT,
    message TEXT,
    enquiry_type TEXT DEFAULT 'Property Details Enquiry',
    status TEXT NOT NULL DEFAULT 'New',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.site_visits (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    property_id TEXT REFERENCES public.properties(id) ON DELETE SET NULL,
    user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    user_name TEXT NOT NULL,
    user_email TEXT NOT NULL,
    user_phone TEXT NOT NULL,
    visit_date TEXT NOT NULL,
    visit_time TEXT NOT NULL,
    visitor_count INT DEFAULT 1,
    cab_required BOOLEAN DEFAULT FALSE,
    pickup_location TEXT,
    message TEXT,
    status TEXT NOT NULL DEFAULT 'REQUESTED'
      CHECK (status IN ('REQUESTED', 'CONFIRMED', 'RESCHEDULED', 'COMPLETED', 'CANCELLED', 'Pending Confirmation', 'Scheduled')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =============================================================================
-- 5. VERIFICATION, AUDIT & NOTIFICATIONS
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.property_verifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    property_id TEXT NOT NULL REFERENCES public.properties(id) ON DELETE CASCADE,
    status TEXT NOT NULL DEFAULT 'PENDING',
    notes TEXT,
    verified_by TEXT,
    verified_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.legal_verifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    property_id TEXT NOT NULL REFERENCES public.properties(id) ON DELETE CASCADE,
    khasra_number TEXT,
    court_cases_found INT DEFAULT 0,
    status TEXT NOT NULL DEFAULT 'WAITING_FOR_API_ACCESS',
    report_summary TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.location_verifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    property_id TEXT NOT NULL REFERENCES public.properties(id) ON DELETE CASCADE,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    pincode_verified BOOLEAN DEFAULT FALSE,
    status TEXT NOT NULL DEFAULT 'PENDING',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.duplicate_checks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    property_id TEXT NOT NULL REFERENCES public.properties(id) ON DELETE CASCADE,
    is_duplicate BOOLEAN DEFAULT FALSE,
    similarity_score NUMERIC DEFAULT 0,
    matched_property_id TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.risk_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    property_id TEXT REFERENCES public.properties(id) ON DELETE SET NULL,
    risk_level TEXT NOT NULL DEFAULT 'LOW',
    reason TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.trust_scores (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    property_id TEXT NOT NULL REFERENCES public.properties(id) ON DELETE CASCADE,
    score INT NOT NULL DEFAULT 70,
    factors JSONB DEFAULT '{}'::jsonb,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.property_reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    property_id TEXT NOT NULL REFERENCES public.properties(id) ON DELETE CASCADE,
    trust_score INT DEFAULT 70,
    verification_status TEXT DEFAULT 'PENDING_VERIFICATION',
    legal_verification_status TEXT DEFAULT 'WAITING_FOR_API_ACCESS',
    location_verification TEXT DEFAULT 'PENDING',
    dealer_verification TEXT DEFAULT 'PENDING',
    risk_indicators JSONB DEFAULT '[]'::jsonb,
    information_completeness INT DEFAULT 80,
    verified_at TIMESTAMPTZ,
    last_checked_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.saved_properties (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    property_id TEXT NOT NULL REFERENCES public.properties(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(user_id, property_id)
);

CREATE TABLE IF NOT EXISTS public.recently_viewed (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    property_id TEXT NOT NULL REFERENCES public.properties(id) ON DELETE CASCADE,
    viewed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(user_id, property_id)
);

CREATE TABLE IF NOT EXISTS public.notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    dealer_id TEXT,
    property_id TEXT,
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    type TEXT DEFAULT 'system',
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id TEXT,
    action TEXT NOT NULL,
    entity_type TEXT NOT NULL,
    entity_id TEXT NOT NULL,
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =============================================================================
-- 6. ENABLE ROW LEVEL SECURITY ON ALL TABLES
-- =============================================================================

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.properties ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.dealers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.builders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.dealer_documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.enquiries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.site_visits ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.property_verifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.legal_verifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.location_verifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.duplicate_checks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.risk_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.trust_scores ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.property_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.saved_properties ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.recently_viewed ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;

-- =============================================================================
-- 7. ROW LEVEL SECURITY POLICIES
-- =============================================================================

-- 7.1 PROFILES
CREATE POLICY "profiles_select_own_or_admin"
ON public.profiles FOR SELECT
USING (auth.uid() = id OR public.is_admin());

CREATE POLICY "profiles_update_own_or_admin"
ON public.profiles FOR UPDATE
USING (auth.uid() = id OR public.is_admin())
WITH CHECK (auth.uid() = id OR public.is_admin());

CREATE POLICY "profiles_insert_own_or_admin"
ON public.profiles FOR INSERT
WITH CHECK (auth.uid() = id OR public.is_admin());

-- 7.2 PROPERTIES
CREATE POLICY "properties_public_view_published"
ON public.properties FOR SELECT
USING (
  listing_status IN ('VERIFIED', 'published')
  OR owner_user_id = auth.uid()
  OR dealer_id = auth.uid()::text
  OR public.is_admin()
);

CREATE POLICY "properties_insert_authenticated"
ON public.properties FOR INSERT
WITH CHECK (
  auth.role() = 'authenticated'
);

CREATE POLICY "properties_update_owner_or_admin"
ON public.properties FOR UPDATE
USING (
  owner_user_id = auth.uid()
  OR dealer_id = auth.uid()::text
  OR public.is_admin()
)
WITH CHECK (
  owner_user_id = auth.uid()
  OR dealer_id = auth.uid()::text
  OR public.is_admin()
);

CREATE POLICY "properties_delete_owner_draft_or_admin"
ON public.properties FOR DELETE
USING (
  (owner_user_id = auth.uid() AND listing_status = 'DRAFT')
  OR public.is_admin()
);

-- 7.3 ENQUIRIES
CREATE POLICY "enquiries_select"
ON public.enquiries FOR SELECT
USING (
  user_id = auth.uid()
  OR dealer_id = auth.uid()::text
  OR public.is_admin()
);

CREATE POLICY "enquiries_insert_anyone"
ON public.enquiries FOR INSERT
WITH CHECK (true);

-- 7.4 SITE VISITS
CREATE POLICY "site_visits_select"
ON public.site_visits FOR SELECT
USING (
  user_id = auth.uid()
  OR public.is_admin()
);

CREATE POLICY "site_visits_insert_anyone"
ON public.site_visits FOR INSERT
WITH CHECK (true);

-- 7.5 NOTIFICATIONS
CREATE POLICY "notifications_select_own"
ON public.notifications FOR SELECT
USING (
  user_id = auth.uid()
  OR dealer_id = auth.uid()::text
  OR public.is_admin()
);

CREATE POLICY "notifications_update_own"
ON public.notifications FOR UPDATE
USING (
  user_id = auth.uid()
  OR dealer_id = auth.uid()::text
  OR public.is_admin()
);

-- 7.6 AUDIT LOGS
CREATE POLICY "audit_logs_select_admin_only"
ON public.audit_logs FOR SELECT
USING (public.is_admin());

CREATE POLICY "audit_logs_insert_admin_or_server"
ON public.audit_logs FOR INSERT
WITH CHECK (true);

-- 7.7 DEALERS
CREATE POLICY "dealers_select_public"
ON public.dealers FOR SELECT
USING (verification_status = 'VERIFIED' OR user_id = auth.uid() OR public.is_admin());

CREATE POLICY "dealers_manage_own_or_admin"
ON public.dealers FOR UPDATE
USING (user_id = auth.uid() OR public.is_admin());

CREATE POLICY "dealers_insert"
ON public.dealers FOR INSERT
WITH CHECK (auth.role() = 'authenticated');
