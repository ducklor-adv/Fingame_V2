-- ===================================================
-- Migration: Create Commission Pool Tables
-- ===================================================
-- วันที่: 2025-12-03
-- คำอธิบาย: สร้างตารางสำหรับระบบ Commission Pool Distribution

BEGIN;

-- ===================================================
-- 1. สร้างตาราง insurance_orders
-- ===================================================
-- เก็บประวัติการซื้อประกันของแต่ละ user
CREATE TABLE IF NOT EXISTS insurance_orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_number VARCHAR(50) UNIQUE NOT NULL,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    insurance_product_id UUID NOT NULL REFERENCES insurance_product(id) ON DELETE RESTRICT,

    -- ข้อมูลราคา
    premium_amount NUMERIC(12, 2) NOT NULL,
    commission_rate NUMERIC(5, 2) NOT NULL, -- 15.00 = 15%

    -- การแบ่ง Commission
    total_commission NUMERIC(12, 2) NOT NULL,
    management_fee NUMERIC(12, 2) NOT NULL,           -- 10% of total_commission
    seller_commission NUMERIC(12, 2) NOT NULL,        -- 45% of total_commission
    commission_pool NUMERIC(12, 2) NOT NULL,          -- 45% of total_commission

    -- วิธีชำระเงิน
    payment_method VARCHAR(20) NOT NULL CHECK (payment_method IN ('cash', 'finpoint')),
    finpoint_spent NUMERIC(12, 2) DEFAULT 0,          -- จำนวน Finpoint ที่ใช้ (ถ้าเป็น finpoint)

    -- สถานะ
    order_status VARCHAR(50) DEFAULT 'completed',

    -- Timestamps
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Create indexes for insurance_orders
CREATE INDEX IF NOT EXISTS idx_io_user ON insurance_orders(user_id);
CREATE INDEX IF NOT EXISTS idx_io_product ON insurance_orders(insurance_product_id);
CREATE INDEX IF NOT EXISTS idx_io_created_at ON insurance_orders(created_at);

-- ===================================================
-- 2. สร้างตาราง commission_pool_distribution
-- ===================================================
-- เก็บรายละเอียดการกระจาย Commission Pool ให้แต่ละคนในเครือข่าย
CREATE TABLE IF NOT EXISTS commission_pool_distribution (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    insurance_order_id UUID REFERENCES insurance_orders(id) ON DELETE CASCADE,
    recipient_user_id UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,

    -- บทบาทของผู้รับ
    recipient_role VARCHAR(20) NOT NULL, -- 'buyer', 'upline_1', ..., 'upline_6', 'system_root', 'finpoint_spent'
    upline_level INTEGER, -- 0 = buyer, 1-6 = upline level, NULL = system_root or finpoint_spent

    -- จำนวนเงินที่ได้รับ/ใช้
    share_portion NUMERIC(10, 6) NOT NULL, -- 0.142857 = 1/7
    amount NUMERIC(12, 2) NOT NULL,        -- จำนวนเงิน (บวก = รับ, ลบ = จ่าย)

    -- Metadata
    transaction_type VARCHAR(20) DEFAULT 'commission', -- 'commission' หรือ 'spending'
    description TEXT,

    -- Timestamp
    distributed_at TIMESTAMP DEFAULT NOW()
);

-- Create indexes for commission_pool_distribution
CREATE INDEX IF NOT EXISTS idx_cpd_recipient ON commission_pool_distribution(recipient_user_id);
CREATE INDEX IF NOT EXISTS idx_cpd_order ON commission_pool_distribution(insurance_order_id);
CREATE INDEX IF NOT EXISTS idx_cpd_distributed_at ON commission_pool_distribution(distributed_at);
CREATE INDEX IF NOT EXISTS idx_cpd_type ON commission_pool_distribution(transaction_type);

-- ===================================================
-- 3. สร้าง View: user_finpoint_summary
-- ===================================================
-- สรุป Finpoint รวมของแต่ละ User (รับ - จ่าย)
CREATE OR REPLACE VIEW user_finpoint_summary AS
SELECT
    recipient_user_id,
    COUNT(*) as total_transactions,
    COUNT(DISTINCT insurance_order_id) as total_orders_involved,
    SUM(CASE WHEN amount > 0 THEN amount ELSE 0 END) as total_received,
    SUM(CASE WHEN amount < 0 THEN ABS(amount) ELSE 0 END) as total_spent,
    SUM(amount) as current_finpoint,

    -- แยกตามประเภท
    SUM(CASE WHEN recipient_role = 'buyer' THEN amount ELSE 0 END) as from_own_purchase,
    SUM(CASE WHEN recipient_role LIKE 'upline_%' THEN amount ELSE 0 END) as from_network,
    SUM(CASE WHEN recipient_role = 'system_root' THEN amount ELSE 0 END) as from_system
FROM commission_pool_distribution
GROUP BY recipient_user_id;

-- ===================================================
-- 4. สร้าง View: insurance_order_detail
-- ===================================================
-- รายละเอียดการกระจาย Commission Pool ของแต่ละ Order
CREATE OR REPLACE VIEW insurance_order_detail AS
SELECT
    io.id as order_id,
    io.order_number,
    io.user_id as buyer_user_id,
    u.username as buyer_username,
    io.insurance_product_id,
    ip.short_title as insurance_name,
    io.premium_amount,
    io.commission_pool,
    io.payment_method,
    io.finpoint_spent,
    cpd.recipient_user_id,
    ur.username as recipient_username,
    cpd.recipient_role,
    cpd.upline_level,
    cpd.share_portion,
    cpd.amount,
    cpd.distributed_at
FROM insurance_orders io
JOIN users u ON io.user_id = u.id
JOIN insurance_product ip ON io.insurance_product_id = ip.id
JOIN commission_pool_distribution cpd ON io.id = cpd.insurance_order_id
JOIN users ur ON cpd.recipient_user_id = ur.id
ORDER BY io.created_at DESC, cpd.upline_level;

-- ===================================================
-- 5. เพิ่ม Comments
-- ===================================================
COMMENT ON TABLE insurance_orders IS 'เก็บประวัติการซื้อประกันของแต่ละ user';
COMMENT ON TABLE commission_pool_distribution IS 'เก็บรายละเอียดการกระจาย Commission Pool (45% ของ Commission) และการใช้ Finpoint';
COMMENT ON COLUMN commission_pool_distribution.amount IS 'จำนวน Finpoint (+ = รับ, - = จ่าย)';
COMMENT ON COLUMN commission_pool_distribution.upline_level IS '0=buyer, 1-6=upline level, NULL=system_root/finpoint_spent';
COMMENT ON VIEW user_finpoint_summary IS 'สรุป Finpoint รวมของแต่ละคน (รับ - จ่าย = คงเหลือ)';

-- ===================================================
-- 6. สร้าง Function: generate_order_number
-- ===================================================
CREATE OR REPLACE FUNCTION generate_insurance_order_number()
RETURNS TEXT AS $$
DECLARE
    new_order_number TEXT;
    counter INT;
BEGIN
    -- สร้าง order number รูปแบบ INS-YYYYMMDD-NNNN
    SELECT COUNT(*) + 1 INTO counter
    FROM insurance_orders
    WHERE DATE(created_at) = CURRENT_DATE;

    new_order_number := 'INS-' || TO_CHAR(CURRENT_DATE, 'YYYYMMDD') || '-' || LPAD(counter::TEXT, 4, '0');

    RETURN new_order_number;
END;
$$ LANGUAGE plpgsql;

COMMIT;

-- แสดงผลลัพธ์
SELECT
    'Migration completed successfully!' as status,
    COUNT(*) FILTER (WHERE table_name = 'insurance_orders') as insurance_orders_created,
    COUNT(*) FILTER (WHERE table_name = 'commission_pool_distribution') as cpd_created
FROM information_schema.tables
WHERE table_name IN ('insurance_orders', 'commission_pool_distribution');
