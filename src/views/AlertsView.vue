<template>
  <div class="alerts-container">
    <h1>การแจ้งเตือน</h1>

    <div class="filters">
      <select v-model="filters.severity" @change="fetchAlerts">
        <option value="">ทุกระดับความรุนแรง</option>
        <option value="WARNING">คำเตือน</option>
        <option value="CRITICAL">วิกฤต</option>
      </select>

      <select v-model="filters.resource_type" @change="fetchAlerts">
        <option value="">ทุกประเภท</option>
        <option value="VEHICLE">ยานพาหนะ</option>
        <option value="MAINTENANCE">การบำรุงรักษา</option>
        <option value="DRIVER">คนขับ</option>
        <option value="TRIP">การเดินทาง</option>
      </select>
    </div>

    <div v-if="loading" class="loading">กำลังโหลด...</div>

    <div v-else-if="alerts.length === 0" class="no-data">ไม่มีการแจ้งเตือน</div>

    <div v-else class="alerts-list">
      <div
        v-for="alert in alerts"
        :key="alert.id"
        :class="['alert-card', alert.severity.toLowerCase()]"
      >
        <div class="alert-header">
          <span :class="['severity-badge', alert.severity.toLowerCase()]">
            {{ getSeverityLabel(alert.severity) }}
          </span>
          <span class="resource-type">{{
            getResourceTypeLabel(alert.affected_resource_type)
          }}</span>
        </div>
        <div class="alert-message">{{ alert.message }}</div>
        <div class="alert-time">
          {{ formatDate(alert.created_at) }}
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, watch } from 'vue'
import { alertsApi } from '../api/alerts'

const alerts = ref([])
const loading = ref(false)
const filters = ref({
  severity: '',
  resource_type: '',
})

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

const getSeverityLabel = (severity) => {
  return severityLabels[severity] || severity
}

const getResourceTypeLabel = (type) => {
  return resourceTypeLabels[type] || type
}

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
  padding: 20px;
}

h1 {
  margin-bottom: 20px;
}

.filters {
  display: flex;
  gap: 10px;
  margin-bottom: 20px;
}

.filters select {
  padding: 8px 12px;
  border: 1px solid #ddd;
  border-radius: 4px;
  font-size: 14px;
}

.loading,
.no-data {
  text-align: center;
  padding: 40px;
  color: #666;
}

.alerts-list {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.alert-card {
  padding: 16px;
  border-radius: 8px;
  border-left: 4px solid;
}

.alert-card.warning {
  background-color: #fff8e1;
  border-left-color: #ff9800;
}

.alert-card.critical {
  background-color: #ffebee;
  border-left-color: #f44336;
}

.alert-header {
  display: flex;
  align-items: center;
  gap: 10px;
  margin-bottom: 8px;
}

.severity-badge {
  padding: 4px 8px;
  border-radius: 4px;
  font-size: 12px;
  font-weight: bold;
}

.severity-badge.warning {
  background-color: #ff9800;
  color: white;
}

.severity-badge.critical {
  background-color: #f44336;
  color: white;
}

.resource-type {
  font-size: 12px;
  color: #666;
}

.alert-message {
  margin-bottom: 8px;
  color: #333;
}

.alert-time {
  font-size: 12px;
  color: #999;
}
</style>
