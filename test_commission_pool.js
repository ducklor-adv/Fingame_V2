/**
 * ===================================================
 * Test Script: Commission Pool System
 * ===================================================
 * ทดสอบการทำงานของระบบ Commission Pool
 */

const { Pool } = require('pg');
const commissionModule = require('./modules/commissionPoolModule');

const pool = new Pool({
  host: 'localhost',
  port: 5433,
  database: 'fingame',
  user: 'fingrow_user',
  password: 'fingrow_pass_2025'
});

// สีสำหรับแสดงผลใน Console
const colors = {
  reset: '\x1b[0m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  red: '\x1b[31m',
  cyan: '\x1b[36m'
};

function log(message, color = 'reset') {
  console.log(colors[color] + message + colors.reset);
}

/**
 * Test 1: ทดสอบการคำนวณ Commission
 */
function test1_CalculateCommission() {
  log('\n=== Test 1: Calculate Commission ===', 'cyan');

  const testCases = [
    { premium: 10000, rate: 0.15 },
    { premium: 20000, rate: 0.12 },
    { premium: 5000, rate: 0.10 }
  ];

  testCases.forEach((testCase, index) => {
    const result = commissionModule.calculateCommission(testCase.premium, testCase.rate);
    log(`\nTest Case ${index + 1}:`, 'blue');
    console.log(`  Premium: ${testCase.premium.toLocaleString()} บาท, Rate: ${(testCase.rate * 100)}%`);
    console.log(`  Total Commission: ${result.totalCommission.toLocaleString()} บาท`);
    console.log(`  Management Fee: ${result.managementFee.toLocaleString()} บาท`);
    console.log(`  Seller Commission: ${result.sellerCommission.toLocaleString()} บาท`);
    console.log(`  Commission Pool: ${result.commissionPool.toLocaleString()} บาท`);

    // Verify percentages
    const total = result.managementFee + result.sellerCommission + result.commissionPool;
    const isCorrect = Math.abs(total - result.totalCommission) < 0.01;
    log(`  ✓ Verification: ${isCorrect ? 'PASS' : 'FAIL'}`, isCorrect ? 'green' : 'red');
  });
}

/**
 * Test 2: ทดสอบการกระจาย Commission Pool
 */
function test2_DistributeCommissionPool() {
  log('\n=== Test 2: Distribute Commission Pool ===', 'cyan');

  const testCases = [
    {
      name: 'Full Upline Chain (6 uplines)',
      commissionPool: 675,
      buyerId: 100,
      uplineChain: [101, 102, 103, 104, 105, 106],
      systemRootId: 1
    },
    {
      name: 'Partial Upline Chain (2 uplines)',
      commissionPool: 1080,
      buyerId: 200,
      uplineChain: [201, 202],
      systemRootId: 1
    },
    {
      name: 'No Upline (Direct under root)',
      commissionPool: 450,
      buyerId: 300,
      uplineChain: [],
      systemRootId: 1
    }
  ];

  testCases.forEach((testCase, index) => {
    log(`\nTest Case ${index + 1}: ${testCase.name}`, 'blue');
    const distribution = commissionModule.calculateCommissionPoolDistribution(
      testCase.commissionPool,
      testCase.buyerId,
      testCase.uplineChain,
      testCase.systemRootId
    );

    console.log(`  Commission Pool: ${testCase.commissionPool.toLocaleString()} บาท`);
    console.log(`  Upline Count: ${testCase.uplineChain.length}`);
    console.log(`  Distribution:`);

    let totalDistributed = 0;
    distribution.forEach(dist => {
      console.log(`    • ${dist.recipientRole} (User ${dist.recipientUserId}): ${dist.amount} บาท (${(dist.sharePortion * 100).toFixed(2)}%)`);
      totalDistributed += dist.amount;
    });

    // Verify total
    const isCorrect = Math.abs(totalDistributed - testCase.commissionPool) < 0.01;
    log(`  Total Distributed: ${totalDistributed.toFixed(2)} บาท`, 'yellow');
    log(`  ✓ Verification: ${isCorrect ? 'PASS' : 'FAIL'}`, isCorrect ? 'green' : 'red');
  });
}

/**
 * Test 3: ทดสอบการดึง Upline Chain
 */
async function test3_GetUplineChain() {
  const client = await pool.connect();

  try {
    log('\n=== Test 3: Get Upline Chain ===', 'cyan');

    // ทดสอบกับ user_id ที่มีอยู่ในระบบ
    const testUserIds = [2, 3, 4, 5];

    for (const userId of testUserIds) {
      const uplineChain = await commissionModule.getUplineChain(userId, client);
      log(`\nUser ID ${userId}:`, 'blue');
      console.log(`  Upline Count: ${uplineChain.length}`);
      console.log(`  Upline Chain: [${uplineChain.join(' → ')}]`);

      // แสดงว่าจะได้รับ Commission Pool กี่ส่วน
      const remainingShares = 6 - uplineChain.length;
      if (remainingShares > 0) {
        log(`  → System Root จะได้รับ ${remainingShares} ส่วน`, 'yellow');
      } else {
        log(`  → Upline ครบ 6 คน, System Root ไม่ได้รับส่วนเพิ่ม`, 'green');
      }
    }

    log('\n✓ Test completed', 'green');

  } catch (error) {
    log(`✗ Error: ${error.message}`, 'red');
  } finally {
    client.release();
  }
}

/**
 * Test 4: ทดสอบสร้าง Order และกระจาย Commission (Dry Run - ไม่ Commit)
 */
async function test4_CreateOrderDryRun() {
  const client = await pool.connect();

  try {
    await client.query('BEGIN');
    log('\n=== Test 4: Create Order (Dry Run - No Commit) ===', 'cyan');

    const orderData = {
      userId: 3, // เปลี่ยนเป็น user_id ที่มีจริงในระบบ
      insuranceProductId: 1,
      premiumAmount: 15000,
      commissionRate: 0.15,
      systemRootUserId: 1
    };

    log('\nOrder Data:', 'blue');
    console.log(`  User ID: ${orderData.userId}`);
    console.log(`  Premium: ${orderData.premiumAmount.toLocaleString()} บาท`);
    console.log(`  Commission Rate: ${(orderData.commissionRate * 100)}%`);

    const result = await commissionModule.createOrderAndDistributeCommission(orderData, client);

    log('\nResult:', 'blue');
    console.log(`  Order ID: ${result.orderId}`);
    console.log(`  Total Commission: ${result.commission.totalCommission} บาท`);
    console.log(`  Commission Pool: ${result.commission.commissionPool} บาท`);
    console.log(`  Upline Count: ${result.uplineCount}`);
    console.log(`  System Root Bonus: ${result.systemRootBonus} บาท`);

    log('\nDistribution Details:', 'blue');
    result.distribution.forEach((dist, index) => {
      console.log(`  ${index + 1}. ${dist.recipientRole} (User ${dist.recipientUserId}): ${dist.amount} บาท`);
    });

    // Rollback เพื่อไม่ให้บันทึกข้อมูลจริง
    await client.query('ROLLBACK');
    log('\n✓ Test completed (ROLLBACK - no data saved)', 'green');

  } catch (error) {
    await client.query('ROLLBACK');
    log(`✗ Error: ${error.message}`, 'red');
  } finally {
    client.release();
  }
}

/**
 * รันทุก Tests
 */
async function runAllTests() {
  console.log('\n' + '='.repeat(60));
  log('Commission Pool System - Test Suite', 'cyan');
  console.log('='.repeat(60));

  // Test 1: Calculate Commission (ไม่ต้องใช้ Database)
  test1_CalculateCommission();

  // Test 2: Distribute Commission Pool (ไม่ต้องใช้ Database)
  test2_DistributeCommissionPool();

  // Test 3: Get Upline Chain (ใช้ Database)
  await test3_GetUplineChain();

  // Test 4: Create Order Dry Run (ใช้ Database แต่ไม่ Commit)
  await test4_CreateOrderDryRun();

  await pool.end();

  console.log('\n' + '='.repeat(60));
  log('All tests completed!', 'green');
  console.log('='.repeat(60) + '\n');
}

// รัน Tests
if (require.main === module) {
  runAllTests().catch(error => {
    log(`Fatal Error: ${error.message}`, 'red');
    console.error(error);
    process.exit(1);
  });
}

module.exports = { runAllTests };
