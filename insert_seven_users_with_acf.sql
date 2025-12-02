-- ============================================================================
-- Insert 7 New Users with ACF Placement
-- Users: 25AAA0012, 25AAA0013, 25AAA0014, 25AAA0015, 25AAA0016, 25AAA0017, 25AAA0018
-- Inviter: system_root (25AAA0000)
-- Parent: Auto-assigned by ACF logic (5 branches, 7 levels)
-- ============================================================================

DO $$
DECLARE
  system_root_uuid UUID;
  acf_parent_uuid UUID;
  acf_parent_world_id VARCHAR(50);
  acf_parent_username VARCHAR(255);
  acf_parent_level INTEGER;
  new_user_uuid UUID;
  new_user_level INTEGER;

  -- User data arrays
  user_world_ids VARCHAR(50)[] := ARRAY['25AAA0012', '25AAA0013', '25AAA0014', '25AAA0015', '25AAA0016', '25AAA0017', '25AAA0018'];
  user_usernames VARCHAR(255)[] := ARRAY['rattana_porn', 'sunan_jai', 'chaiwat_yim', 'lalita_kaew', 'thaworn_suk', 'narong_dee', 'pranom_chai'];
  user_emails VARCHAR(255)[] := ARRAY['rattana@fingrow.com', 'sunan@fingrow.com', 'chaiwat@fingrow.com', 'lalita@fingrow.com', 'thaworn@fingrow.com', 'narong@fingrow.com', 'pranom@fingrow.com'];
  user_phones VARCHAR(20)[] := ARRAY['0823456789', '0834567890', '0845678901', '0856789012', '0867890123', '0878901234', '0889012345'];
  user_first_names VARCHAR(100)[] := ARRAY['รัตนา', 'สุนันท์', 'ชัยวัฒน์', 'ลลิตา', 'ถาวร', 'ณรงค์', 'ประนอม'];
  user_last_names VARCHAR(100)[] := ARRAY['พร', 'ใจ', 'ยิ้ม', 'แก้ว', 'สุข', 'ดี', 'ชัย'];
  user_run_numbers INTEGER[] := ARRAY[12, 13, 14, 15, 16, 17, 18];
  user_invite_codes VARCHAR(50)[] := ARRAY['RATTANA2025', 'SUNAN2025', 'CHAIWAT2025', 'LALITA2025', 'THAWORN2025', 'NARONG2025', 'PRANOM2025'];
  user_fps DECIMAL(10,2)[] := ARRAY[1700.00, 2300.00, 1900.00, 2100.00, 2600.00, 1800.00, 2200.00];
  user_total_fps DECIMAL(10,2)[] := ARRAY[5200.00, 7100.00, 5700.00, 6400.00, 8200.00, 5400.00, 6900.00];

  i INTEGER;
BEGIN
  -- Get system_root UUID (inviter)
  SELECT id INTO system_root_uuid FROM users WHERE world_id = '25AAA0000';

  IF system_root_uuid IS NULL THEN
    RAISE EXCEPTION 'System root (25AAA0000) not found in database';
  END IF;

  RAISE NOTICE '========================================';
  RAISE NOTICE 'Adding 7 new users with ACF placement';
  RAISE NOTICE 'Inviter: system_root (25AAA0000)';
  RAISE NOTICE '========================================';

  -- Loop through all 7 users
  FOR i IN 1..7 LOOP
    -- Find next available parent using ACF logic
    SELECT find_next_acf_parent(system_root_uuid) INTO acf_parent_uuid;

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
      acf_parent_uuid, system_root_uuid, user_invite_codes[i],
      0, 5, TRUE, new_user_level,
      'Atta', 'normal',
      user_fps[i], user_total_fps[i],
      TRUE, 2, 75.0 + (i * 2.5),
      10 + i, 8 + i,
      (100 + i * 10)::VARCHAR || '/12', 'ถนนสุขุมวิท', 'วัฒนา',
      'กรุงเทพมหานคร', '10110', 'สมาชิกใหม่ที่สนใจระบบ Fingrow',
      (EXTRACT(EPOCH FROM NOW()) * 1000)::BIGINT + (i * 1000),
      (EXTRACT(EPOCH FROM NOW()) * 1000)::BIGINT + (i * 1000)
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
      800.00 + (i * 100), 0.10, 80.00 + (i * 10),
      36.00 + (i * 4.5), 36.00 + (i * 4.5), 'COMPLETED',
      NOW() - (i || ' days')::INTERVAL
    );
  END LOOP;

  RAISE NOTICE '';
  RAISE NOTICE '========================================';
  RAISE NOTICE '✅ Successfully created 7 new users:';
  RAISE NOTICE '   - 25AAA0012 (Rattana Porn)';
  RAISE NOTICE '   - 25AAA0013 (Sunan Jai)';
  RAISE NOTICE '   - 25AAA0014 (Chaiwat Yim)';
  RAISE NOTICE '   - 25AAA0015 (Lalita Kaew)';
  RAISE NOTICE '   - 25AAA0016 (Thaworn Suk)';
  RAISE NOTICE '   - 25AAA0017 (Narong Dee)';
  RAISE NOTICE '   - 25AAA0018 (Pranom Chai)';
  RAISE NOTICE '   All invited by system_root (25AAA0000)';
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
WHERE u.world_id IN ('25AAA0012', '25AAA0013', '25AAA0014', '25AAA0015', '25AAA0016', '25AAA0017', '25AAA0018')
ORDER BY u.world_id;
