<template>
  <div class="audit-logs-container">
    <div class="header">
      <h1>ประวัติการใช้งาน</h1>
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

    <!-- Filters -->
    <div class="filters">
      <div class="filter-group">
        <label>การกระทำ</label>
        <select v-model="filters.action" @change="fetchData">
          <option value="">ทั้งหมด</option>
          <option value="LOGIN_SUCCESS">Login สำเร็จ</option>
          <option value="LOGIN_FAIL">Login ล้มเหลว</option>
          <option value="CREATE_VEHICLE">สร้างยานพาหนะ</option>
          <option value="UPDATE_VEHICLE_STATUS">อัปเดตสถานะยานพาหนะ</option>
          <option value="ASSIGN_DRIVER">มอบหมายคนขับ</option>
          <option value="DELETE_VEHICLE">ลบยานพาหนะ</option>
          <option value="UPDATE_TRIP_STATUS">อัปเดตสถานะการเดินทาง</option>
          <option value="UPDATE_CHECKPOINT_STATUS">อัปเดตจุดพัก</option>
        </select>
      </div>

      <div class="filter-group">
        <label>ประเภท</label>
        <select v-model="filters.resource_type" @change="fetchData">
          <option value="">ทั้งหมด</option>
          <option value="AUTH">การยืนยันตัวตน</option>
          <option value="VEHICLE">ยานพาหนะ</option>
          <option value="TRIP">การเดินทาง</option>
          <option value="CHECKPOINT">จุดพัก</option>
        </select>
      </div>

      <div class="filter-group">
        <label>วันที่เริ่ม</label>
        <input type="date" v-model="filters.start_date" @change="fetchData" />
      </div>

      <div class="filter-group">
        <label>วันที่สิ้นสุด</label>
        <input type="date" v-model="filters.end_date" @change="fetchData" />
      </div>
    </div>

    <!-- Loading -->
    <div v-if="loading" class="loading">
      <div class="spinner"></div>
    </div>

    <!-- Table -->
    <div v-else class="table-container">
      <table class="audit-table">
        <thead>
          <tr>
            <th>วันที่/เวลา</th>
            <th>ผู้ใช้</th>
            <th>การกระทำ</th>
            <th>ประเภท</th>
            <th>Resource ID</th>
            <th>ผลลัพธ์</th>
            <th>รายละเอียด</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="log in logs" :key="log.id" :class="log.result.toLowerCase()">
            <td>{{ formatDate(log.created_at) }}</td>
            <td>{{ log.user_id ? log.user_id.substring(0, 8) + '...' : '-' }}</td>
            <td>
              <span :class="['action-badge', getActionClass(log.action)]">
                {{ getActionLabel(log.action) }}
              </span>
            </td>
            <td>{{ getResourceTypeLabel(log.resource_type) }}</td>
            <td>{{ log.resource_id ? log.resource_id.substring(0, 12) + '...' : '-' }}</td>
            <td>
              <span :class="['result-badge', log.result.toLowerCase()]">
                {{ log.result === 'SUCCESS' ? 'สำเร็จ' : 'ล้มเหลว' }}
              </span>
            </td>
            <td>
              <button v-if="log.detail" class="detail-btn" @click="showDetail(log)">
                ดูรายละเอียด
              </button>
              <span v-else>-</span>
            </td>
          </tr>
        </tbody>
      </table>

      <div v-if="logs.length === 0" class="no-data">ไม่พบข้อมูล</div>
    </div>

    <!-- Detail Modal -->
    <div v-if="selectedLog" class="modal-overlay" @click="selectedLog = null">
      <div class="modal" @click.stop>
        <div class="modal-header">
          <h3>รายละเอียด</h3>
          <button class="close-btn" @click="selectedLog = null">&times;</button>
        </div>
        <div class="modal-body">
          <pre>{{ formatDetail(selectedLog.detail) }}</pre>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { auditLogsApi } from '../api/auditLogs'

const loading = ref(false)
const logs = ref([])
const selectedLog = ref(null)

const filters = ref({
  action: '',
  resource_type: '',
  start_date: '',
  end_date: '',
})

const actionLabels = {
  LOGIN_SUCCESS: 'Login สำเร็จ',
  LOGIN_FAIL: 'Login ล้มเหลว',
  CREATE_VEHICLE: 'สร้างยานพาหนะ',
  UPDATE_VEHICLE_STATUS: 'อัปเดตสถานะยานพาหนะ',
  ASSIGN_DRIVER: 'มอบหมายคนขับ',
  DELETE_VEHICLE: 'ลบยานพาหนะ',
  UPDATE_TRIP_STATUS: 'อัปเดตสถานะการเดินทาง',
  UPDATE_CHECKPOINT_STATUS: 'อัปเดตจุดพัก',
}

const resourceTypeLabels = {
  AUTH: 'การยืนยันตัวตน',
  VEHICLE: 'ยานพาหนะ',
  TRIP: 'การเดินทาง',
  CHECKPOINT: 'จุดพัก',
}

const getActionLabel = (action) => actionLabels[action] || action
const getResourceTypeLabel = (type) => resourceTypeLabels[type] || type

const getActionClass = (action) => {
  if (action?.includes('LOGIN_FAIL')) return 'fail'
  if (action?.includes('DELETE')) return 'delete'
  if (action?.includes('CREATE')) return 'create'
  if (action?.includes('UPDATE')) return 'update'
  return ''
}

const formatDate = (dateString) => {
  if (!dateString) return '-'
  const date = new Date(dateString)
  return date.toLocaleString('th-TH', {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  })
}

const formatDetail = (detail) => {
  if (!detail) return '-'
  try {
    return JSON.stringify(JSON.parse(detail), null, 2)
  } catch {
    return detail
  }
}

const showDetail = (log) => {
  selectedLog.value = log
}

const fetchData = async () => {
  loading.value = true
  try {
    const params = {}
    if (filters.value.action) params.action = filters.value.action
    if (filters.value.resource_type) params.resource_type = filters.value.resource_type
    if (filters.value.start_date) params.start_date = filters.value.start_date
    if (filters.value.end_date) params.end_date = filters.value.end_date

    const response = await auditLogsApi.getAuditLogs(params)
    logs.value = response.data
  } catch (error) {
    console.error('Failed to fetch audit logs:', error)
  } finally {
    loading.value = false
  }
}

onMounted(() => {
  fetchData()
})
</script>

<style scoped>
.audit-logs-container {
  padding: 24px;
}

.header {
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

.filters {
  display: flex;
  gap: 16px;
  margin-bottom: 20px;
  padding: 16px;
  background: #f9fafb;
  border-radius: 12px;
  flex-wrap: wrap;
}

.filter-group {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.filter-group label {
  font-size: 13px;
  font-weight: 500;
  color: #6b7280;
}

.filters select,
.filters input {
  padding: 8px 12px;
  border: 1px solid #e5e7eb;
  border-radius: 8px;
  font-size: 14px;
  background: white;
  min-width: 150px;
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

.audit-table {
  width: 100%;
  border-collapse: collapse;
}

.audit-table th {
  background: #f9fafb;
  padding: 14px 16px;
  text-align: left;
  font-size: 13px;
  font-weight: 600;
  color: #6b7280;
  border-bottom: 1px solid #e5e7eb;
}

.audit-table td {
  padding: 12px 16px;
  font-size: 13px;
  color: #374151;
  border-bottom: 1px solid #f3f4f6;
}

.audit-table tr:last-child td {
  border-bottom: none;
}

.audit-table tr.fail {
  background: #fef2f2;
}

.action-badge {
  padding: 4px 8px;
  border-radius: 4px;
  font-size: 12px;
  font-weight: 500;
}

.action-badge.create {
  background: #d1fae5;
  color: #059669;
}
.action-badge.update {
  background: #dbeafe;
  color: #2563eb;
}
.action-badge.delete {
  background: #fee2e2;
  color: #dc2626;
}
.action-badge.fail {
  background: #fee2e2;
  color: #dc2626;
}

.result-badge {
  padding: 4px 8px;
  border-radius: 4px;
  font-size: 12px;
  font-weight: 500;
}

.result-badge.success {
  background: #d1fae5;
  color: #059669;
}
.result-badge.fail {
  background: #fee2e2;
  color: #dc2626;
}

.detail-btn {
  padding: 4px 8px;
  background: #f3f4f6;
  border: none;
  border-radius: 4px;
  font-size: 12px;
  cursor: pointer;
  color: #374151;
}

.detail-btn:hover {
  background: #e5e7eb;
}

.no-data {
  text-align: center;
  padding: 40px;
  color: #9ca3af;
}

.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.5);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
}

.modal {
  background: white;
  border-radius: 12px;
  width: 90%;
  max-width: 500px;
  max-height: 80vh;
  overflow: hidden;
  display: flex;
  flex-direction: column;
}

.modal-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 16px 20px;
  border-bottom: 1px solid #e5e7eb;
}

.modal-header h3 {
  margin: 0;
  font-size: 16px;
  font-weight: 600;
}

.close-btn {
  background: none;
  border: none;
  font-size: 24px;
  cursor: pointer;
  color: #6b7280;
}

.modal-body {
  padding: 20px;
  overflow-y: auto;
}

.modal-body pre {
  background: #f3f4f6;
  padding: 12px;
  border-radius: 8px;
  font-size: 12px;
  white-space: pre-wrap;
  word-break: break-all;
}
</style>
