# 🚛 Fleet Management System

ระบบจัดการยานพาหนะและการขนส่ง (Fleet Management System) — Full-Stack Web Application สำหรับติดตาม ควบคุม และบริหารจัดการกองยาน พนักงานขับรถ และการเดินทาง แบบ Real-time

---

## 📋 สารบัญ

- [ภาพรวมระบบ](#ภาพรวมระบบ)
- [Tech Stack](#tech-stack)
- [โครงสร้างโปรเจค](#โครงสร้างโปรเจค)
- [ฟีเจอร์หลัก](#ฟีเจอร์หลัก)
- [ฐานข้อมูล](#ฐานข้อมูล)
- [Alert Engine](#alert-engine)
- [การติดตั้งและรันระบบ](#การติดตั้งและรันระบบ)
- [API Documentation](#api-documentation)
- [Environment Variables](#environment-variables)

---

## ภาพรวมระบบ

ระบบนี้ถูกพัฒนาเป็น **Full-Stack Web Application** ที่ประกอบด้วย:

| ส่วน | เทคโนโลยี | Port |
|------|-----------|------|
| **Frontend** | Vue 3 + Vite | `5173` |
| **Backend** | Node.js + Express 5 | `3000` |
| **Database** | MySQL 8.0 | `3306` |
| **DB Admin** | phpMyAdmin | `8080` |

ทุก Service รันผ่าน **Docker Compose** ทำให้ติดตั้งและเริ่มต้นใช้งานได้ง่ายในทุก Environment

---

## Tech Stack

### Frontend
- **[Vue 3](https://vuejs.org/)** — Progressive JavaScript Framework (Composition API)
- **[Vite 7](https://vite.dev/)** — Next-generation Frontend Build Tool
- **[Vue Router 5](https://router.vuejs.org/)** — Client-side Routing
- **[Pinia](https://pinia.vuejs.org/)** — State Management
- **[Axios](https://axios-http.com/)** — HTTP Client
- **[Chart.js](https://www.chartjs.org/) + [vue-chartjs](https://vue-chartjs.org/)** — Data Visualization
- **[SweetAlert2](https://sweetalert2.github.io/)** — Beautiful Alert Dialogs

### Backend
- **[Node.js](https://nodejs.org/) (≥20.19 / ≥22.12)** — JavaScript Runtime
- **[Express 5](https://expressjs.com/)** — Web Framework
- **[MySQL2](https://github.com/sidorares/node-mysql2)** — Database Driver
- **[jsonwebtoken](https://github.com/auth0/node-jsonwebtoken)** — JWT Authentication
- **[bcrypt](https://github.com/kelektiv/node.bcrypt.js)** — Password Hashing
- **[swagger-autogen](https://swagger-autogen.github.io/docs/)** + **[@scalar/express-api-reference](https://scalar.com/)** — API Docs

### DevOps
- **Docker + Docker Compose** — Containerization
- **node --watch** — Hot-reload สำหรับ Backend
- **ESLint + OXLint + Prettier** — Code Quality

---

## โครงสร้างโปรเจค

```
full_stack_dev_fix/
├── 📄 server.cjs              # Express Backend (API Server + Auth + Alert Engine)
├── 📄 swagger.cjs             # Swagger Auto-generation Script
├── 📄 Schema.sql              # Database Schema (MySQL)
├── 📄 docker-compose.yml      # Docker Compose Configuration
├── 📄 Dockerfile              # Backend Docker Image
├── 📄 .env                    # Environment Variables
│
└── src/
    ├── alertEngine/           # Alert Engine System
    │   ├── alertEngine.cjs    # Core Engine (auto-loads rules)
    │   ├── ruleInterface.cjs  # Base Class สำหรับกฎแจ้งเตือน
    │   └── rules/
    │       ├── vehicleDueForService.cjs   # ถึงรอบเช็คระยะ
    │       ├── overdueMaintenance.cjs     # ซ่อมบำรุงล่าช้า
    │       ├── licenseExpiringSoon.cjs    # ใบขับขี่ใกล้หมดอายุ
    │       └── tripDelayed.cjs            # การเดินทางล่าช้า
    │
    ├── api/                   # Axios API Client (ฝั่ง Frontend)
    ├── assets/                # Static Assets (รูปภาพ, CSS)
    ├── components/            # Reusable Vue Components
    │   └── Navbar.vue         # Navigation Bar
    ├── layouts/               # Layout Components
    ├── router/                # Vue Router Configuration
    ├── stores/                # Pinia State Stores
    ├── utils/                 # Utility Functions
    └── views/                 # Page Components
        ├── Login.vue          # หน้า Login (Minimal White Theme)
        ├── DashboardView.vue  # หน้า Dashboard + Charts
        ├── VehiclesView.vue   # จัดการยานพาหนะ
        ├── DriversView.vue    # จัดการพนักงานขับรถ
        ├── TripsView.vue      # จัดการการเดินทาง + Checkpoints
        ├── MaintenanceView.vue # จัดการงานซ่อมบำรุง
        ├── AlertsView.vue     # ดูการแจ้งเตือน
        └── AuditLogsView.vue  # ดู Audit Logs
```

---

## ฟีเจอร์หลัก

### 🔐 Authentication
- ระบบ Login ด้วย JWT (Access Token + Refresh Token)
- Password Hashing ด้วย bcrypt
- Role-based Access Control (`ADMIN` / `DISPATCHER`)
- Session Management ผ่าน Pinia Store

### 🚗 จัดการยานพาหนะ (Vehicles)
- เพิ่ม / แก้ไข / ลบ ยานพาหนะ
- ติดตามสถานะ: `ACTIVE` | `IDLE` | `MAINTENANCE` | `RETIRED`
- รองรับประเภทยาน: `TRUCK` | `VAN` | `MOTORCYCLE` | `PICKUP`
- บันทึก ระยะทางสะสม, รอบเช็คระยะ, เชื้อเพลิง

### 👤 จัดการพนักงานขับรถ (Drivers)
- เพิ่ม / แก้ไข / ลบ ข้อมูลพนักงาน
- ติดตามสถานะ: `ACTIVE` | `INACTIVE` | `SUSPENDED`
- บันทึกข้อมูลใบขับขี่และวันหมดอายุ
- เชื่อมต่อกับยานพาหนะที่รับผิดชอบ

### 🗺 จัดการการเดินทาง (Trips)
- สร้าง Trip พร้อม Auto-increment ID (`trp_001`, `trp_002`, ...)
- ควบคุมสถานะ Trip: `SCHEDULED` → `IN_PROGRESS` → `COMPLETED` / `CANCELLED`
- จัดการ **Checkpoints** ระหว่างทาง (ลำดับ, จุดแวะ, วัตถุประสงค์)
- Optimistic UI Update สำหรับสถานะ Checkpoint (`PENDING` | `ARRIVED` | `DEPARTED` | `SKIPPED`)
- รองรับประเภทสินค้า: `GENERAL` | `FRAGILE` | `HAZARDOUS` | `REFRIGERATED`

### 🔧 ซ่อมบำรุง (Maintenance)
- บันทึกงานซ่อมบำรุงพร้อมอะไหล่ที่ใช้
- ติดตามสถานะ: `SCHEDULED` | `IN_PROGRESS` | `COMPLETED` | `OVERDUE`
- รองรับประเภทงาน: `OIL_CHANGE` | `TIRE` | `BRAKE` | `ENGINE` | `INSPECTION` | `REPAIR`
- บันทึกค่าใช้จ่าย (THB)

### 🔔 ระบบแจ้งเตือน (Alerts)
- แจ้งเตือนอัตโนมัติทุก **60 วินาที**
- กรองตามความรุนแรง: `คำเตือน` | `วิกฤต`
- กรองตามประเภท Resource
- ข้อความเป็น **ภาษาไทย** ทั้งหมด

### 📊 Dashboard
- กราฟแสดงสถิติยานพาหนะ
- แนวโน้มระยะทางการเดินทาง

### 📝 Audit Logs
- บันทึกทุก Action ของผู้ใช้ระบบ
- แสดง IP Address, ผลลัพธ์ (`SUCCESS`/`FAIL`), รายละเอียด
- Timezone: **Asia/Bangkok (UTC+7)**

---

## ฐานข้อมูล

ระบบใช้ **MySQL 8.0** พร้อม Timezone `Asia/Bangkok`

```
┌─────────────┐       ┌──────────────┐       ┌──────────────────┐
│   drivers   │──────▶│   vehicles   │──────▶│      trips       │
└─────────────┘       └──────────────┘       └──────────────────┘
                                                       │
                                                       ▼
                                               ┌──────────────────┐
                                               │   checkpoints    │
                                               └──────────────────┘

┌──────────────────┐       ┌──────────────────┐
│   maintenance    │──────▶│maintenance_parts │
└──────────────────┘       └──────────────────┘

┌─────────┐       ┌─────────────┐       ┌──────────┐
│  users  │──────▶│ audit_logs  │       │  alerts  │
└─────────┘       └─────────────┘       └──────────┘
```

### ตาราง

| ตาราง | คำอธิบาย |
|-------|----------|
| `drivers` | ข้อมูลพนักงานขับรถ |
| `vehicles` | ข้อมูลยานพาหนะ |
| `trips` | ข้อมูลการเดินทาง |
| `checkpoints` | จุดแวะระหว่างการเดินทาง |
| `maintenance` | งานซ่อมบำรุง |
| `maintenance_parts` | อะไหล่ที่ใช้ในงานซ่อมบำรุง |
| `users` | ผู้ใช้ระบบ |
| `audit_logs` | บันทึกกิจกรรมในระบบ |
| `alerts` | การแจ้งเตือนอัตโนมัติ |

---

## Alert Engine

Alert Engine ทำงานเป็น Background Service ใน Backend โดย:

1. **Auto-load Rules** — ระบบโหลดไฟล์กฎทุกไฟล์ใน `/src/alertEngine/rules/` อัตโนมัติ
2. **Evaluate Every 60s** — ประเมินกฎทั้งหมดและ sync ผลลัพธ์ไปยังตาราง `alerts`
3. **Upsert Strategy** — ใช้ `UNIQUE (rule_name, affected_resource_id)` เพื่อหลีกเลี่ยง alert ซ้ำ

### กฎแจ้งเตือน

| Rule | เงื่อนไข | Severity |
|------|---------|----------|
| `vehicleDueForService` | ยานพาหนะถึงรอบเช็คระยะ | WARNING |
| `overdueMaintenance` | งานซ่อมบำรุงเลยกำหนดแล้ว | CRITICAL |
| `licenseExpiringSoon` | ใบขับขี่ใกล้หมดอายุ (≤30 วัน) | WARNING |
| `tripDelayed` | การเดินทางใช้เวลาเกินกำหนด | WARNING |

---

## การติดตั้งและรันระบบ

### ข้อกำหนดเบื้องต้น

- [Docker Desktop](https://www.docker.com/products/docker-desktop/)
- [Node.js](https://nodejs.org/) ≥ 20.19.0 หรือ ≥ 22.12.0
- [npm](https://www.npmjs.com/)

### 1. Clone Repository

```sh
git clone <repository-url>
cd full_stack_dev_fix
```

### 2. ตั้งค่า Environment Variables

สร้างไฟล์ `.env` จาก `.env.example` (หรือแก้ไขไฟล์ `.env` ที่มีอยู่):

```env
DB_USER=your_db_user
DB_PASSWORD=your_db_password
DB_NAME=fleet_db
JWT_ACCESS_SECRET=your_access_secret
JWT_REFRESH_SECRET=your_refresh_secret
```

### 3. รัน Backend + Database ด้วย Docker

```sh
# รัน MySQL, phpMyAdmin และ Backend ใน background
docker-compose up -d
```

> **หมายเหตุ**: Backend รัน `node --watch server.cjs` + Volume Mapping (`.:/app`)  
> ทำให้การแก้ไขไฟล์ JS เห็นผลทันที **โดยไม่ต้อง rebuild Docker image**

### 4. รัน Frontend (Local Dev)

```sh
# ติดตั้ง dependencies
npm install

# รัน Vite Dev Server (Hot-Reload)
npm run dev
```

### 5. เข้าใช้งาน

| Service | URL |
|---------|-----|
| **Frontend** | http://localhost:5173 |
| **Backend API** | http://localhost:3000 |
| **API Docs (Scalar)** | http://localhost:3000/api-docs |
| **phpMyAdmin** | http://localhost:8080 |

---

## API Documentation

API Documentation สร้างโดย **swagger-autogen** และแสดงผลผ่าน **@scalar/express-api-reference**

เข้าถึงได้ที่: **http://localhost:3000/api-docs**

### API Endpoints หลัก

| Method | Endpoint | คำอธิบาย |
|--------|----------|----------|
| `POST` | `/auth/login` | เข้าสู่ระบบ |
| `POST` | `/auth/refresh` | Refresh Token |
| `GET` | `/vehicles` | ดูรายการยานพาหนะทั้งหมด |
| `POST` | `/vehicles` | เพิ่มยานพาหนะใหม่ |
| `PATCH` | `/vehicles/:id` | แก้ไขยานพาหนะ |
| `DELETE` | `/vehicles/:id` | ลบยานพาหนะ |
| `GET` | `/drivers` | ดูรายการพนักงานขับรถ |
| `POST` | `/drivers` | เพิ่มพนักงานขับรถ |
| `GET` | `/trips` | ดูรายการการเดินทาง |
| `POST` | `/trips` | สร้าง Trip ใหม่ (Auto-ID: `trp_001`) |
| `PATCH` | `/trips/:id/status` | เปลี่ยนสถานะ Trip |
| `GET` | `/maintenance` | ดูรายการงานซ่อมบำรุง |
| `POST` | `/maintenance` | บันทึกงานซ่อมบำรุงใหม่ |
| `GET` | `/alerts` | ดูการแจ้งเตือนทั้งหมด |
| `GET` | `/audit-logs` | ดู Audit Logs |

### Error Response Format

ทุก API Error ตอบกลับในรูปแบบมาตรฐาน:

```json
{
  "error": {
    "code": "RESOURCE_NOT_FOUND",
    "message": "ไม่พบข้อมูลที่ต้องการ",
    "details": {}
  }
}
```

---

## Environment Variables

| Variable | คำอธิบาย | ตัวอย่าง |
|----------|----------|---------|
| `DB_USER` | MySQL Username | `fleet_user` |
| `DB_PASSWORD` | MySQL Password | `securepassword` |
| `DB_NAME` | ชื่อฐานข้อมูล | `fleet_db` |
| `JWT_ACCESS_SECRET` | Secret สำหรับ Access Token | `random_secret_string` |
| `JWT_REFRESH_SECRET` | Secret สำหรับ Refresh Token | `another_random_secret` |

---

## Scripts

```sh
npm run dev        # รัน Vite Dev Server (Frontend)
npm run build      # Build สำหรับ Production
npm run preview    # Preview Production Build
npm run lint       # ตรวจสอบ Code (OXLint + ESLint)
npm run format     # จัดรูปแบบ Code (Prettier)
```

---

## Docker Commands

```sh
# รัน Services ทั้งหมด
docker-compose up -d

# ดู Log ของ Backend
docker-compose logs -f backend

# หยุด Services ทั้งหมด
docker-compose down

# หยุดและลบ Volume (Database)
docker-compose down -v
```

---

## หมายเหตุสำหรับนักพัฒนา

- ระบบ Backend รองรับ **Hot-Reload** ผ่าน `node --watch` + Docker Volume Mapping — ไม่ต้อง rebuild เมื่อแก้ไข `.cjs` ไฟล์
- Timezone ของระบบทั้งหมดตั้งค่าเป็น **Asia/Bangkok (UTC+7)**
- Frontend ใช้ **Custom Dropdown Component** แทน native `<select>` เพื่อ UI ที่สวยงามกว่า
- Alert ทุกรายการแสดงเป็น **ภาษาไทย**

---

<p align="center">
  Built with ❤️ using Vue 3 + Express + MySQL
</p>
