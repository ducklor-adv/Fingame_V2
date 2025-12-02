# Commission Pool Distribution System

## ภาพรวมระบบ

ระบบการแบ่ง Commission Pool เมื่อมีการซื้อประกัน โดยจะกระจาย Commission ให้กับผู้ซื้อและ Upline ในเครือข่าย

---

## โครงสร้าง Commission

### จากราคาประกัน
```
Commission = ราคาประกัน × Commission Rate
```

### แบ่ง Commission เป็น 3 ส่วน
1. **Management Fee** = 10% × Commission
2. **Seller Commission** = 45% × Commission
3. **Commission Pool** = 45% × Commission

---

## การกระจาย Commission Pool

Commission Pool (45% ของ Commission) จะถูกแบ่งเป็น **7 ส่วนเท่าๆ กัน**:

- **ผู้ซื้อ**: 1/7 ของ Commission Pool
- **Upline 1-6**: อีก 6/7 ของ Commission Pool (คนละ 1/7)

### กรณีต่างๆ

#### กรณีที่ 1: เครือข่ายครบ 7 ชั้น
- User อยู่ชั้นที่ 7 หรือมากกว่า (มี Upline ครบ 6 คน)
- แบ่ง Commission Pool: **ตัวเอง 1 ส่วน + Upline 6 คน (คนละ 1 ส่วน) = ครบ 7 ส่วน**
- System Root ไม่ได้รับส่วนเพิ่ม

#### กรณีที่ 2: เครือข่ายไม่ครบ 7 ชั้น
- User มี Upline น้อยกว่า 6 คน
- แบ่ง Commission Pool: **ตัวเอง 1 ส่วน + Upline ที่มี (คนละ 1 ส่วน)**
- **ส่วนที่เหลือ → ไปให้ System Root ทั้งหมด**

**ตัวอย่าง**: User มี Upline เพียง 2 คน
- แบ่งให้: ตัวเอง (1 ส่วน) + Upline 2 คน (2 ส่วน) = 3 ส่วน
- ส่วนที่เหลือ: 4 ส่วน → System Root

---

## Database Schema

### ตาราง `orders`
เก็บประวัติการซื้อประกันของแต่ละ user

| Column | Type | Description |
|--------|------|-------------|
| order_id | SERIAL | Primary Key |
| user_id | INTEGER | User ที่ซื้อประกัน |
| insurance_product_id | INTEGER | ID ของประกัน |
| premium_amount | DECIMAL(12,2) | ราคาประกัน |
| commission_rate | DECIMAL(5,4) | อัตรา Commission (เช่น 0.15 = 15%) |
| total_commission | DECIMAL(12,2) | Commission ทั้งหมด |
| management_fee | DECIMAL(12,2) | ค่าจัดการ (10%) |
| seller_commission | DECIMAL(12,2) | ค่าคอมมิชชั่นผู้ขาย (45%) |
| commission_pool | DECIMAL(12,2) | Commission Pool (45%) |
| order_status | VARCHAR(50) | สถานะ Order |
| created_at | TIMESTAMP | วันที่สร้าง |

### ตาราง `commission_pool_distribution`
เก็บรายละเอียดการกระจาย Commission Pool ให้แต่ละคนในเครือข่าย

| Column | Type | Description |
|--------|------|-------------|
| distribution_id | SERIAL | Primary Key |
| order_id | INTEGER | FK to orders |
| recipient_user_id | INTEGER | User ที่ได้รับ Commission |
| recipient_role | VARCHAR(20) | บทบาท: 'buyer', 'upline_1', ..., 'system_root' |
| upline_level | INTEGER | ระดับ Upline (0=buyer, 1-6=upline, NULL=system_root) |
| share_portion | DECIMAL(5,4) | สัดส่วนที่ได้รับ (เช่น 0.142857 = 1/7) |
| amount | DECIMAL(12,2) | จำนวนเงินที่ได้รับ |
| distributed_at | TIMESTAMP | วันที่แบ่ง |

### View `user_commission_summary`
สรุป Commission Pool ที่แต่ละคนได้รับทั้งหมด

| Column | Description |
|--------|-------------|
| recipient_user_id | User ID |
| total_orders_participated | จำนวน Orders ที่เกี่ยวข้อง |
| total_from_own_purchase | Commission จากการซื้อเอง |
| total_from_network | Commission จากเครือข่าย |
| total_from_system | Commission จาก System Root |
| total_commission_received | Commission ทั้งหมด |

---

## การใช้งาน Module

### 1. Import Module
```javascript
const commissionModule = require('./modules/commissionPoolModule');
```

### 2. คำนวณ Commission
```javascript
const result = commissionModule.calculateCommission(10000, 0.15);
console.log(result);
// {
//   totalCommission: 1500,
//   managementFee: 150,      // 10%
//   sellerCommission: 675,   // 45%
//   commissionPool: 675      // 45%
// }
```

### 3. สร้าง Order และกระจาย Commission Pool
```javascript
const client = await pool.connect();
await client.query('BEGIN');

const orderData = {
  userId: 5,
  insuranceProductId: 1,
  premiumAmount: 10000,
  commissionRate: 0.15,
  systemRootUserId: 1
};

const result = await commissionModule.createOrderAndDistributeCommission(orderData, client);

console.log('Order ID:', result.orderId);
console.log('Commission Pool:', result.commission.commissionPool);
console.log('Distribution:', result.distribution);

await client.query('COMMIT');
client.release();
```

### 4. ดูสรุป Commission ของ User
```javascript
const summary = await commissionModule.getUserCommissionSummary(userId, client);
console.log('Total Commission:', summary.total_commission_received);
```

### 5. ดูรายละเอียด Commission ของ Order
```javascript
const details = await commissionModule.getOrderCommissionDetail(orderId, client);
details.forEach(d => {
  console.log(`${d.recipient_username}: ${d.amount} บาท`);
});
```

---

## การติดตั้ง

### 1. รัน Migration Script
```bash
psql -h localhost -p 5433 -U fingrow_user -d fingame -f database/migration_add_commission_pool.sql
```

### 2. ทดสอบระบบ
```bash
node test_commission_pool.js
```

### 3. ดูตัวอย่างการใช้งาน
```bash
node examples/commission_pool_example.js
```

---

## ตัวอย่างการคำนวณ

### ตัวอย่างที่ 1: User ชั้นที่ 7 (Upline ครบ 6 คน)

**ข้อมูล:**
- ราคาประกัน: 10,000 บาท
- Commission Rate: 15%
- Upline: 6 คน

**คำนวณ:**
1. Total Commission = 10,000 × 0.15 = **1,500 บาท**
2. Management Fee = 1,500 × 0.10 = **150 บาท**
3. Seller Commission = 1,500 × 0.45 = **675 บาท**
4. Commission Pool = 1,500 × 0.45 = **675 บาท**

**แบ่ง Commission Pool (675 บาท):**
- แต่ละส่วน = 675 ÷ 7 = **96.43 บาท**
- ผู้ซื้อ: 96.43 บาท
- Upline 1-6: อีก 6 คน × 96.43 = 578.58 บาท
- System Root: 0 บาท (เพราะ Upline ครบ)

---

### ตัวอย่างที่ 2: User ชั้นที่ 3 (Upline เพียง 2 คน)

**ข้อมูล:**
- ราคาประกัน: 20,000 บาท
- Commission Rate: 12%
- Upline: 2 คน

**คำนวณ:**
1. Total Commission = 20,000 × 0.12 = **2,400 บาท**
2. Management Fee = 2,400 × 0.10 = **240 บาท**
3. Seller Commission = 2,400 × 0.45 = **1,080 บาท**
4. Commission Pool = 2,400 × 0.45 = **1,080 บาท**

**แบ่ง Commission Pool (1,080 บาท):**
- แต่ละส่วน = 1,080 ÷ 7 = **154.29 บาท**
- ผู้ซื้อ: 154.29 บาท (1 ส่วน)
- Upline 1-2: 2 คน × 154.29 = 308.58 บาท (2 ส่วน)
- System Root: 4 ส่วน × 154.29 = **617.16 บาท** (เพราะ Upline ไม่ครบ)

---

## API Endpoints (สำหรับอนาคต)

### POST /api/orders/create
สร้าง Order และกระจาย Commission

**Request:**
```json
{
  "userId": 5,
  "insuranceProductId": 1,
  "premiumAmount": 10000,
  "commissionRate": 0.15
}
```

**Response:**
```json
{
  "orderId": 123,
  "commission": {
    "totalCommission": 1500,
    "commissionPool": 675
  },
  "distribution": [...]
}
```

### GET /api/users/:userId/commission-summary
ดูสรุป Commission ของ User

**Response:**
```json
{
  "userId": 5,
  "totalCommissionReceived": 5432.10,
  "totalFromOwnPurchase": 1234.56,
  "totalFromNetwork": 3987.54,
  "totalFromSystem": 210.00
}
```

---

## Notes

1. **Transaction Safety**: ทุกการสร้าง Order ต้องอยู่ใน Transaction เพื่อป้องกันข้อมูลไม่สมบูรณ์
2. **Performance**: ใช้ Indexes บน `recipient_user_id` และ `order_id` เพื่อเพิ่มความเร็วในการ Query
3. **Scalability**: แยกตาราง `commission_pool_distribution` ออกจาก `orders` เพื่อรองรับข้อมูลจำนวนมาก
4. **Finpoint**: Finpoint ของแต่ละคนคือผลรวมของ Commission Pool ที่ได้รับทั้งหมด

---

## Files Structure

```
d:\Fingame\
├── database/
│   ├── schema_commission_pool.sql          # Database schema
│   └── migration_add_commission_pool.sql   # Migration script
├── modules/
│   └── commissionPoolModule.js             # Main module
├── examples/
│   └── commission_pool_example.js          # Usage examples
├── test_commission_pool.js                 # Test suite
└── docs/
    └── COMMISSION_POOL_SYSTEM.md           # This file
```

---

## Support

หากมีคำถามหรือพบปัญหา กรุณาติดต่อทีมพัฒนา
