<template>
  <div class="charts-container">
    <h2>รายงานและสถิติ</h2>

    <div class="charts-grid">
      <!-- Vehicles by Status (Donut Chart) -->
      <div class="chart-card">
        <h3>สถานะยานพาหนะ</h3>
        <div class="chart-wrapper">
          <Doughnut v-if="!loading" :data="vehicleChartData" :options="donutOptions" />
          <div v-else class="chart-loading">
            <div class="spinner"></div>
          </div>
        </div>
      </div>

      <!-- Trip Distance Trend (Bar Chart) -->
      <div class="chart-card">
        <h3>ระยะทางการเดินทาง (7 วันล่าสุด)</h3>
        <div class="chart-wrapper">
          <Bar v-if="!loading" :data="tripChartData" :options="barOptions" />
          <div v-else class="chart-loading">
            <div class="spinner"></div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import {
  Chart as ChartJS,
  ArcElement,
  CategoryScale,
  LinearScale,
  BarElement,
  Title,
  Tooltip,
  Legend,
} from 'chart.js'
import { Doughnut, Bar } from 'vue-chartjs'
import { chartsApi } from '../api/charts'

ChartJS.register(ArcElement, CategoryScale, LinearScale, BarElement, Title, Tooltip, Legend)

const loading = ref(true)
const vehiclesByStatus = ref({})
const tripDistanceTrend = ref([])

const statusLabels = {
  ACTIVE: 'ใช้งาน',
  IDLE: 'ว่าง',
  MAINTENANCE: 'ซ่อมบำรุง',
  RETIRED: 'เลิกใช้งาน',
}

const statusColors = {
  ACTIVE: '#22c55e',
  IDLE: '#3b82f6',
  MAINTENANCE: '#f59e0b',
  RETIRED: '#6b7280',
}

const vehicleChartData = ref({
  labels: [],
  datasets: [],
})

const tripChartData = ref({
  labels: [],
  datasets: [],
})

const donutOptions = {
  responsive: true,
  maintainAspectRatio: false,
  plugins: {
    legend: {
      position: 'bottom',
      labels: {
        padding: 20,
        usePointStyle: true,
        font: {
          size: 12,
        },
      },
    },
    tooltip: {
      callbacks: {
        label: (context) => {
          const label = context.label || ''
          const value = context.raw || 0
          const total = context.dataset.data.reduce((a, b) => a + b, 0)
          const percentage = total > 0 ? ((value / total) * 100).toFixed(1) : 0
          return `${label}: ${value} คัน (${percentage}%)`
        },
      },
    },
  },
}

const barOptions = {
  responsive: true,
  maintainAspectRatio: false,
  plugins: {
    legend: {
      display: false,
    },
    tooltip: {
      callbacks: {
        label: (context) => {
          return `ระยะทาง: ${context.raw} กม.`
        },
      },
    },
  },
  scales: {
    y: {
      beginAtZero: true,
      ticks: {
        callback: (value) => value + ' กม.',
      },
    },
  },
}

const formatDateThai = (dateStr) => {
  const date = new Date(dateStr)
  return date.toLocaleDateString('th-TH', { day: 'numeric', month: 'short' })
}

const fetchChartData = async () => {
  try {
    loading.value = true
    const [vehicleRes, tripRes] = await Promise.all([
      chartsApi.getVehiclesByStatus(),
      chartsApi.getTripDistanceTrend(),
    ])

    vehiclesByStatus.value = vehicleRes.data
    tripDistanceTrend.value = tripRes.data

    const vehicleLabels = Object.keys(vehiclesByStatus.value).filter(
      (key) => vehiclesByStatus.value[key] > 0,
    )

    vehicleChartData.value = {
      labels: vehicleLabels.map((key) => statusLabels[key] || key),
      datasets: [
        {
          data: vehicleLabels.map((key) => vehiclesByStatus.value[key]),
          backgroundColor: vehicleLabels.map((key) => statusColors[key] || '#6b7280'),
          borderWidth: 0,
        },
      ],
    }

    tripChartData.value = {
      labels: tripDistanceTrend.value.map((item) => formatDateThai(item.date)),
      datasets: [
        {
          label: 'ระยะทาง (กม.)',
          data: tripDistanceTrend.value.map((item) => item.distance),
          backgroundColor: '#3b82f6',
          borderRadius: 6,
        },
      ],
    }
  } catch (error) {
    console.error('Failed to fetch chart data:', error)
  } finally {
    loading.value = false
  }
}

onMounted(() => {
  fetchChartData()
})
</script>

<style scoped>
.charts-container {
  margin-top: 32px;
}

h2 {
  margin-bottom: 20px;
  color: #1f2937;
  font-size: 20px;
  font-weight: 600;
}

.charts-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(400px, 1fr));
  gap: 24px;
}

.chart-card {
  background: white;
  border-radius: 12px;
  padding: 24px;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.08);
}

.chart-card h3 {
  margin: 0 0 20px 0;
  color: #374151;
  font-size: 16px;
  font-weight: 600;
}

.chart-wrapper {
  height: 280px;
  position: relative;
}

.chart-loading {
  display: flex;
  align-items: center;
  justify-content: center;
  height: 100%;
}

.spinner {
  width: 32px;
  height: 32px;
  border: 3px solid #e5e7eb;
  border-top-color: #3b82f6;
  border-radius: 50%;
  animation: spin 0.8s linear infinite;
}

@keyframes spin {
  from {
    transform: rotate(0deg);
  }
  to {
    transform: rotate(360deg);
  }
}

@media (max-width: 900px) {
  .charts-grid {
    grid-template-columns: 1fr;
  }
}
</style>
