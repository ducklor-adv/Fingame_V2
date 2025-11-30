// Check user placement
const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  port: process.env.DB_PORT || 5433,
  database: process.env.DB_NAME || 'fingame',
  user: process.env.DB_USER || 'fingrow_user',
  password: process.env.DB_PASSWORD || 'fingrow_pass_2025',
});

async function checkPlacement() {
  const client = await pool.connect();

  try {
    console.log('📊 Checking user 25AAA0007 placement...\n');

    const result = await client.query(`
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
        u.child_count
      FROM users u
      LEFT JOIN users i ON u.inviter_id = i.id
      LEFT JOIN users p ON u.parent_id = p.id
      WHERE u.world_id = '25AAA0007'
    `);

    if (result.rows.length > 0) {
      const user = result.rows[0];
      console.log('✅ User 25AAA0007 (Kanya Dee):');
      console.log(`   Username: ${user.username}`);
      console.log(`   Name: ${user.first_name} ${user.last_name}`);
      console.log(`   Inviter: ${user.inviter_world_id} (${user.inviter_username})`);
      console.log(`   Parent: ${user.parent_world_id} (${user.parent_username})`);
      console.log(`   Level: ${user.level}`);
      console.log(`   Children: ${user.child_count}`);
    } else {
      console.log('❌ User 25AAA0007 not found');
    }

    console.log('\n📊 System Root children:');
    const childrenResult = await client.query(`
      SELECT
        u.world_id,
        u.username,
        u.level,
        u.child_count
      FROM users u
      WHERE u.parent_id = (SELECT id FROM users WHERE world_id = '25AAA0000')
      ORDER BY u.created_at
    `);

    childrenResult.rows.forEach((child, i) => {
      console.log(`   ${i+1}. ${child.world_id} (${child.username}) - Level ${child.level}, ${child.child_count} children`);
    });

  } catch (error) {
    console.error('❌ Error:', error.message);
    throw error;
  } finally {
    client.release();
    await pool.end();
  }
}

checkPlacement()
  .then(() => process.exit(0))
  .catch(err => {
    console.error(err);
    process.exit(1);
  });
