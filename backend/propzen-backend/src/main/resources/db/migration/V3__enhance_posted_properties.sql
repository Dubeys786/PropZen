-- =============================================================================
-- PROPZEN FLYWAY MIGRATION V3: ENHANCE POSTED PROPERTIES
-- =============================================================================
-- Target Database: Supabase PostgreSQL (Project eemxylswyvhsyzllcsnp)
--
-- Safely adds nullable extension columns to public.posted_properties to support
-- Phase 5 Property Management, Search, Filtering, and Ownership.
-- Adds high-performance B-tree indexes for database-level filter execution.
-- =============================================================================

ALTER TABLE public.posted_properties ADD COLUMN IF NOT EXISTS description TEXT;
ALTER TABLE public.posted_properties ADD COLUMN IF NOT EXISTS locality VARCHAR(255);
ALTER TABLE public.posted_properties ADD COLUMN IF NOT EXISTS dealer_id UUID;
ALTER TABLE public.posted_properties ADD COLUMN IF NOT EXISTS owner_id UUID;
ALTER TABLE public.posted_properties ADD COLUMN IF NOT EXISTS verification_status VARCHAR(50) DEFAULT 'PENDING';
ALTER TABLE public.posted_properties ADD COLUMN IF NOT EXISTS amenities TEXT;
ALTER TABLE public.posted_properties ADD COLUMN IF NOT EXISTS image_url TEXT;
ALTER TABLE public.posted_properties ADD COLUMN IF NOT EXISTS images TEXT;
ALTER TABLE public.posted_properties ADD COLUMN IF NOT EXISTS admin_note TEXT;
ALTER TABLE public.posted_properties ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP;

-- Create performant indexes for database-level exact search & filter queries
CREATE INDEX IF NOT EXISTS idx_posted_properties_city ON public.posted_properties(city);
CREATE INDEX IF NOT EXISTS idx_posted_properties_sector ON public.posted_properties(sector);
CREATE INDEX IF NOT EXISTS idx_posted_properties_prop_type ON public.posted_properties(property_type);
CREATE INDEX IF NOT EXISTS idx_posted_properties_bhk ON public.posted_properties(bhk);
CREATE INDEX IF NOT EXISTS idx_posted_properties_price_cr ON public.posted_properties(price_cr);
CREATE INDEX IF NOT EXISTS idx_posted_properties_sqft ON public.posted_properties(sqft);
CREATE INDEX IF NOT EXISTS idx_posted_properties_status ON public.posted_properties(status);
CREATE INDEX IF NOT EXISTS idx_posted_properties_dealer_id ON public.posted_properties(dealer_id);
CREATE INDEX IF NOT EXISTS idx_posted_properties_owner_id ON public.posted_properties(owner_id);
CREATE INDEX IF NOT EXISTS idx_posted_properties_status_city ON public.posted_properties(status, city);
