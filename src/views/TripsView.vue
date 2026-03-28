<script setup>
import { ref, onMounted, computed } from 'vue'
import apiClient from '../api/axios'

const trips = ref([])
const availableVehicles = ref([])
const availableDrivers = ref([])
const isLoading = ref(true)
const errorMessage = ref('')
const currentUserRole = ref('')

// Modal State
const isAddModalOpen = ref(false)
const isSaving = ref(false)
const fieldErrors = ref({})

// Tracker Modal State
const isTrackerOpen = ref(false)
const selectedTrip = ref(null)

// Form Model
const newTripForm = ref({
  vehicle_id: '',
  driver_id: '',
  origin: '',
  destination: '',
  distance_km: null,
  cargo_type: 'GENERAL',
  cargo_weight_kg: null,
  checkpoints: [],
})

// คอยเช็คว่าผู้ใช้เป็น Admin หรือ Dispatcher
const decodeToken = (token) => {
  try {
    const base64Url = token.split('.')[1]
    const base64 = base64Url.replace(/-/g, '+').replace(/_/g, '/')
    return JSON.parse(
      decodeURIComponent(
        atob(base64)
          .split('')
          .map((c) => '%' + ('00' + c.charCodeAt(0).toString(16)).slice(-2))
          .join(''),
      ),
    )
  } catch (e) {
    return null
  }
}
const canManageTrips = computed(() => ['ADMIN', 'DISPATCHER'].includes(currentUserRole.value))

const fetchTrips = async () => {
  try {
    isLoading.value = true
    const response = await apiClient.get('/trips')
    console.log(response)
    trips.value = response.data
  } catch (error) {
    errorMessage.value = error.response?.data?.error?.message || 'Failed to fetch trips data.'
    console.error('Failed to fetch trips:', error)
  } finally {
    isLoading.value = false
  }
}

// โหลดตัวเลือกรถและคนขับ
const fetchOptions = async () => {
  try {
    const [vehiclesRes, driversRes] = await Promise.all([
      apiClient.get('/vehicles'),
      apiClient.get('/drivers'),
    ])
    // กรองเฉพาะรถที่ไม่ได้เสีย และคนขับที่ Active
    availableVehicles.value = vehiclesRes.data.filter((v) => ['IDLE', 'ACTIVE'].includes(v.status))
    availableDrivers.value = driversRes.data.filter((d) => d.status === 'ACTIVE')
  } catch (error) {
    console.error('Failed to fetch options:', error)
  }
}

// จัดการ Modal
const openAddModal = () => {
  newTripForm.value = {
    vehicle_id: '',
    driver_id: '',
    origin: '',
    destination: '',
    distance_km: null,
    cargo_type: 'GENERAL',
    cargo_weight_kg: null,
    checkpoints: [],
  }
  fieldErrors.value = {}
  isAddModalOpen.value = true
}
const closeAddModal = () => {
  isAddModalOpen.value = false
}

// จัดการ Checkpoints (Dynamic Array)
const addCheckpoint = () => {
  newTripForm.value.checkpoints.push({ location_name: '', purpose: 'DELIVERY', notes: '' })
}
const removeCheckpoint = (index) => {
  newTripForm.value.checkpoints.splice(index, 1)
}

// ส่งข้อมูลบันทึก
const saveNewTrip = async () => {
  try {
    isSaving.value = true
    fieldErrors.value = {}

    // ทำความสะอาดข้อมูลตัวเลข
    const payload = { ...newTripForm.value }
    if (payload.distance_km) payload.distance_km = parseFloat(payload.distance_km)
    if (payload.cargo_weight_kg) payload.cargo_weight_kg = parseFloat(payload.cargo_weight_kg)

    await apiClient.post('/trips', payload)

    closeAddModal()
    alert('Trip created successfully!')
    await fetchTrips() // รีเฟรชตาราง
  } catch (error) {
    const errorResponse = error.response?.data?.error
    if (errorResponse && errorResponse.details) {
      fieldErrors.value = errorResponse.details
    } else {
      alert(errorResponse?.message || 'Failed to create trip.')
    }
    console.error('Failed to create trip:', error)
  } finally {
    isSaving.value = false
  }
}

// ฟังก์ชันสำหรับ format วันที่และเวลาให้อ่านง่าย
const formatDateTime = (dateString) => {
  if (!dateString) return '-'

  // แก้ปัญหา Timezone: บังคับให้ JavaScript รู้ว่า String ที่ได้มาจาก DB คือเวลาไทย (UTC+7)
  // โดยการแทนที่ช่องว่างด้วย 'T' และต่อท้ายด้วย '+07:00' (ถ้ามี T อยู่แล้วก็ไม่เป็นไร)
  const safeDateString = dateString.replace(' ', 'T').endsWith('Z')
    ? dateString
    : dateString.replace(' ', 'T') + '+07:00'

  const date = new Date(safeDateString)

  // ป้องกันกรณีที่ได้ค่า Invalid Date
  if (isNaN(date.getTime())) return '-'

  return date.toLocaleString('en-GB', {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  })
}

// ==== TRIP TRACKER LOGIC ==== //
const openTracker = async (tripId) => {
  try {
    const response = await apiClient.get(`/trips/${tripId}`)
    selectedTrip.value = response.data
    isTrackerOpen.value = true
  } catch (error) {
    alert('Failed to load trip details.')
  }
}

const closeTracker = () => {
  isTrackerOpen.value = false
  selectedTrip.value = null
}

const getCheckpointStatusLabel = (status) => {
  switch (status) {
    case 'ARRIVED':
      return 'Arrived'
    case 'DEPARTED':
      return 'Departed'
    case 'SKIPPED':
      return 'Skipped'
    default:
      return 'Pending'
  }
}

// ฟังก์ชันตรวจสอบว่า Checkpoint ก่อนหน้าเสร็จสิ้นหรือยัง
// ถ้ายังไม่เสร็จ จะไม่โชว์ปุ่มให้ Checkpoint ปัจจุบัน
const isPreviousCheckpointCompleted = (index) => {
  if (index === 0) return true // จุดแรกสุดทำได้เสมอ
  const prevCp = selectedTrip.value.checkpoints[index - 1]
  return prevCp.status === 'DEPARTED' || prevCp.status === 'SKIPPED'
}

// STEP 2 & 3: Optimistic Update พร้อมจำลอง Delay และ Random Fail (30%)
const updateCheckpointStatus = async (checkpointIndex, newStatus) => {
  if (!selectedTrip.value) return

  const checkpoint = selectedTrip.value.checkpoints[checkpointIndex]

  // 1. เก็บ State เก่าไว้เผื่อกรณีเกิดข้อผิดพลาด (Rollback)
  const previousStatus = checkpoint.status
  const previousArrivedAt = checkpoint.arrived_at
  const previousDepartedAt = checkpoint.departed_at

  // 2. OPTIMISTIC UPDATE: เปลี่ยน UI ให้เห็นทันทีโดยไม่รอ API
  checkpoint.status = newStatus
  const now = new Date().toISOString()
  if (newStatus === 'ARRIVED') checkpoint.arrived_at = now
  if (newStatus === 'DEPARTED') checkpoint.departed_at = now

  try {
    // 3. SIMULATE NETWORK DELAY (300 - 800ms)
    const delay = Math.floor(Math.random() * 500) + 300
    await new Promise((resolve) => setTimeout(resolve, delay))

    // 4. SIMULATE 30% FAILURE RATE
    const isFail = Math.random() < 0.3
    if (isFail) {
      throw new Error('Network timeout! (Simulated 30% failure)')
    }

    // 5. ถ้าไม่พัง... ยิง API ของจริงไปอัปเดต Backend เงียบๆ เบื้องหลัง
    await apiClient.patch(`/checkpoints/${checkpoint.id}/status`, { status: newStatus })
  } catch (error) {
    // 6. ROLLBACK: ถ้ายิง API พัง หรือโดนสุ่มว่าพัง ให้ดึงค่าเก่าที่เก็บไว้มาทับคืน
    checkpoint.status = previousStatus
    checkpoint.arrived_at = previousArrivedAt
    checkpoint.departed_at = previousDepartedAt

    // โชว์ข้อความบอก User ชัดเจนว่าเกิดอะไรขึ้น
    alert(
      `Failed to update ${checkpoint.location_name}: ${error.message}\nPlease try clicking the button again.`,
    )
    console.error('Optimistic Update Failed, rolling back:', error)
  }
}

onMounted(() => {
  const token = localStorage.getItem('accessToken')
  if (token) {
    const decoded = decodeToken(token)
    if (decoded && decoded.role) currentUserRole.value = decoded.role
  }
  fetchTrips()
  fetchOptions()
})
</script>

<template>
  <div class="trips-page">
    <div v-if="isLoading" class="loading-message">Loading trips data...</div>
    <div v-else-if="errorMessage" class="error-message">{{ errorMessage }}</div>
    <div v-else class="table-container">
      <div class="header-actions">
        <h2>All Trips</h2>
        <!-- ปุ่ม Create Trip จะแสดงเมื่อเป็น ADMIN หรือ DISPATCHER เท่านั้น -->
        <button v-if="canManageTrips" @click="openAddModal" class="btn-add">
          <svg
            xmlns="http://www.w3.org/2000/svg"
            fill="none"
            viewBox="0 0 24 24"
            stroke-width="1.5"
            stroke="currentColor"
            class="icon-small"
          >
            <path stroke-linecap="round" stroke-linejoin="round" d="M12 4.5v15m7.5-7.5h-15" />
          </svg>
          Create Trip
        </button>
      </div>

      <div class="table-scroll-wrapper">
        <table>
          <thead>
            <tr>
              <th>ID</th>
              <th>Vehicle</th>
              <th>Driver</th>
              <th>Route</th>
              <th>Status</th>
              <th>Started At</th>
              <th>Ended At</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="trip in trips" :key="trip.id">
              <td class="trip-id" :title="trip.id">{{ trip.id.substring(0, 8) }}...</td>
              <td class="font-medium">{{ trip.vehicle_license_plate || 'Unknown' }}</td>
              <td>{{ trip.driver_name || 'Unknown' }}</td>
              <td>
                <div class="route-info">
                  <span class="origin">{{ trip.origin }}</span>
                  <svg
                    xmlns="http://www.w3.org/2000/svg"
                    fill="none"
                    viewBox="0 0 24 24"
                    stroke-width="1.5"
                    stroke="currentColor"
                    class="arrow-icon"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      d="M17.25 8.25 21 12m0 0-3.75 3.75M21 12H3"
                    />
                  </svg>
                  <span class="destination">{{ trip.destination }}</span>
                </div>
              </td>
              <td>
                <span :class="['status-badge', `status-${trip.status.toLowerCase()}`]">
                  {{ trip.status }}
                </span>
              </td>
              <td class="time-cell">{{ formatDateTime(trip.started_at) }}</td>
              <td class="time-cell">{{ formatDateTime(trip.ended_at) }}</td>
              <td class="action-cell">
                <button @click="openTracker(trip.id)" class="btn-view">Track Trip</button>
              </td>
            </tr>
            <tr v-if="trips.length === 0">
              <td colspan="8" class="text-center py-4 text-gray-500">
                No trips found. Create one to get started.
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <!-- Modal สร้าง Trip ใหม่ -->
    <div v-if="isAddModalOpen" class="modal-overlay">
      <div class="modal-content">
        <h3>Create New Trip</h3>
        <form @submit.prevent="saveNewTrip">
          <div class="form-grid">
            <div class="form-group">
              <label>Vehicle <span class="required">*</span></label>
              <select
                v-model="newTripForm.vehicle_id"
                :class="{ 'has-error': fieldErrors.vehicle_id }"
              >
                <option value="">-- Select Available Vehicle --</option>
                <option v-for="v in availableVehicles" :key="v.id" :value="v.id">
                  {{ v.license_plate }} ({{ v.type }})
                </option>
              </select>
              <span v-if="fieldErrors.vehicle_id" class="error-text">{{
                fieldErrors.vehicle_id
              }}</span>
            </div>

            <div class="form-group">
              <label>Driver <span class="required">*</span></label>
              <select
                v-model="newTripForm.driver_id"
                :class="{ 'has-error': fieldErrors.driver_id }"
              >
                <option value="">-- Select Available Driver --</option>
                <option v-for="d in availableDrivers" :key="d.id" :value="d.id">
                  {{ d.name }}
                </option>
              </select>
              <span v-if="fieldErrors.driver_id" class="error-text">{{
                fieldErrors.driver_id
              }}</span>
            </div>
          </div>

          <div class="form-grid">
            <div class="form-group">
              <label>Origin <span class="required">*</span></label>
              <input
                type="text"
                v-model="newTripForm.origin"
                placeholder="e.g. Warehouse A"
                :class="{ 'has-error': fieldErrors.origin }"
              />
              <span v-if="fieldErrors.origin" class="error-text">{{ fieldErrors.origin }}</span>
            </div>
            <div class="form-group">
              <label>Destination <span class="required">*</span></label>
              <input
                type="text"
                v-model="newTripForm.destination"
                placeholder="e.g. Store B"
                :class="{ 'has-error': fieldErrors.destination }"
              />
              <span v-if="fieldErrors.destination" class="error-text">{{
                fieldErrors.destination
              }}</span>
            </div>
          </div>

          <div class="form-grid">
            <div class="form-group">
              <label>Cargo Type</label>
              <select
                v-model="newTripForm.cargo_type"
                :class="{ 'has-error': fieldErrors.cargo_type }"
              >
                <option value="GENERAL">GENERAL</option>
                <option value="FRAGILE">FRAGILE</option>
                <option value="HAZARDOUS">HAZARDOUS</option>
                <option value="REFRIGERATED">REFRIGERATED</option>
              </select>
            </div>
            <div class="form-group">
              <label>Distance (km)</label>
              <input
                type="number"
                step="0.01"
                v-model="newTripForm.distance_km"
                placeholder="e.g. 150.5"
              />
            </div>
          </div>

          <!-- Checkpoints Section -->
          <div class="checkpoints-section">
            <div class="checkpoints-header">
              <h4>Route Checkpoints</h4>
              <button type="button" @click="addCheckpoint" class="btn-sm">+ Add Stop</button>
            </div>

            <div v-if="newTripForm.checkpoints.length === 0" class="no-checkpoints">
              No stops added. The trip will go straight to destination.
            </div>

            <div v-for="(cp, index) in newTripForm.checkpoints" :key="index" class="checkpoint-row">
              <span class="cp-number">{{ index + 1 }}</span>
              <input type="text" v-model="cp.location_name" placeholder="Location Name" required />
              <select v-model="cp.purpose">
                <option value="DELIVERY">DELIVERY</option>
                <option value="PICKUP">PICKUP</option>
                <option value="REST">REST</option>
                <option value="FUEL">FUEL</option>
                <option value="INSPECTION">INSPECTION</option>
              </select>
              <button type="button" @click="removeCheckpoint(index)" class="btn-remove-cp">
                X
              </button>
            </div>
          </div>

          <div class="modal-actions">
            <button type="button" @click="closeAddModal" class="btn-cancel">Cancel</button>
            <button type="submit" class="btn-save" :disabled="isSaving">
              {{ isSaving ? 'Creating...' : 'Create Trip' }}
            </button>
          </div>
        </form>
      </div>
    </div>

    <!-- TRACKER MODAL: แสดงความคืบหน้า Checkpoints (Optimistic Update) -->
    <div v-if="isTrackerOpen && selectedTrip" class="modal-overlay">
      <div class="modal-content tracker-modal">
        <div class="tracker-header">
          <h3>Trip Tracker: {{ selectedTrip.id.substring(0, 8) }}...</h3>
          <span :class="['status-badge', `status-${selectedTrip.status.toLowerCase()}`]">
            {{ selectedTrip.status }}
          </span>
        </div>
        <p class="tracker-route">{{ selectedTrip.origin }} &rarr; {{ selectedTrip.destination }}</p>
        <hr class="divider" />

        <div class="tracker-timeline">
          <div v-if="selectedTrip.checkpoints.length === 0" class="no-checkpoints">
            No checkpoints for this trip.
          </div>

          <div
            v-for="(cp, idx) in selectedTrip.checkpoints"
            :key="cp.id"
            :class="['timeline-item', `step-${cp.status.toLowerCase()}`]"
          >
            <!-- ตัวบอกสถานะวงกลม -->
            <div class="step-indicator">
              <div class="step-circle"></div>
              <div v-if="idx !== selectedTrip.checkpoints.length - 1" class="step-line"></div>
            </div>

            <!-- รายละเอียด -->
            <div class="step-content">
              <h4>{{ cp.location_name }}</h4>
              <p class="step-purpose">Purpose: {{ cp.purpose }}</p>

              <!-- ข้อมูลเวลา ถ้ามี -->
              <p v-if="cp.arrived_at" class="step-time">
                Arrived: {{ formatDateTime(cp.arrived_at) }}
              </p>
              <p v-if="cp.departed_at" class="step-time">
                Departed: {{ formatDateTime(cp.departed_at) }}
              </p>

              <!-- ป้ายสถานะปัจจุบันของจุดแวะนี้ -->
              <span class="checkpoint-badge">{{ getCheckpointStatusLabel(cp.status) }}</span>

              <!-- ปุ่มกดอัปเดต (Optimistic Actions) จะแสดงต่อเมื่อทริปกำลัง IN_PROGRESS และจุดก่อนหน้าเสร็จแล้ว -->
              <div
                v-if="selectedTrip.status === 'IN_PROGRESS' && isPreviousCheckpointCompleted(idx)"
                class="step-actions"
              >
                <button
                  v-if="cp.status === 'PENDING'"
                  @click="updateCheckpointStatus(idx, 'ARRIVED')"
                  class="btn-arrive"
                >
                  Mark Arrived
                </button>
                <button
                  v-if="cp.status === 'ARRIVED'"
                  @click="updateCheckpointStatus(idx, 'DEPARTED')"
                  class="btn-depart"
                >
                  Mark Departed
                </button>
                <button
                  v-if="cp.status === 'PENDING'"
                  @click="updateCheckpointStatus(idx, 'SKIPPED')"
                  class="btn-skip"
                >
                  Skip
                </button>
              </div>
            </div>
          </div>
        </div>

        <div class="modal-actions">
          <button type="button" @click="closeTracker" class="btn-cancel w-full">
            Close Tracker
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.header-actions {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 1.5rem;
}

h2 {
  margin: 0;
  color: #2d3748;
}

.table-container {
  background-color: #fff;
  padding: 2rem;
  border-radius: 8px;
  box-shadow: 0 4px 6px rgba(0, 0, 0, 0.05);
}

.table-scroll-wrapper {
  overflow-x: auto;
}

table {
  width: 100%;
  border-collapse: collapse;
  white-space: nowrap;
}

th,
td {
  padding: 1rem;
  text-align: left;
  border-bottom: 1px solid #e2e8f0;
}

th {
  font-weight: 600;
  color: #4a5568;
  background-color: #f7fafc;
}

.font-medium {
  font-weight: 500;
}

.trip-id {
  font-family: monospace;
  color: #718096;
}

.route-info {
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.arrow-icon {
  width: 16px;
  height: 16px;
  color: #a0aec0;
}

.time-cell {
  font-size: 0.9rem;
  color: #4a5568;
}

.status-badge {
  padding: 0.35rem 0.75rem;
  border-radius: 9999px;
  font-size: 0.75rem;
  font-weight: 600;
  color: #fff;
}

.status-scheduled {
  background-color: #ecc94b;
  color: #744210;
}
.status-in_progress {
  background-color: #4299e1;
}
.status-completed {
  background-color: #48bb78;
}
.status-cancelled {
  background-color: #f56565;
}

.btn-add {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  background-color: #3182ce;
  color: white;
  border: none;
  padding: 0.6rem 1.2rem;
  border-radius: 6px;
  font-size: 0.95rem;
  font-weight: 500;
  cursor: pointer;
  transition: background-color 0.2s;
}
.btn-add:hover {
  background-color: #2b6cb0;
}
.icon-small {
  width: 18px;
  height: 18px;
}

.btn-view {
  padding: 0.4rem 0.8rem;
  border: 1px solid #cbd5e0;
  background-color: white;
  color: #4a5568;
  border-radius: 4px;
  font-size: 0.85rem;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.2s;
}
.btn-view:hover {
  background-color: #f7fafc;
  color: #2d3748;
}

.loading-message,
.error-message {
  text-align: center;
  padding: 2rem;
  background-color: white;
  border-radius: 8px;
}

.error-message {
  color: #e53e3e;
}
.text-center {
  text-align: center;
}
.py-4 {
  padding-top: 1rem;
  padding-bottom: 1rem;
}
.text-gray-500 {
  color: #a0aec0;
}

/* Modal Styles */
.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  width: 100vw;
  height: 100vh;
  background-color: rgba(0, 0, 0, 0.5);
  display: flex;
  justify-content: center;
  align-items: center;
  z-index: 1000;
}

.modal-content {
  background-color: white;
  padding: 2rem;
  border-radius: 8px;
  width: 90%;
  max-width: 600px;
  box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.1);
  max-height: 90vh;
  overflow-y: auto;
}

.modal-content h3 {
  margin-top: 0;
  margin-bottom: 1.5rem;
  color: #2d3748;
}

.form-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 1rem;
}

.form-group {
  margin-bottom: 1.25rem;
}

.form-group label {
  display: block;
  font-size: 0.9rem;
  font-weight: 500;
  margin-bottom: 0.5rem;
  color: #4a5568;
}
.required {
  color: #e53e3e;
}

.form-group input,
.form-group select {
  width: 100%;
  padding: 0.6rem;
  border: 1px solid #cbd5e0;
  border-radius: 4px;
  background-color: #fff;
  font-size: 0.95rem;
  box-sizing: border-box;
}
.has-error {
  border-color: #e53e3e !important;
  background-color: #fff5f5 !important;
}
.error-text {
  display: block;
  font-size: 0.8rem;
  color: #e53e3e;
  margin-top: 0.4rem;
}

/* Checkpoints UI */
.checkpoints-section {
  margin-top: 1.5rem;
  padding-top: 1.5rem;
  border-top: 1px dashed #e2e8f0;
}

.checkpoints-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 1rem;
}
.checkpoints-header h4 {
  margin: 0;
  color: #2d3748;
}

.btn-sm {
  background-color: #edf2f7;
  color: #4a5568;
  border: 1px solid #cbd5e0;
  padding: 0.3rem 0.6rem;
  border-radius: 4px;
  font-size: 0.8rem;
  cursor: pointer;
}
.btn-sm:hover {
  background-color: #e2e8f0;
}

.no-checkpoints {
  font-size: 0.9rem;
  color: #a0aec0;
  text-align: center;
  padding: 1rem;
  background-color: #f7fafc;
  border-radius: 4px;
}

.checkpoint-row {
  display: flex;
  gap: 0.5rem;
  align-items: center;
  margin-bottom: 0.5rem;
  background-color: #f7fafc;
  padding: 0.5rem;
  border-radius: 4px;
  border: 1px solid #e2e8f0;
}
.cp-number {
  font-weight: bold;
  color: #a0aec0;
  width: 20px;
  text-align: center;
}
.checkpoint-row input {
  flex: 2;
  padding: 0.4rem;
  border: 1px solid #cbd5e0;
  border-radius: 4px;
}
.checkpoint-row select {
  flex: 1;
  padding: 0.4rem;
  border: 1px solid #cbd5e0;
  border-radius: 4px;
}
.btn-remove-cp {
  background-color: #fed7d7;
  color: #e53e3e;
  border: none;
  padding: 0.4rem;
  border-radius: 4px;
  cursor: pointer;
}

/* Actions */
.modal-actions {
  display: flex;
  justify-content: flex-end;
  gap: 1rem;
  margin-top: 2rem;
  border-top: 1px solid #e2e8f0;
  padding-top: 1.5rem;
}

.btn-cancel {
  padding: 0.5rem 1rem;
  border: 1px solid #cbd5e0;
  background-color: white;
  color: #4a5568;
  border-radius: 4px;
  cursor: pointer;
}

.btn-save {
  padding: 0.5rem 1rem;
  background-color: #3182ce;
  color: white;
  border: none;
  border-radius: 4px;
  cursor: pointer;
}

.btn-save:disabled {
  background-color: #a0aec0;
  cursor: not-allowed;
}
.w-full {
  width: 100%;
}

/* --- Trip Tracker (Optimistic Timeline) --- */
.tracker-modal {
  max-width: 500px;
}
.tracker-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 0.5rem;
}
.tracker-route {
  font-size: 1rem;
  color: #4a5568;
  margin-bottom: 1rem;
  font-weight: 500;
}
.divider {
  border: 0;
  border-top: 1px solid #e2e8f0;
  margin: 1.5rem 0;
}

.tracker-timeline {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.timeline-item {
  display: flex;
  gap: 1rem;
  position: relative;
  padding-bottom: 1.5rem; /* space for the line */
}

/* Color Coding for Steps (PENDING, ARRIVED, DEPARTED, SKIPPED) */
.step-circle {
  width: 24px;
  height: 24px;
  border-radius: 50%;
  background-color: #e2e8f0; /* Default: PENDING (Gray) */
  border: 3px solid white;
  box-shadow: 0 0 0 2px #cbd5e0;
  z-index: 2;
  position: relative;
  transition: all 0.3s ease;
}

.step-line {
  position: absolute;
  top: 24px; /* below the circle */
  left: 11px; /* center relative to the 24px circle */
  width: 2px;
  height: calc(100% - 24px + 1rem); /* stretch to next item */
  background-color: #e2e8f0; /* Default: PENDING line (Gray) */
  z-index: 1;
  transition: all 0.3s ease;
}

/* ARRIVED: ฟ้า */
.step-arrived .step-circle {
  background-color: #3182ce;
  box-shadow: 0 0 0 2px #3182ce;
}
.step-arrived .step-line {
  background-color: #3182ce;
}

/* DEPARTED: เขียว (ผ่านไปแล้ว) */
.step-departed .step-circle {
  background-color: #38a169;
  box-shadow: 0 0 0 2px #38a169;
}
.step-departed .step-line {
  background-color: #38a169;
}

/* SKIPPED: แดง */
.step-skipped .step-circle {
  background-color: #e53e3e;
  box-shadow: 0 0 0 2px #e53e3e;
}
.step-skipped .step-line {
  background-color: #e53e3e;
}

.step-content {
  flex: 1;
  background-color: #f7fafc;
  padding: 1rem;
  border-radius: 8px;
  border: 1px solid #e2e8f0;
  transition: all 0.3s ease;
}
.step-content h4 {
  margin: 0 0 0.25rem 0;
  color: #2d3748;
}
.step-purpose {
  margin: 0 0 0.5rem 0;
  font-size: 0.85rem;
  color: #718096;
}
.step-time {
  margin: 0;
  font-size: 0.8rem;
  color: #4a5568;
}

.checkpoint-badge {
  display: inline-block;
  padding: 0.2rem 0.5rem;
  font-size: 0.7rem;
  font-weight: bold;
  border-radius: 4px;
  margin-top: 0.5rem;
  text-transform: uppercase;
}

/* Badges matching colors */
.step-pending .checkpoint-badge {
  background-color: #e2e8f0;
  color: #4a5568;
}
.step-arrived .checkpoint-badge {
  background-color: #ebf8ff;
  color: #3182ce;
}
.step-departed .checkpoint-badge {
  background-color: #f0fff4;
  color: #38a169;
}
.step-skipped .checkpoint-badge {
  background-color: #fff5f5;
  color: #e53e3e;
}

.step-actions {
  margin-top: 1rem;
  display: flex;
  gap: 0.5rem;
  border-top: 1px dashed #cbd5e0;
  padding-top: 0.75rem;
}

/* Optimistic Action Buttons */
.btn-arrive {
  background-color: #3182ce;
  color: white;
  border: none;
  padding: 0.4rem 0.8rem;
  border-radius: 4px;
  font-size: 0.8rem;
  cursor: pointer;
  transition: opacity 0.2s;
}
.btn-arrive:hover {
  opacity: 0.8;
}

.btn-depart {
  background-color: #38a169;
  color: white;
  border: none;
  padding: 0.4rem 0.8rem;
  border-radius: 4px;
  font-size: 0.8rem;
  cursor: pointer;
  transition: opacity 0.2s;
}
.btn-depart:hover {
  opacity: 0.8;
}

.btn-skip {
  background-color: transparent;
  color: #e53e3e;
  border: 1px solid #fc8181;
  padding: 0.4rem 0.8rem;
  border-radius: 4px;
  font-size: 0.8rem;
  cursor: pointer;
  transition: opacity 0.2s;
}
.btn-skip:hover {
  background-color: #fff5f5;
}
</style>
