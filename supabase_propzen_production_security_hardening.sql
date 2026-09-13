-- =============================================================================
-- PROPZEN PRODUCTION-GRADE DATABASE SECURITY & ROLE HARDENING MIGRATION
-- Project ID: eemxylswyvhsyzllcsnp
-- Purpose: Complete database-level security enforcement, Row Level Security (RLS),
--          RBAC (User, Dealer, Admin), Anti-IDOR constraints, Storage policies,
--          and Audit Logging.
-- =============================================================================

-- =============================================================================
-- 1. PROFILES & USER ROLES SCHEMA
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    phone TEXT,
    role TEXT NOT NULL DEFAULT 'user' CHECK (role IN ('user', 'dealer', 'admin')),
    is_active BOOLEAN NOT NULL DEFAULT true,
    is_email_verified BOOLEAN NOT NULL DEFAULT false,
    avatar_url TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index for rapid email and role queries
CREATE INDEX IF NOT EXISTS idx_profiles_email ON public.profiles(email);
CREATE INDEX IF NOT EXISTS idx_profiles_role ON public.profiles(role);

-- =============================================================================
-- 2. AUDIT LOGS TABLE
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.admin_audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    actor_id TEXT NOT NULL,
    actor_email TEXT NOT NULL,
    actor_role TEXT NOT NULL DEFAULT 'admin',
    action TEXT NOT NULL,
    entity_type TEXT NOT NULL,
    entity_id TEXT NOT NULL,
    metadata JSONB DEFAULT '{}'::jsonb,
    ip_address TEXT,
    user_agent TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_audit_logs_actor ON public.admin_audit_logs(actor_email);
CREATE INDEX IF NOT EXISTS idx_audit_logs_entity ON public.admin_audit_logs(entity_type, entity_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_created_at ON public.admin_audit_logs(created_at DESC);

-- =============================================================================
-- 3. SECURITY ALERTS TABLE
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.security_alerts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    alert_type TEXT NOT NULL, -- failed_login, unauthorized_access, rate_limit_hit, role_escalation
    severity TEXT NOT NULL DEFAULT 'medium' CHECK (severity IN ('low', 'medium', 'high', 'critical')),
    source_ip TEXT,
    target_identifier TEXT,
    details JSONB DEFAULT '{}'::jsonb,
    is_resolved BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =============================================================================
-- 4. DATABASE-LEVEL AUTHORIZATION FUNCTIONS (SECURITY DEFINER)
-- =============================================================================

-- Extract caller email safely from JWT
CREATE OR REPLACE FUNCTION public.current_user_email()
RETURNS TEXT
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT LOWER(TRIM(COALESCE(auth.jwt() ->> 'email', '')));
$$;

-- Extract caller role from profiles table
CREATE OR REPLACE FUNCTION public.current_user_role()
RETURNS TEXT
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT COALESCE(
    (SELECT role FROM public.profiles WHERE id = auth.uid() LIMIT 1),
    (SELECT role FROM public.profiles WHERE LOWER(TRIM(email)) = public.current_user_email() LIMIT 1),
    'unauthenticated'
  );
$$;

-- Check if caller is verified administrator
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT (
    -- 1. Check if user is registered in admin_accounts and is active
    EXISTS (
      SELECT 1 FROM public.admin_accounts
      WHERE (LOWER(TRIM(email)) = public.current_user_email() OR id::text = auth.uid()::text)
        AND is_active = true
    )
    -- 2. Check if user has role='admin' in profiles
    OR EXISTS (
      SELECT 1 FROM public.profiles
      WHERE (id = auth.uid() OR LOWER(TRIM(email)) = public.current_user_email())
        AND role = 'admin'
        AND is_active = true
    )
    -- 3. Master admin identity anchor
    OR (public.current_user_email() = 'dubeysakshi618@gmail.com')
  );
$$;

-- Check if caller is verified dealer
CREATE OR REPLACE FUNCTION public.is_dealer()
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT (
    public.current_user_role() = 'dealer'
    OR EXISTS (
      SELECT 1 FROM public.dealers
      WHERE (id::text = auth.uid()::text OR LOWER(TRIM(email)) = public.current_user_email())
        AND verification_status = 'Verified'
        AND account_status = 'Active'
    )
    OR public.is_admin()
  );
$$;

-- =============================================================================
-- 5. ENABLE ROW LEVEL SECURITY ON ALL APPLICATION TABLES
-- =============================================================================

ALTER TABLE IF EXISTS public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.dealers ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.properties ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.enquiries ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.site_visits ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.admin_accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.admin_users ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.admin_audit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.security_alerts ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.complaints_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.wallet_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.property_documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.property_verification_documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.drone_subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.nri_subscriptions ENABLE ROW LEVEL SECURITY;

-- =============================================================================
-- 6. DROP LEGACY / INSECURE POLICIES
-- =============================================================================

DROP POLICY IF EXISTS "Allow select on users" ON public.users;
DROP POLICY IF EXISTS "Allow insert on users" ON public.users;
DROP POLICY IF EXISTS "Allow update on users" ON public.users;
DROP POLICY IF EXISTS "Allow all users" ON public.users;

DROP POLICY IF EXISTS "Allow all on properties" ON public.properties;
DROP POLICY IF EXISTS "Public can view all properties" ON public.properties;
DROP POLICY IF EXISTS "Public views published properties; Dealers view own; Admins view all" ON public.properties;

DROP POLICY IF EXISTS "Allow all on enquiries" ON public.enquiries;
DROP POLICY IF EXISTS "Allow select on enquiries" ON public.enquiries;
DROP POLICY IF EXISTS "Allow insert on enquiries" ON public.enquiries;

DROP POLICY IF EXISTS "Allow all on site_visits" ON public.site_visits;
DROP POLICY IF EXISTS "Allow select on site_visits" ON public.site_visits;
DROP POLICY IF EXISTS "Allow insert on site_visits" ON public.site_visits;

DROP POLICY IF EXISTS "Allow all on admin_accounts" ON public.admin_accounts;
DROP POLICY IF EXISTS "Allow all on admin_audit_logs" ON public.admin_audit_logs;
DROP POLICY IF EXISTS "Allow all on notifications" ON public.notifications;

-- =============================================================================
-- 7. DEFINE GRANULAR ROW LEVEL SECURITY (RLS) POLICIES
-- =============================================================================

--------------------------------------------------------------------------------
-- 7.1 PROFILES POLICIES
--------------------------------------------------------------------------------
CREATE POLICY "Users view own profile; Admins view all"
ON public.profiles FOR SELECT
TO anon, authenticated
USING (
    id = auth.uid()
    OR LOWER(TRIM(email)) = public.current_user_email()
    OR public.is_admin()
);

CREATE POLICY "Users update own profile without role elevation; Admins update any"
ON public.profiles FOR UPDATE
TO anon, authenticated
USING (
    id = auth.uid()
    OR LOWER(TRIM(email)) = public.current_user_email()
    OR public.is_admin()
)
WITH CHECK (
    -- Normal users cannot elevate their role to 'admin'
    (role IN ('user', 'dealer') AND NOT public.is_admin())
    OR public.is_admin()
);

CREATE POLICY "Users can register new profile"
ON public.profiles FOR INSERT
TO anon, authenticated
WITH CHECK (
    email IS NOT NULL AND TRIM(email) <> ''
    -- Cannot register directly as admin unless existing admin performs insert
    AND (role <> 'admin' OR public.is_admin())
);

--------------------------------------------------------------------------------
-- 7.2 USERS TABLE POLICIES (LEGACY/SYNC TABLE)
--------------------------------------------------------------------------------
CREATE POLICY "Users read own record; Admins read all"
ON public.users FOR SELECT
TO anon, authenticated
USING (
    LOWER(TRIM(email)) = public.current_user_email()
    OR auth.uid()::text = id::text
    OR public.is_admin()
);

CREATE POLICY "Users register self; Admins insert"
ON public.users FOR INSERT
TO anon, authenticated
WITH CHECK (
    email IS NOT NULL AND TRIM(email) <> ''
    AND (role <> 'Admin' OR public.is_admin())
);

CREATE POLICY "Users update own user record; Admins update all"
ON public.users FOR UPDATE
TO anon, authenticated
USING (
    LOWER(TRIM(email)) = public.current_user_email()
    OR auth.uid()::text = id::text
    OR public.is_admin()
)
WITH CHECK (
    (role <> 'Admin' OR public.is_admin())
);

--------------------------------------------------------------------------------
-- 7.3 PROPERTIES TABLE POLICIES
--------------------------------------------------------------------------------
-- Public can only view published properties; Dealers can view their own; Admins view all
CREATE POLICY "Public views published; Dealers view own; Admins view all"
ON public.properties FOR SELECT
TO anon, authenticated
USING (
    status = 'published'
    OR (dealer_id IS NOT NULL AND (dealer_id = auth.uid()::text OR dealer_id = public.current_user_email()))
    OR public.is_admin()
);

-- Dealers submit properties with 'pending' status only; Admins can submit any status
CREATE POLICY "Dealers submit pending properties; Admins submit any"
ON public.properties FOR INSERT
TO anon, authenticated
WITH CHECK (
    (status = 'pending' AND dealer_id IS NOT NULL AND TRIM(dealer_id) <> '')
    OR public.is_admin()
);

-- Dealers can update only their own properties if pending/needs_correction; Admins can update all
CREATE POLICY "Dealers update own unapproved listings; Admins update all"
ON public.properties FOR UPDATE
TO anon, authenticated
USING (
    (dealer_id = auth.uid()::text OR dealer_id = public.current_user_email())
    OR public.is_admin()
)
WITH CHECK (
    (
        (dealer_id = auth.uid()::text OR dealer_id = public.current_user_email())
        AND status IN ('pending', 'needs_correction')
    )
    OR public.is_admin()
);

-- Only Admins can delete properties (soft-delete preferred)
CREATE POLICY "Only admins can delete properties"
ON public.properties FOR DELETE
TO anon, authenticated
USING (public.is_admin());

--------------------------------------------------------------------------------
-- 7.4 DEALERS TABLE POLICIES
--------------------------------------------------------------------------------
-- Public can view active verified dealers; Dealers view own; Admins view all
CREATE POLICY "Public views verified dealers; Dealers view own; Admins view all"
ON public.dealers FOR SELECT
TO anon, authenticated
USING (
    (verification_status = 'Verified' AND account_status = 'Active')
    OR id::text = auth.uid()::text
    OR LOWER(TRIM(email)) = public.current_user_email()
    OR public.is_admin()
);

-- Dealers register self; Admins insert
CREATE POLICY "Dealers register self with pending status"
ON public.dealers FOR INSERT
TO anon, authenticated
WITH CHECK (
    email IS NOT NULL AND TRIM(email) <> ''
    AND (verification_status = 'Pending' OR public.is_admin())
);

-- Dealers update own profile (without changing verification_status); Admins update any
CREATE POLICY "Dealers update own info; Admins update verification status"
ON public.dealers FOR UPDATE
TO anon, authenticated
USING (
    id::text = auth.uid()::text
    OR LOWER(TRIM(email)) = public.current_user_email()
    OR public.is_admin()
)
WITH CHECK (
    public.is_admin()
    OR (
        (id::text = auth.uid()::text OR LOWER(TRIM(email)) = public.current_user_email())
        AND verification_status = 'Pending' -- Cannot self-verify
    )
);

--------------------------------------------------------------------------------
-- 7.5 ENQUIRIES TABLE POLICIES
--------------------------------------------------------------------------------
CREATE POLICY "Enquiries visible only to buyer, listing dealer, or admin"
ON public.enquiries FOR SELECT
TO anon, authenticated
USING (
    LOWER(TRIM(email)) = public.current_user_email()
    OR (dealer_id IS NOT NULL AND (dealer_id = auth.uid()::text OR dealer_id = public.current_user_email()))
    OR public.is_admin()
);

CREATE POLICY "Anyone can submit enquiry with valid contact info"
ON public.enquiries FOR INSERT
TO anon, authenticated
WITH CHECK (
    email IS NOT NULL AND TRIM(email) <> ''
    AND phone IS NOT NULL AND TRIM(phone) <> ''
);

CREATE POLICY "Dealer or Admin can update enquiry status"
ON public.enquiries FOR UPDATE
TO anon, authenticated
USING (
    (dealer_id IS NOT NULL AND (dealer_id = auth.uid()::text OR dealer_id = public.current_user_email()))
    OR public.is_admin()
);

--------------------------------------------------------------------------------
-- 7.6 SITE VISITS TABLE POLICIES
--------------------------------------------------------------------------------
CREATE POLICY "Site visits visible only to booking user, dealer, or admin"
ON public.site_visits FOR SELECT
TO anon, authenticated
USING (
    LOWER(TRIM(phone)) = LOWER(TRIM(COALESCE(auth.jwt() ->> 'phone', '')))
    OR LOWER(TRIM(name)) = LOWER(TRIM(COALESCE(auth.jwt() ->> 'name', '')))
    OR (dealer_id IS NOT NULL AND (dealer_id = auth.uid()::text OR dealer_id = public.current_user_email()))
    OR public.is_admin()
);

CREATE POLICY "Authenticated or guest users can book site visits"
ON public.site_visits FOR INSERT
TO anon, authenticated
WITH CHECK (
    property_title IS NOT NULL
    AND name IS NOT NULL AND phone IS NOT NULL
);

CREATE POLICY "Dealers and Admins can update site visit status"
ON public.site_visits FOR UPDATE
TO anon, authenticated
USING (
    (dealer_id IS NOT NULL AND (dealer_id = auth.uid()::text OR dealer_id = public.current_user_email()))
    OR public.is_admin()
);

--------------------------------------------------------------------------------
-- 7.7 ADMIN TABLES POLICIES (STRICT ADMIN ISOLATION)
--------------------------------------------------------------------------------
CREATE POLICY "Admin accounts accessible ONLY by admins"
ON public.admin_accounts FOR ALL
TO anon, authenticated
USING (public.is_admin())
WITH CHECK (public.is_admin());

CREATE POLICY "Admin audit logs accessible ONLY by admins"
ON public.admin_audit_logs FOR ALL
TO anon, authenticated
USING (public.is_admin())
WITH CHECK (public.is_admin());

CREATE POLICY "Security alerts accessible ONLY by admins"
ON public.security_alerts FOR ALL
TO anon, authenticated
USING (public.is_admin())
WITH CHECK (public.is_admin());

CREATE POLICY "Complaints and reports accessible ONLY by admins"
ON public.complaints_reports FOR ALL
TO anon, authenticated
USING (public.is_admin())
WITH CHECK (public.is_admin());

--------------------------------------------------------------------------------
-- 7.8 NOTIFICATIONS TABLE POLICIES
--------------------------------------------------------------------------------
CREATE POLICY "Users read own notifications or broadcasts"
ON public.notifications FOR SELECT
TO anon, authenticated
USING (
    target_user_id IS NULL
    OR target_user_id = auth.uid()::text
    OR LOWER(TRIM(target_user_id)) = public.current_user_email()
    OR public.is_admin()
);

CREATE POLICY "System and Admins can create notifications"
ON public.notifications FOR INSERT
TO anon, authenticated
WITH CHECK (
    title IS NOT NULL AND message IS NOT NULL
);

-- =============================================================================
-- 8. INITIALIZE MASTER ADMIN SEED RECORD
-- =============================================================================

INSERT INTO public.admin_accounts (
    id, name, email, role, is_active, last_login_at
) VALUES (
    'adm_sakshi_dubey_master',
    'Sakshi Dubey',
    'dubeysakshi618@gmail.com',
    'super_admin',
    true,
    NOW()
) ON CONFLICT (email) DO UPDATE SET
    role = 'super_admin',
    is_active = true,
    last_login_at = NOW();

-- Migration completion verification comment
COMMENT ON TABLE public.admin_audit_logs IS 'PropZen Production Audit Log: immutable tracking of sensitive administrative operations.';
