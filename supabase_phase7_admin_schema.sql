-- =============================================================================
-- PROPNZEN — PHASE 7: ADMIN & BUSINESS COMMAND CENTER SCHEMA
-- =============================================================================

-- 1. Admin Users and Roles Table
CREATE TABLE IF NOT EXISTS public.admin_users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    auth_user_id UUID UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    email TEXT NOT NULL UNIQUE,
    role TEXT NOT NULL DEFAULT 'super_admin', -- 'super_admin', 'property_admin', 'dealer_admin', 'support_admin', 'finance_admin', 'content_admin'
    is_active BOOLEAN NOT NULL DEFAULT true,
    last_login_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Immutable Admin Audit Logs Table (Append-Only)
CREATE TABLE IF NOT EXISTS public.admin_audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    admin_id TEXT NOT NULL,
    admin_name TEXT NOT NULL,
    target_type TEXT NOT NULL, -- 'Property', 'Dealer', 'User', 'Document', 'Payment', 'Subscription', 'Content', 'System'
    target_id TEXT NOT NULL,
    target_title TEXT DEFAULT '',
    action TEXT NOT NULL, -- 'Approved', 'Rejected', 'Correction Requested', 'Suspended', 'Reactivated', 'Overridden', 'Refunded'
    field_changed TEXT DEFAULT 'status',
    old_value TEXT DEFAULT '',
    new_value TEXT DEFAULT '',
    reason TEXT NOT NULL,
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Complaints & User Reports Table
CREATE TABLE IF NOT EXISTS public.complaints_reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    ticket_number TEXT NOT NULL UNIQUE,
    reporter_id TEXT,
    reporter_name TEXT NOT NULL,
    reporter_email TEXT NOT NULL,
    target_type TEXT NOT NULL, -- 'Property', 'Dealer', 'Incorrect Information', 'Payment Issue', 'Site Visit Issue', 'Abuse', 'Technical Issue', 'Other'
    target_id TEXT NOT NULL,
    target_title TEXT NOT NULL,
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'New', -- 'New', 'Under Review', 'Waiting for Information', 'Resolved', 'Rejected'
    priority TEXT NOT NULL DEFAULT 'Medium', -- 'Low', 'Medium', 'High', 'Urgent'
    assigned_admin TEXT,
    resolution_notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    resolved_at TIMESTAMPTZ
);

-- 4. Subscription Plans Dynamic Config Table
CREATE TABLE IF NOT EXISTS public.subscription_plans_config (
    id TEXT PRIMARY KEY,
    plan_name TEXT NOT NULL,
    user_type TEXT NOT NULL DEFAULT 'Dealer', -- 'Dealer', 'NRI'
    description TEXT NOT NULL,
    price_rupees NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
    duration TEXT NOT NULL DEFAULT 'Monthly', -- 'Monthly', 'Quarterly', 'Annual'
    listing_limit INTEGER NOT NULL DEFAULT 10,
    lead_limit INTEGER NOT NULL DEFAULT 50,
    features JSONB DEFAULT '[]'::jsonb,
    is_active BOOLEAN NOT NULL DEFAULT true,
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. Broadcast Announcements Table
CREATE TABLE IF NOT EXISTS public.admin_broadcast_notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    notification_type TEXT NOT NULL DEFAULT 'System',
    audience TEXT NOT NULL DEFAULT 'All Users', -- 'All Users', 'Buyers', 'NRI Users', 'Dealers', 'Verified Dealers', 'Specific Users'
    created_by TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'Sent',
    recipient_count INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 6. System Feature Flags Table
CREATE TABLE IF NOT EXISTS public.system_feature_flags (
    key TEXT PRIMARY KEY,
    is_enabled BOOLEAN NOT NULL DEFAULT true,
    description TEXT,
    updated_by TEXT,
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 7. Row Level Security Policies
ALTER TABLE public.admin_users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.admin_audit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.complaints_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subscription_plans_config ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.admin_broadcast_notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.system_feature_flags ENABLE ROW LEVEL SECURITY;

-- Read policies for public configurations
CREATE POLICY "Allow public read for active subscription plans"
    ON public.subscription_plans_config
    FOR SELECT
    USING (is_active = true);

CREATE POLICY "Allow public read for system feature flags"
    ON public.system_feature_flags
    FOR SELECT
    USING (true);

-- Insert policy for user complaints
CREATE POLICY "Allow authenticated or anon user complaint submission"
    ON public.complaints_reports
    FOR INSERT
    WITH CHECK (true);

-- Audit logs are strictly append-only (No DELETE or UPDATE allowed)
CREATE POLICY "Allow insert audit log"
    ON public.admin_audit_logs
    FOR INSERT
    WITH CHECK (true);

CREATE POLICY "Allow admin read audit logs"
    ON public.admin_audit_logs
    FOR SELECT
    USING (true);
