-- ============================================================================
-- Create user_insurance_selections table
-- ============================================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE user_insurance_selections (
  -- 1) Primary key
  id                      UUID PRIMARY KEY DEFAULT uuid_generate_v4() NOT NULL,

  -- 2) Relations
  user_id                 UUID NOT NULL,
  insurance_product_id    UUID NOT NULL,

  -- 3) Selection metadata
  selected_at             TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW(),
  is_active               BOOLEAN NOT NULL DEFAULT true,
  priority                INTEGER DEFAULT 1,
  notes                   TEXT,

  -- 4) Audit
  created_at              TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW(),
  updated_at              TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW(),
  deactivated_at          TIMESTAMP WITHOUT TIME ZONE,

  -- 5) Constraints
  CONSTRAINT fk_user FOREIGN KEY (user_id)
    REFERENCES users(id) ON DELETE CASCADE ON UPDATE NO ACTION,
  CONSTRAINT fk_insurance_product FOREIGN KEY (insurance_product_id)
    REFERENCES insurance_product(id) ON DELETE CASCADE ON UPDATE NO ACTION
);

-- ============================================================================
-- Create indexes
-- ============================================================================

-- Index for user_id lookups (most common query pattern)
CREATE INDEX idx_user_insurance_selections_user_id
  ON user_insurance_selections(user_id);

-- Index for insurance_product_id lookups
CREATE INDEX idx_user_insurance_selections_insurance_product_id
  ON user_insurance_selections(insurance_product_id);

-- Index for active selections (for filtering active/inactive)
CREATE INDEX idx_user_insurance_selections_is_active
  ON user_insurance_selections(is_active);

-- Composite index for getting user's active selections
CREATE INDEX idx_user_insurance_selections_user_active
  ON user_insurance_selections(user_id, is_active)
  WHERE is_active = true;

-- Index for priority ordering
CREATE INDEX idx_user_insurance_selections_priority
  ON user_insurance_selections(user_id, priority, is_active);

-- ============================================================================
-- Create trigger for updated_at
-- ============================================================================

CREATE OR REPLACE FUNCTION update_user_insurance_selections_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_user_insurance_selections_updated_at
  BEFORE UPDATE ON user_insurance_selections
  FOR EACH ROW
  EXECUTE FUNCTION update_user_insurance_selections_updated_at();

-- ============================================================================
-- Create trigger to set deactivated_at when is_active changes to false
-- ============================================================================

CREATE OR REPLACE FUNCTION update_user_insurance_selections_deactivated_at()
RETURNS TRIGGER AS $$
BEGIN
  IF OLD.is_active = true AND NEW.is_active = false THEN
    NEW.deactivated_at = NOW();
  END IF;

  IF OLD.is_active = false AND NEW.is_active = true THEN
    NEW.deactivated_at = NULL;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_user_insurance_selections_deactivated_at
  BEFORE UPDATE ON user_insurance_selections
  FOR EACH ROW
  EXECUTE FUNCTION update_user_insurance_selections_deactivated_at();

-- ============================================================================
-- Add comments
-- ============================================================================

COMMENT ON TABLE user_insurance_selections IS 'เก็บการเลือกผลิตภัณฑ์ประกันภัยของ user แต่ละคน (many-to-many relationship)';
COMMENT ON COLUMN user_insurance_selections.user_id IS 'UUID ของ user ที่เลือก';
COMMENT ON COLUMN user_insurance_selections.insurance_product_id IS 'UUID ของผลิตภัณฑ์ประกันที่ถูกเลือก';
COMMENT ON COLUMN user_insurance_selections.selected_at IS 'เวลาที่เลือกผลิตภัณฑ์นี้';
COMMENT ON COLUMN user_insurance_selections.is_active IS 'สถานะการเลือก (true = กำลังใช้งาน, false = ยกเลิกแล้ว)';
COMMENT ON COLUMN user_insurance_selections.priority IS 'ลำดับความสำคัญ (1 = สูงสุด) ถ้าเลือกหลายตัวใน level เดียวกัน';
COMMENT ON COLUMN user_insurance_selections.notes IS 'หมายเหตุหรือข้อมูลเพิ่มเติม';
COMMENT ON COLUMN user_insurance_selections.deactivated_at IS 'เวลาที่ยกเลิกการเลือก (auto-set เมื่อ is_active = false)';
