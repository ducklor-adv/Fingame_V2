# การวิเคราะห์ฟิลด์ซ้ำซ้อนระหว่าง users และ fingrow_dna

## 🔍 ตรวจสอบฟิลด์ที่ซ้ำกัน

### ตาราง `users` (จาก datalist_merged.md)
```sql
CREATE TABLE users (
  id TEXT PRIMARY KEY,
  world_id TEXT UNIQUE,
  username TEXT NOT NULL UNIQUE,
  email TEXT UNIQUE,
  phone TEXT,
  full_name TEXT,
  avatar_url TEXT,
  profile_image_filename TEXT,
  bio TEXT,
  location TEXT,
  preferred_currency TEXT DEFAULT 'THB',
  language TEXT DEFAULT 'th',
  is_verified INTEGER DEFAULT 0,
  verification_level INTEGER DEFAULT 0,
  trust_score REAL DEFAULT 0.0,
  total_sales INTEGER DEFAULT 0,
  total_purchases INTEGER DEFAULT 0,

  -- Referral / invite system
  invite_code TEXT UNIQUE,
  invitor_id TEXT,                    -- ← ซ้ำ!
  total_invites INTEGER DEFAULT 0,
  active_invites INTEGER DEFAULT 0,

  -- MLM/ACF extended fields
  referrer_id TEXT,                   -- ← ซ้ำ! (alias ของ invitor_id)
  referral_code TEXT,                 -- ← ซ้ำ! (alias ของ invite_code)
  referral_level INTEGER,             -- ← อาจซ้ำ
  total_referrals INTEGER,            -- ← ซ้ำ! (same as total_invites)
  active_referrals INTEGER,           -- ← ซ้ำ! (same as active_invites)

  is_active INTEGER DEFAULT 1,
  is_suspended INTEGER DEFAULT 0,
  last_login TEXT,
  password_hash TEXT,

  -- Inline address fields
  address_number TEXT,
  address_street TEXT,
  address_district TEXT,
  address_province TEXT,
  address_postal_code TEXT,

  -- ACF tree parent id
  parent_id TEXT,                     -- ← ซ้ำ! มีใน fingrow_dna แล้ว

  created_at TEXT DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT DEFAULT CURRENT_TIMESTAMP
);
```

### ตาราง `fingrow_dna`
```sql
CREATE TABLE fingrow_dna (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  run_number INTEGER UNIQUE NOT NULL,
  user_id TEXT NOT NULL UNIQUE,
  user_type TEXT NOT NULL DEFAULT 'Atta',

  -- ACF Tree Structure
  parent_id TEXT,                     -- ← ซ้ำกับ users.parent_id
  child_count INTEGER NOT NULL DEFAULT 0,
  max_children INTEGER NOT NULL DEFAULT 5,
  acf_accepting INTEGER NOT NULL DEFAULT 1,

  -- Referral/Invite
  inviter_id TEXT,                    -- ← ซ้ำกับ users.invitor_id

  -- Level & Timestamps
  level INTEGER NOT NULL DEFAULT 0,
  created_at TEXT DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT DEFAULT CURRENT_TIMESTAMP,

  -- Registration info
  regist_type TEXT NOT NULL DEFAULT 'normal',

  -- Finpoint System
  own_finpoint REAL NOT NULL DEFAULT 0,
  total_finpoint REAL NOT NULL DEFAULT 0,
  max_network INTEGER NOT NULL DEFAULT 19531,

  -- Legacy/Optional fields
  js_file_path TEXT,
  parent_file TEXT
);
```

---

## ⚠️ ฟิลด์ที่ซ้ำซ้อน

| ฟิลด์ | users | fingrow_dna | ควรเก็บที่ไหน? |
|-------|-------|-------------|----------------|
| `parent_id` | ✅ มี | ✅ มี | **fingrow_dna** (ACF-specific) |
| `invitor_id` / `inviter_id` | ✅ มี | ✅ มี | **fingrow_dna** (ACF-specific) |
| `created_at` | ✅ มี | ✅ มี | **ทั้งคู่** (ต่างกัน: user create vs ACF join) |

### ฟิลด์ซ้ำซ้อนใน `users` เอง:
| ฟิลด์ | Alias/Duplicate | ควรทำยังไง? |
|-------|-----------------|-------------|
| `invitor_id` | = `referrer_id` | **ลบ referrer_id** |
| `invite_code` | = `referral_code` | **ลบ referral_code** |
| `total_invites` | = `total_referrals` | **ลบ total_referrals** |
| `active_invites` | = `active_referrals` | **ลบ active_referrals** |

---

## ✅ แนวทางแก้ไข

### 1. ลบฟิลด์ซ้ำซ้อนออกจาก `users`

```sql
CREATE TABLE users (
  id TEXT PRIMARY KEY,
  world_id TEXT UNIQUE,
  username TEXT NOT NULL UNIQUE,
  email TEXT UNIQUE,
  phone TEXT,
  full_name TEXT,
  avatar_url TEXT,
  profile_image_filename TEXT,
  bio TEXT,
  location TEXT,
  preferred_currency TEXT DEFAULT 'THB',
  language TEXT DEFAULT 'th',

  is_verified INTEGER DEFAULT 0,
  verification_level INTEGER DEFAULT 0,
  trust_score REAL DEFAULT 0.0,
  total_sales INTEGER DEFAULT 0,
  total_purchases INTEGER DEFAULT 0,

  -- ❌ ลบฟิลด์เหล่านี้ออก (ย้ายไป fingrow_dna)
  -- invite_code TEXT UNIQUE,
  -- invitor_id TEXT,
  -- total_invites INTEGER DEFAULT 0,
  -- active_invites INTEGER DEFAULT 0,
  -- referrer_id TEXT,
  -- referral_code TEXT,
  -- referral_level INTEGER,
  -- total_referrals INTEGER,
  -- active_referrals INTEGER,
  -- parent_id TEXT,

  is_active INTEGER DEFAULT 1,
  is_suspended INTEGER DEFAULT 0,
  last_login TEXT,
  password_hash TEXT,

  -- Address fields
  address_number TEXT,
  address_street TEXT,
  address_district TEXT,
  address_province TEXT,
  address_postal_code TEXT,

  created_at TEXT DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT DEFAULT CURRENT_TIMESTAMP
);
```

### 2. เพิ่ม `invite_code` ใน `fingrow_dna`

```sql
CREATE TABLE fingrow_dna (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  run_number INTEGER UNIQUE NOT NULL,
  user_id TEXT NOT NULL UNIQUE REFERENCES users(id),
  user_type TEXT NOT NULL DEFAULT 'Atta',

  -- ACF Tree Structure
  parent_id TEXT,
  child_count INTEGER NOT NULL DEFAULT 0,
  max_children INTEGER NOT NULL DEFAULT 5,
  acf_accepting INTEGER NOT NULL DEFAULT 1,

  -- Referral/Invite
  inviter_id TEXT,
  invite_code TEXT UNIQUE,                -- ← เพิ่มตรงนี้ (ย้ายมาจาก users)

  -- Level & Timestamps
  level INTEGER NOT NULL DEFAULT 0,
  created_at TEXT DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT DEFAULT CURRENT_TIMESTAMP,

  -- Registration info
  regist_type TEXT NOT NULL DEFAULT 'normal',

  -- Finpoint System
  own_finpoint REAL NOT NULL DEFAULT 0,
  total_finpoint REAL NOT NULL DEFAULT 0,
  max_network INTEGER NOT NULL DEFAULT 19531,

  -- Legacy/Optional fields
  js_file_path TEXT,
  parent_file TEXT
);
```

---

## 🎯 แนวคิด: แยกความรับผิดชอบ (Separation of Concerns)

### `users` = ข้อมูลผู้ใช้ทั่วไป (Marketplace)
- ข้อมูลส่วนตัว (username, email, phone, full_name)
- การยืนยันตัวตน (is_verified, verification_level)
- ประวัติการซื้อขาย (total_sales, total_purchases, trust_score)
- ที่อยู่ (address fields)
- Authentication (password_hash, last_login)

### `fingrow_dna` = ข้อมูล ACF เฉพาะ
- ACF Tree structure (parent_id, child_count, level)
- Referral system (inviter_id, invite_code)
- ACF settings (acf_accepting, max_children)
- Finpoint system (own_finpoint, total_finpoint)
- Run order (run_number)

---

## 💡 ข้อดีของการแยก

1. **ไม่ซ้ำซ้อน** - ฟิลด์มีที่เดียว
2. **Flexible** - User ที่ไม่เข้า ACF ไม่มี record ใน fingrow_dna
3. **ชัดเจน** - แยก concern ระหว่าง marketplace และ ACF
4. **ประสิทธิภาพ** - ตาราง users เบาลง

---

## ❓ ฟิลด์ที่ยังไม่แน่ใจ

### `invite_code` ควรอยู่ที่ไหน?

**ตัวเลือก A: อยู่ใน `users`**
- ใช้สำหรับ referral ทั่วไป (ไม่ใช่แค่ ACF)
- User ทุกคนมี invite code (แม้ไม่เข้า ACF)

**ตัวเลือก B: อยู่ใน `fingrow_dna`** (แนะนำ)
- ใช้เฉพาะใน ACF system
- เฉพาะคนที่เข้า ACF ถึงมี invite code

---

## 📝 สรุปการแก้ไข

### ลบออกจาก `users`:
- ❌ `parent_id` (ย้ายไป fingrow_dna)
- ❌ `invitor_id` (ย้ายไป fingrow_dna เป็น inviter_id)
- ❌ `invite_code` (ย้ายไป fingrow_dna)
- ❌ `referrer_id` (ลบทิ้ง - duplicate ของ invitor_id)
- ❌ `referral_code` (ลบทิ้ง - duplicate ของ invite_code)
- ❌ `referral_level` (ลบทิ้ง - มี level ใน fingrow_dna แล้ว)
- ❌ `total_invites` (ลบทิ้ง - คำนวณจาก fingrow_dna)
- ❌ `active_invites` (ลบทิ้ง - คำนวณจาก fingrow_dna)
- ❌ `total_referrals` (ลบทิ้ง - duplicate)
- ❌ `active_referrals` (ลบทิ้ง - duplicate)

### เพิ่มใน `fingrow_dna`:
- ✅ `invite_code` (ย้ายมาจาก users)

---

## 🚀 ต้องการให้แก้ไข datalist_merged.md ตามนี้ไหมครับ?
