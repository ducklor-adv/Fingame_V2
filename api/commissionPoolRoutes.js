/**
 * ===================================================
 * Commission Pool API Routes
 * ===================================================
 * API endpoints สำหรับระบบ Commission Pool
 */

const express = require('express');
const { Pool } = require('pg');
const router = express.Router();
const commissionModule = require('../modules/commissionPoolModule');

// PostgreSQL connection
const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  port: parseInt(process.env.DB_PORT) || 5433,
  database: process.env.DB_NAME || 'fingame',
  user: process.env.DB_USER || 'fingrow_user',
  password: process.env.DB_PASSWORD || 'fingrow_pass_2025',
  connectionTimeoutMillis: 5000,
});

/**
 * POST /api/orders/create
 * สร้าง Order ใหม่และกระจาย Commission Pool
 *
 * Request Body:
 * {
 *   userId: number,
 *   insuranceProductId: number,
 *   paymentMethod: 'cash' | 'finpoint'
 * }
 */
router.post('/orders/create', async (req, res) => {
  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    const { userId, insuranceProductId, paymentMethod } = req.body;

    // Validate input
    if (!userId || !insuranceProductId || !paymentMethod) {
      await client.query('ROLLBACK');
      return res.status(400).json({
        success: false,
        error: 'Missing required fields: userId, insuranceProductId, paymentMethod'
      });
    }

    if (!['cash', 'finpoint'].includes(paymentMethod)) {
      await client.query('ROLLBACK');
      return res.status(400).json({
        success: false,
        error: 'paymentMethod must be "cash" or "finpoint"'
      });
    }

    // 1. ดึงข้อมูลประกัน
    const productResult = await client.query(
      'SELECT * FROM insurance_products WHERE id = $1',
      [insuranceProductId]
    );

    if (productResult.rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({
        success: false,
        error: 'Insurance product not found'
      });
    }

    const product = productResult.rows[0];
    const premiumAmount = parseFloat(product.premium_total || product.premiumTotal);
    const commissionRate = parseFloat(product.commission_rate || 0.15); // Default 15% if not set

    // 2. ถ้าใช้ Finpoint ตรวจสอบยอดคงเหลือ
    if (paymentMethod === 'finpoint') {
      const userFinpointResult = await client.query(
        `SELECT COALESCE(SUM(amount), 0) as total_finpoint
         FROM commission_pool_distribution
         WHERE recipient_user_id = $1`,
        [userId]
      );

      const currentFinpoint = parseFloat(userFinpointResult.rows[0].total_finpoint);

      // ตรวจสอบว่า User มี Finpoint เพียงพอหรือไม่
      if (currentFinpoint < premiumAmount) {
        await client.query('ROLLBACK');
        return res.status(400).json({
          success: false,
          error: 'Insufficient Finpoint',
          required: premiumAmount,
          available: currentFinpoint,
          shortage: premiumAmount - currentFinpoint
        });
      }

      // 3. บันทึกการใช้ Finpoint (เป็นรายการ -)
      // สร้าง special distribution record ที่มี amount เป็นลบ
      await client.query(
        `INSERT INTO commission_pool_distribution (
          order_id, recipient_user_id, recipient_role, upline_level,
          share_portion, amount, distributed_at
        ) VALUES (NULL, $1, 'finpoint_spent', NULL, 0, $2, NOW())`,
        [userId, -premiumAmount]
      );
    }

    // 4. สร้าง Order และกระจาย Commission Pool
    const orderData = {
      userId,
      insuranceProductId,
      premiumAmount,
      commissionRate,
      systemRootUserId: 1
    };

    const result = await commissionModule.createOrderAndDistributeCommission(orderData, client);

    await client.query('COMMIT');

    // 5. ดึงยอด Finpoint ใหม่
    const newFinpointResult = await client.query(
      `SELECT COALESCE(SUM(amount), 0) as total_finpoint
       FROM commission_pool_distribution
       WHERE recipient_user_id = $1`,
      [userId]
    );

    res.status(201).json({
      success: true,
      data: {
        orderId: result.orderId,
        paymentMethod,
        premiumAmount,
        commission: result.commission,
        distribution: result.distribution,
        uplineCount: result.uplineCount,
        systemRootBonus: result.systemRootBonus,
        userNewFinpoint: parseFloat(newFinpointResult.rows[0].total_finpoint)
      }
    });

  } catch (error) {
    await client.query('ROLLBACK');
    console.error('Error creating order:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  } finally {
    client.release();
  }
});

/**
 * POST /api/users/:userId/demo-finpoint
 * เติม Demo Finpoint ให้ User (สำหรับทดสอบเท่านั้น)
 */
router.post('/users/:userId/demo-finpoint', async (req, res) => {
  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    const { userId } = req.params;
    const { amount } = req.body;

    if (!amount || amount <= 0) {
      await client.query('ROLLBACK');
      return res.status(400).json({
        success: false,
        error: 'Amount must be greater than 0'
      });
    }

    // สร้าง special distribution record สำหรับ demo finpoint
    await client.query(
      `INSERT INTO commission_pool_distribution (
        insurance_order_id, recipient_user_id, recipient_role, upline_level,
        share_portion, amount, transaction_type, description, distributed_at
      ) VALUES (NULL, $1, 'demo_purchase', NULL, 0, $2, 'demo', 'เติม Demo Finpoint เพื่อทดสอบระบบ', NOW())`,
      [userId, amount]
    );

    // ดึงยอด Finpoint ใหม่
    const result = await client.query(
      `SELECT COALESCE(SUM(amount), 0) as total_finpoint
       FROM commission_pool_distribution
       WHERE recipient_user_id = $1`,
      [userId]
    );

    await client.query('COMMIT');

    res.json({
      success: true,
      data: {
        userId,
        amountAdded: amount,
        newFinpoint: parseFloat(result.rows[0].total_finpoint)
      }
    });

  } catch (error) {
    await client.query('ROLLBACK');
    console.error('Error adding demo finpoint:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  } finally {
    client.release();
  }
});

/**
 * GET /api/users/:userId/finpoint
 * ดึงยอด Finpoint ปัจจุบันของ User
 */
router.get('/users/:userId/finpoint', async (req, res) => {
  const client = await pool.connect();

  try {
    const { userId } = req.params;

    const result = await client.query(
      `SELECT COALESCE(SUM(amount), 0) as total_finpoint
       FROM commission_pool_distribution
       WHERE recipient_user_id = $1`,
      [userId]
    );

    res.json({
      success: true,
      data: {
        userId: parseInt(userId),
        totalFinpoint: parseFloat(result.rows[0].total_finpoint)
      }
    });

  } catch (error) {
    console.error('Error getting finpoint:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  } finally {
    client.release();
  }
});

/**
 * GET /api/users/:userId/transactions
 * ดึงรายการธุรกรรมทั้งหมดของ User (รับ + และจ่าย -)
 */
router.get('/users/:userId/transactions', async (req, res) => {
  const client = await pool.connect();

  try {
    const { userId } = req.params;
    const { limit = 50, offset = 0 } = req.query;

    // ดึงรายการรับ Commission Pool
    const transactionsResult = await client.query(
      `SELECT
        cpd.id as id,
        cpd.insurance_order_id as order_id,
        cpd.amount,
        cpd.recipient_role as type,
        cpd.upline_level,
        cpd.distributed_at as datetime,
        o.user_id as buyer_user_id,
        o.insurance_product_id,
        o.premium_amount,
        u.username as buyer_username,
        ip.short_title as insurance_name
       FROM commission_pool_distribution cpd
       LEFT JOIN insurance_orders o ON cpd.insurance_order_id = o.id
       LEFT JOIN users u ON o.user_id = u.id
       LEFT JOIN insurance_product ip ON o.insurance_product_id = ip.id
       WHERE cpd.recipient_user_id = $1
       ORDER BY cpd.distributed_at DESC
       LIMIT $2 OFFSET $3`,
      [userId, limit, offset]
    );

    // นับจำนวนทั้งหมด
    const countResult = await client.query(
      `SELECT COUNT(*) as total
       FROM commission_pool_distribution
       WHERE recipient_user_id = $1`,
      [userId]
    );

    // คำนวณยอดรวม
    const summaryResult = await client.query(
      `SELECT
        COALESCE(SUM(amount), 0) as total_finpoint,
        COALESCE(SUM(CASE WHEN amount > 0 THEN amount ELSE 0 END), 0) as total_received,
        COALESCE(SUM(CASE WHEN amount < 0 THEN amount ELSE 0 END), 0) as total_spent
       FROM commission_pool_distribution
       WHERE recipient_user_id = $1`,
      [userId]
    );

    const transactions = transactionsResult.rows.map(row => {
      const isNegative = parseFloat(row.amount) < 0;
      const absAmount = Math.abs(parseFloat(row.amount));

      return {
        id: row.id,
        orderId: row.order_id,
        amount: parseFloat(row.amount),
        displayAmount: isNegative ? `-${absAmount.toLocaleString()}` : `+${absAmount.toLocaleString()}`,
        type: row.type, // 'buyer', 'upline_1', 'finpoint_spent', etc.
        category: isNegative ? 'ใช้ Finpoint ซื้อประกัน' : getTransactionCategory(row.type),
        detail: getTransactionDetail(row),
        datetime: row.datetime,
        drCr: isNegative ? 'CR' : 'DR' // DR = รับ, CR = จ่าย
      };
    });

    res.json({
      success: true,
      data: {
        transactions,
        summary: {
          totalFinpoint: parseFloat(summaryResult.rows[0].total_finpoint),
          totalReceived: parseFloat(summaryResult.rows[0].total_received),
          totalSpent: Math.abs(parseFloat(summaryResult.rows[0].total_spent))
        },
        pagination: {
          total: parseInt(countResult.rows[0].total),
          limit: parseInt(limit),
          offset: parseInt(offset)
        }
      }
    });

  } catch (error) {
    console.error('Error getting transactions:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  } finally {
    client.release();
  }
});

/**
 * GET /api/users/:userId/commission-summary
 * สรุป Commission Pool ที่ User ได้รับ
 */
router.get('/users/:userId/commission-summary', async (req, res) => {
  const client = await pool.connect();

  try {
    const { userId } = req.params;

    const summary = await commissionModule.getUserCommissionSummary(userId, client);

    if (!summary) {
      return res.json({
        success: true,
        data: {
          userId: parseInt(userId),
          totalOrdersParticipated: 0,
          totalDistributions: 0,
          totalFromOwnPurchase: 0,
          totalFromNetwork: 0,
          totalFromSystem: 0,
          totalCommissionReceived: 0
        }
      });
    }

    res.json({
      success: true,
      data: {
        userId: parseInt(userId),
        totalOrdersParticipated: parseInt(summary.total_orders_participated),
        totalDistributions: parseInt(summary.total_distributions),
        totalFromOwnPurchase: parseFloat(summary.total_from_own_purchase),
        totalFromNetwork: parseFloat(summary.total_from_network),
        totalFromSystem: parseFloat(summary.total_from_system),
        totalCommissionReceived: parseFloat(summary.total_commission_received)
      }
    });

  } catch (error) {
    console.error('Error getting commission summary:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  } finally {
    client.release();
  }
});

/**
 * GET /api/orders/:orderId/commission-detail
 * ดูรายละเอียดการกระจาย Commission Pool ของ Order หนึ่ง
 */
router.get('/orders/:orderId/commission-detail', async (req, res) => {
  const client = await pool.connect();

  try {
    const { orderId } = req.params;

    const details = await commissionModule.getOrderCommissionDetail(orderId, client);

    if (details.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'Order not found'
      });
    }

    const order = details[0];

    res.json({
      success: true,
      data: {
        orderId: parseInt(orderId),
        buyerUserId: order.buyer_user_id,
        premiumAmount: parseFloat(order.premium_amount),
        commissionPool: parseFloat(order.commission_pool),
        distribution: details.map(d => ({
          recipientUserId: d.recipient_user_id,
          recipientUsername: d.recipient_username,
          recipientRole: d.recipient_role,
          uplineLevel: d.upline_level,
          sharePortion: parseFloat(d.share_portion),
          amount: parseFloat(d.amount),
          distributedAt: d.distributed_at
        }))
      }
    });

  } catch (error) {
    console.error('Error getting order commission detail:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  } finally {
    client.release();
  }
});

// Helper functions
function getTransactionCategory(type) {
  const categories = {
    'buyer': 'รับจากการซื้อเอง',
    'upline_1': 'รับจาก Downline ชั้น 1',
    'upline_2': 'รับจาก Downline ชั้น 2',
    'upline_3': 'รับจาก Downline ชั้น 3',
    'upline_4': 'รับจาก Downline ชั้น 4',
    'upline_5': 'รับจาก Downline ชั้น 5',
    'upline_6': 'รับจาก Downline ชั้น 6',
    'system_root': 'โบนัสจากระบบ',
    'finpoint_spent': 'ใช้ Finpoint ซื้อประกัน',
    'demo_purchase': 'เติม Demo Finpoint'
  };
  return categories[type] || type;
}

function getTransactionDetail(row) {
  if (row.type === 'demo_purchase') {
    return 'สำหรับทดสอบระบบ';
  }
  if (row.type === 'finpoint_spent') {
    return row.insurance_name || 'ซื้อประกัน';
  }
  if (row.type === 'buyer') {
    return `ซื้อ ${row.insurance_name || 'ประกัน'}`;
  }
  return `${row.buyer_username || 'User'} ซื้อ ${row.insurance_name || 'ประกัน'}`;
}

module.exports = router;
