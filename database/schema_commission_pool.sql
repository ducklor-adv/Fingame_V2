-- ===================================================
-- Commission Pool Distribution System
-- ===================================================

-- ตาราง Orders (ถ้ายังไม่มี ให้สร้าง)
CREATE TABLE IF NOT EXISTS orders (
    order_id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(user_id),
    insurance_product_id INTEGER NOT NULL,
    premium_amount DECIMAL(12, 2) NOT NULL,
    commission_rate DECIMAL(5, 4) NOT NULL, -- เช่น 0.15 = 15%
    total_commission DECIMAL(12, 2) NOT NULL, -- premium_amount * commission_rate
    management_fee DECIMAL(12, 2) NOT NULL, -- 10% of total_commission
    seller_commission DECIMAL(12, 2) NOT NULL, -- 45% of total_commission
    commission_pool DECIMAL(12, 2) NOT NULL, -- 45% of total_commission
    order_status VARCHAR(50) DEFAULT 'pending', -- pending, completed, cancelled
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ตาราง Commission Pool Distribution
-- เก็บรายละเอียดการกระจาย Commission Pool ให้แต่ละคนในเครือข่าย
CREATE TABLE IF NOT EXISTS commission_pool_distribution (
    distribution_id SERIAL PRIMARY KEY,
    order_id INTEGER NOT NULL REFERENCES orders(order_id) ON DELETE CASCADE,
    recipient_user_id INTEGER NOT NULL REFERENCES users(user_id),
    recipient_role VARCHAR(20) NOT NULL, -- 'buyer', 'upline_1', 'upline_2', ..., 'upline_6', 'system_root'
    upline_level INTEGER, -- 0 = buyer, 1-6 = upline level, NULL = system_root
    share_portion DECIMAL(5, 4) NOT NULL, -- 1/7 = 0.1429 (1 ส่วนใน 7 ส่วน)
    amount DECIMAL(12, 2) NOT NULL, -- จำนวนเงินที่ได้รับ
    distributed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    -- Indexes for fast queries
    INDEX idx_recipient_user (recipient_user_id),
    INDEX idx_order (order_id),
    INDEX idx_distributed_at (distributed_at)
);

-- View: สรุป Commission Pool ที่แต่ละคนได้รับทั้งหมด
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

-- View: รายละเอียด Commission Pool ของแต่ละ Order
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

-- Comments
COMMENT ON TABLE commission_pool_distribution IS 'เก็บรายละเอียดการกระจาย Commission Pool (45% ของ Commission) ให้ผู้ซื้อและ Upline';
COMMENT ON COLUMN commission_pool_distribution.share_portion IS 'สัดส่วนที่ได้รับ เช่น 1/7 = 0.142857';
COMMENT ON COLUMN commission_pool_distribution.upline_level IS '0=buyer, 1-6=upline level, NULL=system_root';
