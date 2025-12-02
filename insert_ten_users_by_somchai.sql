-- ============================================================================
-- Insert 10 New Users Invited by Somchai Jaidee (25AAA0001)
-- Users: 25AAA0022 - 25AAA0031
-- Inviter: somchai_jaidee (25AAA0001)
-- Parent: Auto-assigned by ACF logic (5 branches, 7 levels)
-- ============================================================================

DO $$
DECLARE
  somchai_uuid UUID;
  acf_parent_uuid UUID;
  acf_parent_world_id VARCHAR(50);
  acf_parent_username VARCHAR(255);
  acf_parent_level INTEGER;
  new_user_uuid UUID;
  new_user_level INTEGER;

  -- User data arrays
  user_world_ids VARCHAR(50)[] := ARRAY[
    '25AAA0022', '25AAA0023', '25AAA0024', '25AAA0025', '25AAA0026',
    '25AAA0027', '25AAA0028', '25AAA0029', '25AAA0030', '25AAA0031'
  ];
  user_usernames VARCHAR(255)[] := ARRAY[
    'anong_kaew', 'boonmee_rak', 'chompoo_suk', 'darika_porn', 'ekachai_dee',
    'fueng_chai', 'ganya_yim', 'hiran_song', 'itsara_won', 'jira_pong'
  ];
  user_emails VARCHAR(255)[] := ARRAY[
    'anong@fingrow.com', 'boonmee@fingrow.com', 'chompoo@fingrow.com', 'darika@fingrow.com', 'ekachai@fingrow.com',
    'fueng@fingrow.com', 'ganya@fingrow.com', 'hiran@fingrow.com', 'itsara@fingrow.com', 'jira@fingrow.com'
  ];
  user_phones VARCHAR(20)[] := ARRAY[
    '0823456780', '0834567891', '0845678902', '0856789013', '0867890124',
    '0878901235', '0889012346', '0890123457', '0801234568', '0812345679'
  ];
  user_first_names VARCHAR(100)[] := ARRAY[
    'อนงค์', 'บุญมี', 'ชมพู', 'ดาริกา', 'เอกชัย',
    'เฟื่อง', 'กัญญา', 'หิรัญ', 'อิสระ', 'จิรา'
  ];
  user_last_names VARCHAR(100)[] := ARRAY[
    'แก้ว', 'รักษ์', 'สุข', 'พร', 'ดี',
    'ชัย', 'ยิ้ม', 'ทรง', 'วรรณ', 'พงษ์'
  ];
  user_run_numbers INTEGER[] := ARRAY[22, 23, 24, 25, 26, 27, 28, 29, 30, 31];
  user_invite_codes VARCHAR(50)[] := ARRAY[
    'ANONG2025', 'BOONMEE2025', 'CHOMPOO2025', 'DARIKA2025', 'EKACHAI2025',
    'FUENG2025', 'GANYA2025', 'HIRAN2025', 'ITSARA2025', 'JIRA2025'
  ];
  user_fps DECIMAL(10,2)[] := ARRAY[
    1600.00, 1900.00, 2100.00, 1750.00, 2200.00,
    1850.00, 2000.00, 1950.00, 2150.00, 1800.00
  ];
  user_total_fps DECIMAL(10,2)[] := ARRAY[
    4900.00, 5800.00, 6500.00, 5300.00, 6800.00,
    5600.00, 6100.00, 5950.00, 6600.00, 5500.00
  ];

  i INTEGER;
BEGIN
  -- Get Somchai's UUID (inviter)
  SELECT id INTO somchai_uuid FROM users WHERE world_id = '25AAA0001';

  IF somchai_uuid IS NULL THEN
    RAISE EXCEPTION 'Somchai Jaidee (25AAA0001) not found in database';
  END IF;

  RAISE NOTICE '========================================';
  RAISE NOTICE 'Adding 10 new users with ACF placement';
  RAISE NOTICE 'Inviter: somchai_jaidee (25AAA0001)';
  RAISE NOTICE '========================================';

  -- Loop through all 10 users
  FOR i IN 1..10 LOOP
    -- Find next available parent using ACF logic
    SELECT find_next_acf_parent(somchai_uuid) INTO acf_parent_uuid;

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
      acf_parent_uuid, somchai_uuid, user_invite_codes[i],
      0, 5, TRUE, new_user_level,
      'Atta', 'normal',
      user_fps[i], user_total_fps[i],
      TRUE, 2, 72.0 + (i * 1.5),
      9 + i, 7 + i,
      (300 + i * 10)::VARCHAR || '/23', 'ถนนพระราม 3', 'บางโพ',
      'กรุงเทพมหานคร', '10160', 'สมาชิกใหม่ที่ถูกชวนโดย Somchai',
      (EXTRACT(EPOCH FROM NOW()) * 1000)::BIGINT + (i * 1000 + 200000),
      (EXTRACT(EPOCH FROM NOW()) * 1000)::BIGINT + (i * 1000 + 200000)
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
      750.00 + (i * 50), 0.10, 75.00 + (i * 5),
      33.75 + (i * 2.25), 33.75 + (i * 2.25), 'COMPLETED',
      NOW() - (i || ' days')::INTERVAL
    );
  END LOOP;

  RAISE NOTICE '';
  RAISE NOTICE '========================================';
  RAISE NOTICE '✅ Successfully created 10 new users';
  RAISE NOTICE '   All invited by somchai_jaidee (25AAA0001)';
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
WHERE u.world_id BETWEEN '25AAA0022' AND '25AAA0031'
ORDER BY u.world_id;
