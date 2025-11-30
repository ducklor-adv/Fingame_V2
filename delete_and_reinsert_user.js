// Script to delete user 25AAA0007 and re-insert with ACF placement
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

async function deleteAndReinsert() {
  const client = await pool.connect();

  try {
    console.log('🗑️  Deleting user 25AAA0007...');
    const deleteSql = fs.readFileSync('./delete_user_25AAA0007.sql', 'utf8');

    await client.query('ALTER TABLE users DISABLE TRIGGER update_users_updated_at;');
    await client.query(deleteSql);
    await client.query('ALTER TABLE users ENABLE TRIGGER update_users_updated_at;');

    console.log('✅ User deleted successfully');

  } catch (error) {
    console.error('❌ Error:', error.message);
    throw error;
  } finally {
    client.release();
    await pool.end();
  }
}

deleteAndReinsert()
  .then(() => process.exit(0))
  .catch(err => {
    console.error(err);
    process.exit(1);
  });
