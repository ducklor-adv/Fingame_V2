# ACF Fields Checklist

เอกสารตรวจสอบว่าฟิลด์ที่ Original ACF Code ใช้งาน มีครบใน datalist_merged.md หรือไม่

---

## 📋 ฟิลด์ที่ Original ACF Code ใช้งาน

จาก `Original ACF code.jsx` (บรรทัด 20-31):

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

---

## ✅ Checklist: ACF Code Type vs Database Fields

| # | ACF Code (camelCase) | ACF Field (Database) | Type | Database Table | Status | Notes |
|---|----------------------|----------------------|------|----------------|--------|-------|
| 1 | `userId` | `id` / `world_id` | string | `users` | ✅ มี | PK=UUID, world_id=YYAAA#### |
| 2 | `runNumber` | `run_number` | number | `fingrow_dna` | ✅ มี | ชื่อตรงกัน 100% |
| 3 | `parentId` | `parent_id` | string\|null | `fingrow_dna` | ✅ มี | ชื่อตรงกัน 100% |
| 4 | `childCount` | `child_count` | number | `fingrow_dna` | ✅ มี | ✅ แก้ไขแล้ว (เดิม: follower_count) |
| 5 | `maxChildren` | `max_children` | number | `fingrow_dna` | ✅ มี | ✅ แก้ไขแล้ว (เดิม: max_follower) |
| 6 | `acfAccepting` | `acf_accepting` | boolean | `fingrow_dna` | ✅ มี | ✅ แก้ไขแล้ว (เดิม: follower_full_status) |
| 7 | `inviterId` | `inviter_id` | string\|null | `fingrow_dna` | ✅ มี | ✅ แก้ไขแล้ว (เดิม: invitor) |
| 8 | `inviteCode` | `invite_code` | string\|null | `fingrow_dna` + `users` | ✅ มี | มีทั้งสองตาราง (คนละจุดประสงค์) |
| 9 | `createdAt` | `created_at` | number | `fingrow_dna` | ✅ มี | ✅ แก้ไขแล้ว (เดิม: regist_time) |
| 10 | `level` | `level` | number | `fingrow_dna` | ✅ มี | ชื่อตรงกัน 100% |

---

## 🎯 สรุป: ครบทุกฟิลด์! ✅

**ผลการตรวจสอบ:** 10/10 ฟิลด์ครบทั้งหมด

### ตารางที่เกี่ยวข้อง:

1. **`users`** - ข้อมูลผู้ใช้พื้นฐาน
   - `world_id` → `userId`
   - `invite_code` → `inviteCode`

2. **`fingrow_dna`** - ข้อมูล ACF Tree (หลัก)
   - `run_number` → `runNumber`
   - `parent_id` → `parentId`
   - `child_count` → `childCount` ✅
   - `max_children` → `maxChildren` ✅
   - `acf_accepting` → `acfAccepting` ✅
   - `inviter_id` → `inviterId` ✅
   - `level` → `level`
   - `created_at` → `createdAt` ✅

---

## 🔄 ฟิลด์ที่แก้ไขแล้ว (Updated)

| ชื่อเดิม | ชื่อใหม่ | เหตุผล |
|----------|----------|--------|
| `follower_count` | `child_count` | ตรงกับ ACF, ชัดเจนกว่า |
| `max_follower` | `max_children` | ตรงกับ ACF |
| `follower_full_status` | `acf_accepting` | ตรงกับ ACF, ใช้ INTEGER (0/1) แทน TEXT |
| `invitor` | `inviter_id` | สะกดถูก + มี _id suffix |
| `regist_time` | `created_at` | ชื่อมาตรฐาน, ตรงกับ ACF |

---

## 📊 การแปลงข้อมูล (Data Type Mapping)

### SQLite → PostgreSQL

| SQLite Type | PostgreSQL Type | ACF TypeScript Type |
|-------------|-----------------|---------------------|
| `TEXT` | `UUID` / `VARCHAR` | `string` |
| `INTEGER` | `INTEGER` / `SERIAL` | `number` |
| `INTEGER (0/1)` | `BOOLEAN` | `boolean` |
| `TEXT (timestamp)` | `TIMESTAMP` | `number` (epoch ms) |
| `REAL` | `DECIMAL` | `number` |

### ตัวอย่าง: acf_accepting

**SQLite (datalist_merged.md):**
```sql
acf_accepting INTEGER NOT NULL DEFAULT 1  -- 0=false, 1=true
```

**PostgreSQL (init script):**
```sql
acf_accepting BOOLEAN NOT NULL DEFAULT TRUE
```

**ACF Code:**
```typescript
acfAccepting: boolean  // true/false
```

---

## 🔍 ฟิลด์เพิ่มเติมที่มีใน Database (แต่ไม่มีใน ACF Code)

ฟิลด์เหล่านี้เป็นข้อมูลเพิ่มเติมสำหรับระบบ Fingrow:

| Field | Table | Purpose |
|-------|-------|---------|
| `user_type` | `fingrow_dna` | ประเภทผู้ใช้ (Atta, etc.) |
| `regist_type` | `fingrow_dna` | ประเภทการลงทะเบียน |
| `own_finpoint` | `fingrow_dna` | คะแนน Finpoint ของตัวเอง |
| `total_finpoint` | `fingrow_dna` | คะแนน Finpoint รวม |
| `max_network` | `fingrow_dna` | ค่าคงที่ 19531 (MAX_NETWORK) |
| `js_file_path` | `fingrow_dna` | Legacy field |
| `parent_file` | `fingrow_dna` | Legacy field |

**หมายเหตุ:** ฟิลด์เหล่านี้ไม่กระทบการทำงานของ ACF Code

---

## 🎯 Query Example: ดึงข้อมูลแบบ ACF Format

### PostgreSQL Query

```sql
SELECT
  u.world_id as "userId",              -- ← ส่ง world_id (YYAAA####) ไปให้ ACF
  dna.run_number as "runNumber",
  dna.parent_id as "parentId",         -- ← เก็บเป็น world_id (ไม่ใช่ UUID)
  dna.child_count as "childCount",
  dna.max_children as "maxChildren",
  dna.acf_accepting as "acfAccepting",
  dna.inviter_id as "inviterId",       -- ← เก็บเป็น world_id (ไม่ใช่ UUID)
  u.invite_code as "inviteCode",
  EXTRACT(EPOCH FROM dna.created_at) * 1000 as "createdAt",
  dna.level
FROM users u
INNER JOIN fingrow_dna dna ON u.id = dna.user_id  -- ← JOIN ด้วย UUID
ORDER BY dna.run_number;
```

**หมายเหตุ:**
- `users.id` = UUID (Primary Key)
- `users.world_id` = YYAAA#### (สำหรับ ACF)
- `fingrow_dna.user_id` = FK ไปที่ `users.id` (UUID)
- `fingrow_dna.parent_id` = เก็บเป็น `world_id` format (YYAAA####)
- `fingrow_dna.inviter_id` = เก็บเป็น `world_id` format (YYAAA####)

**ผลลัพธ์จะได้ข้อมูลในรูปแบบที่ ACF Code ต้องการเลย!**

```json
[
  {
    "userId": "25AAA0001",
    "runNumber": 1,
    "parentId": "25AAA0000",
    "childCount": 3,
    "maxChildren": 5,
    "acfAccepting": true,
    "inviterId": "25AAA0000",
    "inviteCode": "INV-001",
    "createdAt": 1732345678000,
    "level": 1
  }
]
```

---

## ✅ สรุปสถานะ

### ✅ ครบทุกฟิลด์!

- [x] ทุกฟิลด์ที่ ACF Code ใช้งานมีครบใน datalist_merged.md
- [x] ชื่อฟิลด์แก้ไขให้ตรงกับ ACF Code แล้ว
- [x] ไม่มีฟิลด์ใดขาดหาย
- [x] ไม่มีความซ้ำซ้อนของข้อมูล
- [x] พร้อมสร้าง database init script

---

## 📝 Next Steps

1. ✅ ตรวจสอบฟิลด์ (เสร็จแล้ว)
2. ⏭️ สร้าง init script สำหรับ PostgreSQL
3. ⏭️ สร้าง API endpoints
4. ⏭️ ทดสอบการทำงานกับ ACF Code

---

## 📌 Constants ที่ใช้ใน ACF

```javascript
SYSTEM_ROOT_ID = "25AAA0000"      // permanent system root
DEFAULT_ACF_ROOT_ID = "25AAA0001" // default ACF root (first signup)
MAX_NETWORK = 19531               // (5^7 - 1) / 4 for levels 0..6
```

เก็บไว้ใน `fingrow_dna.max_network` (default: 19531)
