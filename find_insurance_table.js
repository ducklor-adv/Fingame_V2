const { Pool } = require('pg');

const pool = new Pool({
  host: 'localhost',
  port: 5433,
  database: 'fingame',
  user: 'fingrow_user',
  password: 'fingrow_pass_2025'
});

async function findTables() {
  const client = await pool.connect();
  try {
    // ค้นหาตารางทั้งหมด
    const tables = await client.query(`
      SELECT table_name
      FROM information_schema.tables
      WHERE table_schema = 'public'
      AND table_type = 'BASE TABLE'
      ORDER BY table_name
    `);

    console.log('=== All Tables in Database ===\n');
    tables.rows.forEach((row, index) => {
      console.log(`${index + 1}. ${row.table_name}`);
    });

    // ค้นหาตารางที่มีคำว่า insurance
    console.log('\n=== Tables with "insurance" keyword ===\n');
    const insuranceTables = tables.rows.filter(row =>
      row.table_name.toLowerCase().includes('insurance') ||
      row.table_name.toLowerCase().includes('product') ||
      row.table_name.toLowerCase().includes('policy')
    );

    if (insuranceTables.length > 0) {
      insuranceTables.forEach(row => console.log(`- ${row.table_name}`));
    } else {
      console.log('No insurance-related tables found');
    }

  } catch (error) {
    console.error('Error:', error.message);
  } finally {
    client.release();
    await pool.end();
  }
}

findTables();
