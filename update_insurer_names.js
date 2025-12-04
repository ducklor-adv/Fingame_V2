/**
 * Update all insurer company names to test company name
 * เพื่อหลีกเลี่ยงการใช้ชื่อบริษัทจริง
 */

const { Pool } = require('pg');

const pool = new Pool({
  host: 'localhost',
  port: 5433,
  database: 'fingame',
  user: 'fingrow_user',
  password: 'fingrow_pass_2025'
});

const TEST_COMPANY_NAME = 'บริษัท ทดลองระบบจ่ายประกัน Fingrow เท่านั้น จำกัด';

async function updateInsurerNames() {
  const client = await pool.connect();

  try {
    console.log('='.repeat(80));
    console.log('🔄 Updating Insurer Company Names to Test Company');
    console.log('='.repeat(80));

    // 1. ดูชื่อบริษัทเดิมก่อน
    console.log('\n📋 Current insurer company names:');
    const currentNames = await client.query(
      'SELECT DISTINCT insurer_company_name FROM insurance_product ORDER BY insurer_company_name'
    );

    currentNames.rows.forEach((row, index) => {
      console.log(`  ${index + 1}. ${row.insurer_company_name}`);
    });

    // 2. นับจำนวนรายการทั้งหมด
    const countResult = await client.query(
      'SELECT COUNT(*) as total FROM insurance_product'
    );
    const totalRecords = parseInt(countResult.rows[0].total);
    console.log(`\n📊 Total insurance products: ${totalRecords}`);

    // 3. อัปเดตชื่อบริษัททั้งหมด
    console.log('\n🔄 Updating all records...');
    const updateResult = await client.query(
      `UPDATE insurance_product
       SET insurer_company_name = $1
       WHERE insurer_company_name != $1`,
      [TEST_COMPANY_NAME]
    );

    console.log(`✅ Updated ${updateResult.rowCount} records`);

    // 4. ตรวจสอบผลลัพธ์
    console.log('\n📋 After update:');
    const afterUpdate = await client.query(
      'SELECT DISTINCT insurer_company_name FROM insurance_product'
    );

    afterUpdate.rows.forEach((row, index) => {
      console.log(`  ${index + 1}. ${row.insurer_company_name}`);
    });

    // 5. แสดงตัวอย่าง 5 รายการ
    console.log('\n📄 Sample records (first 5):');
    const sample = await client.query(
      `SELECT short_title, insurer_company_name
       FROM insurance_product
       LIMIT 5`
    );

    sample.rows.forEach((row, index) => {
      console.log(`  ${index + 1}. ${row.short_title}`);
      console.log(`     บริษัท: ${row.insurer_company_name}`);
    });

    console.log('\n' + '='.repeat(80));
    console.log('✅ Successfully updated all insurer company names!');
    console.log('='.repeat(80));

  } catch (error) {
    console.error('❌ Error updating insurer names:', error.message);
    console.error(error.stack);
  } finally {
    client.release();
    await pool.end();
  }
}

updateInsurerNames();
