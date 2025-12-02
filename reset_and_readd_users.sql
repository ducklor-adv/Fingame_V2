-- Delete users 25AAA0007-25AAA0011 and re-add with correct ACF placement

DO $$
DECLARE
  user_to_delete VARCHAR(50);
  user_uuid UUID;
  parent_uuid UUID;
BEGIN
  RAISE NOTICE 'Deleting incorrectly placed users...';
  RAISE NOTICE '========================================';

  -- Delete users 25AAA0007 through 25AAA0011
  FOR user_to_delete IN
    SELECT world_id
    FROM users
    WHERE world_id IN ('25AAA0007', '25AAA0008', '25AAA0009', '25AAA0010', '25AAA0011')
    ORDER BY world_id
  LOOP
    -- Get user and parent UUID
    SELECT id, parent_id INTO user_uuid, parent_uuid
    FROM users WHERE world_id = user_to_delete;

    -- Delete transactions first
    DELETE FROM simulated_fp_transactions WHERE user_id = user_uuid;
    DELETE FROM simulated_fp_ledger WHERE user_id = user_uuid;

    -- Update parent's child count
    IF parent_uuid IS NOT NULL THEN
      UPDATE users
      SET child_count = child_count - 1,
          updated_at = (EXTRACT(EPOCH FROM NOW()) * 1000)::BIGINT
      WHERE id = parent_uuid;
    END IF;

    -- Delete user
    DELETE FROM users WHERE id = user_uuid;

    RAISE NOTICE '✅ Deleted: %', user_to_delete;
  END LOOP;

  RAISE NOTICE '========================================';
  RAISE NOTICE '✅ All users deleted successfully';

END $$;
