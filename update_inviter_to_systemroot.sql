-- ============================================================================
-- Update Test Users to be Invited by System Root
-- This script updates 25AAA0001 and 25AAA0002 to be children of system_root
-- ============================================================================

DO $$
DECLARE
  system_root_uuid UUID;
  somchai_uuid UUID;
  somsri_uuid UUID;
  updated_count INTEGER;
BEGIN
  -- Get system_root UUID
  SELECT id INTO system_root_uuid FROM users WHERE world_id = '25AAA0000';

  IF system_root_uuid IS NULL THEN
    RAISE EXCEPTION 'System root (25AAA0000) not found in database';
  END IF;

  -- Get user UUIDs
  SELECT id INTO somchai_uuid FROM users WHERE world_id = '25AAA0001';
  SELECT id INTO somsri_uuid FROM users WHERE world_id = '25AAA0002';

  -- Update 25AAA0001 (Somchai) to be invited by system_root
  IF somchai_uuid IS NOT NULL THEN
    UPDATE users
    SET
      parent_id = system_root_uuid,
      inviter_id = system_root_uuid,
      level = 1
    WHERE id = somchai_uuid;
    RAISE NOTICE '✅ Updated 25AAA0001 (Somchai) - parent/inviter set to system_root';
  ELSE
    RAISE NOTICE '⚠️ User 25AAA0001 not found';
  END IF;

  -- Update 25AAA0002 (Somsri) to be invited by system_root
  IF somsri_uuid IS NOT NULL THEN
    UPDATE users
    SET
      parent_id = system_root_uuid,
      inviter_id = system_root_uuid,
      level = 1
    WHERE id = somsri_uuid;
    RAISE NOTICE '✅ Updated 25AAA0002 (Somsri) - parent/inviter set to system_root';
  ELSE
    RAISE NOTICE '⚠️ User 25AAA0002 not found';
  END IF;

  -- Update system_root's child_count
  UPDATE users
  SET child_count = (
    SELECT COUNT(*)
    FROM users
    WHERE parent_id = system_root_uuid
  )
  WHERE id = system_root_uuid;

  RAISE NOTICE '✅ Updated system_root child_count';

  -- Show final result
  RAISE NOTICE '';
  RAISE NOTICE '📊 Final Network Structure:';
  RAISE NOTICE '   System Root (25AAA0000)';
  RAISE NOTICE '   ├── 25AAA0001 (Somchai Jaidee)';
  RAISE NOTICE '   └── 25AAA0002 (Somsri Rakdee)';

END $$;
