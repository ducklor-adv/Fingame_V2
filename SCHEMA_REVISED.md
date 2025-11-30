# Fingrow Database Schema - Revised (ปรับให้ตรงกับ ACF Code)

## 🎯 การเปลี่ยนแปลง

ปรับชื่อฟิลด์ใน `fingrow_dna` ให้ตรงกับ Original ACF Code เพื่อลดความซ้ำซ้อนและความสับสน

---

## ตาราง fingrow_dna (แก้ไขแล้ว)

### ✅ ชื่อฟิลด์ใหม่ (ตรงกับ ACF Code)

```sql
CREATE TABLE fingrow_dna (
  id SERIAL PRIMARY KEY,
  run_number INTEGER UNIQUE NOT NULL,        -- ✅ runNumber
  user_id UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,

  -- ACF Tree Structure
  parent_id UUID REFERENCES users(id) ON DELETE SET NULL,  -- ✅ parentId

  -- 🔄 เปลี่ยนจาก follower → child
  child_count INTEGER NOT NULL DEFAULT 0,     -- ✅ childCount (เดิม: follower_count)
  max_children INTEGER NOT NULL DEFAULT 5,    -- ✅ maxChildren (เดิม: max_follower)

  -- 🔄 เปลี่ยนจาก follower_full_status → acf_accepting
  acf_accepting BOOLEAN NOT NULL DEFAULT TRUE, -- ✅ acfAccepting (เดิม: follower_full_status)

  -- Referral/Invite
  inviter_id TEXT,                            -- ✅ inviterId (เดิม: invitor)

  -- Level & Timestamps
  level INTEGER NOT NULL DEFAULT 0,           -- ✅ level
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,  -- ✅ createdAt

  -- ACF Metadata (เพิ่มเติม)
  user_type TEXT NOT NULL DEFAULT 'Atta',
  regist_type TEXT NOT NULL DEFAULT 'normal',

  -- Finpoint System
  own_finpoint DECIMAL(20,8) NOT NULL DEFAULT 0,
  total_finpoint DECIMAL(20,8) NOT NULL DEFAULT 0,
  max_network INTEGER NOT NULL DEFAULT 19531,  -- MAX_NETWORK constant

  -- Legacy fields (optional)
  js_file_path TEXT,
  parent_file TEXT,

  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

---

## 📊 ตารางเปรียบเทียบ: เดิม vs ใหม่

| ACF Code | Schema เดิม | Schema ใหม่ | สถานะ |
|----------|-------------|-------------|-------|
| `childCount` | `follower_count` | `child_count` | ✅ ตรงกัน |
| `maxChildren` | `max_follower` | `max_children` | ✅ ตรงกัน |
| `acfAccepting` | `follower_full_status` (TEXT) | `acf_accepting` (BOOLEAN) | ✅ ตรงกัน |
| `inviterId` | `invitor` | `inviter_id` | ✅ ตรงกัน |
| `runNumber` | `run_number` | `run_number` | ✅ เหมือนเดิม |
| `parentId` | `parent_id` | `parent_id` | ✅ เหมือนเดิม |
| `level` | `level` | `level` | ✅ เหมือนเดิม |
| `createdAt` | `regist_time` | `created_at` | ✅ ตรงกัน |
| `userId` | `user_id` | `user_id` | ✅ เหมือนเดิม |

---

## 🔄 Migration Script

### SQL Migration (PostgreSQL)

```sql
-- Migration: แก้ไข fingrow_dna ให้ตรงกับ ACF Code
BEGIN;

-- 1. เปลี่ยนชื่อฟิลด์
ALTER TABLE fingrow_dna RENAME COLUMN follower_count TO child_count;
ALTER TABLE fingrow_dna RENAME COLUMN max_follower TO max_children;
ALTER TABLE fingrow_dna RENAME COLUMN invitor TO inviter_id;
ALTER TABLE fingrow_dna RENAME COLUMN regist_time TO created_at;

-- 2. เปลี่ยน follower_full_status (TEXT) → acf_accepting (BOOLEAN)
ALTER TABLE fingrow_dna ADD COLUMN acf_accepting BOOLEAN;

-- แปลงข้อมูล: 'Open' → true, อื่นๆ → false
UPDATE fingrow_dna SET acf_accepting = (follower_full_status = 'Open');

-- ตั้งค่า default และ NOT NULL
ALTER TABLE fingrow_dna ALTER COLUMN acf_accepting SET DEFAULT TRUE;
ALTER TABLE fingrow_dna ALTER COLUMN acf_accepting SET NOT NULL;

-- ลบฟิลด์เก่า
ALTER TABLE fingrow_dna DROP COLUMN follower_full_status;

-- 3. เพิ่ม max_network constant (ถ้ายังไม่มี)
ALTER TABLE fingrow_dna ADD COLUMN IF NOT EXISTS max_network INTEGER DEFAULT 19531;

COMMIT;
```

---

## 💻 โค้ดหลังแก้ไข (ไม่ต้องมี Helper Functions!)

### ✅ Query ตรงๆ เลย (ไม่ต้องแปลง)

```javascript
// GET /api/acf/users
app.get('/api/acf/users', async (req, res) => {
  const result = await query(`
    SELECT
      u.world_id as "userId",
      dna.run_number as "runNumber",
      dna.parent_id as "parentId",
      dna.child_count as "childCount",        -- ✅ ชื่อตรงกันเลย!
      dna.max_children as "maxChildren",       -- ✅ ชื่อตรงกันเลย!
      dna.acf_accepting as "acfAccepting",     -- ✅ ชื่อตรงกันเลย!
      dna.inviter_id as "inviterId",
      u.invite_code as "inviteCode",
      EXTRACT(EPOCH FROM dna.created_at) * 1000 as "createdAt",
      dna.level
    FROM users u
    INNER JOIN fingrow_dna dna ON u.id = dna.user_id
    ORDER BY dna.run_number
  `);

  res.json(result.rows);  // ← ส่งตรงๆ ไม่ต้องแปลง!
});
```

### ✅ Insert ง่ายขึ้นมาก

```javascript
// POST /api/acf/users
app.post('/api/acf/users', async (req, res) => {
  const { userId, runNumber, parentId, childCount, maxChildren,
          acfAccepting, inviterId, level, createdAt } = req.body;

  // Insert โดยใช้ชื่อเดียวกันเลย!
  await query(`
    INSERT INTO fingrow_dna (
      user_id, run_number, parent_id,
      child_count, max_children, acf_accepting,  -- ✅ ชื่อตรงกัน
      inviter_id, level, created_at
    ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, to_timestamp($9/1000.0))
  `, [userId, runNumber, parentId, childCount, maxChildren,
      acfAccepting, inviterId, level, createdAt]);

  res.json({ success: true });
});
```

---

## 🎯 ข้อดีของการแก้ไข Schema

### ✅ ข้อดี

1. **ไม่ต้องมี Helper Functions** - ชื่อตรงกัน query ตรงๆ
2. **โค้ดสั้นลง** - ไม่ต้องแปลงข้อมูล
3. **ไม่สับสน** - ชื่อเดียวกันทั้ง Frontend, Backend, Database
4. **ลด Bug** - ไม่มีโอกาสแปลงผิด
5. **มาตรฐานชัดเจน** - ใช้คำศัพท์ ACF/Tree ที่ถูกต้อง
6. **Boolean จริงๆ** - ไม่ใช่ string 'Open'/'Full'

### ⚠️ ข้อควรระวัง

1. **ต้อง migrate ข้อมูลเก่า** - ถ้ามีข้อมูลอยู่แล้ว
2. **ต้องทดสอบ migration** - ก่อนรันจริง

---

## 📋 Checklist: ขั้นตอนการแก้ไข

- [ ] 1. Backup ฐานข้อมูลก่อน (สำคัญ!)
- [ ] 2. รัน migration script (ALTER TABLE)
- [ ] 3. ตรวจสอบข้อมูลว่าแปลงถูกต้อง
- [ ] 4. อัพเดท API code (ลบ helper functions)
- [ ] 5. ทดสอบ API endpoints
- [ ] 6. อัพเดทเอกสาร (documentation)

---

## 🚀 SQL Script สำหรับสร้างใหม่

ถ้าเริ่มโปรเจคใหม่ ใช้ schema นี้เลย:

```sql
CREATE TABLE fingrow_dna (
  id SERIAL PRIMARY KEY,
  run_number INTEGER UNIQUE NOT NULL,
  user_id UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,

  -- ACF Tree (ชื่อตรงกับ ACF Code)
  parent_id UUID REFERENCES users(id) ON DELETE SET NULL,
  child_count INTEGER NOT NULL DEFAULT 0,
  max_children INTEGER NOT NULL DEFAULT 5,
  acf_accepting BOOLEAN NOT NULL DEFAULT TRUE,
  inviter_id TEXT,
  level INTEGER NOT NULL DEFAULT 0,

  -- Metadata
  user_type TEXT NOT NULL DEFAULT 'Atta',
  regist_type TEXT NOT NULL DEFAULT 'normal',

  -- Finpoint
  own_finpoint DECIMAL(20,8) NOT NULL DEFAULT 0,
  total_finpoint DECIMAL(20,8) NOT NULL DEFAULT 0,
  max_network INTEGER NOT NULL DEFAULT 19531,

  -- Timestamps
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE INDEX idx_fingrow_dna_user_id ON fingrow_dna(user_id);
CREATE INDEX idx_fingrow_dna_parent_id ON fingrow_dna(parent_id);
CREATE INDEX idx_fingrow_dna_run_number ON fingrow_dna(run_number);
CREATE INDEX idx_fingrow_dna_acf_accepting ON fingrow_dna(acf_accepting);

-- Trigger for auto-update updated_at
CREATE TRIGGER update_fingrow_dna_updated_at
  BEFORE UPDATE ON fingrow_dna
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();
```

---

## 📝 สรุป

### เปลี่ยนแปลงหลัก:

| เดิม | ใหม่ | เหตุผล |
|------|------|--------|
| `follower_count` | `child_count` | ชื่อตรงกับ ACF, ชัดเจนกว่า |
| `max_follower` | `max_children` | ชื่อตรงกับ ACF |
| `follower_full_status` (TEXT) | `acf_accepting` (BOOLEAN) | ชื่อตรงกับ ACF, ประเภทข้อมูลถูกต้อง |
| `invitor` | `inviter_id` | สะกดถูกต้อง (inviter) |
| `regist_time` | `created_at` | ชื่อมาตรฐาน |

### ผลลัพธ์:
- ✅ ไม่ต้องเขียน helper functions
- ✅ โค้ดสั้นลง อ่านง่ายขึ้น
- ✅ ลดโอกาส bug จากการแปลงข้อมูล
- ✅ ใช้คำศัพท์มาตรฐาน ACF/Tree
