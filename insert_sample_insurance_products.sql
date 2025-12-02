-- ============================================================================
-- Insert Sample Insurance Products for Fingrow Platform
-- Level 1-4 Insurance Products (Motor Insurance - PRB and Car Insurance)
-- ============================================================================

-- ============================================================================
-- Level 1: พรบ. (Compulsory Motor Insurance) - Entry Level
-- ============================================================================

-- PRB for Motorcycle
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
) VALUES (
  'PRB-MOTO-2025-001',
  'พรบ. รถจักรยานยนต์ ความคุ้มครอง 50,000 บาท',
  'พรบ. มอเตอร์ไซค์',
  'ประกันภาคบังคับรถจักรยานยนต์ คุ้มครองผู้ประสบภัยจากรถ วงเงิน 50,000 บาท ตามกฎหมาย',
  'บริษัท วิริยะประกันภัย จำกัด (มหาชน)',
  'motor', 'PRB',
  true, 'motorcycle', 'personal',
  12, 50000.00,
  'THB', 645.50, 600.00,
  7.00, 42.00, 3.50,
  15.00, 40.00, 60.00,
  2.50,
  '{"levels": [40, 20, 15, 10, 7, 5, 3], "self_bonus": 15}',
  1,
  '["popular", "compulsory", "level1", "motorcycle"]',
  true, true, 10
);

-- PRB for Car (Pickup/Sedan)
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
) VALUES (
  'PRB-CAR-2025-001',
  'พรบ. รถยนต์นั่งส่วนบุคคล ไม่เกิน 7 ที่นั่ง',
  'พรบ. รถยนต์',
  'ประกันภาคบังคับรถยนต์ คุ้มครองผู้ประสบภัยจากรถ ความรับผิดชอบตามกฎหมาย',
  'บริษัท กรุงเทพประกันภัย จำกัด (มหาชน)',
  'motor', 'PRB',
  true, 'car', 'personal',
  12, 100000.00,
  'THB', 756.50, 700.00,
  7.00, 49.00, 7.50,
  15.00, 40.00, 60.00,
  3.00,
  '{"levels": [40, 20, 15, 10, 7, 5, 3], "self_bonus": 15}',
  1,
  '["popular", "compulsory", "level1", "car"]',
  true, true, 20
);

-- ============================================================================
-- Level 2: ประกันภัยรถยนต์ ชั้น 3+ (Third Party Plus)
-- ============================================================================

INSERT INTO insurance_product (
  product_code, title, short_title, description,
  insurer_company_name, insurance_group, insurance_type,
  is_compulsory, vehicle_type, vehicle_usage,
  coverage_term_months, sum_insured_main,
  coverage_detail_json,
  currency_code, premium_total, premium_base,
  tax_vat_percent, tax_vat_amount, stamp_duty_amount,
  commission_percent, commission_to_fingrow_percent, commission_to_network_percent,
  finpoint_rate_per_100,
  finpoint_distribution_config,
  fingrow_level,
  tags,
  is_active, is_featured, sort_order
) VALUES (
  'CAR-3PLUS-2025-001',
  'ประกันภัยรถยนต์ ชั้น 3+ คุ้มครองครบ รวมอุบัติเหตุส่วนบุคคล',
  'รถยนต์ ชั้น 3+',
  'คุ้มครองความเสียหายต่อบุคคลภายนอก + ไฟไหม้ รถหาย + อุบัติเหตุส่วนบุคคลผู้ขับขี่ 100,000 บาท',
  'บริษัท เมืองไทยประกันภัย จำกัด (มหาชน)',
  'motor', 'CAR_3PLUS',
  false, 'car', 'personal',
  12, 1000000.00,
  '{"third_party_body": 1000000, "third_party_property": 1000000, "fire_theft": "covered", "personal_accident_driver": 100000, "medical_expense": 20000}',
  'THB', 4815.00, 4500.00,
  7.00, 315.00, 0.00,
  18.00, 35.00, 65.00,
  4.00,
  '{"levels": [35, 25, 15, 10, 7, 5, 3], "self_bonus": 20}',
  2,
  '["popular", "level2", "car", "fire-theft"]',
  true, true, 30
);

INSERT INTO insurance_product (
  product_code, title, short_title, description,
  insurer_company_name, insurance_group, insurance_type,
  is_compulsory, vehicle_type, vehicle_usage,
  coverage_term_months, sum_insured_main,
  coverage_detail_json,
  currency_code, premium_total, premium_base,
  tax_vat_percent, tax_vat_amount,
  commission_percent, commission_to_fingrow_percent, commission_to_network_percent,
  finpoint_rate_per_100,
  finpoint_distribution_config,
  fingrow_level,
  tags,
  is_active, is_featured, sort_order
) VALUES (
  'CAR-3PLUS-2025-002',
  'ประกันภัยรถยนต์ ชั้น 3+ Platinum คุ้มครองเพิ่ม อุบัติเหตุคนขับ 500,000',
  'รถยนต์ 3+ Platinum',
  'คุ้มครองบุคคลภายนอก + ไฟไหม้ รถหาย + อุบัติเหตุส่วนบุคคล 500,000 บาท + ค่ารักษาพยาบาล',
  'บริษัท ชับบ์สามัคคีประกันภัย จำกัด (มหาชน)',
  'motor', 'CAR_3PLUS',
  false, 'car', 'personal',
  12, 1000000.00,
  '{"third_party_body": 1000000, "third_party_property": 1000000, "fire_theft": "covered", "personal_accident_driver": 500000, "medical_expense": 50000, "bail_bond": 200000}',
  'THB', 6960.50, 6505.00,
  7.00, 455.50,
  20.00, 35.00, 65.00,
  4.50,
  '{"levels": [35, 25, 15, 10, 7, 5, 3], "self_bonus": 20}',
  2,
  '["level2", "car", "premium", "high-coverage"]',
  true, false, 40
);

-- ============================================================================
-- Level 3: ประกันภัยรถยนต์ ชั้น 2+ (Comprehensive Lite)
-- ============================================================================

INSERT INTO insurance_product (
  product_code, title, short_title, description,
  insurer_company_name, insurance_group, insurance_type,
  is_compulsory, vehicle_type, vehicle_usage,
  coverage_term_months, sum_insured_main,
  coverage_detail_json,
  currency_code, premium_total, premium_base,
  tax_vat_percent, tax_vat_amount,
  commission_percent, commission_to_fingrow_percent, commission_to_network_percent,
  finpoint_rate_per_100,
  finpoint_distribution_config,
  fingrow_level,
  tags,
  is_active, is_featured, sort_order
) VALUES (
  'CAR-2PLUS-2025-001',
  'ประกันภัยรถยนต์ ชั้น 2+ คุ้มครองตัวรถ แบบซ่อมอู่ + บุคคลภายนอก',
  'รถยนต์ ชั้น 2+',
  'คุ้มครองตัวรถ (ซ่อมอู่) + บุคคลภายนอก + อุบัติเหตุส่วนบุคคล ราคาประหยัด เหมาะกับรถมือสอง',
  'บริษัท ทิพยประกันภัย จำกัด (มหาชน)',
  'motor', 'CAR_2PLUS',
  false, 'car', 'personal',
  12, 350000.00,
  '{"own_damage": "garage", "deductible": 3000, "third_party_body": 1000000, "third_party_property": 1000000, "fire_theft": "covered", "personal_accident_driver": 100000, "medical_expense": 20000}',
  'THB', 9890.00, 9243.93,
  7.00, 646.07,
  22.00, 30.00, 70.00,
  5.50,
  '{"levels": [30, 25, 18, 12, 8, 5, 2], "self_bonus": 25}',
  3,
  '["level3", "car", "garage-repair", "budget"]',
  true, true, 50
);

INSERT INTO insurance_product (
  product_code, title, short_title, description,
  insurer_company_name, insurance_group, insurance_type,
  is_compulsory, vehicle_type, vehicle_usage,
  coverage_term_months, sum_insured_main,
  coverage_detail_json,
  currency_code, premium_total, premium_base,
  tax_vat_percent, tax_vat_amount,
  commission_percent, commission_to_fingrow_percent, commission_to_network_percent,
  finpoint_rate_per_100,
  finpoint_distribution_config,
  fingrow_level,
  tags,
  is_active, is_featured, sort_order
) VALUES (
  'CAR-2PLUS-2025-002',
  'ประกันภัยรถยนต์ ชั้น 2+ Premium ซ่อมอู่ + คุ้มครองน้ำท่วม',
  'รถยนต์ 2+ น้ำท่วม',
  'คุ้มครองตัวรถแบบซ่อมอู่ + ความเสียหายจากน้ำท่วม + อุบัติเหตุส่วนบุคคล 200,000 บาท',
  'บริษัท แอกซ่าประกันภัย จำกัด (มหาชน)',
  'motor', 'CAR_2PLUS',
  false, 'car', 'personal',
  12, 500000.00,
  '{"own_damage": "garage", "deductible": 2000, "flood_coverage": true, "third_party_body": 1000000, "third_party_property": 1000000, "personal_accident_driver": 200000, "medical_expense": 30000, "bail_bond": 200000}',
  'THB', 12850.00, 12009.35,
  7.00, 840.65,
  22.00, 30.00, 70.00,
  6.00,
  '{"levels": [30, 25, 18, 12, 8, 5, 2], "self_bonus": 25}',
  3,
  '["level3", "car", "flood", "premium"]',
  true, true, 60
);

-- ============================================================================
-- Level 4: ประกันภัยรถยนต์ ชั้น 1 (Full Comprehensive)
-- ============================================================================

INSERT INTO insurance_product (
  product_code, title, short_title, description,
  insurer_company_name, insurance_group, insurance_type,
  is_compulsory, vehicle_type, vehicle_usage,
  coverage_term_months, sum_insured_main,
  coverage_detail_json,
  currency_code, premium_total, premium_base,
  tax_vat_percent, tax_vat_amount,
  commission_percent, commission_to_fingrow_percent, commission_to_network_percent,
  finpoint_rate_per_100,
  finpoint_distribution_config,
  fingrow_level,
  cover_image_url,
  tags,
  is_active, is_featured, sort_order
) VALUES (
  'CAR-1-2025-001',
  'ประกันภัยรถยนต์ ชั้น 1 คุ้มครองเต็มรูป ซ่อมศูนย์ ทุนประกัน 800,000',
  'รถยนต์ ชั้น 1',
  'คุ้มครองตัวรถ (ซ่อมศูนย์) ไม่มีค่าเสียหายส่วนแรก + บุคคลภายนอก + อุบัติเหตุส่วนบุคคล 500,000 บาท',
  'บริษัท กรุงเทพประกันภัย จำกัด (มหาชน)',
  'motor', 'CAR_1',
  false, 'car', 'personal',
  12, 800000.00,
  '{"own_damage": "dealer", "deductible": 0, "third_party_body": 1000000, "third_party_property": 1000000, "fire_theft": "covered", "flood_coverage": true, "personal_accident_driver": 500000, "passenger_accident": 200000, "medical_expense": 50000, "bail_bond": 300000, "replacement_car": 15}',
  'THB', 18500.00, 17289.72,
  7.00, 1210.28,
  25.00, 25.00, 75.00,
  8.00,
  '{"levels": [25, 25, 20, 15, 8, 5, 2], "self_bonus": 30}',
  4,
  'https://example.com/images/car-class1-standard.jpg',
  '["level4", "car", "dealer-repair", "comprehensive", "popular"]',
  true, true, 70
);

INSERT INTO insurance_product (
  product_code, title, short_title, description,
  insurer_company_name, insurance_group, insurance_type,
  is_compulsory, vehicle_type, vehicle_usage,
  coverage_term_months, sum_insured_main,
  coverage_detail_json,
  currency_code, premium_total, premium_base,
  tax_vat_percent, tax_vat_amount,
  commission_percent, commission_to_fingrow_percent, commission_to_network_percent,
  finpoint_rate_per_100,
  finpoint_distribution_config,
  fingrow_level,
  cover_image_url,
  tags,
  is_active, is_featured, sort_order
) VALUES (
  'CAR-1-2025-002',
  'ประกันภัยรถยนต์ ชั้น 1 Premium ซ่อมศูนย์ ทุนประกัน 1,200,000 + รถเช่าทดแทน',
  'รถยนต์ ชั้น 1 Premium',
  'คุ้มครองครบทุกกรณี ซ่อมศูนย์ + รถเช่าทดแทน 30 วัน + อุบัติเหตุส่วนบุคคล 1,000,000 บาท เหมาะกับรถใหม่ป้ายแดง',
  'บริษัท วิริยะประกันภัย จำกัด (มหาชน)',
  'motor', 'CAR_1',
  false, 'car', 'personal',
  12, 1200000.00,
  '{"own_damage": "dealer", "deductible": 0, "third_party_body": 1000000, "third_party_property": 1000000, "fire_theft": "covered", "flood_coverage": true, "personal_accident_driver": 1000000, "passenger_accident": 500000, "medical_expense": 100000, "bail_bond": 500000, "replacement_car": 30, "vip_service": true}',
  'THB', 28750.00, 26869.16,
  7.00, 1880.84,
  25.00, 25.00, 75.00,
  10.00,
  '{"levels": [25, 25, 20, 15, 8, 5, 2], "self_bonus": 30}',
  4,
  'https://example.com/images/car-class1-premium.jpg',
  '["level4", "car", "dealer-repair", "premium", "new-car", "featured"]',
  true, true, 80
);

INSERT INTO insurance_product (
  product_code, title, short_title, description,
  insurer_company_name, insurance_group, insurance_type,
  is_compulsory, vehicle_type, vehicle_usage,
  coverage_term_months, sum_insured_main,
  coverage_detail_json,
  currency_code, premium_total, premium_base,
  tax_vat_percent, tax_vat_amount,
  commission_percent, commission_to_fingrow_percent, commission_to_network_percent,
  finpoint_rate_per_100,
  finpoint_distribution_config,
  fingrow_level,
  cover_image_url,
  tags,
  is_active, is_featured, sort_order
) VALUES (
  'CAR-1-2025-003',
  'ประกันภัยรถยนต์ ชั้น 1 VIP เหมาะกับรถหรู ทุนประกัน 3,000,000',
  'รถยนต์ ชั้น 1 VIP',
  'แพ็คเกจพิเศษสำหรับรถหรู คุ้มครองครบทุกกรณี + รถเช่าทดแทนระดับ Premium + บริการ VIP',
  'บริษัท เมืองไทยประกันภัย จำกัด (มหาชน)',
  'motor', 'CAR_1',
  false, 'car', 'personal',
  12, 3000000.00,
  '{"own_damage": "dealer", "deductible": 0, "third_party_body": 1000000, "third_party_property": 1000000, "fire_theft": "covered", "flood_coverage": true, "personal_accident_driver": 2000000, "passenger_accident": 1000000, "medical_expense": 200000, "bail_bond": 1000000, "replacement_car": 60, "replacement_car_class": "luxury", "vip_service": true, "windshield_coverage": "unlimited"}',
  'THB', 45800.00, 42803.74,
  7.00, 2996.26,
  25.00, 25.00, 75.00,
  12.00,
  '{"levels": [25, 25, 20, 15, 8, 5, 2], "self_bonus": 30}',
  4,
  'https://example.com/images/car-class1-vip.jpg',
  '["level4", "car", "luxury", "vip", "featured"]',
  true, true, 90
);

-- ============================================================================
-- Verification Query
-- ============================================================================

SELECT
  product_code,
  short_title,
  fingrow_level,
  insurance_type,
  premium_total,
  finpoint_rate_per_100,
  is_featured,
  sort_order
FROM insurance_product
ORDER BY fingrow_level, sort_order;
