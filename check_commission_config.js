/**
 * Check Commission Distribution Config
 */

const { Pool } = require('pg');

const pool = new Pool({
  host: 'localhost',
  port: 5433,
  database: 'fingame',
  user: 'fingrow_user',
  password: 'fingrow_pass_2025'
});

async function checkConfig() {
  const client = await pool.connect();

  try {
    console.log('='.repeat(80));
    console.log('📊 Commission Distribution Config');
    console.log('='.repeat(80));

    // Check one product's config
    const productResult = await client.query(`
      SELECT
        id,
        short_title,
        finpoint_price,
        commission_pool_amount,
        finpoint_distribution_config
      FROM insurance_product
      WHERE fingrow_level = 1
      LIMIT 1
    `);

    if (productResult.rows.length > 0) {
      const product = productResult.rows[0];
      console.log('\n📦 Product:', product.short_title);
      console.log('💰 Finpoint Price:', parseFloat(product.finpoint_price).toLocaleString('th-TH', {minimumFractionDigits: 2}), 'FP');
      console.log('💵 Commission Pool:', parseFloat(product.commission_pool_amount).toLocaleString('th-TH', {minimumFractionDigits: 2}), 'FP');
      console.log('\n📋 Distribution Config:');
      console.log(JSON.stringify(product.finpoint_distribution_config, null, 2));
    }

    console.log('\n' + '='.repeat(80));

  } catch (error) {
    console.error('❌ Error:', error.message);
    console.error(error.stack);
  } finally {
    client.release();
    await pool.end();
  }
}

checkConfig();
