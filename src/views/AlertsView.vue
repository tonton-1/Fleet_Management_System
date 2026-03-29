<template>
  <div class="alerts-container">
    <div class="header">
      <h1>การแจ้งเตือน</h1>
      <div class="alert-count" v-if="alerts.length > 0">
        <span class="count-badge critical" v-if="criticalCount > 0">{{ criticalCount }}</span>
        <span class="count-badge warning" v-if="warningCount > 0">{{ warningCount }}</span>
      </div>
    </div>

    <div class="filters">
      <div class="filter-group">
        <label>ระดับความรุนแรง</label>
        <select v-model="filters.severity" @change="fetchAlerts">
          <option value="">ทั้งหมด</option>
          <option value="WARNING">คำเตือน</option>
          <option value="CRITICAL">วิกฤต</option>
        </select>
      </div>

      <div class="filter-group">
        <label>ประเภท</label>
        <select v-model="filters.resource_type" @change="fetchAlerts">
          <option value="">ทั้งหมด</option>
          <option value="VEHICLE">ยานพาหนะ</option>
          <option value="MAINTENANCE">การบำรุงรักษา</option>
          <option value="DRIVER">คนขับ</option>
          <option value="TRIP">การเดินทาง</option>
        </select>
      </div>

      <button class="refresh-btn" @click="fetchAlerts" :disabled="loading">
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
      <span>กำลังโหลด...</span>
    </div>

    <div v-else-if="alerts.length === 0" class="no-data">
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
      <span>ไม่มีการแจ้งเตือน</span>
    </div>

    <div v-else class="alerts-list">
      <div
        v-for="alert in alerts"
        :key="alert.id"
        :class="['alert-card', alert.severity.toLowerCase()]"
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
          <div class="alert-header">
            <span :class="['severity-badge', alert.severity.toLowerCase()]">
              {{ getSeverityLabel(alert.severity) }}
            </span>
            <span class="resource-type">
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
                  d="M6.75 7.5l3 2.25-3 2.25m4.5 0h3m-9 8.25h13.5A2.25 2.25 0 0 0 21 18V6a2.25 2.25 0 0 0-2.25-2.25H5.25A2.25 2.25 0 0 0 3 6v12a2.25 2.25 0 0 0 2.25 2.25Z"
                />
              </svg>
              {{ getResourceTypeLabel(alert.affected_resource_type) }}
            </span>
          </div>
          <div class="alert-message">{{ alert.message }}</div>
          <div class="alert-time">
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
                d="M12 6v6h4.5m4.5 0a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z"
              />
            </svg>
            {{ formatDate(alert.created_at) }}
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { alertsApi } from '../api/alerts'

const alerts = ref([])
const loading = ref(false)
const filters = ref({
  severity: '',
  resource_type: '',
})

const criticalCount = computed(() => alerts.value.filter((a) => a.severity === 'CRITICAL').length)
const warningCount = computed(() => alerts.value.filter((a) => a.severity === 'WARNING').length)

const severityLabels = {
  WARNING: 'คำเตือน',
  CRITICAL: 'วิกฤต',
}

const resourceTypeLabels = {
  VEHICLE: 'ยานพาหนะ',
  MAINTENANCE: 'การบำรุงรักษา',
  DRIVER: 'คนขับ',
  TRIP: 'การเดินทาง',
}

const getSeverityLabel = (severity) => severityLabels[severity] || severity
const getResourceTypeLabel = (type) => resourceTypeLabels[type] || type

const fetchAlerts = async () => {
  loading.value = true
  try {
    const params = {}
    if (filters.value.severity) params.severity = filters.value.severity
    if (filters.value.resource_type) params.resource_type = filters.value.resource_type

    const response = await alertsApi.getAlerts(params)
    alerts.value = response.data
  } catch (error) {
    console.error('Failed to fetch alerts:', error)
  } finally {
    loading.value = false
  }
}

const formatDate = (dateString) => {
  const date = new Date(dateString)
  return date.toLocaleString('th-TH', {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  })
}

onMounted(() => {
  fetchAlerts()
})
</script>

<style scoped>
.alerts-container {
  padding: 24px;
  max-width: 900px;
  margin: 0 auto;
}

.header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 24px;
}

h1 {
  font-size: 24px;
  font-weight: 600;
  color: #1f2937;
  margin: 0;
}

.alert-count {
  display: flex;
  gap: 8px;
}

.count-badge {
  padding: 4px 12px;
  border-radius: 20px;
  font-size: 14px;
  font-weight: 600;
}

.count-badge.critical {
  background-color: #fef2f2;
  color: #dc2626;
}

.count-badge.warning {
  background-color: #fffbeb;
  color: #d97706;
}

.filters {
  display: flex;
  gap: 16px;
  align-items: flex-end;
  margin-bottom: 24px;
  padding: 16px;
  background: #f9fafb;
  border-radius: 12px;
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

.filters select {
  padding: 10px 14px;
  border: 1px solid #e5e7eb;
  border-radius: 8px;
  font-size: 14px;
  background: white;
  min-width: 160px;
  cursor: pointer;
}

.filters select:focus {
  outline: none;
  border-color: #3b82f6;
  box-shadow: 0 0 0 3px rgba(59, 130, 246, 0.1);
}

.refresh-btn {
  display: flex;
  align-items: center;
  gap: 6px;
  padding: 10px 16px;
  background: #3b82f6;
  color: white;
  border: none;
  border-radius: 8px;
  font-size: 14px;
  font-weight: 500;
  cursor: pointer;
  margin-left: auto;
  transition: background 0.2s;
}

.refresh-btn:hover:not(:disabled) {
  background: #2563eb;
}

.refresh-btn:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.refresh-btn svg {
  width: 18px;
  height: 18px;
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
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 60px;
  color: #6b7280;
}

.spinner {
  width: 40px;
  height: 40px;
  border: 3px solid #e5e7eb;
  border-top-color: #3b82f6;
  border-radius: 50%;
  animation: spin 0.8s linear infinite;
  margin-bottom: 12px;
}

.no-data {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 60px;
  color: #9ca3af;
}

.no-data svg {
  width: 64px;
  height: 64px;
  margin-bottom: 12px;
  color: #d1d5db;
}

.alerts-list {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.alert-card {
  display: flex;
  gap: 16px;
  padding: 20px;
  background: white;
  border-radius: 12px;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.08);
  border-left: 4px solid;
  transition:
    transform 0.2s,
    box-shadow 0.2s;
}

.alert-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
}

.alert-card.warning {
  border-left-color: #f59e0b;
}

.alert-card.critical {
  border-left-color: #ef4444;
}

.alert-icon {
  flex-shrink: 0;
  width: 44px;
  height: 44px;
  border-radius: 10px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.alert-card.warning .alert-icon {
  background: #fef3c7;
  color: #d97706;
}

.alert-card.critical .alert-icon {
  background: #fee2e2;
  color: #dc2626;
}

.alert-icon svg {
  width: 24px;
  height: 24px;
}

.alert-content {
  flex: 1;
  min-width: 0;
}

.alert-header {
  display: flex;
  align-items: center;
  gap: 10px;
  margin-bottom: 8px;
  flex-wrap: wrap;
}

.severity-badge {
  padding: 4px 10px;
  border-radius: 6px;
  font-size: 12px;
  font-weight: 600;
}

.severity-badge.warning {
  background: #fef3c7;
  color: #b45309;
}

.severity-badge.critical {
  background: #fee2e2;
  color: #b91c1c;
}

.resource-type {
  display: flex;
  align-items: center;
  gap: 4px;
  font-size: 12px;
  color: #6b7280;
  background: #f3f4f6;
  padding: 4px 8px;
  border-radius: 4px;
}

.resource-type svg {
  width: 14px;
  height: 14px;
}

.alert-message {
  color: #374151;
  font-size: 14px;
  line-height: 1.5;
  margin-bottom: 10px;
}

.alert-time {
  display: flex;
  align-items: center;
  gap: 4px;
  font-size: 12px;
  color: #9ca3af;
}

.alert-time svg {
  width: 14px;
  height: 14px;
}
</style>
