-- ============================================================================
-- Insert 4 New Users with ACF Placement
-- Users: 25AAA0008, 25AAA0009, 25AAA0010, 25AAA0011
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
  user_counter INTEGER := 0;
BEGIN
  -- Get system_root UUID (inviter)
  SELECT id INTO system_root_uuid FROM users WHERE world_id = '25AAA0000';

  IF system_root_uuid IS NULL THEN
    RAISE EXCEPTION 'System root (25AAA0000) not found in database';
  END IF;

  RAISE NOTICE '========================================';
  RAISE NOTICE 'Adding 4 new users with ACF placement';
  RAISE NOTICE 'Inviter: system_root (25AAA0000)';
  RAISE NOTICE '========================================';

  -- User 1: 25AAA0008 (Manee)
  SELECT find_next_acf_parent(system_root_uuid) INTO acf_parent_uuid;
  IF acf_parent_uuid IS NULL THEN
    RAISE EXCEPTION 'No available parent position for user 25AAA0008';
  END IF;

  SELECT world_id, username, level INTO acf_parent_world_id, acf_parent_username, acf_parent_level
  FROM users WHERE id = acf_parent_uuid;
  new_user_level := acf_parent_level + 1;

  RAISE NOTICE '';
  RAISE NOTICE '👤 User 1: 25AAA0008 (Manee)';
  RAISE NOTICE '   Parent: % (%) - Level %', acf_parent_username, acf_parent_world_id, acf_parent_level;
  RAISE NOTICE '   New user Level: %', new_user_level;

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
    '25AAA0008', 'manee_suk', 'manee@fingrow.com', '0889012345',
    'มณี', 'สุข', 8,
    acf_parent_uuid, system_root_uuid, 'MANEE2025',
    0, 5, TRUE, new_user_level,
    'Atta', 'normal',
    1600.00, 4800.00,
    TRUE, 2, 76.0,
    12, 9,
    '234/56', 'ถนนพระราม 4', 'คลองเตย',
    'กรุงเทพมหานคร', '10110', 'สมาชิกใหม่ที่สนใจระบบ Fingrow',
    (EXTRACT(EPOCH FROM NOW()) * 1000)::BIGINT + 5000,
    (EXTRACT(EPOCH FROM NOW()) * 1000)::BIGINT + 5000
  ) RETURNING id INTO new_user_uuid;

  UPDATE users SET child_count = child_count + 1, updated_at = (EXTRACT(EPOCH FROM NOW()) * 1000)::BIGINT
  WHERE id = acf_parent_uuid;

  INSERT INTO simulated_fp_transactions (
    user_id, simulated_tx_type, simulated_source_type,
    simulated_base_amount, simulated_reverse_rate, simulated_generated_fp,
    simulated_self_fp, simulated_network_fp, simulated_status, created_at
  ) VALUES
  (new_user_uuid, 'SECONDHAND_SALE', 'secondhand_sale', 900.00, 0.10, 90.00, 40.50, 40.50, 'COMPLETED', NOW() - INTERVAL '3 days');

  -- User 2: 25AAA0009 (Wichai)
  SELECT find_next_acf_parent(system_root_uuid) INTO acf_parent_uuid;
  IF acf_parent_uuid IS NULL THEN
    RAISE EXCEPTION 'No available parent position for user 25AAA0009';
  END IF;

  SELECT world_id, username, level INTO acf_parent_world_id, acf_parent_username, acf_parent_level
  FROM users WHERE id = acf_parent_uuid;
  new_user_level := acf_parent_level + 1;

  RAISE NOTICE '';
  RAISE NOTICE '👤 User 2: 25AAA0009 (Wichai)';
  RAISE NOTICE '   Parent: % (%) - Level %', acf_parent_username, acf_parent_world_id, acf_parent_level;
  RAISE NOTICE '   New user Level: %', new_user_level;

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
    '25AAA0009', 'wichai_dee', 'wichai@fingrow.com', '0890123456',
    'วิชัย', 'ดี', 9,
    acf_parent_uuid, system_root_uuid, 'WICHAI2025',
    0, 5, TRUE, new_user_level,
    'Atta', 'normal',
    2200.00, 6800.00,
    TRUE, 2, 84.0,
    19, 14,
    '567/89', 'ถนนสุขุมวิท', 'วัฒนา',
    'กรุงเทพมหานคร', '10110', 'นักลงทุนที่สนใจการประกัน',
    (EXTRACT(EPOCH FROM NOW()) * 1000)::BIGINT + 6000,
    (EXTRACT(EPOCH FROM NOW()) * 1000)::BIGINT + 6000
  ) RETURNING id INTO new_user_uuid;

  UPDATE users SET child_count = child_count + 1, updated_at = (EXTRACT(EPOCH FROM NOW()) * 1000)::BIGINT
  WHERE id = acf_parent_uuid;

  INSERT INTO simulated_fp_transactions (
    user_id, simulated_tx_type, simulated_source_type,
    simulated_base_amount, simulated_reverse_rate, simulated_generated_fp,
    simulated_self_fp, simulated_network_fp, simulated_status, created_at
  ) VALUES
  (new_user_uuid, 'SECONDHAND_SALE', 'secondhand_sale', 1300.00, 0.10, 130.00, 58.50, 58.50, 'COMPLETED', NOW() - INTERVAL '2 days');

  -- User 3: 25AAA0010 (Pensri)
  SELECT find_next_acf_parent(system_root_uuid) INTO acf_parent_uuid;
  IF acf_parent_uuid IS NULL THEN
    RAISE EXCEPTION 'No available parent position for user 25AAA0010';
  END IF;

  SELECT world_id, username, level INTO acf_parent_world_id, acf_parent_username, acf_parent_level
  FROM users WHERE id = acf_parent_uuid;
  new_user_level := acf_parent_level + 1;

  RAISE NOTICE '';
  RAISE NOTICE '👤 User 3: 25AAA0010 (Pensri)';
  RAISE NOTICE '   Parent: % (%) - Level %', acf_parent_username, acf_parent_world_id, acf_parent_level;
  RAISE NOTICE '   New user Level: %', new_user_level;

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
    '25AAA0010', 'pensri_chai', 'pensri@fingrow.com', '0801234567',
    'เพ็ญศรี', 'ชัย', 10,
    acf_parent_uuid, system_root_uuid, 'PENSRI2025',
    0, 5, TRUE, new_user_level,
    'Atta', 'normal',
    1750.00, 5100.00,
    TRUE, 1, 72.5,
    13, 10,
    '890/12', 'ถนนพหลโยธิน', 'จตุจักร',
    'กรุงเทพมหานคร', '10900', 'ผู้สนใจธุรกิจขายของมือสอง',
    (EXTRACT(EPOCH FROM NOW()) * 1000)::BIGINT + 7000,
    (EXTRACT(EPOCH FROM NOW()) * 1000)::BIGINT + 7000
  ) RETURNING id INTO new_user_uuid;

  UPDATE users SET child_count = child_count + 1, updated_at = (EXTRACT(EPOCH FROM NOW()) * 1000)::BIGINT
  WHERE id = acf_parent_uuid;

  INSERT INTO simulated_fp_transactions (
    user_id, simulated_tx_type, simulated_source_type,
    simulated_base_amount, simulated_reverse_rate, simulated_generated_fp,
    simulated_self_fp, simulated_network_fp, simulated_status, created_at
  ) VALUES
  (new_user_uuid, 'SECONDHAND_SALE', 'secondhand_sale', 1100.00, 0.10, 110.00, 49.50, 49.50, 'COMPLETED', NOW() - INTERVAL '4 days');

  -- User 4: 25AAA0011 (Somkid)
  SELECT find_next_acf_parent(system_root_uuid) INTO acf_parent_uuid;
  IF acf_parent_uuid IS NULL THEN
    RAISE EXCEPTION 'No available parent position for user 25AAA0011';
  END IF;

  SELECT world_id, username, level INTO acf_parent_world_id, acf_parent_username, acf_parent_level
  FROM users WHERE id = acf_parent_uuid;
  new_user_level := acf_parent_level + 1;

  RAISE NOTICE '';
  RAISE NOTICE '👤 User 4: 25AAA0011 (Somkid)';
  RAISE NOTICE '   Parent: % (%) - Level %', acf_parent_username, acf_parent_world_id, acf_parent_level;
  RAISE NOTICE '   New user Level: %', new_user_level;

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
    '25AAA0011', 'somkid_sri', 'somkid@fingrow.com', '0812345678',
    'สมคิด', 'ศรี', 11,
    acf_parent_uuid, system_root_uuid, 'SOMKID2025',
    0, 5, TRUE, new_user_level,
    'Atta', 'normal',
    2400.00, 7500.00,
    TRUE, 3, 86.5,
    21, 15,
    '345/67', 'ถนนรัชดาภิเษก', 'ห้วยขวาง',
    'กรุงเทพมหานคร', '10310', 'ผู้ประกอบการที่ต้องการขยายเครือข่าย',
    (EXTRACT(EPOCH FROM NOW()) * 1000)::BIGINT + 8000,
    (EXTRACT(EPOCH FROM NOW()) * 1000)::BIGINT + 8000
  ) RETURNING id INTO new_user_uuid;

  UPDATE users SET child_count = child_count + 1, updated_at = (EXTRACT(EPOCH FROM NOW()) * 1000)::BIGINT
  WHERE id = acf_parent_uuid;

  INSERT INTO simulated_fp_transactions (
    user_id, simulated_tx_type, simulated_source_type,
    simulated_base_amount, simulated_reverse_rate, simulated_generated_fp,
    simulated_self_fp, simulated_network_fp, simulated_status, created_at
  ) VALUES
  (new_user_uuid, 'SECONDHAND_SALE', 'secondhand_sale', 1500.00, 0.10, 150.00, 67.50, 67.50, 'COMPLETED', NOW() - INTERVAL '1 day'),
  (new_user_uuid, 'NETWORK_BONUS', 'network_bonus', 500.00, 0.10, 50.00, 0.00, 50.00, 'COMPLETED', NOW() - INTERVAL '6 hours');

  RAISE NOTICE '';
  RAISE NOTICE '========================================';
  RAISE NOTICE '✅ Successfully created 4 new users:';
  RAISE NOTICE '   - 25AAA0008 (Manee Suk)';
  RAISE NOTICE '   - 25AAA0009 (Wichai Dee)';
  RAISE NOTICE '   - 25AAA0010 (Pensri Chai)';
  RAISE NOTICE '   - 25AAA0011 (Somkid Sri)';
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
WHERE u.world_id IN ('25AAA0008', '25AAA0009', '25AAA0010', '25AAA0011')
ORDER BY u.world_id;
