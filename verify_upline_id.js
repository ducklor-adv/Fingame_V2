// Verify upline_id implementation
const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  port: process.env.DB_PORT || 5433,
  database: process.env.DB_NAME || 'fingame',
  user: process.env.DB_USER || 'fingrow_user',
  password: process.env.DB_PASSWORD || 'fingrow_pass_2025',
});

async function verifyUplineId() {
  const client = await pool.connect();

  try {
    console.log('\n' + '='.repeat(70));
    console.log('🔍 Verifying upline_id Implementation');
    console.log('='.repeat(70));

    // Query 1: Basic verification
    console.log('\n📊 Sample users with upline_id:\n');
    const result1 = await client.query(`
      SELECT
        world_id,
        username,
        level,
        jsonb_array_length(COALESCE(upline_id, '[]'::jsonb)) as upline_count,
        upline_id,
        CASE
          WHEN jsonb_array_length(COALESCE(upline_id, '[]'::jsonb)) <= level
           AND jsonb_array_length(COALESCE(upline_id, '[]'::jsonb)) <= 6
          THEN '✅ Valid'
          ELSE '❌ Invalid'
        END as validation_status
      FROM users
      ORDER BY run_number
      LIMIT 20
    `);

    result1.rows.forEach((row, idx) => {
      console.log(`${idx + 1}. ${row.world_id} - ${row.username}`);
      console.log(`   Level: ${row.level}, Upline Count: ${row.upline_count}, Status: ${row.validation_status}`);
      if (row.upline_count > 0) {
        const uplineIds = row.upline_id;
        console.log(`   Upline IDs: ${JSON.stringify(uplineIds).substring(0, 100)}...`);
      }
      console.log('');
    });

    // Query 2: Distribution by upline count
    console.log('\n📈 Distribution by upline count:\n');
    const result2 = await client.query(`
      SELECT
        jsonb_array_length(COALESCE(upline_id, '[]'::jsonb)) as upline_count,
        COUNT(*) as user_count
      FROM users
      GROUP BY upline_count
      ORDER BY upline_count
    `);

    result2.rows.forEach(row => {
      console.log(`   Upline Count ${row.upline_count}: ${row.user_count} users`);
    });

    // Query 3: Detailed view with usernames
    console.log('\n\n🔗 Detailed upline chain (with usernames):\n');
    const result3 = await client.query(`
      SELECT
        u.world_id,
        u.username,
        u.level,
        u.upline_id,
        (
          SELECT jsonb_agg(
            jsonb_build_object(
              'world_id', up.world_id,
              'username', up.username,
              'level', up.level
            ) ORDER BY idx
          )
          FROM jsonb_array_elements_text(u.upline_id) WITH ORDINALITY AS arr(upline_uuid, idx)
          JOIN users up ON up.id = arr.upline_uuid::uuid
        ) as upline_details
      FROM users u
      WHERE u.level > 0 AND u.level <= 7
      ORDER BY u.run_number
      LIMIT 10
    `);

    result3.rows.forEach((row, idx) => {
      console.log(`${idx + 1}. ${row.world_id} - ${row.username} (Level ${row.level})`);
      if (row.upline_details) {
        const uplines = row.upline_details;
        console.log('   Upline chain:');
        uplines.forEach((up, i) => {
          console.log(`     ${i + 1}. ${up.world_id} - ${up.username} (Level ${up.level})`);
        });
      }
      console.log('');
    });

    console.log('='.repeat(70));
    console.log('✅ Verification Complete!\n');

  } catch (error) {
    console.error('\n❌ Error:', error.message);
    throw error;
  } finally {
    client.release();
    await pool.end();
  }
}

verifyUplineId()
  .then(() => process.exit(0))
  .catch(err => {
    console.error(err);
    process.exit(1);
  });
