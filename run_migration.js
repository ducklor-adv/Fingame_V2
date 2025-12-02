/**
 * รัน Migration เพื่อสร้างตาราง Commission Pool
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

async function runMigration() {
  const client = await pool.connect();

  try {
    console.log('='.repeat(60));
    console.log('Running Migration: Create Commission Pool Tables');
    console.log('='.repeat(60));

    // อ่านไฟล์ SQL
    const sqlFile = path.join(__dirname, 'database', 'migration_create_commission_tables.sql');
    const sql = fs.readFileSync(sqlFile, 'utf8');

    console.log('\nExecuting SQL migration...\n');

    // รัน SQL
    const result = await client.query(sql);

    console.log('✅ Migration completed successfully!\n');

    // ตรวจสอบว่าตารางถูกสร้างแล้ว
    const checkTables = await client.query(`
      SELECT table_name
      FROM information_schema.tables
      WHERE table_name IN ('insurance_orders', 'commission_pool_distribution')
      ORDER BY table_name
    `);

    console.log('Tables created:');
    checkTables.rows.forEach(row => {
      console.log(`  ✓ ${row.table_name}`);
    });

    // ตรวจสอบ Views
    const checkViews = await client.query(`
      SELECT table_name
      FROM information_schema.views
      WHERE table_name IN ('user_finpoint_summary', 'insurance_order_detail')
      ORDER BY table_name
    `);

    console.log('\nViews created:');
    checkViews.rows.forEach(row => {
      console.log(`  ✓ ${row.table_name}`);
    });

    console.log('\n' + '='.repeat(60));
    console.log('Migration completed successfully!');
    console.log('='.repeat(60));

  } catch (error) {
    console.error('❌ Migration failed!');
    console.error('Error:', error.message);
    console.error('\nDetails:', error.stack);
  } finally {
    client.release();
    await pool.end();
  }
}

runMigration();
