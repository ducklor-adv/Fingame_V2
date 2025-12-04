/**
 * Check insurance_product table structure
 * ตรวจสอบว่ามี fields ที่เกี่ยวข้องกับ Commission และ VAT หรือยัง
 */

const { Pool } = require('pg');

const pool = new Pool({
  host: 'localhost',
  port: 5433,
  database: 'fingame',
  user: 'fingrow_user',
  password: 'fingrow_pass_2025'
});

async function checkInsuranceFields() {
  const client = await pool.connect();

  try {
    console.log('='.repeat(80));
    console.log('🔍 Checking insurance_product Table Structure');
    console.log('='.repeat(80));

    // 1. ดู column ทั้งหมด
    const columns = await client.query(`
      SELECT
        column_name,
        data_type,
        character_maximum_length,
        numeric_precision,
        numeric_scale,
        column_default,
        is_nullable
      FROM information_schema.columns
      WHERE table_name = 'insurance_product'
      ORDER BY ordinal_position
    `);

    console.log('\n📋 All Columns:');
    console.log('┌────────────────────────────────────┬──────────────────┬──────────┬──────────┐');
    console.log('│ Column Name                        │ Data Type        │ Nullable │ Default  │');
    console.log('├────────────────────────────────────┼──────────────────┼──────────┼──────────┤');

    columns.rows.forEach(col => {
      const name = col.column_name.padEnd(34).substring(0, 34);
      let dataType = col.data_type;
      if (col.numeric_precision) {
        dataType += `(${col.numeric_precision},${col.numeric_scale})`;
      }
      dataType = dataType.padEnd(16).substring(0, 16);
      const nullable = (col.is_nullable === 'YES' ? 'NULL' : 'NOT NULL').padEnd(8);
      const def = (col.column_default || '-').substring(0, 8);
      console.log(`│ ${name} │ ${dataType} │ ${nullable} │ ${def} │`);
    });

    console.log('└────────────────────────────────────┴──────────────────┴──────────┴──────────┘');

    // 2. ตรวจสอบ fields ที่เกี่ยวข้องกับราคาและ Commission
    console.log('\n💰 Price and Commission Related Fields:');

    const priceFields = columns.rows.filter(col =>
      col.column_name.includes('price') ||
      col.column_name.includes('premium') ||
      col.column_name.includes('commission') ||
      col.column_name.includes('vat') ||
      col.column_name.includes('total')
    );

    if (priceFields.length > 0) {
      priceFields.forEach(col => {
        console.log(`  ✓ ${col.column_name} (${col.data_type})`);
      });
    } else {
      console.log('  ⚠️  No price/commission related fields found');
    }

    // 3. ดูตัวอย่างข้อมูล
    console.log('\n📄 Sample Data (1 product):');
    const sample = await client.query(`
      SELECT *
      FROM insurance_product
      LIMIT 1
    `);

    if (sample.rows.length > 0) {
      const product = sample.rows[0];
      console.log('\n' + JSON.stringify(product, null, 2));
    }

    // 4. สรุป fields ที่มีและไม่มี
    console.log('\n📊 Summary:');

    const hasFields = {
      premium_before_vat: columns.rows.some(c => c.column_name === 'premium_before_vat'),
      premium_vat: columns.rows.some(c => c.column_name === 'premium_vat'),
      premium_total: columns.rows.some(c => c.column_name === 'premium_total'),
      commission_rate: columns.rows.some(c => c.column_name === 'commission_rate'),
      commission_amount: columns.rows.some(c => c.column_name === 'commission_amount'),
      commission_to_fingrow_percent: columns.rows.some(c => c.column_name === 'commission_to_fingrow_percent'),
      commission_seller_percent: columns.rows.some(c => c.column_name === 'commission_seller_percent'),
      commission_pool_percent: columns.rows.some(c => c.column_name === 'commission_pool_percent'),
    };

    console.log('\nField Availability:');
    Object.entries(hasFields).forEach(([field, exists]) => {
      const status = exists ? '✅' : '❌';
      console.log(`  ${status} ${field}`);
    });

    console.log('\n' + '='.repeat(80));
    console.log('Inspection completed!');
    console.log('='.repeat(80));

  } catch (error) {
    console.error('❌ Error:', error.message);
    console.error(error.stack);
  } finally {
    client.release();
    await pool.end();
  }
}

checkInsuranceFields();
