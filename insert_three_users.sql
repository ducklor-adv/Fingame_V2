-- ============================================================================
-- Insert 3 New Users Invited by System Root (25AAA0000)
-- Users: 25AAA0004, 25AAA0005, 25AAA0006
-- ============================================================================

DO $$
DECLARE
  system_root_uuid UUID;
  user_uuid_4 UUID;
  user_uuid_5 UUID;
  user_uuid_6 UUID;
BEGIN
  -- Get system_root UUID
  SELECT id INTO system_root_uuid FROM users WHERE world_id = '25AAA0000';

  IF system_root_uuid IS NULL THEN
    RAISE EXCEPTION 'System root (25AAA0000) not found in database';
  END IF;

  -- Create 25AAA0004 (Nattawut)
  INSERT INTO users (
    world_id,
    username,
    email,
    phone,
    first_name,
    last_name,
    run_number,
    parent_id,
    inviter_id,
    invite_code,
    child_count,
    max_children,
    acf_accepting,
    level,
    user_type,
    regist_type,
    own_finpoint,
    total_finpoint,
    is_verified,
    verification_level,
    trust_score,
    total_sales,
    total_purchases,
    address_number,
    address_street,
    address_district,
    address_province,
    address_postal_code,
    bio,
    created_at,
    updated_at
  ) VALUES (
    '25AAA0004',
    'nattawut_chai',
    'nattawut@fingrow.com',
    '0845678901',
    'ณัฐวุฒิ',
    'ชัยชนะ',
    4,
    system_root_uuid,
    system_root_uuid,
    'NATTAWUT2025',
    0,
    5,
    TRUE,
    1,
    'Atta',
    'normal',
    2100.00,
    6500.00,
    TRUE,
    2,
    82.0,
    18,
    12,
    '321/99',
    'ถนนเพชรบุรี',
    'ราชเทวี',
    'กรุงเทพมหานคร',
    '10400',
    'นักลงทุนในระบบ Fingrow ที่สนใจธุรกิจประกัน',
    (EXTRACT(EPOCH FROM NOW()) * 1000)::BIGINT + 1000,
    (EXTRACT(EPOCH FROM NOW()) * 1000)::BIGINT + 1000
  )
  RETURNING id INTO user_uuid_4;

  -- Create 25AAA0005 (Apinya)
  INSERT INTO users (
    world_id,
    username,
    email,
    phone,
    first_name,
    last_name,
    run_number,
    parent_id,
    inviter_id,
    invite_code,
    child_count,
    max_children,
    acf_accepting,
    level,
    user_type,
    regist_type,
    own_finpoint,
    total_finpoint,
    is_verified,
    verification_level,
    trust_score,
    total_sales,
    total_purchases,
    address_number,
    address_street,
    address_district,
    address_province,
    address_postal_code,
    bio,
    created_at,
    updated_at
  ) VALUES (
    '25AAA0005',
    'apinya_sri',
    'apinya@fingrow.com',
    '0856789012',
    'อภิญญา',
    'ศรีสุข',
    5,
    system_root_uuid,
    system_root_uuid,
    'APINYA2025',
    0,
    5,
    TRUE,
    1,
    'Atta',
    'normal',
    1800.00,
    5200.00,
    TRUE,
    2,
    78.5,
    15,
    10,
    '555/21',
    'ถนนวิภาวดีรังสิต',
    'จตุจักร',
    'กรุงเทพมหานคร',
    '10900',
    'สมาชิกใหม่ที่สนใจการลงทุนและประกัน',
    (EXTRACT(EPOCH FROM NOW()) * 1000)::BIGINT + 2000,
    (EXTRACT(EPOCH FROM NOW()) * 1000)::BIGINT + 2000
  )
  RETURNING id INTO user_uuid_5;

  -- Create 25AAA0006 (Preecha)
  INSERT INTO users (
    world_id,
    username,
    email,
    phone,
    first_name,
    last_name,
    run_number,
    parent_id,
    inviter_id,
    invite_code,
    child_count,
    max_children,
    acf_accepting,
    level,
    user_type,
    regist_type,
    own_finpoint,
    total_finpoint,
    is_verified,
    verification_level,
    trust_score,
    total_sales,
    total_purchases,
    address_number,
    address_street,
    address_district,
    address_province,
    address_postal_code,
    bio,
    created_at,
    updated_at
  ) VALUES (
    '25AAA0006',
    'preecha_mana',
    'preecha@fingrow.com',
    '0867890123',
    'ปรีชา',
    'มานะ',
    6,
    system_root_uuid,
    system_root_uuid,
    'PREECHA2025',
    0,
    5,
    TRUE,
    1,
    'Atta',
    'normal',
    2500.00,
    7800.00,
    TRUE,
    3,
    88.0,
    22,
    16,
    '888/77',
    'ถนนลาดพร้าว',
    'จตุจักร',
    'กรุงเทพมหานคร',
    '10900',
    'ผู้ประกอบการที่ต้องการขยายเครือข่าย',
    (EXTRACT(EPOCH FROM NOW()) * 1000)::BIGINT + 3000,
    (EXTRACT(EPOCH FROM NOW()) * 1000)::BIGINT + 3000
  )
  RETURNING id INTO user_uuid_6;

  -- Update system_root's child count
  UPDATE users
  SET child_count = child_count + 3,
      updated_at = (EXTRACT(EPOCH FROM NOW()) * 1000)::BIGINT
  WHERE id = system_root_uuid;

  -- Create some FP transactions for user 4
  INSERT INTO simulated_fp_transactions (
    user_id,
    simulated_tx_type,
    simulated_source_type,
    simulated_base_amount,
    simulated_reverse_rate,
    simulated_generated_fp,
    simulated_self_fp,
    simulated_network_fp,
    simulated_status,
    created_at
  ) VALUES
  (user_uuid_4, 'SECONDHAND_SALE', 'secondhand_sale', 1200.00, 0.10, 120.00, 54.00, 54.00, 'COMPLETED', NOW() - INTERVAL '2 days'),
  (user_uuid_4, 'NETWORK_BONUS', 'network_bonus', 400.00, 0.10, 40.00, 0.00, 40.00, 'COMPLETED', NOW() - INTERVAL '1 day');

  -- Create some FP transactions for user 5
  INSERT INTO simulated_fp_transactions (
    user_id,
    simulated_tx_type,
    simulated_source_type,
    simulated_base_amount,
    simulated_reverse_rate,
    simulated_generated_fp,
    simulated_self_fp,
    simulated_network_fp,
    simulated_status,
    created_at
  ) VALUES
  (user_uuid_5, 'SECONDHAND_SALE', 'secondhand_sale', 900.00, 0.10, 90.00, 40.50, 40.50, 'COMPLETED', NOW() - INTERVAL '3 days'),
  (user_uuid_5, 'NETWORK_BONUS', 'network_bonus', 350.00, 0.10, 35.00, 0.00, 35.00, 'COMPLETED', NOW() - INTERVAL '6 hours');

  -- Create some FP transactions for user 6
  INSERT INTO simulated_fp_transactions (
    user_id,
    simulated_tx_type,
    simulated_source_type,
    simulated_base_amount,
    simulated_reverse_rate,
    simulated_generated_fp,
    simulated_self_fp,
    simulated_network_fp,
    simulated_status,
    created_at
  ) VALUES
  (user_uuid_6, 'SECONDHAND_SALE', 'secondhand_sale', 1500.00, 0.10, 150.00, 67.50, 67.50, 'COMPLETED', NOW() - INTERVAL '4 days'),
  (user_uuid_6, 'INSURANCE_PURCHASE', 'insurance_LEVEL_1', 600.00, 1.00, 600.00, 0.00, 0.00, 'COMPLETED', NOW() - INTERVAL '2 hours');

  RAISE NOTICE '✅ Successfully created 3 new users:';
  RAISE NOTICE '   - 25AAA0004 (Nattawut Chai)';
  RAISE NOTICE '   - 25AAA0005 (Apinya Sri)';
  RAISE NOTICE '   - 25AAA0006 (Preecha Mana)';
  RAISE NOTICE '   All invited by system_root (25AAA0000)';

END $$;

-- Verify the changes
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
WHERE u.world_id IN ('25AAA0000', '25AAA0001', '25AAA0002', '25AAA0003', '25AAA0004', '25AAA0005', '25AAA0006')
ORDER BY u.level, u.created_at;
