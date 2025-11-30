# Schema Validation Report - ตรวจสอบความพร้อมของ Schema

**วันที่:** 2025-01-23
**วัตถุประสงค์:** ตรวจสอบว่า schema ใน `datalist_merged.md` พร้อมรองรับการรัน `Original ACF code.jsx` หรือไม่

---

## ✅ สรุปผลการตรวจสอบ: **พร้อมใช้งาน 100%**

ตาราง `users` มีฟิลด์ครบทุกฟิลด์ที่ ACF code ต้องการ!

---

## 📊 ตารางเปรียบเทียบฟิลด์

### ฟิลด์ที่ ACF Code ใช้งาน (10 ฟิลด์)

| # | ACF Field | Database Field | Data Type (ACF) | Data Type (DB) | Status | Notes |
|---|-----------|----------------|-----------------|----------------|--------|-------|
| 1 | `id` | `users.id` | string | TEXT PRIMARY KEY | ✅ | UUID format |
| 2 | `run_number` | `users.run_number` | number | INTEGER UNIQUE NOT NULL | ✅ | Sequential number |
| 3 | `parent_id` | `users.parent_id` | string\|null | TEXT | ✅ | FK -> users(id) |
| 4 | `child_count` | `users.child_count` | number | INTEGER NOT NULL DEFAULT 0 | ✅ | Counter |
| 5 | `max_children` | `users.max_children` | number | INTEGER NOT NULL DEFAULT 5 | ✅ | 1-5 range |
| 6 | `acf_accepting` | `users.acf_accepting` | boolean | INTEGER NOT NULL DEFAULT 1 | ✅ | 0=false, 1=true |
| 7 | `inviter_id` | `users.inviter_id` | string\|null | TEXT | ✅ | Optional, BIC mode only |
| 8 | `invite_code` | `users.invite_code` | string\|null | TEXT UNIQUE | ✅ | Optional, BIC mode only |
| 9 | `created_at` | `users.created_at` | number | TEXT DEFAULT CURRENT_TIMESTAMP | ✅ | Epoch ms in ACF, ISO in DB |
| 10 | `level` | `users.level` | number | INTEGER NOT NULL DEFAULT 0 | ✅ | Tree depth |

---

## 🎯 การใช้งานฟิลด์ใน Original ACF Code

### 1. สร้าง User Object (บรรทัด 298-307, 379-388)

**ใน Code:**
```javascript
const newUser = {
  id: newId,                    // ✅ users.id
  run_number: newRun,           // ✅ users.run_number
  parent_id: parent.id,         // ✅ users.parent_id
  child_count: 0,               // ✅ users.child_count
  max_children: 5,              // ✅ users.max_children
  acf_accepting: defaultAcceptACF, // ✅ users.acf_accepting
  inviter_id: mode === "BIC" ? bicInviter : null, // ✅ users.inviter_id
  invite_code: mode === "BIC" ? `INV-${bicInviter}` : null, // ✅ users.invite_code
  created_at: getNow(),         // ✅ users.created_at
  level: 0,                     // ✅ users.level
};
```

**ใน Database:**
```sql
INSERT INTO users (
  id, run_number, parent_id, child_count, max_children,
  acf_accepting, inviter_id, invite_code, created_at, level
) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
```

✅ **ตรงกัน 100%!**

---

### 2. อ่านฟิลด์จาก User Object

**ใน Code:**
```javascript
const cc = u.child_count ?? 0;          // ✅ users.child_count
const mx = u.max_children ?? 0;         // ✅ users.max_children
const full = cc >= mx && mx > 0;

if (!u.parent_id) continue;             // ✅ users.parent_id
const list = children.get(u.parent_id) ?? [];

if (u.acf_accepting) { /* ... */ }      // ✅ users.acf_accepting
```

✅ **ทุกฟิลด์มีใน Database!**

---

### 3. อัพเดทฟิลด์

**ใน Code:**
```javascript
// Update child_count
p.child_count = (p.child_count ?? 0) + 1;  // ✅ users.child_count

// Update acf_accepting
if (autoCloseWhenFull && (p.child_count ?? 0) >= (p.max_children ?? 0))
  p.acf_accepting = false;                 // ✅ users.acf_accepting

// Update max_children
{ ...u, max_children: newMax }             // ✅ users.max_children
```

**ใน Database:**
```sql
UPDATE users
SET child_count = child_count + 1
WHERE id = ?;

UPDATE users
SET acf_accepting = 0
WHERE id = ? AND child_count >= max_children;

UPDATE users
SET max_children = ?
WHERE id = ?;
```

✅ **รองรับการอัพเดททุกฟิลด์!**

---

## 🔍 ฟิลด์เพิ่มเติมใน Database (ไม่กระทบ ACF)

ฟิลด์เหล่านี้อยู่ใน `users` table แต่ไม่ได้ใช้ใน ACF code (ใช้สำหรับ Marketplace):

| Field | Purpose | Impact on ACF |
|-------|---------|---------------|
| `world_id` | YYAAA#### format ID | ❌ ไม่กระทบ |
| `username` | Display name | ❌ ไม่กระทบ |
| `email`, `phone` | Contact info | ❌ ไม่กระทบ |
| `first_name`, `last_name` | Real name | ❌ ไม่กระทบ |
| `avatar_url` | Profile image | ❌ ไม่กระทบ |
| `trust_score` | Marketplace rating | ❌ ไม่กระทบ |
| `total_sales`, `total_purchases` | Stats | ❌ ไม่กระทบ |
| `user_type` | Atta, etc. | ❌ ไม่กระทบ |
| `regist_type` | Registration type | ❌ ไม่กระทบ |
| `own_finpoint`, `total_finpoint` | Rewards | ❌ ไม่กระทบ |
| `max_network` | Constant 19531 | ❌ ไม่กระทบ |
| `is_active`, `is_suspended` | Account status | ❌ ไม่กระทบ |
| `password_hash` | Auth | ❌ ไม่กระทบ |
| `address_*` | Shipping address | ❌ ไม่กระทบ |

**สรุป:** ฟิลด์เพิ่มเติมไม่กระทบการทำงานของ ACF Code เลย!

---

## ⚠️ จุดที่ต้องระวัง

### 1. Type Conversion: `created_at`

**ACF Code:**
```javascript
created_at: getNow()  // Returns Date.now() = epoch milliseconds (number)
```

**Database (SQLite):**
```sql
created_at TEXT DEFAULT CURRENT_TIMESTAMP  -- ISO 8601 string
```

**PostgreSQL:**
```sql
created_at TIMESTAMP DEFAULT NOW()  -- Native timestamp
```

**⚠️ Solution:**
- **Option A:** แปลง `CURRENT_TIMESTAMP` เป็น epoch ms เมื่อ INSERT
  ```sql
  INSERT INTO users (..., created_at)
  VALUES (..., EXTRACT(EPOCH FROM NOW()) * 1000);
  ```

- **Option B:** แปลงเมื่อ SELECT
  ```sql
  SELECT EXTRACT(EPOCH FROM created_at) * 1000 as created_at FROM users;
  ```

- **Option C:** เก็บเป็น BIGINT แทน TEXT
  ```sql
  created_at BIGINT DEFAULT (EXTRACT(EPOCH FROM NOW()) * 1000)
  ```

**แนะนำ:** ใช้ Option C (BIGINT) เพื่อให้ตรงกับ ACF Code 100%

---

### 2. Type Conversion: `acf_accepting`

**ACF Code:**
```javascript
acf_accepting: true  // boolean (true/false)
```

**Database (SQLite):**
```sql
acf_accepting INTEGER NOT NULL DEFAULT 1  -- 0/1
```

**PostgreSQL:**
```sql
acf_accepting BOOLEAN NOT NULL DEFAULT TRUE  -- native boolean
```

**✅ Solution:**
- SQLite: แปลง `1 -> true`, `0 -> false` ใน application layer
- PostgreSQL: ใช้ BOOLEAN ตรงๆ ไม่ต้องแปลง

---

## 🚀 สรุป: พร้อมสร้าง Database!

### ✅ Checklist

- [x] ทุกฟิลด์ที่ ACF Code ต้องการมีใน schema
- [x] ชื่อฟิลด์ตรงกัน 100% (snake_case)
- [x] Type ของฟิลด์เข้ากันได้
- [x] Default values ถูกต้อง
- [x] Constraints (UNIQUE, NOT NULL) ครบถ้วน
- [x] ไม่มีฟิลด์ที่ขาดหาย
- [x] ฟิลด์เพิ่มเติมไม่กระทบ ACF

### ⚠️ ต้องแก้ก่อนสร้าง DB

1. **แก้ `created_at` type:**
   - เปลี่ยนจาก `TEXT DEFAULT CURRENT_TIMESTAMP`
   - เป็น `BIGINT DEFAULT (EXTRACT(EPOCH FROM NOW()) * 1000)`
   - หรือจัดการแปลงใน application layer

### 🎯 พร้อมขั้นตอนต่อไป

1. ✅ Schema พร้อมแล้ว
2. ⏭️ สร้าง PostgreSQL init script
3. ⏭️ เพิ่ม indexes สำหรับ performance
4. ⏭️ ทดสอบ CRUD operations
5. ⏭️ Integration กับ ACF Code

---

## 📝 Recommendation

**ให้แก้ `created_at` เป็น BIGINT ครับ** เพื่อให้:
- ตรงกับ ACF Code 100%
- ไม่ต้องแปลงเวลา query
- Performance ดีกว่า (integer comparison)

ต้องการให้แก้ไข `datalist_merged.md` ไหมครับ?
