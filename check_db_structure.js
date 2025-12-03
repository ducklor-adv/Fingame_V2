/**
 * ตรวจสอบโครงสร้างตารางในฐานข้อมูล
 */

const { Pool } = require('pg');

const pool = new Pool({
  host: 'localhost',
  port: 5433,
  database: 'fingame',
  user: 'fingrow_user',
  password: 'fingrow_pass_2025'
});

async function checkDatabaseStructure() {
  const client = await pool.connect();

  try {
    console.log('='.repeat(60));
    console.log('Checking Database Structure');
    console.log('='.repeat(60));

    // 1. ตรวจสอบตาราง insurance_products
    console.log('\n1. Table: insurance_products');
    console.log('-'.repeat(60));
    const insuranceColumns = await client.query(`
      SELECT column_name, data_type, character_maximum_length
      FROM information_schema.columns
      WHERE table_name = 'insurance_products'
      ORDER BY ordinal_position
    `);

    if (insuranceColumns.rows.length > 0) {
      console.log('Columns:');
      insuranceColumns.rows.forEach(col => {
        console.log(`  - ${col.column_name} (${col.data_type}${col.character_maximum_length ? `(${col.character_maximum_length})` : ''})`);
      });
    } else {
      console.log('❌ Table not found!');
    }

    // ตรวจสอบว่ามีฟิลด์ commission_rate หรือไม่
    const hasCommissionRate = insuranceColumns.rows.some(col => col.column_name === 'commission_rate');
    if (hasCommissionRate) {
      console.log('✅ commission_rate field exists');
    } else {
      console.log('⚠️  commission_rate field NOT found - need to add it');
    }

    // 2. ตรวจสอบตาราง users
    console.log('\n2. Table: users');
    console.log('-'.repeat(60));
    const userColumns = await client.query(`
      SELECT column_name, data_type
      FROM information_schema.columns
      WHERE table_name = 'users'
      ORDER BY ordinal_position
    `);

    if (userColumns.rows.length > 0) {
      console.log('Columns:');
      userColumns.rows.forEach(col => {
        console.log(`  - ${col.column_name} (${col.data_type})`);
      });
    } else {
      console.log('❌ Table not found!');
    }

    // ตรวจสอบว่ามีฟิลด์ parent_user_id หรือไม่
    const hasParentUserId = userColumns.rows.some(col => col.column_name === 'parent_user_id');
    if (hasParentUserId) {
      console.log('✅ parent_user_id field exists');
    } else {
      console.log('⚠️  parent_user_id field NOT found - need to add it');
    }

    // 3. ตรวจสอบตาราง orders
    console.log('\n3. Table: orders');
    console.log('-'.repeat(60));
    const ordersExists = await client.query(`
      SELECT EXISTS (
        SELECT FROM information_schema.tables
        WHERE table_name = 'orders'
      )
    `);

    if (ordersExists.rows[0].exists) {
      console.log('✅ Table exists');
      const orderColumns = await client.query(`
        SELECT column_name, data_type
        FROM information_schema.columns
        WHERE table_name = 'orders'
        ORDER BY ordinal_position
      `);
      console.log('Columns:');
      orderColumns.rows.forEach(col => {
        console.log(`  - ${col.column_name} (${col.data_type})`);
      });
    } else {
      console.log('❌ Table NOT found - need to run migration');
    }

    // 4. ตรวจสอบตาราง commission_pool_distribution
    console.log('\n4. Table: commission_pool_distribution');
    console.log('-'.repeat(60));
    const cpdExists = await client.query(`
      SELECT EXISTS (
        SELECT FROM information_schema.tables
        WHERE table_name = 'commission_pool_distribution'
      )
    `);

    if (cpdExists.rows[0].exists) {
      console.log('✅ Table exists');
      const cpdColumns = await client.query(`
        SELECT column_name, data_type
        FROM information_schema.columns
        WHERE table_name = 'commission_pool_distribution'
        ORDER BY ordinal_position
      `);
      console.log('Columns:');
      cpdColumns.rows.forEach(col => {
        console.log(`  - ${col.column_name} (${col.data_type})`);
      });
    } else {
      console.log('❌ Table NOT found - need to run migration');
    }

    // 5. นับจำนวน Users และ Insurance Products
    console.log('\n5. Data Summary');
    console.log('-'.repeat(60));

    const userCount = await client.query('SELECT COUNT(*) as count FROM users');
    console.log(`Users: ${userCount.rows[0].count}`);

    const productCount = await client.query('SELECT COUNT(*) as count FROM insurance_products');
    console.log(`Insurance Products: ${productCount.rows[0].count}`);

    // แสดง sample products
    const sampleProducts = await client.query(`
      SELECT id, short_title, premium_total
      FROM insurance_products
      LIMIT 5
    `);
    console.log('\nSample Insurance Products:');
    sampleProducts.rows.forEach(p => {
      console.log(`  - [${p.id}] ${p.short_title}: ${parseFloat(p.premium_total).toLocaleString()} บาท`);
    });

    // แสดง sample users with parent
    const sampleUsers = await client.query(`
      SELECT user_id, username, parent_user_id, world_id
      FROM users
      ORDER BY user_id
      LIMIT 10
    `);
    console.log('\nSample Users:');
    sampleUsers.rows.forEach(u => {
      console.log(`  - [${u.user_id}] ${u.username} (Parent: ${u.parent_user_id || 'None'}, World: ${u.world_id})`);
    });

    console.log('\n' + '='.repeat(60));
    console.log('Check completed!');
    console.log('='.repeat(60));

  } catch (error) {
    console.error('Error:', error.message);
  } finally {
    client.release();
    await pool.end();
  }
}

checkDatabaseStructure();
