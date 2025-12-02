-- ============================================================================
-- Create insurance_product table
-- ============================================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE insurance_product (
  -- 1) ฟิลด์ระบบพื้นฐาน
  id                              UUID PRIMARY KEY DEFAULT uuid_generate_v4() NOT NULL,
  product_code                    VARCHAR(50) NOT NULL,
  title                           VARCHAR(255) NOT NULL,
  short_title                     VARCHAR(120),
  description                     TEXT,

  -- 2) การเชื่อมกับบริษัทประกัน / ผู้ขาย
  insurer_company_name            VARCHAR(255) NOT NULL,
  seller_id                       UUID,

  -- 3) การจัดประเภทแผนประกัน
  insurance_group                 VARCHAR(50) NOT NULL,
  insurance_type                  VARCHAR(50) NOT NULL,
  is_compulsory                   BOOLEAN NOT NULL DEFAULT false,
  vehicle_type                    VARCHAR(50),
  vehicle_usage                   VARCHAR(50),

  -- 4) ระยะเวลาและทุนประกัน
  coverage_term_months            INTEGER NOT NULL DEFAULT 12,
  sum_insured_main                NUMERIC(15,2),
  coverage_detail_json            JSONB,

  -- 5) โครงราคาที่ลูกค้าจ่าย
  currency_code                   VARCHAR(3) NOT NULL DEFAULT 'THB',
  premium_total                   NUMERIC(15,2) NOT NULL,
  premium_base                    NUMERIC(15,2),
  tax_vat_percent                 NUMERIC(5,2),
  tax_vat_amount                  NUMERIC(15,2),
  government_levy_amount          NUMERIC(15,2),
  stamp_duty_amount               NUMERIC(15,2),

  -- 6) ฟิลด์เฉพาะ Fingrow / FinPoint / MLM
  commission_percent              NUMERIC(5,2),
  commission_to_fingrow_percent   NUMERIC(5,2),
  commission_to_network_percent   NUMERIC(5,2),
  finpoint_rate_per_100           NUMERIC(10,2),
  finpoint_distribution_config    JSONB,
  fingrow_level                   SMALLINT NOT NULL,

  -- 7) รูปภาพ / UI / Tag
  cover_image_url                 VARCHAR(500),
  brochure_url                    VARCHAR(500),
  tags                            JSONB,

  -- 8) สถานะการแสดงผล + เวลาบังคับใช้
  is_active                       BOOLEAN NOT NULL DEFAULT true,
  is_featured                     BOOLEAN NOT NULL DEFAULT false,
  sort_order                      INTEGER,
  effective_from                  DATE,
  effective_to                    DATE,

  -- 9) ฟิลด์ระบบ (Audit)
  created_at                      TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW(),
  updated_at                      TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW(),
  created_by                      UUID,
  updated_by                      UUID,
  deleted_at                      TIMESTAMP WITHOUT TIME ZONE,

  -- Constraints
  CONSTRAINT fk_seller FOREIGN KEY (seller_id)
    REFERENCES users(id) ON DELETE SET NULL ON UPDATE NO ACTION,
  CONSTRAINT fk_created_by FOREIGN KEY (created_by)
    REFERENCES users(id) ON DELETE SET NULL ON UPDATE NO ACTION,
  CONSTRAINT fk_updated_by FOREIGN KEY (updated_by)
    REFERENCES users(id) ON DELETE SET NULL ON UPDATE NO ACTION,
  CONSTRAINT chk_fingrow_level CHECK (fingrow_level BETWEEN 1 AND 4)
);

-- ============================================================================
-- Create indexes
-- ============================================================================

CREATE INDEX idx_insurance_product_insurance_group ON insurance_product(insurance_group);
CREATE INDEX idx_insurance_product_insurance_type ON insurance_product(insurance_type);
CREATE INDEX idx_insurance_product_is_active ON insurance_product(is_active);
CREATE INDEX idx_insurance_product_insurer_company_name ON insurance_product(insurer_company_name);
CREATE INDEX idx_insurance_product_fingrow_level ON insurance_product(fingrow_level);

CREATE INDEX idx_insurance_product_tags ON insurance_product USING GIN(tags);
CREATE INDEX idx_insurance_product_coverage_detail_json ON insurance_product USING GIN(coverage_detail_json);
CREATE INDEX idx_insurance_product_finpoint_distribution_config ON insurance_product USING GIN(finpoint_distribution_config);

-- ============================================================================
-- Create trigger for updated_at
-- ============================================================================

CREATE OR REPLACE FUNCTION update_insurance_product_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_insurance_product_updated_at
  BEFORE UPDATE ON insurance_product
  FOR EACH ROW
  EXECUTE FUNCTION update_insurance_product_updated_at();

-- ============================================================================
-- Add comments
-- ============================================================================

COMMENT ON TABLE insurance_product IS 'ตารางเก็บข้อมูลผลิตภัณฑ์ประกันภัยสำหรับ Fingrow Platform';
COMMENT ON COLUMN insurance_product.product_code IS 'รหัสผลิตภัณฑ์ประกัน';
COMMENT ON COLUMN insurance_product.fingrow_level IS 'ระดับ Fingrow Level (1-4) สำหรับ UI Dashboard';
COMMENT ON COLUMN insurance_product.finpoint_rate_per_100 IS 'จำนวน FinPoint ต่อเบี้ยประกัน 100 บาท';
COMMENT ON COLUMN insurance_product.finpoint_distribution_config IS 'การกระจาย FinPoint แต่ละชั้น (ACF 7 levels)';
