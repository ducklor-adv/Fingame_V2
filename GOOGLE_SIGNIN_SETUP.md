# Google Sign-In Setup Guide

## สิ่งที่ได้เพิ่มเข้ามาแล้ว

### 1. Frontend ([fingrow-app-mobile.html](fingrow-app-mobile.html))
- ✅ เพิ่ม Google Sign-In library script
- ✅ เพิ่มแท็บ "สมัครสมาชิก" ในหน้า Login
- ✅ สร้าง UI สำหรับการสมัครสมาชิกด้วย Google
- ✅ เพิ่มฟังก์ชัน `handleGoogleSignIn()` สำหรับจัดการ Google credential
- ✅ Auto-initialize Google Sign-In button เมื่อเปิดแท็บสมัครสมาชิก

### 2. Backend API ([api/users.js](api/users.js))
- ✅ เพิ่ม endpoint `POST /api/users/google-signin`
- ✅ ตรวจสอบว่าผู้ใช้เคยมีอยู่แล้วหรือไม่ (ผ่าน email)
- ✅ สร้างผู้ใช้ใหม่อัตโนมัติพร้อม:
  - World ID ที่ไม่ซ้ำ
  - Username จาก email
  - ข้อมูลจาก Google (ชื่อ, รูปโปรไฟล์)
- ✅ Login ทันทีหลังจากสร้างผู้ใช้

## ขั้นตอนการ Setup Google OAuth

### ที่ต้องทำเพิ่มเติม:

#### 1. สร้าง Google Cloud Project และ OAuth 2.0 Client ID

1. ไปที่ [Google Cloud Console](https://console.cloud.google.com/)
2. สร้างโปรเจกต์ใหม่หรือเลือกโปรเจกต์ที่มีอยู่
3. ไปที่ **APIs & Services > Credentials**
4. คลิก **Create Credentials > OAuth 2.0 Client ID**
5. เลือก Application type: **Web application**
6. ตั้งค่า:
   - **Name**: Fingrow Web App
   - **Authorized JavaScript origins**:
     - `http://localhost:3001`
     - `http://localhost:3000`
     - (เพิ่ม production domain ของคุณเมื่อ deploy)
   - **Authorized redirect URIs**:
     - `http://localhost:3001`
     - (เพิ่ม production URL ของคุณเมื่อ deploy)
7. คลิก **Create**
8. คัดลอก **Client ID** ที่ได้

#### 2. อัปเดต Client ID ในโค้ด

แก้ไขไฟล์ [fingrow-app-mobile.html](fingrow-app-mobile.html) บรรทัดที่ 348:

```javascript
// เปลี่ยนจาก
client_id: 'YOUR_GOOGLE_CLIENT_ID.apps.googleusercontent.com',

// เป็น Client ID ที่ได้จาก Google Cloud Console
client_id: 'xxxxxxxxxx-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx.apps.googleusercontent.com',
```

#### 3. ทดสอบ

1. เปิดเว็บแอป: `http://localhost:3001/fingrow-app-mobile.html`
2. คลิกแท็บ **"สมัครสมาชิก"**
3. คลิกปุ่ม **"Sign in with Google"**
4. เลือก Google Account
5. ระบบจะสร้างผู้ใช้ใหม่และ login ทันที

## คุณสมบัติ

- 🔐 **Secure**: ใช้ Google OAuth 2.0
- 🚀 **Auto-register**: สร้างผู้ใช้อัตโนมัติจากข้อมูล Google
- ✨ **Seamless**: Login ทันทีหลังจากสมัครสมาชิก
- 🎨 **Beautiful UI**: Google Sign-In button มาตรฐาน
- 📧 **Smart**: ตรวจสอบ email ซ้ำอัตโนมัติ
- 🆔 **Unique**: สร้าง World ID และ username ที่ไม่ซ้ำ

## ข้อมูลที่เก็บจาก Google

- Email
- ชื่อ (First Name, Last Name)
- รูปโปรไฟล์ (Avatar URL)
- Google ID (สำหรับการอ้างอิง)

## Database Schema

ผู้ใช้ที่สมัครผ่าน Google จะมีค่าเหล่านี้:
- `regist_type`: `'google'`
- `is_verified`: `true`
- `verification_level`: `1`
- `user_type`: `'member'`
- `level`: `1`

## Troubleshooting

### ปุ่ม Google Sign-In ไม่แสดง
- ตรวจสอบว่า script `https://accounts.google.com/gsi/client` โหลดสำเร็จ
- ตรวจสอบ Console ใน Browser Developer Tools
- ตรวจสอบว่า Client ID ถูกต้อง

### Error: "Google Sign-In ยังไม่พร้อมใช้งาน"
- รีเฟรชหน้าเว็บ
- ตรวจสอบว่า Google script โหลดเสร็จแล้ว

### Error: "Missing required fields"
- ตรวจสอบว่า backend API `/api/users/google-signin` ทำงานปกติ
- ตรวจสอบ Network tab ใน Developer Tools

## ไฟล์ที่เกี่ยวข้อง

- 📄 [fingrow-app-mobile.html](fingrow-app-mobile.html) - Frontend UI และ Google Sign-In integration
- 📄 [api/users.js](api/users.js) - Backend API สำหรับ Google Sign-In
