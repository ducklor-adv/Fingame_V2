// Reset users 25AAA0007-25AAA0011
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

async function resetUsers() {
  const client = await pool.connect();

  try {
    console.log('🗑️  Deleting users 25AAA0007-25AAA0011...');
    const sql = fs.readFileSync('./reset_and_readd_users.sql', 'utf8');

    await client.query('ALTER TABLE users DISABLE TRIGGER update_users_updated_at;');
    await client.query(sql);
    await client.query('ALTER TABLE users ENABLE TRIGGER update_users_updated_at;');

    console.log('✅ Users deleted successfully!');
    console.log('\n📊 Ready to re-add with correct ACF placement');

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

resetUsers()
  .then(() => process.exit(0))
  .catch(err => {
    console.error(err);
    process.exit(1);
  });
