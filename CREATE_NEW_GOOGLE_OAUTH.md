# วิธีสร้าง Google OAuth Client ID ใหม่

## ขั้นตอนละเอียด

### 1. ไปที่ Google Cloud Console
https://console.cloud.google.com/

### 2. สร้าง/เลือก Project
- คลิก dropdown ที่มุมบนซ้าย
- เลือก Project ที่มีอยู่ หรือคลิก "NEW PROJECT"
- ตั้งชื่อ: **Fingrow**
- คลิก **CREATE**

### 3. Enable APIs (ถ้ายังไม่เคย)
- ไปที่ **APIs & Services > Library**
- ค้นหา "Google Identity Services"
- คลิก **ENABLE**

### 4. ตั้งค่า OAuth Consent Screen
- ไปที่ **APIs & Services > OAuth consent screen**
- เลือก **External** (สำหรับใช้กับคนทั่วไป)
- คลิก **CREATE**

กรอกข้อมูล:
```
App name: Fingrow
User support email: [your-email@gmail.com]
App logo: (ข้าม)

App domain:
  Application home page: http://localhost:3001
  (ส่วนอื่นข้าม)

Developer contact information:
  Email addresses: [your-email@gmail.com]
```

- คลิก **SAVE AND CONTINUE**
- หน้า Scopes: คลิก **SAVE AND CONTINUE** (ไม่ต้องเพิ่ม)
- หน้า Test users: คลิก **ADD USERS** แล้วใส่ email ของคุณ (Gmail account ที่จะใช้ทดสอบ)
- คลิก **SAVE AND CONTINUE**
- คลิก **BACK TO DASHBOARD**

### 5. สร้าง OAuth 2.0 Client ID
- ไปที่ **APIs & Services > Credentials**
- คลิก **+ CREATE CREDENTIALS**
- เลือก **OAuth 2.0 Client ID**

ตั้งค่า:
```
Application type: Web application

Name: Fingrow OAuth Client

Authorized JavaScript origins:
  - คลิก "+ ADD URI"
  - ใส่: http://localhost:3001
  - คลิก "+ ADD URI"
  - ใส่: http://localhost:3000
  - คลิก "+ ADD URI"
  - ใส่: http://127.0.0.1:3001

Authorized redirect URIs:
  - ไม่ต้องใส่อะไร (เว้นว่างไว้)
```

- คลิก **CREATE**

### 6. คัดลอก Client ID
จะมี popup แสดง:
```
Your Client ID
xxxxxxxxxxxxx-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx.apps.googleusercontent.com

Your Client Secret
GOCSPX-xxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

**คัดลอก Client ID** (อันบน ไม่ใช่ Client Secret)

### 7. ใส่ใน Code

แก้ไขไฟล์ `fingrow-app-mobile.html` บรรทัดที่ 348:

```javascript
client_id: 'PASTE_YOUR_CLIENT_ID_HERE.apps.googleusercontent.com',
```

### 8. ทดสอบ

1. เปิด browser ไปที่: `http://localhost:3001/fingrow-app-mobile.html`
2. คลิกแท็บ "สมัครสมาชิก"
3. คลิกปุ่ม "Sign in with Google"
4. เลือก Google Account
5. ยอมรับ permissions
6. ควรจะ login สำเร็จ!

---

## หมายเหตุสำคัญ

### ถ้าเจอ Error "This app isn't verified"
- ปกติสำหรับ app ที่อยู่ในโหมด Testing
- คลิก **Advanced** > **Go to Fingrow (unsafe)**
- ใช้งานได้ตามปกติ

### Production Mode
เมื่อพร้อม deploy จริง:
1. ไปที่ OAuth consent screen
2. คลิก **PUBLISH APP**
3. รอ Google review (อาจใช้เวลาหลายวัน)
4. เพิ่ม production domain ใน Authorized JavaScript origins

### สำคัญมาก!
- **ห้าม** commit หรือ push Client ID ขึ้น public repository
- ใช้ environment variable หรือ config file (ที่ถูก gitignore) สำหรับ production
