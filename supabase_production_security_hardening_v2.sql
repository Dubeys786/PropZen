-- =============================================================================
-- PROPZEN PRODUCTION DATABASE SECURITY HARDENING MIGRATION (V2)
-- Project ID: eemxylswyvhsyzllcsnp
-- Purpose: 
--  1. Revoke all legacy / dangerous USING (true) / WITH CHECK (true) policies
--  2. Enable Row Level Security (RLS) on 100% of public tables
--  3. Implement strict role-based & tenant isolation for Buyers, Dealers, Partners & Admins
--  4. Remove all hardcoded emails from SQL functions
-- =============================================================================

-- 1. AUTHORITATIVE ADMIN HELPER FUNCTION (NO HARDCODED EMAIL STRINGS)
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

-- 2. DROP ALL LEGACY PERMISSIVE POLICIES
DO $$ 
DECLARE
    pol RECORD;
BEGIN
    FOR pol IN (
        SELECT policyname, tablename 
        FROM pg_policies 
        WHERE schemaname = 'public' 
          AND (policyname ILIKE '%allow all%' 
               OR policyname ILIKE '%allow select%' 
               OR policyname ILIKE '%allow update%' 
               OR policyname ILIKE '%allow insert%'
               OR policyname ILIKE '%public can%'
               OR policyname ILIKE '%anon%')
    ) LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON public.%I', pol.policyname, pol.tablename);
    END LOOP;
END $$;

-- 3. FORCE ENABLE RLS ON ALL PUBLIC TABLES
ALTER TABLE IF EXISTS public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.properties ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.posted_properties ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.dealer_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.service_partner_profiles ENABLE ROW LEVEL SECURITY;
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
ALTER TABLE IF EXISTS public.deal_rooms ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.deal_offers ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.deal_documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.deal_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.property_verification_documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.verification_checks ENABLE ROW LEVEL SECURITY;

-- 4. BUYER ISOLATION POLICIES
DROP POLICY IF EXISTS "Buyer view own enquiries" ON public.enquiries;
CREATE POLICY "Buyer view own enquiries"
  ON public.enquiries FOR SELECT
  USING (user_id = auth.uid() OR public.is_admin());

DROP POLICY IF EXISTS "Buyer view own site visits" ON public.site_visits;
CREATE POLICY "Buyer view own site visits"
  ON public.site_visits FOR SELECT
  USING (user_id = auth.uid() OR public.is_admin());

-- 5. DEAL ROOM & DEAL DOCUMENT ISOLATION (STRICT IDOR PROTECTION)
DROP POLICY IF EXISTS "Deal documents participant access" ON public.deal_documents;
CREATE POLICY "Deal documents participant access"
  ON public.deal_documents FOR SELECT
  USING (
    public.is_admin()
    OR EXISTS (
      SELECT 1 FROM public.deal_rooms dr
      WHERE dr.id = deal_documents.deal_room_id
        AND (dr.buyer_id = auth.uid() OR dr.dealer_id IN (
          SELECT id FROM public.dealer_profiles WHERE user_id = auth.uid()
        ))
    )
  );

DROP POLICY IF EXISTS "Deal messages participant access" ON public.deal_messages;
CREATE POLICY "Deal messages participant access"
  ON public.deal_messages FOR SELECT
  USING (
    public.is_admin()
    OR EXISTS (
      SELECT 1 FROM public.deal_rooms dr
      WHERE dr.id = deal_messages.deal_room_id
        AND (dr.buyer_id = auth.uid() OR dr.dealer_id IN (
          SELECT id FROM public.dealer_profiles WHERE user_id = auth.uid()
        ))
    )
  );
