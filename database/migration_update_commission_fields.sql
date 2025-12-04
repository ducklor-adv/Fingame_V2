-- ===================================================
-- Migration: Update Commission Fields in Insurance Product
-- ===================================================
-- วันที่: 2025-12-03
-- คำอธิบาย: เพิ่มและอัปเดต fields สำหรับ Commission Structure

BEGIN;

-- 1. เพิ่ม columns ใหม่
ALTER TABLE insurance_product
ADD COLUMN IF NOT EXISTS commission_pool_percent NUMERIC(5,2) DEFAULT 45.00,
ADD COLUMN IF NOT EXISTS commission_seller_percent NUMERIC(5,2) DEFAULT 45.00;

-- 2. อัปเดต commission_to_fingrow_percent ให้มี default และ populate ข้อมูล
ALTER TABLE insurance_product
ALTER COLUMN commission_to_fingrow_percent SET DEFAULT 10.00;

-- Update existing NULL values
UPDATE insurance_product
SET commission_to_fingrow_percent = 10.00
WHERE commission_to_fingrow_percent IS NULL;

-- Update existing NULL values for new fields
UPDATE insurance_product
SET
  commission_pool_percent = 45.00,
  commission_seller_percent = 45.00
WHERE commission_pool_percent IS NULL
   OR commission_seller_percent IS NULL;

-- 3. อัปเดตทุกรายการให้มีค่าครบ 100% (force update all rows)
UPDATE insurance_product
SET
  commission_to_fingrow_percent = 10.00,
  commission_pool_percent = 45.00,
  commission_seller_percent = 45.00;

-- 4. เพิ่ม NOT NULL constraints
ALTER TABLE insurance_product
ALTER COLUMN commission_to_fingrow_percent SET NOT NULL,
ALTER COLUMN commission_pool_percent SET NOT NULL,
ALTER COLUMN commission_seller_percent SET NOT NULL;

-- 5. ลบ field commission_to_network_percent (ไม่จำเป็นแล้ว เพราะมี pool + seller แทน)
-- คำนวณได้จาก: commission_pool_percent + commission_seller_percent
ALTER TABLE insurance_product
DROP COLUMN IF EXISTS commission_to_network_percent;

-- 6. เพิ่ม comments อธิบาย fields
COMMENT ON COLUMN insurance_product.commission_to_fingrow_percent IS 'เปอร์เซ็นต์ค่าคอมมิชชันที่ Fingrow Platform จะได้รับ (Management Fee) - Default 10%';
COMMENT ON COLUMN insurance_product.commission_pool_percent IS 'เปอร์เซ็นต์ของค่าคอมมิชชันที่จะเข้า Commission Pool (แบ่งให้ Network 7 คน) - Default 45%';
COMMENT ON COLUMN insurance_product.commission_seller_percent IS 'เปอร์เซ็นต์ของค่าคอมมิชชันที่ Seller (ผู้ซื้อ) จะได้รับ - Default 45%';

-- 7. เพิ่ม CHECK constraint เพื่อให้แน่ใจว่าผลรวม = 100%
ALTER TABLE insurance_product
ADD CONSTRAINT check_commission_total
CHECK (
  commission_to_fingrow_percent +
  commission_pool_percent +
  commission_seller_percent = 100.00
);

-- 8. แสดงตัวอย่างข้อมูล
SELECT
    short_title,
    commission_to_fingrow_percent as fingrow_fee,
    commission_seller_percent as seller_share,
    commission_pool_percent as pool_share,
    (commission_to_fingrow_percent + commission_seller_percent + commission_pool_percent) as sum_check
FROM insurance_product
LIMIT 5;

COMMIT;

-- แสดงผลลัพธ์
SELECT
    'Migration completed successfully!' as status,
    COUNT(*) as total_products,
    AVG(commission_to_fingrow_percent) as avg_fingrow_percent,
    AVG(commission_seller_percent) as avg_seller_percent,
    AVG(commission_pool_percent) as avg_pool_percent
FROM insurance_product;
