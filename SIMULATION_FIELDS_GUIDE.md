# Simulation Fields Guide - ฟิลด์สำหรับจำลองระบบ

## 🎯 วัตถุประสงค์

ฟิลด์เหล่านี้ใช้เก็บข้อมูล**ประมาณการ**จากผู้ใช้ เพื่อใช้ในการ**จำลอง (simulate)** ยอดขาย/รายได้ทั้งระบบ

---

## 📊 ฟิลด์ที่เพิ่มเข้ามา

### 1. `estimated_inventory_value`

**ชนิดข้อมูล:** `REAL DEFAULT 0.0`

**คำอธิบาย:**
- มูลค่าสินค้ามือสองโดยประมาณที่ผู้ใช้**คาดว่า**จะนำมาขายในระบบ
- หน่วย: THB (บาท)
- ใช้สำหรับคำนวณ potential revenue ของระบบ

**ตัวอย่างการใช้งาน:**
```javascript
// ผู้ใช้กรอกว่ามีของมูลค่า 50,000 บาท
estimated_inventory_value: 50000.00

// ระบบคำนวณ potential fee (2%)
const potentialFee = estimated_inventory_value * 0.02;  // 1,000 บาท
```

---

### 2. `estimated_item_count`

**ชนิดข้อมูล:** `INTEGER DEFAULT 0`

**คำอธิบาย:**
- จำนวนชิ้นสินค้าโดยประมาณที่ผู้ใช้**คาดว่า**จะนำมาขาย
- หน่วย: ชิ้น
- ใช้สำหรับคำนวณ average item price

**ตัวอย่างการใช้งาน:**
```javascript
// ผู้ใช้กรอกว่ามีของ 10 ชิ้น มูลค่ารวม 50,000 บาท
estimated_item_count: 10
estimated_inventory_value: 50000

// ระบบคำนวณ average price per item
const avgPrice = estimated_inventory_value / estimated_item_count;  // 5,000 บาท/ชิ้น
```

---

## 🔍 การใช้งานในระบบ Simulation

### Scenario 1: คำนวณ Total Potential Revenue

```sql
-- ดูมูลค่ารวมทั้งระบบ
SELECT
  COUNT(*) as total_users,
  SUM(estimated_inventory_value) as total_potential_value,
  SUM(estimated_item_count) as total_potential_items,
  AVG(estimated_inventory_value) as avg_value_per_user,
  AVG(estimated_item_count) as avg_items_per_user
FROM users
WHERE estimated_inventory_value > 0;
```

**ตัวอย่างผลลัพธ์:**
```
total_users: 1,000
total_potential_value: 50,000,000 (50 ล้านบาท)
total_potential_items: 10,000 (10,000 ชิ้น)
avg_value_per_user: 50,000 (5 หมื่นบาท/คน)
avg_items_per_user: 10 (10 ชิ้น/คน)
```

---

### Scenario 2: คำนวณ Community Fee Potential

```sql
-- คำนวณค่าธรรมเนียมรวมที่อาจได้รับ (2%)
SELECT
  SUM(estimated_inventory_value * 0.02) as potential_community_fee,
  SUM(estimated_inventory_value * 0.98) as potential_seller_revenue
FROM users;
```

**ตัวอย่างผลลัพธ์:**
```
potential_community_fee: 1,000,000 (1 ล้านบาท)
potential_seller_revenue: 49,000,000 (49 ล้านบาท)
```

---

### Scenario 3: จำลองการกระจายรายได้ใน ACF Network

```sql
-- คำนวณ potential earning ตาม ACF tree
WITH RECURSIVE acf_tree AS (
  SELECT
    id,
    parent_id,
    estimated_inventory_value * 0.02 as commission,
    1 as level
  FROM users
  WHERE parent_id IS NOT NULL

  UNION ALL

  SELECT
    u.id,
    u.parent_id,
    acf_tree.commission * 0.1 as commission,  -- 10% ของค่าธรรมเนียมไปให้ parent
    acf_tree.level + 1
  FROM users u
  INNER JOIN acf_tree ON u.id = acf_tree.parent_id
  WHERE acf_tree.level < 7  -- สูงสุด 7 level
)
SELECT
  id,
  SUM(commission) as total_potential_acf_earning
FROM acf_tree
GROUP BY id
ORDER BY total_potential_acf_earning DESC
LIMIT 10;
```

---

### Scenario 4: Segmentation ตามมูลค่าสินค้า

```sql
-- แบ่งกลุ่มผู้ใช้ตามมูลค่าสินค้า
SELECT
  CASE
    WHEN estimated_inventory_value = 0 THEN '0. No Estimate'
    WHEN estimated_inventory_value < 10000 THEN '1. < 10K'
    WHEN estimated_inventory_value < 50000 THEN '2. 10K-50K'
    WHEN estimated_inventory_value < 100000 THEN '3. 50K-100K'
    WHEN estimated_inventory_value < 500000 THEN '4. 100K-500K'
    ELSE '5. >= 500K'
  END as segment,
  COUNT(*) as user_count,
  SUM(estimated_inventory_value) as total_value,
  AVG(estimated_inventory_value) as avg_value
FROM users
GROUP BY segment
ORDER BY segment;
```

**ตัวอย่างผลลัพธ์:**
```
segment        | user_count | total_value  | avg_value
---------------|------------|--------------|----------
0. No Estimate | 500        | 0            | 0
1. < 10K       | 200        | 1,000,000    | 5,000
2. 10K-50K     | 200        | 6,000,000    | 30,000
3. 50K-100K    | 80         | 6,000,000    | 75,000
4. 100K-500K   | 15         | 4,500,000    | 300,000
5. >= 500K     | 5          | 3,500,000    | 700,000
```

---

## 📝 UI/UX Recommendations

### ในหน้า Registration/Onboarding:

```
┌─────────────────────────────────────────────────────────┐
│ ช่วยเราประมาณการสินค้าของคุณ (ไม่บังคับ)              │
├─────────────────────────────────────────────────────────┤
│                                                         │
│ 💰 มูลค่าสินค้ามือสองที่คุณมี (โดยประมาณ)            │
│ ┌──────────────────┐                                   │
│ │ 50,000          │ บาท                               │
│ └──────────────────┘                                   │
│                                                         │
│ 📦 จำนวนสินค้าที่คุณมี (โดยประมาณ)                   │
│ ┌──────────────────┐                                   │
│ │ 10              │ ชิ้น                              │
│ └──────────────────┘                                   │
│                                                         │
│ 💡 ข้อมูลนี้ใช้สำหรับจำลองระบบเท่านั้น                │
│    ไม่มีผลต่อการใช้งานจริง                            │
│                                                         │
│ [ข้าม]                              [บันทึกข้อมูล]    │
└─────────────────────────────────────────────────────────┘
```

### Validation Rules:

```javascript
// Frontend validation
const validateEstimation = (value, count) => {
  // ค่าต้องไม่ติดลบ
  if (value < 0 || count < 0) {
    return "กรุณากรอกตัวเลขที่มากกว่าหรือเท่ากับ 0";
  }

  // ถ้ากรอกมูลค่า ต้องกรอกจำนวนด้วย
  if (value > 0 && count === 0) {
    return "กรุณากรอกจำนวนสินค้าด้วย";
  }

  // ถ้ากรอกจำนวน ต้องกรอกมูลค่าด้วย
  if (count > 0 && value === 0) {
    return "กรุณากรอกมูลค่าสินค้าด้วย";
  }

  // Average price ต้องสมเหตุสมผล (100-10,000,000 บาทต่อชิ้น)
  if (value > 0 && count > 0) {
    const avgPrice = value / count;
    if (avgPrice < 100) {
      return "ราคาเฉลี่ยต่ำเกินไป (ต่ำกว่า 100 บาท/ชิ้น)";
    }
    if (avgPrice > 10000000) {
      return "ราคาเฉลี่ยสูงเกินไป (สูงกว่า 10 ล้านบาท/ชิ้น)";
    }
  }

  return null; // Valid
};
```

---

## 🔧 Database Schema (PostgreSQL)

```sql
-- ตาราง users (excerpt)
CREATE TABLE users (
  -- ... other fields ...

  trust_score DECIMAL(10, 2) DEFAULT 0.0,
  total_sales INTEGER DEFAULT 0,
  total_purchases INTEGER DEFAULT 0,

  -- Estimated inventory for simulation
  estimated_inventory_value DECIMAL(15, 2) DEFAULT 0.0,  -- มูลค่าสินค้าที่คาดว่าจะนำมาขาย (THB)
  estimated_item_count INTEGER DEFAULT 0,                -- จำนวนชิ้นที่คาดว่าจะนำมาขาย

  -- ... other fields ...
);

-- Index สำหรับ simulation queries
CREATE INDEX idx_users_estimated_value ON users(estimated_inventory_value)
  WHERE estimated_inventory_value > 0;
```

---

## ⚠️ ข้อควรระวัง

### 1. ข้อมูลนี้เป็นเพียงประมาณการ
- **ไม่ใช่**ข้อมูลจริง
- **ไม่ผูกพัน**กับการขายจริง
- ใช้สำหรับ **simulation** เท่านั้น

### 2. ไม่ควรใช้เป็น Commitment
- ผู้ใช้อาจกรอกตัวเลขไม่ตรงกับความเป็นจริง
- ไม่ควรนำไปคำนวณ revenue projection แบบแน่นอน

### 3. Privacy
- ข้อมูลนี้เป็นความลับของผู้ใช้
- ไม่ควรแสดงต่อ public
- ควร aggregate ก่อนแสดง (เช่น ยอดรวมทั้งระบบ)

---

## 📊 ตัวอย่าง Simulation Dashboard

```javascript
// Frontend: Simulation Dashboard Component
const SimulationDashboard = ({ users }) => {
  const stats = {
    totalUsers: users.length,
    usersWithEstimate: users.filter(u => u.estimated_inventory_value > 0).length,
    totalPotentialValue: users.reduce((sum, u) => sum + u.estimated_inventory_value, 0),
    totalPotentialItems: users.reduce((sum, u) => sum + u.estimated_item_count, 0),
    potentialCommunityFee: users.reduce((sum, u) => sum + (u.estimated_inventory_value * 0.02), 0),
  };

  return (
    <div className="dashboard">
      <h2>System Simulation (Based on User Estimates)</h2>

      <div className="stat-card">
        <h3>Total Users</h3>
        <p>{stats.totalUsers.toLocaleString()}</p>
        <small>{stats.usersWithEstimate} provided estimates</small>
      </div>

      <div className="stat-card">
        <h3>Potential GMV</h3>
        <p>฿{stats.totalPotentialValue.toLocaleString()}</p>
        <small>{stats.totalPotentialItems.toLocaleString()} items</small>
      </div>

      <div className="stat-card">
        <h3>Potential Community Fee (2%)</h3>
        <p>฿{stats.potentialCommunityFee.toLocaleString()}</p>
      </div>

      <div className="stat-card">
        <h3>Average per User</h3>
        <p>฿{(stats.totalPotentialValue / stats.usersWithEstimate).toLocaleString()}</p>
        <small>{(stats.totalPotentialItems / stats.usersWithEstimate).toFixed(1)} items</small>
      </div>
    </div>
  );
};
```

---

## ✅ สรุป

ฟิลด์ใหม่:
- ✅ `estimated_inventory_value` - มูลค่าสินค้าประมาณการ (THB)
- ✅ `estimated_item_count` - จำนวนสินค้าประมาณการ (ชิ้น)

ใช้สำหรับ:
- ✅ จำลองยอดขายรวมของระบบ
- ✅ คำนวณ potential revenue
- ✅ วิเคราะห์ user segments
- ✅ Forecast ACF earnings
- ✅ Dashboard analytics

**หมายเหตุ:** ข้อมูลเป็นเพียงประมาณการ ไม่ใช่ความจริง!
