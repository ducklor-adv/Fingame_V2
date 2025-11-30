-- ============================================================================
-- Fingrow Database Schema - PostgreSQL Implementation
-- Generated from: datalist_merged_ add_simulation.md
-- ============================================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================================
-- 1. USERS TABLE
-- ============================================================================
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  world_id VARCHAR(10) UNIQUE,                -- YYAAA#### format
  username VARCHAR(255) NOT NULL UNIQUE,
  email VARCHAR(255) UNIQUE,
  phone VARCHAR(50),
  first_name VARCHAR(255),
  last_name VARCHAR(255),
  avatar_url TEXT,
  profile_image_filename VARCHAR(255),
  bio TEXT,
  location JSONB,                             -- {city, country, coordinates}
  preferred_currency VARCHAR(3) DEFAULT 'THB',
  language VARCHAR(10) DEFAULT 'th',
  is_verified BOOLEAN DEFAULT FALSE,
  verification_level INTEGER DEFAULT 0,       -- 0:none, 1:phone, 2:email, 3:worldid, 4:full
  trust_score DECIMAL(10, 2) DEFAULT 0.0,
  total_sales INTEGER DEFAULT 0,
  total_purchases INTEGER DEFAULT 0,

  -- Estimated inventory for simulation
  estimated_inventory_value DECIMAL(15, 2) DEFAULT 0.0,
  estimated_item_count INTEGER DEFAULT 0,

  -- ACF Tree Structure (merged from fingrow_dna)
  run_number INTEGER UNIQUE NOT NULL,
  parent_id UUID REFERENCES users(id) ON DELETE SET NULL,
  child_count INTEGER NOT NULL DEFAULT 0,
  max_children INTEGER NOT NULL DEFAULT 5,
  acf_accepting BOOLEAN NOT NULL DEFAULT TRUE,

  -- Referral/Invite system
  inviter_id UUID REFERENCES users(id) ON DELETE SET NULL,
  invite_code VARCHAR(50) UNIQUE,

  -- ACF Level
  level INTEGER NOT NULL DEFAULT 0,

  -- ACF Registration & User Type
  user_type VARCHAR(50) NOT NULL DEFAULT 'Atta',
  regist_type VARCHAR(50) NOT NULL DEFAULT 'normal',

  -- Finpoint System
  own_finpoint DECIMAL(15, 2) NOT NULL DEFAULT 0,
  total_finpoint DECIMAL(15, 2) NOT NULL DEFAULT 0,
  max_network INTEGER NOT NULL DEFAULT 19531,

  -- Account status
  is_active BOOLEAN DEFAULT TRUE,
  is_suspended BOOLEAN DEFAULT FALSE,
  last_login TIMESTAMP,
  password_hash VARCHAR(255),

  -- Inline address fields
  address_number VARCHAR(50),
  address_street VARCHAR(255),
  address_district VARCHAR(100),
  address_province VARCHAR(100),
  address_postal_code VARCHAR(20),

  -- Timestamps (epoch milliseconds to match ACF code)
  created_at BIGINT DEFAULT (EXTRACT(EPOCH FROM NOW()) * 1000)::BIGINT,
  updated_at BIGINT DEFAULT (EXTRACT(EPOCH FROM NOW()) * 1000)::BIGINT,

  -- Constraints
  CHECK (verification_level >= 0 AND verification_level <= 4),
  CHECK (max_children >= 1 AND max_children <= 5),
  CHECK (level >= 0),
  CHECK (estimated_inventory_value >= 0),
  CHECK (estimated_item_count >= 0)
);

-- Indexes for users table
CREATE INDEX idx_users_world_id ON users(world_id);
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_run_number ON users(run_number);
CREATE INDEX idx_users_parent_id ON users(parent_id);
CREATE INDEX idx_users_inviter_id ON users(inviter_id);
CREATE INDEX idx_users_level ON users(level);
CREATE INDEX idx_users_acf_accepting ON users(acf_accepting) WHERE acf_accepting = TRUE;
CREATE INDEX idx_users_estimated_value ON users(estimated_inventory_value) WHERE estimated_inventory_value > 0;
CREATE INDEX idx_users_created_at ON users(created_at);

-- ============================================================================
-- 2. PRODUCTS TABLE
-- ============================================================================
CREATE TABLE products (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  seller_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

  -- Category
  category VARCHAR(100),
  category_id UUID,

  -- Basic info
  title VARCHAR(500) NOT NULL,
  description TEXT,
  condition VARCHAR(50),

  -- Pricing
  price_wld DECIMAL(15, 8),
  price_local DECIMAL(15, 2) NOT NULL,
  original_price DECIMAL(15, 2),
  currency_code VARCHAR(3) DEFAULT 'THB',

  -- Location & shipping
  location JSONB,
  shipping_options JSONB,
  pickup_available BOOLEAN DEFAULT FALSE,

  -- Attributes
  brand VARCHAR(255),
  model VARCHAR(255),
  year_purchased INTEGER,
  warranty_remaining INTEGER,
  included_accessories JSONB,

  -- Media
  images JSONB,
  videos JSONB,

  -- Stock / flags
  quantity INTEGER DEFAULT 1,
  is_available BOOLEAN DEFAULT TRUE,
  is_featured BOOLEAN DEFAULT FALSE,
  featured_until TIMESTAMP,

  -- Metrics
  community_percentage DECIMAL(5, 2) DEFAULT 2.0,
  amount_fee DECIMAL(15, 2) DEFAULT 0.0,
  view_count INTEGER DEFAULT 0,
  favorite_count INTEGER DEFAULT 0,
  inquiry_count INTEGER DEFAULT 0,

  status VARCHAR(50) DEFAULT 'active',

  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),

  CHECK (price_local >= 0),
  CHECK (quantity >= 0),
  CHECK (community_percentage >= 0 AND community_percentage <= 100)
);

CREATE INDEX idx_products_seller_id ON products(seller_id);
CREATE INDEX idx_products_category ON products(category);
CREATE INDEX idx_products_status ON products(status);
CREATE INDEX idx_products_is_available ON products(is_available) WHERE is_available = TRUE;
CREATE INDEX idx_products_created_at ON products(created_at);

-- ============================================================================
-- 3. ORDERS TABLE
-- ============================================================================
CREATE TABLE orders (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  order_number VARCHAR(50) UNIQUE,

  buyer_id UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
  seller_id UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,

  -- For simple one-product orders
  product_id UUID,
  quantity INTEGER DEFAULT 1,

  -- Financials
  subtotal DECIMAL(15, 2) DEFAULT 0,
  shipping_cost DECIMAL(15, 2) DEFAULT 0,
  tax_amount DECIMAL(15, 2) DEFAULT 0,
  community_fee DECIMAL(15, 2) DEFAULT 0,
  total_amount DECIMAL(15, 2) DEFAULT 0,

  -- WLD / FX
  total_price_wld DECIMAL(15, 8) DEFAULT 0,
  total_price_local DECIMAL(15, 2) DEFAULT 0,
  currency_code VARCHAR(3) DEFAULT 'THB',
  wld_rate DECIMAL(15, 8) DEFAULT 0,
  total_wld DECIMAL(15, 8) DEFAULT 0,

  -- Shipping
  shipping_address JSONB,
  shipping_method VARCHAR(100),
  tracking_number VARCHAR(100),

  -- Notes
  notes TEXT,
  buyer_notes TEXT,
  seller_notes TEXT,
  admin_notes TEXT,

  -- Status
  status VARCHAR(50) DEFAULT 'pending',
  payment_status VARCHAR(50) DEFAULT 'pending',
  order_date TIMESTAMP DEFAULT NOW(),
  confirmed_at TIMESTAMP,
  shipped_at TIMESTAMP,
  delivered_at TIMESTAMP,
  completed_at TIMESTAMP,

  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_orders_buyer_id ON orders(buyer_id);
CREATE INDEX idx_orders_seller_id ON orders(seller_id);
CREATE INDEX idx_orders_status ON orders(status);
CREATE INDEX idx_orders_payment_status ON orders(payment_status);
CREATE INDEX idx_orders_order_date ON orders(order_date);

-- ============================================================================
-- 4. PRODUCT_IMAGES TABLE
-- ============================================================================
CREATE TABLE product_images (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  image_url TEXT NOT NULL,
  is_primary BOOLEAN DEFAULT FALSE,
  sort_order INTEGER DEFAULT 0,
  alt_text VARCHAR(500),
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_product_images_product_id ON product_images(product_id);

-- ============================================================================
-- 5. ORDER_ITEMS TABLE
-- ============================================================================
CREATE TABLE order_items (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  product_id UUID NOT NULL REFERENCES products(id) ON DELETE RESTRICT,
  quantity INTEGER DEFAULT 1,
  unit_price DECIMAL(15, 2) NOT NULL,
  total_price DECIMAL(15, 2) NOT NULL,
  product_title VARCHAR(500),
  product_condition VARCHAR(50),
  product_image TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_order_items_order_id ON order_items(order_id);
CREATE INDEX idx_order_items_product_id ON order_items(product_id);

-- ============================================================================
-- 6. CATEGORIES TABLE
-- ============================================================================
CREATE TABLE categories (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name VARCHAR(255) NOT NULL,
  name_th VARCHAR(255),
  description TEXT,
  icon VARCHAR(255),
  is_active BOOLEAN DEFAULT TRUE,
  sort_order INTEGER DEFAULT 0,
  slug VARCHAR(255),
  parent_id UUID REFERENCES categories(id) ON DELETE SET NULL,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_categories_slug ON categories(slug);
CREATE INDEX idx_categories_parent_id ON categories(parent_id);
CREATE INDEX idx_categories_is_active ON categories(is_active) WHERE is_active = TRUE;

-- ============================================================================
-- 7. REVIEWS TABLE
-- ============================================================================
CREATE TABLE reviews (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

  order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  buyer_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  seller_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

  reviewer_id UUID,
  reviewed_user_id UUID,

  rating INTEGER NOT NULL,
  title VARCHAR(255),
  comment TEXT NOT NULL,
  images JSONB,

  communication_rating INTEGER,
  item_quality_rating INTEGER,
  shipping_rating INTEGER,

  is_verified_purchase BOOLEAN DEFAULT TRUE,
  is_visible BOOLEAN DEFAULT TRUE,

  seller_response TEXT,
  seller_response_date TIMESTAMP,

  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),

  CHECK (rating >= 1 AND rating <= 5),
  CHECK (communication_rating IS NULL OR (communication_rating >= 1 AND communication_rating <= 5)),
  CHECK (item_quality_rating IS NULL OR (item_quality_rating >= 1 AND item_quality_rating <= 5)),
  CHECK (shipping_rating IS NULL OR (shipping_rating >= 1 AND shipping_rating <= 5))
);

CREATE INDEX idx_reviews_product_id ON reviews(product_id);
CREATE INDEX idx_reviews_buyer_id ON reviews(buyer_id);
CREATE INDEX idx_reviews_seller_id ON reviews(seller_id);
CREATE INDEX idx_reviews_rating ON reviews(rating);

-- ============================================================================
-- 8. FAVORITES TABLE
-- ============================================================================
CREATE TABLE favorites (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  created_at TIMESTAMP DEFAULT NOW(),

  UNIQUE(user_id, product_id)
);

CREATE INDEX idx_favorites_user_id ON favorites(user_id);
CREATE INDEX idx_favorites_product_id ON favorites(product_id);

-- ============================================================================
-- 9. CHAT_ROOMS TABLE
-- ============================================================================
CREATE TABLE chat_rooms (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  buyer_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  seller_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  product_id UUID REFERENCES products(id) ON DELETE SET NULL,

  last_message TEXT,
  last_message_at TIMESTAMP,

  current_offer_amount DECIMAL(15, 2),
  current_offer_currency VARCHAR(3),
  offer_status VARCHAR(50) DEFAULT 'none',

  is_active BOOLEAN DEFAULT TRUE,

  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_chat_rooms_buyer_id ON chat_rooms(buyer_id);
CREATE INDEX idx_chat_rooms_seller_id ON chat_rooms(seller_id);
CREATE INDEX idx_chat_rooms_product_id ON chat_rooms(product_id);

-- ============================================================================
-- 10. MESSAGES TABLE
-- ============================================================================
CREATE TABLE messages (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  chat_room_id UUID NOT NULL REFERENCES chat_rooms(id) ON DELETE CASCADE,
  sender_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

  message_type VARCHAR(50) DEFAULT 'text',
  content TEXT,
  images JSONB,

  offer_amount DECIMAL(15, 2),
  offer_currency VARCHAR(3),
  offer_expires_at TIMESTAMP,

  is_read BOOLEAN DEFAULT FALSE,
  read_at TIMESTAMP,
  is_deleted BOOLEAN DEFAULT FALSE,

  created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_messages_chat_room_id ON messages(chat_room_id);
CREATE INDEX idx_messages_sender_id ON messages(sender_id);
CREATE INDEX idx_messages_created_at ON messages(created_at);

-- ============================================================================
-- 11. REFERRALS TABLE
-- ============================================================================
CREATE TABLE referrals (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  referrer_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  referee_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  level INTEGER NOT NULL,

  first_purchase_made BOOLEAN DEFAULT FALSE,
  first_purchase_date TIMESTAMP,

  total_purchases_made INTEGER DEFAULT 0,
  total_purchase_value DECIMAL(15, 2) DEFAULT 0,
  total_commission_earned DECIMAL(15, 2) DEFAULT 0,
  last_commission_date TIMESTAMP,

  created_at TIMESTAMP DEFAULT NOW(),

  CHECK (level >= 1 AND level <= 7)
);

CREATE INDEX idx_referrals_referrer_id ON referrals(referrer_id);
CREATE INDEX idx_referrals_referee_id ON referrals(referee_id);
CREATE INDEX idx_referrals_level ON referrals(level);

-- ============================================================================
-- 12. EARNINGS TABLE
-- ============================================================================
CREATE TABLE earnings (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  source_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

  order_id UUID REFERENCES orders(id) ON DELETE SET NULL,
  source_order_id UUID,

  source_type VARCHAR(100),
  earning_type VARCHAR(100),

  amount_wld DECIMAL(15, 8) NOT NULL,
  amount_local DECIMAL(15, 2) NOT NULL,
  currency_code VARCHAR(3) DEFAULT 'THB',

  level INTEGER,
  percentage DECIMAL(5, 2),
  referral_level INTEGER,
  commission_rate DECIMAL(5, 2),

  status VARCHAR(50) DEFAULT 'pending',
  paid_at TIMESTAMP,
  payment_transaction_id VARCHAR(255),
  description TEXT,

  created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_earnings_user_id ON earnings(user_id);
CREATE INDEX idx_earnings_source_user_id ON earnings(source_user_id);
CREATE INDEX idx_earnings_status ON earnings(status);
CREATE INDEX idx_earnings_created_at ON earnings(created_at);

-- ============================================================================
-- 13. ADDRESSES TABLE
-- ============================================================================
CREATE TABLE addresses (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

  label VARCHAR(50) NOT NULL,
  recipient_name VARCHAR(255) NOT NULL,
  phone VARCHAR(50),

  address_line1 VARCHAR(500) NOT NULL,
  address_line2 VARCHAR(500),
  city VARCHAR(100) NOT NULL,
  state_province VARCHAR(100),
  postal_code VARCHAR(20) NOT NULL,
  country VARCHAR(3) NOT NULL,

  coordinates JSONB,

  is_default BOOLEAN DEFAULT FALSE,
  is_active BOOLEAN DEFAULT TRUE,

  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_addresses_user_id ON addresses(user_id);

-- ============================================================================
-- 14. NOTIFICATIONS TABLE
-- ============================================================================
CREATE TABLE notifications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

  type VARCHAR(50) NOT NULL,
  title VARCHAR(255) NOT NULL,
  body TEXT NOT NULL,
  data JSONB,

  is_read BOOLEAN DEFAULT FALSE,
  read_at TIMESTAMP,

  push_sent BOOLEAN DEFAULT FALSE,
  push_sent_at TIMESTAMP,

  created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_notifications_user_id ON notifications(user_id);
CREATE INDEX idx_notifications_type ON notifications(type);
CREATE INDEX idx_notifications_is_read ON notifications(is_read) WHERE is_read = FALSE;

-- ============================================================================
-- 15. PAYMENT_METHODS TABLE
-- ============================================================================
CREATE TABLE payment_methods (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

  type VARCHAR(50) NOT NULL,
  provider VARCHAR(100),
  account_details JSONB,
  display_name VARCHAR(255),

  is_verified BOOLEAN DEFAULT FALSE,
  is_default BOOLEAN DEFAULT FALSE,
  is_active BOOLEAN DEFAULT TRUE,

  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_payment_methods_user_id ON payment_methods(user_id);

-- ============================================================================
-- 16. SETTINGS TABLE
-- ============================================================================
CREATE TABLE settings (
  key VARCHAR(255) PRIMARY KEY,
  value TEXT,
  description TEXT,
  updated_at TIMESTAMP DEFAULT NOW()
);

-- ============================================================================
-- 17. SIMULATED_FP_TRANSACTIONS TABLE
-- ============================================================================
CREATE TABLE simulated_fp_transactions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

  simulated_tx_type VARCHAR(50) NOT NULL,
  simulated_source_type VARCHAR(100) NOT NULL,
  simulated_source_id VARCHAR(255),

  simulated_base_amount DECIMAL(15, 2) NOT NULL,
  simulated_reverse_rate DECIMAL(5, 4) NOT NULL,

  simulated_generated_fp DECIMAL(15, 2) NOT NULL,
  simulated_system_cut_rate DECIMAL(5, 2) DEFAULT 0.10,
  simulated_system_cut_fp DECIMAL(15, 2) DEFAULT 0.0,
  simulated_self_rate DECIMAL(5, 2) DEFAULT 0.45,
  simulated_self_fp DECIMAL(15, 2) DEFAULT 0.0,
  simulated_network_rate DECIMAL(5, 2) DEFAULT 0.45,
  simulated_network_fp DECIMAL(15, 2) DEFAULT 0.0,
  simulated_upline_depth INTEGER DEFAULT 7,

  simulated_status VARCHAR(50) NOT NULL DEFAULT 'PENDING',
  simulated_error_message TEXT,
  simulated_run_mode VARCHAR(50) DEFAULT 'AUTO',

  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),

  CHECK (simulated_base_amount >= 0),
  CHECK (simulated_reverse_rate >= 0),
  CHECK (simulated_upline_depth >= 1 AND simulated_upline_depth <= 7)
);

CREATE INDEX idx_simulated_fp_transactions_user_id ON simulated_fp_transactions(user_id);
CREATE INDEX idx_simulated_fp_transactions_tx_type ON simulated_fp_transactions(simulated_tx_type);
CREATE INDEX idx_simulated_fp_transactions_status ON simulated_fp_transactions(simulated_status);
CREATE INDEX idx_simulated_fp_transactions_created_at ON simulated_fp_transactions(created_at);

-- ============================================================================
-- 18. SIMULATED_FP_LEDGER TABLE
-- ============================================================================
CREATE TABLE simulated_fp_ledger (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

  simulated_tx_id UUID NOT NULL REFERENCES simulated_fp_transactions(id) ON DELETE CASCADE,

  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  related_user_id UUID REFERENCES users(id) ON DELETE SET NULL,

  level INTEGER,
  simulated_entry_role VARCHAR(50),

  dr_cr VARCHAR(2) NOT NULL,
  simulated_fp_amount DECIMAL(15, 2) NOT NULL,
  simulated_balance_after DECIMAL(15, 2),

  simulated_tx_type VARCHAR(50) NOT NULL,
  simulated_source_type VARCHAR(100),
  simulated_source_id VARCHAR(255),

  simulated_tx_datetime TIMESTAMP,
  simulated_tx_year INTEGER,
  simulated_tx_month INTEGER,
  simulated_tx_day INTEGER,

  created_at TIMESTAMP DEFAULT NOW(),

  CHECK (dr_cr IN ('DR', 'CR')),
  CHECK (simulated_fp_amount >= 0),
  CHECK (level IS NULL OR (level >= 0 AND level <= 6))
);

CREATE INDEX idx_simulated_fp_ledger_tx_id ON simulated_fp_ledger(simulated_tx_id);
CREATE INDEX idx_simulated_fp_ledger_user_id ON simulated_fp_ledger(user_id);
CREATE INDEX idx_simulated_fp_ledger_tx_type ON simulated_fp_ledger(simulated_tx_type);
CREATE INDEX idx_simulated_fp_ledger_dr_cr ON simulated_fp_ledger(dr_cr);
CREATE INDEX idx_simulated_fp_ledger_tx_datetime ON simulated_fp_ledger(simulated_tx_datetime);
CREATE INDEX idx_simulated_fp_ledger_year_month ON simulated_fp_ledger(simulated_tx_year, simulated_tx_month);

-- ============================================================================
-- TRIGGERS FOR updated_at TIMESTAMPS
-- ============================================================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply trigger to tables with updated_at
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_products_updated_at BEFORE UPDATE ON products
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_orders_updated_at BEFORE UPDATE ON orders
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_reviews_updated_at BEFORE UPDATE ON reviews
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_chat_rooms_updated_at BEFORE UPDATE ON chat_rooms
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_addresses_updated_at BEFORE UPDATE ON addresses
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_payment_methods_updated_at BEFORE UPDATE ON payment_methods
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_simulated_fp_transactions_updated_at BEFORE UPDATE ON simulated_fp_transactions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- SEED DATA - SYSTEM ROOT USER
-- ============================================================================

-- Insert system root user (25AAA0000)
INSERT INTO users (
  id,
  world_id,
  username,
  run_number,
  parent_id,
  child_count,
  max_children,
  acf_accepting,
  level,
  user_type,
  regist_type,
  created_at,
  updated_at
) VALUES (
  '00000000-0000-0000-0000-000000000000'::UUID,
  '25AAA0000',
  'system_root',
  0,
  NULL,
  0,
  1,
  TRUE,
  0,
  'System',
  'system',
  (EXTRACT(EPOCH FROM NOW()) * 1000)::BIGINT,
  (EXTRACT(EPOCH FROM NOW()) * 1000)::BIGINT
) ON CONFLICT (run_number) DO NOTHING;

-- ============================================================================
-- HELPFUL VIEWS
-- ============================================================================

-- View: Active users with ACF info
CREATE OR REPLACE VIEW v_active_users_acf AS
SELECT
  u.id,
  u.world_id,
  u.username,
  u.run_number,
  u.parent_id,
  u.level,
  u.child_count,
  u.max_children,
  u.acf_accepting,
  u.own_finpoint,
  u.total_finpoint,
  u.created_at
FROM users u
WHERE u.is_active = TRUE
ORDER BY u.run_number;

-- View: User network summary
CREATE OR REPLACE VIEW v_user_network_summary AS
SELECT
  u.id,
  u.world_id,
  u.username,
  u.run_number,
  u.level,
  u.child_count,
  u.max_children,
  u.acf_accepting,
  COUNT(DISTINCT r.referee_id) as total_referrals,
  COALESCE(SUM(e.amount_local), 0) as total_earnings
FROM users u
LEFT JOIN referrals r ON r.referrer_id = u.id
LEFT JOIN earnings e ON e.user_id = u.id AND e.status = 'paid'
GROUP BY u.id, u.world_id, u.username, u.run_number, u.level,
         u.child_count, u.max_children, u.acf_accepting
ORDER BY u.run_number;

-- View: Simulated FP summary by user
CREATE OR REPLACE VIEW v_simulated_fp_summary AS
SELECT
  u.id as user_id,
  u.world_id,
  u.username,
  COUNT(DISTINCT sft.id) as total_transactions,
  COALESCE(SUM(CASE WHEN sfl.dr_cr = 'DR' THEN sfl.simulated_fp_amount ELSE 0 END), 0) as total_fp_earned,
  COALESCE(SUM(CASE WHEN sfl.dr_cr = 'CR' THEN sfl.simulated_fp_amount ELSE 0 END), 0) as total_fp_spent,
  COALESCE(SUM(CASE WHEN sfl.dr_cr = 'DR' THEN sfl.simulated_fp_amount ELSE -sfl.simulated_fp_amount END), 0) as net_fp_balance
FROM users u
LEFT JOIN simulated_fp_ledger sfl ON sfl.user_id = u.id
LEFT JOIN simulated_fp_transactions sft ON sft.id = sfl.simulated_tx_id
GROUP BY u.id, u.world_id, u.username
ORDER BY net_fp_balance DESC;

-- ============================================================================
-- COMPLETION MESSAGE
-- ============================================================================
DO $$
BEGIN
  RAISE NOTICE '✅ Fingrow Database Schema Created Successfully!';
  RAISE NOTICE '📊 Tables: 18 (including simulated_fp_transactions & simulated_fp_ledger)';
  RAISE NOTICE '🔍 Views: 3 helper views created';
  RAISE NOTICE '🌱 Seed Data: System root user (25AAA0000) inserted';
  RAISE NOTICE '🚀 Database is ready for use!';
END $$;
