/**
 * Finpoint API Endpoints
 *
 * Endpoints:
 * - GET /api/finpoint/:userId/balance
 * - GET /api/finpoint/:userId/transactions
 * - GET /api/finpoint/:userId/ledger
 * - GET /api/finpoint/:userId/today
 */

const express = require('express');
const { Pool } = require('pg');

const router = express.Router();

const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  port: parseInt(process.env.DB_PORT) || 5433,
  database: process.env.DB_NAME || 'fingame',
  user: process.env.DB_USER || 'fingrow_user',
  password: process.env.DB_PASSWORD || 'fingrow_pass_2025',
  connectionTimeoutMillis: 5000,
});

// ============================================================================
// GET /api/finpoint/:userId/balance
// Get user's current FP balance
// ============================================================================
router.get('/:userId/balance', async (req, res) => {
  try {
    const { userId } = req.params;

    // Check if user exists
    const userCheck = await pool.query(
      'SELECT id FROM users WHERE id = $1',
      [userId]
    );

    if (userCheck.rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }

    // Calculate balance from commission_pool_distribution
    const balanceResult = await pool.query(
      `SELECT
        COALESCE(SUM(amount), 0) as current_balance
      FROM commission_pool_distribution
      WHERE recipient_user_id = $1`,
      [userId]
    );

    const currentBalance = parseFloat(balanceResult.rows[0].current_balance);

    res.json({
      currentBalance: currentBalance,
      totalEarned: currentBalance, // For now, same as current balance
    });
  } catch (error) {
    console.error('Error fetching FP balance:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// ============================================================================
// GET /api/finpoint/:userId/transactions
// Get FP transactions with pagination
// ============================================================================
router.get('/:userId/transactions', async (req, res) => {
  try {
    const { userId } = req.params;
    const { limit = 20, offset = 0, status } = req.query;

    let query = `
      SELECT
        id,
        simulated_tx_type,
        simulated_source_type,
        simulated_base_amount,
        simulated_generated_fp,
        simulated_self_fp,
        simulated_network_fp,
        simulated_status,
        created_at
      FROM simulated_fp_transactions
      WHERE user_id = $1
    `;

    const params = [userId];

    if (status) {
      query += ` AND simulated_status = $${params.length + 1}`;
      params.push(status);
    }

    query += ` ORDER BY created_at DESC LIMIT $${params.length + 1} OFFSET $${params.length + 2}`;
    params.push(parseInt(limit), parseInt(offset));

    const result = await pool.query(query, params);

    res.json({
      transactions: result.rows.map(row => ({
        id: row.id,
        type: row.simulated_tx_type,
        sourceType: row.simulated_source_type,
        baseAmount: parseFloat(row.simulated_base_amount),
        generatedFP: parseFloat(row.simulated_generated_fp),
        selfFP: parseFloat(row.simulated_self_fp),
        networkFP: parseFloat(row.simulated_network_fp),
        status: row.simulated_status,
        createdAt: row.created_at,
      })),
      pagination: {
        limit: parseInt(limit),
        offset: parseInt(offset),
      }
    });
  } catch (error) {
    console.error('Error fetching transactions:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// ============================================================================
// GET /api/finpoint/:userId/ledger
// Get FP ledger entries (recent activity feed)
// ============================================================================
router.get('/:userId/ledger', async (req, res) => {
  try {
    const { userId } = req.params;
    const { limit = 10 } = req.query;

    const result = await pool.query(
      `SELECT
        l.id,
        l.dr_cr,
        l.simulated_fp_amount,
        l.simulated_balance_after,
        l.simulated_tx_type,
        l.simulated_source_type,
        l.simulated_source_id,
        l.simulated_tx_datetime,
        l.level,
        t.simulated_tx_type as transaction_type
      FROM simulated_fp_ledger l
      LEFT JOIN simulated_fp_transactions t ON t.id = l.simulated_tx_id
      WHERE l.user_id = $1
      ORDER BY l.created_at DESC
      LIMIT $2`,
      [userId, parseInt(limit)]
    );

    res.json({
      ledger: result.rows.map(row => ({
        id: row.id,
        datetime: row.simulated_tx_datetime || row.created_at,
        category: getCategoryLabel(row.simulated_tx_type, row.simulated_source_type),
        detail: row.simulated_source_id || '-',
        drCr: row.dr_cr,
        amount: parseFloat(row.simulated_fp_amount),
        balanceAfter: parseFloat(row.simulated_balance_after),
        level: row.level,
      }))
    });
  } catch (error) {
    console.error('Error fetching ledger:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// ============================================================================
// GET /api/finpoint/:userId/today
// Get today's FP earnings breakdown
// ============================================================================
router.get('/:userId/today', async (req, res) => {
  try {
    const { userId } = req.params;

    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const result = await pool.query(
      `SELECT
        COALESCE(SUM(CASE WHEN dr_cr = 'DR' THEN simulated_fp_amount ELSE 0 END), 0) as total_earned,
        COALESCE(SUM(CASE
          WHEN dr_cr = 'DR' AND simulated_source_type LIKE '%secondhand%'
          THEN simulated_fp_amount ELSE 0 END), 0) as from_secondhand,
        COALESCE(SUM(CASE
          WHEN dr_cr = 'DR' AND level IS NOT NULL AND level > 0
          THEN simulated_fp_amount ELSE 0 END), 0) as from_upline
      FROM simulated_fp_ledger
      WHERE user_id = $1
        AND created_at >= $2`,
      [userId, today]
    );

    const row = result.rows[0] || {};

    res.json({
      todayEarned: parseFloat(row.total_earned || 0),
      todayFromSecondhand: parseFloat(row.from_secondhand || 0),
      todayFromUpline: parseFloat(row.from_upline || 0),
    });
  } catch (error) {
    console.error('Error fetching today earnings:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// ============================================================================
// Helper Functions
// ============================================================================

function getCategoryLabel(txType, sourceType) {
  if (sourceType && sourceType.includes('secondhand')) {
    return 'ขายของมือสอง';
  }
  if (sourceType && sourceType.includes('insurance')) {
    return 'ซื้อประกัน';
  }
  if (txType === 'NETWORK_BONUS') {
    return 'Network Bonus';
  }
  return txType || 'อื่นๆ';
}

module.exports = router;
