/**
 * Check User Finpoint Balance
 */

const { Pool } = require('pg');

const pool = new Pool({
  host: 'localhost',
  port: 5433,
  database: 'fingame',
  user: 'fingrow_user',
  password: 'fingrow_pass_2025'
});

async function checkBalance() {
  const client = await pool.connect();

  try {
    const userId = '4d003630-3ed6-4d80-89fd-5c1d2f017be1';

    console.log('='.repeat(80));
    console.log('💰 Checking User Finpoint Balance');
    console.log('='.repeat(80));
    console.log(`\nUser ID: ${userId}\n`);

    // Check user balance
    const userResult = await client.query(`
      SELECT
        id,
        world_id,
        own_finpoint,
        total_finpoint
      FROM users
      WHERE id = $1
    `, [userId]);

    if (userResult.rows.length > 0) {
      const user = userResult.rows[0];
      console.log('📊 User Information:');
      console.log(`  World ID:       ${user.world_id}`);
      console.log(`  Own Finpoint:   ${parseFloat(user.own_finpoint).toLocaleString('th-TH', {minimumFractionDigits: 2})} FP`);
      console.log(`  Total Finpoint: ${parseFloat(user.total_finpoint).toLocaleString('th-TH', {minimumFractionDigits: 2})} FP`);
    } else {
      console.log('❌ User not found!');
    }

    console.log('\n' + '='.repeat(80));

  } catch (error) {
    console.error('❌ Error:', error.message);
    console.error(error.stack);
  } finally {
    client.release();
    await pool.end();
  }
}

checkBalance();
