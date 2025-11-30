# Fingrow Database Setup Guide

## 📦 วิธีที่ 1: ใช้ Docker (แนะนำ - ง่ายที่สุด)

### ขั้นตอน:

1. **ติดตั้ง Docker Desktop**
   ```
   https://www.docker.com/products/docker-desktop
   ```

2. **รัน Database ด้วย Docker Compose**
   ```bash
   # เปิด terminal ที่โฟลเดอร์ d:\Fingame
   cd d:\Fingame

   # สร้างและรัน PostgreSQL
   docker-compose up -d
   ```

3. **รอให้ Database พร้อม** (ประมาณ 10-20 วินาที)
   ```bash
   # ตรวจสอบสถานะ
   docker-compose ps

   # ดู logs
   docker-compose logs postgres
   ```

4. **เข้าใช้งาน Database**

   **Option A: ใช้ Adminer (Web UI)**
   - เปิดเบราว์เซอร์: http://localhost:8080
   - Server: `postgres`
   - Username: `fingrow_user`
   - Password: `fingrow_pass_2025`
   - Database: `fingrow`

   **Option B: ใช้ psql command line**
   ```bash
   docker exec -it fingrow-postgres psql -U fingrow_user -d fingrow
   ```

5. **ตรวจสอบว่าตารางถูกสร้างแล้ว**
   ```sql
   -- ดูรายชื่อตาราง
   \dt

   -- ตรวจสอบ System Root User
   SELECT * FROM users WHERE world_id = '25AAA0000';

   -- นับจำนวนตาราง
   SELECT COUNT(*) FROM information_schema.tables
   WHERE table_schema = 'public';
   ```

### 🛑 หยุด/ลบ Database:

```bash
# หยุด (ข้อมูลยังอยู่)
docker-compose stop

# รัน Database อีกครั้ง
docker-compose start

# ลบทั้งหมด (รวมข้อมูล)
docker-compose down -v
```

---

## 📦 วิธีที่ 2: ติดตั้ง PostgreSQL บนเครื่อง

### Windows:

1. **Download PostgreSQL**
   ```
   https://www.postgresql.org/download/windows/
   ```

2. **ติดตั้งตามขั้นตอน** (เลือก password สำหรับ postgres user)

3. **สร้าง Database**
   ```bash
   # เปิด SQL Shell (psql)
   createdb -U postgres fingrow
   ```

4. **รัน Init Script**
   ```bash
   psql -U postgres -d fingrow -f "d:\Fingame\init_postgres.sql"
   ```

### macOS (Homebrew):

```bash
# ติดตั้ง
brew install postgresql@16

# เริ่มบริการ
brew services start postgresql@16

# สร้าง database
createdb fingrow

# รัน script
psql -d fingrow -f init_postgres.sql
```

### Linux (Ubuntu/Debian):

```bash
# ติดตั้ง
sudo apt update
sudo apt install postgresql postgresql-contrib

# เข้า postgres user
sudo -u postgres psql

# สร้าง database
CREATE DATABASE fingrow;
\q

# รัน script
sudo -u postgres psql -d fingrow -f init_postgres.sql
```

---

## 🔌 Connection String

หลังจากสร้าง Database แล้ว ใช้ Connection String นี้เพื่อเชื่อมต่อจาก Application:

### Docker:
```
postgresql://fingrow_user:fingrow_pass_2025@localhost:5432/fingrow
```

### Local PostgreSQL:
```
postgresql://postgres:YOUR_PASSWORD@localhost:5432/fingrow
```

---

## 📊 ข้อมูลเบื้องต้น

Database จะมี:
- ✅ **18 ตาราง** (users, products, orders, simulated_fp_transactions, ...)
- ✅ **40+ indexes** สำหรับ performance
- ✅ **3 views** (v_active_users_acf, v_user_network_summary, v_simulated_fp_summary)
- ✅ **System Root User** (world_id: `25AAA0000`, run_number: 0)
- ✅ **Auto-triggers** สำหรับ `updated_at`

---

## 🧪 ทดสอบ Database

```sql
-- 1. ตรวจสอบตาราง
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
ORDER BY table_name;

-- 2. ดู System Root User
SELECT id, world_id, username, run_number, level, acf_accepting
FROM users
WHERE world_id = '25AAA0000';

-- 3. สร้าง Test User (ACF first signup)
INSERT INTO users (
  world_id, username, run_number, parent_id, level, acf_accepting
) VALUES (
  '25AAA0001',
  'test_user_1',
  1,
  (SELECT id FROM users WHERE world_id = '25AAA0000'),
  1,
  TRUE
);

-- 4. ตรวจสอบ Test User
SELECT * FROM v_active_users_acf;

-- 5. ทดสอบ Simulation Tables
INSERT INTO simulated_fp_transactions (
  user_id,
  simulated_tx_type,
  simulated_source_type,
  simulated_base_amount,
  simulated_reverse_rate,
  simulated_generated_fp,
  simulated_self_fp,
  simulated_network_fp
) VALUES (
  (SELECT id FROM users WHERE world_id = '25AAA0001'),
  'SECONDHAND_SALE',
  'SIM_SECONDHAND_SALE',
  10000.00,
  0.07,
  700.00,
  315.00,
  315.00
);

-- 6. ดู Summary
SELECT * FROM v_simulated_fp_summary;
```

---

## 🆘 Troubleshooting

### Docker ไม่ขึ้น:
```bash
# ตรวจสอบว่า Docker Desktop เปิดอยู่หรือไม่
docker ps

# ดู logs เพื่อดู error
docker-compose logs -f postgres
```

### ติดตั้ง PostgreSQL แล้วแต่ใช้ไม่ได้:
```bash
# Windows: เพิ่ม PostgreSQL bin ใน PATH
C:\Program Files\PostgreSQL\16\bin

# ทดสอบ
psql --version
```

### Port 5432 ถูกใช้งานแล้ว:
```yaml
# แก้ไขใน docker-compose.yml
ports:
  - "5433:5432"  # เปลี่ยนจาก 5432 เป็น 5433
```

---

## 🚀 ขั้นตอนต่อไป

หลังจากสร้าง Database แล้ว คุณสามารถ:

1. **เชื่อมต่อจาก Application** (Node.js, Python, etc.)
2. **สร้าง API endpoints** เพื่อ CRUD operations
3. **Integration กับ ACF Code** (Original ACF code.jsx)
4. **ทดสอบ Finpoint Simulation System**
5. **สร้าง Seed Data** สำหรับทดสอบ

---

**Database พร้อมใช้งาน!** 🎉
