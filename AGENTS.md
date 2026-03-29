# Agents Working Notes

## Alert Engine Implementation

### 1. Database Schema

- Created `alerts` table in MySQL with fields:
  - id, rule_name, severity, affected_resource_type, affected_resource_id, message, created_at, updated_at
  - UNIQUE constraint on (rule_name, affected_resource_id)

### 2. Alert Engine Structure

```
src/alertEngine/
├── alertEngine.cjs         # Core Engine (auto-loads all rules from /rules)
├── ruleInterface.cjs      # Base class for rules
└── rules/
    ├── vehicleDueForService.cjs   # Rule 1: mileage_km >= next_service_km
    ├── overdueMaintenance.cjs    # Rule 2: maintenance SCHEDULED > 3 days
    ├── licenseExpiringSoon.cjs   # Rule 3: license expires within 30 days
    └── tripDelayed.cjs           # Rule 4: trip IN_PROGRESS > 150% estimated duration
```

### 3. Key Features

- **Auto-loading**: Core engine loads all `.cjs` files in `/rules` folder automatically
- **Add new rule**: Simply create new file in `/rules` - no code changes needed in core
- **Background sync**: Runs every 60 seconds to evaluate all rules and sync to database
- **API**: `GET /alerts` with filters for `severity` and `resource_type`

### 4. Frontend

- Created `AlertsView.vue` with Thai language support
- Filters: severity (คำเตือน/วิกฤต), resource_type (ยานพาหนะ/การบำรุงรักษา/คนขับ/การเดินทาง)
- Added route in router and menu in Navbar

### 5. Test Data

```sql
-- Vehicle Due for Service
INSERT INTO vehicles (id, license_plate, type, status, mileage_km, next_service_km)
VALUES ('veh_test1', 'กท-1111', 'TRUCK', 'IDLE', 50000, 45000);

-- Overdue Maintenance
INSERT INTO vehicles (id, license_plate, type, status)
VALUES ('veh_test2', 'กท-2222', 'VAN', 'MAINTENANCE');
INSERT INTO maintenance (id, vehicle_id, status, type, scheduled_at)
VALUES ('mnt_test1', 'veh_test2', 'SCHEDULED', 'OIL_CHANGE', '2024-01-01 09:00:00');

-- License Expiring Soon
INSERT INTO drivers (id, name, license_number, license_expires_at, phone, status)
VALUES ('drv_test1', 'สมชาย', '123456789', DATE_ADD(CURDATE(), INTERVAL 15 DAY), '0812345678', 'ACTIVE');
```

### 6. Docker Commands

```bash
# Rebuild backend with new code
docker-compose build backend
docker-compose up -d backend

# Build frontend
docker-compose build frontend

# Run frontend locally (not in docker)
npm run dev
```

### 7. API Endpoints

- `POST /auth/login` - Login
- `GET /alerts` - Get alerts with filters
  - Query params: `?severity=WARNING|CRITICAL`, `?resource_type=VEHICLE|MAINTENANCE|DRIVER|TRIP`

## Remaining Tasks

- [ ] Trip Delayed alert (needs trip running > 150% estimated duration)
- [ ] Audit Log implementation
- [ ] Dashboard charts (vehicles by status, trip distance trend)
