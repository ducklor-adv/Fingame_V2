// Execute upline_id migration script
const fs = require('fs');
const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  port: process.env.DB_PORT || 5433,
  database: process.env.DB_NAME || 'fingame',
  user: process.env.DB_USER || 'fingrow_user',
  password: process.env.DB_PASSWORD || 'fingrow_pass_2025',
});

async function executeUplineIdMigration() {
  const client = await pool.connect();

  try {
    console.log('\n' + '='.repeat(60));
    console.log('🚀 Starting upline_id Migration');
    console.log('='.repeat(60));

    // Read SQL file
    console.log('📝 Reading SQL script...');
    const sql = fs.readFileSync('./add_upline_id_column.sql', 'utf8');

    console.log('⚡ Executing migration...\n');

    // Execute the SQL script
    const result = await client.query(sql);

    console.log('\n' + '='.repeat(60));
    console.log('✅ Migration completed successfully!');
    console.log('='.repeat(60));

    // Display verification results
    if (result.rows && result.rows.length > 0) {
      console.log('\n📊 Verification Results (First 15 users):');
      console.log('-'.repeat(60));
      result.rows.forEach((row, idx) => {
        console.log(`${idx + 1}. ${row.world_id} - ${row.username}`);
        console.log(`   Level: ${row.level}, Upline Count: ${row.upline_count}`);
        console.log(`   Status: ${row.validation_status}`);
        if (row.upline_count > 0) {
          console.log(`   Upline IDs: ${JSON.stringify(row.upline_id).substring(0, 80)}...`);
        }
        console.log('');
      });
    }

  } catch (error) {
    console.error('\n❌ Error during migration:', error.message);
    console.error('Stack:', error.stack);
    throw error;
  } finally {
    client.release();
    await pool.end();
  }
}

executeUplineIdMigration()
  .then(() => {
    console.log('✅ Script completed successfully!');
    process.exit(0);
  })
  .catch(err => {
    console.error('❌ Script failed:', err);
    process.exit(1);
  });
