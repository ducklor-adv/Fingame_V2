const { Pool } = require('pg');

const pool = new Pool({
  host: 'localhost',
  port: 5433,
  database: 'fingame',
  user: 'fingrow_user',
  password: 'fingrow_pass_2025'
});

async function getTableStructure() {
  const client = await pool.connect();
  try {
    console.log('=== insurance_product table structure ===\n');

    const columns = await client.query(`
      SELECT
        column_name,
        data_type,
        character_maximum_length,
        column_default,
        is_nullable
      FROM information_schema.columns
      WHERE table_name = 'insurance_product'
      ORDER BY ordinal_position
    `);

    columns.rows.forEach(col => {
      console.log(`${col.column_name.padEnd(30)} ${col.data_type.padEnd(20)} ${col.is_nullable === 'YES' ? 'NULL' : 'NOT NULL'}`);
    });

    // แสดง sample data
    console.log('\n=== Sample insurance products ===\n');
    const sample = await client.query('SELECT * FROM insurance_product LIMIT 3');

    if (sample.rows.length > 0) {
      console.log(JSON.stringify(sample.rows, null, 2));
    }

  } catch (error) {
    console.error('Error:', error.message);
  } finally {
    client.release();
    await pool.end();
  }
}

getTableStructure();
