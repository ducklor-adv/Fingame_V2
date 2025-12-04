/**
 * Add Commission Amount Field
 * เพิ่ม field commission_amount และคำนวณค่าคอมมิชชันเป็นตัวเงิน
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

async function addCommissionAmount() {
  const client = await pool.connect();

  try {
    console.log('='.repeat(80));
    console.log('💰 Adding Commission Amount Fields');
    console.log('='.repeat(80));

    // อ่านไฟล์ SQL
    const sqlFile = path.join(__dirname, 'database', 'migration_add_commission_amount.sql');
    const sql = fs.readFileSync(sqlFile, 'utf8');

    console.log('\n📋 Executing migration...\n');

    // รัน SQL
    await client.query(sql);

    console.log('✅ Migration completed successfully!\n');

    // แสดงตัวอย่างข้อมูลแบบละเอียด
    console.log('📄 Sample Commission Breakdown:');
    const sample = await client.query(`
      SELECT
        short_title,
        premium_base,
        commission_percent,
        commission_amount,
        commission_fingrow_amount,
        commission_seller_amount,
        commission_pool_amount,
        ROUND((commission_pool_amount / 7), 2) as pool_per_person
      FROM insurance_product
      ORDER BY premium_base
      LIMIT 10
    `);

    console.log('\n┌────────────────────────────┬──────────┬──────┬──────────┬─────────┬─────────┬─────────┬──────────┐');
    console.log('│ Product                    │ Premium  │ Com% │ Total    │ Fingrow │ Seller  │ Pool    │ Per/7    │');
    console.log('├────────────────────────────┼──────────┼──────┼──────────┼─────────┼─────────┼─────────┼──────────┤');

    sample.rows.forEach(row => {
      const title = row.short_title.padEnd(26).substring(0, 26);
      const premium = parseFloat(row.premium_base).toLocaleString('th-TH', {minimumFractionDigits: 0}).padStart(8);
      const comPct = parseFloat(row.commission_percent).toFixed(0).padStart(4);
      const total = parseFloat(row.commission_amount).toLocaleString('th-TH', {minimumFractionDigits: 2}).padStart(8);
      const fingrow = parseFloat(row.commission_fingrow_amount).toLocaleString('th-TH', {minimumFractionDigits: 2}).padStart(7);
      const seller = parseFloat(row.commission_seller_amount).toLocaleString('th-TH', {minimumFractionDigits: 2}).padStart(7);
      const pool = parseFloat(row.commission_pool_amount).toLocaleString('th-TH', {minimumFractionDigits: 2}).padStart(7);
      const perPerson = parseFloat(row.pool_per_person).toLocaleString('th-TH', {minimumFractionDigits: 2}).padStart(8);

      console.log(`│ ${title} │ ${premium} │ ${comPct}% │ ${total} │ ${fingrow} │ ${seller} │ ${pool} │ ${perPerson} │`);
    });

    console.log('└────────────────────────────┴──────────┴──────┴──────────┴─────────┴─────────┴─────────┴──────────┘');

    // ตัวอย่างการคำนวณแบบละเอียด
    console.log('\n💡 Example Calculation Detail:');
    const detail = await client.query(`
      SELECT
        short_title,
        premium_base,
        tax_vat_amount,
        stamp_duty_amount,
        premium_total,
        commission_percent,
        commission_amount,
        commission_fingrow_amount,
        commission_seller_amount,
        commission_pool_amount
      FROM insurance_product
      WHERE short_title = 'พรบ. มอเตอร์ไซค์'
      LIMIT 1
    `);

    if (detail.rows.length > 0) {
      const d = detail.rows[0];
      console.log(`\nProduct: ${d.short_title}`);
      console.log('\n📊 Price Breakdown:');
      console.log(`  Premium Base (ก่อน VAT):  ${parseFloat(d.premium_base).toLocaleString('th-TH', {minimumFractionDigits: 2})} บาท`);
      console.log(`  + VAT (7%):                ${parseFloat(d.tax_vat_amount).toLocaleString('th-TH', {minimumFractionDigits: 2})} บาท`);
      console.log(`  + Stamp Duty:              ${parseFloat(d.stamp_duty_amount || 0).toLocaleString('th-TH', {minimumFractionDigits: 2})} บาท`);
      console.log(`  ─────────────────────────────────────────`);
      console.log(`  = Premium Total:           ${parseFloat(d.premium_total).toLocaleString('th-TH', {minimumFractionDigits: 2})} บาท`);

      console.log(`\n💰 Commission Breakdown (${parseFloat(d.commission_percent)}% ของ Premium Base):`);
      console.log(`  Total Commission:          ${parseFloat(d.commission_amount).toLocaleString('th-TH', {minimumFractionDigits: 2})} บาท (100%)`);
      console.log(`  ├─ Fingrow (10%):          ${parseFloat(d.commission_fingrow_amount).toLocaleString('th-TH', {minimumFractionDigits: 2})} บาท`);
      console.log(`  ├─ Seller (45%):           ${parseFloat(d.commission_seller_amount).toLocaleString('th-TH', {minimumFractionDigits: 2})} บาท`);
      console.log(`  └─ Pool (45%):             ${parseFloat(d.commission_pool_amount).toLocaleString('th-TH', {minimumFractionDigits: 2})} บาท`);

      const poolPer7 = parseFloat(d.commission_pool_amount) / 7;
      console.log(`     └─ แบ่ง 7 คน (1/7):     ${poolPer7.toLocaleString('th-TH', {minimumFractionDigits: 2})} บาท/คน`);
    }

    // สถิติ
    console.log('\n📊 Statistics:');
    const stats = await client.query(`
      SELECT
        COUNT(*) as total_products,
        AVG(commission_amount) as avg_commission,
        MIN(commission_amount) as min_commission,
        MAX(commission_amount) as max_commission,
        SUM(commission_amount) as total_commission_if_all_sold
      FROM insurance_product
    `);

    const st = stats.rows[0];
    console.log(`  Total Products:            ${st.total_products}`);
    console.log(`  Avg Commission:            ${parseFloat(st.avg_commission).toLocaleString('th-TH', {minimumFractionDigits: 2})} บาท`);
    console.log(`  Min Commission:            ${parseFloat(st.min_commission).toLocaleString('th-TH', {minimumFractionDigits: 2})} บาท`);
    console.log(`  Max Commission:            ${parseFloat(st.max_commission).toLocaleString('th-TH', {minimumFractionDigits: 2})} บาท`);
    console.log(`  Total (if all sold once):  ${parseFloat(st.total_commission_if_all_sold).toLocaleString('th-TH', {minimumFractionDigits: 2})} บาท`);

    console.log('\n' + '='.repeat(80));
    console.log('✅ Commission Amount Fields Added Successfully!');
    console.log('📐 Formula: commission_amount = premium_base × commission_percent / 100');
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

addCommissionAmount();
