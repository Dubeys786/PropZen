-- =============================================================================
-- PROPZEN FLYWAY MIGRATION V11: STRICT ROW LEVEL SECURITY & TENANT ISOLATION
-- =============================================================================
-- Target Database: Supabase PostgreSQL (Project eemxylswyvhsyzllcsnp)
-- Purpose: Enable RLS and establish airtight ownership policies for Buyers,
--          Dealers, Service Partners, and Administrators.
-- =============================================================================

-- 1. Helper Functions (Strictly Dynamic, Never Hardcoding Plaintext Admin Emails)
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.users
    WHERE id = auth.uid()
      AND UPPER(TRIM(COALESCE(role, ''))) IN ('ADMIN', 'SUPER_ADMIN', 'ADMINISTRATOR')
  ) OR (
    (auth.jwt() -> 'app_metadata' ->> 'role') IN ('admin', 'super_admin', 'administrator')
  ) OR (
    auth.role() = 'service_role'
  );
$$;

CREATE OR REPLACE FUNCTION public.current_dealer_id()
RETURNS UUID
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT id FROM public.dealer_profiles
  WHERE user_id = auth.uid() AND status = 'APPROVED'
  LIMIT 1;
$$;

CREATE OR REPLACE FUNCTION public.current_service_partner_id()
RETURNS UUID
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT id FROM public.service_partner_profiles
  WHERE user_id = auth.uid() AND partner_status = 'APPROVED'
  LIMIT 1;
$$;

-- =============================================================================
-- 2. ENABLE ROW LEVEL SECURITY ACROSS ALL ENTITIES
-- =============================================================================

ALTER TABLE IF EXISTS public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.dealer_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.service_partner_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.posted_properties ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.crm_leads ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.crm_tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.crm_followups ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.crm_communications ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.crm_contact_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.service_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.service_milestones ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.service_deliverables ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.service_payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.service_feedback ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.service_journey_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.audit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.enquiries ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.site_visits ENABLE ROW LEVEL SECURITY;

-- =============================================================================
-- 3. POLICIES: PUBLIC.USERS
-- =============================================================================
DROP POLICY IF EXISTS "Users can read own profile" ON public.users;
CREATE POLICY "Users can read own profile"
  ON public.users FOR SELECT
  USING (id = auth.uid() OR public.is_admin());

DROP POLICY IF EXISTS "Users can update own profile" ON public.users;
CREATE POLICY "Users can update own profile"
  ON public.users FOR UPDATE
  USING (id = auth.uid() OR public.is_admin())
  WITH CHECK (id = auth.uid() OR public.is_admin());

-- =============================================================================
-- 4. POLICIES: PUBLIC.POSTED_PROPERTIES
-- =============================================================================
DROP POLICY IF EXISTS "Public can view published properties" ON public.posted_properties;
CREATE POLICY "Public can view published properties"
  ON public.posted_properties FOR SELECT
  USING (
    status = 'PUBLISHED'
    OR (dealer_id IS NOT NULL AND dealer_id = public.current_dealer_id())
    OR (owner_id IS NOT NULL AND owner_id = auth.uid())
    OR public.is_admin()
  );

DROP POLICY IF EXISTS "Dealers can insert properties" ON public.posted_properties;
CREATE POLICY "Dealers can insert properties"
  ON public.posted_properties FOR INSERT
  WITH CHECK (
    public.is_admin()
    OR (dealer_id IS NOT NULL AND dealer_id = public.current_dealer_id())
    OR (owner_id IS NOT NULL AND owner_id = auth.uid())
  );

DROP POLICY IF EXISTS "Dealers can update own properties" ON public.posted_properties;
CREATE POLICY "Dealers can update own properties"
  ON public.posted_properties FOR UPDATE
  USING (
    public.is_admin()
    OR (dealer_id IS NOT NULL AND dealer_id = public.current_dealer_id())
    OR (owner_id IS NOT NULL AND owner_id = auth.uid())
  );

-- =============================================================================
-- 5. POLICIES: PUBLIC.CRM_LEADS
-- =============================================================================
DROP POLICY IF EXISTS "CRM Leads Tenant Isolation" ON public.crm_leads;
CREATE POLICY "CRM Leads Tenant Isolation"
  ON public.crm_leads FOR SELECT
  USING (
    public.is_admin()
    OR (dealer_id IS NOT NULL AND dealer_id = public.current_dealer_id())
    OR (assigned_to IS NOT NULL AND assigned_to = auth.uid())
    OR (assigned_partner_id IS NOT NULL AND assigned_partner_id = public.current_service_partner_id())
    OR (user_id IS NOT NULL AND user_id = auth.uid())
  );

DROP POLICY IF EXISTS "CRM Leads Insert Policy" ON public.crm_leads;
CREATE POLICY "CRM Leads Insert Policy"
  ON public.crm_leads FOR INSERT
  WITH CHECK (
    auth.role() = 'authenticated'
    OR auth.role() = 'anon'
    OR public.is_admin()
  );

DROP POLICY IF EXISTS "CRM Leads Update Policy" ON public.crm_leads;
CREATE POLICY "CRM Leads Update Policy"
  ON public.crm_leads FOR UPDATE
  USING (
    public.is_admin()
    OR (dealer_id IS NOT NULL AND dealer_id = public.current_dealer_id())
    OR (assigned_to IS NOT NULL AND assigned_to = auth.uid())
    OR (assigned_partner_id IS NOT NULL AND assigned_partner_id = public.current_service_partner_id())
  );

-- =============================================================================
-- 6. POLICIES: PUBLIC.SERVICE_REQUESTS
-- =============================================================================
DROP POLICY IF EXISTS "Service Requests Isolation" ON public.service_requests;
CREATE POLICY "Service Requests Isolation"
  ON public.service_requests FOR SELECT
  USING (
    public.is_admin()
    OR customer_id = auth.uid()
    OR (partner_id IS NOT NULL AND partner_id = public.current_service_partner_id())
  );

DROP POLICY IF EXISTS "Service Requests Insert" ON public.service_requests;
CREATE POLICY "Service Requests Insert"
  ON public.service_requests FOR INSERT
  WITH CHECK (
    public.is_admin()
    OR customer_id = auth.uid()
  );

DROP POLICY IF EXISTS "Service Requests Update" ON public.service_requests;
CREATE POLICY "Service Requests Update"
  ON public.service_requests FOR UPDATE
  USING (
    public.is_admin()
    OR customer_id = auth.uid()
    OR (partner_id IS NOT NULL AND partner_id = public.current_service_partner_id())
  );

-- =============================================================================
-- 7. POLICIES: PUBLIC.SERVICE_DELIVERABLES & PAYMENTS
-- =============================================================================
DROP POLICY IF EXISTS "Service Deliverables Access" ON public.service_deliverables;
CREATE POLICY "Service Deliverables Access"
  ON public.service_deliverables FOR SELECT
  USING (
    public.is_admin()
    OR EXISTS (
      SELECT 1 FROM public.service_requests sr
      WHERE sr.id = service_deliverables.service_request_id
        AND (sr.customer_id = auth.uid() OR sr.partner_id = public.current_service_partner_id())
    )
  );

DROP POLICY IF EXISTS "Service Payments Access" ON public.service_payments;
CREATE POLICY "Service Payments Access"
  ON public.service_payments FOR SELECT
  USING (
    public.is_admin()
    OR customer_id = auth.uid()
    OR (partner_id IS NOT NULL AND partner_id = public.current_service_partner_id())
  );

-- =============================================================================
-- 8. POLICIES: PUBLIC.NOTIFICATIONS & AUDIT_LOGS
-- =============================================================================
DROP POLICY IF EXISTS "Notifications Isolation" ON public.notifications;
CREATE POLICY "Notifications Isolation"
  ON public.notifications FOR SELECT
  USING (user_id = auth.uid() OR public.is_admin());

CREATE POLICY "Notifications User Update"
  ON public.notifications FOR UPDATE
  USING (user_id = auth.uid() OR public.is_admin());

DROP POLICY IF EXISTS "Audit Logs Admin Only" ON public.audit_logs;
CREATE POLICY "Audit Logs Admin Only"
  ON public.audit_logs FOR SELECT
  USING (public.is_admin());

CREATE POLICY "Audit Logs System Insert"
  ON public.audit_logs FOR INSERT
  WITH CHECK (true);
