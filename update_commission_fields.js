/**
 * Update Commission Fields in Insurance Product Table
 * เพิ่มและอัปเดต fields สำหรับ Commission Structure
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

async function updateCommissionFields() {
  const client = await pool.connect();

  try {
    console.log('='.repeat(80));
    console.log('🔄 Updating Commission Fields in Insurance Product');
    console.log('='.repeat(80));

    // อ่านไฟล์ SQL
    const sqlFile = path.join(__dirname, 'database', 'migration_update_commission_fields.sql');
    const sql = fs.readFileSync(sqlFile, 'utf8');

    console.log('\n📋 Executing migration...\n');

    // รัน SQL
    await client.query(sql);

    console.log('✅ Migration completed successfully!\n');

    // แสดงตัวอย่างข้อมูล
    console.log('📄 Sample products with Commission Structure:');
    const sample = await client.query(`
      SELECT
        short_title,
        premium_total,
        commission_to_fingrow_percent as fingrow,
        commission_seller_percent as seller,
        commission_pool_percent as pool,
        (commission_to_fingrow_percent + commission_seller_percent + commission_pool_percent) as total_check
      FROM insurance_product
      ORDER BY premium_total
      LIMIT 10
    `);

    console.log('\n┌──────────────────────────────┬───────────┬─────────┬─────────┬─────────┬───────┐');
    console.log('│ Product                      │ Premium   │ Fingrow │ Seller  │ Pool    │ Total │');
    console.log('├──────────────────────────────┼───────────┼─────────┼─────────┼─────────┼───────┤');

    sample.rows.forEach(row => {
      const title = row.short_title.padEnd(28).substring(0, 28);
      const premium = row.premium_total.toLocaleString('th-TH', {minimumFractionDigits: 0}).padStart(9);
      const fingrow = parseFloat(row.fingrow).toFixed(0).padStart(7);
      const seller = parseFloat(row.seller).toFixed(0).padStart(7);
      const pool = parseFloat(row.pool).toFixed(0).padStart(7);
      const total = parseFloat(row.total_check).toFixed(0).padStart(5);
      console.log(`│ ${title} │ ${premium} │ ${fingrow}% │ ${seller}% │ ${pool}% │ ${total}% │`);
    });

    console.log('└──────────────────────────────┴───────────┴─────────┴─────────┴─────────┴───────┘');

    // คำนวณตัวอย่างค่าคอมมิชชันจริง (ใช้ commission rate เริ่มต้น 15%)
    console.log('\n💰 Example Commission Calculation (assuming 15% commission rate):');
    const example = await client.query(`
      SELECT
        short_title,
        premium_total,
        15.0 as commission_rate,
        (premium_total * 15.0 / 100) as total_commission,
        (premium_total * 15.0 / 100 * commission_to_fingrow_percent / 100) as fingrow_amount,
        (premium_total * 15.0 / 100 * commission_seller_percent / 100) as seller_amount,
        (premium_total * 15.0 / 100 * commission_pool_percent / 100) as pool_amount
      FROM insurance_product
      WHERE short_title = 'ประกันชีวิต 10 ปี'
      LIMIT 1
    `);

    if (example.rows.length > 0) {
      const ex = example.rows[0];
      console.log(`\nProduct: ${ex.short_title}`);
      console.log(`Premium: ${parseFloat(ex.premium_total).toLocaleString('th-TH', {minimumFractionDigits: 2})} บาท`);
      console.log(`Commission Rate: ${parseFloat(ex.commission_rate)}%`);
      console.log(`\nTotal Commission: ${parseFloat(ex.total_commission).toLocaleString('th-TH', {minimumFractionDigits: 2})} บาท`);
      console.log(`├─ Fingrow (10%):  ${parseFloat(ex.fingrow_amount).toLocaleString('th-TH', {minimumFractionDigits: 2})} บาท`);
      console.log(`├─ Seller (45%):   ${parseFloat(ex.seller_amount).toLocaleString('th-TH', {minimumFractionDigits: 2})} บาท`);
      console.log(`└─ Pool (45%):     ${parseFloat(ex.pool_amount).toLocaleString('th-TH', {minimumFractionDigits: 2})} บาท`);

      const poolPerPerson = parseFloat(ex.pool_amount) / 7;
      console.log(`\n   Pool แบ่ง 7 คน:  ${poolPerPerson.toLocaleString('th-TH', {minimumFractionDigits: 2})} บาท/คน`);
    }

    // สถิติ
    console.log('\n📊 Statistics:');
    const stats = await client.query(`
      SELECT
        COUNT(*) as total_products,
        AVG(commission_to_fingrow_percent) as avg_fingrow,
        AVG(commission_seller_percent) as avg_seller,
        AVG(commission_pool_percent) as avg_pool
      FROM insurance_product
    `);

    const st = stats.rows[0];
    console.log(`  Total Products: ${st.total_products}`);
    console.log(`  Avg Fingrow %:  ${parseFloat(st.avg_fingrow).toFixed(2)}%`);
    console.log(`  Avg Seller %:   ${parseFloat(st.avg_seller).toFixed(2)}%`);
    console.log(`  Avg Pool %:     ${parseFloat(st.avg_pool).toFixed(2)}%`);

    console.log('\n' + '='.repeat(80));
    console.log('✅ Commission Structure Updated Successfully!');
    console.log('📐 Formula: Fingrow (10%) + Seller (45%) + Pool (45%) = 100%');
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

updateCommissionFields();
