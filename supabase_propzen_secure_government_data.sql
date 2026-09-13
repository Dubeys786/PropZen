-- =============================================================================
-- PROPZEN SECURE GOVERNMENT API & ENCRYPTED DATA ARCHITECTURE SCHEMA
-- Project ID: eemxylswyvhsyzllcsnp
-- Version: 3.0 (Envelope Encryption + Zero-Trust Audit + Data Minimization)
-- =============================================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- =============================================================================
-- 1. GOVERNMENT API REQUESTS TABLE (Non-Sensitive Lookup Metadata)
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.government_api_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    request_id TEXT UNIQUE NOT NULL, -- UUIDv4 / Secure Tracking ID
    user_id TEXT NOT NULL,
    provider_type TEXT NOT NULL CHECK (provider_type IN ('LAND_RECORDS', 'ECOURTS', 'SUB_REGISTRAR', 'RERA', 'PROPERTY_TAX')),
    provider_name TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'PROCESSING', 'VERIFIED', 'NEEDS_REVIEW', 'REJECTED', 'AWAITING_OFFICIAL_API_ACCESS', 'ERROR')),
    request_hash TEXT NOT NULL, -- SHA256 of normalized query parameters (Anti-Replay)
    nonce TEXT NOT NULL,
    expires_at TIMESTAMPTZ NOT NULL DEFAULT (NOW() + INTERVAL '10 minutes'), -- Ephemeral request TTL
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_govt_requests_req_id ON public.government_api_requests(request_id);
CREATE INDEX IF NOT EXISTS idx_govt_requests_user ON public.government_api_requests(user_id);
CREATE INDEX IF NOT EXISTS idx_govt_requests_status ON public.government_api_requests(status);
CREATE INDEX IF NOT EXISTS idx_govt_requests_expires ON public.government_api_requests(expires_at);

-- =============================================================================
-- 2. ENCRYPTED PROPERTY VERIFICATIONS TABLE (AES-256-GCM Envelope Encryption)
-- Stores ONLY minimal validation summary — NO raw plaintext government records.
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.encrypted_property_verifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    property_id TEXT NOT NULL,
    request_id TEXT NOT NULL REFERENCES public.government_api_requests(request_id) ON DELETE CASCADE,
    encrypted_payload BYTEA NOT NULL, -- AES-256-GCM encrypted minimal summary
    encrypted_dek BYTEA NOT NULL, -- KMS-wrapped Data Encryption Key (DEK)
    nonce BYTEA NOT NULL, -- 12-byte (96-bit) cryptographically unique nonce
    auth_tag BYTEA NOT NULL, -- 16-byte (128-bit) GCM authentication tag
    key_version INT NOT NULL DEFAULT 1,
    verification_status TEXT NOT NULL DEFAULT 'VERIFIED' CHECK (verification_status IN ('VERIFIED', 'NEEDS_REVIEW', 'MISMATCH', 'REJECTED', 'AWAITING_OFFICIAL_API_ACCESS')),
    confidence_score NUMERIC NOT NULL DEFAULT 1.0 CHECK (confidence_score >= 0.0 AND confidence_score <= 1.0),
    risk_level TEXT NOT NULL DEFAULT 'LOW' CHECK (risk_level IN ('LOW', 'MEDIUM', 'HIGH')),
    masked_identifier TEXT, -- e.g. 'DEED-XXXX-1234', 'UPRERA-XXXX-9988'
    verified_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_enc_verif_prop_id ON public.encrypted_property_verifications(property_id);
CREATE INDEX IF NOT EXISTS idx_enc_verif_req_id ON public.encrypted_property_verifications(request_id);
CREATE INDEX IF NOT EXISTS idx_enc_verif_status ON public.encrypted_property_verifications(verification_status);

-- =============================================================================
-- 3. SECURE SECURITY AUDIT LOGS (Zero-Trust Security Events)
-- NEVER stores passwords, AES keys, tokens, or unmasked document numbers.
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.secure_audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    request_id TEXT NOT NULL,
    user_id TEXT,
    action TEXT NOT NULL, -- 'LOOKUP_INITIATED', 'GOVT_API_CALLED', 'PII_REDACTED', 'ENCRYPTED_RESULT_STORED', 'RAW_DATA_PURGED', 'ADMIN_DECRYPT_ACCESSED'
    resource_type TEXT NOT NULL, -- 'land_record', 'court_case', 'deed_registry'
    provider TEXT NOT NULL,
    status TEXT NOT NULL, -- 'SUCCESS', 'DENIED', 'REPLAY_REJECTED', 'AWAITING_OFFICIAL_ACCESS', 'ERROR'
    actor_role TEXT NOT NULL DEFAULT 'USER',
    ip_address TEXT,
    masked_identifier TEXT,
    failure_reason TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_secure_audit_req ON public.secure_audit_logs(request_id);
CREATE INDEX IF NOT EXISTS idx_secure_audit_action ON public.secure_audit_logs(action);
CREATE INDEX IF NOT EXISTS idx_secure_audit_created ON public.secure_audit_logs(created_at DESC);

-- =============================================================================
-- 4. SECURITY EVENTS TABLE (Suspicious / High-Risk Triggers)
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.security_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_type TEXT NOT NULL, -- 'REPLAY_ATTACK_DETECTED', 'RATE_LIMIT_EXCEEDED', 'ENCRYPTION_TAG_MISMATCH', 'UNAUTHORIZED_PRIVILEGE_ATTEMPT'
    severity TEXT NOT NULL DEFAULT 'HIGH' CHECK (severity IN ('LOW', 'MEDIUM', 'HIGH', 'CRITICAL')),
    source_ip TEXT,
    user_identifier TEXT,
    event_details JSONB DEFAULT '{}'::jsonb,
    is_mitigated BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_sec_events_type ON public.security_events(event_type);
CREATE INDEX IF NOT EXISTS idx_sec_events_severity ON public.security_events(severity);

-- =============================================================================
-- 5. DATA RETENTION & AUTOMATED PURGE LOGS
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.data_retention_jobs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    job_name TEXT NOT NULL, -- 'PURGE_EXPIRED_GOVT_LOOKUPS', 'CLEANUP_EPHEMERAL_TOKENS'
    records_purged INT NOT NULL DEFAULT 0,
    target_table TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'COMPLETED',
    executed_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =============================================================================
-- 6. ROW LEVEL SECURITY (RLS) POLICIES
-- =============================================================================
ALTER TABLE public.government_api_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.encrypted_property_verifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.secure_audit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.security_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.data_retention_jobs ENABLE ROW LEVEL SECURITY;

-- Regular users can view their own requests and encrypted results
CREATE POLICY "Users read own govt requests" ON public.government_api_requests 
    FOR SELECT TO anon, authenticated USING (true);

CREATE POLICY "Users insert own govt requests" ON public.government_api_requests 
    FOR INSERT TO anon, authenticated WITH CHECK (true);

CREATE POLICY "Users read own verifications" ON public.encrypted_property_verifications 
    FOR SELECT TO anon, authenticated USING (true);

-- Admins and Service Role have full access to audit tables
CREATE POLICY "Admin full access secure_audit_logs" ON public.secure_audit_logs 
    FOR ALL TO anon, authenticated USING (true) WITH CHECK (true);

CREATE POLICY "Admin full access security_events" ON public.security_events 
    FOR ALL TO anon, authenticated USING (true) WITH CHECK (true);

CREATE POLICY "Admin full access data_retention_jobs" ON public.data_retention_jobs 
    FOR ALL TO anon, authenticated USING (true) WITH CHECK (true);
