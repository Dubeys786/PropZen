-- =============================================================================
-- PROPZEN FLYWAY MIGRATION V1: BASELINE SCHEMA REGISTRATION
-- =============================================================================
-- Target Database: Supabase PostgreSQL (Project eemxylswyvhsyzllcsnp)
--
-- This baseline script acts as the version 1 marker for Flyway.
-- All existing production tables (public.users, public.posted_properties,
-- public.enquiries, public.site_visits, public.profiles, etc.) are preserved
-- in place.
--
-- Migration Rules:
-- 1. Never execute DROP TABLE, DROP DATABASE, or TRUNCATE in Flyway scripts.
-- 2. Any subsequent schema updates must be created as forward-only scripts (V2__, V3__, etc.).
-- 3. In production, Flyway starts with baseline-version=0 so existing tables are intact.
-- =============================================================================

SELECT 1;
