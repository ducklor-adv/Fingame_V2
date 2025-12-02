// Execute insert sample insurance products script
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

async function insertSampleInsuranceProducts() {
  const client = await pool.connect();

  try {
    console.log('\n' + '='.repeat(70));
    console.log('🚀 Inserting Sample Insurance Products');
    console.log('='.repeat(70));

    // Read SQL file
    console.log('📝 Reading SQL script...');
    const sql = fs.readFileSync('./insert_sample_insurance_products.sql', 'utf8');

    console.log('⚡ Executing SQL...\n');

    // Execute the SQL script
    await client.query(sql);

    console.log('✅ Sample insurance products inserted successfully!');

    // Verify insertion
    console.log('\n📊 Verifying inserted products...\n');
    const result = await client.query(`
      SELECT
        fingrow_level,
        COUNT(*) as product_count,
        MIN(premium_total) as min_premium,
        MAX(premium_total) as max_premium,
        AVG(premium_total)::NUMERIC(15,2) as avg_premium
      FROM insurance_product
      GROUP BY fingrow_level
      ORDER BY fingrow_level
    `);

    console.log('Products by Fingrow Level:');
    result.rows.forEach(row => {
      console.log(`  Level ${row.fingrow_level}: ${row.product_count} products`);
      console.log(`    Premium range: ${row.min_premium} - ${row.max_premium} THB`);
      console.log(`    Average: ${row.avg_premium} THB\n`);
    });

    // Show sample products
    console.log('📋 Sample products from each level:\n');
    const samples = await client.query(`
      SELECT
        fingrow_level,
        product_code,
        short_title,
        premium_total,
        finpoint_rate_per_100,
        insurance_type
      FROM insurance_product
      ORDER BY fingrow_level, premium_total
    `);

    samples.rows.forEach(row => {
      console.log(`  [Level ${row.fingrow_level}] ${row.short_title}`);
      console.log(`    Code: ${row.product_code}`);
      console.log(`    Type: ${row.insurance_type}`);
      console.log(`    Premium: ${row.premium_total} THB`);
      console.log(`    FinPoint Rate: ${row.finpoint_rate_per_100} per 100 THB\n`);
    });

    console.log('='.repeat(70));
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

insertSampleInsuranceProducts()
  .then(() => {
    console.log('✅ Script completed successfully!');
    process.exit(0);
  })
  .catch(err => {
    console.error('❌ Script failed:', err);
    process.exit(1);
  });
