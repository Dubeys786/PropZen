-- ================================================================
-- PROPZEN DATABASE MIGRATION V8: AI INTELLIGENCE & USAGE LOGS
-- ================================================================

-- 1. AI Usage & Audit Log Table
CREATE TABLE IF NOT EXISTS ai_usage_logs (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    request_id VARCHAR(100) NOT NULL,
    user_id UUID,
    operation VARCHAR(100) NOT NULL,
    provider VARCHAR(50) NOT NULL,
    model VARCHAR(100),
    tokens_used INTEGER DEFAULT 0,
    latency_ms BIGINT NOT NULL,
    status VARCHAR(50) NOT NULL,
    fallback_used BOOLEAN NOT NULL DEFAULT FALSE,
    error_message TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_ai_usage_user_op ON ai_usage_logs (user_id, operation);
CREATE INDEX IF NOT EXISTS idx_ai_usage_created ON ai_usage_logs (created_at DESC);
CREATE INDEX IF NOT EXISTS idx_ai_usage_status ON ai_usage_logs (status);

-- 2. AI Enquiry Classification Table
CREATE TABLE IF NOT EXISTS ai_enquiry_classifications (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    enquiry_id UUID NOT NULL,
    category VARCHAR(100) NOT NULL,
    priority VARCHAR(50) NOT NULL,
    sentiment VARCHAR(50),
    suggested_department VARCHAR(100),
    suggested_action TEXT,
    confidence DOUBLE PRECISION,
    classified_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_ai_enquiry_class_enquiry ON ai_enquiry_classifications (enquiry_id);

-- 3. AI Lead Scores Table
CREATE TABLE IF NOT EXISTS ai_lead_scores (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    lead_id UUID NOT NULL,
    score INTEGER NOT NULL,
    classification VARCHAR(50) NOT NULL,
    reasons TEXT,
    next_action VARCHAR(255),
    confidence DOUBLE PRECISION,
    scored_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_ai_lead_scores_lead ON ai_lead_scores (lead_id);
