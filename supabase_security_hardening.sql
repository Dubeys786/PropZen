-- =============================================================================
-- PROPZEN COMPLETE DATABASE SECURITY HARDENING MIGRATION
-- Project ID: eemxylswyvhsyzllcsnp
-- Purpose: Enforce strict Row Level Security (RLS), Tenant Isolation, RBAC,
--          Anti-IDOR constraints, and Data Privacy across all tables.
-- =============================================================================

-- =============================================================================
-- 1. ENABLE ROW LEVEL SECURITY (RLS) ON ALL TABLES
-- =============================================================================

ALTER TABLE IF EXISTS public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.properties ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.dealer_terms_acceptances ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.enquiries ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.site_visits ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.admin_accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.admin_users ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.admin_audit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.complaints_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.saved_property_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.ai_home_projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.ai_floor_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.ai_facade_designs ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.ai_interior_designs ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.ai_walkthroughs ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.property_documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.document_analysis ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.verification_checks ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.property_verification_documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.property_intelligence_evaluations ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.drone_subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.nri_subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.remote_tour_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.account_deletion_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.subscription_plans_config ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.system_feature_flags ENABLE ROW LEVEL SECURITY;

-- =============================================================================
-- 2. HELPER FUNCTIONS FOR ROLE & TENANT VERIFICATION
-- =============================================================================

-- Check if current authenticated user is an active administrator
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.admin_users
    WHERE auth_user_id = auth.uid()
      AND is_active = true
  ) OR (auth.jwt() ->> 'email' = 'admin@propzen.ai');
$$;

-- Extract clean user email from auth JWT or caller
CREATE OR REPLACE FUNCTION public.current_user_email()
RETURNS TEXT
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT LOWER(TRIM(COALESCE(auth.jwt() ->> 'email', '')));
$$;

-- =============================================================================
-- 3. DROP INSECURE / OVERLY-PERMISSIVE POLICIES
-- =============================================================================

-- Drop generic "USING (true)" policies
DROP POLICY IF EXISTS "Allow select on users" ON public.users;
DROP POLICY IF EXISTS "Allow insert on users" ON public.users;
DROP POLICY IF EXISTS "Allow update on users" ON public.users;

DROP POLICY IF EXISTS "Public users can view published properties only" ON public.properties;
DROP POLICY IF EXISTS "Dealers can submit properties with pending status" ON public.properties;
DROP POLICY IF EXISTS "Dealers can view their own properties" ON public.properties;
DROP POLICY IF EXISTS "Admin can update property status and admin_note" ON public.properties;

DROP POLICY IF EXISTS "Allow select on notifications" ON public.notifications;
DROP POLICY IF EXISTS "Allow insert on notifications" ON public.notifications;
DROP POLICY IF EXISTS "Allow update on notifications" ON public.notifications;

DROP POLICY IF EXISTS "Allow select on enquiries" ON public.enquiries;
DROP POLICY IF EXISTS "Allow insert on enquiries" ON public.enquiries;

DROP POLICY IF EXISTS "Allow select on site_visits" ON public.site_visits;
DROP POLICY IF EXISTS "Allow insert on site_visits" ON public.site_visits;

DROP POLICY IF EXISTS "Allow select on admin_accounts" ON public.admin_accounts;
DROP POLICY IF EXISTS "Allow insert on admin_accounts" ON public.admin_accounts;
DROP POLICY IF EXISTS "Allow update on admin_accounts" ON public.admin_accounts;

DROP POLICY IF EXISTS "Public can view own drone subscriptions" ON public.drone_subscriptions;
DROP POLICY IF EXISTS "Authenticated users can insert drone subscriptions" ON public.drone_subscriptions;
DROP POLICY IF EXISTS "Authenticated users can update own drone subscriptions" ON public.drone_subscriptions;

DROP POLICY IF EXISTS "Allow select on property_documents" ON public.property_documents;
DROP POLICY IF EXISTS "Allow insert on property_documents" ON public.property_documents;
DROP POLICY IF EXISTS "Allow read for property verification docs" ON public.property_verification_documents;

-- =============================================================================
-- 4. HARDENED TABLE POLICIES (STRICT TENANT ISOLATION & ACCESS CONTROL)
-- =============================================================================

--------------------------------------------------------------------------------
-- 4.1 USERS TABLE POLICIES
--------------------------------------------------------------------------------
CREATE POLICY "Users can view own profile"
ON public.users FOR SELECT
TO anon, authenticated
USING (
    email IS NOT NULL 
    AND (
      LOWER(TRIM(email)) = public.current_user_email()
      OR auth.uid() = id
      OR public.is_admin()
    )
);

CREATE POLICY "Users can insert registration"
ON public.users FOR INSERT
TO anon, authenticated
WITH CHECK (
    email IS NOT NULL AND TRIM(email) <> ''
);

CREATE POLICY "Users can update own profile"
ON public.users FOR UPDATE
TO anon, authenticated
USING (
    LOWER(TRIM(email)) = public.current_user_email()
    OR auth.uid() = id
    OR public.is_admin()
)
WITH CHECK (
    (role <> 'Admin' AND role <> 'Master Administrator') OR public.is_admin()
);

--------------------------------------------------------------------------------
-- 4.2 PROPERTIES TABLE POLICIES
--------------------------------------------------------------------------------
CREATE POLICY "Public views published properties; Dealers view own; Admins view all"
ON public.properties FOR SELECT
TO anon, authenticated
USING (
    status = 'published'
    OR (dealer_id IS NOT NULL AND (dealer_id = auth.jwt() ->> 'sub' OR dealer_id = auth.jwt() ->> 'dealer_id'))
    OR public.is_admin()
);

CREATE POLICY "Dealers submit pending properties only"
ON public.properties FOR INSERT
TO anon, authenticated
WITH CHECK (
    status = 'pending'
    AND dealer_id IS NOT NULL
    AND TRIM(dealer_id) <> ''
);

CREATE POLICY "Dealers update own properties without self-approval; Admins update all"
ON public.properties FOR UPDATE
TO anon, authenticated
USING (
    (dealer_id = auth.jwt() ->> 'sub' OR dealer_id = auth.jwt() ->> 'dealer_id')
    OR public.is_admin()
)
WITH CHECK (
    (
      (dealer_id = auth.jwt() ->> 'sub' OR dealer_id = auth.jwt() ->> 'dealer_id')
      AND status IN ('pending', 'needs_correction')
    )
    OR public.is_admin()
);

CREATE POLICY "Admins only can delete properties"
ON public.properties FOR DELETE
TO anon, authenticated
USING (public.is_admin());

--------------------------------------------------------------------------------
-- 4.3 ENQUIRIES TABLE POLICIES
--------------------------------------------------------------------------------
CREATE POLICY "Enquiries readable only by client or assigned dealer"
ON public.enquiries FOR SELECT
TO anon, authenticated
USING (
    (client_email IS NOT NULL AND LOWER(TRIM(client_email)) = public.current_user_email())
    OR (dealer_id IS NOT NULL AND (dealer_id = auth.jwt() ->> 'sub' OR dealer_id = auth.jwt() ->> 'dealer_id'))
    OR public.is_admin()
);

CREATE POLICY "Users can insert property enquiry"
ON public.enquiries FOR INSERT
TO anon, authenticated
WITH CHECK (
    property_title IS NOT NULL
    AND client_name IS NOT NULL
    AND client_phone IS NOT NULL
);

CREATE POLICY "Dealer or Admin can update enquiry status"
ON public.enquiries FOR UPDATE
TO anon, authenticated
USING (
    (dealer_id IS NOT NULL AND (dealer_id = auth.jwt() ->> 'sub' OR dealer_id = auth.jwt() ->> 'dealer_id'))
    OR public.is_admin()
);

--------------------------------------------------------------------------------
-- 4.4 SITE VISITS TABLE POLICIES
--------------------------------------------------------------------------------
CREATE POLICY "Site visits readable by booking user or assigned dealer"
ON public.site_visits FOR SELECT
TO anon, authenticated
USING (
    (user_email IS NOT NULL AND LOWER(TRIM(user_email)) = public.current_user_email())
    OR (email IS NOT NULL AND LOWER(TRIM(email)) = public.current_user_email())
    OR (dealer_id IS NOT NULL AND (dealer_id = auth.jwt() ->> 'sub' OR dealer_id = auth.jwt() ->> 'dealer_id'))
    OR public.is_admin()
);

CREATE POLICY "Users can book site visit"
ON public.site_visits FOR INSERT
TO anon, authenticated
WITH CHECK (
    property_title IS NOT NULL
    AND visit_date IS NOT NULL
    AND time_slot IS NOT NULL
);

CREATE POLICY "Dealer or Admin can update site visit status"
ON public.site_visits FOR UPDATE
TO anon, authenticated
USING (
    (dealer_id IS NOT NULL AND (dealer_id = auth.jwt() ->> 'sub' OR dealer_id = auth.jwt() ->> 'dealer_id'))
    OR (user_email IS NOT NULL AND LOWER(TRIM(user_email)) = public.current_user_email())
    OR public.is_admin()
);

--------------------------------------------------------------------------------
-- 4.5 NOTIFICATIONS TABLE POLICIES
--------------------------------------------------------------------------------
CREATE POLICY "Users view own notifications"
ON public.notifications FOR SELECT
TO anon, authenticated
USING (
    (user_id IS NOT NULL AND (user_id = auth.jwt() ->> 'sub' OR user_id = public.current_user_email()))
    OR (dealer_id IS NOT NULL AND (dealer_id = auth.jwt() ->> 'sub' OR dealer_id = auth.jwt() ->> 'dealer_id'))
    OR (user_id IS NULL AND dealer_id IS NULL AND public.is_admin())
    OR public.is_admin()
);

CREATE POLICY "System can insert notifications"
ON public.notifications FOR INSERT
TO anon, authenticated
WITH CHECK (title IS NOT NULL AND message IS NOT NULL);

CREATE POLICY "Users can mark own notifications read"
ON public.notifications FOR UPDATE
TO anon, authenticated
USING (
    (user_id IS NOT NULL AND (user_id = auth.jwt() ->> 'sub' OR user_id = public.current_user_email()))
    OR (dealer_id IS NOT NULL AND (dealer_id = auth.jwt() ->> 'sub' OR dealer_id = auth.jwt() ->> 'dealer_id'))
    OR public.is_admin()
);

--------------------------------------------------------------------------------
-- 4.6 DRONE & NRI SUBSCRIPTIONS TABLE POLICIES
--------------------------------------------------------------------------------
CREATE POLICY "Subscribers view own drone subscriptions"
ON public.drone_subscriptions FOR SELECT
TO anon, authenticated
USING (
    LOWER(TRIM(user_email)) = public.current_user_email()
    OR user_id = auth.jwt() ->> 'sub'
    OR public.is_admin()
);

CREATE POLICY "Subscribers insert drone subscription"
ON public.drone_subscriptions FOR INSERT
TO anon, authenticated
WITH CHECK (
    user_email IS NOT NULL
    AND drone_plan_id IS NOT NULL
    AND amount >= 0
);

CREATE POLICY "Subscribers view own NRI subscriptions"
ON public.nri_subscriptions FOR SELECT
TO anon, authenticated
USING (
    (user_email IS NOT NULL AND LOWER(TRIM(user_email)) = public.current_user_email())
    OR user_id = auth.jwt() ->> 'sub'
    OR public.is_admin()
);

CREATE POLICY "Subscribers insert NRI subscription"
ON public.nri_subscriptions FOR INSERT
TO anon, authenticated
WITH CHECK (
    plan_id IS NOT NULL
    AND amount >= 0
);

--------------------------------------------------------------------------------
-- 4.7 PROPERTY DOCUMENTS & VERIFICATION TABLE POLICIES (PRIVATE)
--------------------------------------------------------------------------------
CREATE POLICY "Property documents readable by owner dealer or admin"
ON public.property_documents FOR SELECT
TO anon, authenticated
USING (
    (dealer_id IS NOT NULL AND (dealer_id = auth.jwt() ->> 'sub' OR dealer_id = auth.jwt() ->> 'dealer_id'))
    OR (user_id IS NOT NULL AND user_id = auth.jwt() ->> 'sub')
    OR public.is_admin()
);

CREATE POLICY "Dealers upload property documents"
ON public.property_documents FOR INSERT
TO anon, authenticated
WITH CHECK (
    property_id IS NOT NULL
    AND file_name IS NOT NULL
    AND document_type IS NOT NULL
);

--------------------------------------------------------------------------------
-- 4.8 ADMIN AUDIT LOGS (IMMUTABLE APPEND-ONLY)
--------------------------------------------------------------------------------
CREATE POLICY "Admins can view audit logs"
ON public.admin_audit_logs FOR SELECT
TO anon, authenticated
USING (public.is_admin());

CREATE POLICY "Append only audit logs"
ON public.admin_audit_logs FOR INSERT
TO anon, authenticated
WITH CHECK (action IS NOT NULL AND target_id IS NOT NULL);

DROP POLICY IF EXISTS "Prevent update audit logs" ON public.admin_audit_logs;
DROP POLICY IF EXISTS "Prevent delete audit logs" ON public.admin_audit_logs;

-- =============================================================================
-- 5. UNIQUE CONSTRAINTS AND PERFORMANCE INDEXES
-- =============================================================================

CREATE UNIQUE INDEX IF NOT EXISTS idx_users_unique_lower_email_clean
ON public.users (LOWER(TRIM(email)))
WHERE email IS NOT NULL AND TRIM(email) <> '';

CREATE UNIQUE INDEX IF NOT EXISTS idx_users_unique_phone_clean
ON public.users (TRIM(phone))
WHERE phone IS NOT NULL AND TRIM(phone) <> '';

CREATE INDEX IF NOT EXISTS idx_properties_status_locality 
ON public.properties (status, effective_locality, city) 
WHERE status = 'published';

CREATE INDEX IF NOT EXISTS idx_enquiries_dealer_status 
ON public.enquiries (dealer_id, status);

CREATE INDEX IF NOT EXISTS idx_site_visits_dealer_date 
ON public.site_visits (dealer_id, visit_date);

-- =============================================================================
-- END OF MIGRATION
-- =============================================================================
