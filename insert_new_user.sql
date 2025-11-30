-- ============================================================================
-- Insert New User Invited by Somchai Jaidee (25AAA0001)
-- User: 25AAA0003 - Supattra Sawadee
-- ============================================================================

DO $$
DECLARE
  inviter_uuid UUID;
  new_user_uuid UUID;
BEGIN
  -- Get Somchai's UUID (25AAA0001)
  SELECT id INTO inviter_uuid FROM users WHERE world_id = '25AAA0001';

  IF inviter_uuid IS NULL THEN
    RAISE EXCEPTION 'User 25AAA0001 (Somchai Jaidee) not found in database';
  END IF;

  -- Create new user 25AAA0003 (Supattra)
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
    '25AAA0003',
    'supattra_sawadee',
    'supattra@fingrow.com',
    '0834567890',
    'สุพัตรา',
    'สวัสดี',
    3,
    inviter_uuid, -- parent is 25AAA0001 (Somchai)
    inviter_uuid, -- invited by 25AAA0001 (Somchai)
    'SUPATTRA2025',
    0, -- no children yet
    5,
    TRUE,
    2, -- level 2 (child of level 1)
    'Atta',
    'normal',
    800.00,
    2500.00,
    TRUE,
    1,
    75.0,
    10,
    8,
    '789/12',
    'ถนนรัชดาภิเษก',
    'ห้วยขวาง',
    'กรุงเทพมหานคร',
    '10310',
    'สมาชิกใหม่ที่สนใจลงทุนในระบบ Fingrow',
    (EXTRACT(EPOCH FROM NOW()) * 1000)::BIGINT,
    (EXTRACT(EPOCH FROM NOW()) * 1000)::BIGINT
  )
  RETURNING id INTO new_user_uuid;

  -- Update Somchai's child count
  UPDATE users
  SET child_count = child_count + 1,
      updated_at = (EXTRACT(EPOCH FROM NOW()) * 1000)::BIGINT
  WHERE id = inviter_uuid;

  -- Create some FP transactions for the new user
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
  -- Transaction 1: Sell secondhand item
  (
    new_user_uuid,
    'SECONDHAND_SALE',
    'secondhand_sale',
    800.00,
    0.10,
    80.00,
    36.00,
    36.00,
    'COMPLETED',
    NOW() - INTERVAL '1 day'
  ),
  -- Transaction 2: Network bonus
  (
    new_user_uuid,
    'NETWORK_BONUS',
    'network_bonus',
    300.00,
    0.10,
    30.00,
    0.00,
    30.00,
    'COMPLETED',
    NOW() - INTERVAL '5 hours'
  );

  -- Create FP ledger entries
  INSERT INTO simulated_fp_ledger (
    simulated_tx_id,
    user_id,
    dr_cr,
    simulated_fp_amount,
    simulated_balance_after,
    simulated_tx_type,
    simulated_source_type,
    simulated_tx_datetime,
    created_at
  )
  SELECT
    t.id,
    new_user_uuid,
    'DR',
    t.simulated_self_fp,
    CASE
      WHEN t.simulated_tx_type = 'SECONDHAND_SALE' THEN 36.00
      WHEN t.simulated_tx_type = 'NETWORK_BONUS' THEN 66.00
    END,
    t.simulated_tx_type,
    t.simulated_source_type,
    t.created_at,
    t.created_at
  FROM simulated_fp_transactions t
  WHERE t.user_id = new_user_uuid
  ORDER BY t.created_at;

  RAISE NOTICE '✅ Successfully created user 25AAA0003 (Supattra Sawadee)';
  RAISE NOTICE '   - World ID: 25AAA0003';
  RAISE NOTICE '   - Username: supattra_sawadee';
  RAISE NOTICE '   - Email: supattra@fingrow.com';
  RAISE NOTICE '   - Inviter: 25AAA0001 (Somchai Jaidee)';
  RAISE NOTICE '   - FP Balance: 800.00';
  RAISE NOTICE '   - Level: 2';
  RAISE NOTICE '   - Transactions: 2 created';

END $$;

-- Verify the network structure
SELECT
  u.world_id,
  u.username,
  u.first_name,
  u.last_name,
  p.world_id as parent_world_id,
  p.username as parent_username,
  i.world_id as inviter_world_id,
  i.username as inviter_username,
  u.level,
  u.child_count,
  u.own_finpoint
FROM users u
LEFT JOIN users p ON u.parent_id = p.id
LEFT JOIN users i ON u.inviter_id = i.id
WHERE u.world_id IN ('25AAA0000', '25AAA0001', '25AAA0002', '25AAA0003')
ORDER BY u.level, u.world_id;
