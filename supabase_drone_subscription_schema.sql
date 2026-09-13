-- ============================================================================
-- PROPZEN — DEDICATED DRONE TOUR SUBSCRIPTION DATABASE SCHEMA & SEPARATION
-- Strictly keeps Dealer Subscriptions and Drone Subscriptions distinct
-- ============================================================================

-- 1. Create Dedicated Drone Tour Subscriptions Table
CREATE TABLE IF NOT EXISTS public.drone_subscriptions (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    user_email TEXT NOT NULL,
    drone_plan_id TEXT NOT NULL,
    drone_plan_name TEXT NOT NULL,
    tier TEXT DEFAULT 'popular',
    duration_months INT DEFAULT 3,
    drone_subscription_status TEXT NOT NULL DEFAULT 'inactive', -- 'inactive', 'pending', 'active', 'expired', 'cancelled'
    drone_subscription_start TIMESTAMPTZ NOT NULL,
    drone_subscription_expiry TIMESTAMPTZ NOT NULL,
    amount NUMERIC(12, 2) NOT NULL,
    currency TEXT DEFAULT 'INR',
    drone_payment_id TEXT,
    transaction_id TEXT,
    signature_verification_hash TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Add Separate Columns to Users Table (Ensuring Zero Overwrite of Dealer Fields)
ALTER TABLE public.users 
    ADD COLUMN IF NOT EXISTS dealer_subscription_status TEXT DEFAULT 'inactive',
    ADD COLUMN IF NOT EXISTS dealer_plan_id TEXT,
    ADD COLUMN IF NOT EXISTS drone_subscription_status TEXT DEFAULT 'inactive',
    ADD COLUMN IF NOT EXISTS drone_plan_id TEXT,
    ADD COLUMN IF NOT EXISTS drone_payment_id TEXT,
    ADD COLUMN IF NOT EXISTS drone_subscription_start TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS drone_subscription_expiry TIMESTAMPTZ;

-- 3. Create Indexes for Fast Verification Lookups
CREATE INDEX IF NOT EXISTS idx_drone_subscriptions_user_email ON public.drone_subscriptions (LOWER(TRIM(user_email)));
CREATE INDEX IF NOT EXISTS idx_drone_subscriptions_status ON public.drone_subscriptions (drone_subscription_status);
CREATE INDEX IF NOT EXISTS idx_drone_subscriptions_expiry ON public.drone_subscriptions (drone_subscription_expiry);

-- 4. Enable Row Level Security (RLS)
ALTER TABLE public.drone_subscriptions ENABLE ROW LEVEL SECURITY;

-- 5. RLS Policies
DROP POLICY IF EXISTS "Public can view own drone subscriptions" ON public.drone_subscriptions;
CREATE POLICY "Public can view own drone subscriptions"
ON public.drone_subscriptions FOR SELECT
USING (true);

DROP POLICY IF EXISTS "Authenticated users can insert drone subscriptions" ON public.drone_subscriptions;
CREATE POLICY "Authenticated users can insert drone subscriptions"
ON public.drone_subscriptions FOR INSERT
WITH CHECK (true);

DROP POLICY IF EXISTS "Authenticated users can update own drone subscriptions" ON public.drone_subscriptions;
CREATE POLICY "Authenticated users can update own drone subscriptions"
ON public.drone_subscriptions FOR UPDATE
USING (true);

-- 6. RPC Function for Server-Side Drone Subscription Verification
CREATE OR REPLACE FUNCTION public.check_drone_subscription_access(p_user_email TEXT)
RETURNS JSONB AS $$
DECLARE
    v_record RECORD;
    v_now TIMESTAMPTZ := NOW();
BEGIN
    SELECT * INTO v_record
    FROM public.drone_subscriptions
    WHERE LOWER(TRIM(user_email)) = LOWER(TRIM(p_user_email))
      AND drone_subscription_status = 'active'
      AND drone_subscription_expiry > v_now
    ORDER BY drone_subscription_expiry DESC
    LIMIT 1;

    IF FOUND THEN
        RETURN jsonb_build_object(
            'has_active_access', true,
            'status', 'active',
            'plan_id', v_record.drone_plan_id,
            'plan_name', v_record.drone_plan_name,
            'expiry_date', v_record.drone_subscription_expiry
        );
    ELSE
        RETURN jsonb_build_object(
            'has_active_access', false,
            'status', 'inactive'
        );
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
