# Schema Cleanup Summary - ลบฟิลด์ซ้ำซ้อน

## ✅ การเปลี่ยนแปลงที่ทำแล้ว

### ตาราง `users` - ลบฟิลด์ที่ซ้ำซ้อน

**ฟิลด์ที่ลบออก:**
- ❌ `invite_code` → ย้ายไป `fingrow_dna`
- ❌ `invitor_id` → ย้ายไป `fingrow_dna` (เป็น `inviter_id`)
- ❌ `total_invites` → ลบทิ้ง (คำนวณได้จาก fingrow_dna)
- ❌ `active_invites` → ลบทิ้ง (คำนวณได้จาก fingrow_dna)
- ❌ `referrer_id` → ลบทิ้ง (duplicate ของ invitor_id)
- ❌ `referral_code` → ลบทิ้ง (duplicate ของ invite_code)
- ❌ `referral_level` → ลบทิ้ง (มี level ใน fingrow_dna)
- ❌ `total_referrals` → ลบทิ้ง (duplicate ของ total_invites)
- ❌ `active_referrals` → ลบทิ้ง (duplicate ของ active_invites)
- ❌ `parent_id` → ย้ายไป `fingrow_dna`

**ผลลัพธ์:**
ตาราง `users` เหลือเฉพาะข้อมูล **Marketplace** ล้วนๆ:
- ข้อมูลส่วนตัว (username, email, phone, full_name, bio)
- การยืนยันตัวตน (is_verified, verification_level)
- ประวัติการซื้อขาย (total_sales, total_purchases, trust_score)
- ที่อยู่ (address fields)
- Authentication (password_hash, last_login, is_active)

---

### ตาราง `fingrow_dna` - รวมฟิลด์ ACF ทั้งหมด

**ฟิลด์ที่เพิ่มเข้ามา:**
- ✅ `invite_code` → ย้ายมาจาก `users`

**ฟิลด์ที่มีอยู่แล้ว:**
- ✅ `parent_id` (ACF tree parent)
- ✅ `inviter_id` (ไม่ใช้ invitor อีกต่อไป)
- ✅ `child_count`, `max_children`, `acf_accepting`
- ✅ `level`, `run_number`
- ✅ `own_finpoint`, `total_finpoint`

**ผลลัพธ์:**
ตาราง `fingrow_dna` รวมข้อมูล **ACF/Referral** ทั้งหมด

---

## 📊 โครงสร้างหลังแก้ไข

### ตาราง users (Marketplace Only)

```sql
CREATE TABLE users (
  id TEXT PRIMARY KEY,                       -- UUID
  world_id TEXT UNIQUE,                      -- YYAAA#### format
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

  is_active INTEGER DEFAULT 1,
  is_suspended INTEGER DEFAULT 0,
  last_login TEXT,
  password_hash TEXT,

  address_number TEXT,
  address_street TEXT,
  address_district TEXT,
  address_province TEXT,
  address_postal_code TEXT,

  created_at TEXT DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT DEFAULT CURRENT_TIMESTAMP
);
```

### ตาราง fingrow_dna (ACF Only)

```sql
CREATE TABLE fingrow_dna (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  run_number INTEGER UNIQUE NOT NULL,

  user_id TEXT NOT NULL UNIQUE REFERENCES users(id),
  user_type TEXT NOT NULL DEFAULT 'Atta',

  -- ACF Tree
  parent_id TEXT,
  child_count INTEGER NOT NULL DEFAULT 0,
  max_children INTEGER NOT NULL DEFAULT 5,
  acf_accepting INTEGER NOT NULL DEFAULT 1,

  -- Referral/Invite
  inviter_id TEXT,
  invite_code TEXT UNIQUE,

  -- Level & Timestamps
  level INTEGER NOT NULL DEFAULT 0,
  created_at TEXT DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT DEFAULT CURRENT_TIMESTAMP,

  -- Registration
  regist_type TEXT NOT NULL DEFAULT 'normal',

  -- Finpoint
  own_finpoint REAL NOT NULL DEFAULT 0,
  total_finpoint REAL NOT NULL DEFAULT 0,
  max_network INTEGER NOT NULL DEFAULT 19531,

  -- Legacy
  js_file_path TEXT,
  parent_file TEXT
);
```

---

## 🎯 ประโยชน์ของการแก้ไข

### 1. ไม่มีฟิลด์ซ้ำซ้อน
- ข้อมูลมีที่เดียว (Single Source of Truth)
- ไม่เกิด data inconsistency

### 2. แยก Concerns ชัดเจน
- `users` = Marketplace data
- `fingrow_dna` = ACF/Referral data

### 3. Flexible
- User ที่ไม่เข้า ACF → ไม่มี record ใน `fingrow_dna`
- ประหยัดพื้นที่

### 4. ง่ายต่อการ Maintain
- แก้ ACF → แก้แค่ `fingrow_dna`
- แก้ Marketplace → แก้แค่ `users`

---

## 🔄 การ Query ข้อมูล

### ดึงข้อมูล User ทั่วไป (ไม่ต้อง JOIN)

```sql
SELECT * FROM users WHERE username = 'john';
```

### ดึงข้อมูล ACF User (ต้อง JOIN)

```sql
SELECT
  u.world_id as userId,
  u.username,
  dna.run_number as runNumber,
  dna.parent_id as parentId,
  dna.child_count as childCount,
  dna.max_children as maxChildren,
  dna.acf_accepting as acfAccepting,
  dna.inviter_id as inviterId,
  dna.invite_code as inviteCode,
  dna.level
FROM users u
INNER JOIN fingrow_dna dna ON u.id = dna.user_id
WHERE u.world_id = '25AAA0001';
```

### คำนวณ total_invites (แทนฟิลด์เก่า)

```sql
SELECT
  u.id,
  u.username,
  COUNT(dna2.id) as total_invites
FROM users u
LEFT JOIN fingrow_dna dna ON u.id = dna.user_id
LEFT JOIN fingrow_dna dna2 ON dna.user_id = dna2.inviter_id  -- นับคนที่ invite มา
GROUP BY u.id;
```

---

## ✅ Checklist: ACF Fields

| ACF Field | Database Location | Notes |
|-----------|-------------------|-------|
| `userId` | `users.world_id` | YYAAA#### format |
| `runNumber` | `fingrow_dna.run_number` | ✅ |
| `parentId` | `fingrow_dna.parent_id` | ✅ |
| `childCount` | `fingrow_dna.child_count` | ✅ |
| `maxChildren` | `fingrow_dna.max_children` | ✅ |
| `acfAccepting` | `fingrow_dna.acf_accepting` | ✅ |
| `inviterId` | `fingrow_dna.inviter_id` | ✅ (ไม่ใช้ invitor) |
| `inviteCode` | `fingrow_dna.invite_code` | ✅ (ย้ายมาจาก users) |
| `createdAt` | `fingrow_dna.created_at` | ✅ |
| `level` | `fingrow_dna.level` | ✅ |

**สรุป: ครบทุกฟิลด์!** ✅

---

## 📝 สรุปการเปลี่ยนแปลง

1. ✅ ลบฟิลด์ซ้ำซ้อนจาก `users` (10 ฟิลด์)
2. ✅ ย้าย ACF fields ไป `fingrow_dna`
3. ✅ ใช้ `inviter_id` แทน `invitor_id` ทั้งหมด
4. ✅ เพิ่ม `invite_code` ใน `fingrow_dna`
5. ✅ แยก Marketplace และ ACF ชัดเจน

---

## 🚀 พร้อมสร้าง PostgreSQL Init Script!

Schema สะอาด ไม่ซ้ำซ้อน พร้อมใช้งานแล้วครับ
