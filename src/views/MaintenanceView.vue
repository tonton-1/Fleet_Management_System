<template>
  <div class="maintenance-container">
    <div class="main-layout">
      <!-- Maintenance Schedule Section -->
      <div class="schedule-section">
        <div class="section-header">
          <h1>ตารางการบำรุงรักษา</h1>
          <button class="refresh-btn" @click="fetchData" :disabled="loading">
            <svg
              xmlns="http://www.w3.org/2000/svg"
              fill="none"
              viewBox="0 0 24 24"
              stroke-width="1.5"
              stroke="currentColor"
              :class="{ spinning: loading }"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                d="M16.023 9.348h4.992v-.001M2.985 19.644v-4.992m0 0h4.992m-4.993 0 3.181 3.183a8.25 8.25 0 0 0 13.803-3.7M4.031 9.865a8.25 8.25 0 0 1 13.803-3.7l3.181 3.182m0-4.991v4.99"
              />
            </svg>
            รีเฟรช
          </button>
        </div>

        <div v-if="loading" class="loading">
          <div class="spinner"></div>
        </div>

        <div v-else class="table-container">
          <table class="maintenance-table">
            <thead>
              <tr>
                <th>สถานะ</th>
                <th>ยานพาหนะ</th>
                <th>ประเภท</th>
                <th>กำหนดวันที่</th>
                <th>ช่าง</th>
                <th>หมายเหตุ</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="item in maintenanceList" :key="item.id" :class="getRowClass(item)">
                <td>
                  <span :class="['status-badge', getStatusClass(item)]">
                    {{ getStatusLabel(item) }}
                  </span>
                </td>
                <td>
                  <div class="vehicle-info">
                    <span class="license-plate">{{ item.license_plate || '-' }}</span>
                    <span class="vehicle-type">{{ item.vehicle_type || '-' }}</span>
                  </div>
                </td>
                <td>{{ getTypeLabel(item.type) }}</td>
                <td>{{ formatDate(item.scheduled_at) }}</td>
                <td>{{ item.technician || '-' }}</td>
                <td>{{ item.notes || '-' }}</td>
              </tr>
            </tbody>
          </table>

          <div v-if="maintenanceList.length === 0" class="no-data">ไม่มีข้อมูลการบำรุงรักษา</div>
        </div>
      </div>

      <!-- Alerts Panel -->
      <div class="alerts-panel">
        <div class="panel-header">
          <h2>
            <svg
              xmlns="http://www.w3.org/2000/svg"
              fill="none"
              viewBox="0 0 24 24"
              stroke-width="2"
              stroke="currentColor"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                d="M14.857 17.082a23.848 23.848 0 0 0 5.454-1.31A8.967 8.967 0 0 1 18 9.75V9A6 6 0 0 0 6 9v.75a8.967 8.967 0 0 1-2.312 6.022c1.733.64 3.56 1.085 5.455 1.31m5.714 0a24.255 24.255 0 0 1-5.714 0m5.714 0a3 3 0 1 1-5.714 0"
              />
            </svg>
            การแจ้งเตือน
          </h2>
          <div class="alert-count" v-if="alerts.length > 0">
            <span class="count critical" v-if="criticalCount > 0">{{ criticalCount }} วิกฤต</span>
            <span class="count warning" v-if="warningCount > 0">{{ warningCount }} คำเตือน</span>
          </div>
        </div>

        <div class="alerts-list">
          <div
            v-for="alert in alerts"
            :key="alert.id"
            :class="['alert-item', alert.severity.toLowerCase()]"
          >
            <div class="alert-icon">
              <svg
                v-if="alert.severity === 'CRITICAL'"
                xmlns="http://www.w3.org/2000/svg"
                fill="none"
                viewBox="0 0 24 24"
                stroke-width="2"
                stroke="currentColor"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"
                />
              </svg>
              <svg
                v-else
                xmlns="http://www.w3.org/2000/svg"
                fill="none"
                viewBox="0 0 24 24"
                stroke-width="2"
                stroke="currentColor"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
                />
              </svg>
            </div>
            <div class="alert-content">
              <div class="alert-type">{{ getResourceTypeLabel(alert.affected_resource_type) }}</div>
              <div class="alert-message">{{ alert.message }}</div>
            </div>
          </div>

          <div v-if="alerts.length === 0" class="no-alerts">
            <svg
              xmlns="http://www.w3.org/2000/svg"
              fill="none"
              viewBox="0 0 24 24"
              stroke-width="1.5"
              stroke="currentColor"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                d="M9 12.75 11.25 15 15 9.75M21 12a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z"
              />
            </svg>
            ไม่มีการแจ้งเตือน
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { maintenanceApi } from '../api/maintenance'
import { alertsApi } from '../api/alerts'

const maintenanceList = ref([])
const alerts = ref([])
const loading = ref(false)

const criticalCount = computed(() => alerts.value.filter((a) => a.severity === 'CRITICAL').length)
const warningCount = computed(() => alerts.value.filter((a) => a.severity === 'WARNING').length)

const maintenanceTypes = {
  OIL_CHANGE: 'เปลี่ยนน้ำมัน',
  TIRE: 'ยาง',
  BRAKE: 'เบรก',
  ENGINE: 'เครื่องยนต์',
  INSPECTION: 'ตรวจสภาพ',
  REPAIR: 'ซ่อมแซม',
}

const maintenanceStatuses = {
  SCHEDULED: 'รอดำเนินการ',
  IN_PROGRESS: 'กำลังดำเนินการ',
  COMPLETED: 'เสร็จสิ้น',
  OVERDUE: 'เลยกำหนด',
}

const resourceTypeLabels = {
  VEHICLE: 'ยานพาหนะ',
  MAINTENANCE: 'การบำรุงรักษา',
  DRIVER: 'คนขับ',
  TRIP: 'การเดินทาง',
}

const getTypeLabel = (type) => maintenanceTypes[type] || type
const getMaintenanceStatusLabel = (status) => maintenanceStatuses[status] || status
const getResourceTypeLabel = (type) => resourceTypeLabels[type] || type

const getDaysUntilDue = (scheduledAt) => {
  const scheduled = new Date(scheduledAt)
  const today = new Date()
  today.setHours(0, 0, 0, 0)
  scheduled.setHours(0, 0, 0, 0)
  const diffTime = scheduled - today
  return Math.ceil(diffTime / (1000 * 60 * 60 * 24))
}

const getStatusClass = (item) => {
  if (item.status === 'OVERDUE') return 'overdue'
  if (item.status === 'COMPLETED') return 'completed'
  if (item.status === 'IN_PROGRESS') return 'in-progress'

  const daysUntil = getDaysUntilDue(item.scheduled_at)
  if (daysUntil < 0) return 'overdue'
  if (daysUntil <= 7) return 'due-soon'
  return 'scheduled'
}

const getStatusLabel = (item) => {
  if (item.status === 'OVERDUE') return 'เลยกำหนด'
  if (item.status === 'COMPLETED') return 'เสร็จสิ้น'
  if (item.status === 'IN_PROGRESS') return 'กำลังดำเนินการ'

  const daysUntil = getDaysUntilDue(item.scheduled_at)
  if (daysUntil < 0) return 'เลยกำหนด'
  if (daysUntil <= 7) return 'ใกล้ถึงกำหนด'
  return 'ตามกำหนด'
}

const getRowClass = (item) => {
  return {
    'row-overdue': getStatusClass(item) === 'overdue',
    'row-due-soon': getStatusClass(item) === 'due-soon',
    'row-completed': getStatusClass(item) === 'completed',
    'row-in-progress': getStatusClass(item) === 'in-progress',
  }
}

const formatDate = (dateString) => {
  if (!dateString) return '-'
  const date = new Date(dateString)
  return date.toLocaleDateString('th-TH', {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
  })
}

const fetchData = async () => {
  loading.value = true
  try {
    const [maintenanceRes, alertsRes] = await Promise.all([
      maintenanceApi.getAll(),
      alertsApi.getAlerts(),
    ])
    maintenanceList.value = maintenanceRes.data
    alerts.value = alertsRes.data
  } catch (error) {
    console.error('Failed to fetch data:', error)
  } finally {
    loading.value = false
  }
}

onMounted(() => {
  fetchData()
})
</script>

<style scoped>
.maintenance-container {
  padding: 32px 24px;
  max-width: 1400px;
  margin: 0 auto;
  font-family:
    'Inter',
    -apple-system,
    BlinkMacSystemFont,
    'Segoe UI',
    Roboto,
    sans-serif;
  color: #1f2937;
}

.main-layout {
  display: grid;
  grid-template-columns: 1fr 340px;
  gap: 32px;
}

@media (max-width: 1024px) {
  .main-layout {
    grid-template-columns: 1fr;
  }
}

.section-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 24px;
}

h1 {
  font-size: 32px;
  font-weight: 800;
  margin: 0;
  letter-spacing: -0.025em;
  background: linear-gradient(135deg, #1e293b 0%, #334155 100%);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
}

.refresh-btn {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 12px 20px;
  background: linear-gradient(135deg, #3b82f6 0%, #2563eb 100%);
  color: white;
  border: none;
  border-radius: 12px;
  font-size: 15px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
  box-shadow: 0 4px 12px rgba(37, 99, 235, 0.2);
}

.refresh-btn:hover:not(:disabled) {
  transform: translateY(-2px);
  box-shadow: 0 8px 16px rgba(37, 99, 235, 0.3);
}

.refresh-btn:active:not(:disabled) {
  transform: translateY(1px);
}

.refresh-btn:disabled {
  opacity: 0.6;
  cursor: not-allowed;
  transform: none;
  box-shadow: none;
}

.refresh-btn svg {
  width: 16px;
  height: 16px;
}

.refresh-btn svg.spinning {
  animation: spin 1s linear infinite;
}

@keyframes spin {
  from {
    transform: rotate(0deg);
  }
  to {
    transform: rotate(360deg);
  }
}

.loading {
  display: flex;
  justify-content: center;
  padding: 40px;
}

.spinner {
  width: 32px;
  height: 32px;
  border: 3px solid #e5e7eb;
  border-top-color: #3b82f6;
  border-radius: 50%;
  animation: spin 0.8s linear infinite;
}

.table-container {
  background: white;
  border-radius: 16px;
  box-shadow: 0 4px 24px rgba(0, 0, 0, 0.04);
  border: 1px solid rgba(226, 232, 240, 0.8);
  overflow-x: auto;
}

.maintenance-table {
  width: 100%;
  border-collapse: collapse;
  white-space: nowrap;
}

.maintenance-table th {
  background: #f8fafc;
  padding: 18px 32px;
  text-align: left;
  font-size: 13px;
  font-weight: 600;
  color: #64748b;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  border-bottom: 2px solid #e2e8f0;
}

.maintenance-table td {
  padding: 16px 32px;
  font-size: 14px;
  color: #334155;
  border-bottom: 1px solid #f1f5f9;
  vertical-align: middle;
}

.maintenance-table tr {
  transition: all 0.2s ease;
  border-left: 4px solid transparent;
}

.maintenance-table tr:hover {
  background-color: #f8fafc;
}

.maintenance-table tr:last-child td {
  border-bottom: none;
}

.maintenance-table tr.row-overdue {
  border-left-color: #ef4444;
  background: #fef2f2;
}

.maintenance-table tr.row-due-soon {
  border-left-color: #f59e0b;
  background: #fffbeb;
}

.maintenance-table tr.row-completed {
  border-left-color: #22c55e;
}

.maintenance-table tr.row-in-progress {
  border-left-color: #3b82f6;
}

.status-badge {
  display: inline-block;
  padding: 6px 14px;
  border-radius: 20px;
  font-size: 12px;
  font-weight: 600;
  letter-spacing: 0.025em;
}

.status-badge.overdue {
  background: #fee2e2;
  color: #b91c1c;
  border: 1px solid #fecaca;
}

.status-badge.due-soon {
  background: #fef3c7;
  color: #b45309;
  border: 1px solid #fde68a;
}

.status-badge.scheduled {
  background: #f1f5f9;
  color: #475569;
  border: 1px solid #e2e8f0;
}

.status-badge.completed {
  background: #dcfce7;
  color: #166534;
  border: 1px solid #bbf7d0;
}

.status-badge.in-progress {
  background: #dbeafe;
  color: #1e40af;
  border: 1px solid #bfdbfe;
}

.vehicle-info {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.license-plate {
  font-weight: 700;
  color: #0f172a;
  font-size: 15px;
}

.vehicle-type {
  font-size: 12px;
  color: #64748b;
  background: #f1f5f9;
  padding: 2px 8px;
  border-radius: 6px;
  width: fit-content;
}

.maintenance-status {
  font-size: 13px;
  font-weight: 600;
  padding: 4px 10px;
  border-radius: 6px;
}

.maintenance-status.scheduled {
  color: #4f46e5;
}
.maintenance-status.in_progress {
  color: #2563eb;
}
.maintenance-status.completed {
  color: #16a34a;
}
.maintenance-status.overdue {
  color: #dc2626;
}

.no-data {
  text-align: center;
  padding: 40px;
  color: #9ca3af;
}

/* Alerts Panel */
.alerts-panel {
  background: white;
  border-radius: 16px;
  box-shadow: 0 4px 24px rgba(0, 0, 0, 0.04);
  border: 1px solid rgba(226, 232, 240, 0.8);
  height: fit-content;
  position: sticky;
  top: 24px;
  overflow: hidden;
}

.panel-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 20px 24px;
  border-bottom: 1px solid #f1f5f9;
  background: #f8fafc;
}

.panel-header h2 {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 18px;
  font-weight: 700;
  color: #1e293b;
  margin: 0;
}

.panel-header h2 svg {
  width: 22px;
  height: 22px;
  color: #3b82f6;
}

.alert-count {
  display: flex;
  gap: 8px;
}

.alert-count .count {
  font-size: 12px;
  padding: 4px 10px;
  border-radius: 20px;
  font-weight: 600;
}

.alert-count .count.critical {
  background: #fee2e2;
  color: #dc2626;
  border: 1px solid #fecaca;
}

.alert-count .count.warning {
  background: #fffbeb;
  color: #d97706;
  border: 1px solid #fde68a;
}

.alerts-list {
  max-height: 500px;
  overflow-y: auto;
  padding: 12px;
}

.alert-item {
  display: flex;
  gap: 16px;
  padding: 16px;
  border-radius: 12px;
  margin-bottom: 8px;
  border: 1px solid transparent;
  transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);
}

.alert-item:last-child {
  margin-bottom: 0;
}

.alert-item:hover {
  background: #f8fafc;
  border-color: #e2e8f0;
  transform: translateY(-1px);
}

.alert-icon {
  flex-shrink: 0;
  width: 40px;
  height: 40px;
  border-radius: 10px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.alert-item.warning .alert-icon {
  background: #fffbeb;
  color: #d97706;
  box-shadow: 0 4px 10px rgba(217, 119, 6, 0.15);
}

.alert-item.critical .alert-icon {
  background: #fef2f2;
  color: #dc2626;
  box-shadow: 0 4px 10px rgba(220, 38, 38, 0.15);
}

.alert-icon svg {
  width: 22px;
  height: 22px;
}

.alert-content {
  flex: 1;
  min-width: 0;
  display: flex;
  flex-direction: column;
  justify-content: center;
}

.alert-type {
  font-size: 12px;
  color: #64748b;
  font-weight: 600;
  text-transform: uppercase;
  margin-bottom: 4px;
  letter-spacing: 0.025em;
}

.alert-message {
  font-size: 14px;
  color: #1e293b;
  line-height: 1.5;
  font-weight: 500;
}

.no-alerts {
  display: flex;
  flex-direction: column;
  align-items: center;
  padding: 60px 20px;
  color: #64748b;
  background: #f8fafc;
  border-radius: 12px;
  margin: 12px;
}

.no-alerts svg {
  width: 48px;
  height: 48px;
  margin-bottom: 12px;
  color: #94a3b8;
}
</style>
