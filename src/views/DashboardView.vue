<script setup>
import { ref, onMounted } from 'vue'
import apiClient from '../api/axios'

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

onMounted(() => {
  fetchDashboardData()
})
</script>

<template>
  <div class="dashboard-overview">
    <h2>Dashboard Overview</h2>

    <div v-if="isLoading" class="loading-message">Loading stats...</div>
    <div v-else-if="errorMessage" class="error-message">{{ errorMessage }}</div>
    <div v-else class="stats-grid">
      <div class="stat-card">
        <h3>Total Vehicles</h3>
        <p class="stat-value">{{ stats.total_vehicles || 0 }}</p>
      </div>
      <div class="stat-card">
        <h3>Active Vehicles</h3>
        <p class="stat-value text-success">{{ stats.active_vehicles || 0 }}</p>
      </div>
      <div class="stat-card">
        <h3>In Maintenance</h3>
        <p class="stat-value text-warning">{{ stats.maintenance_vehicles || 0 }}</p>
      </div>
    </div>
  </div>
</template>

<style scoped>
.dashboard-overview {
  padding: 1rem 0;
}

h2 {
  margin-bottom: 2rem;
  color: #2d3748;
}

.stats-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
  gap: 2rem;
}

.stat-card {
  background-color: #ffffff;
  padding: 2rem;
  border-radius: 8px;
  box-shadow: 0 4px 6px rgba(0, 0, 0, 0.05);
  text-align: center;
}

.stat-card h3 {
  margin: 0 0 1rem 0;
  color: #718096;
  font-size: 1.1rem;
  font-weight: 500;
}

.stat-value {
  margin: 0;
  font-size: 3rem;
  font-weight: 700;
  color: #2d3748;
}

.text-success {
  color: #38a169;
}
.text-warning {
  color: #d69e2e;
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
