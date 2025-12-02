/**
 * Fingrow API Server
 *
 * Express server with PostgreSQL integration
 */

const express = require('express');
const cors = require('cors');
const morgan = require('morgan');
require('dotenv').config();

const usersRouter = require('./api/users');
const finpointRouter = require('./api/finpoint');
const networkRouter = require('./api/network');
const insuranceRouter = require('./api/insurance');
const databaseRouter = require('./api/database');
const commissionPoolRouter = require('./api/commissionPoolRoutes');

const app = express();
const PORT = process.env.PORT || 3001;

// ---------- Middleware ----------

app.use(cors());
app.use(express.json());
app.use(morgan('dev'));

// Serve static files (HTML, CSS, JS) from dist folder (for production build)
app.use(express.static('dist'));
// Also serve from current directory (for development)
app.use(express.static('.'));

// Serve HTML file on root path for direct access
app.get('/fingrow-app-mobile', (req, res) => {
  res.sendFile(__dirname + '/fingrow-app-mobile.html');
});

// ---------- Routes ----------

app.get('/', (req, res) => {
  res.json({
    name: 'Fingrow API',
    version: '2.0.0',
    status: 'Production Ready',
    endpoints: {
      users: {
        'GET /api/users/:id': 'Get user profile by UUID',
        'GET /api/users/world/:worldId': 'Get user by World ID',
        'GET /api/users/username/:username': 'Get user by username',
        'PATCH /api/users/:id': 'Update user profile',
        'GET /api/users/:id/stats': 'Get user statistics',
        'GET /api/users/:id/children': 'Get user ACF children',
        'GET /api/users/:id/upline': 'Get user upline path'
      },
      finpoint: {
        'GET /api/finpoint/:userId/balance': 'Get FP balance',
        'GET /api/finpoint/:userId/transactions': 'Get FP transactions',
        'GET /api/finpoint/:userId/ledger': 'Get FP ledger',
        'GET /api/finpoint/:userId/today': 'Get today earnings'
      },
      network: {
        'GET /api/network/:userId/tree': 'Get network tree',
        'GET /api/network/:userId/summary': 'Get network summary',
        'GET /api/network/:userId/acf': 'Get ACF network table',
        'GET /api/network/:userId/upline': 'Get upline path'
      },
      insurance: {
        'GET /api/insurance/:userId/levels': 'Get level progress',
        'POST /api/insurance/:userId/purchase': 'Purchase insurance',
        'POST /api/insurance/:userId/use-rights': 'Use insurance rights',
        'GET /api/insurance/products': 'Get all insurance products (optionally filtered by level)',
        'GET /api/insurance/products/:id': 'Get specific insurance product',
        'GET /api/insurance/selections/:userId': 'Get user insurance selections',
        'POST /api/insurance/selections': 'Create new insurance selection',
        'DELETE /api/insurance/selections/:selectionId': 'Deactivate insurance selection',
        'PUT /api/insurance/selections/:selectionId/priority': 'Update selection priority'
      },
      database: {
        'GET /api/database/tables': 'List all tables',
        'GET /api/database/tables/:tableName': 'View table data',
        'GET /api/database/users/all': 'Get all users overview'
      }
    }
  });
});

// API routes
app.use('/api/users', usersRouter);
app.use('/api/finpoint', finpointRouter);
app.use('/api/network', networkRouter);
app.use('/api/insurance', insuranceRouter);
app.use('/api/database', databaseRouter);
app.use('/api', commissionPoolRouter); // Commission Pool routes

// ---------- Error Handling ----------

app.use((req, res) => {
  res.status(404).json({ error: 'Not found' });
});

app.use((err, req, res, next) => {
  console.error('Unhandled error:', err);
  res.status(500).json({ error: 'Internal server error' });
});

// ---------- Start Server ----------

app.listen(PORT, () => {
  console.log(`\n${'='.repeat(60)}`);
  console.log(`🚀 Fingrow API Server v2.0 - Production Ready`);
  console.log(`${'='.repeat(60)}`);
  console.log(`📡 Server:     http://localhost:${PORT}`);
  console.log(`🗄️  Database:   ${process.env.DB_NAME || 'fingame'}`);
  console.log(`🔗 PostgreSQL: ${process.env.DB_HOST || 'localhost'}:${process.env.DB_PORT || 5433}`);
  console.log(`⚡ Environment: ${process.env.NODE_ENV || 'development'}`);
  console.log(`${'='.repeat(60)}\n`);
});

module.exports = app;
