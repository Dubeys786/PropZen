-- ============================================================================
-- PROPZEN SMART MEDIA UPLOAD & STORAGE OPTIMIZATION SYSTEM — DATABASE MIGRATION
-- Production-grade schema, RLS policies, and Supabase Storage bucket hardening
-- ============================================================================

-- 1. Create property_images Table
CREATE TABLE IF NOT EXISTS public.property_images (
    id TEXT PRIMARY KEY,
    property_id TEXT NOT NULL REFERENCES public.properties(id) ON DELETE CASCADE,
    storage_path TEXT NOT NULL,
    public_url TEXT NOT NULL,
    medium_url TEXT,
    thumbnail_url TEXT,
    width INT DEFAULT 1920,
    height INT DEFAULT 1080,
    file_size BIGINT DEFAULT 0,
    mime_type TEXT DEFAULT 'image/webp',
    uploaded_by TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for lightning fast media queries
CREATE INDEX IF NOT EXISTS idx_property_images_property_id ON public.property_images(property_id);
CREATE INDEX IF NOT EXISTS idx_property_images_created_at ON public.property_images(created_at DESC);

-- 2. Extend properties Table with YouTube and Responsive Image Fields
ALTER TABLE public.properties
    ADD COLUMN IF NOT EXISTS youtube_video_id TEXT,
    ADD COLUMN IF NOT EXISTS youtube_url TEXT,
    ADD COLUMN IF NOT EXISTS optimized_thumbnail_url TEXT,
    ADD COLUMN IF NOT EXISTS optimized_medium_url TEXT;

-- 3. Enable Row Level Security (RLS) on property_images
ALTER TABLE public.property_images ENABLE ROW LEVEL SECURITY;

-- 4. RLS POLICIES FOR property_images
-- A. Public/All users can read images of published properties
CREATE POLICY "Public can view images of published properties"
    ON public.property_images
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.properties p
            WHERE p.id = property_images.property_id
            AND p.status = 'published'
        )
        OR public.is_admin()
    );

-- B. Dealers can view images of their own properties (even pending ones)
CREATE POLICY "Dealers can view images of their own properties"
    ON public.property_images
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.properties p
            WHERE p.id = property_images.property_id
            AND p.dealer_id = auth.uid()::text
        )
    );

-- C. Dealers can insert/upload images only for properties they own
CREATE POLICY "Dealers can insert images for their own properties"
    ON public.property_images
    FOR INSERT
    WITH CHECK (
        public.is_admin()
        OR EXISTS (
            SELECT 1 FROM public.properties p
            WHERE p.id = property_images.property_id
            AND (p.dealer_id = auth.uid()::text OR p.dealer_email = public.current_user_email())
        )
    );

-- D. Dealers can delete images only for properties they own
CREATE POLICY "Dealers can delete images for their own properties"
    ON public.property_images
    FOR DELETE
    USING (
        public.is_admin()
        OR EXISTS (
            SELECT 1 FROM public.properties p
            WHERE p.id = property_images.property_id
            AND (p.dealer_id = auth.uid()::text OR p.dealer_email = public.current_user_email())
        )
    );

-- E. Admins have full access
CREATE POLICY "Admins have full access to property_images"
    ON public.property_images
    FOR ALL
    USING (public.is_admin())
    WITH CHECK (public.is_admin());

-- ============================================================================
-- 5. SUPABASE STORAGE BUCKET CONFIGURATION & SECURITY POLICIES
-- ============================================================================

-- Ensure property-images bucket exists
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'property-images',
    'property-images',
    true,
    15728640, -- 15 MB limit
    ARRAY['image/jpeg', 'image/png', 'image/webp']
)
ON CONFLICT (id) DO UPDATE SET
    public = true,
    file_size_limit = 15728640,
    allowed_mime_types = ARRAY['image/jpeg', 'image/png', 'image/webp'];

-- Storage RLS: Public read access for property images
CREATE POLICY "Public Read Property Images"
    ON storage.objects
    FOR SELECT
    USING (bucket_id = 'property-images');

-- Storage RLS: Authenticated upload to property-images
CREATE POLICY "Authenticated Dealers and Admins Upload Property Images"
    ON storage.objects
    FOR INSERT
    WITH CHECK (
        bucket_id = 'property-images'
        AND (auth.role() = 'authenticated' OR public.is_admin())
    );

-- Storage RLS: Dealers and Admins delete property images
CREATE POLICY "Dealers and Admins Delete Property Images"
    ON storage.objects
    FOR DELETE
    USING (
        bucket_id = 'property-images'
        AND (auth.role() = 'authenticated' OR public.is_admin())
    );
