/**
 * Database Viewer API
 * View database tables and data
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
// GET /api/database/tables
// List all tables
// ============================================================================
router.get('/tables', async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT
        table_name,
        (SELECT COUNT(*) FROM information_schema.columns WHERE table_name = t.table_name) as column_count
      FROM information_schema.tables t
      WHERE table_schema = 'public'
        AND table_type = 'BASE TABLE'
      ORDER BY table_name
    `);

    res.json({ tables: result.rows });
  } catch (error) {
    console.error('Error fetching tables:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// ============================================================================
// GET /api/database/tables/:tableName
// Get table data with pagination
// ============================================================================
router.get('/tables/:tableName', async (req, res) => {
  try {
    const { tableName } = req.params;
    const { limit = 50, offset = 0 } = req.query;

    // Validate table name (prevent SQL injection)
    const validTables = await pool.query(
      `SELECT table_name FROM information_schema.tables
       WHERE table_schema = 'public' AND table_name = $1`,
      [tableName]
    );

    if (validTables.rows.length === 0) {
      return res.status(404).json({ error: 'Table not found' });
    }

    // Get columns
    const columnsResult = await pool.query(
      `SELECT column_name, data_type
       FROM information_schema.columns
       WHERE table_name = $1
       ORDER BY ordinal_position`,
      [tableName]
    );

    // Get data
    const dataResult = await pool.query(
      `SELECT * FROM ${tableName} ORDER BY created_at DESC LIMIT $1 OFFSET $2`,
      [parseInt(limit), parseInt(offset)]
    );

    // Get total count
    const countResult = await pool.query(`SELECT COUNT(*) FROM ${tableName}`);

    res.json({
      tableName,
      columns: columnsResult.rows,
      data: dataResult.rows,
      total: parseInt(countResult.rows[0].count),
      limit: parseInt(limit),
      offset: parseInt(offset),
    });
  } catch (error) {
    console.error('Error fetching table data:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// ============================================================================
// GET /api/database/users/all
// Get all users (for quick overview)
// ============================================================================
router.get('/users/all', async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT
        world_id,
        username,
        first_name,
        last_name,
        email,
        phone,
        own_finpoint,
        child_count,
        level,
        is_verified,
        created_at
      FROM users
      ORDER BY created_at DESC
      LIMIT 100
    `);

    res.json({ users: result.rows });
  } catch (error) {
    console.error('Error fetching all users:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

module.exports = router;
