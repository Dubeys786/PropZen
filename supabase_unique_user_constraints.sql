-- =========================================================================
-- PROPZEN SUPABASE DATABASE MIGRATION: UNIQUE EMAIL & PHONE VALIDATION
-- Purpose: Enforce strict uniqueness for user email and phone numbers
-- =========================================================================

-- 1. Check for any existing duplicate emails in the database
-- (Will return rows if any duplicates exist in production table)
SELECT LOWER(TRIM(email)) AS normalized_email, COUNT(*) AS occurrences
FROM public.users
WHERE email IS NOT NULL AND TRIM(email) <> ''
GROUP BY LOWER(TRIM(email))
HAVING COUNT(*) > 1;

-- 2. Check for any existing duplicate phone numbers in the database
SELECT TRIM(phone) AS normalized_phone, COUNT(*) AS occurrences
FROM public.users
WHERE phone IS NOT NULL AND TRIM(phone) <> ''
GROUP BY TRIM(phone)
HAVING COUNT(*) > 1;

-- 3. Create Case-Insensitive Unique Index on Email
-- This prevents race conditions and ensures ONE EMAIL -> ONE ACCOUNT
CREATE UNIQUE INDEX IF NOT EXISTS idx_users_unique_lower_email
ON public.users (LOWER(TRIM(email)))
WHERE email IS NOT NULL AND TRIM(email) <> '';

-- 4. Create Unique Index on Phone Number
-- This ensures ONE PHONE NUMBER -> ONE ACCOUNT
CREATE UNIQUE INDEX IF NOT EXISTS idx_users_unique_phone
ON public.users (TRIM(phone))
WHERE phone IS NOT NULL AND TRIM(phone) <> '';

-- 5. Helper Function for Rapid Pre-Check RPC (Optional PostgREST endpoint)
CREATE OR REPLACE FUNCTION public.check_credentials_availability(
    p_email TEXT,
    p_phone TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_email_exists BOOLEAN := FALSE;
    v_phone_exists BOOLEAN := FALSE;
    v_clean_email TEXT := LOWER(TRIM(p_email));
    v_clean_phone TEXT := TRIM(p_phone);
BEGIN
    IF v_clean_email IS NOT NULL AND v_clean_email <> '' THEN
        SELECT EXISTS(
            SELECT 1 FROM public.users 
            WHERE LOWER(TRIM(email)) = v_clean_email
        ) INTO v_email_exists;
    END IF;

    IF v_clean_phone IS NOT NULL AND v_clean_phone <> '' THEN
        SELECT EXISTS(
            SELECT 1 FROM public.users 
            WHERE TRIM(phone) = v_clean_phone
        ) INTO v_phone_exists;
    END IF;

    RETURN jsonb_build_object(
        'email_exists', v_email_exists,
        'phone_exists', v_phone_exists,
        'is_available', NOT (v_email_exists OR v_phone_exists)
    );
END;
$$;
