<script setup>
import { ref, onMounted, computed, onUnmounted } from 'vue'
import apiClient from '../api/axios'
import Swal from 'sweetalert2'

const trips = ref([])
const availableVehicles = ref([])
const selectedStatus = ref('')

const isFilterOpen = ref(false)
const filterOptions = [
  { value: '', label: 'All Statuses', colorClass: 'status-all' },
  { value: 'SCHEDULED', label: 'Scheduled', colorClass: 'status-scheduled' },
  { value: 'IN_PROGRESS', label: 'In Progress', colorClass: 'status-in_progress' },
  { value: 'COMPLETED', label: 'Completed', colorClass: 'status-completed' },
  { value: 'CANCELLED', label: 'Cancelled', colorClass: 'status-cancelled' }
]

const currentFilterOption = computed(() => {
  return filterOptions.find((o) => o.value === selectedStatus.value) || filterOptions[0]
})

const selectFilter = (val) => {
  selectedStatus.value = val
  isFilterOpen.value = false
}

// Click outside to close custom dropdown
const closeFilterDropdown = (e) => {
  if (!e.target.closest('.custom-dropdown')) {
    isFilterOpen.value = false
  }
}

const filteredTrips = computed(() => {
  if (!selectedStatus.value) return trips.value
  return trips.value.filter((trip) => trip.status === selectedStatus.value)
})
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
const isAdmin = computed(() => currentUserRole.value === 'ADMIN')

// ---- DELETE TRIP ----
const deleteTrip = async (trip) => {
  const result = await Swal.fire({
    title: 'ยืนยันการลบ?',
    html: `ต้องการลบทริป <strong>${trip.id}</strong> (เส้นทาง ${trip.origin} → ${trip.destination})?<br><small style="color:#718096">ผลการแวะพักทุกจุดในทริปนี้จะถูกลบด้วย</small>`,
    icon: 'warning',
    showCancelButton: true,
    confirmButtonColor: '#e53e3e',
    cancelButtonColor: '#a0aec0',
    confirmButtonText: 'ใช่, ลบเลย',
    cancelButtonText: 'ยกเลิก',
    reverseButtons: true,
  })

  if (!result.isConfirmed) return

  try {
    await apiClient.delete(`/trips/${trip.id}`)
    await Swal.fire({
      title: 'ลบสำเร็จ!',
      text: `ลบทริป ${trip.id} ออกจากระบบแล้ว`,
      icon: 'success',
      timer: 2000,
      timerProgressBar: true,
      showConfirmButton: false,
    })
    await fetchTrips()
  } catch (error) {
    const msg = error.response?.data?.error?.message || 'Failed to delete trip.'
    Swal.fire({ title: 'ไม่สามารถลบได้', text: msg, icon: 'error', confirmButtonColor: '#3182ce' })
    console.error('Failed to delete trip:', error)
  }
}

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

    const res = await apiClient.post('/trips', payload)
    const newTripId = res.data?.trip_id || ''

    closeAddModal()
    await fetchTrips() // รีเฟรชตาราง

    await Swal.fire({
      title: 'สร้างทริปสำเร็จ!',
      html: `ทริปใหม่ <strong>${newTripId}</strong> ถูกสร้างและบันทึกลงระบบแล้ว`,
      icon: 'success',
      timer: 2500,
      timerProgressBar: true,
      showConfirmButton: false,
    })
  } catch (error) {
    const errorResponse = error.response?.data?.error
    if (errorResponse && errorResponse.details) {
      fieldErrors.value = errorResponse.details
    } else {
      Swal.fire({
        title: 'สร้างทริปไม่สำเร็จ',
        text: errorResponse?.message || 'Failed to create trip.',
        icon: 'error',
        confirmButtonColor: '#3182ce',
      })
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
    // ยิง API ของจริงไปอัปเดต Backend
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
  document.addEventListener('click', closeFilterDropdown)
  const token = localStorage.getItem('accessToken')
  if (token) {
    const decoded = decodeToken(token)
    if (decoded && decoded.role) currentUserRole.value = decoded.role
  }
  fetchTrips()
  fetchOptions()
})

onUnmounted(() => {
  document.removeEventListener('click', closeFilterDropdown)
})
</script>

<template>
  <div class="trips-page">
    <div v-if="isLoading" class="loading-message">Loading trips data...</div>
    <div v-else-if="errorMessage" class="error-message">{{ errorMessage }}</div>
    <div v-else class="table-container">
      <div class="header-actions">
        <h2>All Trips</h2>
        <div class="header-actions-right">
          <div class="custom-dropdown">
            <div class="dropdown-trigger" @click="isFilterOpen = !isFilterOpen">
              <span v-if="currentFilterOption.value !== ''" :class="['dot-indicator', currentFilterOption.colorClass]"></span>
              <span>{{ currentFilterOption.label }}</span>
              <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2" class="chevron" :class="{ 'chevron-up': isFilterOpen }">
                <path stroke-linecap="round" stroke-linejoin="round" d="M19 9l-7 7-7-7" />
              </svg>
            </div>
            
            <Transition name="fade-slide">
              <div v-if="isFilterOpen" class="dropdown-menu">
                <div 
                  v-for="opt in filterOptions" 
                  :key="opt.value" 
                  class="dropdown-item"
                  :class="{ 'active': selectedStatus === opt.value }"
                  @click="selectFilter(opt.value)"
                >
                  <span v-if="opt.value !== ''" :class="['dot-indicator', opt.colorClass]"></span>
                  <span v-else class="dot-indicator empty-dot"></span>
                  {{ opt.label }}
                  
                  <!-- Checkmark for selected -->
                  <svg v-if="selectedStatus === opt.value" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2" class="check-icon">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M5 13l4 4L19 7" />
                  </svg>
                </div>
              </div>
            </Transition>
          </div>
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
              <th>Distance</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="trip in filteredTrips" :key="trip.id">
              <td class="trip-id" :title="trip.id">{{ trip.id.substring(0, 8) }}</td>
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
              <td class="distance-cell">{{ trip.distance_km ? trip.distance_km + ' km' : '-' }}</td>
              <td class="action-cell">
                <button @click="openTracker(trip.id)" class="btn-view">Track Trip</button>
                <button
                  v-if="isAdmin && trip.status !== 'IN_PROGRESS'"
                  @click="deleteTrip(trip)"
                  class="btn-delete"
                  title="Delete"
                >
                  <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="icon-small">
                    <path stroke-linecap="round" stroke-linejoin="round" d="m14.74 9-.346 9m-4.788 0L9.26 9m9.968-3.21c.342.052.682.107 1.022.166m-1.022-.165L18.16 19.673a2.25 2.25 0 0 1-2.244 2.077H8.084a2.25 2.25 0 0 1-2.244-2.077L4.772 5.79m14.456 0a48.108 48.108 0 0 0-3.478-.397m-12 .562c.34-.059.68-.114 1.022-.165m0 0a48.11 48.11 0 0 1 3.478-.397m7.5 0v-.916c0-1.18-.91-2.164-2.09-2.201a51.964 51.964 0 0 0-3.32 0c-1.18.037-2.09 1.022-2.09 2.201v.916m7.5 0a48.667 48.667 0 0 0-7.5 0" />
                  </svg>
                </button>
              </td>
            </tr>
            <tr v-if="filteredTrips.length === 0">
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
          <h3>Tracking: <span class="trip-id-highlight">{{ selectedTrip.id.substring(0, 8) }}</span></h3>
          <span :class="['status-badge', `status-${selectedTrip.status.toLowerCase()}`]">
            {{ selectedTrip.status }}
          </span>
        </div>
        <div class="tracker-route-wrap">
          <div class="route-pill origin">
            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2" class="icon-tiny">
              <path stroke-linecap="round" stroke-linejoin="round" d="M15 10.5a3 3 0 11-6 0 3 3 0 016 0z" />
              <path stroke-linecap="round" stroke-linejoin="round" d="M19.5 10.5c0 7.142-7.5 11.25-7.5 11.25S4.5 17.642 4.5 10.5a7.5 7.5 0 1115 0z" />
            </svg>
            {{ selectedTrip.origin }}
          </div>
          <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2" class="icon-tiny arrow-route">
            <path stroke-linecap="round" stroke-linejoin="round" d="M17.25 8.25L21 12m0 0l-3.75 3.75M21 12H3" />
          </svg>
          <div class="route-pill dest">
            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2" class="icon-tiny">
              <path stroke-linecap="round" stroke-linejoin="round" d="M3 13.5l6 6L21 4.5" />
            </svg>
            {{ selectedTrip.destination }}
          </div>
        </div>
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
  margin-bottom: 2rem;
}

.header-actions-right {
  display: flex;
  align-items: center;
  gap: 1rem;
}

.custom-dropdown {
  position: relative;
  display: inline-block;
  user-select: none;
}

.dropdown-trigger {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  background-color: #f8fafc;
  border: 1px solid transparent;
  padding: 0.5rem 1rem;
  border-radius: 9999px;
  color: #4a5568;
  font-size: 0.85rem;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s ease;
}

.dropdown-trigger:hover {
  background-color: #edf2f7;
}

.chevron {
  width: 14px;
  height: 14px;
  color: #a0aec0;
  transition: transform 0.2s ease;
}

.chevron-up {
  transform: rotate(180deg);
}

.dropdown-menu {
  position: absolute;
  top: calc(100% + 0.5rem);
  right: 0;
  min-width: 180px;
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

/* Reusing existing badge colors for dots */
.dot-indicator.status-scheduled { background-color: #f6e05e; }
.dot-indicator.status-in_progress { background-color: #63b3ed; }
.dot-indicator.status-completed { background-color: #68d391; }
.dot-indicator.status-cancelled { background-color: #fc8181; }

.fade-slide-enter-active,
.fade-slide-leave-active {
  transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);
}
.fade-slide-enter-from,
.fade-slide-leave-to {
  opacity: 0;
  transform: translateY(-5px);
}

h2 {
  margin: 0;
  color: #1a202c;
  font-size: 1.75rem;
  font-weight: 700;
}

.table-container {
  background-color: #fff;
  padding: 2.5rem;
  border-radius: 12px;
  box-shadow:
    0 10px 15px -3px rgba(0, 0, 0, 0.05),
    0 4px 6px -2px rgba(0, 0, 0, 0.025);
}

.table-scroll-wrapper {
  overflow-x: auto;
  border-radius: 8px;
  border: 1px solid #e2e8f0;
}

table {
  width: 100%;
  border-collapse: collapse;
  background-color: white;
}

th {
  font-weight: 600;
  color: #4a5568;
  background-color: #f8fafc;
  text-transform: uppercase;
  font-size: 0.75rem;
  letter-spacing: 0.05em;
  padding: 1rem;
  text-align: left;
  border-bottom: 2px solid #e2e8f0;
  white-space: nowrap;
}

td {
  padding: 1rem;
  text-align: left;
  border-bottom: 1px solid #edf2f7;
  color: #2d3748;
  vertical-align: middle;
}

tbody tr:hover {
  background-color: #f8fafc;
  transition: background-color 0.2s ease;
}

tbody tr:last-child td {
  border-bottom: none;
}

.font-medium {
  font-weight: 500;
}

.trip-id {
  font-family: 'SFMono-Regular', Consolas, 'Liberation Mono', Menlo, monospace;
  color: #718096;
  font-size: 0.9rem;
  font-weight: 500;
}

.route-info {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  background-color: #f7fafc;
  padding: 0.5rem 0.75rem;
  border-radius: 8px;
  width: fit-content;
  flex-wrap: wrap;
}

.origin,
.destination {
  font-weight: 500;
  color: #2d3748;
}

.arrow-icon {
  width: 16px;
  height: 16px;
  color: #3182ce;
}

.time-cell {
  font-size: 0.9rem;
  color: #4a5568;
  white-space: nowrap;
}

.action-cell {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  white-space: nowrap;
}

.status-badge {
  padding: 0.4rem 0.85rem;
  border-radius: 9999px;
  font-size: 0.75rem;
  font-weight: 700;
  letter-spacing: 0.05em;
  text-transform: uppercase;
  display: inline-block;
}

.status-scheduled {
  background-color: #fefcbf;
  color: #975a16;
}
.status-in_progress {
  background-color: #ebf8ff;
  color: #2b6cb0;
}
.status-completed {
  background-color: #f0fff4;
  color: #2f855a;
}
.status-cancelled {
  background-color: #fff5f5;
  color: #c53030;
}

.btn-add {
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
}
.btn-add:hover {
  transform: translateY(-2px);
  box-shadow: 0 8px 16px rgba(37, 99, 235, 0.3);
}
.btn-add:active {
  transform: translateY(1px);
  box-shadow: 0 2px 4px rgba(37, 99, 235, 0.2);
}
.icon-small {
  width: 18px;
  height: 18px;
}

.btn-view {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  height: 34px;
  padding: 0 1rem;
  border: 1px solid #e2e8f0;
  background-color: white;
  color: #4a5568;
  border-radius: 6px;
  font-size: 0.85rem;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.2s;
  box-shadow: 0 1px 2px rgba(0, 0, 0, 0.05);
}
.btn-view:hover {
  background-color: #f7fafc;
  color: #2b6cb0;
  border-color: #cbd5e0;
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

@keyframes fadeIn {
  from {
    opacity: 0;
  }
  to {
    opacity: 1;
  }
}

.modal-content {
  background-color: white;
  padding: 2.5rem;
  border-radius: 20px;
  width: 100%;
  max-width: 700px;
  box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.25);
  max-height: 90vh;
  overflow-y: auto;
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

.modal-content h3 {
  margin-top: 0;
  margin-bottom: 2rem;
  color: #1a202c;
  font-size: 1.5rem;
  font-weight: 700;
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
  padding: 0.75rem 1rem;
  border: 1px solid #cbd5e0;
  border-radius: 6px;
  background-color: #fff;
  font-size: 0.95rem;
  box-sizing: border-box;
  transition:
    border-color 0.2s,
    box-shadow 0.2s;
}
.form-group input:focus,
.form-group select:focus {
  outline: none;
  border-color: #3182ce;
  box-shadow: 0 0 0 3px rgba(49, 130, 206, 0.1);
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
  padding: 0.4rem 0.8rem;
  border-radius: 6px;
  font-size: 0.85rem;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.2s;
}
.btn-sm:hover {
  background-color: #e2e8f0;
  color: #1a202c;
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
  gap: 0.75rem;
  align-items: center;
  margin-bottom: 0.75rem;
  background-color: #f8fafc;
  padding: 0.75rem;
  border-radius: 8px;
  border: 1px solid #e2e8f0;
  box-shadow: 0 1px 2px rgba(0, 0, 0, 0.02);
}
.cp-number {
  font-weight: bold;
  color: #a0aec0;
  width: 20px;
  text-align: center;
}
.checkpoint-row input {
  flex: 2;
  padding: 0.6rem;
  border: 1px solid #cbd5e0;
  border-radius: 6px;
  transition: all 0.2s;
}
.checkpoint-row select {
  flex: 1;
  padding: 0.6rem;
  border: 1px solid #cbd5e0;
  border-radius: 6px;
  transition: all 0.2s;
}
.checkpoint-row input:focus,
.checkpoint-row select:focus {
  outline: none;
  border-color: #3182ce;
  box-shadow: 0 0 0 3px rgba(49, 130, 206, 0.1);
}
.btn-remove-cp {
  background-color: #fff5f5;
  color: #e53e3e;
  border: 1px solid #feb2b2;
  padding: 0.6rem;
  border-radius: 6px;
  cursor: pointer;
  transition: all 0.2s;
}
.btn-remove-cp:hover {
  background-color: #fed7d7;
  color: #c53030;
  border-color: #fc8181;
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
  padding: 0.65rem 1.5rem;
  border: 1px solid #e2e8f0;
  background-color: white;
  color: #4a5568;
  border-radius: 6px;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.2s;
}
.btn-cancel:hover {
  background-color: #f8fafc;
  color: #1a202c;
  border-color: #cbd5e0;
}

.btn-save {
  padding: 0.65rem 1.5rem;
  background-color: #3182ce;
  color: white;
  border: none;
  border-radius: 6px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s ease;
  box-shadow: 0 4px 6px -1px rgba(49, 130, 206, 0.4);
}
.btn-save:hover:not(:disabled) {
  background-color: #2b6cb0;
  transform: translateY(-1px);
}
.btn-save:active:not(:disabled) {
  transform: translateY(1px);
  box-shadow: 0 2px 4px -1px rgba(49, 130, 206, 0.4);
}
.btn-save:disabled {
  background-color: #a0aec0;
  cursor: not-allowed;
  box-shadow: none;
}
.w-full {
  width: 100%;
}

/* --- Trip Tracker (Optimistic Timeline) --- */
.tracker-modal {
  max-width: 520px;
  padding: 2rem 1.5rem;
  border-radius: 16px;
}
.tracker-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 1rem;
}
.tracker-header h3 {
  margin: 0 !important;
  font-size: 1.25rem;
  color: #0f172a;
}
.trip-id-highlight {
  color: #64748b;
  font-weight: 500;
}
.tracker-route-wrap {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  margin-bottom: 1.2rem;
  flex-wrap: wrap;
}
.route-pill {
  display: inline-flex;
  align-items: center;
  gap: 0.3rem;
  padding: 0.35rem 0.8rem;
  border-radius: 9999px;
  font-size: 0.85rem;
  font-weight: 600;
}
.route-pill.origin {
  background-color: #f8fafc;
  color: #475569;
  border: 1px solid #e2e8f0;
}
.route-pill.dest {
  background-color: #eff6ff;
  color: #2563eb;
  border: 1px solid #bfdbfe;
}
.icon-tiny {
  width: 14px;
  height: 14px;
}
.arrow-route {
  color: #94a3b8;
}

.divider {
  border: 0;
  border-top: 1px dashed #e2e8f0;
  margin: 1.2rem 0;
}

.tracker-timeline {
  display: flex;
  flex-direction: column;
  gap: 1rem;
  max-height: 50vh;
  overflow-y: auto;
  padding-right: 0.5rem;
  padding-left: 0.2rem;
  padding-top: 0.5rem;
}

.tracker-modal .modal-actions {
  margin-top: 1rem;
  padding-top: 1rem;
  border-top: none;
}

.tracker-timeline::-webkit-scrollbar {
  width: 6px;
}
.tracker-timeline::-webkit-scrollbar-track {
  background: #f8fafc;
  border-radius: 4px;
}
.tracker-timeline::-webkit-scrollbar-thumb {
  background: #cbd5e1;
  border-radius: 4px;
}
.tracker-timeline::-webkit-scrollbar-thumb:hover {
  background: #94a3b8;
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
  background-color: white;
  padding: 1rem 1.2rem;
  border-radius: 12px;
  border: 1px solid #e2e8f0;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.02);
  transition: all 0.3s ease;
}
.step-content:hover {
  box-shadow: 0 8px 12px rgba(0, 0, 0, 0.04);
  border-color: #cbd5e1;
  transform: translateY(-1px);
}
.step-content h4 {
  margin: 0 0 0.25rem 0;
  color: #1e293b;
  font-size: 0.95rem;
  font-weight: 600;
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
  margin-top: 0.75rem;
  display: flex;
  gap: 0.5rem;
  border-top: 1px dashed #e2e8f0;
  padding-top: 0.75rem;
}

/* Optimistic Action Buttons */
.btn-arrive {
  background-color: #3182ce;
  color: white;
  border: none;
  padding: 0.5rem 1rem;
  border-radius: 6px;
  font-size: 0.85rem;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.2s;
  box-shadow: 0 2px 4px rgba(49, 130, 206, 0.2);
}
.btn-arrive:hover {
  background-color: #2b6cb0;
  transform: translateY(-1px);
}

.btn-depart {
  background-color: #38a169;
  color: white;
  border: none;
  padding: 0.5rem 1rem;
  border-radius: 6px;
  font-size: 0.85rem;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.2s;
  box-shadow: 0 2px 4px rgba(56, 161, 105, 0.2);
}
.btn-depart:hover {
  background-color: #2f855a;
  transform: translateY(-1px);
}

.btn-skip {
  background-color: white;
  color: #e53e3e;
  border: 1px solid #fc8181;
  padding: 0.5rem 1rem;
  border-radius: 6px;
  font-size: 0.85rem;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.2s;
}
.btn-skip:hover {
  background-color: #fff5f5;
  border-color: #e53e3e;
}

.btn-delete {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  height: 34px;
  width: 34px;
  padding: 0;
  background-color: #fff5f5;
  color: #c53030;
  border: 1px solid #fed7d7;
  border-radius: 6px;
  cursor: pointer;
  transition: all 0.2s;
}
.btn-delete:hover {
  background-color: #fed7d7;
  color: #742a2a;
}
</style>
