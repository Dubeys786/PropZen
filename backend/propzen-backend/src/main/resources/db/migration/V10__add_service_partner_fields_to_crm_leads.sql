-- =============================================================================
-- PROPZEN FLYWAY MIGRATION V10: SERVICE PARTNER LEAD ROUTING & CRM INTEGRATION
-- =============================================================================
-- Target Database: Supabase PostgreSQL (Project eemxylswyvhsyzllcsnp) & H2 dev
--
-- Unifies Service Partner leads into the authoritative crm_leads table.
-- Adds category mapping, partner assignment, and assignment lifecycle status.
-- =============================================================================

ALTER TABLE public.crm_leads ADD COLUMN IF NOT EXISTS service_category VARCHAR(100);
ALTER TABLE public.crm_leads ADD COLUMN IF NOT EXISTS assigned_partner_id UUID REFERENCES public.service_partner_profiles(id);
ALTER TABLE public.crm_leads ADD COLUMN IF NOT EXISTS assignment_status VARCHAR(50) DEFAULT 'UNASSIGNED';

CREATE INDEX IF NOT EXISTS idx_crm_leads_service_category ON public.crm_leads(service_category);
CREATE INDEX IF NOT EXISTS idx_crm_leads_assigned_partner_id ON public.crm_leads(assigned_partner_id);
CREATE INDEX IF NOT EXISTS idx_crm_leads_assignment_status ON public.crm_leads(assignment_status);
