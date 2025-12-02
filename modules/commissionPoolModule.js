/**
 * ===================================================
 * Commission Pool Distribution Module
 * ===================================================
 *
 * คำนวณและกระจาย Commission Pool เมื่อมีการซื้อประกัน
 *
 * กลไกการทำงาน:
 * 1. Commission = ราคาประกัน × Commission Rate
 * 2. แบ่ง Commission:
 *    - Management Fee = 10% × Commission
 *    - Seller Commission = 45% × Commission
 *    - Commission Pool = 45% × Commission
 * 3. แบ่ง Commission Pool เป็น 7 ส่วนเท่าๆ กัน:
 *    - ผู้ซื้อ: 1/7
 *    - Upline 1-6: อีก 6/7 (คนละ 1/7)
 *    - ถ้า Upline ไม่ครบ 6 คน ส่วนที่เหลือไปให้ System Root
 */

const COMMISSION_STRUCTURE = {
  MANAGEMENT_FEE_RATE: 0.10,      // 10%
  SELLER_COMMISSION_RATE: 0.45,   // 45%
  COMMISSION_POOL_RATE: 0.45,     // 45%
  POOL_TOTAL_SHARES: 7,            // แบ่งเป็น 7 ส่วน
  BUYER_SHARES: 1,                 // ผู้ซื้อได้ 1 ส่วน
  MAX_UPLINE_LEVELS: 6             // Upline สูงสุด 6 ชั้น
};

/**
 * คำนวณ Commission จากราคาประกัน
 */
function calculateCommission(premiumAmount, commissionRate) {
  const totalCommission = premiumAmount * commissionRate;
  const managementFee = totalCommission * COMMISSION_STRUCTURE.MANAGEMENT_FEE_RATE;
  const sellerCommission = totalCommission * COMMISSION_STRUCTURE.SELLER_COMMISSION_RATE;
  const commissionPool = totalCommission * COMMISSION_STRUCTURE.COMMISSION_POOL_RATE;

  return {
    totalCommission: parseFloat(totalCommission.toFixed(2)),
    managementFee: parseFloat(managementFee.toFixed(2)),
    sellerCommission: parseFloat(sellerCommission.toFixed(2)),
    commissionPool: parseFloat(commissionPool.toFixed(2))
  };
}

/**
 * ดึงข้อมูล Upline ของ user (สูงสุด 6 ชั้น)
 * @param {number} userId - User ID ของผู้ซื้อ
 * @param {object} client - PostgreSQL client
 * @returns {Promise<Array>} - Array ของ upline user IDs [parent, grandparent, ...]
 */
async function getUplineChain(userId, client) {
  const uplineChain = [];
  let currentUserId = userId;

  // ดึง upline สูงสุด 6 ชั้น
  for (let level = 1; level <= COMMISSION_STRUCTURE.MAX_UPLINE_LEVELS; level++) {
    const result = await client.query(
      'SELECT parent_user_id FROM users WHERE user_id = $1',
      [currentUserId]
    );

    if (result.rows.length === 0 || !result.rows[0].parent_user_id) {
      break; // ไม่มี parent แล้ว
    }

    const parentUserId = result.rows[0].parent_user_id;
    uplineChain.push(parentUserId);
    currentUserId = parentUserId;
  }

  return uplineChain;
}

/**
 * คำนวณการกระจาย Commission Pool
 * @param {number} commissionPool - จำนวน Commission Pool ทั้งหมด
 * @param {number} buyerUserId - User ID ของผู้ซื้อ
 * @param {Array} uplineChain - Array ของ upline user IDs
 * @param {number} systemRootUserId - User ID ของ System Root
 * @returns {Array} - Array ของ distribution records
 */
function calculateCommissionPoolDistribution(commissionPool, buyerUserId, uplineChain, systemRootUserId) {
  const shareAmount = commissionPool / COMMISSION_STRUCTURE.POOL_TOTAL_SHARES;
  const distribution = [];

  // 1. ผู้ซื้อได้ 1 ส่วน
  distribution.push({
    recipientUserId: buyerUserId,
    recipientRole: 'buyer',
    uplineLevel: 0,
    sharePortion: 1 / COMMISSION_STRUCTURE.POOL_TOTAL_SHARES,
    amount: parseFloat(shareAmount.toFixed(2))
  });

  // 2. Upline แต่ละคนได้ 1 ส่วน (สูงสุด 6 คน)
  uplineChain.forEach((uplineUserId, index) => {
    distribution.push({
      recipientUserId: uplineUserId,
      recipientRole: `upline_${index + 1}`,
      uplineLevel: index + 1,
      sharePortion: 1 / COMMISSION_STRUCTURE.POOL_TOTAL_SHARES,
      amount: parseFloat(shareAmount.toFixed(2))
    });
  });

  // 3. ถ้า Upline ไม่ครบ 6 คน ส่วนที่เหลือไปให้ System Root
  const remainingShares = COMMISSION_STRUCTURE.MAX_UPLINE_LEVELS - uplineChain.length;
  if (remainingShares > 0) {
    const remainingAmount = shareAmount * remainingShares;
    distribution.push({
      recipientUserId: systemRootUserId,
      recipientRole: 'system_root',
      uplineLevel: null,
      sharePortion: remainingShares / COMMISSION_STRUCTURE.POOL_TOTAL_SHARES,
      amount: parseFloat(remainingAmount.toFixed(2))
    });
  }

  return distribution;
}

/**
 * สร้าง Order และกระจาย Commission Pool
 * @param {object} orderData - ข้อมูล order
 * @param {object} client - PostgreSQL client (ใช้ใน transaction)
 * @returns {Promise<object>} - Order และ distribution records
 */
async function createOrderAndDistributeCommission(orderData, client) {
  const {
    userId,
    insuranceProductId,
    premiumAmount,
    commissionRate,
    systemRootUserId = 1 // Default system root user ID
  } = orderData;

  // 1. คำนวณ Commission
  const commission = calculateCommission(premiumAmount, commissionRate);

  // 2. สร้าง Order
  const orderResult = await client.query(
    `INSERT INTO orders (
      user_id, insurance_product_id, premium_amount, commission_rate,
      total_commission, management_fee, seller_commission, commission_pool,
      order_status, created_at
    ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, NOW())
    RETURNING order_id`,
    [
      userId,
      insuranceProductId,
      premiumAmount,
      commissionRate,
      commission.totalCommission,
      commission.managementFee,
      commission.sellerCommission,
      commission.commissionPool,
      'completed'
    ]
  );

  const orderId = orderResult.rows[0].order_id;

  // 3. ดึง Upline chain
  const uplineChain = await getUplineChain(userId, client);

  // 4. คำนวณการกระจาย Commission Pool
  const distribution = calculateCommissionPoolDistribution(
    commission.commissionPool,
    userId,
    uplineChain,
    systemRootUserId
  );

  // 5. บันทึกการกระจาย Commission Pool
  const distributionInsertPromises = distribution.map(dist =>
    client.query(
      `INSERT INTO commission_pool_distribution (
        order_id, recipient_user_id, recipient_role, upline_level,
        share_portion, amount, distributed_at
      ) VALUES ($1, $2, $3, $4, $5, $6, NOW())`,
      [
        orderId,
        dist.recipientUserId,
        dist.recipientRole,
        dist.uplineLevel,
        dist.sharePortion,
        dist.amount
      ]
    )
  );

  await Promise.all(distributionInsertPromises);

  return {
    orderId,
    commission,
    distribution,
    uplineCount: uplineChain.length,
    systemRootBonus: distribution.find(d => d.recipientRole === 'system_root')?.amount || 0
  };
}

/**
 * ดึงข้อมูล Commission Pool ที่ user คนหนึ่งได้รับทั้งหมด
 */
async function getUserCommissionSummary(userId, client) {
  const result = await client.query(
    `SELECT * FROM user_commission_summary WHERE recipient_user_id = $1`,
    [userId]
  );

  return result.rows[0] || null;
}

/**
 * ดึงรายละเอียดการกระจาย Commission Pool ของ Order หนึ่ง
 */
async function getOrderCommissionDetail(orderId, client) {
  const result = await client.query(
    `SELECT * FROM order_commission_detail WHERE order_id = $1`,
    [orderId]
  );

  return result.rows;
}

module.exports = {
  COMMISSION_STRUCTURE,
  calculateCommission,
  getUplineChain,
  calculateCommissionPoolDistribution,
  createOrderAndDistributeCommission,
  getUserCommissionSummary,
  getOrderCommissionDetail
};
