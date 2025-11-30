/**
 * User Profile API Endpoints
 *
 * Endpoints:
 * - GET    /api/users/:id        - Get user profile by ID
 * - PATCH  /api/users/:id        - Update user profile
 * - GET    /api/users/world/:worldId - Get user by World ID
 * - GET    /api/users/username/:username - Get user by username
 */

const express = require('express');
const { Pool } = require('pg');

const router = express.Router();

// PostgreSQL connection
// Note: Docker container uses 'trust' authentication internally
// but 'md5' from external connections
const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  port: parseInt(process.env.DB_PORT) || 5432,
  database: process.env.DB_NAME || 'fingrow',
  user: process.env.DB_USER || 'fingrow_user',
  password: process.env.DB_PASSWORD || 'fingrow_pass_2025',
  // Add connection timeout
  connectionTimeoutMillis: 5000,
});

// ---------- Helper Functions ----------

/**
 * Convert database row to UserProfile object
 */
function mapUserProfile(row) {
  return {
    id: row.id,
    worldId: row.world_id,
    username: row.username,
    email: row.email,
    phone: row.phone,
    firstName: row.first_name,
    lastName: row.last_name,
    avatarUrl: row.avatar_url,
    profileImageFilename: row.profile_image_filename,
    bio: row.bio,
    location: row.location,
    preferredCurrency: row.preferred_currency,
    language: row.language,
    isVerified: row.is_verified,
    verificationLevel: row.verification_level,
    trustScore: parseFloat(row.trust_score),
    totalSales: row.total_sales,
    totalPurchases: row.total_purchases,
    estimatedInventoryValue: parseFloat(row.estimated_inventory_value),
    estimatedItemCount: row.estimated_item_count,

    // ACF Info
    runNumber: row.run_number,
    parentId: row.parent_id,
    childCount: row.child_count,
    maxChildren: row.max_children,
    acfAccepting: row.acf_accepting,
    inviterId: row.inviter_id,
    inviteCode: row.invite_code,
    level: row.level,
    userType: row.user_type,
    registType: row.regist_type,

    // Finpoint
    ownFinpoint: parseFloat(row.own_finpoint),
    totalFinpoint: parseFloat(row.total_finpoint),
    maxNetwork: row.max_network,

    // Status
    isActive: row.is_active,
    isSuspended: row.is_suspended,
    lastLogin: row.last_login,

    // Address
    addressNumber: row.address_number,
    addressStreet: row.address_street,
    addressDistrict: row.address_district,
    addressProvince: row.address_province,
    addressPostalCode: row.address_postal_code,

    // Metadata
    createdAt: parseInt(row.created_at),
    updatedAt: parseInt(row.updated_at),
  };
}

// ---------- API Endpoints ----------

/**
 * GET /api/users/:id
 * Get user profile by UUID
 */
router.get('/:id', async (req, res) => {
  try {
    const { id } = req.params;

    const result = await pool.query(
      'SELECT * FROM users WHERE id = $1',
      [id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }

    const profile = mapUserProfile(result.rows[0]);
    res.json(profile);
  } catch (error) {
    console.error('Error fetching user:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * GET /api/users/world/:worldId
 * Get user profile by World ID (e.g., 25AAA0001)
 */
router.get('/world/:worldId', async (req, res) => {
  try {
    const { worldId } = req.params;

    const result = await pool.query(
      'SELECT * FROM users WHERE world_id = $1',
      [worldId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }

    const profile = mapUserProfile(result.rows[0]);
    res.json(profile);
  } catch (error) {
    console.error('Error fetching user by world_id:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * GET /api/users/username/:username
 * Get user profile by username
 */
router.get('/username/:username', async (req, res) => {
  try {
    const { username } = req.params;

    const result = await pool.query(
      'SELECT * FROM users WHERE username = $1',
      [username]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }

    const profile = mapUserProfile(result.rows[0]);
    res.json(profile);
  } catch (error) {
    console.error('Error fetching user by username:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * PATCH /api/users/:id
 * Update user profile
 *
 * Allowed fields:
 * - firstName, lastName, email, phone
 * - bio, avatarUrl, profileImageFilename
 * - preferredCurrency, language
 * - addressNumber, addressStreet, addressDistrict, addressProvince, addressPostalCode
 */
router.patch('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const updates = req.body;

    // Allowed fields for update
    const allowedFields = [
      'firstName', 'lastName', 'email', 'phone',
      'bio', 'avatarUrl', 'profileImageFilename',
      'preferredCurrency', 'language',
      'addressNumber', 'addressStreet', 'addressDistrict',
      'addressProvince', 'addressPostalCode'
    ];

    // Map camelCase to snake_case
    const fieldMapping = {
      firstName: 'first_name',
      lastName: 'last_name',
      avatarUrl: 'avatar_url',
      profileImageFilename: 'profile_image_filename',
      preferredCurrency: 'preferred_currency',
      addressNumber: 'address_number',
      addressStreet: 'address_street',
      addressDistrict: 'address_district',
      addressProvince: 'address_province',
      addressPostalCode: 'address_postal_code',
    };

    const setClause = [];
    const values = [];
    let paramIndex = 1;

    for (const [key, value] of Object.entries(updates)) {
      if (allowedFields.includes(key)) {
        const dbField = fieldMapping[key] || key;
        setClause.push(`${dbField} = $${paramIndex}`);
        values.push(value);
        paramIndex++;
      }
    }

    if (setClause.length === 0) {
      return res.status(400).json({ error: 'No valid fields to update' });
    }

    // Add updated_at timestamp
    setClause.push(`updated_at = $${paramIndex}`);
    values.push(Date.now());
    paramIndex++;

    // Add ID for WHERE clause
    values.push(id);

    const query = `
      UPDATE users
      SET ${setClause.join(', ')}
      WHERE id = $${paramIndex}
      RETURNING *
    `;

    const result = await pool.query(query, values);

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }

    const profile = mapUserProfile(result.rows[0]);
    res.json(profile);
  } catch (error) {
    console.error('Error updating user:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * GET /api/users/:id/stats
 * Get user statistics (sales, purchases, network info)
 */
router.get('/:id/stats', async (req, res) => {
  try {
    const { id } = req.params;

    const result = await pool.query(
      `SELECT
        u.id,
        u.world_id,
        u.username,
        u.total_sales,
        u.total_purchases,
        u.trust_score,
        u.own_finpoint,
        u.total_finpoint,
        u.child_count,
        u.max_children,
        u.level,
        COUNT(DISTINCT r.referee_id) as total_referrals,
        COALESCE(SUM(e.amount_local), 0) as total_earnings
      FROM users u
      LEFT JOIN referrals r ON r.referrer_id = u.id
      LEFT JOIN earnings e ON e.user_id = u.id AND e.status = 'paid'
      WHERE u.id = $1
      GROUP BY u.id`,
      [id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }

    res.json(result.rows[0]);
  } catch (error) {
    console.error('Error fetching user stats:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * GET /api/users/:id/children
 * Get user's ACF children
 */
router.get('/:id/children', async (req, res) => {
  try {
    const { id } = req.params;

    const result = await pool.query(
      `SELECT
        id, world_id, username, run_number, level,
        child_count, max_children, acf_accepting,
        own_finpoint, total_finpoint, created_at
      FROM users
      WHERE parent_id = $1
      ORDER BY run_number`,
      [id]
    );

    res.json(result.rows.map(mapUserProfile));
  } catch (error) {
    console.error('Error fetching user children:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * GET /api/users/:id/upline
 * Get user's upline path (from user to root)
 */
router.get('/:id/upline', async (req, res) => {
  try {
    const { id } = req.params;

    const result = await pool.query(
      `WITH RECURSIVE upline_path AS (
        SELECT
          u.id, u.world_id, u.username, u.parent_id,
          0 as depth
        FROM users u
        WHERE u.id = $1

        UNION ALL

        SELECT
          u.id, u.world_id, u.username, u.parent_id,
          up.depth + 1
        FROM users u
        INNER JOIN upline_path up ON u.id = up.parent_id
        WHERE up.depth < 7
      )
      SELECT * FROM upline_path
      ORDER BY depth ASC`,
      [id]
    );

    res.json({
      uplinePath: result.rows.map(row => ({
        id: row.world_id,
        worldId: row.world_id,
        name: row.username,
      })),
    });
  } catch (error) {
    console.error('Error fetching upline path:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// ---------- Export ----------

module.exports = router;
