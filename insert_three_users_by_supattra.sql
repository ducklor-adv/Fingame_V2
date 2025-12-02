-- ============================================================================
-- Insert 3 New Users Invited by Supattra Sawadee (25AAA0003)
-- Users: 25AAA0019, 25AAA0020, 25AAA0021
-- Inviter: supattra_sawadee (25AAA0003)
-- Parent: Auto-assigned by ACF logic (5 branches, 7 levels)
-- ============================================================================

DO $$
DECLARE
  supattra_uuid UUID;
  acf_parent_uuid UUID;
  acf_parent_world_id VARCHAR(50);
  acf_parent_username VARCHAR(255);
  acf_parent_level INTEGER;
  new_user_uuid UUID;
  new_user_level INTEGER;

  -- User data arrays
  user_world_ids VARCHAR(50)[] := ARRAY['25AAA0019', '25AAA0020', '25AAA0021'];
  user_usernames VARCHAR(255)[] := ARRAY['wipawee_chan', 'sarawut_song', 'nida_porn'];
  user_emails VARCHAR(255)[] := ARRAY['wipawee@fingrow.com', 'sarawut@fingrow.com', 'nida@fingrow.com'];
  user_phones VARCHAR(20)[] := ARRAY['0890123456', '0801234567', '0812345678'];
  user_first_names VARCHAR(100)[] := ARRAY['วิภาวี', 'สราวุฒิ', 'นิดา'];
  user_last_names VARCHAR(100)[] := ARRAY['จันทร์', 'ทรง', 'พร'];
  user_run_numbers INTEGER[] := ARRAY[19, 20, 21];
  user_invite_codes VARCHAR(50)[] := ARRAY['WIPAWEE2025', 'SARAWUT2025', 'NIDA2025'];
  user_fps DECIMAL(10,2)[] := ARRAY[1500.00, 2000.00, 1800.00];
  user_total_fps DECIMAL(10,2)[] := ARRAY[4500.00, 6200.00, 5400.00];

  i INTEGER;
BEGIN
  -- Get Supattra's UUID (inviter)
  SELECT id INTO supattra_uuid FROM users WHERE world_id = '25AAA0003';

  IF supattra_uuid IS NULL THEN
    RAISE EXCEPTION 'Supattra Sawadee (25AAA0003) not found in database';
  END IF;

  RAISE NOTICE '========================================';
  RAISE NOTICE 'Adding 3 new users with ACF placement';
  RAISE NOTICE 'Inviter: supattra_sawadee (25AAA0003)';
  RAISE NOTICE '========================================';

  -- Loop through all 3 users
  FOR i IN 1..3 LOOP
    -- Find next available parent using ACF logic
    SELECT find_next_acf_parent(supattra_uuid) INTO acf_parent_uuid;

    IF acf_parent_uuid IS NULL THEN
      RAISE EXCEPTION 'No available parent position for user %', user_world_ids[i];
    END IF;

    -- Get parent info
    SELECT world_id, username, level INTO acf_parent_world_id, acf_parent_username, acf_parent_level
    FROM users WHERE id = acf_parent_uuid;

    new_user_level := acf_parent_level + 1;

    RAISE NOTICE '';
    RAISE NOTICE '👤 User %: % (%)', i, user_world_ids[i], user_usernames[i];
    RAISE NOTICE '   Parent: % (%) - Level %', acf_parent_username, acf_parent_world_id, acf_parent_level;
    RAISE NOTICE '   New user Level: %', new_user_level;

    -- Insert user
    INSERT INTO users (
      world_id, username, email, phone,
      first_name, last_name, run_number,
      parent_id, inviter_id, invite_code,
      child_count, max_children, acf_accepting, level,
      user_type, regist_type,
      own_finpoint, total_finpoint,
      is_verified, verification_level, trust_score,
      total_sales, total_purchases,
      address_number, address_street, address_district,
      address_province, address_postal_code, bio,
      created_at, updated_at
    ) VALUES (
      user_world_ids[i], user_usernames[i], user_emails[i], user_phones[i],
      user_first_names[i], user_last_names[i], user_run_numbers[i],
      acf_parent_uuid, supattra_uuid, user_invite_codes[i],
      0, 5, TRUE, new_user_level,
      'Atta', 'normal',
      user_fps[i], user_total_fps[i],
      TRUE, 1, 70.0 + (i * 3.0),
      8 + i, 6 + i,
      (200 + i * 10)::VARCHAR || '/45', 'ถนนรัชดาภิเษก', 'ห้วยขวาง',
      'กรุงเทพมหานคร', '10310', 'สมาชิกใหม่ที่ถูกชวนโดย Supattra',
      (EXTRACT(EPOCH FROM NOW()) * 1000)::BIGINT + (i * 1000 + 100000),
      (EXTRACT(EPOCH FROM NOW()) * 1000)::BIGINT + (i * 1000 + 100000)
    ) RETURNING id INTO new_user_uuid;

    -- Update parent's child count
    UPDATE users
    SET child_count = child_count + 1,
        updated_at = (EXTRACT(EPOCH FROM NOW()) * 1000)::BIGINT
    WHERE id = acf_parent_uuid;

    -- Add sample FP transaction
    INSERT INTO simulated_fp_transactions (
      user_id, simulated_tx_type, simulated_source_type,
      simulated_base_amount, simulated_reverse_rate, simulated_generated_fp,
      simulated_self_fp, simulated_network_fp, simulated_status, created_at
    ) VALUES (
      new_user_uuid, 'SECONDHAND_SALE', 'secondhand_sale',
      700.00 + (i * 100), 0.10, 70.00 + (i * 10),
      31.50 + (i * 4.5), 31.50 + (i * 4.5), 'COMPLETED',
      NOW() - (i || ' days')::INTERVAL
    );
  END LOOP;

  RAISE NOTICE '';
  RAISE NOTICE '========================================';
  RAISE NOTICE '✅ Successfully created 3 new users:';
  RAISE NOTICE '   - 25AAA0019 (Wipawee Chan)';
  RAISE NOTICE '   - 25AAA0020 (Sarawut Song)';
  RAISE NOTICE '   - 25AAA0021 (Nida Porn)';
  RAISE NOTICE '   All invited by supattra_sawadee (25AAA0003)';
  RAISE NOTICE '   Parents assigned by ACF logic';
  RAISE NOTICE '========================================';

END $$;

-- Verify the new users
SELECT
  u.world_id,
  u.username,
  u.first_name,
  u.last_name,
  i.world_id as inviter_world_id,
  i.username as inviter_username,
  p.world_id as parent_world_id,
  p.username as parent_username,
  u.level,
  u.child_count,
  u.own_finpoint
FROM users u
LEFT JOIN users i ON u.inviter_id = i.id
LEFT JOIN users p ON u.parent_id = p.id
WHERE u.world_id IN ('25AAA0019', '25AAA0020', '25AAA0021')
ORDER BY u.world_id;
