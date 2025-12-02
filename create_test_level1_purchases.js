/**
 * ===================================================
 * สร้างข้อมูลทดสอบ: ทุกคนซื้อ พ.ร.บ. รถ (Level 1)
 * ===================================================
 * สร้างรายการซื้อประกัน Level 1 ให้กับทุก User ในระบบ
 * เพื่อทดสอบระบบ Commission Pool Distribution
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

// ฟังก์ชันดึง Upline Chain (ใช้ parent_id แทน parent_user_id)
async function getUplineChain(userId, client) {
  const uplineChain = [];
  let currentUserId = userId;

  // ดึง upline สูงสุด 6 ชั้น
  for (let level = 1; level <= 6; level++) {
    const result = await client.query(
      'SELECT parent_id FROM users WHERE id = $1',
      [currentUserId]
    );

    if (result.rows.length === 0 || !result.rows[0].parent_id) {
      break; // ไม่มี parent แล้ว
    }

    const parentUserId = result.rows[0].parent_id;
    uplineChain.push(parentUserId);
    currentUserId = parentUserId;
  }

  return uplineChain;
}

// ฟังก์ชันคำนวณและกระจาย Commission Pool
async function createInsuranceOrder(orderData, client) {
  const {
    userId,
    insuranceProductId,
    premiumAmount,
    commissionRate,
    paymentMethod = 'cash',
    systemRootUserId
  } = orderData;

  // 1. คำนวณ Commission
  const totalCommission = premiumAmount * (commissionRate / 100);
  const managementFee = totalCommission * 0.10;      // 10%
  const sellerCommission = totalCommission * 0.45;   // 45%
  const commissionPool = totalCommission * 0.45;     // 45%

  // 2. Generate Order Number
  const orderNumberResult = await client.query('SELECT generate_insurance_order_number()');
  const orderNumber = orderNumberResult.rows[0].generate_insurance_order_number;

  // 3. สร้าง Insurance Order
  const orderResult = await client.query(
    `INSERT INTO insurance_orders (
      order_number, user_id, insurance_product_id, premium_amount, commission_rate,
      total_commission, management_fee, seller_commission, commission_pool,
      payment_method, finpoint_spent, order_status, created_at
    ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, NOW())
    RETURNING id`,
    [
      orderNumber,
      userId,
      insuranceProductId,
      premiumAmount,
      commissionRate,
      totalCommission.toFixed(2),
      managementFee.toFixed(2),
      sellerCommission.toFixed(2),
      commissionPool.toFixed(2),
      paymentMethod,
      paymentMethod === 'finpoint' ? premiumAmount : 0,
      'completed'
    ]
  );

  const orderId = orderResult.rows[0].id;

  // 4. ดึง Upline Chain
  const uplineChain = await getUplineChain(userId, client);

  // 5. คำนวณการกระจาย Commission Pool (แบ่ง 7 ส่วน)
  const shareAmount = commissionPool / 7;
  const distribution = [];

  // ผู้ซื้อได้ 1 ส่วน (1/7)
  distribution.push({
    recipientUserId: userId,
    recipientRole: 'buyer',
    uplineLevel: 0,
    sharePortion: 1 / 7,
    amount: shareAmount
  });

  // Upline แต่ละคนได้ 1 ส่วน (สูงสุด 6 คน)
  uplineChain.forEach((uplineUserId, index) => {
    distribution.push({
      recipientUserId: uplineUserId,
      recipientRole: `upline_${index + 1}`,
      uplineLevel: index + 1,
      sharePortion: 1 / 7,
      amount: shareAmount
    });
  });

  // ถ้า Upline ไม่ครบ 6 คน ส่วนที่เหลือไปให้ System Root
  const remainingShares = 6 - uplineChain.length;
  if (remainingShares > 0 && systemRootUserId) {
    const remainingAmount = shareAmount * remainingShares;
    distribution.push({
      recipientUserId: systemRootUserId,
      recipientRole: 'system_root',
      uplineLevel: null,
      sharePortion: remainingShares / 7,
      amount: remainingAmount
    });
  }

  // 6. บันทึกการกระจาย Commission Pool
  for (const dist of distribution) {
    await client.query(
      `INSERT INTO commission_pool_distribution (
        insurance_order_id, recipient_user_id, recipient_role, upline_level,
        share_portion, amount, transaction_type, distributed_at
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, NOW())`,
      [
        orderId,
        dist.recipientUserId,
        dist.recipientRole,
        dist.uplineLevel,
        dist.sharePortion.toFixed(6),
        dist.amount.toFixed(2),
        'commission'
      ]
    );
  }

  return {
    orderId,
    orderNumber,
    commission: {
      totalCommission: parseFloat(totalCommission.toFixed(2)),
      managementFee: parseFloat(managementFee.toFixed(2)),
      sellerCommission: parseFloat(sellerCommission.toFixed(2)),
      commissionPool: parseFloat(commissionPool.toFixed(2))
    },
    distribution,
    uplineCount: uplineChain.length,
    systemRootBonus: distribution.find(d => d.recipientRole === 'system_root')?.amount || 0
  };
}

// สคริปต์หลัก: สร้างรายการซื้อให้ทุกคน
async function createTestPurchases() {
  const client = await pool.connect();

  try {
    console.log('='.repeat(70));
    console.log('สร้างข้อมูลทดสอบ: ทุกคนซื้อ พ.ร.บ. รถ (Level 1)');
    console.log('='.repeat(70));

    await client.query('BEGIN');

    // 1. ดึง User ทั้งหมดในระบบ
    const usersResult = await client.query(`
      SELECT id, username, world_id, parent_id
      FROM users
      WHERE is_active = true
      ORDER BY world_id
    `);

    console.log(`\nพบ ${usersResult.rows.length} users ในระบบ\n`);

    // 2. ดึงประกัน พ.ร.บ. รถยนต์ (Level 1)
    const productResult = await client.query(`
      SELECT id, short_title, premium_total, commission_percent
      FROM insurance_product
      WHERE insurance_type = 'PRB' AND vehicle_type = 'car' AND fingrow_level = 1
      LIMIT 1
    `);

    if (productResult.rows.length === 0) {
      throw new Error('ไม่พบประกัน พ.ร.บ. รถยนต์ในระบบ');
    }

    const product = productResult.rows[0];
    console.log(`ประกัน: ${product.short_title}`);
    console.log(`ราคา: ${parseFloat(product.premium_total).toLocaleString()} บาท`);
    console.log(`Commission Rate: ${parseFloat(product.commission_percent)}%\n`);
    console.log('-'.repeat(70));

    // 3. หา System Root User (user ที่ไม่มี parent)
    const systemRootResult = await client.query(`
      SELECT id, username
      FROM users
      WHERE parent_id IS NULL
      LIMIT 1
    `);

    const systemRootUserId = systemRootResult.rows.length > 0 ? systemRootResult.rows[0].id : null;
    if (systemRootUserId) {
      console.log(`System Root: ${systemRootResult.rows[0].username} (${systemRootUserId})\n`);
    }

    // 4. สร้างรายการซื้อให้ทุกคน
    let successCount = 0;
    let errorCount = 0;

    for (const user of usersResult.rows) {
      try {
        const result = await createInsuranceOrder({
          userId: user.id,
          insuranceProductId: product.id,
          premiumAmount: parseFloat(product.premium_total),
          commissionRate: parseFloat(product.commission_percent),
          paymentMethod: 'cash', // Level 1 ต้องใช้เงินสด
          systemRootUserId
        }, client);

        console.log(`✓ ${user.username.padEnd(20)} | Order: ${result.orderNumber} | Upline: ${result.uplineCount} คน | Pool: ${result.commission.commissionPool.toLocaleString()} บาท`);
        successCount++;

      } catch (error) {
        console.error(`✗ ${user.username.padEnd(20)} | Error: ${error.message}`);
        errorCount++;
      }
    }

    await client.query('COMMIT');

    console.log('-'.repeat(70));
    console.log(`\nสรุปผลการสร้างข้อมูล:`);
    console.log(`  สำเร็จ: ${successCount} รายการ`);
    console.log(`  ล้มเหลว: ${errorCount} รายการ`);
    console.log(`  รวม: ${usersResult.rows.length} รายการ`);

    // 5. แสดงสรุป Finpoint ของแต่ละคน
    console.log('\n' + '='.repeat(70));
    console.log('สรุป Finpoint ของแต่ละ User');
    console.log('='.repeat(70));

    const summaryResult = await client.query(`
      SELECT
        u.username,
        u.world_id,
        COALESCE(ufs.current_finpoint, 0) as finpoint,
        COALESCE(ufs.from_own_purchase, 0) as from_self,
        COALESCE(ufs.from_network, 0) as from_network,
        COALESCE(ufs.from_system, 0) as from_system
      FROM users u
      LEFT JOIN user_finpoint_summary ufs ON u.id = ufs.recipient_user_id
      WHERE u.is_active = true
      ORDER BY COALESCE(ufs.current_finpoint, 0) DESC
      LIMIT 20
    `);

    console.log('\nTop 20 Users โดย Finpoint:');
    console.log('-'.repeat(70));
    summaryResult.rows.forEach((row, index) => {
      console.log(`${(index + 1).toString().padStart(2)}. ${row.username.padEnd(20)} | FP: ${parseFloat(row.finpoint).toFixed(2).padStart(10)} | ตัวเอง: ${parseFloat(row.from_self).toFixed(2).padStart(8)} | เครือข่าย: ${parseFloat(row.from_network).toFixed(2).padStart(10)}`);
    });

    console.log('\n' + '='.repeat(70));
    console.log('เสร็จสิ้น!');
    console.log('='.repeat(70));

  } catch (error) {
    await client.query('ROLLBACK');
    console.error('\n❌ Error:', error.message);
    console.error(error.stack);
  } finally {
    client.release();
    await pool.end();
  }
}

// รันสคริปต์
if (require.main === module) {
  createTestPurchases().catch(console.error);
}

module.exports = { createTestPurchases, createInsuranceOrder, getUplineChain };
