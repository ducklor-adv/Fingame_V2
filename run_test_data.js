// Script to insert test data into PostgreSQL
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

async function runTestData() {
  try {
    console.log('📝 Reading SQL file...');
    const sql = fs.readFileSync('./insert_test_user.sql', 'utf8');

    console.log('🔌 Connecting to database...');
    const client = await pool.connect();

    console.log('🚀 Executing SQL script...');
    const result = await client.query(sql);

    console.log('✅ Test data inserted successfully!');
    if (result.rows) {
      console.log('   Result:', result.rows);
    }

    client.release();
    await pool.end();

    console.log('\n📊 Verifying data...');
    process.exit(0);
  } catch (error) {
    console.error('❌ Error:', error.message);
    console.error(error.stack);
    await pool.end();
    process.exit(1);
  }
}

runTestData();
