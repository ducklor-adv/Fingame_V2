/**
 * Insurance / Level Progress API Endpoints
 *
 * Endpoints:
 * - GET /api/insurance/:userId/levels
 * - POST /api/insurance/:userId/purchase
 * - POST /api/insurance/:userId/use-rights
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

// Level configuration
const LEVELS = {
  LEVEL_1: { label: 'Level 1 – พรบ.', target: 600, cost: 600 },
  LEVEL_2: { label: 'Level 2 – ประกันภัยรถ', target: 5000, cost: 5000 },
  LEVEL_3: { label: 'Level 3 – ประกันสุขภาพ', target: 20000, cost: 20000 },
  LEVEL_4: { label: 'Level 4 – ประกันชีวิต', target: 50000, cost: 50000 },
};

// ============================================================================
// GET /api/insurance/:userId/levels
// Get user's level progress
// ============================================================================
router.get('/:userId/levels', async (req, res) => {
  try {
    const { userId } = req.params;

    // Get user's FP spent on each level (from ledger)
    const result = await pool.query(
      `SELECT
        simulated_source_type,
        SUM(simulated_fp_amount) as total_spent
      FROM simulated_fp_ledger
      WHERE user_id = $1
        AND dr_cr = 'CR'
        AND simulated_source_type LIKE 'insurance_%'
      GROUP BY simulated_source_type`,
      [userId]
    );

    // Build progress map
    const progressMap = {};
    result.rows.forEach(row => {
      const levelMatch = row.simulated_source_type.match(/LEVEL_(\d+)/);
      if (levelMatch) {
        const levelCode = `LEVEL_${levelMatch[1]}`;
        progressMap[levelCode] = parseFloat(row.total_spent);
      }
    });

    // Build response
    const levels = Object.entries(LEVELS).map(([code, config]) => ({
      code,
      label: config.label,
      target: config.target,
      current: progressMap[code] || 0,
    }));

    res.json({ levels });
  } catch (error) {
    console.error('Error fetching level progress:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// ============================================================================
// POST /api/insurance/:userId/purchase
// Purchase insurance with FP
// ============================================================================
router.post('/:userId/purchase', async (req, res) => {
  const client = await pool.connect();

  try {
    const { userId } = req.params;
    const { levelCode } = req.body;

    if (!LEVELS[levelCode]) {
      return res.status(400).json({ error: 'Invalid level code' });
    }

    const level = LEVELS[levelCode];

    await client.query('BEGIN');

    // Check user's FP balance
    const userResult = await client.query(
      'SELECT own_finpoint FROM users WHERE id = $1 FOR UPDATE',
      [userId]
    );

    if (userResult.rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({ error: 'User not found' });
    }

    const currentBalance = parseFloat(userResult.rows[0].own_finpoint);

    if (currentBalance < level.cost) {
      await client.query('ROLLBACK');
      return res.status(400).json({
        error: 'Insufficient FP balance',
        required: level.cost,
        current: currentBalance,
      });
    }

    // Deduct FP
    const newBalance = currentBalance - level.cost;
    await client.query(
      'UPDATE users SET own_finpoint = $1 WHERE id = $2',
      [newBalance, userId]
    );

    // Create transaction
    const txResult = await client.query(
      `INSERT INTO simulated_fp_transactions (
        user_id,
        simulated_tx_type,
        simulated_source_type,
        simulated_base_amount,
        simulated_reverse_rate,
        simulated_generated_fp,
        simulated_status
      ) VALUES ($1, $2, $3, $4, $5, $6, $7)
      RETURNING id`,
      [
        userId,
        'PURCHASE',
        `insurance_${levelCode}`,
        level.cost,
        1.0,
        level.cost,
        'COMPLETED'
      ]
    );

    const txId = txResult.rows[0].id;

    // Create ledger entry
    await client.query(
      `INSERT INTO simulated_fp_ledger (
        simulated_tx_id,
        user_id,
        dr_cr,
        simulated_fp_amount,
        simulated_balance_after,
        simulated_tx_type,
        simulated_source_type,
        simulated_tx_datetime
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, NOW())`,
      [
        txId,
        userId,
        'CR',
        level.cost,
        newBalance,
        'PURCHASE',
        `insurance_${levelCode}`
      ]
    );

    await client.query('COMMIT');

    res.json({
      success: true,
      levelCode,
      amountSpent: level.cost,
      newBalance,
      transactionId: txId,
    });
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('Error purchasing insurance:', error);
    res.status(500).json({ error: 'Internal server error' });
  } finally {
    client.release();
  }
});

// ============================================================================
// POST /api/insurance/:userId/use-rights
// Use insurance rights (for levels already unlocked)
// ============================================================================
router.post('/:userId/use-rights', async (req, res) => {
  try {
    const { userId } = req.params;
    const { levelCode } = req.body;

    if (!LEVELS[levelCode]) {
      return res.status(400).json({ error: 'Invalid level code' });
    }

    // Check if user has reached target for this level
    const result = await pool.query(
      `SELECT SUM(simulated_fp_amount) as total_spent
       FROM simulated_fp_ledger
       WHERE user_id = $1
         AND dr_cr = 'CR'
         AND simulated_source_type = $2`,
      [userId, `insurance_${levelCode}`]
    );

    const totalSpent = parseFloat(result.rows[0]?.total_spent || 0);
    const level = LEVELS[levelCode];

    if (totalSpent < level.target) {
      return res.status(400).json({
        error: 'Level not unlocked yet',
        required: level.target,
        current: totalSpent,
      });
    }

    // TODO: Implement actual insurance rights usage logic
    // For now, just return success

    res.json({
      success: true,
      levelCode,
      message: 'Insurance rights used successfully',
    });
  } catch (error) {
    console.error('Error using insurance rights:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

module.exports = router;
