-- =============================================================================
-- PROPZEN ADVANCED SMART MEDIA SYSTEM V2 — SUPABASE SQL MIGRATION
-- Production-Grade Relational Schema, Storage Configuration & RLS Hardening
-- =============================================================================

-- 1. Create / Update property_images table
CREATE TABLE IF NOT EXISTS public.property_images (
    id TEXT PRIMARY KEY,
    property_id TEXT NOT NULL REFERENCES public.properties(id) ON DELETE CASCADE,
    storage_path TEXT NOT NULL,
    public_url TEXT NOT NULL,
    medium_url TEXT,
    thumbnail_url TEXT,
    width INTEGER DEFAULT 1920,
    height INTEGER DEFAULT 1080,
    file_size INTEGER DEFAULT 0,
    mime_type TEXT DEFAULT 'image/jpeg',
    display_order INTEGER DEFAULT 1,
    is_cover BOOLEAN DEFAULT FALSE,
    status TEXT DEFAULT 'approved' CHECK (status IN ('pending', 'approved', 'rejected', 'flagged')),
    rejection_reason TEXT,
    content_hash TEXT,
    uploaded_by TEXT DEFAULT '',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Create index on property_id, status, and content_hash for high-speed lookups
CREATE INDEX IF NOT EXISTS idx_property_images_property_id ON public.property_images(property_id);
CREATE INDEX IF NOT EXISTS idx_property_images_status ON public.property_images(status);
CREATE INDEX IF NOT EXISTS idx_property_images_content_hash ON public.property_images(property_id, content_hash);
CREATE INDEX IF NOT EXISTS idx_property_images_display_order ON public.property_images(property_id, display_order);

-- 3. Extend properties table with YouTube fields & responsive URLs if not present
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'properties' AND column_name = 'youtube_video_id') THEN
        ALTER TABLE public.properties ADD COLUMN youtube_video_id TEXT;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'properties' AND column_name = 'youtube_url') THEN
        ALTER TABLE public.properties ADD COLUMN youtube_url TEXT;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'properties' AND column_name = 'optimized_thumbnail_url') THEN
        ALTER TABLE public.properties ADD COLUMN optimized_thumbnail_url TEXT;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'properties' AND column_name = 'optimized_medium_url') THEN
        ALTER TABLE public.properties ADD COLUMN optimized_medium_url TEXT;
    END IF;
END $$;

-- 4. Enable Row Level Security (RLS) on property_images
ALTER TABLE public.property_images ENABLE ROW LEVEL SECURITY;

-- 5. Drop existing policies to ensure clean idempotent migration
DROP POLICY IF EXISTS "Public can view approved property images for published properties" ON public.property_images;
DROP POLICY IF EXISTS "Dealers can manage media for their own properties" ON public.property_images;
DROP POLICY IF EXISTS "Admins have full access to property_images" ON public.property_images;

-- 6. Policy: Public can view approved media for published properties
CREATE POLICY "Public can view approved property images for published properties"
ON public.property_images
FOR SELECT
TO public
USING (
    status = 'approved' AND EXISTS (
        SELECT 1 FROM public.properties p
        WHERE p.id = property_images.property_id
        AND p.status = 'published'
    )
);

-- 7. Policy: Dealers can view, insert, update and delete images only for their own properties
CREATE POLICY "Dealers can manage media for their own properties"
ON public.property_images
FOR ALL
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.properties p
        WHERE p.id = property_images.property_id
        AND (p.dealer_id = auth.uid()::text OR p.dealer_email = auth.jwt() ->> 'email')
    )
)
WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.properties p
        WHERE p.id = property_images.property_id
        AND (p.dealer_id = auth.uid()::text OR p.dealer_email = auth.jwt() ->> 'email')
    )
);

-- 8. Policy: Admins have full read/write/delete access on all property_images
CREATE POLICY "Admins have full access to property_images"
ON public.property_images
FOR ALL
TO authenticated
USING (public.is_admin())
WITH CHECK (public.is_admin());

-- 9. Storage Bucket Configuration: property-images
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'property-images',
    'property-images',
    true,
    15728640, -- 15 MB
    ARRAY['image/jpeg', 'image/png', 'image/webp']
)
ON CONFLICT (id) DO UPDATE SET
    public = true,
    file_size_limit = 15728640,
    allowed_mime_types = ARRAY['image/jpeg', 'image/png', 'image/webp'];

-- 10. Storage Object Security Policies
DROP POLICY IF EXISTS "Public can view property images storage" ON storage.objects;
DROP POLICY IF EXISTS "Dealers can upload property images storage" ON storage.objects;
DROP POLICY IF EXISTS "Dealers can delete own property images storage" ON storage.objects;
DROP POLICY IF EXISTS "Admins have full control on property images storage" ON storage.objects;

-- Public can view files in property-images bucket
CREATE POLICY "Public can view property images storage"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'property-images');

-- Dealers can upload into their property folder: properties/{property_id}/...
CREATE POLICY "Dealers can upload property images storage"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
    bucket_id = 'property-images' AND
    (storage.foldername(name))[1] = 'properties'
);

-- Dealers can delete images in their property folder
CREATE POLICY "Dealers can delete own property images storage"
ON storage.objects FOR DELETE
TO authenticated
USING (
    bucket_id = 'property-images' AND
    (storage.foldername(name))[1] = 'properties'
);

-- Admins full access to storage
CREATE POLICY "Admins have full control on property images storage"
ON storage.objects FOR ALL
TO authenticated
USING (bucket_id = 'property-images' AND public.is_admin())
WITH CHECK (bucket_id = 'property-images' AND public.is_admin());
