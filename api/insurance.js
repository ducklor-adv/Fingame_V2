/**
 * Insurance / Level Progress API Endpoints
 *
 * Endpoints:
 * - GET /api/insurance/:userId/levels
 * - POST /api/insurance/:userId/purchase
 * - POST /api/insurance/:userId/use-rights
 * - GET /api/insurance/products (get all products, optionally filtered by level)
 * - GET /api/insurance/products/:id (get specific product)
 * - GET /api/insurance/selections/:userId (get user's selections)
 * - POST /api/insurance/selections (create new selection)
 * - DELETE /api/insurance/selections/:selectionId (deactivate selection)
 * - PUT /api/insurance/selections/:selectionId/priority (update priority)
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

    // Get user's total FP balance from commission_pool_distribution
    const balanceResult = await pool.query(
      `SELECT COALESCE(SUM(amount), 0) as total_balance
       FROM commission_pool_distribution
       WHERE recipient_user_id = $1`,
      [userId]
    );

    const currentBalance = parseFloat(balanceResult.rows[0].total_balance);

    // Build response - show current balance for all levels
    const levels = Object.entries(LEVELS).map(([code, config]) => ({
      code,
      label: config.label,
      target: config.target,
      current: currentBalance, // Show total FP balance for all levels
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

// ============================================================================
// Insurance Products Endpoints
// ============================================================================

/**
 * GET /api/insurance/products
 * Get all active insurance products, optionally filtered by level
 */
router.get('/products', async (req, res) => {
  try {
    const { level, is_active = 'true' } = req.query;

    let query = `
      SELECT
        id, product_code, title, short_title, description,
        insurer_company_name, insurance_group, insurance_type,
        is_compulsory, vehicle_type, vehicle_usage,
        coverage_term_months, sum_insured_main, coverage_detail_json,
        currency_code, premium_total, premium_base,
        tax_vat_percent, tax_vat_amount, government_levy_amount, stamp_duty_amount,
        commission_percent, commission_to_fingrow_percent,
        commission_seller_percent, commission_pool_percent,
        commission_amount, commission_fingrow_amount,
        commission_seller_amount, commission_pool_amount,
        finpoint_price, finpoint_rate_per_100, finpoint_distribution_config, fingrow_level,
        cover_image_url, brochure_url, tags,
        is_active, is_featured, sort_order, effective_from, effective_to,
        created_at, updated_at
      FROM insurance_product
      WHERE deleted_at IS NULL
    `;

    const params = [];
    let paramIndex = 1;

    if (is_active === 'true') {
      query += ` AND is_active = $${paramIndex}`;
      params.push(true);
      paramIndex++;
    }

    if (level) {
      query += ` AND fingrow_level = $${paramIndex}`;
      params.push(parseInt(level));
      paramIndex++;
    }

    query += ` ORDER BY fingrow_level ASC, sort_order ASC, premium_total ASC`;

    const result = await pool.query(query, params);

    res.json({
      products: result.rows.map(row => ({
        id: row.id,
        productCode: row.product_code,
        title: row.title,
        shortTitle: row.short_title,
        description: row.description,
        insurerCompanyName: row.insurer_company_name,
        insuranceGroup: row.insurance_group,
        insuranceType: row.insurance_type,
        isCompulsory: row.is_compulsory,
        vehicleType: row.vehicle_type,
        vehicleUsage: row.vehicle_usage,
        coverageTermMonths: row.coverage_term_months,
        sumInsuredMain: row.sum_insured_main,
        coverageDetail: row.coverage_detail_json,
        currencyCode: row.currency_code,
        premiumTotal: row.premium_total,
        premiumBase: row.premium_base,
        taxVatPercent: row.tax_vat_percent,
        taxVatAmount: row.tax_vat_amount,
        governmentLevyAmount: row.government_levy_amount,
        stampDutyAmount: row.stamp_duty_amount,
        commissionPercent: row.commission_percent,
        commissionToFingrowPercent: row.commission_to_fingrow_percent,
        commissionSellerPercent: row.commission_seller_percent,
        commissionPoolPercent: row.commission_pool_percent,
        commissionAmount: row.commission_amount,
        commissionFingrowAmount: row.commission_fingrow_amount,
        commissionSellerAmount: row.commission_seller_amount,
        commissionPoolAmount: row.commission_pool_amount,
        finpointPrice: row.finpoint_price,
        finpointRatePer100: row.finpoint_rate_per_100,
        finpointDistributionConfig: row.finpoint_distribution_config,
        fingrowLevel: row.fingrow_level,
        coverImageUrl: row.cover_image_url,
        brochureUrl: row.brochure_url,
        tags: row.tags,
        isActive: row.is_active,
        isFeatured: row.is_featured,
        sortOrder: row.sort_order,
        effectiveFrom: row.effective_from,
        effectiveTo: row.effective_to,
        createdAt: row.created_at,
        updatedAt: row.updated_at
      }))
    });
  } catch (error) {
    console.error('Error fetching insurance products:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * GET /api/insurance/products/:id
 * Get a specific insurance product by ID
 */
router.get('/products/:id', async (req, res) => {
  try {
    const { id } = req.params;

    const result = await pool.query(
      `SELECT * FROM insurance_product WHERE id = $1 AND deleted_at IS NULL`,
      [id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Insurance product not found' });
    }

    const row = result.rows[0];
    res.json({
      id: row.id,
      productCode: row.product_code,
      title: row.title,
      shortTitle: row.short_title,
      description: row.description,
      insurerCompanyName: row.insurer_company_name,
      premiumTotal: row.premium_total,
      finpointRatePer100: row.finpoint_rate_per_100,
      fingrowLevel: row.fingrow_level,
      insuranceType: row.insurance_type,
      coverageDetail: row.coverage_detail_json,
      tags: row.tags
    });
  } catch (error) {
    console.error('Error fetching insurance product:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// ============================================================================
// User Insurance Selections Endpoints
// ============================================================================

/**
 * GET /api/insurance/selections/:userId
 * Get all active insurance selections for a user
 */
router.get('/selections/:userId', async (req, res) => {
  try {
    const { userId } = req.params;

    const result = await pool.query(
      `SELECT
        s.id, s.user_id, s.insurance_product_id,
        s.selected_at, s.is_active, s.priority, s.notes,
        s.created_at, s.updated_at, s.deactivated_at,
        p.product_code, p.title, p.short_title, p.fingrow_level,
        p.premium_total, p.finpoint_rate_per_100, p.insurance_type,
        p.insurer_company_name
      FROM user_insurance_selections s
      JOIN insurance_product p ON s.insurance_product_id = p.id
      WHERE s.user_id = $1 AND s.is_active = true
      ORDER BY p.fingrow_level ASC, s.priority ASC, s.selected_at DESC`,
      [userId]
    );

    res.json({
      selections: result.rows.map(row => ({
        id: row.id,
        userId: row.user_id,
        insuranceProductId: row.insurance_product_id,
        selectedAt: row.selected_at,
        isActive: row.is_active,
        priority: row.priority,
        notes: row.notes,
        product: {
          productCode: row.product_code,
          title: row.title,
          shortTitle: row.short_title,
          fingrowLevel: row.fingrow_level,
          premiumTotal: row.premium_total,
          finpointRatePer100: row.finpoint_rate_per_100,
          insuranceType: row.insurance_type,
          insurerCompanyName: row.insurer_company_name
        }
      }))
    });
  } catch (error) {
    console.error('Error fetching user insurance selections:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * POST /api/insurance/selections
 * Create a new insurance selection for a user
 */
router.post('/selections', async (req, res) => {
  try {
    const { userId, insuranceProductId, priority, notes } = req.body;

    if (!userId || !insuranceProductId) {
      return res.status(400).json({ error: 'userId and insuranceProductId are required' });
    }

    // Check if user exists
    const userCheck = await pool.query('SELECT id FROM users WHERE id = $1', [userId]);
    if (userCheck.rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }

    // Check if insurance product exists and is active
    const productCheck = await pool.query(
      'SELECT id, fingrow_level FROM insurance_product WHERE id = $1 AND is_active = true AND deleted_at IS NULL',
      [insuranceProductId]
    );
    if (productCheck.rows.length === 0) {
      return res.status(404).json({ error: 'Insurance product not found or not active' });
    }

    // Check if already selected (and active)
    const existingCheck = await pool.query(
      `SELECT id FROM user_insurance_selections
       WHERE user_id = $1 AND insurance_product_id = $2 AND is_active = true`,
      [userId, insuranceProductId]
    );

    if (existingCheck.rows.length > 0) {
      return res.status(409).json({ error: 'This insurance product is already selected' });
    }

    // Insert new selection
    const result = await pool.query(
      `INSERT INTO user_insurance_selections
       (user_id, insurance_product_id, priority, notes)
       VALUES ($1, $2, $3, $4)
       RETURNING *`,
      [userId, insuranceProductId, priority || 1, notes || null]
    );

    res.status(201).json({
      success: true,
      selection: {
        id: result.rows[0].id,
        userId: result.rows[0].user_id,
        insuranceProductId: result.rows[0].insurance_product_id,
        selectedAt: result.rows[0].selected_at,
        isActive: result.rows[0].is_active,
        priority: result.rows[0].priority,
        notes: result.rows[0].notes
      }
    });
  } catch (error) {
    console.error('Error creating insurance selection:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * DELETE /api/insurance/selections/:selectionId
 * Deactivate an insurance selection (soft delete)
 */
router.delete('/selections/:selectionId', async (req, res) => {
  try {
    const { selectionId } = req.params;

    const result = await pool.query(
      `UPDATE user_insurance_selections
       SET is_active = false
       WHERE id = $1 AND is_active = true
       RETURNING *`,
      [selectionId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Selection not found or already deactivated' });
    }

    res.json({
      success: true,
      message: 'Selection deactivated successfully',
      selection: {
        id: result.rows[0].id,
        isActive: result.rows[0].is_active,
        deactivatedAt: result.rows[0].deactivated_at
      }
    });
  } catch (error) {
    console.error('Error deactivating insurance selection:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * PUT /api/insurance/selections/:selectionId/priority
 * Update the priority of a selection
 */
router.put('/selections/:selectionId/priority', async (req, res) => {
  try {
    const { selectionId } = req.params;
    const { priority } = req.body;

    if (priority === undefined || priority === null) {
      return res.status(400).json({ error: 'priority is required' });
    }

    const result = await pool.query(
      `UPDATE user_insurance_selections
       SET priority = $1
       WHERE id = $2 AND is_active = true
       RETURNING *`,
      [priority, selectionId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Selection not found or not active' });
    }

    res.json({
      success: true,
      message: 'Priority updated successfully',
      selection: {
        id: result.rows[0].id,
        priority: result.rows[0].priority,
        updatedAt: result.rows[0].updated_at
      }
    });
  } catch (error) {
    console.error('Error updating selection priority:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * GET /api/insurance/:userId/purchased
 * Get list of insurance products that user has already purchased
 */
router.get('/:userId/purchased', async (req, res) => {
  try {
    const { userId } = req.params;

    const result = await pool.query(
      `SELECT DISTINCT insurance_product_id
       FROM insurance_orders
       WHERE user_id = $1 AND order_status = 'COMPLETED'`,
      [userId]
    );

    const purchasedProductIds = result.rows.map(row => row.insurance_product_id);

    res.json({
      userId,
      purchasedProductIds
    });
  } catch (error) {
    console.error('Error fetching purchased products:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * POST /api/insurance/purchase
 * Purchase insurance product using Finpoint from commission pool
 */
router.post('/purchase', async (req, res) => {
  const client = await pool.connect();

  try {
    const { userId, insuranceProductId } = req.body;
    console.log('🛒 Purchase request:', { userId, insuranceProductId });

    if (!userId || !insuranceProductId) {
      console.log('❌ Missing required fields');
      return res.status(400).json({ error: 'userId and insuranceProductId are required' });
    }

    await client.query('BEGIN');

    // Get user's current FP balance from commission_pool_distribution
    const balanceResult = await client.query(
      `SELECT COALESCE(SUM(amount), 0) as current_balance
       FROM commission_pool_distribution
       WHERE recipient_user_id = $1`,
      [userId]
    );

    const currentBalance = parseFloat(balanceResult.rows[0].current_balance);
    console.log('💰 Current FP balance:', currentBalance);

    // Get insurance product details including distribution config
    const productResult = await client.query(
      `SELECT id, title, short_title, finpoint_price, premium_total, fingrow_level,
              commission_percent, commission_amount, commission_fingrow_amount,
              commission_seller_amount, commission_pool_amount,
              finpoint_distribution_config
       FROM insurance_product
       WHERE id = $1 AND is_active = true AND deleted_at IS NULL`,
      [insuranceProductId]
    );

    console.log('📦 Product query result:', { found: productResult.rows.length, insuranceProductId });

    if (productResult.rows.length === 0) {
      await client.query('ROLLBACK');
      console.log('❌ Product not found or not active');
      return res.status(404).json({ error: 'Insurance product not found or not active' });
    }

    const product = productResult.rows[0];
    const finpointPrice = parseFloat(product.finpoint_price || product.premium_total);

    // Check if user has enough FP
    if (currentBalance < finpointPrice) {
      await client.query('ROLLBACK');
      return res.status(400).json({
        error: 'Insufficient Finpoint balance',
        required: finpointPrice,
        current: currentBalance,
        missing: finpointPrice - currentBalance
      });
    }

    // Generate order number
    const now = new Date();
    const dateStr = now.toISOString().slice(0, 10).replace(/-/g, '');
    const countResult = await client.query(
      `SELECT COUNT(*) as count FROM insurance_orders WHERE created_at >= CURRENT_DATE`
    );
    const orderCount = parseInt(countResult.rows[0].count) + 1;
    const orderNumber = `INS-${dateStr}-${orderCount.toString().padStart(4, '0')}`;

    // Create insurance order
    const orderResult = await client.query(
      `INSERT INTO insurance_orders (
        order_number,
        user_id,
        insurance_product_id,
        order_status,
        finpoint_spent,
        premium_amount,
        commission_rate,
        total_commission,
        management_fee,
        seller_commission,
        commission_pool,
        payment_method,
        created_at
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, NOW())
      RETURNING id, created_at`,
      [
        orderNumber,
        userId,
        insuranceProductId,
        'COMPLETED',
        finpointPrice,
        product.premium_total,
        product.commission_percent,
        product.commission_amount,
        product.commission_fingrow_amount,
        product.commission_seller_amount,
        product.commission_pool_amount,
        'finpoint'
      ]
    );

    const orderId = orderResult.rows[0].id;
    const orderDate = orderResult.rows[0].created_at;

    // Deduct FP from commission pool by creating negative entry
    await client.query(
      `INSERT INTO commission_pool_distribution (
        insurance_order_id,
        recipient_user_id,
        recipient_role,
        upline_level,
        share_portion,
        amount,
        distributed_at
      ) VALUES ($1, $2, $3, $4, $5, $6, NOW())`,
      [orderId, userId, 'finpoint_spent', null, 0, -finpointPrice]
    );

    // Distribute commission pool to upline and self
    const distributionConfig = product.finpoint_distribution_config || { levels: [40, 20, 15, 10, 7, 5, 3], self_bonus: 15 };
    const commissionPoolAmount = parseFloat(product.commission_pool_amount);

    // Get user's upline path
    const uplineResult = await client.query(
      `WITH RECURSIVE upline_path AS (
        SELECT id, parent_id, 1 as level
        FROM users
        WHERE id = $1
        UNION ALL
        SELECT u.id, u.parent_id, up.level + 1
        FROM users u
        INNER JOIN upline_path up ON u.id = up.parent_id
        WHERE up.level < 7
      )
      SELECT id, level FROM upline_path WHERE level > 1 ORDER BY level`,
      [userId]
    );

    const uplineUsers = uplineResult.rows;

    // Distribute to upline (7 levels)
    for (let i = 0; i < distributionConfig.levels.length; i++) {
      const uplineLevel = i + 1;
      const sharePercent = distributionConfig.levels[i];
      const shareAmount = (commissionPoolAmount * sharePercent) / 100;

      if (uplineUsers[i]) {
        // Has upline at this level - distribute to upline
        await client.query(
          `INSERT INTO commission_pool_distribution (
            insurance_order_id,
            recipient_user_id,
            recipient_role,
            upline_level,
            share_portion,
            amount,
            distributed_at
          ) VALUES ($1, $2, $3, $4, $5, $6, NOW())`,
          [orderId, uplineUsers[i].id, 'upline', uplineLevel, sharePercent, shareAmount]
        );
      }
      // If no upline at this level, the commission stays with Fingrow (no record created)
    }

    // Distribute self bonus back to buyer
    const selfBonusPercent = distributionConfig.self_bonus || 0;
    if (selfBonusPercent > 0) {
      const selfBonusAmount = (commissionPoolAmount * selfBonusPercent) / 100;
      await client.query(
        `INSERT INTO commission_pool_distribution (
          insurance_order_id,
          recipient_user_id,
          recipient_role,
          upline_level,
          share_portion,
          amount,
          distributed_at
        ) VALUES ($1, $2, $3, $4, $5, $6, NOW())`,
        [orderId, userId, 'self_bonus', null, selfBonusPercent, selfBonusAmount]
      );
    }

    await client.query('COMMIT');

    // Calculate new balance
    const newBalance = currentBalance - finpointPrice;

    console.log('✅ Purchase successful:', { orderId, finpointSpent: finpointPrice, newBalance });

    res.status(201).json({
      success: true,
      message: 'Insurance purchased successfully',
      data: {
        orderId: orderId,
        orderDate: orderDate,
        product: {
          id: product.id,
          title: product.short_title || product.title,
          level: product.fingrow_level
        },
        finpointSpent: finpointPrice,
        newBalance: newBalance
      }
    });
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('❌ Error purchasing insurance:', error);
    console.error('Error stack:', error.stack);
    res.status(500).json({ error: 'Internal server error', details: error.message });
  } finally {
    client.release();
  }
});

module.exports = router;
