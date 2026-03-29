<template>
  <div class="audit-logs-container">
    <div class="header">
      <h1>ประวัติการใช้งาน</h1>
      <button class="refresh-btn" @click="fetchData" :disabled="loading">
        <svg
          xmlns="http://www.w3.org/2000/svg"
          fill="none"
          viewBox="0 0 24 24"
          stroke-width="2"
          stroke="currentColor"
          :class="{ spinning: loading }"
        >
          <path
            stroke-linecap="round"
            stroke-linejoin="round"
            d="M16.023 9.348h4.992v-.001M2.985 19.644v-4.992m0 0h4.992m-4.993 0 3.181 3.183a8.25 8.25 0 0 0 13.803-3.7M4.031 9.865a8.25 8.25 0 0 1 13.803-3.7l3.181 3.182m0-4.991v4.99"
          />
        </svg>
        รีเฟรชข้อมูล
      </button>
    </div>

    <!-- Filters -->
    <div class="filters">
      <div class="filter-group">
        <label>การกระทำ</label>
        <div class="select-wrapper">
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
      </div>

      <div class="filter-group">
        <label>ประเภท</label>
        <div class="select-wrapper">
          <select v-model="filters.resource_type" @change="fetchData">
            <option value="">ทั้งหมด</option>
            <option value="AUTH">การยืนยันตัวตน</option>
            <option value="VEHICLE">ยานพาหนะ</option>
            <option value="TRIP">การเดินทาง</option>
            <option value="CHECKPOINT">จุดพัก</option>
          </select>
        </div>
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
          <tr
            v-for="log in logs"
            :key="log.id"
            :class="log.result.toLowerCase() === 'fail' ? 'row-fail' : ''"
          >
            <td class="time-cell">{{ formatDate(log.created_at) }}</td>
            <td class="user-cell">{{ log.user_id ? log.user_id.substring(0, 8) + '...' : '-' }}</td>
            <td>
              <span :class="['action-badge', getActionClass(log.action)]">
                {{ getActionLabel(log.action) }}
              </span>
            </td>
            <td>
              <span class="resource-badge">{{ getResourceTypeLabel(log.resource_type) }}</span>
            </td>
            <td class="id-cell">
              {{ log.resource_id ? log.resource_id.substring(0, 12) + '...' : '-' }}
            </td>
            <td>
              <span :class="['result-badge', log.result.toLowerCase()]">
                {{ log.result === 'SUCCESS' ? 'สำเร็จ' : 'ล้มเหลว' }}
              </span>
            </td>
            <td class="action-cell">
              <button v-if="log.detail" class="detail-btn" @click="showDetail(log)">
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
                    d="M19.5 14.25v-2.625a3.375 3.375 0 0 0-3.375-3.375h-1.5A1.125 1.125 0 0 1 13.5 7.125v-1.5a3.375 3.375 0 0 0-3.375-3.375H8.25m5.231 13.481L15 17.25m-4.5-15H5.625c-.621 0-1.125.504-1.125 1.125v17.25c0 .621.504 1.125 1.125 1.125h12.75c.621 0 1.125-.504 1.125-1.125V11.25a9 9 0 0 0-9-9Zm3.75 11.625a2.625 2.625 0 1 1-5.25 0 2.625 2.625 0 0 1 5.25 0Z"
                  />
                </svg>
                รายละเอียด
              </button>
              <span v-else class="empty-detail">-</span>
            </td>
          </tr>
        </tbody>
      </table>

      <div v-if="logs.length === 0" class="no-data">
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
            d="M19.5 14.25v-2.625a3.375 3.375 0 0 0-3.375-3.375h-1.5A1.125 1.125 0 0 1 13.5 7.125v-1.5a3.375 3.375 0 0 0-3.375-3.375H8.25m5.231 13.481L15 17.25m-4.5-15H5.625c-.621 0-1.125.504-1.125 1.125v17.25c0 .621.504 1.125 1.125 1.125h12.75c.621 0 1.125-.504 1.125-1.125V11.25a9 9 0 0 0-9-9Zm3.75 11.625a2.625 2.625 0 1 1-5.25 0 2.625 2.625 0 0 1 5.25 0Z"
          />
        </svg>
        ไม่พบข้อมูลประวัติการใช้งาน
      </div>
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

.header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 32px;
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
  width: 20px;
  height: 20px;
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
  align-items: center;
  margin-bottom: 32px;
  padding: 20px;
  background: white;
  border-radius: 16px;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.03);
  border: 1px solid rgba(226, 232, 240, 0.8);
  flex-wrap: wrap;
}

.filter-group {
  display: flex;
  flex-direction: column;
  gap: 8px;
  flex: 1;
  min-width: 200px;
}

.filter-group label {
  font-size: 13px;
  font-weight: 600;
  color: #475569;
}

.select-wrapper {
  position: relative;
  width: 100%;
}

.filters select,
.filters input {
  width: 100%;
  padding: 12px 16px;
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  font-size: 14px;
  color: #334155;
  background-color: #f8fafc;
  transition: all 0.2s;
  box-sizing: border-box;
}

.filters select {
  cursor: pointer;
  appearance: none;
}

.select-wrapper::after {
  content: '▼';
  font-size: 10px;
  position: absolute;
  right: 16px;
  top: 50%;
  transform: translateY(-50%);
  pointer-events: none;
  color: #94a3b8;
}

.filters select:hover,
.filters input:hover {
  background-color: #fff;
  border-color: #cbd5e1;
}

.filters select:focus,
.filters input:focus {
  outline: none;
  background-color: #fff;
  border-color: #3b82f6;
  box-shadow: 0 0 0 4px rgba(59, 130, 246, 0.1);
}

.loading {
  display: flex;
  justify-content: center;
  padding: 60px;
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

.audit-table {
  width: 100%;
  border-collapse: collapse;
  white-space: nowrap;
}

.audit-table th {
  background: #f8fafc;
  padding: 18px 24px;
  text-align: left;
  font-size: 13px;
  font-weight: 600;
  color: #64748b;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  border-bottom: 2px solid #e2e8f0;
}

.audit-table td {
  padding: 16px 24px;
  font-size: 14px;
  color: #334155;
  border-bottom: 1px solid #f1f5f9;
  vertical-align: middle;
}

.audit-table tr {
  transition: all 0.2s ease;
  border-left: 4px solid transparent;
}

.audit-table tr:hover {
  background-color: #f8fafc;
}

.audit-table tr:last-child td {
  border-bottom: none;
}

.audit-table tr.row-fail {
  border-left-color: #ef4444;
  background: #fef2f2;
}

.time-cell,
.id-cell,
.user-cell {
  font-family: 'SFMono-Regular', Consolas, 'Liberation Mono', Menlo, monospace;
  color: #64748b;
}

.resource-badge {
  font-size: 12px;
  color: #475569;
  background: #f1f5f9;
  padding: 4px 10px;
  border-radius: 6px;
  font-weight: 500;
}

.action-badge {
  display: inline-block;
  padding: 6px 12px;
  border-radius: 8px;
  font-size: 12px;
  font-weight: 600;
  letter-spacing: 0.025em;
  border: 1px solid transparent;
}

.action-badge.create {
  background: #dcfce7;
  color: #166534;
  border-color: #bbf7d0;
}
.action-badge.update {
  background: #dbeafe;
  color: #1e40af;
  border-color: #bfdbfe;
}
.action-badge.delete {
  background: #fee2e2;
  color: #b91c1c;
  border-color: #fecaca;
}
.action-badge.fail {
  background: #fff5f5;
  color: #c53030;
  border-color: #fed7d7;
}

.result-badge {
  display: inline-block;
  padding: 6px 12px;
  border-radius: 20px;
  font-size: 12px;
  font-weight: 600;
  letter-spacing: 0.025em;
}

.result-badge.success {
  background: #dcfce7;
  color: #166534;
  border: 1px solid #bbf7d0;
}
.result-badge.fail {
  background: #fee2e2;
  color: #b91c1c;
  border: 1px solid #fecaca;
}

.action-cell {
  white-space: nowrap;
}

.detail-btn {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  padding: 6px 12px;
  background: white;
  border: 1px solid #cbd5e1;
  border-radius: 8px;
  font-size: 13px;
  font-weight: 600;
  cursor: pointer;
  color: #475569;
  transition: all 0.2s;
  box-shadow: 0 1px 2px rgba(0, 0, 0, 0.05);
}

.detail-btn svg {
  width: 16px;
  height: 16px;
  color: #3b82f6;
}

.detail-btn:hover {
  background: #f8fafc;
  color: #1e293b;
  border-color: #94a3b8;
}

.empty-detail {
  color: #94a3b8;
  padding-left: 12px;
}

.no-data {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 80px 40px;
  color: #64748b;
  background: white;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 16px;
  font-size: 15px;
  font-weight: 500;
}

.no-data svg {
  width: 48px;
  height: 48px;
  color: #cbd5e1;
}

.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(15, 23, 42, 0.6);
  backdrop-filter: blur(8px);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
  padding: 20px;
  animation: fadeIn 0.3s ease-out;
}

.modal {
  background: white;
  border-radius: 20px;
  width: 100%;
  max-width: 600px;
  max-height: 85vh;
  overflow: hidden;
  display: flex;
  flex-direction: column;
  box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.25);
  animation: slideUp 0.4s cubic-bezier(0.16, 1, 0.3, 1);
}

@keyframes slideUp {
  from {
    opacity: 0;
    transform: translateY(30px) scale(0.95);
  }
  to {
    opacity: 1;
    transform: translateY(0) scale(1);
  }
}

.modal-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 20px 24px;
  border-bottom: 1px solid #e2e8f0;
  background: #f8fafc;
}

.modal-header h3 {
  margin: 0;
  font-size: 18px;
  font-weight: 700;
  color: #0f172a;
}

.close-btn {
  background: white;
  border: 1px solid #e2e8f0;
  width: 32px;
  height: 32px;
  border-radius: 8px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 20px;
  cursor: pointer;
  color: #64748b;
  transition: all 0.2s;
}

.close-btn:hover {
  background: #f1f5f9;
  color: #0f172a;
  border-color: #cbd5e1;
}

.modal-body {
  padding: 24px;
  overflow-y: auto;
  background: white;
}

.modal-body pre {
  background: #1e293b;
  color: #e2e8f0;
  padding: 16px 20px;
  border-radius: 12px;
  font-size: 13px;
  font-family: 'SFMono-Regular', Consolas, 'Liberation Mono', Menlo, monospace;
  white-space: pre-wrap;
  word-break: break-all;
  margin: 0;
  box-shadow: inset 0 2px 4px rgba(0, 0, 0, 0.1);
  overflow-x: auto;
}
</style>
