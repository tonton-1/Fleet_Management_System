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
                <th>สถานะการบำรุงรักษา</th>
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
                <td>
                  <span :class="['maintenance-status', item.status.toLowerCase()]">
                    {{ getMaintenanceStatusLabel(item.status) }}
                  </span>
                </td>
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
              stroke-width="1.5"
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
                stroke-width="1.5"
                stroke="currentColor"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  d="M12 9v3.75m-9.303 3.376c-.866 1.5.217 3.374 1.948 3.374h14.71c1.73 0 2.813-1.874 1.948-3.374L13.949 3.378c-.866-1.5-3.032-1.5-3.898 0L2.697 16.126ZM12 15.75h.007v.008H12v-.008Z"
                />
              </svg>
              <svg
                v-else
                xmlns="http://www.w3.org/2000/svg"
                fill="none"
                viewBox="0 0 24 24"
                stroke-width="1.5"
                stroke="currentColor"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  d="M12 9v3.75m9-.75a9 9 0 1 1-18 0 9 9 0 0 1 18 0Zm-9 3.75h.008v.008H12v-.008Z"
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
  padding: 24px;
}

.main-layout {
  display: grid;
  grid-template-columns: 1fr 320px;
  gap: 24px;
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
  margin-bottom: 20px;
}

h1 {
  font-size: 24px;
  font-weight: 600;
  color: #1f2937;
  margin: 0;
}

.refresh-btn {
  display: flex;
  align-items: center;
  gap: 6px;
  padding: 8px 14px;
  background: #3b82f6;
  color: white;
  border: none;
  border-radius: 8px;
  font-size: 14px;
  cursor: pointer;
  transition: background 0.2s;
}

.refresh-btn:hover:not(:disabled) {
  background: #2563eb;
}

.refresh-btn:disabled {
  opacity: 0.6;
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
  border-radius: 12px;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.08);
  overflow: hidden;
}

.maintenance-table {
  width: 100%;
  border-collapse: collapse;
}

.maintenance-table th {
  background: #f9fafb;
  padding: 14px 16px;
  text-align: left;
  font-size: 13px;
  font-weight: 600;
  color: #6b7280;
  border-bottom: 1px solid #e5e7eb;
}

.maintenance-table td {
  padding: 14px 16px;
  font-size: 14px;
  color: #374151;
  border-bottom: 1px solid #f3f4f6;
}

.maintenance-table tr:last-child td {
  border-bottom: none;
}

.maintenance-table tr.row-overdue {
  background: #fef2f2;
}

.maintenance-table tr.row-due-soon {
  background: #fffbeb;
}

.maintenance-table tr.row-completed {
  background: #f0fdf4;
}

.maintenance-table tr.row-in-progress {
  background: #eff6ff;
}

.status-badge {
  display: inline-block;
  padding: 4px 10px;
  border-radius: 6px;
  font-size: 12px;
  font-weight: 600;
}

.status-badge.overdue {
  background: #fee2e2;
  color: #dc2626;
}

.status-badge.due-soon {
  background: #fef3c7;
  color: #d97706;
}

.status-badge.scheduled {
  background: #e0e7ff;
  color: #4f46e5;
}

.status-badge.completed {
  background: #dcfce7;
  color: #16a34a;
}

.status-badge.in-progress {
  background: #dbeafe;
  color: #2563eb;
}

.vehicle-info {
  display: flex;
  flex-direction: column;
}

.license-plate {
  font-weight: 600;
  color: #1f2937;
}

.vehicle-type {
  font-size: 12px;
  color: #6b7280;
}

.maintenance-status {
  font-size: 13px;
  padding: 4px 8px;
  border-radius: 4px;
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
  border-radius: 12px;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.08);
  height: fit-content;
  position: sticky;
  top: 24px;
}

.panel-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 16px 20px;
  border-bottom: 1px solid #e5e7eb;
}

.panel-header h2 {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 16px;
  font-weight: 600;
  color: #1f2937;
  margin: 0;
}

.panel-header h2 svg {
  width: 20px;
  height: 20px;
  color: #6b7280;
}

.alert-count {
  display: flex;
  gap: 8px;
}

.alert-count .count {
  font-size: 12px;
  padding: 3px 8px;
  border-radius: 12px;
  font-weight: 500;
}

.alert-count .count.critical {
  background: #fee2e2;
  color: #dc2626;
}

.alert-count .count.warning {
  background: #fef3c7;
  color: #d97706;
}

.alerts-list {
  max-height: 500px;
  overflow-y: auto;
}

.alert-item {
  display: flex;
  gap: 12px;
  padding: 14px 20px;
  border-bottom: 1px solid #f3f4f6;
}

.alert-item:last-child {
  border-bottom: none;
}

.alert-icon {
  flex-shrink: 0;
  width: 32px;
  height: 32px;
  border-radius: 8px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.alert-item.warning .alert-icon {
  background: #fef3c7;
  color: #d97706;
}

.alert-item.critical .alert-icon {
  background: #fee2e2;
  color: #dc2626;
}

.alert-icon svg {
  width: 18px;
  height: 18px;
}

.alert-content {
  flex: 1;
  min-width: 0;
}

.alert-type {
  font-size: 11px;
  color: #6b7280;
  text-transform: uppercase;
  margin-bottom: 2px;
}

.alert-message {
  font-size: 13px;
  color: #374151;
  line-height: 1.4;
}

.no-alerts {
  display: flex;
  flex-direction: column;
  align-items: center;
  padding: 40px 20px;
  color: #9ca3af;
}

.no-alerts svg {
  width: 40px;
  height: 40px;
  margin-bottom: 8px;
  color: #d1d5db;
}
</style>
