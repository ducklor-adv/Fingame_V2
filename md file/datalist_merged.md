
# Fingrow Database Schema - Merged (SQLite + PostgreSQL)
# File: datalist_merged.md
#
# NOTE:
# - This schema is SQLite-oriented (TEXT / INTEGER / REAL), extended with fields that only existed in PostgreSQL.
# - An AI coding agent can use these CREATE TABLE templates as a base and adjust types/constraints for PostgreSQL if needed.
# - Primary keys are TEXT (UUID string) except where noted.

-----------------------------
## 1. users

```sql
CREATE TABLE users (
  id TEXT PRIMARY KEY,                       -- UUID string
  world_id TEXT UNIQUE,                      -- World ID for authentication (YYAAA#### format)
  username TEXT NOT NULL UNIQUE,             -- Unique username
  email TEXT UNIQUE,
  phone TEXT,
  first_name TEXT,                           -- ชื่อจริง
  last_name TEXT,                            -- นามสกุล
  avatar_url TEXT,                           -- Remote profile image URL
  profile_image_filename TEXT,               -- Local profile image filename
  bio TEXT,
  location TEXT,                             -- JSON string {city,country,coordinates}
  preferred_currency TEXT DEFAULT 'THB',     -- ISO currency code
  language TEXT DEFAULT 'th',                -- Language code
  is_verified INTEGER DEFAULT 0,             -- Boolean 0/1
  verification_level INTEGER DEFAULT 0,      -- 0:none, 1:phone, 2:email, 3:worldid, 4:full
  trust_score REAL DEFAULT 0.0,
  total_sales INTEGER DEFAULT 0,
  total_purchases INTEGER DEFAULT 0,

  -- Estimated inventory for simulation
  estimated_inventory_value REAL DEFAULT 0.0,  -- มูลค่าสินค้าที่คาดว่าจะนำมาขาย (THB)
  estimated_item_count INTEGER DEFAULT 0,      -- จำนวนชิ้นที่คาดว่าจะนำมาขาย

  -- ACF Tree Structure (merged from fingrow_dna)
  run_number INTEGER UNIQUE NOT NULL,        -- System run number (matches ACF run_number)
  parent_id TEXT,                            -- FK -> users(id), ACF parent
  child_count INTEGER NOT NULL DEFAULT 0,    -- จำนวนลูกปัจจุบัน
  max_children INTEGER NOT NULL DEFAULT 5,   -- จำนวนลูกสูงสุด
  acf_accepting INTEGER NOT NULL DEFAULT 1,  -- เปิดรับ ACF (1=true, 0=false)

  -- Referral/Invite system
  inviter_id TEXT,                           -- FK -> users(id), ผู้เชิญ
  invite_code TEXT UNIQUE,                   -- รหัสเชิญของ user คนนี้

  -- ACF Level
  level INTEGER NOT NULL DEFAULT 0,          -- ระดับใน tree

  -- ACF Registration & User Type
  user_type TEXT NOT NULL DEFAULT 'Atta',    -- User type in ACF system
  regist_type TEXT NOT NULL DEFAULT 'normal',

  -- Finpoint System
  own_finpoint REAL NOT NULL DEFAULT 0,
  total_finpoint REAL NOT NULL DEFAULT 0,
  max_network INTEGER NOT NULL DEFAULT 19531, -- MAX_NETWORK constant (5^7-1)/4

  is_active INTEGER DEFAULT 1,               -- Account active
  is_suspended INTEGER DEFAULT 0,            -- Suspended flag
  last_login TEXT,                           -- ISO timestamp
  password_hash TEXT,                        -- Bcrypt hash

  -- Inline address fields
  address_number TEXT,
  address_street TEXT,
  address_district TEXT,
  address_province TEXT,
  address_postal_code TEXT,

  created_at BIGINT,                         -- Epoch milliseconds (matches ACF getNow())
  updated_at BIGINT                          -- Epoch milliseconds
);
```

-----------------------------
## 2. products

```sql
CREATE TABLE products (
  id TEXT PRIMARY KEY,                       -- Product ID (UUID string)
  seller_id TEXT NOT NULL,                   -- FK -> users(id)

  -- Category handling (SQLite + PostgreSQL)
  category TEXT,                             -- Simple category name / slug
  category_id TEXT,                          -- FK -> categories(id) if using full category table

  title TEXT NOT NULL,
  description TEXT,
  condition TEXT,                            -- 'ใหม่', 'ดีมาก', 'ดี', 'ปานกลาง', 'เก่า'

  -- Pricing
  price_wld REAL,                            -- Price in WLD (optional)
  price_local REAL NOT NULL,                 -- Price in local currency
  original_price REAL,                       -- Original retail price
  currency_code TEXT DEFAULT 'THB',

  -- Location & shipping
  location TEXT,                             -- JSON string
  shipping_options TEXT,                     -- JSON string
  pickup_available INTEGER DEFAULT 0,        -- 0/1

  -- Attributes
  brand TEXT,
  model TEXT,
  year_purchased INTEGER,
  warranty_remaining INTEGER,                -- Months
  included_accessories TEXT,                 -- JSON array string

  -- Media
  images TEXT,                               -- JSON array of image URLs
  videos TEXT,                               -- JSON array of video URLs

  -- Stock / flags
  quantity INTEGER DEFAULT 1,
  is_available INTEGER DEFAULT 1,
  is_featured INTEGER DEFAULT 0,
  featured_until TEXT,                       -- ISO timestamp

  -- Metrics
  community_percentage REAL DEFAULT 2.0,
  amount_fee REAL DEFAULT 0.0,
  view_count INTEGER DEFAULT 0,
  favorite_count INTEGER DEFAULT 0,
  inquiry_count INTEGER DEFAULT 0,

  status TEXT DEFAULT 'active',              -- active, sold, suspended, deleted

  created_at TEXT DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT DEFAULT CURRENT_TIMESTAMP
);
```

-----------------------------
## 3. orders

```sql
CREATE TABLE orders (
  id TEXT PRIMARY KEY,                       -- Order ID (UUID string)
  order_number TEXT UNIQUE,                  -- Human-readable order code

  buyer_id TEXT NOT NULL,                    -- FK -> users(id)
  seller_id TEXT NOT NULL,                   -- FK -> users(id)

  -- For simple one-product orders (SQLite)
  product_id TEXT,
  quantity INTEGER DEFAULT 1,

  -- Financials
  subtotal REAL DEFAULT 0,
  shipping_cost REAL DEFAULT 0,
  tax_amount REAL DEFAULT 0,
  community_fee REAL DEFAULT 0,
  total_amount REAL DEFAULT 0,

  -- WLD / FX
  total_price_wld REAL DEFAULT 0,
  total_price_local REAL DEFAULT 0,
  currency_code TEXT DEFAULT 'THB',
  wld_rate REAL DEFAULT 0,
  total_wld REAL DEFAULT 0,

  -- Shipping
  shipping_address TEXT,                     -- JSON string
  shipping_method TEXT,
  tracking_number TEXT,

  -- Notes
  notes TEXT,                                -- General notes
  buyer_notes TEXT,
  seller_notes TEXT,
  admin_notes TEXT,

  -- Status timestamps
  status TEXT DEFAULT 'pending',             -- pending, confirmed, shipped, delivered, completed, cancelled, disputed
  payment_status TEXT DEFAULT 'pending',     -- pending, paid, failed, refunded
  order_date TEXT DEFAULT CURRENT_TIMESTAMP,
  confirmed_at TEXT,
  shipped_at TEXT,
  delivered_at TEXT,
  completed_at TEXT,

  created_at TEXT DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT DEFAULT CURRENT_TIMESTAMP
);
```

-----------------------------
## 4. product_images

```sql
CREATE TABLE product_images (
  id TEXT PRIMARY KEY,                       -- Image ID (UUID string)
  product_id TEXT NOT NULL,                  -- FK -> products(id)
  image_url TEXT NOT NULL,
  is_primary INTEGER DEFAULT 0,              -- 0/1
  sort_order INTEGER DEFAULT 0,
  alt_text TEXT,
  created_at TEXT DEFAULT CURRENT_TIMESTAMP
);
```

-----------------------------
## 5. order_items

```sql
CREATE TABLE order_items (
  id TEXT PRIMARY KEY,                       -- Order item ID (UUID string)
  order_id TEXT NOT NULL,                    -- FK -> orders(id)
  product_id TEXT NOT NULL,                  -- FK -> products(id)
  quantity INTEGER DEFAULT 1,
  unit_price REAL NOT NULL,
  total_price REAL NOT NULL,
  product_title TEXT,                        -- Snapshot at time of order
  product_condition TEXT,
  product_image TEXT,
  created_at TEXT DEFAULT CURRENT_TIMESTAMP
);
```

-----------------------------
## 6. categories

```sql
CREATE TABLE categories (
  id TEXT PRIMARY KEY,                       -- Category ID (UUID string or slug)
  name TEXT NOT NULL,
  name_th TEXT,
  description TEXT,
  icon TEXT,
  is_active INTEGER DEFAULT 1,
  sort_order INTEGER DEFAULT 0,
  slug TEXT,                                 -- URL-friendly slug
  parent_id TEXT,                            -- FK -> categories(id) for hierarchy
  created_at TEXT DEFAULT CURRENT_TIMESTAMP
);
```

-----------------------------
## 7. reviews

```sql
CREATE TABLE reviews (
  id TEXT PRIMARY KEY,                       -- Review ID (UUID string)

  -- Order & user linkage
  order_id TEXT NOT NULL,                    -- FK -> orders(id)
  product_id TEXT NOT NULL,                  -- FK -> products(id)
  buyer_id TEXT NOT NULL,                    -- Reviewer (buyer) FK -> users(id)
  seller_id TEXT NOT NULL,                   -- Reviewed seller FK -> users(id)

  -- Extended fields from PostgreSQL
  reviewer_id TEXT,                          -- Same as buyer_id, kept for compatibility
  reviewed_user_id TEXT,                     -- Same as seller_id, or other user

  rating INTEGER NOT NULL,                   -- 1–5
  title TEXT,
  comment TEXT NOT NULL,
  images TEXT,                               -- JSON array of image URLs

  communication_rating INTEGER,
  item_quality_rating INTEGER,
  shipping_rating INTEGER,

  is_verified_purchase INTEGER DEFAULT 1,    -- 0/1
  is_visible INTEGER DEFAULT 1,              -- 0/1

  seller_response TEXT,
  seller_response_date TEXT,

  created_at TEXT DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT DEFAULT CURRENT_TIMESTAMP
);
```

-----------------------------
## 8. favorites

```sql
CREATE TABLE favorites (
  id TEXT PRIMARY KEY,                       -- Favorite ID (UUID string)
  user_id TEXT NOT NULL,                     -- FK -> users(id)
  product_id TEXT NOT NULL,                  -- FK -> products(id)
  created_at TEXT DEFAULT CURRENT_TIMESTAMP
);
```

-----------------------------
## 9. chat_rooms

```sql
CREATE TABLE chat_rooms (
  id TEXT PRIMARY KEY,                       -- Chat room ID (UUID string)
  buyer_id TEXT NOT NULL,                    -- FK -> users(id)
  seller_id TEXT NOT NULL,                   -- FK -> users(id)
  product_id TEXT,                           -- FK -> products(id)

  -- Simple chat data (SQLite)
  last_message TEXT,
  last_message_at TEXT,

  -- Offer system (from PostgreSQL)
  current_offer_amount REAL,
  current_offer_currency TEXT,
  offer_status TEXT DEFAULT 'none',          -- none, pending, accepted, rejected, countered

  is_active INTEGER DEFAULT 1,               -- 0/1

  created_at TEXT DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT DEFAULT CURRENT_TIMESTAMP
);
```

-----------------------------
## 10. messages

```sql
CREATE TABLE messages (
  id TEXT PRIMARY KEY,                       -- Message ID (UUID string)
  chat_room_id TEXT NOT NULL,                -- FK -> chat_rooms(id)
  sender_id TEXT NOT NULL,                   -- FK -> users(id)

  message_type TEXT DEFAULT 'text',          -- text, image, offer, system
  content TEXT,
  images TEXT,                               -- JSON array (for image messages)

  -- Offer fields (from PostgreSQL)
  offer_amount REAL,
  offer_currency TEXT,
  offer_expires_at TEXT,

  is_read INTEGER DEFAULT 0,
  read_at TEXT,
  is_deleted INTEGER DEFAULT 0,

  created_at TEXT DEFAULT CURRENT_TIMESTAMP
);
```

-----------------------------
## 11. referrals

```sql
CREATE TABLE referrals (
  id TEXT PRIMARY KEY,                       -- Referral ID (UUID string)
  referrer_id TEXT NOT NULL,                 -- FK -> users(id), who referred
  referee_id TEXT NOT NULL,                  -- FK -> users(id), who was referred
  level INTEGER NOT NULL,                    -- MLM level (1–7)

  first_purchase_made INTEGER DEFAULT 0,     -- 0/1
  first_purchase_date TEXT,

  total_purchases_made INTEGER DEFAULT 0,
  total_purchase_value REAL DEFAULT 0,
  total_commission_earned REAL DEFAULT 0,    -- In WLD or local as chosen
  last_commission_date TEXT,

  created_at TEXT DEFAULT CURRENT_TIMESTAMP
);
```

-----------------------------
## 12. earnings

```sql
CREATE TABLE earnings (
  id TEXT PRIMARY KEY,                       -- Earning ID (UUID string)
  user_id TEXT NOT NULL,                     -- Recipient FK -> users(id)
  source_user_id TEXT NOT NULL,              -- Who generated earning FK -> users(id)

  -- Links to transactions / orders
  order_id TEXT,                             -- FK -> orders(id)
  source_order_id TEXT,                      -- Alias or additional ref

  -- Type fields
  source_type TEXT,                          -- Generic source type (SQLite)
  earning_type TEXT,                         -- referral_commission, community_share, direct_sale

  -- Amounts
  amount_wld REAL NOT NULL,
  amount_local REAL NOT NULL,
  currency_code TEXT DEFAULT 'THB',

  -- MLM info
  level INTEGER,
  percentage REAL,
  referral_level INTEGER,
  commission_rate REAL,

  -- Status / payment tracking
  status TEXT DEFAULT 'pending',             -- pending, confirmed, paid, cancelled
  paid_at TEXT,
  payment_transaction_id TEXT,
  description TEXT,

  created_at TEXT DEFAULT CURRENT_TIMESTAMP
);
```

-----------------------------
## 13. addresses

```sql
CREATE TABLE addresses (
  id TEXT PRIMARY KEY,                       -- Address ID (UUID string)
  user_id TEXT NOT NULL,                     -- FK -> users(id)

  label TEXT NOT NULL,                       -- 'Home', 'Work', etc.
  recipient_name TEXT NOT NULL,
  phone TEXT,

  address_line1 TEXT NOT NULL,
  address_line2 TEXT,
  city TEXT NOT NULL,
  state_province TEXT,
  postal_code TEXT NOT NULL,
  country TEXT NOT NULL,                     -- ISO country code

  coordinates TEXT,                          -- JSON {lat,lng}

  is_default INTEGER DEFAULT 0,
  is_active INTEGER DEFAULT 1,

  created_at TEXT DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT DEFAULT CURRENT_TIMESTAMP
);
```

-----------------------------
## 14. notifications

```sql
CREATE TABLE notifications (
  id TEXT PRIMARY KEY,                       -- Notification ID (UUID string)
  user_id TEXT NOT NULL,                     -- FK -> users(id)

  type TEXT NOT NULL,                        -- order_update, message, earning, system, promotion
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  data TEXT,                                 -- JSON payload

  is_read INTEGER DEFAULT 0,
  read_at TEXT,

  push_sent INTEGER DEFAULT 0,               -- 0/1
  push_sent_at TEXT,

  created_at TEXT DEFAULT CURRENT_TIMESTAMP
);
```

-----------------------------
## 15. payment_methods

```sql
CREATE TABLE payment_methods (
  id TEXT PRIMARY KEY,                       -- Payment method ID (UUID string)
  user_id TEXT NOT NULL,                     -- FK -> users(id)

  type TEXT NOT NULL,                        -- worldcoin, bank_transfer, credit_card, etc.
  provider TEXT,
  account_details TEXT,                      -- JSON/encrypted data
  display_name TEXT,

  is_verified INTEGER DEFAULT 0,
  is_default INTEGER DEFAULT 0,
  is_active INTEGER DEFAULT 1,

  created_at TEXT DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT DEFAULT CURRENT_TIMESTAMP
);
```

-----------------------------
## 16. settings

```sql
CREATE TABLE settings (
  key TEXT PRIMARY KEY,                      -- Setting key
  value TEXT,
  description TEXT,
  updated_at TEXT DEFAULT CURRENT_TIMESTAMP
);
```

-----------------------------
## 17. ~~fingrow_dna~~ (MERGED INTO users TABLE)

**NOTE:** ตาราง `fingrow_dna` ถูกรวมเข้ากับตาราง `users` แล้ว
เนื่องจากทุกคน User ต้องเข้า ACF 100%

ฟิลด์ทั้งหมดจาก `fingrow_dna` ถูกย้ายไปอยู่ในตาราง `users` ดังนี้:
- `run_number` → `users.run_number`
- `parent_id` → `users.parent_id`
- `child_count` → `users.child_count`
- `max_children` → `users.max_children`
- `acf_accepting` → `users.acf_accepting`
- `inviter_id` → `users.inviter_id`
- `invite_code` → `users.invite_code`
- `level` → `users.level`
- `user_type` → `users.user_type`
- `regist_type` → `users.regist_type`
- `own_finpoint` → `users.own_finpoint`
- `total_finpoint` → `users.total_finpoint`
- `max_network` → `users.max_network`
