# 🗄️ Fingrow Database Access Guide

## 📊 ข้อมูลทั้งหมดเป็นข้อมูลจริงจากฐานข้อมูล PostgreSQL แล้ว!

### ✅ การแก้ไขที่ทำแล้ว

เราได้แก้ไขไฟล์ `fingrow-app-mobile.html` ให้ดึงข้อมูลจริงจาก API ทั้งหมดแล้ว:

1. **Dashboard (หน้าแรก)**
   - ✅ ยอด Finpoint จริงจากฐานข้อมูล
   - ✅ FP ที่เพิ่มวันนี้ (Real-time)
   - ✅ รายการธุรกรรมล่าสุด
   - ✅ ข้อมูลเครือข่าย ACF
   - ✅ **Insurance Level Progress** (เชื่อมกับ API แล้ว!)

2. **Network Tree Page**
   - ✅ โครงสร้างเครือข่ายจริงจากฐานข้อมูล
   - ✅ จำนวนลูกข่ายแต่ละคน
   - ✅ Loading state แสดงสถานะการโหลด

3. **ACF Network Page**
   - ✅ ตารางเครือข่าย ACF จริง
   - ✅ Parent-Child relationships
   - ✅ ACF accepting status

4. **Database Viewer Page**
   - ✅ ดูตารางฐานข้อมูลทั้งหมด
   - ✅ Quick access links

---

## 🔗 ลิงค์เข้าดูฐานข้อมูล

### 1. เข้าใช้งานเว็บแอป
```
http://localhost:3001/fingrow-app-mobile.html
```

### 2. API Endpoints สำหรับดูข้อมูล

#### 📋 ดูรายการตารางทั้งหมด
```
http://localhost:3001/api/database/tables
```

#### 👥 ดูข้อมูลผู้ใช้ทั้งหมด
```
http://localhost:3001/api/database/users/all
```

#### 🗃️ ดูข้อมูลในตารางเฉพาะ (เปลี่ยน {tableName} ตามต้องการ)
```
http://localhost:3001/api/database/tables/{tableName}
```

**ตัวอย่าง:**
- Users: `http://localhost:3001/api/database/tables/users`
- Transactions: `http://localhost:3001/api/database/tables/simulated_fp_transactions`
- Ledger: `http://localhost:3001/api/database/tables/simulated_fp_ledger`
- Products: `http://localhost:3001/api/database/tables/products`
- Orders: `http://localhost:3001/api/database/tables/orders`

---

## 📊 ตารางฐานข้อมูลที่สำคัญ

### 1. **users** - ข้อมูลผู้ใช้
- World ID, Username, Email, Phone
- ACF tree structure (parent_id, child_count, level)
- Finpoint balances (own_finpoint, total_finpoint)
- ที่อยู่และข้อมูลส่วนตัว

### 2. **simulated_fp_transactions** - ธุรกรรม Finpoint
- การทำธุรกรรม FP ทั้งหมด
- ประเภท: ขายของ, โบนัส, ซื้อประกัน
- สถานะ, จำนวน, วันที่

### 3. **simulated_fp_ledger** - บัญชีแยกประเภท FP
- รายการเดบิต/เครดิต (DR/CR)
- ยอดคงเหลือหลังแต่ละรายการ
- ประวัติการทำธุรกรรม

### 4. **products** - สินค้า
- รายการสินค้าในระบบ
- ราคา, หมวดหมู่, รายละเอียด
- สถานะการขาย

### 5. **orders** - คำสั่งซื้อ
- ประวัติการสั่งซื้อ
- สถานะคำสั่งซื้อ
- ข้อมูลการจัดส่ง

---

## 🎯 ข้อมูลทดสอบที่มีอยู่

### ผู้ใช้ทดสอบ:

#### 1. System Root
- **World ID**: 25AAA0000
- **Username**: system_root
- **Email**: root@fingrow.com
- **Role**: Root ของระบบ

#### 2. Somchai Jaidee
- **World ID**: 25AAA0001
- **Username**: somchai_jaidee
- **Email**: somchai@fingrow.com
- **Phone**: 0812345678
- **FP Balance**: 3,250 FP
- **Level**: 1

#### 3. Somsri Rakdee
- **World ID**: 25AAA0002
- **Username**: somsri_rakdee
- **Email**: somsri@fingrow.com
- **Phone**: 0823456789
- **FP Balance**: 1,500 FP
- **Parent**: 25AAA0001 (Somchai)

---

## 🔧 เปิดใช้งานเว็บแอป

### 1. เริ่ม Server
```bash
cd d:\Fingame
node server.js
```

### 2. เปิดเว็บ
```
http://localhost:3001/fingrow-app-mobile.html
```

### 3. เข้าใช้งานด้วย Test User
- กดที่หน้า Profile
- ระบบจะใช้ User ID: `4d003630-3ed6-4d80-89fd-5c1d2f017be1` (25AAA0001)
- หรือแก้ localStorage ด้วย Developer Tools

---

## 🗂️ Database Viewer ในแอป

ในแอปมีหน้า **Database Viewer** ที่สามารถ:

1. เลือกดูตารางต่างๆ ในฐานข้อมูล
2. ดูข้อมูลแบบ real-time
3. Export ข้อมูลผ่าน API

### วิธีเข้าใช้:
1. เปิดแอป: `http://localhost:3001/fingrow-app-mobile.html`
2. คลิกที่แท็บ **🗄️ Database** ที่ Bottom Navigation
3. เลือกตารางที่ต้องการดู

---

## 📝 API Endpoints สำหรับดูข้อมูล

### User APIs
```
GET /api/users/:id                  - ดูข้อมูลผู้ใช้
GET /api/users/world/:worldId       - ดูข้อมูลจาก World ID
GET /api/users/username/:username   - ดูข้อมูลจาก Username
GET /api/users/:id/stats            - สถิติผู้ใช้
```

### Finpoint APIs
```
GET /api/finpoint/:userId/balance       - ยอดคงเหลือ
GET /api/finpoint/:userId/transactions  - รายการธุรกรรม
GET /api/finpoint/:userId/ledger        - บัญชีแยกประเภท
GET /api/finpoint/:userId/today         - ข้อมูลวันนี้
```

### Network APIs
```
GET /api/network/:userId/tree       - โครงสร้างเครือข่าย
GET /api/network/:userId/summary    - สรุปเครือข่าย
GET /api/network/:userId/acf        - ตาราง ACF
GET /api/network/:userId/upline     - เส้นทาง upline
```

### Insurance APIs
```
GET /api/insurance/:userId/levels   - ระดับประกัน
POST /api/insurance/:userId/purchase - ซื้อประกัน
```

### Database APIs
```
GET /api/database/tables            - รายการตาราง
GET /api/database/tables/:tableName - ข้อมูลตาราง
GET /api/database/users/all         - ผู้ใช้ทั้งหมด
```

---

## 🎨 การทดสอบข้อมูล

### ทดสอบ Dashboard
```bash
# ดูยอด FP
curl http://localhost:3001/api/finpoint/4d003630-3ed6-4d80-89fd-5c1d2f017be1/balance

# ดูธุรกรรม
curl http://localhost:3001/api/finpoint/4d003630-3ed6-4d80-89fd-5c1d2f017be1/transactions

# ดูข้อมูลวันนี้
curl http://localhost:3001/api/finpoint/4d003630-3ed6-4d80-89fd-5c1d2f017be1/today
```

### ทดสอบ Network
```bash
# ดู Network Tree
curl http://localhost:3001/api/network/4d003630-3ed6-4d80-89fd-5c1d2f017be1/tree

# ดู ACF Network
curl http://localhost:3001/api/network/4d003630-3ed6-4d80-89fd-5c1d2f017be1/acf
```

### ทดสอบ Insurance
```bash
# ดูระดับประกัน
curl http://localhost:3001/api/insurance/4d003630-3ed6-4d80-89fd-5c1d2f017be1/levels
```

---

## 🔍 การตรวจสอบฐานข้อมูลโดยตรง

### ถ้ามี psql ติดตั้ง:
```bash
psql -h localhost -p 5433 -U fingrow_user -d fingame
```

Password: `fingrow_pass_2025`

### SQL Queries ตัวอย่าง:
```sql
-- ดูผู้ใช้ทั้งหมด
SELECT world_id, username, email, own_finpoint, child_count
FROM users
ORDER BY created_at DESC;

-- ดูธุรกรรมล่าสุด
SELECT u.world_id, u.username, l.dr_cr, l.simulated_fp_amount,
       l.simulated_balance_after, l.simulated_tx_datetime
FROM simulated_fp_ledger l
JOIN users u ON l.user_id = u.id
ORDER BY l.simulated_tx_datetime DESC
LIMIT 10;

-- ดูเครือข่าย ACF
SELECT world_id, username, parent_id, level, child_count, acf_accepting
FROM users
WHERE parent_id IS NOT NULL
ORDER BY level, created_at;
```

---

## ✅ สรุป

**ทุกหน้าในเว็บแอปใช้ข้อมูลจริงจากฐานข้อมูล PostgreSQL แล้ว!**

- ✅ Dashboard → Real FP balance, transactions, network data
- ✅ Insurance Levels → Real API data
- ✅ Network Tree → Real database structure
- ✅ ACF Network → Real ACF table
- ✅ Database Viewer → Direct database access

**ไม่มี Mock Data เหลืออยู่แล้ว!** 🎉

---

## 🚀 Next Steps

1. เปิด server: `node server.js`
2. เข้าเว็บ: http://localhost:3001/fingrow-app-mobile.html
3. ดู Database: คลิกแท็บ 🗄️ Database
4. ทดสอบ API: เปิด browser ที่ลิงค์ด้านบน

---

**สร้างเมื่อ:** 30 พฤศจิกายน 2025
**Version:** 2.0 - Production Ready with Real Database
