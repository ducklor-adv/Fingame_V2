// Check latest user world IDs
const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  port: process.env.DB_PORT || 5433,
  database: process.env.DB_NAME || 'fingame',
  user: process.env.DB_USER || 'fingrow_user',
  password: process.env.DB_PASSWORD || 'fingrow_pass_2025',
});

async function checkLatestUsers() {
  const client = await pool.connect();

  try {
    const result = await client.query(`
      SELECT world_id, username, run_number
      FROM users
      ORDER BY world_id DESC
      LIMIT 15;
    `);

    console.log('Latest 15 users:');
    result.rows.forEach(row => {
      console.log(`  ${row.world_id} - ${row.username} (run: ${row.run_number})`);
    });

  } catch (error) {
    console.error('Error:', error.message);
  } finally {
    client.release();
    await pool.end();
  }
}

checkLatestUsers()
  .then(() => process.exit(0))
  .catch(err => {
    console.error(err);
    process.exit(1);
  });
