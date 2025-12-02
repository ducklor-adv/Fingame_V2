// Execute create insurance_product table script
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

async function createInsuranceProductTable() {
  const client = await pool.connect();

  try {
    console.log('\n' + '='.repeat(70));
    console.log('🚀 Creating insurance_product Table');
    console.log('='.repeat(70));

    // Read SQL file
    console.log('📝 Reading SQL script...');
    const sql = fs.readFileSync('./create_insurance_product_table.sql', 'utf8');

    console.log('⚡ Executing SQL...\n');

    // Execute the SQL script
    await client.query(sql);

    console.log('✅ Table insurance_product created successfully!');
    console.log('✅ Indexes created successfully!');
    console.log('✅ Trigger created successfully!');
    console.log('✅ Comments added successfully!');

    // Verify table creation
    console.log('\n📊 Verifying table structure...\n');
    const result = await client.query(`
      SELECT column_name, data_type, is_nullable, column_default
      FROM information_schema.columns
      WHERE table_name = 'insurance_product'
      ORDER BY ordinal_position
      LIMIT 15
    `);

    console.log('First 15 columns:');
    result.rows.forEach((row, idx) => {
      console.log(`  ${idx + 1}. ${row.column_name} (${row.data_type}) ${row.is_nullable === 'NO' ? 'NOT NULL' : 'NULL'}`);
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

createInsuranceProductTable()
  .then(() => {
    console.log('✅ Script completed successfully!');
    process.exit(0);
  })
  .catch(err => {
    console.error('❌ Script failed:', err);
    process.exit(1);
  });
