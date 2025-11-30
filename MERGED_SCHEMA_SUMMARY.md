# Merged Schema Summary - รวม fingrow_dna เข้ากับ users

## ✅ การเปลี่ยนแปลงที่ทำแล้ว

### สาเหตุ: ทุกคนต้องเข้า ACF 100%

เนื่องจากทุก User ต้องเข้าร่วม ACF ไม่มีข้อยกเว้น → **รวมตารางจะง่ายกว่า**

---

## 📊 โครงสร้างหลังรวม

### ตาราง users (รวม ACF fields)

```sql
CREATE TABLE users (
  -- ข้อมูลพื้นฐาน
  id TEXT PRIMARY KEY,                       -- UUID string
  world_id TEXT UNIQUE,                      -- YYAAA#### format
  username TEXT NOT NULL UNIQUE,
  email TEXT UNIQUE,
  phone TEXT,
  first_name TEXT,                           -- ชื่อจริง
  last_name TEXT,                            -- นามสกุล
  avatar_url TEXT,
  profile_image_filename TEXT,
  bio TEXT,
  location TEXT,
  preferred_currency TEXT DEFAULT 'THB',
  language TEXT DEFAULT 'th',

  -- การยืนยันตัวตน & Trust
  is_verified INTEGER DEFAULT 0,
  verification_level INTEGER DEFAULT 0,
  trust_score REAL DEFAULT 0.0,
  total_sales INTEGER DEFAULT 0,
  total_purchases INTEGER DEFAULT 0,

  -- ACF Tree Structure (รวมจาก fingrow_dna)
  run_number INTEGER UNIQUE NOT NULL,        -- System run number
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

  -- Account Status
  is_active INTEGER DEFAULT 1,
  is_suspended INTEGER DEFAULT 0,
  last_login TEXT,
  password_hash TEXT,

  -- Address
  address_number TEXT,
  address_street TEXT,
  address_district TEXT,
  address_province TEXT,
  address_postal_code TEXT,

  created_at TEXT DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT DEFAULT CURRENT_TIMESTAMP
);
```

---

## 🎯 ข้อดีของการรวม

### 1. ✅ ง่ายกว่า
- Query ตรงไม่ต้อง JOIN
- จัดการตารางเดียว
- Code น้อยกว่า

### 2. ✅ เร็วกว่า
- ไม่ต้อง JOIN (เล็กน้อย)
- Index ตรงไปตรงมา

### 3. ✅ ไม่เสียพื้นที่
- ทุกคนมีข้อมูล ACF อยู่แล้ว
- ไม่มีฟิลด์ NULL ที่เปลืองที่

### 4. ✅ เหมาะกับ Business Logic
- ทุกคนต้องเข้า ACF 100%
- ไม่มี edge case

---

## 🔄 การ Query ข้อมูล

### Query ACF User (ง่ายมาก!)

```sql
-- ดึงข้อมูล ACF User
SELECT
  id,
  username,
  run_number,
  parent_id,
  child_count,
  max_children,
  acf_accepting,
  inviter_id,
  invite_code,
  level,
  own_finpoint,
  total_finpoint
FROM users
WHERE id = 'xxx';
```

**ไม่ต้อง JOIN เลย!** 🎉

### Query ลูก/parent

```sql
-- ดึงลูกทั้งหมด
SELECT * FROM users WHERE parent_id = 'parent-uuid';

-- ดึง parent
SELECT * FROM users WHERE id = (SELECT parent_id FROM users WHERE id = 'child-uuid');
```

### คำนวณ Network Size

```sql
-- นับ subtree (recursive CTE)
WITH RECURSIVE subtree AS (
  SELECT id FROM users WHERE id = 'root-uuid'
  UNION ALL
  SELECT u.id FROM users u
  INNER JOIN subtree s ON u.parent_id = s.id
)
SELECT COUNT(*) as network_size FROM subtree;
```

---

## ✅ Checklist: ACF Fields

| ACF Field | Database Location | Status |
|-----------|-------------------|--------|
| `id` | `users.id` | ✅ |
| `run_number` | `users.run_number` | ✅ |
| `parent_id` | `users.parent_id` | ✅ |
| `child_count` | `users.child_count` | ✅ |
| `max_children` | `users.max_children` | ✅ |
| `acf_accepting` | `users.acf_accepting` | ✅ |
| `inviter_id` | `users.inviter_id` | ✅ |
| `invite_code` | `users.invite_code` | ✅ |
| `created_at` | `users.created_at` | ✅ |
| `level` | `users.level` | ✅ |

**สรุป: ครบทุกฟิลด์!** ✅

---

## 📝 Migration Notes

### จาก Schema เดิม (แยกตาราง)

ถ้าคุณมีข้อมูลใน `fingrow_dna` อยู่แล้ว ใช้คำสั่งนี้ Migrate:

```sql
-- PostgreSQL Migration
ALTER TABLE users
ADD COLUMN run_number INTEGER UNIQUE,
ADD COLUMN parent_id TEXT,
ADD COLUMN child_count INTEGER NOT NULL DEFAULT 0,
ADD COLUMN max_children INTEGER NOT NULL DEFAULT 5,
ADD COLUMN acf_accepting BOOLEAN NOT NULL DEFAULT TRUE,
ADD COLUMN level INTEGER NOT NULL DEFAULT 0,
ADD COLUMN user_type TEXT NOT NULL DEFAULT 'Atta',
ADD COLUMN regist_type TEXT NOT NULL DEFAULT 'normal',
ADD COLUMN own_finpoint DECIMAL NOT NULL DEFAULT 0,
ADD COLUMN total_finpoint DECIMAL NOT NULL DEFAULT 0,
ADD COLUMN max_network INTEGER NOT NULL DEFAULT 19531;

-- Copy data from fingrow_dna to users
UPDATE users u
SET
  run_number = dna.run_number,
  parent_id = dna.parent_id,
  child_count = dna.child_count,
  max_children = dna.max_children,
  acf_accepting = dna.acf_accepting,
  level = dna.level,
  user_type = dna.user_type,
  regist_type = dna.regist_type,
  own_finpoint = dna.own_finpoint,
  total_finpoint = dna.total_finpoint,
  max_network = dna.max_network
FROM fingrow_dna dna
WHERE u.id = dna.user_id;

-- Drop old table
DROP TABLE fingrow_dna;
```

---

## 🚀 พร้อมสร้าง PostgreSQL Init Script!

Schema สะอาด ไม่ซับซ้อน พร้อมใช้งานแล้วครับ

ตารางเดียว จบ! 💪
