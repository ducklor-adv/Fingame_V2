# Finpoint System Analysis & Schema Design

## 🎯 ภาพรวมระบบ Finpoint

Finpoint เป็นระบบคะแนนที่ทำหน้าที่เหมือน**เงิน**ในระบบ Fingrow หมุนเวียนผ่าน:
1. การขายของมือสอง → สร้าง reversed_fp (7% จากยอดขาย)
2. การใช้จ่าย (พรบ./ประกัน) → ได้รับส่วนลดเป็น Finpoint
3. การแบ่งปันไปยัง upline 6 ชั้น

---

## 📊 กลไกการทำงาน

### 1. การสร้าง Finpoint จากยอดขาย (reversed_fp)

```
ตัวอย่าง: User A ขายของได้ 10,000 บาท
→ reversed_fp = 10,000 × 7% = 700 FP

การแบ่ง 700 FP ให้ 7 คน:
- User A (ตัวเอง): 700 / 7 = 100 FP
- Upline level 1: 100 FP
- Upline level 2: 100 FP
- Upline level 3: 100 FP
- Upline level 4: 100 FP
- Upline level 5: 100 FP
- Upline level 6: 100 FP
```

**สูตร:**
```javascript
const reversedFP = salesAmount * 0.07;
const fpPerPerson = reversedFP / 7;
```

---

### 2. การใช้ Finpoint (Expenses)

#### EXP_1: พรบ. (Compulsory Motor Insurance)
- **ราคามาตรฐาน:** 600 บาท (ผู้ใช้แก้ได้)
- **ส่วนลด:** 15%
- **เงินคืน:** 600 × 15% = 90 บาท → แปลงเป็น Finpoint

#### EXP_2: ประกันรถ (Car Insurance)
- **ราคามาตรฐาน:** 5,000 บาท (ผู้ใช้แก้ได้)
- **ส่วนลด:** 20%
- **เงินคืน:** 5,000 × 20% = 1,000 บาท → แปลงเป็น Finpoint

#### EXP_3: ประกันสุขภาพ (Health Insurance)
- **ราคามาตรฐาน:** 20,000 บาท (ผู้ใช้แก้ได้)
- **ส่วนลด:** 20%
- **เงินคืน:** 20,000 × 20% = 4,000 บาท → แปลงเป็น Finpoint

---

### 3. การแบ่งเงินคืนจาก Expenses

```
ตัวอย่าง: User A ซื้อประกันรถ 5,000 บาท
→ เงินคืน = 5,000 × 20% = 1,000 บาท (= 1,000 FP)

การแบ่ง 1,000 FP:
1. System Fee (10%):      1,000 × 10% = 100 FP → เข้าระบบ
2. Direct Discount (45%): 1,000 × 45% = 450 FP → ให้ User A
3. Shared (45%):          1,000 × 45% = 450 FP → แบ่ง 7 ส่วน

การแบ่ง 450 FP ให้ 7 คน:
- User A (ตัวเอง): 450 / 7 = 64.29 FP
- Upline level 1: 64.29 FP
- Upline level 2: 64.29 FP
- Upline level 3: 64.29 FP
- Upline level 4: 64.29 FP
- Upline level 5: 64.29 FP
- Upline level 6: 64.29 FP

สรุป User A ได้รับ:
- Direct: 450 FP
- Shared: 64.29 FP
- รวม: 514.29 FP
```

**สูตร:**
```javascript
const cashback = expenseAmount * discountRate;
const systemFee = cashback * 0.10;
const directDiscount = cashback * 0.45;
const sharedAmount = cashback * 0.45;
const fpPerPerson = sharedAmount / 7;
```

---

## 🗄️ Schema Design

### ตาราง 1: `expense_types` (ประเภทค่าใช้จ่าย)

```sql
CREATE TABLE expense_types (
  id TEXT PRIMARY KEY,                          -- UUID
  code TEXT UNIQUE NOT NULL,                    -- 'EXP_1', 'EXP_2', 'EXP_3'
  name TEXT NOT NULL,                           -- 'พรบ.', 'ประกันรถ', 'ประกันสุขภาพ'
  name_en TEXT,                                 -- 'Motor Insurance', 'Car Insurance', 'Health Insurance'

  default_amount REAL NOT NULL,                 -- ราคามาตรฐาน (600, 5000, 20000)
  discount_rate REAL NOT NULL,                  -- อัตราส่วนลด (0.15, 0.20, 0.20)

  is_active INTEGER DEFAULT 1,
  sort_order INTEGER DEFAULT 0,

  created_at BIGINT,
  updated_at BIGINT
);

-- ข้อมูลเริ่มต้น
INSERT INTO expense_types (id, code, name, name_en, default_amount, discount_rate, sort_order) VALUES
('exp-type-1', 'EXP_1', 'พรบ.', 'Compulsory Motor Insurance', 600, 0.15, 1),
('exp-type-2', 'EXP_2', 'ประกันรถ', 'Car Insurance', 5000, 0.20, 2),
('exp-type-3', 'EXP_3', 'ประกันสุขภาพ', 'Health Insurance', 20000, 0.20, 3);
```

---

### ตาราง 2: `user_expense_settings` (การตั้งค่าค่าใช้จ่ายของ User)

```sql
CREATE TABLE user_expense_settings (
  id TEXT PRIMARY KEY,                          -- UUID
  user_id TEXT NOT NULL,                        -- FK -> users(id)
  expense_type_id TEXT NOT NULL,               -- FK -> expense_types(id)

  custom_amount REAL,                           -- ราคาที่ user แก้ไข (NULL = ใช้ default)

  created_at BIGINT,
  updated_at BIGINT,

  UNIQUE(user_id, expense_type_id)
);

-- Index
CREATE INDEX idx_user_expense_user ON user_expense_settings(user_id);
```

---

### ตาราง 3: `orders` (เพิ่มฟิลด์สำหรับ reversed_fp)

แก้ไขตาราง orders ที่มีอยู่แล้ว:

```sql
-- เพิ่มฟิลด์ลงใน orders table
ALTER TABLE orders ADD COLUMN reversed_fp REAL DEFAULT 0;  -- 7% จากยอดขาย
ALTER TABLE orders ADD COLUMN reversed_fp_distributed INTEGER DEFAULT 0;  -- 0=ยังไม่แบ่ง, 1=แบ่งแล้ว
```

---

### ตาราง 4: `expense_transactions` (รายการซื้อ พรบ./ประกัน)

```sql
CREATE TABLE expense_transactions (
  id TEXT PRIMARY KEY,                          -- UUID
  transaction_number TEXT UNIQUE NOT NULL,      -- เลขที่รายการ (EXP-2025-0001)

  user_id TEXT NOT NULL,                        -- FK -> users(id) ผู้ซื้อ
  expense_type_id TEXT NOT NULL,               -- FK -> expense_types(id)

  amount REAL NOT NULL,                         -- จำนวนเงินที่จ่าย
  discount_rate REAL NOT NULL,                  -- อัตราส่วนลดที่ใช้

  cashback_total REAL NOT NULL,                 -- เงินคืนรวม (amount × discount_rate)
  cashback_system_fee REAL NOT NULL,            -- 10% เข้าระบบ
  cashback_direct REAL NOT NULL,                -- 45% ให้ตัวเอง
  cashback_shared REAL NOT NULL,                -- 45% แบ่ง 7 คน

  fp_distributed INTEGER DEFAULT 0,             -- 0=ยังไม่แบ่ง, 1=แบ่งแล้ว

  status TEXT DEFAULT 'completed',              -- pending, completed, cancelled

  -- Metadata
  provider TEXT,                                -- ชื่อบริษัทประกัน
  policy_number TEXT,                           -- เลขกรมธรรม์
  coverage_start_date BIGINT,                   -- วันเริ่มคุ้มครอง
  coverage_end_date BIGINT,                     -- วันสิ้นสุดคุ้มครอง
  notes TEXT,

  created_at BIGINT,
  updated_at BIGINT
);

-- Indexes
CREATE INDEX idx_expense_user ON expense_transactions(user_id);
CREATE INDEX idx_expense_type ON expense_transactions(expense_type_id);
CREATE INDEX idx_expense_status ON expense_transactions(status);
CREATE INDEX idx_expense_created ON expense_transactions(created_at);
```

---

### ตาราง 5: `finpoint_ledger` (สมุดรายวัน Finpoint)

บันทึกทุก transaction แบบ Double-Entry Bookkeeping (Dr./Cr.)

```sql
CREATE TABLE finpoint_ledger (
  id TEXT PRIMARY KEY,                          -- UUID
  entry_number TEXT UNIQUE NOT NULL,            -- เลขที่รายการ (FP-2025-0001)

  -- Transaction Info
  user_id TEXT NOT NULL,                        -- FK -> users(id) เจ้าของบัญชี
  transaction_date BIGINT NOT NULL,             -- Epoch milliseconds

  -- Date components (เพื่อให้ง่ายต่อการสรุปยอด)
  day INTEGER NOT NULL,                         -- 1-31
  month INTEGER NOT NULL,                       -- 1-12
  year INTEGER NOT NULL,                        -- 2025

  -- Accounting (Dr./Cr.)
  dr_fp REAL DEFAULT 0,                         -- Debit (เพิ่ม)
  cr_fp REAL DEFAULT 0,                         -- Credit (ลด)
  balance REAL NOT NULL,                        -- ยอดคงเหลือหลัง transaction

  -- Source Information
  source_type TEXT NOT NULL,                    -- 'SALE_REVERSED', 'EXPENSE_DIRECT', 'EXPENSE_SHARED', 'EXPENSE_UPLINE', 'ADJUSTMENT'
  source_id TEXT,                               -- FK -> orders(id) หรือ expense_transactions(id)
  source_user_id TEXT,                          -- FK -> users(id) ผู้สร้าง reversed_fp หรือผู้ซื้อประกัน

  -- Distribution Info (สำหรับการแบ่ง)
  distribution_level INTEGER,                   -- 0=ตัวเอง, 1-6=upline level
  original_amount REAL,                         -- จำนวน FP รวมก่อนแบ่ง

  description TEXT,                             -- คำอธิบายรายการ
  notes TEXT,

  created_at BIGINT
);

-- Indexes
CREATE INDEX idx_fp_ledger_user ON finpoint_ledger(user_id);
CREATE INDEX idx_fp_ledger_date ON finpoint_ledger(transaction_date);
CREATE INDEX idx_fp_ledger_year_month ON finpoint_ledger(year, month);
CREATE INDEX idx_fp_ledger_source ON finpoint_ledger(source_type, source_id);
CREATE INDEX idx_fp_ledger_source_user ON finpoint_ledger(source_user_id);
```

---

### ตาราง 6: `finpoint_summary` (สรุปยอด Finpoint)

สำหรับ cache ยอดรวมเพื่อ performance

```sql
CREATE TABLE finpoint_summary (
  id TEXT PRIMARY KEY,                          -- UUID
  user_id TEXT NOT NULL UNIQUE,                 -- FK -> users(id)

  -- Totals
  total_earned REAL DEFAULT 0,                  -- รับมาทั้งหมด (Dr. รวม)
  total_spent REAL DEFAULT 0,                   -- ใช้ไปทั้งหมด (Cr. รวม)
  balance REAL DEFAULT 0,                       -- คงเหลือ (Dr. - Cr.)

  -- Breakdown by source
  earned_from_sales REAL DEFAULT 0,             -- จากขายของมือสอง
  earned_from_expense_direct REAL DEFAULT 0,    -- ส่วนลดตรง 45%
  earned_from_expense_shared REAL DEFAULT 0,    -- ส่วนแบ่ง 45% / 7
  earned_from_upline REAL DEFAULT 0,            -- ได้จาก downline ของเรา

  -- Monthly tracking
  current_month_earned REAL DEFAULT 0,
  current_month_spent REAL DEFAULT 0,

  last_transaction_at BIGINT,

  created_at BIGINT,
  updated_at BIGINT
);

-- Index
CREATE INDEX idx_fp_summary_balance ON finpoint_summary(balance);
```

---

## 📝 ตัวอย่างการบันทึก

### ตัวอย่าง 1: User A ขายของได้ 10,000 บาท

```sql
-- 1. บันทึกใน orders
INSERT INTO orders (..., total_amount, reversed_fp, reversed_fp_distributed)
VALUES (..., 10000, 700, 0);  -- 7% = 700 FP

-- 2. แบ่ง FP ให้ 7 คน (100 FP/คน)
-- User A (ตัวเอง)
INSERT INTO finpoint_ledger (
  user_id, day, month, year, dr_fp, cr_fp, balance,
  source_type, source_id, source_user_id,
  distribution_level, original_amount, description
) VALUES (
  'user-a-id', 23, 1, 2025, 100, 0, 100,
  'SALE_REVERSED', 'order-123', 'user-a-id',
  0, 700, 'Reversed FP from sales (self)'
);

-- Upline Level 1
INSERT INTO finpoint_ledger (...) VALUES (
  'upline-1-id', 23, 1, 2025, 100, 0, [balance],
  'SALE_REVERSED', 'order-123', 'user-a-id',
  1, 700, 'Reversed FP from downline (level 1)'
);

-- ... ทำแบบเดียวกันสำหรับ upline level 2-6

-- 3. อัพเดท orders
UPDATE orders SET reversed_fp_distributed = 1 WHERE id = 'order-123';

-- 4. อัพเดท summary
UPDATE finpoint_summary
SET
  total_earned = total_earned + 100,
  earned_from_sales = earned_from_sales + 100,
  balance = balance + 100,
  current_month_earned = current_month_earned + 100
WHERE user_id = 'user-a-id';
```

---

### ตัวอย่าง 2: User B ซื้อประกันรถ 5,000 บาท (ส่วนลด 20%)

```sql
-- 1. บันทึกใน expense_transactions
INSERT INTO expense_transactions (
  id, user_id, expense_type_id, amount, discount_rate,
  cashback_total, cashback_system_fee, cashback_direct, cashback_shared,
  fp_distributed
) VALUES (
  'exp-001', 'user-b-id', 'exp-type-2', 5000, 0.20,
  1000,  -- 20% cashback
  100,   -- 10% system fee
  450,   -- 45% direct
  450,   -- 45% shared
  0      -- ยังไม่แบ่ง
);

-- 2. บันทึก Direct Discount (450 FP)
INSERT INTO finpoint_ledger (...) VALUES (
  'user-b-id', 23, 1, 2025, 450, 0, [balance],
  'EXPENSE_DIRECT', 'exp-001', 'user-b-id',
  NULL, 1000, 'Direct discount from car insurance (45%)'
);

-- 3. แบ่ง Shared Amount (450 FP / 7 = 64.29 FP/คน)
-- User B (ตัวเอง)
INSERT INTO finpoint_ledger (...) VALUES (
  'user-b-id', 23, 1, 2025, 64.29, 0, [balance],
  'EXPENSE_SHARED', 'exp-001', 'user-b-id',
  0, 450, 'Shared cashback from expense (self)'
);

-- Upline Level 1-6 (ทำแบบเดียวกัน)
INSERT INTO finpoint_ledger (...) VALUES (
  'upline-1-id', 23, 1, 2025, 64.29, 0, [balance],
  'EXPENSE_UPLINE', 'exp-001', 'user-b-id',
  1, 450, 'Shared cashback from downline expense'
);

-- ... level 2-6

-- 4. บันทึก System Fee (ไม่แจกให้ user)
-- (Optional: อาจมีตาราง system_revenue แยก)

-- 5. อัพเดท expense_transactions
UPDATE expense_transactions SET fp_distributed = 1 WHERE id = 'exp-001';

-- 6. อัพเดท summary
UPDATE finpoint_summary
SET
  total_earned = total_earned + 514.29,  -- 450 + 64.29
  earned_from_expense_direct = earned_from_expense_direct + 450,
  earned_from_expense_shared = earned_from_expense_shared + 64.29,
  balance = balance + 514.29
WHERE user_id = 'user-b-id';
```

---

## 🔍 การ Query ข้อมูล

### ดูยอด Finpoint ของ User

```sql
SELECT * FROM finpoint_summary WHERE user_id = 'user-a-id';
```

### ดูประวัติรายการทั้งหมด (Ledger)

```sql
SELECT
  entry_number,
  transaction_date,
  dr_fp,
  cr_fp,
  balance,
  source_type,
  description
FROM finpoint_ledger
WHERE user_id = 'user-a-id'
ORDER BY transaction_date DESC;
```

### สรุปยอดรายเดือน

```sql
SELECT
  year,
  month,
  SUM(dr_fp) as total_earned,
  SUM(cr_fp) as total_spent,
  SUM(dr_fp) - SUM(cr_fp) as net
FROM finpoint_ledger
WHERE user_id = 'user-a-id'
GROUP BY year, month
ORDER BY year DESC, month DESC;
```

### ดู Top Earners

```sql
SELECT
  u.username,
  fs.balance,
  fs.earned_from_sales,
  fs.earned_from_upline
FROM finpoint_summary fs
JOIN users u ON fs.user_id = u.id
ORDER BY fs.balance DESC
LIMIT 10;
```

---

## ✅ สรุปฟิลด์ที่ต้องเพิ่ม/สร้าง

### ตารางใหม่:
1. ✅ `expense_types` - ประเภทค่าใช้จ่าย (EXP_1, EXP_2, EXP_3)
2. ✅ `user_expense_settings` - การตั้งค่าราคาของแต่ละ user
3. ✅ `expense_transactions` - รายการซื้อ พรบ./ประกัน
4. ✅ `finpoint_ledger` - สมุดรายวัน (Dr./Cr.)
5. ✅ `finpoint_summary` - สรุปยอด FP (cache)

### แก้ไขตารางเดิม:
6. ✅ `orders` - เพิ่ม `reversed_fp` และ `reversed_fp_distributed`

---

## 🎯 Next Steps

1. สร้างตาราง SQL ใน PostgreSQL
2. เขียน Stored Procedures/Functions สำหรับ:
   - `distribute_reversed_fp(order_id)` - แบ่ง FP จากยอดขาย
   - `distribute_expense_cashback(expense_id)` - แบ่ง FP จาก expense
   - `recalculate_summary(user_id)` - คำนวณยอดรวมใหม่
3. เขียน API endpoints
4. สร้าง Dashboard แสดงยอด FP

ต้องการให้ผมสร้าง SQL script หรือ API endpoints ต่อไหมครับ?
