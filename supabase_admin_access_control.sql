-- =============================================================================
-- PROPZEN SECURE ADMIN ACCESS CONTROL & ROLE DEFINITIONS
-- Designated Platform Super Administrator: dubeysakshi618@gmail.com
-- =============================================================================

-- 1. Ensure public.admin_accounts table exists and is strictly configured
CREATE TABLE IF NOT EXISTS public.admin_accounts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT UNIQUE NOT NULL,
  name TEXT NOT NULL DEFAULT 'PropZen Platform Administrator',
  role TEXT NOT NULL DEFAULT 'ADMIN',
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 2. Ensure public.admin_audit_logs table exists
CREATE TABLE IF NOT EXISTS public.admin_audit_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  actor_id TEXT NOT NULL,
  actor_email TEXT NOT NULL,
  actor_role TEXT NOT NULL DEFAULT 'admin',
  action TEXT NOT NULL,
  entity_type TEXT NOT NULL,
  entity_id TEXT NOT NULL,
  metadata JSONB DEFAULT '{}'::jsonb,
  ip_address TEXT DEFAULT 'client_session',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3. Upsert Designated Admin Account in public.admin_accounts
INSERT INTO public.admin_accounts (email, name, role, is_active)
VALUES (
  'dubeysakshi618@gmail.com',
  'Sakshi Dubey',
  'ADMIN',
  true
)
ON CONFLICT (email) DO UPDATE SET
  role = 'ADMIN',
  is_active = true,
  name = 'Sakshi Dubey',
  updated_at = NOW();

-- 4. Ensure public.profiles reflects ADMIN for dubeysakshi618@gmail.com
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'profiles') THEN
    UPDATE public.profiles
    SET role = 'ADMIN', is_email_verified = true, updated_at = NOW()
    WHERE LOWER(TRIM(email)) = 'dubeysakshi618@gmail.com';

    -- Sanitize any other account that claims to be ADMIN back to USER
    UPDATE public.profiles
    SET role = 'USER'
    WHERE LOWER(TRIM(role)) IN ('admin', 'super_admin', 'administrator')
      AND LOWER(TRIM(email)) != 'dubeysakshi618@gmail.com';
  END IF;
END $$;

-- 5. Ensure public.users reflects ADMIN for dubeysakshi618@gmail.com
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'users') THEN
    UPDATE public.users
    SET role = 'ADMIN', is_email_verified = true, updated_at = NOW()
    WHERE LOWER(TRIM(email)) = 'dubeysakshi618@gmail.com';

    -- Sanitize any other account that claims to be ADMIN back to USER
    UPDATE public.users
    SET role = 'USER'
    WHERE LOWER(TRIM(role)) IN ('admin', 'super_admin', 'administrator')
      AND LOWER(TRIM(email)) != 'dubeysakshi618@gmail.com';
  END IF;
END $$;

-- 6. Strict Trigger: Prevent any user other than dubeysakshi618@gmail.com from having role = ADMIN
CREATE OR REPLACE FUNCTION public.enforce_admin_email_constraint()
RETURNS TRIGGER AS $$
BEGIN
  IF (NEW.role IS NOT NULL AND LOWER(TRIM(NEW.role)) IN ('admin', 'super_admin', 'administrator')) THEN
    IF (LOWER(TRIM(NEW.email)) != 'dubeysakshi618@gmail.com') THEN
      RAISE EXCEPTION 'Unauthorized: Only dubeysakshi618@gmail.com is authorized to have administrator privileges.';
    END IF;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply trigger to public.profiles if exists
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'profiles') THEN
    DROP TRIGGER IF EXISTS trg_enforce_admin_email_profiles ON public.profiles;
    CREATE TRIGGER trg_enforce_admin_email_profiles
      BEFORE INSERT OR UPDATE ON public.profiles
      FOR EACH ROW
      EXECUTE FUNCTION public.enforce_admin_email_constraint();
  END IF;
END $$;

-- Apply trigger to public.users if exists
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'users') THEN
    DROP TRIGGER IF EXISTS trg_enforce_admin_email_users ON public.users;
    CREATE TRIGGER trg_enforce_admin_email_users
      BEFORE INSERT OR UPDATE ON public.users
      FOR EACH ROW
      EXECUTE FUNCTION public.enforce_admin_email_constraint();
  END IF;
END $$;

-- 7. Row Level Security (RLS) Configuration
ALTER TABLE public.admin_accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.admin_audit_logs ENABLE ROW LEVEL SECURITY;

-- Allow designated admin full access to admin_accounts
DROP POLICY IF EXISTS "Designated Admin Full Access" ON public.admin_accounts;
CREATE POLICY "Designated Admin Full Access" ON public.admin_accounts
  FOR ALL
  USING (
    LOWER(TRIM(auth.jwt() ->> 'email')) = 'dubeysakshi618@gmail.com'
    OR auth.role() = 'service_role'
  );

-- Allow designated admin full access to audit logs
DROP POLICY IF EXISTS "Designated Admin Audit Access" ON public.admin_audit_logs;
CREATE POLICY "Designated Admin Audit Access" ON public.admin_audit_logs
  FOR ALL
  USING (
    LOWER(TRIM(auth.jwt() ->> 'email')) = 'dubeysakshi618@gmail.com'
    OR auth.role() = 'service_role'
  );

COMMENT ON TABLE public.admin_accounts IS 'Authoritative registry of PropZen platform administrators restricted to dubeysakshi618@gmail.com.';
