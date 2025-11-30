// Script to add 3 new users invited by system_root
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

async function addThreeUsers() {
  const client = await pool.connect();

  try {
    console.log('📝 Reading SQL file...');
    const sql = fs.readFileSync('./insert_three_users.sql', 'utf8');

    console.log('🔌 Connecting to database...');
    console.log('🚀 Executing SQL script...');

    // Disable trigger temporarily
    await client.query('ALTER TABLE users DISABLE TRIGGER update_users_updated_at;');

    const result = await client.query(sql);

    // Re-enable trigger
    await client.query('ALTER TABLE users ENABLE TRIGGER update_users_updated_at;');

    console.log('✅ Three new users added successfully!');

    if (result.rows && result.rows.length > 0) {
      console.log('\n📊 Network Structure:');
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

    console.log('\n✅ Complete! 3 new users added to system_root network.');
    console.log('\n📊 Updated Network Tree:');
    console.log('   System Root (25AAA0000) - 5 direct children');
    console.log('   ├── Somchai Jaidee (25AAA0001)');
    console.log('   │   └── Supattra Sawadee (25AAA0003)');
    console.log('   ├── Somsri Rakdee (25AAA0002)');
    console.log('   ├── Nattawut Chai (25AAA0004) ⭐ NEW');
    console.log('   ├── Apinya Sri (25AAA0005) ⭐ NEW');
    console.log('   └── Preecha Mana (25AAA0006) ⭐ NEW');

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

addThreeUsers()
  .then(() => process.exit(0))
  .catch(err => {
    console.error(err);
    process.exit(1);
  });
