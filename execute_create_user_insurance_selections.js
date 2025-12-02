// Execute create user_insurance_selections table script
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

async function createUserInsuranceSelectionsTable() {
  const client = await pool.connect();

  try {
    console.log('\n' + '='.repeat(70));
    console.log('🚀 Creating user_insurance_selections Table');
    console.log('='.repeat(70));

    // Read SQL file
    console.log('📝 Reading SQL script...');
    const sql = fs.readFileSync('./create_user_insurance_selections_table.sql', 'utf8');

    console.log('⚡ Executing SQL...\n');

    // Execute the SQL script
    await client.query(sql);

    console.log('✅ Table user_insurance_selections created successfully!');
    console.log('✅ Indexes created successfully!');
    console.log('✅ Triggers created successfully!');
    console.log('✅ Comments added successfully!');

    // Verify table creation
    console.log('\n📊 Verifying table structure...\n');
    const result = await client.query(`
      SELECT column_name, data_type, is_nullable, column_default
      FROM information_schema.columns
      WHERE table_name = 'user_insurance_selections'
      ORDER BY ordinal_position
    `);

    console.log('Table columns:');
    result.rows.forEach((row, idx) => {
      console.log(`  ${idx + 1}. ${row.column_name} (${row.data_type}) ${row.is_nullable === 'NO' ? 'NOT NULL' : 'NULL'}`);
    });

    // Verify indexes
    console.log('\n📑 Verifying indexes...\n');
    const indexResult = await client.query(`
      SELECT indexname, indexdef
      FROM pg_indexes
      WHERE tablename = 'user_insurance_selections'
      ORDER BY indexname
    `);

    console.log('Indexes:');
    indexResult.rows.forEach((row, idx) => {
      console.log(`  ${idx + 1}. ${row.indexname}`);
    });

    // Verify triggers
    console.log('\n⚡ Verifying triggers...\n');
    const triggerResult = await client.query(`
      SELECT trigger_name, event_manipulation, event_object_table
      FROM information_schema.triggers
      WHERE event_object_table = 'user_insurance_selections'
      ORDER BY trigger_name
    `);

    console.log('Triggers:');
    triggerResult.rows.forEach((row, idx) => {
      console.log(`  ${idx + 1}. ${row.trigger_name} (${row.event_manipulation})`);
    });

    console.log('\n' + '='.repeat(70));
    console.log('✅ All operations completed successfully!');
    console.log('='.repeat(70) + '\n');

  } catch (error) {
    console.error('\n❌ Error:', error.message);
    console.error('Stack:', error.stack);
    throw error;
  } finally {
    client.release();
    await pool.end();
  }
}

createUserInsuranceSelectionsTable()
  .then(() => {
    console.log('✅ Script completed successfully!');
    process.exit(0);
  })
  .catch(err => {
    console.error('❌ Script failed:', err);
    process.exit(1);
  });
