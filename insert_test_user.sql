-- ============================================================================
-- Insert Test User with Complete Details
-- User: 25AAA0002 (ลูกของ 25AAA0001)
-- ============================================================================

-- First, get the UUID of the inviter (25AAA0001 - system root's first child)
-- We'll create 25AAA0001 first if it doesn't exist

DO $$
DECLARE
  inviter_uuid UUID;
  new_user_uuid UUID;
BEGIN
  -- Check if 25AAA0001 exists, if not create it
  SELECT id INTO inviter_uuid FROM users WHERE world_id = '25AAA0001';

  IF inviter_uuid IS NULL THEN
    -- Create 25AAA0001 first (child of system root)
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
      address_number,
      address_street,
      address_district,
      address_province,
      address_postal_code,
      created_at,
      updated_at
    ) VALUES (
      '25AAA0001',
      'somchai_jaidee',
      'somchai@fingrow.com',
      '0812345678',
      'สมชาย',
      'ใจดี',
      1,
      '00000000-0000-0000-0000-000000000000'::UUID, -- parent is system root
      '00000000-0000-0000-0000-000000000000'::UUID, -- invited by system root
      'SOMCHAI2025',
      0, -- no children yet
      5,
      TRUE,
      1,
      'Atta',
      'normal',
      3250.00,
      12500.00,
      TRUE,
      3,
      95.5,
      '123/45',
      'ถนนสุขุมวิท',
      'คลองเตย',
      'กรุงเทพมหานคร',
      '10110',
      (EXTRACT(EPOCH FROM NOW()) * 1000)::BIGINT,
      (EXTRACT(EPOCH FROM NOW()) * 1000)::BIGINT
    )
    RETURNING id INTO inviter_uuid;

    RAISE NOTICE 'Created user 25AAA0001 (Somchai)';
  END IF;

  -- Now create 25AAA0002 (child of 25AAA0001)
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
    '25AAA0002',
    'somsri_rakdee',
    'somsri@fingrow.com',
    '0823456789',
    'สมศรี',
    'รักดี',
    2,
    inviter_uuid, -- parent is 25AAA0001
    inviter_uuid, -- invited by 25AAA0001
    'SOMSRI2025',
    0, -- no children yet
    5,
    TRUE,
    0,
    'Atta',
    'normal',
    1500.00,
    5000.00,
    TRUE,
    2,
    87.5,
    25,
    15,
    '456/78',
    'ถนนพระราม 4',
    'คลองเตย',
    'กรุงเทพมหานคร',
    '10110',
    'สมาชิกใหม่ของ Fingrow ที่สนใจซื้อขายของมือสอง',
    (EXTRACT(EPOCH FROM NOW()) * 1000)::BIGINT,
    (EXTRACT(EPOCH FROM NOW()) * 1000)::BIGINT
  )
  RETURNING id INTO new_user_uuid;

  -- Update inviter's child count
  UPDATE users
  SET child_count = child_count + 1
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
    1000.00,
    0.10,
    100.00,
    45.00,
    45.00,
    'COMPLETED',
    NOW() - INTERVAL '2 days'
  ),
  -- Transaction 2: Network bonus
  (
    new_user_uuid,
    'NETWORK_BONUS',
    'network_bonus',
    500.00,
    0.10,
    50.00,
    0.00,
    50.00,
    'COMPLETED',
    NOW() - INTERVAL '1 day'
  ),
  -- Transaction 3: Purchase insurance
  (
    new_user_uuid,
    'INSURANCE_PURCHASE',
    'insurance_LEVEL_1',
    600.00,
    1.00,
    600.00,
    0.00,
    0.00,
    'COMPLETED',
    NOW() - INTERVAL '3 hours'
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
    CASE
      WHEN t.simulated_tx_type = 'INSURANCE_PURCHASE' THEN 'CR'
      ELSE 'DR'
    END,
    CASE
      WHEN t.simulated_tx_type = 'INSURANCE_PURCHASE' THEN t.simulated_generated_fp
      ELSE t.simulated_self_fp
    END,
    CASE
      WHEN t.simulated_tx_type = 'SECONDHAND_SALE' THEN 45.00
      WHEN t.simulated_tx_type = 'NETWORK_BONUS' THEN 95.00
      WHEN t.simulated_tx_type = 'INSURANCE_PURCHASE' THEN -505.00
    END,
    t.simulated_tx_type,
    t.simulated_source_type,
    t.created_at,
    t.created_at
  FROM simulated_fp_transactions t
  WHERE t.user_id = new_user_uuid
  ORDER BY t.created_at;

  RAISE NOTICE '✅ Successfully created user 25AAA0002 (Somsri Rakdee)';
  RAISE NOTICE '   - World ID: 25AAA0002';
  RAISE NOTICE '   - Username: somsri_rakdee';
  RAISE NOTICE '   - Email: somsri@fingrow.com';
  RAISE NOTICE '   - Inviter: 25AAA0001 (Somchai Jaidee)';
  RAISE NOTICE '   - FP Balance: 1500.00';
  RAISE NOTICE '   - Transactions: 3 created';

END $$;
