-- =============================================================================
-- PROPZEN PRODUCTION RELIABILITY, MONITORING, SOC & DR MIGRATION
-- Enterprise Security, Error Tracking, System Health & Disaster Recovery
-- =============================================================================

-- 1. Create system_health_logs table
CREATE TABLE IF NOT EXISTS public.system_health_logs (
    id TEXT PRIMARY KEY,
    component_name TEXT NOT NULL,
    category TEXT NOT NULL,
    status TEXT NOT NULL CHECK (status IN ('healthy', 'degraded', 'down', 'notConfigured')),
    latency_ms INTEGER DEFAULT 0,
    message TEXT,
    checked_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Create system_error_logs table
CREATE TABLE IF NOT EXISTS public.system_error_logs (
    error_fingerprint TEXT PRIMARY KEY,
    error_type TEXT NOT NULL,
    severity TEXT NOT NULL CHECK (severity IN ('info', 'low', 'medium', 'high', 'critical')),
    message TEXT NOT NULL,
    page_or_service TEXT NOT NULL,
    occurrences INTEGER DEFAULT 1,
    first_seen_at TIMESTAMPTZ DEFAULT NOW(),
    last_seen_at TIMESTAMPTZ DEFAULT NOW(),
    status TEXT DEFAULT 'active' CHECK (status IN ('active', 'investigating', 'resolved')),
    stack_snippet TEXT
);

-- 3. Create background_jobs table
CREATE TABLE IF NOT EXISTS public.background_jobs (
    job_id TEXT PRIMARY KEY,
    job_type TEXT NOT NULL,
    status TEXT NOT NULL CHECK (status IN ('queued', 'running', 'completed', 'failed')),
    progress_percent INTEGER DEFAULT 0,
    retry_count INTEGER DEFAULT 0,
    max_retries INTEGER DEFAULT 3,
    target_entity_id TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    completed_at TIMESTAMPTZ,
    error_message TEXT
);

-- 4. Create maintenance_mode_config table
CREATE TABLE IF NOT EXISTS public.maintenance_mode_config (
    id TEXT PRIMARY KEY DEFAULT 'current_config',
    mode TEXT NOT NULL DEFAULT 'off' CHECK (mode IN ('off', 'readOnly', 'limited', 'full')),
    is_enabled BOOLEAN DEFAULT FALSE,
    enabled_by TEXT,
    enabled_at TIMESTAMPTZ,
    reason TEXT DEFAULT 'Operational',
    allow_admin_bypass BOOLEAN DEFAULT TRUE,
    allow_public_browsing BOOLEAN DEFAULT TRUE,
    allow_new_submissions BOOLEAN DEFAULT TRUE,
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. Enable RLS on all monitoring tables
ALTER TABLE public.system_health_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.system_error_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.background_jobs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.maintenance_mode_config ENABLE ROW LEVEL SECURITY;

-- 6. RLS Policies: Restricted to Administrators
DROP POLICY IF EXISTS "Admins manage system_health_logs" ON public.system_health_logs;
CREATE POLICY "Admins manage system_health_logs"
ON public.system_health_logs FOR ALL TO authenticated
USING (public.is_admin()) WITH CHECK (public.is_admin());

DROP POLICY IF EXISTS "Admins manage system_error_logs" ON public.system_error_logs;
CREATE POLICY "Admins manage system_error_logs"
ON public.system_error_logs FOR ALL TO authenticated
USING (public.is_admin()) WITH CHECK (public.is_admin());

DROP POLICY IF EXISTS "Admins manage background_jobs" ON public.background_jobs;
CREATE POLICY "Admins manage background_jobs"
ON public.background_jobs FOR ALL TO authenticated
USING (public.is_admin()) WITH CHECK (public.is_admin());

DROP POLICY IF EXISTS "Public can read maintenance mode" ON public.maintenance_mode_config;
CREATE POLICY "Public can read maintenance mode"
ON public.maintenance_mode_config FOR SELECT TO public
USING (true);

DROP POLICY IF EXISTS "Admins can update maintenance mode" ON public.maintenance_mode_config;
CREATE POLICY "Admins can update maintenance mode"
ON public.maintenance_mode_config FOR ALL TO authenticated
USING (public.is_admin()) WITH CHECK (public.is_admin());
