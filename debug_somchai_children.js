// Debug Somchai's children
const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  port: process.env.DB_PORT || 5433,
  database: process.env.DB_NAME || 'fingame',
  user: process.env.DB_USER || 'fingrow_user',
  password: process.env.DB_PASSWORD || 'fingrow_pass_2025',
});

async function debugSomchai() {
  const client = await pool.connect();

  try {
    console.log('🔍 Debugging Somchai children...\n');

    // Get Somchai's UUID
    const somchaiResult = await client.query(`
      SELECT id, world_id, username, child_count
      FROM users
      WHERE world_id = '25AAA0001'
    `);

    if (somchaiResult.rows.length === 0) {
      console.log('❌ Somchai not found!');
      return;
    }

    const somchai = somchaiResult.rows[0];
    console.log('👤 Somchai Info:');
    console.log(`   ID: ${somchai.id}`);
    console.log(`   World ID: ${somchai.world_id}`);
    console.log(`   Username: ${somchai.username}`);
    console.log(`   child_count: ${somchai.child_count}`);

    // Get all children
    const childrenResult = await client.query(`
      SELECT
        world_id,
        username,
        first_name,
        last_name,
        level,
        created_at
      FROM users
      WHERE parent_id = $1
      ORDER BY created_at
    `, [somchai.id]);

    console.log(`\n📊 Actual children in database: ${childrenResult.rows.length}`);
    console.log('----------------------------------------');

    childrenResult.rows.forEach((child, i) => {
      console.log(`${i+1}. ${child.world_id} (${child.username})`);
      console.log(`   Name: ${child.first_name} ${child.last_name}`);
      console.log(`   Level: ${child.level}`);
      console.log(`   Created: ${child.created_at}`);
      console.log('');
    });

    // Check if there's a mismatch
    if (childrenResult.rows.length !== somchai.child_count) {
      console.log(`⚠️  MISMATCH!`);
      console.log(`   child_count column: ${somchai.child_count}`);
      console.log(`   Actual children: ${childrenResult.rows.length}`);
    }

  } catch (error) {
    console.error('❌ Error:', error.message);
    throw error;
  } finally {
    client.release();
    await pool.end();
  }
}

debugSomchai()
  .then(() => process.exit(0))
  .catch(err => {
    console.error(err);
    process.exit(1);
  });
