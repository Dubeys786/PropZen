-- =============================================================================
-- PROPZEN FLYWAY MIGRATION V5: SERVICE MANAGEMENT, PARTNERS, REQUESTS & JOURNEY
-- =============================================================================
-- Target Database: Supabase PostgreSQL (Project eemxylswyvhsyzllcsnp) & H2 dev
--
-- Creates database-driven service categories, partner profiles, requests,
-- assignments, journey events, documents, milestones, payments, and feedback.
-- =============================================================================

-- 1. Service Categories Table
CREATE TABLE IF NOT EXISTS public.service_categories (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    slug VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    icon VARCHAR(255),
    is_active BOOLEAN NOT NULL DEFAULT true,
    sort_order INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_service_categories_slug ON public.service_categories(slug);
CREATE INDEX IF NOT EXISTS idx_service_categories_active ON public.service_categories(is_active);

-- Seed Initial Core Categories
INSERT INTO public.service_categories (name, slug, description, icon, is_active, sort_order)
VALUES 
    ('Loan / Home Finance', 'loan-home-finance', 'Home loan eligibility, documentation, bank underwriting and sanction', 'account_balance', true, 1),
    ('Home Design', 'home-design', 'Interior architecture, 2D floor plans, 3D photorealistic renderings and turnkey styling', 'palette', true, 2),
    ('Vastu Consultation', 'vastu-consultation', 'Directional energy analysis, plot evaluation, and non-demolition remedial solutions', 'compass_calibration', true, 3),
    ('Construction', 'construction', 'Turnkey civil construction, site assessment, structural BOQ, and milestone inspection', 'handyman', true, 4),
    ('Property Verification', 'property-verification', 'Title deed search, 30-year ownership verification, RERA legal audit, and encumbrance certificates', 'verified', true, 5),
    ('Virtual & 3D Visualization', 'virtual-3d-visualization', 'Interactive 360 virtual tours, high-fidelity WebXR walkthroughs, and 4K aerial drone mapping', 'view_in_ar', true, 6)
ON CONFLICT DO NOTHING;

-- 2. Service Partner Profiles Table
CREATE TABLE IF NOT EXISTS public.service_partner_profiles (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL UNIQUE,
    business_name VARCHAR(255) NOT NULL,
    company_name VARCHAR(255),
    display_name VARCHAR(255),
    phone VARCHAR(50),
    email VARCHAR(255),
    description TEXT,
    experience_years INTEGER DEFAULT 0,
    city VARCHAR(100),
    service_area VARCHAR(255),
    profile_image_url VARCHAR(500),
    service_category_id UUID REFERENCES public.service_categories(id),
    service_categories TEXT,
    verification_status VARCHAR(50) NOT NULL DEFAULT 'PENDING',
    partner_status VARCHAR(50) NOT NULL DEFAULT 'PENDING',
    rating NUMERIC(3, 2) DEFAULT 5.00,
    total_completed_services INTEGER DEFAULT 0,
    total_active_services INTEGER DEFAULT 0,
    admin_notes TEXT,
    reviewed_by UUID,
    reviewed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_sp_profiles_user_id ON public.service_partner_profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_sp_profiles_status ON public.service_partner_profiles(partner_status);
CREATE INDEX IF NOT EXISTS idx_sp_profiles_verification ON public.service_partner_profiles(verification_status);
CREATE INDEX IF NOT EXISTS idx_sp_profiles_city ON public.service_partner_profiles(city);
CREATE INDEX IF NOT EXISTS idx_sp_profiles_category ON public.service_partner_profiles(service_category_id);

-- 3. Service Requests Table
CREATE TABLE IF NOT EXISTS public.service_requests (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    service_number VARCHAR(50) UNIQUE NOT NULL,
    customer_id UUID NOT NULL,
    partner_id UUID REFERENCES public.service_partner_profiles(id),
    service_category_id UUID NOT NULL REFERENCES public.service_categories(id),
    property_id VARCHAR(255),
    title VARCHAR(255) NOT NULL,
    description TEXT,
    location VARCHAR(255),
    budget NUMERIC(14, 2),
    preferred_date TIMESTAMPTZ,
    preferred_time VARCHAR(50),
    priority VARCHAR(50) NOT NULL DEFAULT 'MEDIUM',
    status VARCHAR(50) NOT NULL DEFAULT 'NEW',
    assigned_at TIMESTAMPTZ,
    started_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    cancelled_at TIMESTAMPTZ,
    rejection_reason TEXT,
    cancellation_reason TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_sr_customer_id ON public.service_requests(customer_id);
CREATE INDEX IF NOT EXISTS idx_sr_partner_id ON public.service_requests(partner_id);
CREATE INDEX IF NOT EXISTS idx_sr_category_id ON public.service_requests(service_category_id);
CREATE INDEX IF NOT EXISTS idx_sr_status ON public.service_requests(status);
CREATE INDEX IF NOT EXISTS idx_sr_created_at ON public.service_requests(created_at);

-- 4. Service Request Assignments Table
CREATE TABLE IF NOT EXISTS public.service_request_assignments (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    service_request_id UUID NOT NULL REFERENCES public.service_requests(id) ON DELETE CASCADE,
    partner_id UUID NOT NULL REFERENCES public.service_partner_profiles(id),
    assigned_by UUID,
    assignment_status VARCHAR(50) NOT NULL DEFAULT 'RECOMMENDED',
    assignment_score NUMERIC(5, 2) DEFAULT 0.00,
    assigned_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    accepted_at TIMESTAMPTZ,
    rejected_at TIMESTAMPTZ,
    notes TEXT
);

CREATE INDEX IF NOT EXISTS idx_sr_assign_request ON public.service_request_assignments(service_request_id);
CREATE INDEX IF NOT EXISTS idx_sr_assign_partner ON public.service_request_assignments(partner_id);
CREATE INDEX IF NOT EXISTS idx_sr_assign_status ON public.service_request_assignments(assignment_status);

-- 5. Service Journey Events (Timeline) Table
CREATE TABLE IF NOT EXISTS public.service_journey_events (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    service_request_id UUID NOT NULL REFERENCES public.service_requests(id) ON DELETE CASCADE,
    event_type VARCHAR(100) NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    created_by UUID,
    metadata TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_sr_journey_request ON public.service_journey_events(service_request_id);
CREATE INDEX IF NOT EXISTS idx_sr_journey_created_at ON public.service_journey_events(created_at);

-- 6. Service Documents Table
CREATE TABLE IF NOT EXISTS public.service_documents (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    service_request_id UUID NOT NULL REFERENCES public.service_requests(id) ON DELETE CASCADE,
    uploaded_by UUID NOT NULL,
    document_type VARCHAR(100) NOT NULL,
    file_name VARCHAR(255) NOT NULL,
    storage_path VARCHAR(500),
    file_url VARCHAR(500) NOT NULL,
    mime_type VARCHAR(100),
    file_size BIGINT,
    verification_status VARCHAR(50) NOT NULL DEFAULT 'UPLOADED',
    uploaded_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    verified_at TIMESTAMPTZ,
    verified_by UUID,
    rejection_reason TEXT
);

CREATE INDEX IF NOT EXISTS idx_sr_docs_request ON public.service_documents(service_request_id);
CREATE INDEX IF NOT EXISTS idx_sr_docs_uploaded_by ON public.service_documents(uploaded_by);
CREATE INDEX IF NOT EXISTS idx_sr_docs_status ON public.service_documents(verification_status);

-- 7. Service Milestones Table
CREATE TABLE IF NOT EXISTS public.service_milestones (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    service_request_id UUID NOT NULL REFERENCES public.service_requests(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    sequence_number INTEGER NOT NULL DEFAULT 0,
    amount NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
    status VARCHAR(50) NOT NULL DEFAULT 'PENDING',
    due_date TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_sr_milestones_request ON public.service_milestones(service_request_id);
CREATE INDEX IF NOT EXISTS idx_sr_milestones_status ON public.service_milestones(status);

-- 8. Service Payments Table
CREATE TABLE IF NOT EXISTS public.service_payments (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    service_request_id UUID NOT NULL REFERENCES public.service_requests(id) ON DELETE CASCADE,
    milestone_id UUID REFERENCES public.service_milestones(id),
    customer_id UUID NOT NULL,
    partner_id UUID,
    amount NUMERIC(12, 2) NOT NULL,
    currency VARCHAR(10) NOT NULL DEFAULT 'INR',
    payment_provider VARCHAR(50) NOT NULL DEFAULT 'RAZORPAY',
    provider_payment_id VARCHAR(255),
    provider_order_id VARCHAR(255),
    status VARCHAR(50) NOT NULL DEFAULT 'PENDING',
    paid_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_sr_payments_request ON public.service_payments(service_request_id);
CREATE INDEX IF NOT EXISTS idx_sr_payments_customer ON public.service_payments(customer_id);
CREATE INDEX IF NOT EXISTS idx_sr_payments_partner ON public.service_payments(partner_id);
CREATE INDEX IF NOT EXISTS idx_sr_payments_status ON public.service_payments(status);

-- 9. Service Feedback Table
CREATE TABLE IF NOT EXISTS public.service_feedback (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    service_request_id UUID NOT NULL UNIQUE REFERENCES public.service_requests(id) ON DELETE CASCADE,
    customer_id UUID NOT NULL,
    partner_id UUID NOT NULL REFERENCES public.service_partner_profiles(id),
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
    comment TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_sr_feedback_partner ON public.service_feedback(partner_id);
CREATE INDEX IF NOT EXISTS idx_sr_feedback_customer ON public.service_feedback(customer_id);

-- 10. Service Customer Notes (CRM) Table
CREATE TABLE IF NOT EXISTS public.service_customer_notes (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    customer_id UUID NOT NULL,
    partner_id UUID REFERENCES public.service_partner_profiles(id),
    service_request_id UUID,
    note TEXT NOT NULL,
    tags VARCHAR(255),
    next_followup_at TIMESTAMPTZ,
    created_by UUID NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_sr_notes_customer ON public.service_customer_notes(customer_id);
CREATE INDEX IF NOT EXISTS idx_sr_notes_partner ON public.service_customer_notes(partner_id);
