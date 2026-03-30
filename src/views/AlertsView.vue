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
        <div class="custom-dropdown severity-filter">
          <div class="dropdown-trigger" @click="isSeverityOpen = !isSeverityOpen">
            <span v-if="currentSeverityOption.value !== ''" :class="['dot-indicator', currentSeverityOption.colorClass]"></span>
            <span>{{ currentSeverityOption.label }}</span>
            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2" class="chevron" :class="{ 'chevron-up': isSeverityOpen }">
              <path stroke-linecap="round" stroke-linejoin="round" d="M19 9l-7 7-7-7" />
            </svg>
          </div>
          <Transition name="fade-slide">
            <div v-if="isSeverityOpen" class="dropdown-menu">
              <div 
                v-for="opt in severityOptions" 
                :key="opt.value" 
                class="dropdown-item"
                :class="{ 'active': filters.severity === opt.value }"
                @click="selectSeverity(opt.value)"
              >
                <span v-if="opt.value !== ''" :class="['dot-indicator', opt.colorClass]"></span>
                <span v-else class="dot-indicator empty-dot"></span>
                {{ opt.label }}
                <!-- Checkmark -->
                <svg v-if="filters.severity === opt.value" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2" class="check-icon">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M5 13l4 4L19 7" />
                </svg>
              </div>
            </div>
          </Transition>
        </div>
      </div>

      <div class="filter-group">
        <label>ประเภท</label>
        <div class="custom-dropdown resource-filter">
          <div class="dropdown-trigger" @click="isResourceOpen = !isResourceOpen">
            <span v-if="currentResourceOption.value !== ''" :class="['dot-indicator', currentResourceOption.colorClass]"></span>
            <span>{{ currentResourceOption.label }}</span>
            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2" class="chevron" :class="{ 'chevron-up': isResourceOpen }">
              <path stroke-linecap="round" stroke-linejoin="round" d="M19 9l-7 7-7-7" />
            </svg>
          </div>
          <Transition name="fade-slide">
            <div v-if="isResourceOpen" class="dropdown-menu">
              <div 
                v-for="opt in resourceOptions" 
                :key="opt.value" 
                class="dropdown-item"
                :class="{ 'active': filters.resource_type === opt.value }"
                @click="selectResource(opt.value)"
              >
                <span v-if="opt.value !== ''" :class="['dot-indicator', opt.colorClass]"></span>
                <span v-else class="dot-indicator empty-dot"></span>
                {{ opt.label }}
                <!-- Checkmark -->
                <svg v-if="filters.resource_type === opt.value" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2" class="check-icon">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M5 13l4 4L19 7" />
                </svg>
              </div>
            </div>
          </Transition>
        </div>
      </div>

      <button class="refresh-btn" @click="fetchAlerts" :disabled="loading">
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

    <div v-if="loading" class="loading">
      <div class="spinner"></div>
      <span>กำลังโหลด...</span>
    </div>

    <div v-else-if="alerts.length === 0" class="no-data">
      <div class="no-data-icon-wrapper">
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
      </div>
      <h3>ไม่มีการแจ้งเตือน</h3>
      <p>ระบบทำงานเป็นปกติ ไม่มีรายการที่ต้องตรวจสอบ</p>
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
          <div class="alert-header">
            <span :class="['severity-badge', alert.severity.toLowerCase()]">
              {{ getSeverityLabel(alert.severity) }}
            </span>
            <span class="resource-type">
              <!-- ยานพาหนะ (Vehicle) -->
              <svg
                v-if="alert.affected_resource_type === 'VEHICLE'"
                xmlns="http://www.w3.org/2000/svg"
                fill="none"
                viewBox="0 0 24 24"
                stroke-width="1.5"
                stroke="currentColor"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  d="M8.25 18.75a1.5 1.5 0 0 1-3 0m3 0a1.5 1.5 0 0 0-3 0m3 0h6m-9 0H3.375a1.125 1.125 0 0 1-1.125-1.125V14.25m17.25 4.5a1.5 1.5 0 0 1-3 0m3 0a1.5 1.5 0 0 0-3 0m3 0h1.125c.621 0 1.129-.504 1.09-1.124a17.902 17.902 0 0 0-3.213-9.193 2.056 2.056 0 0 0-1.58-.86H14.25M16.5 18.75h-2.25m0-11.177v-.958c0-.568-.422-1.048-.987-1.106a48.554 48.554 0 0 0-10.026 0 1.106 1.106 0 0 0-.987 1.106v7.635m12-6.677v6.677m0 4.5v-4.5m0 0h-12"
                />
              </svg>
              <!-- การบำรุงรักษา (Maintenance) -->
              <svg
                v-else-if="alert.affected_resource_type === 'MAINTENANCE'"
                xmlns="http://www.w3.org/2000/svg"
                fill="none"
                viewBox="0 0 24 24"
                stroke-width="1.5"
                stroke="currentColor"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  d="M11.42 15.17L17.25 21A2.652 2.652 0 0021 17.25l-5.877-5.877M11.42 15.17l2.496-3.03c.317-.384.74-.626 1.208-.766M11.42 15.17l-4.655 5.653a2.548 2.548 0 11-3.586-3.586l6.837-5.63m5.108-.233c.55-.164 1.163-.188 1.743-.14a4.5 4.5 0 004.486-6.336l-3.276 3.277a3.004 3.004 0 01-2.25-2.25l3.276-3.276a4.5 4.5 0 00-6.336 4.486c.091 1.076-.071 2.264-.904 2.95l-.102.085m-1.745 1.437L5.909 7.5H4.5L2.25 3.75l1.5-1.5L7.5 4.5v1.409l4.26 4.26m-1.745 1.437l1.745-1.437m6.615 8.206L15.75 15.75M4.867 19.125h.008v.008h-.008v-.008z"
                />
              </svg>
              <!-- คนขับ (Driver) -->
              <svg
                v-else-if="alert.affected_resource_type === 'DRIVER'"
                xmlns="http://www.w3.org/2000/svg"
                fill="none"
                viewBox="0 0 24 24"
                stroke-width="1.5"
                stroke="currentColor"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  d="M15 9h3.75M15 12h3.75M15 15h3.75M4.5 19.5h15a2.25 2.25 0 002.25-2.25V6.75A2.25 2.25 0 0019.5 4.5h-15a2.25 2.25 0 00-2.25 2.25v10.5A2.25 2.25 0 004.5 19.5zm6-10.125a1.875 1.875 0 11-3.75 0 1.875 1.875 0 013.75 0zm1.294 6.336a6.721 6.721 0 01-3.17.789 6.721 6.721 0 01-3.168-.789 3.376 3.376 0 016.338 0z"
                />
              </svg>
              <!-- การเดินทาง (Trip) -->
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
                  d="M9 6.75V15m6-6v8.25m.503 3.498l4.875-2.437c.381-.19.622-.58.622-1.006V4.82c0-.836-.88-1.38-1.628-1.006l-3.869 1.934c-.317.159-.69.159-1.006 0L9.503 3.252a1.125 1.125 0 00-1.006 0L3.622 5.689C3.24 5.88 3 6.27 3 6.695V19.18c0 .836.88 1.38 1.628 1.006l3.869-1.934c.317-.159.69-.159 1.006 0l4.994 2.497c.317.158.69.158 1.006 0z"
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
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { alertsApi } from '../api/alerts'

const alerts = ref([])
const loading = ref(false)
const filters = ref({
  severity: '',
  resource_type: '',
})

const isSeverityOpen = ref(false)
const isResourceOpen = ref(false)

const severityOptions = [
  { value: '', label: 'ทั้งหมด', colorClass: 'status-all' },
  { value: 'WARNING', label: 'คำเตือน', colorClass: 'status-warning' },
  { value: 'CRITICAL', label: 'วิกฤต', colorClass: 'status-critical' }
]

const resourceOptions = [
  { value: '', label: 'ทั้งหมด' },
  { value: 'VEHICLE', label: 'ยานพาหนะ' },
  { value: 'MAINTENANCE', label: 'การบำรุงรักษา' },
  { value: 'DRIVER', label: 'คนขับ' },
  { value: 'TRIP', label: 'การเดินทาง' }
]

const currentSeverityOption = computed(() => {
  return severityOptions.find((o) => o.value === filters.value.severity) || severityOptions[0]
})

const currentResourceOption = computed(() => {
  return resourceOptions.find((o) => o.value === filters.value.resource_type) || resourceOptions[0]
})

const selectSeverity = (val) => {
  filters.value.severity = val
  isSeverityOpen.value = false
  fetchAlerts()
}

const selectResource = (val) => {
  filters.value.resource_type = val
  isResourceOpen.value = false
  fetchAlerts()
}

const closeDropdowns = (e) => {
  if (!e.target.closest('.custom-dropdown.severity-filter')) {
    isSeverityOpen.value = false
  }
  if (!e.target.closest('.custom-dropdown.resource-filter')) {
    isResourceOpen.value = false
  }
}

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
  document.addEventListener('click', closeDropdowns)
  fetchAlerts()
})

onUnmounted(() => {
  document.removeEventListener('click', closeDropdowns)
})
</script>

<style scoped>
.alerts-container {
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
  min-width: 200px;
  padding-right: 30px;
}

.filter-group label {
  font-size: 13px;
  font-weight: 600;
  color: #475569;
}

.custom-dropdown {
  position: relative;
  width: 100%;
  user-select: none;
}

.dropdown-trigger {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  background-color: #f8fafc;
  border: 1px solid transparent;
  padding: 10px 16px;
  border-radius: 9999px;
  color: #4a5568;
  font-size: 0.85rem;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s ease;
  width: 100%;
  justify-content: space-between;
}

.dropdown-trigger:hover {
  background-color: #edf2f7;
}

.chevron {
  width: 14px;
  height: 14px;
  color: #a0aec0;
  transition: transform 0.2s ease;
  margin-left: auto;
}

.chevron-up {
  transform: rotate(180deg);
}

.dropdown-menu {
  position: absolute;
  top: calc(100% + 0.5rem);
  left: 0;
  min-width: 100%;
  background-color: white;
  border-radius: 12px;
  box-shadow: 0 10px 25px rgba(0, 0, 0, 0.1);
  border: 1px solid #e2e8f0;
  z-index: 50;
  overflow: hidden;
  padding: 0.5rem 0;
}

.dropdown-item {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  padding: 0.75rem 1.25rem;
  font-size: 0.85rem;
  font-weight: 500;
  color: #4a5568;
  cursor: pointer;
  transition: background-color 0.2s;
  position: relative;
  white-space: nowrap;
}

.dropdown-item:hover {
  background-color: #f7fafc;
}

.dropdown-item.active {
  background-color: #ebf8ff;
  color: #2b6cb0;
}

.check-icon {
  width: 16px;
  height: 16px;
  color: #3182ce;
  margin-left: auto;
}

.dot-indicator {
  width: 12px;
  height: 12px;
  border-radius: 50%;
  flex-shrink: 0;
}

.empty-dot {
  background-color: transparent;
  border: 2px solid #cbd5e0;
}

.dot-indicator.status-warning { background-color: #f59e0b; }
.dot-indicator.status-critical { background-color: #ef4444; }
.dot-indicator.status-gray { background-color: #94a3b8; }

.fade-slide-enter-active,
.fade-slide-leave-active {
  transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);
}
.fade-slide-enter-from,
.fade-slide-leave-to {
  opacity: 0;
  transform: translateY(-5px);
}

.refresh-btn {
  display: flex;
  align-items: center;
  gap: 8px;
  background: linear-gradient(135deg, #3b82f6 0%, #2563eb 100%);
  color: white;
  border: none;
  padding: 12px 20px;
  border-radius: 12px;
  font-size: 15px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
  box-shadow: 0 4px 12px rgba(37, 99, 235, 0.2);
  margin-left: auto;
  align-self: flex-end;
}

.refresh-btn:hover:not(:disabled) {
  transform: translateY(-2px);
  box-shadow: 0 8px 16px rgba(37, 99, 235, 0.3);
}

.refresh-btn:active:not(:disabled) {
  transform: translateY(1px);
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
  padding: 80px 40px;
  color: #64748b;
  background: white;
  border-radius: 16px;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.03);
  border: 1px solid rgba(226, 232, 240, 0.8);
}

.no-data-icon-wrapper {
  background: #f1f5f9;
  padding: 24px;
  border-radius: 50%;
  margin-bottom: 20px;
}

.no-data svg {
  width: 48px;
  height: 48px;
  color: #94a3b8;
}

.no-data h3 {
  font-size: 1.25rem;
  color: #1e293b;
  margin: 0 0 8px 0;
}

.no-data p {
  color: #64748b;
  margin: 0;
  font-size: 0.95rem;
}

.alerts-list {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.alert-card {
  display: flex;
  gap: 20px;
  padding: 24px;
  background: white;
  border-radius: 16px;
  box-shadow: 0 4px 15px rgba(0, 0, 0, 0.03);
  border: 1px solid rgba(226, 232, 240, 0.8);
  border-left: 6px solid;
  transition:
    transform 0.2s cubic-bezier(0.4, 0, 0.2, 1),
    box-shadow 0.2s cubic-bezier(0.4, 0, 0.2, 1);
}

.alert-card:hover {
  transform: translateY(-3px) scale(1.005);
  box-shadow: 0 12px 24px -8px rgba(0, 0, 0, 0.1);
}

.alert-card.warning {
  border-left-color: #f59e0b;
}

.alert-card.critical {
  border-left-color: #ef4444;
}

.alert-icon {
  flex-shrink: 0;
  width: 52px;
  height: 52px;
  border-radius: 14px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.alert-card.warning .alert-icon {
  background: #fffbeb;
  color: #d97706;
  box-shadow: 0 4px 10px rgba(217, 119, 6, 0.15);
}

.alert-card.critical .alert-icon {
  background: #fef2f2;
  color: #dc2626;
  box-shadow: 0 4px 10px rgba(220, 38, 38, 0.15);
}

.alert-icon svg {
  width: 28px;
  height: 28px;
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
  color: #1e293b;
  font-size: 15px;
  line-height: 1.6;
  margin-bottom: 12px;
  font-weight: 500;
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
