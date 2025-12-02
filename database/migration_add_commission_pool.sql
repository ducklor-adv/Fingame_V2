-- ===================================================
-- Migration: Add Commission Pool System
-- ===================================================
-- วันที่: 2025-12-02
-- คำอธิบาย: เพิ่มตารางและ functions สำหรับระบบ Commission Pool Distribution

-- เริ่ม Transaction
BEGIN;

-- 1. สร้างตาราง orders (ถ้ายังไม่มี)
CREATE TABLE IF NOT EXISTS orders (
    order_id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(user_id),
    insurance_product_id INTEGER NOT NULL,
    premium_amount DECIMAL(12, 2) NOT NULL,
    commission_rate DECIMAL(5, 4) NOT NULL,
    total_commission DECIMAL(12, 2) NOT NULL,
    management_fee DECIMAL(12, 2) NOT NULL,
    seller_commission DECIMAL(12, 2) NOT NULL,
    commission_pool DECIMAL(12, 2) NOT NULL,
    order_status VARCHAR(50) DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. สร้างตาราง commission_pool_distribution
CREATE TABLE IF NOT EXISTS commission_pool_distribution (
    distribution_id SERIAL PRIMARY KEY,
    order_id INTEGER NOT NULL REFERENCES orders(order_id) ON DELETE CASCADE,
    recipient_user_id INTEGER NOT NULL REFERENCES users(user_id),
    recipient_role VARCHAR(20) NOT NULL,
    upline_level INTEGER,
    share_portion DECIMAL(5, 4) NOT NULL,
    amount DECIMAL(12, 2) NOT NULL,
    distributed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 3. สร้าง Indexes
CREATE INDEX IF NOT EXISTS idx_cpd_recipient_user ON commission_pool_distribution(recipient_user_id);
CREATE INDEX IF NOT EXISTS idx_cpd_order ON commission_pool_distribution(order_id);
CREATE INDEX IF NOT EXISTS idx_cpd_distributed_at ON commission_pool_distribution(distributed_at);
CREATE INDEX IF NOT EXISTS idx_orders_user ON orders(user_id);
CREATE INDEX IF NOT EXISTS idx_orders_created_at ON orders(created_at);

-- 4. สร้าง Views
CREATE OR REPLACE VIEW user_commission_summary AS
SELECT
    recipient_user_id,
    COUNT(DISTINCT order_id) as total_orders_participated,
    COUNT(*) as total_distributions,
    SUM(CASE WHEN recipient_role = 'buyer' THEN amount ELSE 0 END) as total_from_own_purchase,
    SUM(CASE WHEN recipient_role LIKE 'upline_%' THEN amount ELSE 0 END) as total_from_network,
    SUM(CASE WHEN recipient_role = 'system_root' THEN amount ELSE 0 END) as total_from_system,
    SUM(amount) as total_commission_received
FROM commission_pool_distribution
GROUP BY recipient_user_id;

CREATE OR REPLACE VIEW order_commission_detail AS
SELECT
    o.order_id,
    o.user_id as buyer_user_id,
    o.premium_amount,
    o.commission_pool,
    cpd.recipient_user_id,
    cpd.recipient_role,
    cpd.upline_level,
    cpd.share_portion,
    cpd.amount,
    u.username as recipient_username,
    cpd.distributed_at
FROM orders o
JOIN commission_pool_distribution cpd ON o.order_id = cpd.order_id
JOIN users u ON cpd.recipient_user_id = u.user_id
ORDER BY o.order_id, cpd.upline_level;

-- 5. เพิ่ม Comments
COMMENT ON TABLE orders IS 'เก็บประวัติการซื้อประกันของแต่ละ user';
COMMENT ON TABLE commission_pool_distribution IS 'เก็บรายละเอียดการกระจาย Commission Pool (45% ของ Commission) ให้ผู้ซื้อและ Upline';
COMMENT ON COLUMN commission_pool_distribution.share_portion IS 'สัดส่วนที่ได้รับ เช่น 1/7 = 0.142857';
COMMENT ON COLUMN commission_pool_distribution.upline_level IS '0=buyer, 1-6=upline level, NULL=system_root';
COMMENT ON VIEW user_commission_summary IS 'สรุป Commission Pool ที่แต่ละคนได้รับทั้งหมด';

-- Commit Transaction
COMMIT;

-- แสดงผลลัพธ์
SELECT 'Migration completed successfully!' as status;
