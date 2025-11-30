# created_at Type Fix Summary

## ✅ การแก้ไขที่ทำแล้ว

### ตาราง `users` - แก้แล้ว!

**เดิม:**
```sql
created_at TEXT DEFAULT CURRENT_TIMESTAMP,  -- ISO string
updated_at TEXT DEFAULT CURRENT_TIMESTAMP   -- ISO string
```

**ใหม่:**
```sql
created_at BIGINT,  -- Epoch milliseconds (matches ACF getNow())
updated_at BIGINT   -- Epoch milliseconds
```

---

## 🎯 เหตุผลที่แก้

### ใน ACF Code:
```javascript
created_at: getNow()  // Returns Date.now() = epoch milliseconds
```

**ตัวอย่าง:**
- `1732345678000` (epoch ms)
- `2023-11-23T10:34:38.000Z` (ISO string) ❌ ไม่ตรงกัน

### ใน Database ใหม่:
```sql
created_at BIGINT  -- 1732345678000 (epoch ms) ✅ ตรงกับ ACF
```

---

## 📊 ข้อดีของการใช้ BIGINT

1. **ตรงกับ ACF Code 100%**
   - ไม่ต้องแปลง type เวลา INSERT
   - ไม่ต้องแปลง type เวลา SELECT

2. **Performance ดีกว่า**
   - Integer comparison เร็วกว่า string/timestamp
   - Index ทำงานได้ดีกว่า

3. **ง่ายต่อการใช้งาน**
   ```javascript
   // JavaScript
   const now = Date.now();  // 1732345678000

   // SQL INSERT
   INSERT INTO users (..., created_at) VALUES (..., 1732345678000);

   // SQL SELECT
   SELECT created_at FROM users WHERE id = ?;
   // Returns: 1732345678000

   // JavaScript
   const date = new Date(created_at);  // Convert back to Date
   ```

---

## 🔍 ตารางอื่นๆ ไม่ต้องแก้

ตารางอื่นๆ (products, orders, reviews, etc.) **ไม่ต้องแก้** เพราะ:
- ไม่ได้ใช้ใน ACF Code
- ใช้ `TEXT DEFAULT CURRENT_TIMESTAMP` ต่อได้
- เป็นข้อมูล Marketplace ปกติ

**ตารางที่ไม่ต้องแก้:**
- products
- orders
- order_items
- categories
- reviews
- favorites
- chat_rooms
- messages
- referrals
- earnings
- addresses
- notifications
- payment_methods
- settings

---

## 🚀 ตัวอย่างการใช้งาน

### PostgreSQL Migration

```sql
-- สร้าง function สำหรับ default value (optional)
CREATE OR REPLACE FUNCTION get_epoch_ms()
RETURNS BIGINT AS $$
BEGIN
  RETURN (EXTRACT(EPOCH FROM NOW()) * 1000)::BIGINT;
END;
$$ LANGUAGE plpgsql;

-- สร้างตาราง users
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  world_id VARCHAR(10) UNIQUE,
  username VARCHAR(255) NOT NULL UNIQUE,
  -- ... other fields ...

  created_at BIGINT DEFAULT (EXTRACT(EPOCH FROM NOW()) * 1000)::BIGINT,
  updated_at BIGINT DEFAULT (EXTRACT(EPOCH FROM NOW()) * 1000)::BIGINT
);
```

### INSERT ตัวอย่าง

```javascript
// JavaScript (ACF Code)
const newUser = {
  id: uuid(),
  world_id: '25AAA0001',
  username: 'john',
  created_at: Date.now(),  // 1732345678000
  updated_at: Date.now()
};

// SQL
INSERT INTO users (id, world_id, username, created_at, updated_at)
VALUES ($1, $2, $3, $4, $5);
// Values: uuid, '25AAA0001', 'john', 1732345678000, 1732345678000
```

### SELECT ตัวอย่าง

```sql
-- ดึงข้อมูล
SELECT id, username, created_at FROM users WHERE world_id = '25AAA0001';
-- Returns: {id: 'uuid...', username: 'john', created_at: 1732345678000}

-- แปลงเป็น timestamp ใน SQL (ถ้าต้องการ)
SELECT
  id,
  username,
  created_at,
  to_timestamp(created_at / 1000.0) as created_at_timestamp
FROM users;
-- Returns: created_at_timestamp: 2023-11-23 10:34:38+00
```

### WHERE clause ตัวอย่าง

```sql
-- หา users ที่สร้างใน 24 ชม.ที่แล้ว
SELECT * FROM users
WHERE created_at >= (EXTRACT(EPOCH FROM NOW() - INTERVAL '24 hours') * 1000)::BIGINT;

-- หา users ที่สร้างหลัง timestamp ที่กำหนด
SELECT * FROM users
WHERE created_at > 1732345678000;
```

---

## ✅ สรุป

- ✅ แก้ `users.created_at` และ `users.updated_at` เป็น `BIGINT` แล้ว
- ✅ ตรงกับ ACF Code 100%
- ✅ ไม่ต้องแปลง type ใน application layer
- ✅ Performance ดีกว่า
- ✅ ง่ายต่อการใช้งาน

**Schema พร้อมสร้าง PostgreSQL Database แล้ว!** 🎉
