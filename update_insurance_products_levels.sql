-- ============================================================================
-- Update Insurance Products to Correct Levels and Add Health/Life Insurance
-- ============================================================================

BEGIN;

-- Step 1: Delete existing Level 3 and 4 products (car insurance in wrong levels)
DELETE FROM insurance_product WHERE fingrow_level IN (3, 4);

-- Step 2: Insert Level 3 - Health Insurance Products
INSERT INTO insurance_product (
  product_code, title, short_title, description,
  insurer_company_name, insurance_group, insurance_type,
  is_compulsory, vehicle_type, vehicle_usage,
  coverage_term_months, sum_insured_main,
  currency_code, premium_total, premium_base,
  tax_vat_percent, tax_vat_amount, stamp_duty_amount,
  commission_percent, commission_to_fingrow_percent, commission_to_network_percent,
  finpoint_rate_per_100,
  finpoint_distribution_config,
  fingrow_level,
  tags,
  is_active, is_featured, sort_order
) VALUES
-- Level 3: Health Insurance Product 1
(
  'HEALTH-IND-2025-001',
  'ประกันสุขภาพรายบุคคล แผนพื้นฐาน',
  'ประกันสุขภาพ แผนพื้นฐาน',
  'ประกันสุขภาพรายบุคคล คุ้มครองค่ารักษาพยาบาล ค่าห้องและค่าอาหาร วงเงิน 500,000 บาท/ปี',
  'บริษัท เมืองไทยประกันชีวิต จำกัด (มหาชน)',
  'health', 'INDIVIDUAL_HEALTH',
  false, null, null,
  12, 500000.00,
  'THB', 8500.00, 8000.00,
  7.00, 560.00, NULL,
  18.00, 30.00, 70.00,
  5.00,
  '{"levels": [35, 20, 15, 12, 8, 6, 4], "self_bonus": 20}',
  3,
  '["popular", "health", "level3", "individual"]',
  true, true, 10
),

-- Level 3: Health Insurance Product 2
(
  'HEALTH-FAM-2025-001',
  'ประกันสุขภาพครอบครัว แผนครอบครัว',
  'ประกันสุขภาพ ครอบครัว',
  'ประกันสุขภาพครอบครัว คุ้มครอง 4 คน ค่ารักษาพยาบาล ค่าห้องและค่าอาหาร วงเงิน 1,000,000 บาท/ปี',
  'บริษัท เมืองไทยประกันชีวิต จำกัด (มหาชน)',
  'health', 'FAMILY_HEALTH',
  false, null, null,
  12, 1000000.00,
  'THB', 15800.00, 15000.00,
  7.00, 1050.00, NULL,
  18.00, 30.00, 70.00,
  6.00,
  '{"levels": [35, 20, 15, 12, 8, 6, 4], "self_bonus": 20}',
  3,
  '["popular", "health", "level3", "family"]',
  true, true, 20
),

-- Level 3: Health Insurance Product 3
(
  'HEALTH-CANCER-2025-001',
  'ประกันโรคร้ายแรง (มะเร็ง)',
  'ประกันโรคมะเร็ง',
  'ประกันโรคร้ายแรง คุ้มครองโรคมะเร็ง จ่ายเงินก้อน 1,000,000 บาท เมื่อวินิจฉัยเป็นมะเร็ง',
  'บริษัท กรุงไทย-แอกซ่า ประกันชีวิต จำกัด (มหาชน)',
  'health', 'CRITICAL_ILLNESS',
  false, null, null,
  12, 1000000.00,
  'THB', 12500.00, 12000.00,
  7.00, 840.00, NULL,
  20.00, 30.00, 70.00,
  5.50,
  '{"levels": [35, 20, 15, 12, 8, 6, 4], "self_bonus": 20}',
  3,
  '["health", "level3", "critical-illness", "cancer"]',
  true, false, 30
);

-- Step 3: Insert Level 4 - Life Insurance Products
INSERT INTO insurance_product (
  product_code, title, short_title, description,
  insurer_company_name, insurance_group, insurance_type,
  is_compulsory, vehicle_type, vehicle_usage,
  coverage_term_months, sum_insured_main,
  currency_code, premium_total, premium_base,
  tax_vat_percent, tax_vat_amount, stamp_duty_amount,
  commission_percent, commission_to_fingrow_percent, commission_to_network_percent,
  finpoint_rate_per_100,
  finpoint_distribution_config,
  fingrow_level,
  tags,
  is_active, is_featured, sort_order
) VALUES
-- Level 4: Life Insurance Product 1
(
  'LIFE-TERM-2025-001',
  'ประกันชีวิตแบบสะสมทรัพย์ 10 ปี',
  'ประกันชีวิต 10 ปี',
  'ประกันชีวิตแบบสะสมทรัพย์ ระยะเวลา 10 ปี ทุนประกัน 1,000,000 บาท พร้อมเงินคืนเมื่อครบกำหนด',
  'บริษัท เมืองไทยประกันชีวิต จำกัด (มหาชน)',
  'life', 'ENDOWMENT',
  false, null, null,
  120, 1000000.00,
  'THB', 35000.00, 33000.00,
  7.00, 2310.00, NULL,
  25.00, 25.00, 75.00,
  8.00,
  '{"levels": [40, 20, 15, 10, 7, 5, 3], "self_bonus": 25}',
  4,
  '["popular", "life", "level4", "endowment", "savings"]',
  true, true, 10
),

-- Level 4: Life Insurance Product 2
(
  'LIFE-WHOLE-2025-001',
  'ประกันชีวิตตลอดชีพ พรีเมียม',
  'ประกันชีวิต ตลอดชีพ',
  'ประกันชีวิตตลอดชีพ ทุนประกัน 2,000,000 บาท คุ้มครองตลอดชีพ มูลค่าเงินสดสะสม',
  'บริษัท กรุงเทพประกันชีวิต จำกัด (มหาชน)',
  'life', 'WHOLE_LIFE',
  false, null, null,
  12, 2000000.00,
  'THB', 58000.00, 55000.00,
  7.00, 3850.00, NULL,
  25.00, 25.00, 75.00,
  10.00,
  '{"levels": [40, 20, 15, 10, 7, 5, 3], "self_bonus": 25}',
  4,
  '["life", "level4", "whole-life", "premium"]',
  true, true, 20
),

-- Level 4: Life Insurance Product 3
(
  'LIFE-INVEST-2025-001',
  'ประกันชีวิตควบการลงทุน (Unit Link)',
  'Unit Link ชีวิต+ลงทุน',
  'ประกันชีวิตควบการลงทุน ทุนประกัน 3,000,000 บาท พร้อมกองทุนลงทุนหลากหลาย',
  'บริษัท กรุงไทย-แอกซ่า ประกันชีวิต จำกัด (มหาชน)',
  'life', 'UNIT_LINKED',
  false, null, null,
  12, 3000000.00,
  'THB', 72000.00, 68000.00,
  7.00, 4760.00, NULL,
  28.00, 25.00, 75.00,
  12.00,
  '{"levels": [40, 20, 15, 10, 7, 5, 3], "self_bonus": 25}',
  4,
  '["life", "level4", "unit-linked", "investment", "premium"]',
  true, true, 30
),

-- Level 4: Life Insurance Product 4
(
  'LIFE-RETIRE-2025-001',
  'ประกันบำนาญ เพื่อการเกษียณ',
  'ประกันบำนาญ',
  'ประกันบำนาญ เริ่มรับเงินบำนาญอายุ 60 ปี 20,000 บาท/เดือน ตลอดชีพ',
  'บริษัท อาคเนย์ประกันชีวิต จำกัด (มหาชน)',
  'life', 'ANNUITY',
  false, null, null,
  12, 5000000.00,
  'THB', 95000.00, 90000.00,
  7.00, 6300.00, NULL,
  28.00, 25.00, 75.00,
  15.00,
  '{"levels": [40, 20, 15, 10, 7, 5, 3], "self_bonus": 25}',
  4,
  '["life", "level4", "annuity", "retirement", "vip"]',
  true, false, 40
);

COMMIT;

-- Verification
SELECT
  fingrow_level,
  COUNT(*) as product_count,
  insurance_group,
  STRING_AGG(short_title, ', ' ORDER BY premium_total) as products
FROM insurance_product
WHERE is_active = true AND deleted_at IS NULL
GROUP BY fingrow_level, insurance_group
ORDER BY fingrow_level, insurance_group;
