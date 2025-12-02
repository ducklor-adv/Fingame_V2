/**
 * Network API Endpoints
 *
 * Endpoints:
 * - GET /api/network/:userId/tree
 * - GET /api/network/:userId/summary
 * - GET /api/network/:userId/acf
 * - GET /api/network/:userId/upline
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
// GET /api/network/:userId/tree
// Get network tree structure (parent + children + grandchildren)
// ============================================================================
router.get('/:userId/tree', async (req, res) => {
  try {
    const { userId } = req.params;

    // Get root user
    const rootResult = await pool.query(
      `SELECT
        id, world_id, username, run_number, level,
        child_count, max_children, acf_accepting,
        profile_image_filename, avatar_url,
        parent_id
      FROM users
      WHERE id = $1`,
      [userId]
    );

    if (rootResult.rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }

    const root = rootResult.rows[0];

    // Get direct children (max 5)
    const childrenResult = await pool.query(
      `SELECT
        id, world_id, username, run_number, level,
        child_count, max_children, acf_accepting,
        profile_image_filename, avatar_url,
        created_at
      FROM users
      WHERE parent_id = $1
      ORDER BY created_at ASC
      LIMIT 5`,
      [userId]
    );

    const children = childrenResult.rows;

    // Get grandchildren for each child
    const childrenWithGrandchildren = await Promise.all(
      children.map(async (child) => {
        const grandchildrenResult = await pool.query(
          `SELECT
            id, world_id, username, run_number, level,
            child_count, max_children, acf_accepting,
            profile_image_filename, avatar_url,
            created_at
          FROM users
          WHERE parent_id = $1
          ORDER BY created_at ASC
          LIMIT 5`,
          [child.id]
        );

        return {
          ...mapTreeNode(child),
          children: grandchildrenResult.rows.map(mapTreeNode),
        };
      })
    );

    res.json({
      root: mapTreeNode(root),
      children: childrenWithGrandchildren,
    });
  } catch (error) {
    console.error('Error fetching network tree:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// ============================================================================
// GET /api/network/:userId/summary
// Get network summary statistics
// ============================================================================
router.get('/:userId/summary', async (req, res) => {
  try {
    const { userId } = req.params;

    // Get total network size using recursive CTE
    const networkSizeResult = await pool.query(
      `WITH RECURSIVE network_tree AS (
        SELECT id, parent_id, 1 as depth
        FROM users
        WHERE id = $1

        UNION ALL

        SELECT u.id, u.parent_id, nt.depth + 1
        FROM users u
        INNER JOIN network_tree nt ON u.parent_id = nt.id
        WHERE nt.depth < 7
      )
      SELECT COUNT(*) - 1 as network_size
      FROM network_tree`,
      [userId]
    );

    const networkSize = parseInt(networkSizeResult.rows[0].network_size);

    // Get user's direct children count
    const userResult = await pool.query(
      'SELECT child_count FROM users WHERE id = $1',
      [userId]
    );

    const childCount = userResult.rows[0]?.child_count || 0;

    res.json({
      networkSize,
      directChildren: childCount,
      maxDepth: 7,
    });
  } catch (error) {
    console.error('Error fetching network summary:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// ============================================================================
// GET /api/network/:userId/acf
// Get ACF network table (all descendants)
// ============================================================================
router.get('/:userId/acf', async (req, res) => {
  try {
    const { userId } = req.params;

    const result = await pool.query(
      `WITH RECURSIVE network_tree AS (
        SELECT
          u.id, u.world_id, u.username, u.parent_id,
          u.level, u.child_count, u.max_children, u.acf_accepting,
          u.run_number, u.created_at,
          0 as depth,
          ARRAY[u.run_number] as path
        FROM users u
        WHERE u.id = $1

        UNION ALL

        SELECT
          u.id, u.world_id, u.username, u.parent_id,
          u.level, u.child_count, u.max_children, u.acf_accepting,
          u.run_number, u.created_at,
          nt.depth + 1,
          nt.path || u.run_number
        FROM users u
        INNER JOIN network_tree nt ON u.parent_id = nt.id
        WHERE nt.depth < 7
      )
      SELECT * FROM network_tree
      ORDER BY path`,
      [userId]
    );

    // Get children and parent info for each node
    const nodesWithChildren = await Promise.all(
      result.rows.map(async (node) => {
        // Get parent username
        let parentUsername = null;
        if (node.parent_id) {
          const parentResult = await pool.query(
            'SELECT username FROM users WHERE id = $1',
            [node.parent_id]
          );
          parentUsername = parentResult.rows[0]?.username || null;
        }

        // Get inviter username and info
        let inviterId = null;
        let inviterUsername = null;
        const userInfoResult = await pool.query(
          'SELECT inviter_id FROM users WHERE id = $1',
          [node.id]
        );
        inviterId = userInfoResult.rows[0]?.inviter_id || null;

        if (inviterId) {
          const inviterResult = await pool.query(
            'SELECT username FROM users WHERE id = $1',
            [inviterId]
          );
          inviterUsername = inviterResult.rows[0]?.username || null;
        }

        // Get children (direct children only - level 1)
        const childrenResult = await pool.query(
          `SELECT world_id, username
           FROM users
           WHERE parent_id = $1
           ORDER BY created_at ASC
           LIMIT 5`,
          [node.id]
        );

        const children = childrenResult.rows.map(c => ({
          worldId: c.world_id,
          username: c.username
        }));
        const emptySlots = Math.max(0, 5 - children.length);

        // Calculate network size (all descendants within 5 branches, 7 levels)
        const networkSizeResult = await pool.query(
          `WITH RECURSIVE descendant_tree AS (
            SELECT id, 1 as depth, 1::bigint as branch_num
            FROM users
            WHERE id = $1

            UNION ALL

            SELECT u.id, dt.depth + 1,
                   CASE WHEN u.parent_id = $1 THEN
                     ROW_NUMBER() OVER (PARTITION BY u.parent_id ORDER BY u.created_at)::bigint
                   ELSE dt.branch_num
                   END as branch_num
            FROM users u
            INNER JOIN descendant_tree dt ON u.parent_id = dt.id
            WHERE dt.depth < 7 AND dt.branch_num <= 5
          )
          SELECT COUNT(*) - 1 as network_size
          FROM descendant_tree`,
          [node.id]
        );

        const networkSize = parseInt(networkSizeResult.rows[0]?.network_size || 0);

        return {
          id: node.id,
          userId: node.world_id,
          username: node.username,
          inviterId: inviterId,
          inviterUsername: inviterUsername,
          parentId: node.parent_id,
          parentUsername: parentUsername,
          level: node.level,
          networkSize: networkSize,
          maxChildren: 5, // Fixed value
          childCount: children.length,
          acfAccepting: node.acf_accepting,
          childrenLevel1: children,
          children: [
            ...children.map(c => c.worldId),
            ...Array(emptySlots).fill(null)
          ],
          createdAt: node.created_at,
        };
      })
    );

    res.json({
      nodes: nodesWithChildren,
    });
  } catch (error) {
    console.error('Error fetching ACF network:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// ============================================================================
// GET /api/network/:userId/upline
// Get upline path (from user to root)
// ============================================================================
router.get('/:userId/upline', async (req, res) => {
  try {
    const { userId } = req.params;

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
      [userId]
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
// Helper Functions
// ============================================================================

function mapTreeNode(row) {
  return {
    userDbId: row.id, // UUID for API calls
    userId: row.world_id,
    username: row.username,
    parentId: row.parent_id,
    childCount: row.child_count,
    maxChildren: row.max_children,
    acfAccepting: row.acf_accepting,
    avatarUrl: row.avatar_url,
    profileImageFilename: row.profile_image_filename,
    registTime: row.created_at,
  };
}

module.exports = router;
