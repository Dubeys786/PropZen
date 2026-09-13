-- =============================================================================
-- PROPZEN PERSISTENCE SCHEMA & ROW LEVEL SECURITY (RLS) POLICIES
-- Ensures user login session, saved properties, compared properties, and site
-- visits persist authoritatively in Supabase PostgreSQL across browser reloads.
-- =============================================================================

-- Enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =============================================================================
-- 1. SAVED PROPERTIES TABLE (Wishlist / Shortlist)
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.saved_properties (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id TEXT NOT NULL,
    property_id TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    CONSTRAINT uq_saved_properties_user_property UNIQUE (user_id, property_id)
);

-- Indexes for lightning fast lookups
CREATE INDEX IF NOT EXISTS idx_saved_properties_user_id ON public.saved_properties(user_id);
CREATE INDEX IF NOT EXISTS idx_saved_properties_prop_id ON public.saved_properties(property_id);

-- Enable RLS
ALTER TABLE public.saved_properties ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if any
DROP POLICY IF EXISTS "Users can read own saved properties" ON public.saved_properties;
DROP POLICY IF EXISTS "Users can insert own saved properties" ON public.saved_properties;
DROP POLICY IF EXISTS "Users can delete own saved properties" ON public.saved_properties;
DROP POLICY IF EXISTS "Admin full access on saved properties" ON public.saved_properties;

-- RLS Policies: Authenticated users can only read, insert, and delete their own saved properties
CREATE POLICY "Users can read own saved properties"
    ON public.saved_properties
    FOR SELECT
    USING (
        auth.uid()::text = user_id 
        OR (auth.jwt() ->> 'sub') = user_id
        OR (auth.jwt() ->> 'email' = 'dubeysakshi618@gmail.com')
    );

CREATE POLICY "Users can insert own saved properties"
    ON public.saved_properties
    FOR INSERT
    WITH CHECK (
        auth.uid()::text = user_id 
        OR (auth.jwt() ->> 'sub') = user_id
        OR (auth.jwt() ->> 'email' = 'dubeysakshi618@gmail.com')
    );

CREATE POLICY "Users can delete own saved properties"
    ON public.saved_properties
    FOR DELETE
    USING (
        auth.uid()::text = user_id 
        OR (auth.jwt() ->> 'sub') = user_id
        OR (auth.jwt() ->> 'email' = 'dubeysakshi618@gmail.com')
    );

CREATE POLICY "Admin full access on saved properties"
    ON public.saved_properties
    FOR ALL
    USING (auth.jwt() ->> 'email' = 'dubeysakshi618@gmail.com');

-- =============================================================================
-- 2. COMPARED PROPERTIES TABLE (Comparison Matrix)
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.compared_properties (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id TEXT NOT NULL,
    property_id TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    CONSTRAINT uq_compared_properties_user_property UNIQUE (user_id, property_id)
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_compared_properties_user_id ON public.compared_properties(user_id);
CREATE INDEX IF NOT EXISTS idx_compared_properties_prop_id ON public.compared_properties(property_id);

-- Enable RLS
ALTER TABLE public.compared_properties ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if any
DROP POLICY IF EXISTS "Users can read own compared properties" ON public.compared_properties;
DROP POLICY IF EXISTS "Users can insert own compared properties" ON public.compared_properties;
DROP POLICY IF EXISTS "Users can delete own compared properties" ON public.compared_properties;
DROP POLICY IF EXISTS "Admin full access on compared properties" ON public.compared_properties;

CREATE POLICY "Users can read own compared properties"
    ON public.compared_properties
    FOR SELECT
    USING (
        auth.uid()::text = user_id 
        OR (auth.jwt() ->> 'sub') = user_id
        OR (auth.jwt() ->> 'email' = 'dubeysakshi618@gmail.com')
    );

CREATE POLICY "Users can insert own compared properties"
    ON public.compared_properties
    FOR INSERT
    WITH CHECK (
        auth.uid()::text = user_id 
        OR (auth.jwt() ->> 'sub') = user_id
        OR (auth.jwt() ->> 'email' = 'dubeysakshi618@gmail.com')
    );

CREATE POLICY "Users can delete own compared properties"
    ON public.compared_properties
    FOR DELETE
    USING (
        auth.uid()::text = user_id 
        OR (auth.jwt() ->> 'sub') = user_id
        OR (auth.jwt() ->> 'email' = 'dubeysakshi618@gmail.com')
    );

CREATE POLICY "Admin full access on compared properties"
    ON public.compared_properties
    FOR ALL
    USING (auth.jwt() ->> 'email' = 'dubeysakshi618@gmail.com');

-- =============================================================================
-- 3. SITE VISITS TABLE (Guided Tours & Inspections)
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.site_visits (
    id TEXT PRIMARY KEY,
    user_id TEXT,
    property_id TEXT NOT NULL,
    property_title TEXT,
    visitor_name TEXT,
    name TEXT,
    user_name TEXT,
    email TEXT,
    user_email TEXT,
    phone TEXT,
    user_phone TEXT,
    visit_date TEXT NOT NULL,
    visit_time TEXT,
    time_slot TEXT,
    visitor_count INTEGER DEFAULT 1,
    cab_required BOOLEAN DEFAULT false,
    status TEXT DEFAULT 'Pending Confirmation',
    message TEXT DEFAULT '',
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- Ensure user_id column exists if table was created previously without it
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'site_visits' AND column_name = 'user_id'
    ) THEN
        ALTER TABLE public.site_visits ADD COLUMN user_id TEXT;
    END IF;
END $$;

-- Indexes
CREATE INDEX IF NOT EXISTS idx_site_visits_user_id ON public.site_visits(user_id);
CREATE INDEX IF NOT EXISTS idx_site_visits_prop_id ON public.site_visits(property_id);
CREATE INDEX IF NOT EXISTS idx_site_visits_email ON public.site_visits(email);
CREATE INDEX IF NOT EXISTS idx_site_visits_phone ON public.site_visits(phone);

-- Enable RLS
ALTER TABLE public.site_visits ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if any
DROP POLICY IF EXISTS "Users can view own site visits" ON public.site_visits;
DROP POLICY IF EXISTS "Users can insert site visits" ON public.site_visits;
DROP POLICY IF EXISTS "Users can update own site visits" ON public.site_visits;
DROP POLICY IF EXISTS "Admin full access on site visits" ON public.site_visits;

CREATE POLICY "Users can view own site visits"
    ON public.site_visits
    FOR SELECT
    USING (
        auth.uid()::text = user_id 
        OR (auth.jwt() ->> 'sub') = user_id
        OR email = (auth.jwt() ->> 'email')
        OR phone = (auth.jwt() ->> 'phone')
        OR (auth.jwt() ->> 'email' = 'dubeysakshi618@gmail.com')
    );

CREATE POLICY "Users can insert site visits"
    ON public.site_visits
    FOR INSERT
    WITH CHECK (true);

CREATE POLICY "Users can update own site visits"
    ON public.site_visits
    FOR UPDATE
    USING (
        auth.uid()::text = user_id 
        OR (auth.jwt() ->> 'sub') = user_id
        OR (auth.jwt() ->> 'email' = 'dubeysakshi618@gmail.com')
    );

CREATE POLICY "Admin full access on site visits"
    ON public.site_visits
    FOR ALL
    USING (auth.jwt() ->> 'email' = 'dubeysakshi618@gmail.com');
