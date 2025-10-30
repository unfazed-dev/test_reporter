-- Migration script to update existing user roles to new structure
-- This script migrates users from legacy roles to the new multi-role architecture
--
-- BACKUP YOUR DATABASE BEFORE RUNNING THIS SCRIPT!
--
-- Usage:
--   Run via Supabase dashboard SQL editor or via psql/supabase CLI

-- ============================================================================
-- STEP 1: Migrate existing participants
-- ============================================================================

-- Option A: Migrate all existing 'participant' to 'participant_main'
UPDATE profiles
SET
  role = 'participant_main',
  sub_role = NULL,
  updated_at = NOW()
WHERE role = 'participant';

-- Option B: If you want to manually assign some as managers, you can do:
-- UPDATE profiles
-- SET
--   role = 'participant_manager',
--   sub_role = NULL,
--   updated_at = NOW()
-- WHERE role = 'participant' AND email IN (
--   'manager1@example.com',
--   'manager2@example.com'
-- );

-- ============================================================================
-- STEP 2: Migrate existing providers
-- ============================================================================

-- Option A: Migrate all existing 'provider' to 'provider_independent'
UPDATE profiles
SET
  role = 'provider_independent',
  sub_role = NULL,
  updated_at = NOW()
WHERE role = 'provider';

-- Option B: If you have companies and want to assign company roles:
-- First, ensure companies exist in the companies table
-- Then assign providers to company roles:

-- UPDATE profiles
-- SET
--   role = 'provider_company_admin',
--   sub_role = NULL,
--   company_id = 'your-company-uuid-here',
--   updated_at = NOW()
-- WHERE role = 'provider' AND email IN (
--   'admin@company.com'
-- );

-- UPDATE profiles
-- SET
--   role = 'provider_company_employee',
--   sub_role = NULL,
--   company_id = 'your-company-uuid-here',
--   updated_at = NOW()
-- WHERE role = 'provider' AND email IN (
--   'employee1@company.com',
--   'employee2@company.com'
-- );

-- ============================================================================
-- STEP 3: Verify migration
-- ============================================================================

-- Check role distribution
SELECT
  role,
  COUNT(*) as user_count
FROM profiles
WHERE role != 'newUser'
GROUP BY role
ORDER BY role;

-- Check for any unmigrated users (should be empty unless new registrations)
SELECT
  id,
  email,
  role,
  created_at
FROM profiles
WHERE role IN ('participant', 'provider')
ORDER BY created_at DESC;

-- ============================================================================
-- STEP 4: Create sample companies (if needed)
-- ============================================================================

-- Uncomment and modify to create sample companies:

-- INSERT INTO companies (
--   name,
--   abn,
--   email,
--   phone_number,
--   ndis_registered,
--   ndis_registration_number,
--   service_categories,
--   default_hourly_rate,
--   default_overtime_rate,
--   address
-- ) VALUES (
--   'Sample NDIS Provider Pty Ltd',
--   '12345678901', -- Replace with valid ABN
--   'admin@samplendis.com.au',
--   '0400 000 000',
--   true,
--   'NDIS-12345',
--   ARRAY['personal_care', 'community_participation', 'transport'],
--   85.00,
--   127.50,
--   jsonb_build_object(
--     'street', '123 Example Street',
--     'city', 'Sydney',
--     'state', 'NSW',
--     'postcode', '2000',
--     'country', 'Australia'
--   )
-- )
-- RETURNING id, name;

-- ============================================================================
-- STEP 5: Create sample access grants (if needed)
-- ============================================================================

-- Uncomment to create sample participant manager access grants:

-- INSERT INTO participant_access_grants (
--   participant_id,
--   manager_id,
--   access_level,
--   granted_by_id,
--   is_active
-- ) VALUES (
--   'participant-user-uuid-here',
--   'manager-user-uuid-here',
--   'full',
--   'participant-user-uuid-here', -- participant grants access to themselves
--   true
-- );

-- ============================================================================
-- ROLLBACK (if needed)
-- ============================================================================

-- If you need to rollback the migration:

-- Rollback participants
-- UPDATE profiles
-- SET role = 'participant'
-- WHERE role IN ('participant_main', 'participant_manager');

-- Rollback providers
-- UPDATE profiles
-- SET role = 'provider'
-- WHERE role IN ('provider_independent', 'provider_company_admin', 'provider_company_employee', 'provider_company_coordinator');

-- ============================================================================
-- NOTES
-- ============================================================================

-- 1. This script uses the simplest migration path (all participants -> participant_main, all providers -> provider_independent)
-- 2. You may want to manually review and assign specific users to manager or company roles
-- 3. Make sure to test in a development environment first
-- 4. Consider creating a backup before running: pg_dump your_database > backup.sql
-- 5. The legacy 'participant' and 'provider' roles are still valid in the enum for backward compatibility
-- 6. After migration, you can monitor for any remaining legacy roles and migrate them as needed

-- ============================================================================
-- END OF MIGRATION SCRIPT
-- ============================================================================
