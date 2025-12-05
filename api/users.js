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
const multer = require('multer');
const path = require('path');
const fs = require('fs');

const router = express.Router();

// Configure multer for file uploads
const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    const uploadDir = path.join(__dirname, '..', 'uploads', 'profiles');
    // Create directory if it doesn't exist
    if (!fs.existsSync(uploadDir)) {
      fs.mkdirSync(uploadDir, { recursive: true });
    }
    cb(null, uploadDir);
  },
  filename: function (req, file, cb) {
    // Generate unique filename: userId_timestamp.ext
    const userId = req.params.id;
    const timestamp = Date.now();
    const ext = path.extname(file.originalname);
    cb(null, `${userId}_${timestamp}${ext}`);
  }
});

const upload = multer({
  storage: storage,
  limits: {
    fileSize: 5 * 1024 * 1024 // 5MB limit
  },
  fileFilter: function (req, file, cb) {
    // Accept images only
    const allowedTypes = /jpeg|jpg|png|gif|webp/;
    const extname = allowedTypes.test(path.extname(file.originalname).toLowerCase());
    const mimetype = allowedTypes.test(file.mimetype);

    if (mimetype && extname) {
      return cb(null, true);
    } else {
      cb(new Error('Only image files are allowed (jpeg, jpg, png, gif, webp)'));
    }
  }
});

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
  // Support different DB naming: some schemas use "invitor_id" and "full_name".
  // Build inviter object from whichever alias is present (inviter_* or invitor_*).
  const inviterId = row.inviter_id || row.invitor_id || null;
  const inviterUsername = row.inviter_username || row.invitor_username || null;
  // for name fields support first_name/last_name and full_name
  const inviterFullName = row.inviter_full_name || row.invitor_full_name || null;
  const inviterFirstName = row.inviter_first_name || row.invitor_first_name || null;
  const inviterLastName = row.inviter_last_name || row.invitor_last_name || null;

  const inviter = inviterId ? {
    id: inviterId,
    username: inviterUsername,
    firstName: inviterFirstName,
    lastName: inviterLastName,
    fullName: inviterFullName || (inviterFirstName || inviterLastName ? `${inviterFirstName || ''} ${inviterLastName || ''}`.trim() : null),
    worldId: row.inviter_world_id || row.invitor_world_id || null,
  } : null;

  const parentId = row.parent_id || null;
  const parentUsername = row.parent_username || null;
  const parentFullName = row.parent_full_name || null;
  const parentFirstName = row.parent_first_name || null;
  const parentLastName = row.parent_last_name || null;

  const parent = parentId ? {
    id: parentId,
    username: parentUsername,
    firstName: parentFirstName,
    lastName: parentLastName,
    fullName: parentFullName || (parentFirstName || parentLastName ? `${parentFirstName || ''} ${parentLastName || ''}`.trim() : null),
    worldId: row.parent_world_id || null,
  } : null;

  return {
    id: row.id,
    worldId: row.world_id,
    username: row.username,
    email: row.email,
    phone: row.phone,
    // Prefer separate name fields, fall back to `full_name` if present (some DBs use full_name)
    firstName: row.first_name || (row.full_name ? row.full_name.split(' ')[0] : null),
    lastName: row.last_name || (row.full_name ? row.full_name.split(' ').slice(1).join(' ') : null),
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
    parentId: row.parent_id || null,
    parent,
    childCount: row.child_count,
    maxChildren: row.max_children,
    acfAccepting: row.acf_accepting,
    // Keep backwards-compatible fields
    inviterId: row.inviter_id || row.invitor_id || null,
    invitorId: row.invitor_id || null,
    // backwards-compatible top-level convenience fields
    inviterUsername: inviterUsername || null,
    parentUsername: parentUsername || null,
    inviter,
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

// Generate a unique invite code (6-10 chars) based on username when possible
const INVITE_CODE_MAX_ATTEMPTS = 50;
async function generateUniqueInviteCode(username) {
  const prefix = (username || 'INVITE')
    .replace(/[^a-zA-Z0-9]/g, '')
    .toUpperCase()
    .slice(0, 6) || 'INVITE';

  for (let attempt = 0; attempt < INVITE_CODE_MAX_ATTEMPTS; attempt++) {
    const randomSuffix = Math.random().toString(36).replace(/[^a-z0-9]/g, '').toUpperCase().slice(0, 4 + (attempt % 2));
    const candidate = `${prefix}${randomSuffix}`.slice(0, 10); // keep within 10 chars

    const existing = await pool.query(
      'SELECT 1 FROM users WHERE invite_code = $1',
      [candidate]
    );

    if (existing.rows.length === 0) {
      return candidate;
    }
  }

  throw new Error('Failed to generate unique invite code after multiple attempts');
}

// Ensure invite_code exists for a given user row (used for legacy rows)
async function ensureInviteCode(userRow) {
  if (!userRow || userRow.invite_code) {
    return userRow;
  }

  const newInviteCode = await generateUniqueInviteCode(userRow.username || userRow.world_id);
  const updated = await pool.query(
    'UPDATE users SET invite_code = $1 WHERE id = $2 RETURNING *',
    [newInviteCode, userRow.id]
  );

  return updated.rows[0];
}

// Base SELECT that joins inviter and parent users so endpoints can return human-friendly inviter/parent fields
const baseUserSelect = `
  SELECT u.*,
    -- support both spellings
    i.id AS invitor_id, i.username AS invitor_username,
    i.id AS inviter_id, i.username AS inviter_username,
    p.id AS parent_id, p.username AS parent_username
  FROM users u
  LEFT JOIN users i ON i.id = u.inviter_id
  LEFT JOIN users p ON p.id = u.parent_id
`;

// ---------- API Endpoints ----------

/**
 * GET /api/users/:id
 * Get user profile by UUID
 */
router.get('/:id', async (req, res) => {
  try {
    const { id } = req.params;

    const result = await pool.query(
      `${baseUserSelect} WHERE u.id = $1`,
      [id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }

    const ensured = await ensureInviteCode(result.rows[0]);
    const profile = mapUserProfile(ensured);
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
      `${baseUserSelect} WHERE u.world_id = $1`,
      [worldId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }

    const ensured = await ensureInviteCode(result.rows[0]);
    const profile = mapUserProfile(ensured);
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
      `${baseUserSelect} WHERE u.username = $1`,
      [username]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }

    const ensured = await ensureInviteCode(result.rows[0]);
    const profile = mapUserProfile(ensured);
    res.json(profile);
  } catch (error) {
    console.error('Error fetching user by username:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * GET /api/users/referral/:code
 * Get user by referral code (invite_code only; case-insensitive)
 */
router.get('/referral/:code', async (req, res) => {
  try {
    const referralCode = (req.params.code || '').trim();

    if (!referralCode) {
      return res.status(400).json({ error: 'Referral code is required' });
    }

    const result = await pool.query(
      `${baseUserSelect}
       WHERE UPPER(u.invite_code) = UPPER($1)
       LIMIT 1`,
      [referralCode]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }

    const ensured = await ensureInviteCode(result.rows[0]);
    const profile = mapUserProfile(ensured);
    res.json(profile);
  } catch (error) {
    console.error('Error fetching user by referral code:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * POST /api/users/google-signin
 * Register or login with Google
 */
router.post('/google-signin', async (req, res) => {
  try {
    const { googleId, email, firstName, lastName, avatarUrl, referralCode } = req.body;

    if (!googleId || !email) {
      return res.status(400).json({ error: 'Missing required fields: googleId and email' });
    }

    // Check if user already exists by email
    const existingUser = await pool.query(
      `${baseUserSelect} WHERE u.email = $1`,
      [email]
    );

    if (existingUser.rows.length > 0) {
      // User exists, ensure invite_code present before return
      const ensuredUser = await ensureInviteCode(existingUser.rows[0]);
      const refreshed = await pool.query(
        `${baseUserSelect} WHERE u.id = $1`,
        [ensuredUser.id]
      );
      const profile = mapUserProfile(refreshed.rows[0]);
      return res.json(profile);
    }

    // Generate unique World ID
    const generateWorldId = async () => {
      const year = new Date().getFullYear().toString().slice(-2);
      let attempts = 0;
      const maxAttempts = 100;

      while (attempts < maxAttempts) {
        const random = Math.random().toString(36).substring(2, 6).toUpperCase();
        const worldId = `${year}${random}`;

        // Check if World ID already exists
        const checkResult = await pool.query(
          'SELECT id FROM users WHERE world_id = $1',
          [worldId]
        );

        if (checkResult.rows.length === 0) {
          return worldId;
        }

        attempts++;
      }

      throw new Error('Failed to generate unique World ID');
    };

    const worldId = await generateWorldId();

    // Generate username from email (before @)
    const baseUsername = email.split('@')[0].toLowerCase().replace(/[^a-z0-9_]/g, '_');
    let username = baseUsername;
    let usernameAttempt = 1;

    // Ensure username is unique
    while (true) {
      const checkUsername = await pool.query(
        'SELECT id FROM users WHERE username = $1',
        [username]
      );

      if (checkUsername.rows.length === 0) {
        break;
      }

      username = `${baseUsername}${usernameAttempt}`;
      usernameAttempt++;
    }

    // Generate invite code for this new user
    const inviteCode = await generateUniqueInviteCode(username);

    // Determine inviter: use referralCode if provided, otherwise System Root
    let inviterId;
    if (referralCode) {
      // Find inviter by invite_code (strict)
      const inviterResult = await pool.query(
        `SELECT id FROM users
         WHERE UPPER(invite_code) = UPPER($1)
         LIMIT 1`,
        [referralCode]
      );

      if (inviterResult.rows.length === 0) {
        return res.status(400).json({
          error: `รหัสแนะนำไม่ถูกต้อง: ${referralCode}`,
          message: 'ไม่พบรหัสแนะนำในระบบ กรุณาตรวจสอบและลองใหม่อีกครั้ง'
        });
      }

      inviterId = inviterResult.rows[0].id;
    } else {
      // Use System Root as default inviter
      const systemRootResult = await pool.query(
        'SELECT id FROM users WHERE world_id = $1',
        ['25AAA0000']
      );

      if (systemRootResult.rows.length === 0) {
        throw new Error('System Root user not found. Please ensure 25AAA0000 exists.');
      }

      inviterId = systemRootResult.rows[0].id;
    }

    // Get next run_number
    const runNumberResult = await pool.query(
      'SELECT COALESCE(MAX(run_number), 0) + 1 as next_run_number FROM users'
    );
    const runNumber = runNumberResult.rows[0].next_run_number;

    // Find best parent using ACF placement function
    const placementResult = await pool.query(
      'SELECT find_next_acf_parent($1) as parent_id',
      [inviterId] // Start searching from inviter's network
    );
    const parentId = placementResult.rows[0].parent_id;

    // Create new user with inviter and ACF parent
    const nowTimestamp = Date.now(); // BIGINT for created_at, updated_at
    const nowDate = new Date(); // TIMESTAMP for last_login
    const insertResult = await pool.query(
      `INSERT INTO users (
        world_id, username, email, first_name, last_name, avatar_url,
        regist_type, user_type, level, run_number,
        inviter_id, parent_id, invite_code,
        is_active, is_verified, verification_level, trust_score,
        own_finpoint, total_finpoint, max_network,
        child_count, max_children, acf_accepting,
        total_sales, total_purchases,
        estimated_inventory_value, estimated_item_count,
        created_at, updated_at, last_login
      ) VALUES (
        $1, $2, $3, $4, $5, $6,
        'google', 'member', 1, $7,
        $8, $9, $10,
        true, true, 1, 50.0,
        0, 0, 7,
        0, 5, true,
        0, 0,
        0, 0,
        $11, $12, $13
      ) RETURNING *`,
      [worldId, username, email, firstName || 'User', lastName || '', avatarUrl, runNumber, inviterId, parentId, inviteCode, nowTimestamp, nowTimestamp, nowDate]
    );

    // Update parent's child_count
    if (parentId) {
      await pool.query(
        'UPDATE users SET child_count = child_count + 1 WHERE id = $1',
        [parentId]
      );
    }

    // Fetch the created user with joined data
    const result = await pool.query(
      `${baseUserSelect} WHERE u.id = $1`,
      [insertResult.rows[0].id]
    );

    const profile = mapUserProfile(result.rows[0]);
    res.status(201).json(profile);
  } catch (error) {
    console.error('Error in Google Sign-In:', error);
    res.status(500).json({ error: 'Internal server error: ' + error.message });
  }
});

/**
 * POST /api/users/:id/upload-avatar
 * Upload profile avatar image
 */
router.post('/:id/upload-avatar', upload.single('avatar'), async (req, res) => {
  try {
    const { id } = req.params;

    if (!req.file) {
      return res.status(400).json({ error: 'No file uploaded' });
    }

    // Get the file path relative to server root
    const filename = req.file.filename;
    const avatarUrl = `/uploads/profiles/${filename}`;

    // Delete old profile image if exists
    const userResult = await pool.query(
      'SELECT profile_image_filename FROM users WHERE id = $1',
      [id]
    );

    if (userResult.rows.length > 0 && userResult.rows[0].profile_image_filename) {
      const oldFilePath = path.join(__dirname, '..', 'uploads', 'profiles', userResult.rows[0].profile_image_filename);
      if (fs.existsSync(oldFilePath)) {
        fs.unlinkSync(oldFilePath);
      }
    }

    // Update user profile with new avatar
    const result = await pool.query(
      `UPDATE users
       SET avatar_url = $1,
           profile_image_filename = $2
       WHERE id = $3
       RETURNING *`,
      [avatarUrl, filename, id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }

    const profile = mapUserProfile(result.rows[0]);
    res.json({
      message: 'Avatar uploaded successfully',
      avatarUrl,
      profile
    });
  } catch (error) {
    console.error('Error uploading avatar:', error);
    res.status(500).json({ error: error.message || 'Internal server error' });
  }
});

// Notifications derived from user relations (signup/ACF placement)
router.get('/:id/notifications', async (req, res) => {
  try {
    const { id } = req.params;

    // Fetch recent users where requester is inviter or parent
    const result = await pool.query(
      `
      SELECT
        child.id,
        child.first_name, child.last_name, child.username, child.created_at,
        child.inviter_id, child.parent_id,
        inv.first_name AS inviter_first_name, inv.last_name AS inviter_last_name, inv.username AS inviter_username,
        par.first_name AS parent_first_name, par.last_name AS parent_last_name, par.username AS parent_username
      FROM users child
      LEFT JOIN users inv ON inv.id = child.inviter_id
      LEFT JOIN users par ON par.id = child.parent_id
      WHERE child.inviter_id = $1
         OR child.parent_id = $1
      ORDER BY child.created_at DESC
      LIMIT 50
      `,
      [id]
    );

    // Fetch recent finpoint distributions to this user (cast to text for compatibility)
    const fpResult = await pool.query(
      `
      SELECT
        d.insurance_order_id as order_id,
        d.amount,
        d.recipient_role,
        d.upline_level,
        d.distributed_at,
        d.transaction_type,
        d.description,
        io.user_id AS buyer_id,
        buyer.first_name AS buyer_first_name,
        buyer.last_name AS buyer_last_name,
        buyer.username AS buyer_username,
        prod.fingrow_level AS product_level
      FROM commission_pool_distribution d
      LEFT JOIN insurance_orders io ON io.id = d.insurance_order_id
      LEFT JOIN users buyer ON buyer.id = io.user_id
      LEFT JOIN insurance_product prod ON prod.id = io.insurance_product_id
      WHERE CAST(d.recipient_user_id AS TEXT) = $1::text
        AND d.amount > 0
      ORDER BY d.distributed_at DESC
      LIMIT 50
      `,
      [id]
    );

    const formatName = (first, last, username) => {
      if (first || last) {
        return `${first || ''} ${last || ''}`.trim();
      }
      return username || 'ไม่ทราบชื่อ';
    };

    const signupNotifications = result.rows.map(row => {
      const childName = formatName(row.first_name, row.last_name, row.username);
      const inviterName = formatName(row.inviter_first_name, row.inviter_last_name, row.inviter_username);
      const parentName = formatName(row.parent_first_name, row.parent_last_name, row.parent_username);
      const createdAt = parseInt(row.created_at);

      // Case 1: came via this user's invite_code
      if (row.inviter_id === id) {
        if (row.parent_id === id) {
          return {
            id: `invite-${row.id}`,
            type: 'invite_direct',
            message: `${childName} ได้สมัครโดยรหัสของคุณ โดยมีคุณเป็น Parent`,
            createdAt
          };
        } else {
          return {
            id: `invite-${row.id}`,
            type: 'invite_reroute',
            message: `${childName} ได้สมัครโดยรหัสของคุณ แต่ระบบ ACF จัดไปให้ ${parentName} ในสายงานของคุณ`,
            createdAt
          };
        }
      }

      // Case 2: received as child via ACF (parent = user, inviter someone else)
      if (row.parent_id === id && row.inviter_id !== id) {
        return {
          id: `acfchild-${row.id}`,
          type: 'acf_child',
          message: `คุณได้รับ Child ${childName} จากระบบ ACF โดยมี ${inviterName} เป็นผู้แนะนำ`,
          createdAt
        };
      }

      return null;
    }).filter(Boolean);

    const finpointNotifications = fpResult.rows.map(row => {
      const createdAt = row.distributed_at ? new Date(row.distributed_at).getTime() : Date.now();
      const amount = parseFloat(row.amount) || 0;

      // Demo finpoint (no order, transaction_type = demo)
      if (row.transaction_type === 'demo' || row.recipient_role === 'demo_purchase' || !row.order_id) {
        return {
          id: `fp-demo-${createdAt}-${amount}`,
          type: 'finpoint_demo',
          message: `ระบบเติม Finpoint จำนวน ${amount} สำเร็จแล้ว`,
          createdAt
        };
      }

      const buyerName = formatName(row.buyer_first_name, row.buyer_last_name, row.buyer_username);
      const level = row.product_level || '-';
      return {
        id: `fp-${row.order_id || 'none'}-${createdAt}-${amount}`,
        type: 'finpoint_gain',
        message: `คุณได้รับ ${amount} FP จากระบบ จาก ${buyerName} ซื้อประกัน Level ${level}`,
        createdAt
      };
    });

    const notifications = [...signupNotifications, ...finpointNotifications]
      .sort((a, b) => b.createdAt - a.createdAt)
      .slice(0, 100);

    res.json({ notifications });
  } catch (error) {
    console.error('Error fetching notifications:', error);
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

// ============================================================================
// GET /api/users/:id/upline-list
// Get upline list with details (from upline_id field)
// ============================================================================
router.get('/:id/upline-list', async (req, res) => {
  try {
    const { id } = req.params;

    // Get user's upline_id field
    const userResult = await pool.query(
      'SELECT upline_id FROM users WHERE id = $1',
      [id]
    );

    if (userResult.rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }

    const uplineIds = userResult.rows[0].upline_id;

    // If no upline, return empty array
    if (!uplineIds || uplineIds.length === 0) {
      return res.json({ uplines: [] });
    }

    // Fetch upline details
    const uplineResult = await pool.query(
      `SELECT id, world_id, username, level
       FROM users
       WHERE id = ANY($1::uuid[])
       ORDER BY level ASC`,
      [uplineIds]
    );

    // Map to response format maintaining order from upline_id
    const uplineMap = {};
    uplineResult.rows.forEach(row => {
      uplineMap[row.id] = {
        id: row.id,
        worldId: row.world_id,
        username: row.username,
        level: row.level
      };
    });

    // Maintain order from upline_id array
    const uplines = uplineIds
      .map(id => uplineMap[id])
      .filter(upline => upline); // Filter out any null values

    res.json({ uplines });
  } catch (error) {
    console.error('Error fetching upline list:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// ---------- Export ----------

module.exports = router;
