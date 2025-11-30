# 🚀 Fingrow - คู่มือติดตั้งและใช้งาน

## ✅ สิ่งที่ทำเสร็จแล้ว (Completed)

### 1. Backend API (Production-Ready)
✅ **Express Server** - พร้อมใช้งาน
✅ **PostgreSQL Integration** - เชื่อมต่อ database สำเร็จ
✅ **API Endpoints ครบถ้วน:**
  - Users API (CRUD, stats, children, upline)
  - Finpoint API (balance, transactions, ledger, today earnings)
  - Network API (tree, summary, ACF table, upline)
  - Insurance API (levels, purchase, use-rights)

### 2. Frontend Build System
✅ **Vite Setup** - Build tool พร้อมใช้งาน
✅ **React 18** - Modern React structure
✅ **Tailwind CSS** - Styling framework
✅ **API Service Layer** - Separation of concerns
✅ **Production Optimization:**
  - Code splitting
  - Tree shaking
  - Minification
  - Fast HMR (Hot Module Replacement)

### 3. Database
✅ **PostgreSQL Schema** - ครบถ้วน 18 tables
✅ **Indexes** - Optimized queries
✅ **Views** - Helper views สำหรับ common queries
✅ **Triggers** - Auto-update timestamps

### 4. Documentation
✅ **README.md** - Complete documentation
✅ **SETUP_GUIDE.md** - Step-by-step guide
✅ **API Documentation** - All endpoints documented

## 📋 ขั้นตอนการติดตั้ง

### ขั้นตอนที่ 1: ติดตั้ง Dependencies

```bash
# 1. Backend dependencies (ในโฟลเดอร์หลัก)
npm install

# 2. Frontend dependencies
cd frontend
npm install
cd ..
```

### ขั้นตอนที่ 2: ตรวจสอบ Database

```bash
# ตรวจสอบว่า PostgreSQL ทำงานอยู่
# Windows (ใน Command Prompt/PowerShell)
docker ps
# หรือ
pg_isready -h localhost -p 5433

# ถ้ายังไม่ได้ init database ให้รัน:
psql -h localhost -p 5433 -U fingrow_user -d fingame -f init_postgres.sql
```

### ขั้นตอนที่ 3: Start Development Servers

```bash
# Terminal 1: Backend API
npm run dev
# → Server จะรันที่ http://localhost:3001

# Terminal 2: Frontend Dev Server (เปิด terminal ใหม่)
cd frontend
npm run dev
# → Frontend จะรันที่ http://localhost:5173
```

### ขั้นตอนที่ 4: ทดสอบระบบ

1. เปิดเบราว์เซอร์ไปที่: **http://localhost:5173**
2. ดู Network tab ใน DevTools เพื่อดู API calls
3. ทดสอบ API โดยตรงที่: **http://localhost:3001**

## 🧪 ทดสอบ API

### ทดสอบด้วย curl (Windows PowerShell)

```powershell
# ดู API endpoints
Invoke-WebRequest http://localhost:3001

# ดู user profile
Invoke-WebRequest http://localhost:3001/api/users/world/25AAA0001

# ดู FP balance (ต้องใส่ user UUID จริง)
# Invoke-WebRequest http://localhost:3001/api/finpoint/{UUID}/balance
```

### ทดสอบด้วย Browser

เปิด browser console (F12) แล้วรันคำสั่ง:

```javascript
// ดู API endpoints
fetch('http://localhost:3001/')
  .then(r => r.json())
  .then(console.log);

// ดู user data
fetch('http://localhost:3001/api/users/world/25AAA0001')
  .then(r => r.json())
  .then(console.log);
```

## ⚠️ สิ่งที่ยังต้องทำต่อ (TODO)

### 1. สร้างข้อมูลทดสอบ (Test Data)
```sql
-- ต้องสร้าง users ทดสอบเพิ่มเติมใน database
-- ตอนนี้มีแค่ system_root (25AAA0000) เท่านั้น
```

### 2. แปลง React Components
ต้องแปลงโค้ดจาก `fingrow-app-mobile.html` มาเป็น React components ใน `/frontend/src/`

**ไฟล์ที่ต้องสร้าง:**
```
frontend/src/
├── App.jsx                 # Main app component
├── components/
│   ├── HomePage.jsx
│   ├── TransactionsPage.jsx
│   ├── TreePage.jsx
│   ├── ACFPage.jsx
│   ├── ProfilePage.jsx
│   ├── BottomNav.jsx
│   └── ExpCard.jsx
├── hooks/
│   └── useUser.js         # Custom hook for user data
└── utils/
    └── format.js          # Helper functions
```

### 3. เชื่อม Frontend กับ API
ต้องแทนที่ `mockData` ด้วยการเรียก API จริง

**ตัวอย่าง:**
```javascript
// ❌ เดิม (mock data)
const [user, setUser] = useState(mockUser);

// ✅ ใหม่ (API call)
const [user, setUser] = useState(null);
useEffect(() => {
  userAPI.getUserByWorldId('25AAA0001')
    .then(setUser)
    .catch(console.error);
}, []);
```

### 4. Authentication
ต้องเพิ่มระบบ login/logout

**ไฟล์ที่ต้องสร้าง:**
```
api/auth.js                # JWT authentication
frontend/src/pages/LoginPage.jsx
frontend/src/contexts/AuthContext.jsx
```

### 5. Production Build
```bash
# Build frontend
cd frontend
npm run build

# Start production server
cd ..
npm start
```

## 📊 สถานะโครงการ

| Component | Status | Progress |
|-----------|--------|----------|
| Database Schema | ✅ Complete | 100% |
| Backend API | ✅ Complete | 100% |
| Frontend Build System | ✅ Complete | 100% |
| API Service Layer | ✅ Complete | 100% |
| React Components | ⏳ TODO | 0% |
| API Integration | ⏳ TODO | 0% |
| Authentication | ⏳ TODO | 0% |
| Test Data | ⏳ TODO | 0% |

## 🎯 ขั้นตอนถัดไป (Next Steps)

### ขั้นตอนที่ 1: สร้างข้อมูลทดสอบ

สร้างไฟล์ `seed_test_data.sql`:
```sql
-- สร้าง users ทดสอบ
INSERT INTO users (world_id, username, run_number, parent_id, ...)
VALUES
  ('25AAA0001', 'user1', 1, NULL, ...),
  ('25AAA0002', 'user2', 2, '25AAA0001', ...),
  ...
```

### ขั้นตอนที่ 2: แปลง React Components

คัดลอกโค้ดจาก `fingrow-app-mobile.html` มาแยกเป็น components ใน `frontend/src/`

### ขั้นตอนที่ 3: เชื่อม API

แทนที่ mock data ด้วย API calls โดยใช้ `frontend/src/services/api.js`

### ขั้นตอนที่ 4: ทดสอบ

ทดสอบทุก feature ให้ทำงานถูกต้อง

### ขั้นตอนที่ 5: Deploy

Build และ deploy ไปยัง production server

## 🆘 แก้ปัญหา (Troubleshooting)

### ปัญหา: Database connection failed
```bash
# ตรวจสอบว่า PostgreSQL ทำงานอยู่
docker ps

# ตรวจสอบ port
netstat -an | findstr 5433

# ลองเชื่อมต่อด้วย psql
psql -h localhost -p 5433 -U fingrow_user -d fingame
```

### ปัญหา: API ไม่ตอบกลับ
```bash
# ตรวจสอบว่า server ทำงานอยู่
curl http://localhost:3001

# ดู logs
# (ดูใน terminal ที่รัน npm run dev)
```

### ปัญหา: Frontend ไม่โหลด
```bash
# ลบ node_modules และ install ใหม่
cd frontend
rm -rf node_modules
npm install
npm run dev
```

## 📞 ติดต่อ

- **Repository:** D:\Fingame
- **API Server:** http://localhost:3001
- **Frontend Dev:** http://localhost:5173
- **Database:** PostgreSQL @ localhost:5433

---

**สถานะ:** Development Ready → ต้องทำ React Components + API Integration ต่อ
**Last Updated:** November 2025
