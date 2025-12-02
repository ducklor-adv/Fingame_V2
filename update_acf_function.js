// Update ACF placement function
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

async function updateACFFunction() {
  const client = await pool.connect();

  try {
    console.log('📝 Reading SQL file...');
    const sql = fs.readFileSync('./fix_acf_placement_function.sql', 'utf8');

    console.log('🔧 Updating ACF placement function...');
    await client.query(sql);

    console.log('✅ ACF placement function updated successfully!');
    console.log('\n📊 Function now uses real-time COUNT instead of child_count column');
    console.log('   This fixes the issue where children were placed incorrectly');

  } catch (error) {
    console.error('❌ Error:', error.message);
    throw error;
  } finally {
    client.release();
    await pool.end();
  }
}

updateACFFunction()
  .then(() => process.exit(0))
  .catch(err => {
    console.error(err);
    process.exit(1);
  });
