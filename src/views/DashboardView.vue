<script setup>
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import apiClient from '../api/axios'
import DashboardCharts from '../components/DashboardCharts.vue'

const router = useRouter()
const stats = ref(null)
const isLoading = ref(true)
const errorMessage = ref('')

const fetchDashboardData = async () => {
  try {
    isLoading.value = true
    const response = await apiClient.get('/dashboard')
    stats.value = response.data.stats
  } catch (error) {
    errorMessage.value = error.response?.data?.error?.message || 'Failed to fetch dashboard data.'
    console.error('Failed to fetch dashboard:', error)
  } finally {
    isLoading.value = false
  }
}

const navigateTo = (path) => {
  router.push(path)
}

onMounted(() => {
  fetchDashboardData()
})
</script>

<template>
  <div class="dashboard-overview">
    <h2>ภาพรวมระบบ</h2>

    <div v-if="isLoading" class="loading-message">กำลังโหลด...</div>
    <div v-else-if="errorMessage" class="error-message">{{ errorMessage }}</div>
    <div v-else class="stats-grid">
      <div class="stat-card" @click="navigateTo('/vehicles')">
        <div class="stat-icon vehicles">
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
              d="M8.25 18.75a1.5 1.5 0 0 1-3 0m3 0a1.5 1.5 0 0 0-3 0m3 0h6m-9 0H3.375a1.125 1.125 0 0 1-1.125-1.125V14.25m17.25 4.5a1.5 1.5 0 0 1-3 0m3 0a1.5 1.5 0 0 0-3 0m3 0h1.125c.621 0 1.129-.504 1.09-1.124a17.902 17.902 0 0 0-3.213-9.193 2.056 2.056 0 0 0-1.58-.86H14.25M16.5 18.75h-2.25m0-11.177v-.958c0-.568-.422-1.048-.987-1.106a48.554 48.554 0 0 0-10.026 0 1.106 1.106 0 0 0-.987 1.106v7.635m12-6.677v6.677m0 4.5v-4.5m0 0h-12"
            />
          </svg>
        </div>
        <div class="stat-content">
          <h3>ยานพาหนะทั้งหมด</h3>
          <p class="stat-value">{{ stats.total_vehicles || 0 }}</p>
        </div>
        <div class="card-arrow">
          <svg
            xmlns="http://www.w3.org/2000/svg"
            fill="none"
            viewBox="0 0 24 24"
            stroke-width="1.5"
            stroke="currentColor"
          >
            <path stroke-linecap="round" stroke-linejoin="round" d="m8.25 4.5 7.5 7.5-7.5 7.5" />
          </svg>
        </div>
      </div>

      <div class="stat-card" @click="navigateTo('/trips')">
        <div class="stat-icon trips">
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
              d="M9 6.75V15m6-6v8.25m.503 3.498 4.875-2.437c.381-.19.622-.58.622-1.006V4.82c0-.836-.88-1.38-1.628-1.006l-3.869 1.934c-.317.159-.69.159-1.006 0L9.503 3.252a1.125 1.125 0 0 0-1.006 0L3.622 5.689C3.24 5.88 3 6.27 3 6.695V19.18c0 .836.88 1.38 1.628 1.006l3.869-1.934c.317-.159.69-.159 1.006 0l4.994 2.497c.317.158.69.158 1.006 0Z"
            />
          </svg>
        </div>
        <div class="stat-content">
          <h3>การเดินทางวันนี้</h3>
          <p class="stat-value">{{ stats.active_trips_count || 0 }}</p>
        </div>
        <div class="card-arrow">
          <svg
            xmlns="http://www.w3.org/2000/svg"
            fill="none"
            viewBox="0 0 24 24"
            stroke-width="1.5"
            stroke="currentColor"
          >
            <path stroke-linecap="round" stroke-linejoin="round" d="m8.25 4.5 7.5 7.5-7.5 7.5" />
          </svg>
        </div>
      </div>

      <div class="stat-card" @click="navigateTo('/trips')">
        <div class="stat-icon distance">
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
              d="M3.75 3v11.25A2.25 2.25 0 0 1 6 16.5h2.25M3.75 3h-1.5m1.5 0h16.5m0 0h1.5m-1.5 0v11.25A2.25 2.25 0 0 1 18 16.5h-2.25m-7.5 0h7.5m-7.5 0-1 3m8.5-3 1 3m0 0 .5 1.5m-.5-1.5h-9.5m0 0-.5 1.5M9 11.25v1.5M12 9v3.75m3-6v6"
            />
          </svg>
        </div>
        <div class="stat-content">
          <h3>ระยะทางวันนี้</h3>
          <p class="stat-value">
            {{ stats.total_distance_today || 0 }} <span class="unit">กม.</span>
          </p>
        </div>
        <div class="card-arrow">
          <svg
            xmlns="http://www.w3.org/2000/svg"
            fill="none"
            viewBox="0 0 24 24"
            stroke-width="1.5"
            stroke="currentColor"
          >
            <path stroke-linecap="round" stroke-linejoin="round" d="m8.25 4.5 7.5 7.5-7.5 7.5" />
          </svg>
        </div>
      </div>

      <div class="stat-card" @click="navigateTo('/maintenance')">
        <div class="stat-icon maintenance">
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
              d="M11.42 15.17 17.25 21A2.652 2.652 0 0 0 21 17.25l-5.877-5.877M11.42 15.17l2.496-3.03c.317-.384.74-.626 1.208-.766M11.42 15.17l-4.655 5.653a2.548 2.548 0 1 1-3.586-3.586l6.837-5.63m5.108-.233c.55-.164 1.163-.188 1.743-.14a4.5 4.5 0 0 0 4.486-6.336l-3.276 3.277a3.004 3.004 0 0 1-2.25-2.25l3.276-3.276a4.5 4.5 0 0 0-6.336 4.486c.091 1.076-.071 2.264-.904 2.95l-.102.085m-1.745 1.437L5.909 7.5H4.5L2.25 3.75l1.5-1.5L7.5 4.5v1.409l4.26 4.26m-1.745 1.437 1.745-1.437m6.615 8.206L15.75 15.75M4.867 19.125h.008v.008h-.008v-.008Z"
            />
          </svg>
        </div>
        <div class="stat-content">
          <h3>รอบำรุงรักษา</h3>
          <p class="stat-value text-danger">{{ stats.overdue_maintenance_count || 0 }}</p>
        </div>
        <div class="card-arrow">
          <svg
            xmlns="http://www.w3.org/2000/svg"
            fill="none"
            viewBox="0 0 24 24"
            stroke-width="1.5"
            stroke="currentColor"
          >
            <path stroke-linecap="round" stroke-linejoin="round" d="m8.25 4.5 7.5 7.5-7.5 7.5" />
          </svg>
        </div>
      </div>
    </div>

    <DashboardCharts />
  </div>
</template>

<style scoped>
.dashboard-overview {
  padding: 1rem 0;
}

h2 {
  margin-bottom: 2rem;
  color: #1f2937;
  font-size: 24px;
  font-weight: 600;
}

.stats-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(260px, 1fr));
  gap: 1.5rem;
}

.stat-card {
  display: flex;
  align-items: center;
  gap: 16px;
  background-color: #ffffff;
  padding: 20px;
  border-radius: 12px;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.08);
  cursor: pointer;
  transition: all 0.2s ease;
}

.stat-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.12);
}

.stat-icon {
  flex-shrink: 0;
  width: 52px;
  height: 52px;
  border-radius: 12px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.stat-icon svg {
  width: 28px;
  height: 28px;
}

.stat-icon.vehicles {
  background: #e0e7ff;
  color: #4f46e5;
}

.stat-icon.trips {
  background: #d1fae5;
  color: #059669;
}

.stat-icon.distance {
  background: #fef3c7;
  color: #d97706;
}

.stat-icon.maintenance {
  background: #fee2e2;
  color: #dc2626;
}

.stat-content {
  flex: 1;
}

.stat-content h3 {
  margin: 0 0 4px 0;
  color: #6b7280;
  font-size: 14px;
  font-weight: 500;
}

.stat-value {
  margin: 0;
  font-size: 28px;
  font-weight: 700;
  color: #1f2937;
  line-height: 1.2;
}

.stat-value .unit {
  font-size: 16px;
  font-weight: 500;
  color: #6b7280;
}

.text-danger {
  color: #dc2626 !important;
}

.card-arrow {
  color: #9ca3af;
  flex-shrink: 0;
}

.card-arrow svg {
  width: 20px;
  height: 20px;
}

.loading-message,
.error-message {
  text-align: center;
  padding: 2rem;
  background: white;
  border-radius: 8px;
}

.error-message {
  color: #e53e3e;
}
</style>
