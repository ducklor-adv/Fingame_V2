-- ============================================================================
-- Insert 1 New User Invited by System Root (25AAA0000)
-- User: 25AAA0007 - Kanya Dee
-- ============================================================================

DO $$
DECLARE
  system_root_uuid UUID;
  new_user_uuid UUID;
BEGIN
  -- Get system_root UUID
  SELECT id INTO system_root_uuid FROM users WHERE world_id = '25AAA0000';

  IF system_root_uuid IS NULL THEN
    RAISE EXCEPTION 'System root (25AAA0000) not found in database';
  END IF;

  -- Create 25AAA0007 (Kanya)
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
    '25AAA0007',
    'kanya_dee',
    'kanya@fingrow.com',
    '0878901234',
    'กัญญา',
    'ดี',
    7,
    system_root_uuid,
    system_root_uuid,
    'KANYA2025',
    0,
    5,
    TRUE,
    1,
    'Atta',
    'normal',
    1950.00,
    5800.00,
    TRUE,
    2,
    80.0,
    14,
    11,
    '777/55',
    'ถนนงามวงศ์วาน',
    'บางเขน',
    'กรุงเทพมหานคร',
    '10220',
    'ผู้สนใจการลงทุนในระบบ Fingrow',
    (EXTRACT(EPOCH FROM NOW()) * 1000)::BIGINT + 4000,
    (EXTRACT(EPOCH FROM NOW()) * 1000)::BIGINT + 4000
  )
  RETURNING id INTO new_user_uuid;

  -- Update system_root's child count
  UPDATE users
  SET child_count = child_count + 1,
      updated_at = (EXTRACT(EPOCH FROM NOW()) * 1000)::BIGINT
  WHERE id = system_root_uuid;

  -- Create some FP transactions
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
  (new_user_uuid, 'SECONDHAND_SALE', 'secondhand_sale', 1000.00, 0.10, 100.00, 45.00, 45.00, 'COMPLETED', NOW() - INTERVAL '2 days'),
  (new_user_uuid, 'NETWORK_BONUS', 'network_bonus', 300.00, 0.10, 30.00, 0.00, 30.00, 'COMPLETED', NOW() - INTERVAL '8 hours');

  RAISE NOTICE '✅ Successfully created user 25AAA0007 (Kanya Dee)';
  RAISE NOTICE '   Invited by system_root (25AAA0000)';

END $$;

-- Verify
SELECT
  u.world_id,
  u.username,
  u.first_name,
  u.last_name,
  i.world_id as inviter_world_id,
  i.username as inviter_username,
  u.level,
  u.own_finpoint
FROM users u
LEFT JOIN users i ON u.inviter_id = i.id
WHERE u.world_id = '25AAA0007';
