// Script to add 7 new users with ACF placement
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

async function addSevenUsers() {
  const client = await pool.connect();

  try {
    console.log('📝 Reading SQL file...');
    const sql = fs.readFileSync('./insert_seven_users_with_acf.sql', 'utf8');

    console.log('🔌 Connecting to database...');
    console.log('🚀 Executing SQL script with ACF placement...');

    // Disable trigger temporarily
    await client.query('ALTER TABLE users DISABLE TRIGGER update_users_updated_at;');

    const result = await client.query(sql);

    // Re-enable trigger
    await client.query('ALTER TABLE users ENABLE TRIGGER update_users_updated_at;');

    console.log('✅ Seven new users added successfully with ACF placement!');

    if (result.rows && result.rows.length > 0) {
      console.log('\n📊 New Users Details:');
      result.rows.forEach(row => {
        console.log(`\n   ${row.world_id} - ${row.first_name} ${row.last_name} (${row.username})`);
        if (row.inviter_world_id) {
          console.log(`      Inviter: ${row.inviter_world_id} (${row.inviter_username})`);
        }
        if (row.parent_world_id) {
          console.log(`      Parent: ${row.parent_world_id} (${row.parent_username})`);
        }
        console.log(`      Level: ${row.level}, Children: ${row.child_count || 0}, FP: ${row.own_finpoint || 0}`);
      });
    }

    console.log('\n✅ Complete! 7 new users added to system_root network with ACF placement.');

  } catch (error) {
    console.error('❌ Error:', error.message);
    // Try to re-enable trigger
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

addSevenUsers()
  .then(() => process.exit(0))
  .catch(err => {
    console.error(err);
    process.exit(1);
  });
