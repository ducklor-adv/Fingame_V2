// Check network structure after adding users
const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  port: process.env.DB_PORT || 5433,
  database: process.env.DB_NAME || 'fingame',
  user: process.env.DB_USER || 'fingrow_user',
  password: process.env.DB_PASSWORD || 'fingrow_pass_2025',
});

async function checkNetwork() {
  const client = await pool.connect();

  try {
    console.log('📊 Network Structure (ACF Placement)\n');
    console.log('========================================');

    // Get all users ordered by level and created_at
    const result = await client.query(`
      SELECT
        u.world_id,
        u.username,
        u.level,
        u.child_count,
        i.world_id as inviter_world_id,
        i.username as inviter_username,
        p.world_id as parent_world_id,
        p.username as parent_username
      FROM users u
      LEFT JOIN users i ON u.inviter_id = i.id
      LEFT JOIN users p ON u.parent_id = p.id
      ORDER BY u.level, u.created_at
    `);

    let currentLevel = -1;
    result.rows.forEach(user => {
      if (user.level !== currentLevel) {
        currentLevel = user.level;
        console.log(`\n📍 Level ${currentLevel}:`);
        console.log('----------------------------------------');
      }

      const indent = '  '.repeat(currentLevel);
      console.log(`${indent}${user.world_id} (${user.username})`);
      if (user.inviter_world_id) {
        console.log(`${indent}  ↳ Inviter: ${user.inviter_world_id} (${user.inviter_username})`);
      }
      if (user.parent_world_id) {
        console.log(`${indent}  ↳ Parent: ${user.parent_world_id} (${user.parent_username})`);
      }
      console.log(`${indent}  ↳ Children: ${user.child_count}/5`);
    });

    console.log('\n========================================');
    console.log('📊 Summary by Level:');
    console.log('----------------------------------------');

    const summaryResult = await client.query(`
      SELECT level, COUNT(*) as user_count
      FROM users
      GROUP BY level
      ORDER BY level
    `);

    summaryResult.rows.forEach(row => {
      console.log(`Level ${row.level}: ${row.user_count} users`);
    });

    console.log('\n========================================');
    console.log('📊 System Root Network:');
    console.log('----------------------------------------');

    const rootChildrenResult = await client.query(`
      SELECT
        u.world_id,
        u.username,
        u.child_count,
        u.level
      FROM users u
      WHERE u.parent_id = (SELECT id FROM users WHERE world_id = '25AAA0000')
      ORDER BY u.created_at
    `);

    console.log(`Total direct children: ${rootChildrenResult.rows.length}/5\n`);
    rootChildrenResult.rows.forEach((child, i) => {
      console.log(`${i+1}. ${child.world_id} (${child.username}) - ${child.child_count}/5 children`);
    });

  } catch (error) {
    console.error('❌ Error:', error.message);
    throw error;
  } finally {
    client.release();
    await pool.end();
  }
}

checkNetwork()
  .then(() => process.exit(0))
  .catch(err => {
    console.error(err);
    process.exit(1);
  });
