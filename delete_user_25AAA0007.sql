-- Delete user 25AAA0007 (Kanya Dee) to re-insert with correct ACF placement

DO $$
DECLARE
  user_uuid UUID;
  parent_uuid UUID;
BEGIN
  -- Get user UUID
  SELECT id, parent_id INTO user_uuid, parent_uuid
  FROM users WHERE world_id = '25AAA0007';

  IF user_uuid IS NULL THEN
    RAISE NOTICE '⚠️  User 25AAA0007 not found';
  ELSE
    -- Delete FP transactions first
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

    RAISE NOTICE '✅ User 25AAA0007 (Kanya Dee) deleted successfully';
  END IF;
END $$;
