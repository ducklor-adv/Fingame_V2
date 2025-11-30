// Script to update test users to be invited by system_root
const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  port: process.env.DB_PORT || 5433,
  database: process.env.DB_NAME || 'fingame',
  user: process.env.DB_USER || 'fingrow_user',
  password: process.env.DB_PASSWORD || 'fingrow_pass_2025',
});

async function updateInviter() {
  const client = await pool.connect();

  try {
    console.log('🔌 Connected to database');

    // Get system_root UUID
    const rootResult = await client.query(
      "SELECT id FROM users WHERE world_id = '25AAA0000'"
    );

    if (rootResult.rows.length === 0) {
      throw new Error('System root (25AAA0000) not found');
    }

    const systemRootId = rootResult.rows[0].id;
    console.log(`✅ Found system_root: ${systemRootId}`);

    // Get current timestamp in milliseconds
    const now = Date.now();

    // Update 25AAA0001 (Somchai)
    await client.query(
      `UPDATE users
       SET parent_id = $1, inviter_id = $1, level = 1, updated_at = $2
       WHERE world_id = '25AAA0001'`,
      [systemRootId, now]
    );
    console.log('✅ Updated 25AAA0001 (Somchai) - parent/inviter set to system_root');

    // Update 25AAA0002 (Somsri)
    await client.query(
      `UPDATE users
       SET parent_id = $1, inviter_id = $1, level = 1, updated_at = $2
       WHERE world_id = '25AAA0002'`,
      [systemRootId, now]
    );
    console.log('✅ Updated 25AAA0002 (Somsri) - parent/inviter set to system_root');

    // Update system_root's child_count
    await client.query(
      `UPDATE users
       SET child_count = (
         SELECT COUNT(*) FROM users WHERE parent_id = $1
       ),
       updated_at = $2
       WHERE id = $1`,
      [systemRootId, now]
    );
    console.log('✅ Updated system_root child_count');

    // Verify the changes
    console.log('\n📊 Verifying changes...');
    const verifyResult = await client.query(
      `SELECT
        u.world_id,
        u.username,
        p.world_id as parent_world_id,
        p.username as parent_username,
        u.level,
        u.child_count
       FROM users u
       LEFT JOIN users p ON u.parent_id = p.id
       WHERE u.world_id IN ('25AAA0000', '25AAA0001', '25AAA0002')
       ORDER BY u.world_id`
    );

    console.log('\n📋 Current Network Structure:');
    verifyResult.rows.forEach(row => {
      console.log(`\n   ${row.world_id} (${row.username})`);
      if (row.parent_world_id) {
        console.log(`      Parent: ${row.parent_world_id} (${row.parent_username})`);
      }
      console.log(`      Level: ${row.level}, Children: ${row.child_count || 0}`);
    });

    console.log('\n✅ Complete! Both test users are now invited by system_root.');
    console.log('\n📊 Final Structure:');
    console.log('   System Root (25AAA0000)');
    console.log('   ├── 25AAA0001 (Somchai Jaidee)');
    console.log('   └── 25AAA0002 (Somsri Rakdee)');

  } catch (error) {
    console.error('❌ Error:', error.message);
    throw error;
  } finally {
    client.release();
    await pool.end();
  }
}

updateInviter()
  .then(() => process.exit(0))
  .catch(err => {
    console.error(err);
    process.exit(1);
  });
