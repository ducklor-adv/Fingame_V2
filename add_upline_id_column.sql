-- ============================================================================
-- COMPLETE SCRIPT: Add upline_id to users table
-- Execute this entire script in PostgreSQL
-- ============================================================================

-- ============================================================================
-- Section 1: Add upline_id column
-- ============================================================================
ALTER TABLE users
ADD COLUMN IF NOT EXISTS upline_id JSONB DEFAULT '[]'::jsonb;

COMMENT ON COLUMN users.upline_id IS 'Array of upline user IDs (up to 6 levels), ordered from closest to farthest parent';

-- ============================================================================
-- Section 2: Create function to get upline IDs
-- ============================================================================
CREATE OR REPLACE FUNCTION get_upline_ids(start_user_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
AS $$
DECLARE
  upline_array UUID[] := ARRAY[]::UUID[];
  current_parent_id UUID;
  level_count INTEGER := 0;
  max_levels INTEGER := 6;
BEGIN
  -- Get the parent_id of the starting user
  SELECT parent_id INTO current_parent_id
  FROM users
  WHERE id = start_user_id;

  -- If no parent, return empty array
  IF current_parent_id IS NULL THEN
    RETURN '[]'::jsonb;
  END IF;

  -- Traverse up the tree, collecting parent IDs
  WHILE current_parent_id IS NOT NULL AND level_count < max_levels LOOP
    -- Add current parent to array
    upline_array := upline_array || current_parent_id;
    level_count := level_count + 1;

    -- Get the next parent
    SELECT parent_id INTO current_parent_id
    FROM users
    WHERE id = current_parent_id;
  END LOOP;

  -- Convert UUID array to JSONB array
  RETURN to_jsonb(upline_array);
END;
$$;

COMMENT ON FUNCTION get_upline_ids(UUID) IS 'Returns JSONB array of upline user IDs (max 6 levels) for a given user';

-- ============================================================================
-- Section 3: Create trigger function
-- ============================================================================
CREATE OR REPLACE FUNCTION auto_update_upline_id()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  -- Calculate and set upline_id
  NEW.upline_id := get_upline_ids(NEW.id);
  RETURN NEW;
END;
$$;

-- ============================================================================
-- Section 4: Create trigger
-- ============================================================================
DROP TRIGGER IF EXISTS trigger_auto_update_upline_id ON users;

CREATE TRIGGER trigger_auto_update_upline_id
  BEFORE INSERT OR UPDATE OF parent_id
  ON users
  FOR EACH ROW
  EXECUTE FUNCTION auto_update_upline_id();

COMMENT ON TRIGGER trigger_auto_update_upline_id ON users IS 'Automatically updates upline_id when user is inserted or parent_id changes';

-- ============================================================================
-- Section 5: Update existing data
-- ============================================================================
DO $$
DECLARE
  user_record RECORD;
  total_users INTEGER;
  processed INTEGER := 0;
BEGIN
  -- Disable the update_updated_at trigger temporarily
  ALTER TABLE users DISABLE TRIGGER update_users_updated_at;

  SELECT COUNT(*) INTO total_users FROM users;
  RAISE NOTICE '';
  RAISE NOTICE '========================================';
  RAISE NOTICE 'Section 5: Updating upline_id for % users...', total_users;
  RAISE NOTICE '========================================';

  FOR user_record IN SELECT id FROM users ORDER BY run_number LOOP
    UPDATE users
    SET upline_id = get_upline_ids(user_record.id)
    WHERE id = user_record.id;

    processed := processed + 1;

    -- Progress notification every 10 users
    IF processed % 10 = 0 THEN
      RAISE NOTICE 'Progress: % / % users updated', processed, total_users;
    END IF;
  END LOOP;

  -- Re-enable the trigger
  ALTER TABLE users ENABLE TRIGGER update_users_updated_at;

  RAISE NOTICE '';
  RAISE NOTICE '✅ Section 5: Updated upline_id for % users', processed;
  RAISE NOTICE '';
  RAISE NOTICE '========================================';
  RAISE NOTICE '🎉 ALL SECTIONS COMPLETED SUCCESSFULLY!';
  RAISE NOTICE '========================================';
EXCEPTION
  WHEN OTHERS THEN
    -- Make sure to re-enable trigger even if error occurs
    ALTER TABLE users ENABLE TRIGGER update_users_updated_at;
    RAISE;
END $$;

-- ============================================================================
-- Section 6: Create indexes
-- ============================================================================
CREATE INDEX IF NOT EXISTS idx_users_upline_id_gin
ON users USING gin(upline_id);

CREATE INDEX IF NOT EXISTS idx_users_upline_count
ON users((jsonb_array_length(COALESCE(upline_id, '[]'::jsonb))));

-- ============================================================================
-- Verification Query
-- ============================================================================
SELECT
  world_id,
  username,
  level,
  jsonb_array_length(COALESCE(upline_id, '[]'::jsonb)) as upline_count,
  upline_id,
  CASE
    WHEN jsonb_array_length(COALESCE(upline_id, '[]'::jsonb)) <= level
     AND jsonb_array_length(COALESCE(upline_id, '[]'::jsonb)) <= 6
    THEN '✅ Valid'
    ELSE '❌ Invalid'
  END as validation_status
FROM users
ORDER BY run_number
LIMIT 15;
