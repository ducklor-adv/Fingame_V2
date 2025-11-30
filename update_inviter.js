// Script to update test users to be invited by system_root
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

async function updateInviter() {
  try {
    console.log('📝 Reading SQL file...');
    const sql = fs.readFileSync('./update_inviter_to_systemroot.sql', 'utf8');

    console.log('🔌 Connecting to database...');
    const client = await pool.connect();

    console.log('🚀 Executing SQL script...');
    const result = await client.query(sql);

    console.log('✅ Database updated successfully!');
    console.log('\n📊 Verification Results:');
    if (result.rows && result.rows.length > 0) {
      result.rows.forEach(row => {
        console.log(`   ${row.world_id} (${row.username})`);
        console.log(`      Parent: ${row.parent_world_id} (${row.parent_username})`);
        console.log(`      Inviter: ${row.inviter_world_id} (${row.inviter_username})`);
        console.log(`      Level: ${row.level}, Children: ${row.child_count}`);
        console.log('');
      });
    }

    client.release();
    await pool.end();

    console.log('✅ Complete! Both test users are now invited by system_root.');
    process.exit(0);
  } catch (error) {
    console.error('❌ Error:', error.message);
    console.error(error.stack);
    await pool.end();
    process.exit(1);
  }
}

updateInviter();
