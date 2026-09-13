-- =============================================================================
-- PROPZEN AI INTELLIGENCE, VERIFICATION LIFECYCLE & DEALER CRM MIGRATION
-- Production-Ready Relational Schema, RLS Hardening & Audit Logging
-- =============================================================================

-- 1. Extend properties table with verification, duplicate, and availability fields
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'properties' AND column_name = 'duplicate_status') THEN
        ALTER TABLE public.properties ADD COLUMN duplicate_status TEXT DEFAULT 'normal' CHECK (duplicate_status IN ('normal', 'possible_duplicate', 'confirmed_duplicate'));
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'properties' AND column_name = 'duplicate_of_property_id') THEN
        ALTER TABLE public.properties ADD COLUMN duplicate_of_property_id TEXT REFERENCES public.properties(id) ON DELETE SET NULL;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'properties' AND column_name = 'availability_status') THEN
        ALTER TABLE public.properties ADD COLUMN availability_status TEXT DEFAULT 'Available' CHECK (availability_status IN ('Available', 'Reserved', 'Sold', 'Rented', 'Unavailable'));
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'properties' AND column_name = 'quality_score') THEN
        ALTER TABLE public.properties ADD COLUMN quality_score INTEGER DEFAULT 88;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'properties' AND column_name = 're_review_required') THEN
        ALTER TABLE public.properties ADD COLUMN re_review_required BOOLEAN DEFAULT FALSE;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'properties' AND column_name = 'internal_admin_notes') THEN
        ALTER TABLE public.properties ADD COLUMN internal_admin_notes TEXT;
    END IF;
END $$;

-- 2. Create property_verification_checks table
CREATE TABLE IF NOT EXISTS public.property_verification_checks (
    id TEXT PRIMARY KEY,
    property_id TEXT NOT NULL REFERENCES public.properties(id) ON DELETE CASCADE,
    check_name TEXT NOT NULL,
    category TEXT NOT NULL,
    status TEXT NOT NULL CHECK (status IN ('PENDING', 'PASSED', 'FAILED', 'FLAGGED')),
    verified_by TEXT,
    verified_at TIMESTAMPTZ DEFAULT NOW(),
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Create property_internal_notes table (Private to Admins only)
CREATE TABLE IF NOT EXISTS public.property_internal_notes (
    id TEXT PRIMARY KEY,
    property_id TEXT NOT NULL REFERENCES public.properties(id) ON DELETE CASCADE,
    admin_id TEXT NOT NULL,
    admin_email TEXT NOT NULL,
    note_content TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. Create property_history_events table (Append-only)
CREATE TABLE IF NOT EXISTS public.property_history_events (
    id TEXT PRIMARY KEY,
    property_id TEXT NOT NULL REFERENCES public.properties(id) ON DELETE CASCADE,
    event_type TEXT NOT NULL,
    event_title TEXT NOT NULL,
    old_value TEXT,
    new_value TEXT,
    actor_id TEXT NOT NULL,
    actor_role TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. Create dealer_crm_leads table (Tenant isolated by dealer_id)
CREATE TABLE IF NOT EXISTS public.dealer_crm_leads (
    id TEXT PRIMARY KEY,
    dealer_id TEXT NOT NULL,
    property_id TEXT NOT NULL REFERENCES public.properties(id) ON DELETE CASCADE,
    buyer_id TEXT,
    buyer_name TEXT NOT NULL,
    buyer_phone TEXT NOT NULL,
    buyer_email TEXT,
    status TEXT NOT NULL DEFAULT 'NEW' CHECK (status IN ('NEW', 'CONTACTED', 'FOLLOW_UP', 'SITE_VISIT', 'NEGOTIATION', 'CONVERTED', 'CLOSED', 'LOST')),
    lead_score INTEGER DEFAULT 75,
    lead_tier TEXT DEFAULT 'WARM LEAD',
    notes TEXT,
    follow_up_date TIMESTAMPTZ,
    visitor_count INTEGER DEFAULT 1,
    cab_required BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 6. Create property_price_alerts table
CREATE TABLE IF NOT EXISTS public.property_price_alerts (
    id TEXT PRIMARY KEY,
    property_id TEXT NOT NULL REFERENCES public.properties(id) ON DELETE CASCADE,
    user_id TEXT NOT NULL,
    previous_price NUMERIC NOT NULL,
    new_price NUMERIC NOT NULL,
    alert_status TEXT DEFAULT 'PENDING' CHECK (alert_status IN ('PENDING', 'SENT', 'READ')),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 7. Enable Row Level Security on all tables
ALTER TABLE public.property_verification_checks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.property_internal_notes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.property_history_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.dealer_crm_leads ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.property_price_alerts ENABLE ROW LEVEL SECURITY;

-- 8. RLS Policies: property_internal_notes (Strict Admin Only)
DROP POLICY IF EXISTS "Admins only internal notes" ON public.property_internal_notes;
CREATE POLICY "Admins only internal notes"
ON public.property_internal_notes FOR ALL TO authenticated
USING (public.is_admin()) WITH CHECK (public.is_admin());

-- 9. RLS Policies: dealer_crm_leads (Tenant Isolation)
DROP POLICY IF EXISTS "Dealers view own leads" ON public.dealer_crm_leads;
CREATE POLICY "Dealers view own leads"
ON public.dealer_crm_leads FOR SELECT TO authenticated
USING (
    dealer_id = auth.uid()::text OR 
    EXISTS (SELECT 1 FROM public.dealers d WHERE d.id = dealer_crm_leads.dealer_id AND d.email = auth.jwt() ->> 'email') OR
    public.is_admin()
);

DROP POLICY IF EXISTS "Dealers update own leads" ON public.dealer_crm_leads;
CREATE POLICY "Dealers update own leads"
ON public.dealer_crm_leads FOR UPDATE TO authenticated
USING (
    dealer_id = auth.uid()::text OR 
    EXISTS (SELECT 1 FROM public.dealers d WHERE d.id = dealer_crm_leads.dealer_id AND d.email = auth.jwt() ->> 'email') OR
    public.is_admin()
)
WITH CHECK (
    dealer_id = auth.uid()::text OR 
    EXISTS (SELECT 1 FROM public.dealers d WHERE d.id = dealer_crm_leads.dealer_id AND d.email = auth.jwt() ->> 'email') OR
    public.is_admin()
);

-- 10. RLS Policies: property_price_alerts (User access own alerts)
DROP POLICY IF EXISTS "Users view own price alerts" ON public.property_price_alerts;
CREATE POLICY "Users view own price alerts"
ON public.property_price_alerts FOR SELECT TO authenticated
USING (user_id = auth.uid()::text OR public.is_admin());
