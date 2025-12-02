// Fix child_count to match actual children
const fs = require('fs');
const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  port: process.env.DB_PORT || 5433,
  database: process.env.DB_NAME || 'fingame',
  user: process.env.DB_USER || 'fingrow_user',
  password: process.env.DB_PASSWORD || 'fingrow_pass_2025',
});

async function fixChildCount() {
  const client = await pool.connect();

  try {
    console.log('🔧 Fixing child_count for all users...');
    const sql = fs.readFileSync('./fix_child_count.sql', 'utf8');

    await client.query('ALTER TABLE users DISABLE TRIGGER update_users_updated_at;');
    const result = await client.query(sql);
    await client.query('ALTER TABLE users ENABLE TRIGGER update_users_updated_at;');

    console.log('✅ child_count fixed successfully!');

    if (result.rows && result.rows.length > 0) {
      console.log('\n⚠️  Remaining mismatches:');
      result.rows.forEach(row => {
        console.log(`   ${row.world_id} (${row.username}): ${row.child_count} vs ${row.actual_children}`);
      });
    } else {
      console.log('\n✅ All child_count values are correct!');
    }

  } catch (error) {
    console.error('❌ Error:', error.message);
    try {
      await client.query('ALTER TABLE users ENABLE TRIGGER update_users_updated_at;');
    } catch (e) {
      console.error('Failed to re-enable trigger:', e.message);
    }
    throw error;
  } finally {
    client.release();
    await pool.end();
  }
}

fixChildCount()
  .then(() => process.exit(0))
  .catch(err => {
    console.error(err);
    process.exit(1);
  });
