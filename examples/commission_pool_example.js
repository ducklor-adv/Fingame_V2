/**
 * ===================================================
 * ตัวอย่างการใช้งาน Commission Pool Module
 * ===================================================
 */

const { Pool } = require('pg');
const commissionModule = require('../modules/commissionPoolModule');

// Database configuration
const pool = new Pool({
  host: 'localhost',
  port: 5433,
  database: 'fingame',
  user: 'fingrow_user',
  password: 'fingrow_pass_2025'
});

/**
 * ตัวอย่างที่ 1: สร้าง Order และกระจาย Commission Pool
 * กรณี: User ชั้นที่ 7 (มี Upline ครบ 6 คน)
 */
async function example1_FullUplineChain() {
  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    console.log('=== ตัวอย่างที่ 1: User ชั้นที่ 7 (มี Upline ครบ 6 คน) ===\n');

    const orderData = {
      userId: 8, // User ชั้นที่ 7 (สมมติ)
      insuranceProductId: 1,
      premiumAmount: 10000, // ราคาประกัน 10,000 บาท
      commissionRate: 0.15, // Commission rate 15%
      systemRootUserId: 1
    };

    const result = await commissionModule.createOrderAndDistributeCommission(orderData, client);

    console.log('Order ID:', result.orderId);
    console.log('\nCommission Breakdown:');
    console.log('- Total Commission:', result.commission.totalCommission, 'บาท');
    console.log('- Management Fee (10%):', result.commission.managementFee, 'บาท');
    console.log('- Seller Commission (45%):', result.commission.sellerCommission, 'บาท');
    console.log('- Commission Pool (45%):', result.commission.commissionPool, 'บาท');

    console.log('\nCommission Pool Distribution:');
    console.log('- จำนวน Upline:', result.uplineCount, 'คน');
    console.log('- ส่วนที่ไปให้ System Root:', result.systemRootBonus, 'บาท');

    console.log('\nรายละเอียดการแบ่ง:');
    result.distribution.forEach(dist => {
      console.log(`  • ${dist.recipientRole} (User ID: ${dist.recipientUserId}): ${dist.amount} บาท (${(dist.sharePortion * 100).toFixed(2)}%)`);
    });

    await client.query('COMMIT');
    console.log('\n✓ Transaction committed successfully\n');

  } catch (error) {
    await client.query('ROLLBACK');
    console.error('Error:', error.message);
  } finally {
    client.release();
  }
}

/**
 * ตัวอย่างที่ 2: สร้าง Order และกระจาย Commission Pool
 * กรณี: User ชั้นที่ 3 (มี Upline เพียง 2 คน)
 */
async function example2_PartialUplineChain() {
  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    console.log('=== ตัวอย่างที่ 2: User ชั้นที่ 3 (มี Upline เพียง 2 คน) ===\n');

    const orderData = {
      userId: 4, // User ชั้นที่ 3 (สมมติ)
      insuranceProductId: 2,
      premiumAmount: 20000, // ราคาประกัน 20,000 บาท
      commissionRate: 0.12, // Commission rate 12%
      systemRootUserId: 1
    };

    const result = await commissionModule.createOrderAndDistributeCommission(orderData, client);

    console.log('Order ID:', result.orderId);
    console.log('\nCommission Breakdown:');
    console.log('- Total Commission:', result.commission.totalCommission, 'บาท');
    console.log('- Management Fee (10%):', result.commission.managementFee, 'บาท');
    console.log('- Seller Commission (45%):', result.commission.sellerCommission, 'บาท');
    console.log('- Commission Pool (45%):', result.commission.commissionPool, 'บาท');

    console.log('\nCommission Pool Distribution:');
    console.log('- จำนวน Upline:', result.uplineCount, 'คน (ไม่ครบ 6 คน)');
    console.log('- ส่วนที่ไปให้ System Root:', result.systemRootBonus, 'บาท (4 ส่วนจาก 7 ส่วน)');

    console.log('\nรายละเอียดการแบ่ง:');
    result.distribution.forEach(dist => {
      console.log(`  • ${dist.recipientRole} (User ID: ${dist.recipientUserId}): ${dist.amount} บาท (${(dist.sharePortion * 100).toFixed(2)}%)`);
    });

    await client.query('COMMIT');
    console.log('\n✓ Transaction committed successfully\n');

  } catch (error) {
    await client.query('ROLLBACK');
    console.error('Error:', error.message);
  } finally {
    client.release();
  }
}

/**
 * ตัวอย่างที่ 3: ดูสรุป Commission Pool ของ User
 */
async function example3_GetUserCommissionSummary() {
  const client = await pool.connect();

  try {
    console.log('=== ตัวอย่างที่ 3: สรุป Commission Pool ของ User ===\n');

    const userId = 2;
    const summary = await commissionModule.getUserCommissionSummary(userId, client);

    if (summary) {
      console.log(`User ID: ${userId}`);
      console.log(`\nสรุปการรับ Commission:`);
      console.log(`- จำนวน Orders ที่เกี่ยวข้อง: ${summary.total_orders_participated}`);
      console.log(`- จำนวนครั้งที่ได้รับ: ${summary.total_distributions}`);
      console.log(`- จากการซื้อเอง: ${parseFloat(summary.total_from_own_purchase).toLocaleString()} บาท`);
      console.log(`- จากเครือข่าย (Upline): ${parseFloat(summary.total_from_network).toLocaleString()} บาท`);
      console.log(`- จาก System Root: ${parseFloat(summary.total_from_system).toLocaleString()} บาท`);
      console.log(`- รวมทั้งหมด: ${parseFloat(summary.total_commission_received).toLocaleString()} บาท`);
    } else {
      console.log(`User ID ${userId} ยังไม่มีประวัติรับ Commission`);
    }

  } catch (error) {
    console.error('Error:', error.message);
  } finally {
    client.release();
  }
}

/**
 * ตัวอย่างที่ 4: ดูรายละเอียดการกระจาย Commission Pool ของ Order
 */
async function example4_GetOrderCommissionDetail() {
  const client = await pool.connect();

  try {
    console.log('=== ตัวอย่างที่ 4: รายละเอียดการกระจาย Commission Pool ของ Order ===\n');

    const orderId = 1;
    const details = await commissionModule.getOrderCommissionDetail(orderId, client);

    if (details.length > 0) {
      const order = details[0];
      console.log(`Order ID: ${orderId}`);
      console.log(`Buyer: User ID ${order.buyer_user_id}`);
      console.log(`Premium Amount: ${parseFloat(order.premium_amount).toLocaleString()} บาท`);
      console.log(`Commission Pool: ${parseFloat(order.commission_pool).toLocaleString()} บาท`);

      console.log(`\nการกระจาย Commission Pool:`);
      details.forEach((detail, index) => {
        console.log(`${index + 1}. ${detail.recipient_username} (${detail.recipient_role}): ${parseFloat(detail.amount).toLocaleString()} บาท`);
      });
    } else {
      console.log(`Order ID ${orderId} ไม่พบข้อมูล`);
    }

  } catch (error) {
    console.error('Error:', error.message);
  } finally {
    client.release();
  }
}

/**
 * ตัวอย่างที่ 5: คำนวณ Commission (ไม่บันทึกลง Database)
 */
function example5_CalculateCommissionOnly() {
  console.log('=== ตัวอย่างที่ 5: คำนวณ Commission (ไม่บันทึก) ===\n');

  const premiumAmount = 15000;
  const commissionRate = 0.10; // 10%

  const result = commissionModule.calculateCommission(premiumAmount, commissionRate);

  console.log(`ราคาประกัน: ${premiumAmount.toLocaleString()} บาท`);
  console.log(`Commission Rate: ${(commissionRate * 100)}%`);
  console.log(`\nผลการคำนวณ:`);
  console.log(`- Total Commission: ${result.totalCommission.toLocaleString()} บาท`);
  console.log(`- Management Fee (10%): ${result.managementFee.toLocaleString()} บาท`);
  console.log(`- Seller Commission (45%): ${result.sellerCommission.toLocaleString()} บาท`);
  console.log(`- Commission Pool (45%): ${result.commissionPool.toLocaleString()} บาท`);
  console.log(`\nแต่ละส่วนใน Commission Pool (แบ่ง 7 ส่วน):`);
  console.log(`- แต่ละส่วน: ${(result.commissionPool / 7).toFixed(2)} บาท`);
}

// รัน Examples
async function runAllExamples() {
  console.log('\n' + '='.repeat(60));
  console.log('Commission Pool Module - Examples');
  console.log('='.repeat(60) + '\n');

  // Example 5: Calculate only (ไม่ต้องใช้ Database)
  example5_CalculateCommissionOnly();
  console.log('\n');

  // Examples ที่ใช้ Database
  // หมายเหตุ: Comment out บรรทัดที่ไม่ต้องการรัน

  // await example1_FullUplineChain();
  // await example2_PartialUplineChain();
  // await example3_GetUserCommissionSummary();
  // await example4_GetOrderCommissionDetail();

  await pool.end();
  console.log('='.repeat(60));
  console.log('All examples completed!');
  console.log('='.repeat(60) + '\n');
}

// รันถ้าเรียก file นี้โดยตรง
if (require.main === module) {
  runAllExamples().catch(console.error);
}

module.exports = {
  example1_FullUplineChain,
  example2_PartialUplineChain,
  example3_GetUserCommissionSummary,
  example4_GetOrderCommissionDetail,
  example5_CalculateCommissionOnly
};
