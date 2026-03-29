# Agents Working Notes

## 1. Alert Engine Implementation

### Database Schema
- Created `alerts` table in MySQL with fields:
  - id, rule_name, severity, affected_resource_type, affected_resource_id, message, created_at, updated_at
  - UNIQUE constraint on (rule_name, affected_resource_id)

### Alert Engine Structure
```text
src/alertEngine/
├── alertEngine.cjs         # Core Engine (auto-loads all rules from /rules)
├── ruleInterface.cjs      # Base class for rules
└── rules/
    ├── vehicleDueForService.cjs   # แจ้งเตือน: ถึงรอบเช็คระยะ
    ├── overdueMaintenance.cjs    # แจ้งเตือน: ซ่อมบำรุงล่าช้า
    ├── licenseExpiringSoon.cjs   # แจ้งเตือน: ใบขับขี่ใกล้หมดอายุ
    └── tripDelayed.cjs           # แจ้งเตือน: การเดินทางล่าช้า
```

### Key Features
- **Auto-loading**: Core engine loads all `.cjs` files in `/rules` folder automatically.
- **Thai Localization**: All alert messages and rule names have been fully translated to Thai for frontend display.
- **Background sync**: Runs every 60 seconds to evaluate all rules and sync to database.

## 2. API & Backend Enhancements

- **Timezone Support**: Backend and MySQL configured to `Asia/Bangkok` timezone resolving date discrepancies in Audit Logs and database timestamps.
- **Auto-Increment IDs**: `POST /trips` endpoint modified to automatically generate sequentially incremented IDs like `trp_001`, `trp_002` (per PDF assignment specs) instead of UUIDs.
- **Hot-Reloading**: Backend container now mapped to local volume with `node --watch server.cjs` for instant development reloads.
- **Standardized Error Responses**: All API error responses follow the standard schema format:
  ```json
  {
    "error": {
      "code": "...",
      "message": "...",
      "details": {}
    }
  }
  ```

## 3. Frontend Details

- **Login UI**: Completely redesigned to a highly premium "Minimal White" theme with subtle aesthetics and dark accents. Removed unused options like "Remember me" and "Forgot password" to keep it highly minimalistic.
- **AlertsView.vue**: Features Thai language support with filtering for severity (`คำเตือน`/`วิกฤต`) and resource types.
- **TripsView.vue**: Contains optimistic UI updating for Checkpoint statuses (`PENDING`, `ARRIVED`, `DEPARTED`, `SKIPPED`). Removed artificial simulated 30% network failure rate for smooth local testing.

## 4. Docker Commands (Current Flow)

```bash
# Start all containers in background
docker-compose up -d

# NOTE: Thanks to Volume Mapping (`.:/app`) and `node --watch`, backend changes instantly sync!
# You do NOT need to run `docker-compose build backend` anymore when editing JS files.

# Run frontend locally for instant UI development
npm run dev
```

## 5. Completed & Remaining Tasks

- [x] Fix Trip Auto-Increment IDs (trp_001)
- [x] Alert Engine UI & Thai Translations completed
- [x] Audit Log timezone discrepancies fixed
- [x] Login UI Redesign (Minimal White theme completed)
- [x] Add overarching Trip Status controls (e.g. manually Start, Complete, or Cancel trips)
- [ ] Dashboard charts (vehicles by status, trip distance trend)
