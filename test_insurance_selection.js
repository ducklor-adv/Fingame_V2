// Test insurance selection functionality
const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  port: process.env.DB_PORT || 5433,
  database: process.env.DB_NAME || 'fingame',
  user: process.env.DB_USER || 'fingrow_user',
  password: process.env.DB_PASSWORD || 'fingrow_pass_2025',
});

async function testInsuranceSelection() {
  const client = await pool.connect();

  try {
    console.log('\n' + '='.repeat(70));
    console.log('🧪 Testing Insurance Selection Functionality');
    console.log('='.repeat(70));

    // Get first 3 users
    console.log('\n📋 Getting test users...');
    const usersResult = await client.query(`
      SELECT id, world_id, username
      FROM users
      ORDER BY run_number
      LIMIT 3
    `);

    const users = usersResult.rows;
    console.log(`Found ${users.length} users for testing\n`);

    // Get available insurance products by level
    console.log('📦 Getting insurance products...');
    const productsResult = await client.query(`
      SELECT id, fingrow_level, short_title, premium_total
      FROM insurance_product
      WHERE is_active = true
      ORDER BY fingrow_level, premium_total
    `);

    const productsByLevel = {};
    productsResult.rows.forEach(product => {
      if (!productsByLevel[product.fingrow_level]) {
        productsByLevel[product.fingrow_level] = [];
      }
      productsByLevel[product.fingrow_level].push(product);
    });

    console.log(`Found products for levels: ${Object.keys(productsByLevel).join(', ')}\n`);

    // Create sample selections
    console.log('💾 Creating sample selections...\n');

    for (let i = 0; i < users.length; i++) {
      const user = users[i];
      const level = (i % 4) + 1; // Assign levels 1-4

      console.log(`User ${i + 1}: ${user.world_id} - ${user.username}`);
      console.log(`  Assigning Level ${level} products:`);

      const levelProducts = productsByLevel[level] || [];

      // Select 1-2 products for this level
      const numToSelect = Math.min(levelProducts.length, 2);

      for (let j = 0; j < numToSelect; j++) {
        const product = levelProducts[j];

        try {
          await client.query(
            `INSERT INTO user_insurance_selections
             (user_id, insurance_product_id, priority)
             VALUES ($1, $2, $3)
             ON CONFLICT DO NOTHING`,
            [user.id, product.id, j + 1]
          );

          console.log(`    ✓ ${product.short_title} (${product.premium_total} THB)`);
        } catch (error) {
          console.log(`    ✗ Failed to add ${product.short_title}`);
        }
      }
      console.log('');
    }

    // Verify selections
    console.log('=' + '='.repeat(69));
    console.log('✅ Verification - User Insurance Selections');
    console.log('=' + '='.repeat(69) + '\n');

    for (const user of users) {
      const result = await client.query(`
        SELECT
          s.id,
          s.priority,
          s.selected_at,
          p.fingrow_level,
          p.short_title,
          p.premium_total,
          p.finpoint_rate_per_100
        FROM user_insurance_selections s
        JOIN insurance_product p ON s.insurance_product_id = p.id
        WHERE s.user_id = $1 AND s.is_active = true
        ORDER BY p.fingrow_level, s.priority
      `, [user.id]);

      console.log(`${user.world_id} - ${user.username}:`);

      if (result.rows.length === 0) {
        console.log('  No selections\n');
      } else {
        result.rows.forEach((row, idx) => {
          console.log(`  ${idx + 1}. [Level ${row.fingrow_level}] ${row.short_title}`);
          console.log(`     Premium: ${row.premium_total} THB | FP Rate: ${row.finpoint_rate_per_100}/100`);
          console.log(`     Priority: ${row.priority} | Selected: ${new Date(row.selected_at).toLocaleString('th-TH')}`);
        });
        console.log('');
      }
    }

    console.log('=' + '='.repeat(69));
    console.log('🎉 Test Completed Successfully!');
    console.log('=' + '='.repeat(69) + '\n');

  } catch (error) {
    console.error('\n❌ Error:', error.message);
    console.error('Stack:', error.stack);
    throw error;
  } finally {
    client.release();
    await pool.end();
  }
}

testInsuranceSelection()
  .then(() => {
    console.log('✅ Script completed!');
    process.exit(0);
  })
  .catch(err => {
    console.error('❌ Script failed:', err);
    process.exit(1);
  });
