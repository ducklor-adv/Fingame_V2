-- ===================================================
-- Migration: Add Commission Amount Field
-- ===================================================
-- วันที่: 2025-12-03
-- คำอธิบาย: เพิ่ม field commission_amount (ค่าคอมมิชชันเป็นตัวเงิน)
-- คำนวณจาก premium_base × commission_percent / 100

BEGIN;

-- 1. เพิ่ม column commission_amount
ALTER TABLE insurance_product
ADD COLUMN IF NOT EXISTS commission_amount NUMERIC(15,2);

-- 2. คำนวณและ populate ข้อมูล commission_amount
-- สูตร: premium_base × commission_percent / 100
UPDATE insurance_product
SET commission_amount = ROUND((premium_base * commission_percent / 100), 2)
WHERE premium_base IS NOT NULL
  AND commission_percent IS NOT NULL;

-- 3. เพิ่ม NOT NULL constraint หลังจาก populate ข้อมูล
ALTER TABLE insurance_product
ALTER COLUMN commission_amount SET NOT NULL;

-- 4. เพิ่ม comment อธิบาย field
COMMENT ON COLUMN insurance_product.commission_amount IS 'ค่าคอมมิชชันรวม (บาท) คำนวณจาก premium_base × commission_percent / 100';

-- 5. เพิ่ม calculated columns สำหรับแต่ละส่วน
ALTER TABLE insurance_product
ADD COLUMN IF NOT EXISTS commission_fingrow_amount NUMERIC(15,2),
ADD COLUMN IF NOT EXISTS commission_seller_amount NUMERIC(15,2),
ADD COLUMN IF NOT EXISTS commission_pool_amount NUMERIC(15,2);

-- 6. คำนวณและ populate ข้อมูลแต่ละส่วน
UPDATE insurance_product
SET
  commission_fingrow_amount = ROUND((commission_amount * commission_to_fingrow_percent / 100), 2),
  commission_seller_amount = ROUND((commission_amount * commission_seller_percent / 100), 2),
  commission_pool_amount = ROUND((commission_amount * commission_pool_percent / 100), 2)
WHERE commission_amount IS NOT NULL;

-- 7. เพิ่ม NOT NULL constraints
ALTER TABLE insurance_product
ALTER COLUMN commission_fingrow_amount SET NOT NULL,
ALTER COLUMN commission_seller_amount SET NOT NULL,
ALTER COLUMN commission_pool_amount SET NOT NULL;

-- 8. เพิ่ม comments
COMMENT ON COLUMN insurance_product.commission_fingrow_amount IS 'ค่าคอมมิชชันส่วน Fingrow Platform (10% ของ commission_amount)';
COMMENT ON COLUMN insurance_product.commission_seller_amount IS 'ค่าคอมมิชชันส่วน Seller (45% ของ commission_amount)';
COMMENT ON COLUMN insurance_product.commission_pool_amount IS 'ค่าคอมมิชชันส่วน Pool แบ่ง 7 คน (45% ของ commission_amount)';

-- 9. แสดงตัวอย่างข้อมูล
SELECT
    short_title,
    premium_base,
    commission_percent,
    commission_amount,
    commission_fingrow_amount as fingrow,
    commission_seller_amount as seller,
    commission_pool_amount as pool,
    ROUND((commission_pool_amount / 7), 2) as pool_per_person
FROM insurance_product
ORDER BY premium_base
LIMIT 5;

COMMIT;

-- แสดงผลลัพธ์
SELECT
    'Migration completed successfully!' as status,
    COUNT(*) as total_products,
    AVG(commission_amount) as avg_commission,
    MIN(commission_amount) as min_commission,
    MAX(commission_amount) as max_commission
FROM insurance_product;
