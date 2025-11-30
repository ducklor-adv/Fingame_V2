/**
 * Insert Test User Script
 * Creates a new user with complete details
 * User: 25AAA0002 (child of 25AAA0001)
 */

require('dotenv').config();
const { Pool } = require('pg');

const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  port: parseInt(process.env.DB_PORT) || 5433,
  database: process.env.DB_NAME || 'fingame',
  user: process.env.DB_USER || 'fingrow_user',
  password: process.env.DB_PASSWORD || 'fingrow_pass_2025',
});

async function insertTestUser() {
  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    // Disable triggers temporarily
    await client.query('SET session_replication_role = replica');

    console.log('🔍 Checking if 25AAA0001 exists...');

    // Check if 25AAA0001 exists
    const inviterCheck = await client.query(
      'SELECT id FROM users WHERE world_id = $1',
      ['25AAA0001']
    );

    let inviterId;

    if (inviterCheck.rows.length === 0) {
      console.log('📝 Creating 25AAA0001 (Somchai Jaidee) first...');

      // Create 25AAA0001 first
      const inviterResult = await client.query(
        `INSERT INTO users (
          world_id, username, email, phone, first_name, last_name,
          run_number, parent_id, inviter_id, invite_code,
          child_count, max_children, acf_accepting, level,
          user_type, regist_type, own_finpoint, total_finpoint,
          is_verified, verification_level, trust_score,
          address_number, address_street, address_district,
          address_province, address_postal_code,
          created_at, updated_at
        ) VALUES (
          $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14,
          $15, $16, $17, $18, $19, $20, $21, $22, $23, $24, $25, $26, $27, $28
        ) RETURNING id`,
        [
          '25AAA0001',
          'somchai_jaidee',
          'somchai@fingrow.com',
          '0812345678',
          'สมชาย',
          'ใจดี',
          1,
          '00000000-0000-0000-0000-000000000000', // parent is system root
          '00000000-0000-0000-0000-000000000000', // invited by system root
          'SOMCHAI2025',
          0,
          5,
          true,
          1,
          'Atta',
          'normal',
          3250.00,
          12500.00,
          true,
          3,
          95.5,
          '123/45',
          'ถนนสุขุมวิท',
          'คลองเตย',
          'กรุงเทพมหานคร',
          '10110',
          Date.now(),
          Date.now()
        ]
      );

      inviterId = inviterResult.rows[0].id;
      console.log('✅ Created 25AAA0001');
    } else {
      inviterId = inviterCheck.rows[0].id;
      console.log('✅ 25AAA0001 already exists');
    }

    console.log('📝 Creating 25AAA0002 (Somsri Rakdee)...');

    // Create 25AAA0002
    const newUserResult = await client.query(
      `INSERT INTO users (
        world_id, username, email, phone, first_name, last_name,
        run_number, parent_id, inviter_id, invite_code,
        child_count, max_children, acf_accepting, level,
        user_type, regist_type, own_finpoint, total_finpoint,
        is_verified, verification_level, trust_score,
        total_sales, total_purchases,
        address_number, address_street, address_district,
        address_province, address_postal_code, bio,
        created_at, updated_at
      ) VALUES (
        $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14,
        $15, $16, $17, $18, $19, $20, $21, $22, $23, $24, $25, $26, $27, $28, $29, $30, $31
      ) RETURNING id, world_id, username, email`,
      [
        '25AAA0002',
        'somsri_rakdee',
        'somsri@fingrow.com',
        '0823456789',
        'สมศรี',
        'รักดี',
        2,
        inviterId, // parent is 25AAA0001
        inviterId, // invited by 25AAA0001
        'SOMSRI2025',
        0,
        5,
        true,
        0,
        'Atta',
        'normal',
        1500.00,
        5000.00,
        true,
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
        Date.now(),
        Date.now()
      ]
    );

    const newUser = newUserResult.rows[0];
    console.log('✅ Created user:', newUser);

    // Update inviter's child count (disable trigger temporarily)
    await client.query(
      'UPDATE users SET child_count = child_count + 1, updated_at = $2 WHERE id = $1',
      [inviterId, Date.now()]
    );
    console.log('✅ Updated inviter child count');

    // Create FP transactions
    console.log('📝 Creating FP transactions...');

    const tx1 = await client.query(
      `INSERT INTO simulated_fp_transactions (
        user_id, simulated_tx_type, simulated_source_type,
        simulated_base_amount, simulated_reverse_rate, simulated_generated_fp,
        simulated_self_fp, simulated_network_fp, simulated_status, created_at
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, NOW() - INTERVAL '2 days')
      RETURNING id`,
      [newUser.id, 'SECONDHAND_SALE', 'secondhand_sale', 1000, 0.10, 100, 45, 45, 'COMPLETED']
    );

    const tx2 = await client.query(
      `INSERT INTO simulated_fp_transactions (
        user_id, simulated_tx_type, simulated_source_type,
        simulated_base_amount, simulated_reverse_rate, simulated_generated_fp,
        simulated_self_fp, simulated_network_fp, simulated_status, created_at
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, NOW() - INTERVAL '1 day')
      RETURNING id`,
      [newUser.id, 'NETWORK_BONUS', 'network_bonus', 500, 0.10, 50, 0, 50, 'COMPLETED']
    );

    const tx3 = await client.query(
      `INSERT INTO simulated_fp_transactions (
        user_id, simulated_tx_type, simulated_source_type,
        simulated_base_amount, simulated_reverse_rate, simulated_generated_fp,
        simulated_self_fp, simulated_network_fp, simulated_status, created_at
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, NOW() - INTERVAL '3 hours')
      RETURNING id`,
      [newUser.id, 'INSURANCE_PURCHASE', 'insurance_LEVEL_1', 600, 1.0, 600, 0, 0, 'COMPLETED']
    );

    // Create ledger entries
    await client.query(
      `INSERT INTO simulated_fp_ledger (
        simulated_tx_id, user_id, dr_cr, simulated_fp_amount,
        simulated_balance_after, simulated_tx_type, simulated_source_type,
        simulated_tx_datetime, created_at
      ) VALUES
      ($1, $2, 'DR', 45, 45, 'SECONDHAND_SALE', 'secondhand_sale', NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days'),
      ($3, $4, 'DR', 50, 95, 'NETWORK_BONUS', 'network_bonus', NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day'),
      ($5, $6, 'CR', 600, -505, 'INSURANCE_PURCHASE', 'insurance_LEVEL_1', NOW() - INTERVAL '3 hours', NOW() - INTERVAL '3 hours')`,
      [tx1.rows[0].id, newUser.id, tx2.rows[0].id, newUser.id, tx3.rows[0].id, newUser.id]
    );

    console.log('✅ Created 3 FP transactions');

    // Re-enable triggers
    await client.query('SET session_replication_role = DEFAULT');

    await client.query('COMMIT');

    console.log('\n' + '='.repeat(60));
    console.log('✅ Successfully created test user!');
    console.log('='.repeat(60));
    console.log('📋 User Details:');
    console.log('   - World ID: 25AAA0002');
    console.log('   - Username: somsri_rakdee');
    console.log('   - Email: somsri@fingrow.com');
    console.log('   - Password: (not set - for testing only)');
    console.log('   - Name: สมศรี รักดี');
    console.log('   - Phone: 0823456789');
    console.log('   - Inviter: 25AAA0001 (สมชาย ใจดี)');
    console.log('   - FP Balance: 1,500.00');
    console.log('   - Address: 456/78 ถนนพระราม 4 คลองเตย กรุงเทพมหานคร 10110');
    console.log('   - Trust Score: 87.5');
    console.log('   - Total Sales: 25');
    console.log('   - Total Purchases: 15');
    console.log('='.repeat(60));

  } catch (error) {
    await client.query('ROLLBACK');
    console.error('❌ Error creating user:', error);
    throw error;
  } finally {
    client.release();
    await pool.end();
  }
}

insertTestUser().catch(console.error);
