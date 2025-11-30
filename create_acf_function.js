// Script to create ACF placement function
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

async function createACFFunction() {
  const client = await pool.connect();

  try {
    console.log('📝 Reading SQL file...');
    const sql = fs.readFileSync('./create_acf_placement_function.sql', 'utf8');

    console.log('🔌 Connecting to database...');
    console.log('🚀 Creating ACF placement function...');

    const result = await client.query(sql);

    console.log('✅ ACF placement function created successfully!');
    console.log('\n📊 Function: find_next_acf_parent(inviter_user_id UUID)');
    console.log('   Returns: UUID of next available parent position');
    console.log('   Logic: 5 branches, 7 levels, fill top-to-bottom, left-to-right');

  } catch (error) {
    console.error('❌ Error:', error.message);
    throw error;
  } finally {
    client.release();
    await pool.end();
  }
}

createACFFunction()
  .then(() => process.exit(0))
  .catch(err => {
    console.error(err);
    process.exit(1);
  });
