-- ============================================================================
-- Quick SQL Queries for Fingrow Database
-- ============================================================================

-- 1. ดูตารางทั้งหมด
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
ORDER BY table_name;

-- 2. ดู System Root User
SELECT id, world_id, username, run_number, level, child_count, max_children, acf_accepting
FROM users
WHERE world_id = '25AAA0000';

-- 3. ดู Users ทั้งหมด
SELECT id, world_id, username, run_number, level, child_count, own_finpoint, total_finpoint
FROM users
ORDER BY run_number;

-- 4. นับจำนวน Users
SELECT COUNT(*) as total_users FROM users;

-- 5. ดูตารางที่มีข้อมูล
SELECT
  schemaname,
  tablename,
  n_live_tup as row_count
FROM pg_stat_user_tables
WHERE schemaname = 'public'
ORDER BY n_live_tup DESC;

-- 6. ดู Products ทั้งหมด
SELECT id, title, price_local, currency_code, status, seller_id
FROM products
LIMIT 10;

-- 7. ดู Orders ทั้งหมด
SELECT id, order_number, buyer_id, seller_id, total_amount, status
FROM orders
LIMIT 10;

-- 8. ดู Simulated FP Transactions
SELECT
  id,
  user_id,
  simulated_tx_type,
  simulated_base_amount,
  simulated_generated_fp,
  simulated_self_fp,
  simulated_network_fp,
  simulated_status
FROM simulated_fp_transactions
LIMIT 10;

-- 9. ดู Simulated FP Ledger
SELECT
  id,
  user_id,
  simulated_tx_type,
  dr_cr,
  simulated_fp_amount,
  simulated_balance_after,
  level
FROM simulated_fp_ledger
ORDER BY created_at DESC
LIMIT 20;

-- 10. ดู Active Users with ACF info (using view)
SELECT * FROM v_active_users_acf LIMIT 10;

-- 11. ดู User Network Summary (using view)
SELECT * FROM v_user_network_summary LIMIT 10;

-- 12. ดู Simulated FP Summary (using view)
SELECT * FROM v_simulated_fp_summary LIMIT 10;

-- 13. สร้าง Test User
INSERT INTO users (
  world_id,
  username,
  run_number,
  parent_id,
  level,
  acf_accepting
) VALUES (
  '25AAA0001',
  'test_user_1',
  1,
  (SELECT id FROM users WHERE world_id = '25AAA0000'),
  1,
  TRUE
) RETURNING id, world_id, username, run_number, level;

-- 14. สร้าง Test Product
INSERT INTO products (
  seller_id,
  title,
  description,
  price_local,
  currency_code,
  quantity,
  status
) VALUES (
  (SELECT id FROM users WHERE world_id = '25AAA0000'),
  'Test iPhone 15 Pro Max',
  'มือสอง สภาพดีมาก ใช้งานไม่ถึง 6 เดือน',
  35000.00,
  'THB',
  1,
  'active'
) RETURNING id, title, price_local;

-- 15. สร้าง Test Simulated Transaction
INSERT INTO simulated_fp_transactions (
  user_id,
  simulated_tx_type,
  simulated_source_type,
  simulated_base_amount,
  simulated_reverse_rate,
  simulated_generated_fp,
  simulated_self_fp,
  simulated_network_fp,
  simulated_system_cut_fp
) VALUES (
  (SELECT id FROM users WHERE world_id = '25AAA0000'),
  'SECONDHAND_SALE',
  'SIM_SECONDHAND_SALE',
  10000.00,
  0.07,
  700.00,
  315.00,
  315.00,
  70.00
) RETURNING id, simulated_tx_type, simulated_generated_fp, simulated_status;

-- ============================================================================
-- USEFUL ADMIN QUERIES
-- ============================================================================

-- ดูขนาดของแต่ละตาราง
SELECT
  schemaname,
  tablename,
  pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;

-- ดู Indexes ทั้งหมด
SELECT
  tablename,
  indexname,
  indexdef
FROM pg_indexes
WHERE schemaname = 'public'
ORDER BY tablename, indexname;

-- ดู Foreign Keys
SELECT
  tc.table_name,
  kcu.column_name,
  ccu.table_name AS foreign_table_name,
  ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
  ON tc.constraint_name = kcu.constraint_name
  AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
  ON ccu.constraint_name = tc.constraint_name
  AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY'
  AND tc.table_schema = 'public'
ORDER BY tc.table_name, kcu.column_name;
