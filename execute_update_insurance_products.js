// Execute update insurance products levels
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

async function updateInsuranceProducts() {
  const client = await pool.connect();

  try {
    console.log('\n' + '='.repeat(70));
    console.log('🔄 Updating Insurance Products Levels');
    console.log('='.repeat(70));

    // Read SQL file
    console.log('📝 Reading SQL script...');
    const sql = fs.readFileSync('./update_insurance_products_levels.sql', 'utf8');

    console.log('⚡ Executing SQL...\n');

    // Execute the SQL script
    await client.query(sql);

    console.log('✅ Insurance products updated successfully!');

    // Verify updated products
    console.log('\n📊 Verifying products by level...\n');
    const result = await client.query(`
      SELECT
        fingrow_level,
        insurance_group,
        COUNT(*) as product_count,
        MIN(premium_total) as min_premium,
        MAX(premium_total) as max_premium
      FROM insurance_product
      WHERE is_active = true AND deleted_at IS NULL
      GROUP BY fingrow_level, insurance_group
      ORDER BY fingrow_level, insurance_group
    `);

    const levelNames = {
      1: 'Level 1 – พรบ.',
      2: 'Level 2 – ประกันภัยรถ',
      3: 'Level 3 – ประกันสุขภาพ',
      4: 'Level 4 – ประกันชีวิต'
    };

    const groupNames = {
      motor: 'ประกันรถยนต์',
      health: 'ประกันสุขภาพ',
      life: 'ประกันชีวิต'
    };

    result.rows.forEach(row => {
      console.log(`${levelNames[row.fingrow_level]} - ${groupNames[row.insurance_group]}`);
      console.log(`  Products: ${row.product_count}`);
      console.log(`  Premium range: ${row.min_premium} - ${row.max_premium} THB\n`);
    });

    // Show all products
    console.log('=' + '='.repeat(69));
    console.log('📋 All Insurance Products');
    console.log('=' + '='.repeat(69) + '\n');

    const allProducts = await client.query(`
      SELECT
        fingrow_level,
        product_code,
        short_title,
        premium_total,
        finpoint_rate_per_100,
        insurance_group,
        insurance_type
      FROM insurance_product
      WHERE is_active = true AND deleted_at IS NULL
      ORDER BY fingrow_level, premium_total
    `);

    let currentLevel = 0;
    allProducts.rows.forEach(row => {
      if (row.fingrow_level !== currentLevel) {
        currentLevel = row.fingrow_level;
        console.log(`\n${levelNames[currentLevel]}:`);
        console.log('-'.repeat(70));
      }
      console.log(`  ${row.short_title}`);
      console.log(`    Code: ${row.product_code} | Type: ${row.insurance_type}`);
      console.log(`    Premium: ${row.premium_total} THB | FP Rate: ${row.finpoint_rate_per_100}/100\n`);
    });

    console.log('=' + '='.repeat(69));
    console.log('✅ All operations completed successfully!');
    console.log('=' + '='.repeat(69) + '\n');

  } catch (error) {
    console.error('\n❌ Error:', error.message);
    console.error('Stack:', error.stack);
    throw error;
  } finally {
    client.release();
    await pool.end();
  }
}

updateInsuranceProducts()
  .then(() => {
    console.log('✅ Script completed successfully!');
    process.exit(0);
  })
  .catch(err => {
    console.error('❌ Script failed:', err);
    process.exit(1);
  });
