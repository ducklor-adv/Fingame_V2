# User Profile - Fingrow

หน้า User Profile แบบมาตรฐานพร้อมเชื่อมต่อกับ PostgreSQL Database

---

## 📦 ไฟล์ที่สร้าง

### 1. Frontend Components
- **[components/UserProfile.jsx](components/UserProfile.jsx)** - React component หน้า User Profile
  - แสดงข้อมูลส่วนตัว, ACF info, Finpoint
  - รองรับการแก้ไขข้อมูล (Edit mode)
  - Responsive design (Mobile & Desktop)
  - Tailwind CSS styling

### 2. Backend API
- **[api/users.js](api/users.js)** - Express API endpoints
  - `GET /api/users/:id` - ดึงข้อมูล user ด้วย UUID
  - `GET /api/users/world/:worldId` - ดึงข้อมูล user ด้วย World ID
  - `GET /api/users/username/:username` - ดึงข้อมูล user ด้วย username
  - `PATCH /api/users/:id` - อัพเดทข้อมูล user
  - `GET /api/users/:id/stats` - ดึงสถิติของ user
  - `GET /api/users/:id/children` - ดึงรายชื่อลูกใน ACF tree

### 3. Server
- **[server.js](server.js)** - Express server
- **[package.json](package.json)** - Dependencies
- **[.env](.env)** - Environment variables

### 4. Test/Demo
- **[test-profile.html](test-profile.html)** - Standalone HTML demo (ใช้ mock data)

---

## 🚀 การติดตั้งและรัน

### 1. ติดตั้ง Dependencies

```bash
cd d:\Fingame
npm install
```

### 2. ตรวจสอบว่า PostgreSQL รันอยู่

```bash
docker-compose ps
```

ถ้ายังไม่รัน:
```bash
docker-compose up -d
```

### 3. รัน API Server

```bash
# Development mode (auto-reload)
npm run dev

# Production mode
npm start
```

Server จะรันที่: **http://localhost:3000**

---

## 🧪 ทดสอบ API

### 1. ทดสอบด้วย Browser

เปิด: **http://localhost:3000**

จะเห็นรายชื่อ API endpoints ทั้งหมด

### 2. ทดสอบด้วย curl

```bash
# ดึงข้อมูล System Root User
curl http://localhost:3000/api/users/world/25AAA0000

# ดึงข้อมูล User ด้วย username
curl http://localhost:3000/api/users/username/system_root

# อัพเดทข้อมูล User
curl -X PATCH http://localhost:3000/api/users/00000000-0000-0000-0000-000000000000 \
  -H "Content-Type: application/json" \
  -d '{
    "firstName": "Updated",
    "lastName": "Name",
    "bio": "This is updated bio"
  }'
```

### 3. ทดสอบด้วย Test HTML

เปิดไฟล์: **[test-profile.html](test-profile.html)** ในเบราว์เซอร์

หน้านี้ใช้ mock data ทดสอบ UI ได้โดยไม่ต้องรัน server

---

## 📊 ฟิลด์ข้อมูลที่รองรับ

### ข้อมูลพื้นฐาน
- `id` - UUID (primary key)
- `worldId` - World ID (25AAA####)
- `username` - ชื่อผู้ใช้
- `email` - อีเมล
- `phone` - เบอร์โทร
- `firstName` - ชื่อจริง
- `lastName` - นามสกุล
- `bio` - ประวัติส่วนตัว
- `avatarUrl` - URL รูปโปรไฟล์

### ACF Information
- `runNumber` - ลำดับการลงทะเบียน
- `level` - ระดับใน ACF tree
- `childCount` - จำนวนลูกปัจจุบัน
- `maxChildren` - จำนวนลูกสูงสุด (1-5)
- `acfAccepting` - เปิดรับ ACF หรือไม่
- `parentId` - Parent ใน ACF tree
- `inviterId` - ผู้เชิญ
- `inviteCode` - รหัสเชิญ

### Finpoint
- `ownFinpoint` - FP ของตัวเอง
- `totalFinpoint` - FP รวม
- `maxNetwork` - Max network size (19531)

### สถิติ
- `totalSales` - ยอดขายทั้งหมด
- `totalPurchases` - ยอดซื้อทั้งหมด
- `trustScore` - คะแนนความน่าเชื่อถือ
- `isVerified` - ยืนยันตัวตนแล้วหรือไม่
- `verificationLevel` - ระดับการยืนยัน (0-4)

### ที่อยู่
- `addressNumber` - บ้านเลขที่
- `addressStreet` - ถนน
- `addressDistrict` - แขวง/ตำบล
- `addressProvince` - จังหวัด
- `addressPostalCode` - รหัสไปรษณีย์

### การตั้งค่า
- `preferredCurrency` - สกุลเงินที่ต้องการ (THB, USD, EUR)
- `language` - ภาษา (th, en)

---

## 🎨 UI Components

### Layout
```
┌─────────────────────────────────────┐
│ Header (Sticky)                     │
│ - Logo + Title                      │
│ - Edit/Save/Cancel buttons          │
├─────────────────────────────────────┤
│ Profile Header Card                 │
│ - Cover gradient                    │
│ - Avatar (with verified badge)      │
│ - Username, World ID, Level         │
│ - Basic stats                       │
├──────────────┬──────────────────────┤
│ Left Column  │ Right Column         │
│              │                      │
│ Stats Card   │ Personal Info        │
│ ACF Info     │ - Editable fields    │
│ Finpoint     │                      │
│              │ Address Info         │
│              │ - Editable fields    │
│              │                      │
│              │ Preferences          │
└──────────────┴──────────────────────┘
```

### สี Theme (Tailwind)
- Background: `slate-950` (dark)
- Cards: `slate-900/60` (semi-transparent)
- Borders: `slate-800`
- Primary: `emerald-600` (green)
- Accent: `teal-600`, `cyan-600`

---

## 🔒 ฟิลด์ที่แก้ไขได้

User สามารถแก้ไขฟิลด์เหล่านี้ได้:
- ✅ ชื่อจริง, นามสกุล
- ✅ อีเมล, เบอร์โทร
- ✅ ประวัติส่วนตัว (bio)
- ✅ รูปโปรไฟล์
- ✅ ที่อยู่ทั้งหมด
- ✅ สกุลเงิน, ภาษา

ฟิลด์ที่ **ไม่สามารถ** แก้ไขได้ (read-only):
- ❌ World ID, Username, Run Number
- ❌ ACF info (level, childCount, etc.)
- ❌ Finpoint
- ❌ Stats (totalSales, trustScore, etc.)

---

## 🔌 Integration กับ React App

### วิธีที่ 1: Import Component

```jsx
import UserProfile from './components/UserProfile';

function App() {
  return (
    <UserProfile
      userId="00000000-0000-0000-0000-000000000000"
      onUpdate={(profile) => {
        console.log('Profile updated:', profile);
      }}
    />
  );
}
```

### วิธีที่ 2: ใช้ใน Next.js

```jsx
// pages/profile/[id].jsx
import UserProfile from '@/components/UserProfile';
import { useRouter } from 'next/router';

export default function ProfilePage() {
  const router = useRouter();
  const { id } = router.query;

  return <UserProfile userId={id} />;
}
```

---

## 📝 ตัวอย่างการใช้งาน API

### JavaScript (Fetch)

```javascript
// ดึงข้อมูล User
const response = await fetch('http://localhost:3000/api/users/world/25AAA0000');
const user = await response.json();
console.log(user);

// อัพเดทข้อมูล
const updated = await fetch('http://localhost:3000/api/users/00000000-0000-0000-0000-000000000000', {
  method: 'PATCH',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    firstName: 'John',
    lastName: 'Doe',
    bio: 'Updated bio'
  })
});
const result = await updated.json();
console.log(result);
```

### Python (requests)

```python
import requests

# ดึงข้อมูล User
response = requests.get('http://localhost:3000/api/users/world/25AAA0000')
user = response.json()
print(user)

# อัพเดทข้อมูล
response = requests.patch(
    'http://localhost:3000/api/users/00000000-0000-0000-0000-000000000000',
    json={
        'firstName': 'John',
        'lastName': 'Doe',
        'bio': 'Updated bio'
    }
)
result = response.json()
print(result)
```

---

## 🐛 Troubleshooting

### API ไม่ทำงาน
```bash
# ตรวจสอบว่า database รันอยู่
docker-compose ps

# ตรวจสอบ connection
docker exec fingrow-postgres psql -U fingrow_user -d fingrow -c "SELECT COUNT(*) FROM users;"

# ดู logs
docker-compose logs postgres
```

### Port 3000 ถูกใช้แล้ว
แก้ไขใน `.env`:
```
PORT=3001
```

### Database connection error
ตรวจสอบค่าใน `.env`:
```bash
DB_HOST=localhost
DB_PORT=5432
DB_NAME=fingrow
DB_USER=fingrow_user
DB_PASSWORD=fingrow_pass_2025
```

---

## 🚀 ขั้นตอนต่อไป

1. **เพิ่ม Authentication**
   - JWT tokens
   - Session management
   - Protected routes

2. **เพิ่มฟีเจอร์**
   - อัพโหลดรูปโปรไฟล์
   - Change password
   - 2FA authentication

3. **Integration**
   - เชื่อมกับ ACF Canvas
   - เชื่อมกับ Dashboard
   - เชื่อมกับ Product listing

4. **Testing**
   - Unit tests
   - Integration tests
   - E2E tests

---

**User Profile พร้อมใช้งาน!** 🎉

ต้องการให้เพิ่มฟีเจอร์อะไรเพิ่มเติมบอกได้เลยครับ!
