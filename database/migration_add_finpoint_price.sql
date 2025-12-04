-- ===================================================
-- Migration: Add Finpoint Price to Insurance Product
-- ===================================================
-- วันที่: 2025-12-03
-- คำอธิบาย: เพิ่ม field finpoint_price สำหรับราคาเป็น Finpoint

BEGIN;

-- 1. เพิ่ม column finpoint_price
ALTER TABLE insurance_product
ADD COLUMN IF NOT EXISTS finpoint_price NUMERIC(12, 2);

-- 2. คำนวณและ populate ข้อมูล finpoint_price จาก premium_total
-- สมมติ: 1 บาท = 1 Finpoint
UPDATE insurance_product
SET finpoint_price = premium_total
WHERE finpoint_price IS NULL;

-- 3. เพิ่ม NOT NULL constraint หลังจาก populate ข้อมูลเสร็จ
ALTER TABLE insurance_product
ALTER COLUMN finpoint_price SET NOT NULL;

-- 4. เพิ่ม comment อธิบาย field
COMMENT ON COLUMN insurance_product.finpoint_price IS 'ราคาสินค้าเป็น Finpoint (1 FP = 1 บาท ในปัจจุบัน)';

-- 5. แสดงตัวอย่างข้อมูล
SELECT
    id,
    short_title,
    premium_total as price_baht,
    finpoint_price as price_fp,
    (premium_total = finpoint_price) as is_equal
FROM insurance_product
LIMIT 5;

COMMIT;

-- แสดงผลลัพธ์
SELECT
    'Migration completed successfully!' as status,
    COUNT(*) as total_products,
    MIN(finpoint_price) as min_fp_price,
    MAX(finpoint_price) as max_fp_price,
    AVG(finpoint_price) as avg_fp_price
FROM insurance_product;
