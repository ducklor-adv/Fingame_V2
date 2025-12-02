-- Fix child_count for all users to match actual children

DO $$
DECLARE
  user_record RECORD;
  actual_count INTEGER;
BEGIN
  RAISE NOTICE 'Fixing child_count for all users...';
  RAISE NOTICE '========================================';

  -- Loop through all users
  FOR user_record IN
    SELECT id, world_id, username, child_count
    FROM users
    ORDER BY world_id
  LOOP
    -- Count actual children
    SELECT COUNT(*) INTO actual_count
    FROM users
    WHERE parent_id = user_record.id;

    -- Update if mismatch
    IF user_record.child_count != actual_count THEN
      RAISE NOTICE '% (%): % → %',
        user_record.world_id,
        user_record.username,
        user_record.child_count,
        actual_count;

      UPDATE users
      SET child_count = actual_count,
          updated_at = (EXTRACT(EPOCH FROM NOW()) * 1000)::BIGINT
      WHERE id = user_record.id;
    END IF;
  END LOOP;

  RAISE NOTICE '========================================';
  RAISE NOTICE '✅ child_count fixed for all users';

END $$;

-- Verify
SELECT
  u.world_id,
  u.username,
  u.child_count,
  (SELECT COUNT(*) FROM users WHERE parent_id = u.id) as actual_children
FROM users u
WHERE u.child_count != (SELECT COUNT(*) FROM users WHERE parent_id = u.id)
ORDER BY u.world_id;
