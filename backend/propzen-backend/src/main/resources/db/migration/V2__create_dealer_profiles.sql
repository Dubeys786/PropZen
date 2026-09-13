-- =============================================================================
-- PROPZEN FLYWAY MIGRATION V2: CREATE DEALER PROFILES
-- =============================================================================
-- Target Database: Supabase PostgreSQL (Project eemxylswyvhsyzllcsnp)
--
-- Creates the dealer_profiles table linking to public.users(id) with
-- unique constraint on user_id to prevent duplicate active applications.
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.dealer_profiles (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL,
    business_name VARCHAR(255) NOT NULL,
    company_name VARCHAR(255),
    display_name VARCHAR(255),
    phone VARCHAR(50) NOT NULL,
    email VARCHAR(255) NOT NULL,
    description TEXT,
    experience_years INTEGER,
    city VARCHAR(100),
    verification_status VARCHAR(50) NOT NULL DEFAULT 'PENDING',
    status VARCHAR(50) NOT NULL DEFAULT 'PENDING',
    admin_notes TEXT,
    reviewed_by UUID,
    reviewed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_dealer_user FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE,
    CONSTRAINT uq_dealer_user UNIQUE (user_id)
);

CREATE INDEX IF NOT EXISTS idx_dealer_profiles_user_id ON public.dealer_profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_dealer_profiles_status ON public.dealer_profiles(status);
CREATE INDEX IF NOT EXISTS idx_dealer_profiles_verification_status ON public.dealer_profiles(verification_status);
