/**
 * Add finpoint_price field to insurance_product table
 * เพิ่ม field finpoint_price โดยคำนวณจาก premium_total
 * 1 บาท = 1 Finpoint
 */

const { Pool } = require('pg');
const fs = require('fs');
const path = require('path');

const pool = new Pool({
  host: 'localhost',
  port: 5433,
  database: 'fingame',
  user: 'fingrow_user',
  password: 'fingrow_pass_2025'
});

async function addFinpointPrice() {
  const client = await pool.connect();

  try {
    console.log('='.repeat(80));
    console.log('🔄 Adding Finpoint Price to Insurance Products');
    console.log('='.repeat(80));

    // อ่านไฟล์ SQL
    const sqlFile = path.join(__dirname, 'database', 'migration_add_finpoint_price.sql');
    const sql = fs.readFileSync(sqlFile, 'utf8');

    console.log('\n📋 Executing migration...\n');

    // รัน SQL
    const result = await client.query(sql);

    console.log('✅ Migration completed successfully!\n');

    // แสดงตัวอย่างข้อมูล
    console.log('📄 Sample products with Finpoint prices:');
    const sample = await client.query(`
      SELECT
        short_title,
        premium_total as price_baht,
        finpoint_price as price_fp,
        insurer_company_name
      FROM insurance_product
      ORDER BY finpoint_price
      LIMIT 10
    `);

    console.log('\n┌─────────────────────────────────┬────────────┬────────────┐');
    console.log('│ Product                         │ Baht       │ Finpoint   │');
    console.log('├─────────────────────────────────┼────────────┼────────────┤');

    sample.rows.forEach(row => {
      const title = row.short_title.padEnd(31).substring(0, 31);
      const baht = row.price_baht.toLocaleString('th-TH', {minimumFractionDigits: 2}).padStart(10);
      const fp = row.price_fp.toLocaleString('th-TH', {minimumFractionDigits: 2}).padStart(10);
      console.log(`│ ${title} │ ${baht} │ ${fp} │`);
    });

    console.log('└─────────────────────────────────┴────────────┴────────────┘');

    // สถิติ
    console.log('\n📊 Statistics:');
    const stats = await client.query(`
      SELECT
        COUNT(*) as total_products,
        MIN(finpoint_price) as min_fp,
        MAX(finpoint_price) as max_fp,
        AVG(finpoint_price) as avg_fp
      FROM insurance_product
    `);

    const st = stats.rows[0];
    console.log(`  Total Products: ${st.total_products}`);
    console.log(`  Min FP Price:   ${parseFloat(st.min_fp).toLocaleString('th-TH', {minimumFractionDigits: 2})} FP`);
    console.log(`  Max FP Price:   ${parseFloat(st.max_fp).toLocaleString('th-TH', {minimumFractionDigits: 2})} FP`);
    console.log(`  Avg FP Price:   ${parseFloat(st.avg_fp).toLocaleString('th-TH', {minimumFractionDigits: 2})} FP`);

    console.log('\n' + '='.repeat(80));
    console.log('✅ Successfully added finpoint_price field!');
    console.log('💡 Exchange Rate: 1 บาท = 1 Finpoint');
    console.log('='.repeat(80));

  } catch (error) {
    console.error('❌ Migration failed!');
    console.error('Error:', error.message);
    console.error('\nDetails:', error.stack);
  } finally {
    client.release();
    await pool.end();
  }
}

addFinpointPrice();
