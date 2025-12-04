/**
 * Fix update_updated_at_column trigger to use Unix timestamp
 */

const { Pool } = require('pg');

const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  port: parseInt(process.env.DB_PORT) || 5433,
  database: process.env.DB_NAME || 'fingame',
  user: process.env.DB_USER || 'fingrow_user',
  password: process.env.DB_PASSWORD || 'fingrow_pass_2025',
});

async function fixTrigger() {
  try {
    console.log('Fixing update_updated_at_column trigger...');

    const result = await pool.query(`
      CREATE OR REPLACE FUNCTION update_updated_at_column()
      RETURNS TRIGGER AS $$
      BEGIN
          NEW.updated_at = EXTRACT(EPOCH FROM NOW())::BIGINT * 1000;
          RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;
    `);

    console.log('✅ Trigger function updated successfully!');
    console.log('The trigger now converts timestamp to Unix milliseconds (bigint)');

  } catch (error) {
    console.error('❌ Error fixing trigger:', error);
  } finally {
    await pool.end();
  }
}

fixTrigger();
