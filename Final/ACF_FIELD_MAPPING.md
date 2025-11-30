# ACF Field Mapping - Original Code vs Database Schema

## 📊 สรุปการ Mapping

เอกสารนี้แสดงการเชื่อมโยงระหว่าง:
- **Original ACF code.jsx** (React TypeScript)
- **datalist_merged.md** (Database Schema)

---

## 🔍 การวิเคราะห์ Original ACF Code

### Type Definition: `User` (บรรทัด 20-31)

```typescript
type User = {
  userId: string;          // e.g., 25AAA0001
  runNumber: number;       // insertion/run order
  parentId: string | null;
  childCount: number;
  maxChildren: number;
  acfAccepting: boolean;
  inviterId?: string | null;
  inviteCode?: string | null;
  createdAt: number;       // epoch ms
  level: number;           // depth from GLOBAL system root
};
```

### ค่าคงที่สำคัญ (Constants)

```typescript
SYSTEM_ROOT_ID = "25AAA0000"      // permanent system root
DEFAULT_ACF_ROOT_ID = "25AAA0001" // default ACF root
MAX_NETWORK = 19531               // (5^7 - 1) / 4 for levels 0..6
```

### ฟิลด์ที่ใช้ใน UI

1. **User Management:**
   - `userId` - รหัสผู้ใช้ (YYAAA####)
   - `runNumber` - ลำดับการลงทะเบียน
   - `parentId` - parent ใน ACF tree
   - `level` - ระดับความลึกจาก root

2. **ACF Tree Logic:**
   - `childCount` - จำนวนลูกปัจจุบัน
   - `maxChildren` - จำนวนลูกสูงสุด (1-5)
   - `acfAccepting` - เปิดรับ ACF หรือไม่

3. **Referral/Invite:**
   - `inviterId` - ผู้เชิญ (BIC mode)
   - `inviteCode` - รหัสเชิญ

4. **Timestamp:**
   - `createdAt` - เวลาสร้าง (epoch milliseconds)

---

## 📋 Field Mapping Table

### ตาราง `users` - ฟิลด์หลัก

| ACF Code Field | Database Field | Type (DB) | Notes |
|----------------|----------------|-----------|-------|
| `userId` | `id` | UUID/TEXT | รหัสผู้ใช้ (เปลี่ยนจาก YYAAA#### เป็น UUID) |
| `userId` | `world_id` | TEXT | อาจใช้เป็น World ID (format YYAAA####) |
| ❌ | `username` | TEXT | ไม่มีใน ACF code (ต้องเพิ่ม) |
| ❌ | `email` | TEXT | ไม่มีใน ACF code (ต้องเพิ่ม) |
| ❌ | `phone` | TEXT | ไม่มีใน ACF code (optional) |
| `inviteCode` | `invite_code` | TEXT | รหัสแนะนำ ✅ match |
| `inviterId` | `invitor_id` | UUID/TEXT | ผู้เชิญ ✅ match |
| `inviterId` | `referrer_id` | UUID/TEXT | Alias ของ invitor_id ✅ |
| `inviteCode` | `referral_code` | TEXT | Alias ของ invite_code ✅ |
| `level` | `referral_level` | INTEGER | ระดับ MLM (1-7) ⚠️ ต่างกัน |
| `parentId` | `parent_id` | UUID/TEXT | Parent ใน ACF tree ✅ match |
| `createdAt` | `created_at` | TIMESTAMP | เวลาสร้าง ✅ match |
| ❌ | `updated_at` | TIMESTAMP | ไม่มีใน ACF code |
| `acfAccepting` | ❌ | - | **ไม่มีในฐานข้อมูล!** ต้องเพิ่ม |
| `childCount` | ❌ | - | **ไม่มีในฐานข้อมูล!** ต้องเพิ่ม |
| `maxChildren` | ❌ | - | **ไม่มีในฐานข้อมูล!** ต้องเพิ่ม |
| `runNumber` | ❌ | - | **มีใน fingrow_dna.run_number!** |

---

### ตาราง `fingrow_dna` - ACF Tree Data

| ACF Code Field | Database Field | Type (DB) | Notes |
|----------------|----------------|-----------|-------|
| `runNumber` | `run_number` | INTEGER | ลำดับการเข้าร่วม ✅ match |
| `userId` | `user_id` | UUID | FK -> users(id) ✅ |
| ❌ | `user_type` | TEXT | ประเภทผู้ใช้ (Atta) - ไม่มีใน ACF code |
| `createdAt` | `regist_time` | TIMESTAMP | เวลาลงทะเบียน ✅ |
| ❌ | `regist_type` | TEXT | ประเภทการลงทะเบียน |
| `inviterId` | `invitor` | TEXT | ผู้เชิญ ACF ✅ |
| `maxChildren` | `max_follower` | INTEGER | จำนวน follower สูงสุด ✅ (default: 5) |
| `childCount` | `follower_count` | INTEGER | จำนวน follower ปัจจุบัน ✅ |
| `acfAccepting` | `follower_full_status` | TEXT | 'Open'/'Full' ✅ (แปลงจาก boolean) |
| ❌ | `max_level_royalty` | INTEGER | 19530 - คงที่ (ตรงกับ MAX_NETWORK) |
| `childCount` | `child_count` | INTEGER | จำนวนลูก ✅ duplicate |
| `parentId` | `parent_id` | UUID | Parent node ✅ match |
| ❌ | `own_finpoint` | DECIMAL | คะแนน Finpoint ของตัวเอง |
| ❌ | `total_finpoint` | DECIMAL | คะแนน Finpoint รวม |
| `level` | `level` | INTEGER | ระดับใน tree ✅ match |

---

## ⚠️ ฟิลด์ที่ขาดหายไปในฐานข้อมูล

### ต้องเพิ่มในตาราง `users`:

```sql
ALTER TABLE users ADD COLUMN acf_accepting BOOLEAN DEFAULT TRUE;
ALTER TABLE users ADD COLUMN child_count INTEGER DEFAULT 0;
ALTER TABLE users ADD COLUMN max_children INTEGER DEFAULT 5;
```

หรือใช้ฟิลด์จาก `fingrow_dna`:
- `follower_count` = `childCount`
- `max_follower` = `maxChildren`
- `follower_full_status` = `acfAccepting` (Open/Full)

---

## 🔄 การแปลงข้อมูล (Data Transformation)

### 1. User ID Format

**ACF Code:**
```typescript
userId: "25AAA0001" // YYAAA#### (9 chars)
```

**Database:**
```sql
id: UUID (gen_random_uuid())
world_id: "25AAA0001" -- เก็บ format เดิมไว้
```

**วิธีแก้:** ใช้ `world_id` เก็บ format YYAAA####

---

### 2. ACF Accepting Status

**ACF Code:**
```typescript
acfAccepting: boolean  // true/false
```

**Database (fingrow_dna):**
```sql
follower_full_status: TEXT  -- 'Open' / 'Full'
```

**การแปลง:**
```javascript
// ACF -> DB
follower_full_status = acfAccepting ? 'Open' : 'Full'

// DB -> ACF
acfAccepting = (follower_full_status === 'Open')
```

---

### 3. Created At Timestamp

**ACF Code:**
```typescript
createdAt: number  // epoch milliseconds (1732345678000)
```

**Database:**
```sql
created_at: TIMESTAMP  -- '2024-11-23 12:34:56'
```

**การแปลง:**
```javascript
// ACF -> DB
created_at = new Date(createdAt).toISOString()

// DB -> ACF
createdAt = new Date(created_at).getTime()
```

---

### 4. Level vs Referral Level

**ACF Code:**
```typescript
level: number  // depth from GLOBAL system root (0,1,2,3...)
```

**Database:**
```sql
referral_level: INTEGER  -- MLM level 1-7
level (fingrow_dna): INTEGER  -- depth in tree
```

**ความแตกต่าง:**
- ACF `level` = ความลึกจาก root (เริ่มที่ 0)
- DB `referral_level` = ระดับ MLM (1-7)
- DB `fingrow_dna.level` = ความลึกใน tree ✅ ตรงกับ ACF

**วิธีแก้:** ใช้ `fingrow_dna.level`

---

## 📐 Schema Recommendation

### แนวทางที่ 1: ใช้ `fingrow_dna` เป็นหลัก

ข้อมูล ACF ส่วนใหญ่เก็บใน `fingrow_dna`:

```sql
CREATE TABLE fingrow_dna (
  id SERIAL PRIMARY KEY,
  run_number INTEGER UNIQUE,           -- ✅ runNumber
  user_id UUID REFERENCES users(id),   -- ✅ userId

  parent_id UUID REFERENCES users(id), -- ✅ parentId

  max_follower INTEGER DEFAULT 5,      -- ✅ maxChildren
  follower_count INTEGER DEFAULT 0,    -- ✅ childCount
  follower_full_status TEXT DEFAULT 'Open', -- ✅ acfAccepting

  invitor TEXT,                        -- ✅ inviterId
  level INTEGER DEFAULT 0,             -- ✅ level

  regist_time TIMESTAMP,               -- ✅ createdAt

  -- Extra fields
  max_level_royalty INTEGER DEFAULT 19530, -- MAX_NETWORK
  own_finpoint DECIMAL DEFAULT 0,
  total_finpoint DECIMAL DEFAULT 0
);
```

### แนวทางที่ 2: เพิ่มฟิลด์ใน `users`

เพิ่มฟิลด์ ACF เข้าไปใน `users` เลย:

```sql
ALTER TABLE users
  ADD COLUMN acf_accepting BOOLEAN DEFAULT TRUE,
  ADD COLUMN child_count INTEGER DEFAULT 0,
  ADD COLUMN max_children INTEGER DEFAULT 5,
  ADD COLUMN run_number INTEGER UNIQUE;
```

---

## 🎯 การใช้งานในระบบ

### Query ตัวอย่าง: ดึงข้อมูล ACF User

```sql
SELECT
  u.id,
  u.world_id as userId,          -- YYAAA#### format
  dna.run_number as runNumber,
  dna.parent_id as parentId,
  dna.follower_count as childCount,
  dna.max_follower as maxChildren,
  (dna.follower_full_status = 'Open') as acfAccepting,
  dna.invitor as inviterId,
  u.invite_code as inviteCode,
  EXTRACT(EPOCH FROM dna.regist_time) * 1000 as createdAt,
  dna.level
FROM users u
LEFT JOIN fingrow_dna dna ON u.id = dna.user_id
ORDER BY dna.run_number;
```

### Insert ตัวอย่าง: เพิ่ม User ใหม่ (ACF)

```javascript
// ACF Code data
const newUser = {
  userId: "25AAA0002",
  runNumber: 2,
  parentId: "25AAA0001",
  childCount: 0,
  maxChildren: 5,
  acfAccepting: true,
  inviterId: "25AAA0001",
  inviteCode: "INV-25AAA0001",
  createdAt: Date.now(),
  level: 1
};

// SQL Insert
const userId = await db.query(`
  INSERT INTO users (world_id, invite_code, invitor_id, parent_id)
  VALUES ($1, $2, $3, $4)
  RETURNING id
`, [newUser.userId, newUser.inviteCode, newUser.inviterId, newUser.parentId]);

await db.query(`
  INSERT INTO fingrow_dna (
    user_id, run_number, parent_id, invitor,
    max_follower, follower_count, follower_full_status,
    level, regist_time
  ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, to_timestamp($9/1000.0))
`, [
  userId,
  newUser.runNumber,
  newUser.parentId,
  newUser.inviterId,
  newUser.maxChildren,
  newUser.childCount,
  newUser.acfAccepting ? 'Open' : 'Full',
  newUser.level,
  newUser.createdAt
]);
```

---

## ✅ สรุปการ Mapping

### ✅ ฟิลด์ที่ Match (พร้อมใช้งาน)

- `userId` → `world_id` / `fingrow_dna.user_id`
- `runNumber` → `fingrow_dna.run_number`
- `parentId` → `users.parent_id` / `fingrow_dna.parent_id`
- `inviterId` → `users.invitor_id` / `fingrow_dna.invitor`
- `inviteCode` → `users.invite_code`
- `level` → `fingrow_dna.level`
- `createdAt` → `fingrow_dna.regist_time`

### ⚠️ ฟิลด์ที่ต้องแปลง

- `childCount` → `fingrow_dna.follower_count`
- `maxChildren` → `fingrow_dna.max_follower`
- `acfAccepting` → `fingrow_dna.follower_full_status` (Open/Full)
- `createdAt` → แปลง epoch → TIMESTAMP

### ❌ ฟิลด์ที่ขาดใน ACF Code (มีในฐานข้อมูล)

- `username`, `email`, `phone` (ต้องเพิ่มใน ACF)
- `own_finpoint`, `total_finpoint` (ระบบคะแนน)
- `user_type`, `regist_type` (metadata)

---

## 🚀 ขั้นตอนถัดไป

1. **ตัดสินใจ Schema Strategy:**
   - ใช้ `fingrow_dna` เป็นหลัก (แนะนำ)
   - หรือ เพิ่มฟิลด์ใน `users`

2. **สร้าง API Endpoints:**
   - `GET /api/acf/users` - ดึงข้อมูล ACF users
   - `POST /api/acf/users` - เพิ่ม user ใหม่
   - `PUT /api/acf/users/:id/toggle-accept` - เปิด/ปิด ACF
   - `GET /api/acf/tree/:rootId` - ดึง subtree

3. **สร้าง Helper Functions:**
   - `acfUserToDbFormat()` - แปลง ACF → DB
   - `dbToAcfUserFormat()` - แปลง DB → ACF
   - `calculateLevel()` - คำนวณ level
   - `bfsSubtree()` - หา subtree

---

## 📝 Notes

- **MAX_NETWORK = 19,531** (ตรงกับ `max_level_royalty`)
- ACF ใช้ **BFS (layer-first)** algorithm
- System Root = `25AAA0000`, Default ACF Root = `25AAA0001`
- ฟิลด์ `world_id` สามารถใช้เก็บ format YYAAA#### ได้
