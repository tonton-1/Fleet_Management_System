<script setup>
import { ref, onMounted, computed, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import apiClient from '../api/axios'

const vehicles = ref([])
const drivers = ref([]) // สำหรับเก็บรายชื่อคนขับใน dropdown
const isLoading = ref(true)
const errorMessage = ref('')
const currentUserRole = ref('')
const route = useRoute()
const router = useRouter()

const filters = ref({
  status: '',
  type: '',
  driver: '',
  search: '',
})

const initFiltersFromURL = () => {
  filters.value.status = route.query.status || ''
  filters.value.type = route.query.type || ''
  filters.value.driver = route.query.driver || ''
  filters.value.search = route.query.search || ''
}

const updateURL = () => {
  const query = {}
  if (filters.value.status) query.status = filters.value.status
  if (filters.value.type) query.type = filters.value.type
  if (filters.value.driver) query.driver = filters.value.driver
  if (filters.value.search) query.search = filters.value.search
  router.push({ query })
}

const filteredVehicles = computed(() => {
  return vehicles.value.filter((v) => {
    if (filters.value.status && v.status !== filters.value.status) return false
    if (filters.value.type && v.type !== filters.value.type)
      if (filters.value.driver) {
        const driverMatch =
          v.driver_id === filters.value.driver ||
          v.driver_name?.toLowerCase().includes(filters.value.driver.toLowerCase())
        if (!driverMatch) return false
      }
    if (filters.value.search) {
      const search = filters.value.search.toLowerCase()
      const match =
        v.license_plate?.toLowerCase().includes(search) ||
        v.brand?.toLowerCase().includes(search) ||
        v.model?.toLowerCase().includes(search)
      if (!match) return false
    }
    return true
  })
})

// สถานะของ Modal แก้ไข
const isEditModalOpen = ref(false)
const isSaving = ref(false)
const editForm = ref({
  id: '',
  license_plate: '',
  status: '',
  driver_id: '',
})

// ฟังก์ชันสำหรับถอดรหัส JWT Token แบบง่ายๆ ฝั่ง Frontend
const decodeToken = (token) => {
  try {
    const base64Url = token.split('.')[1]
    const base64 = base64Url.replace(/-/g, '+').replace(/_/g, '/')
    const jsonPayload = decodeURIComponent(
      atob(base64)
        .split('')
        .map((c) => '%' + ('00' + c.charCodeAt(0).toString(16)).slice(-2))
        .join(''),
    )
    return JSON.parse(jsonPayload)
  } catch (e) {
    return null
  }
}

const fetchVehicles = async () => {
  try {
    isLoading.value = true
    const response = await apiClient.get('/vehicles')
    vehicles.value = response.data
  } catch (error) {
    errorMessage.value = error.response?.data?.error?.message || 'Failed to fetch vehicle data.'
    console.error('Failed to fetch vehicles:', error)
  } finally {
    isLoading.value = false
  }
}

const fetchDrivers = async () => {
  try {
    const response = await apiClient.get('/drivers')
    drivers.value = response.data
  } catch (error) {
    console.error('Failed to fetch drivers:', error)
  }
}

const deleteVehicle = async (id, licensePlate) => {
  if (!confirm(`Are you sure you want to delete vehicle ${licensePlate}?`)) return

  try {
    await apiClient.delete(`/vehicles/${id}`)
    // ลบรถคันนั้นออกจากรายการในหน้าจอโดยไม่ต้องโหลดใหม่ทั้งหมด
    vehicles.value = vehicles.value.filter((v) => v.id !== id)
    alert(`Vehicle ${licensePlate} deleted successfully.`)
  } catch (error) {
    alert(error.response?.data?.error?.message || 'Failed to delete vehicle.')
    console.error('Failed to delete vehicle:', error)
  }
}

const openEditModal = (vehicle) => {
  // นำข้อมูลปัจจุบันมาใส่ในฟอร์ม
  editForm.value = {
    id: vehicle.id,
    license_plate: vehicle.license_plate,
    status: vehicle.status,
    driver_id: vehicle.driver_id || '', // ถ้าเป็น null ให้เป็น string ว่างสำหรับ select
  }
  isEditModalOpen.value = true
}

const closeEditModal = () => {
  isEditModalOpen.value = false
  editForm.value = { id: '', license_plate: '', status: '', driver_id: '' }
}

const saveVehicle = async () => {
  try {
    isSaving.value = true

    // จัดเตรียมข้อมูลที่จะส่ง (ถ้าไม่มีคนขับให้ส่ง null แทน string ว่าง)
    const payload = {
      status: editForm.value.status,
      driver_id: editForm.value.driver_id || null,
    }

    await apiClient.patch(`/vehicles/${editForm.value.id}`, payload)

    // รีเฟรชข้อมูลรถทั้งหมดใหม่หลังจากแก้เสร็จ
    await fetchVehicles()

    closeEditModal()
    alert('Vehicle updated successfully.')
  } catch (error) {
    alert(error.response?.data?.error?.message || 'Failed to update vehicle.')
    console.error('Failed to update vehicle:', error)
  } finally {
    isSaving.value = false
  }
}

// Computed property เพื่อเช็คว่าเป็น Admin หรือไม่
const isAdmin = computed(() => currentUserRole.value === 'ADMIN')

onMounted(() => {
  // ดึง token และหา role ของ user ปัจจุบัน
  const token = localStorage.getItem('accessToken')
  if (token) {
    const decoded = decodeToken(token)
    if (decoded && decoded.role) {
      currentUserRole.value = decoded.role
    }
  }

  initFiltersFromURL()
  fetchVehicles()
  fetchDrivers() // ดึงข้อมูลคนขับเตรียมไว้สำหรับ Dropdown
})

watch(
  filters,
  () => {
    updateURL()
  },
  { deep: true },
)
</script>

<template>
  <div class="vehicles-page">
    <div v-if="isLoading" class="loading-message">Loading vehicle data...</div>
    <div v-else-if="errorMessage" class="error-message">{{ errorMessage }}</div>
    <div v-else class="table-container">
      <div class="header-actions">
        <h2>All Vehicles</h2>
      </div>

      <div class="filters">
        <select v-model="filters.status">
          <option value="">All Status</option>
          <option value="IDLE">Idle</option>
          <option value="ACTIVE">Active</option>
          <option value="MAINTENANCE">Maintenance</option>
          <option value="RETIRED">Retired</option>
        </select>
        <select v-model="filters.type">
          <option value="">All Types</option>
          <option value="TRUCK">Truck</option>
          <option value="VAN">Van</option>
          <option value="MOTORCYCLE">Motorcycle</option>
          <option value="PICKUP">Pickup</option>
        </select>
        <input type="text" v-model="filters.search" placeholder="Search license, brand, model..." />
      </div>

      <table>
        <thead>
          <tr>
            <th>License Plate</th>
            <th>Type</th>
            <th>Status</th>
            <th>Driver</th>
            <th>Model</th>
            <th>Actions</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="vehicle in filteredVehicles" :key="vehicle.id">
            <td>{{ vehicle.license_plate }}</td>
            <td>{{ vehicle.type }}</td>
            <td>
              <span :class="['status-badge', `status-${vehicle.status.toLowerCase()}`]">
                {{ vehicle.status }}
              </span>
            </td>
            <td>{{ vehicle.driver_name || 'N/A' }}</td>
            <td>{{ vehicle.brand || '' }} {{ vehicle.model || '' }}</td>
            <td class="action-cell">
              <button @click="openEditModal(vehicle)" class="btn-edit">Edit</button>
              <!-- แสดงปุ่ม Delete เฉพาะเมื่อ isAdmin เป็น true -->
              <button
                v-if="isAdmin"
                @click="deleteVehicle(vehicle.id, vehicle.license_plate)"
                class="btn-delete"
              >
                Delete
              </button>
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <!-- Modal สำหรับแก้ไขข้อมูลรถ -->
    <div v-if="isEditModalOpen" class="modal-overlay">
      <div class="modal-content">
        <h3>Edit Vehicle ({{ editForm.license_plate }})</h3>
        <form @submit.prevent="saveVehicle">
          <div class="form-group">
            <label for="status">Status</label>
            <select id="status" v-model="editForm.status" required>
              <option value="ACTIVE">ACTIVE</option>
              <option value="IDLE">IDLE</option>
              <option value="MAINTENANCE">MAINTENANCE</option>
              <option value="RETIRED">RETIRED</option>
            </select>
          </div>

          <div class="form-group">
            <label for="driver">Assign Driver</label>
            <select id="driver" v-model="editForm.driver_id">
              <option value="">-- No Driver (Unassign) --</option>
              <!-- วนลูปรายชื่อคนขับทั้งหมดมาเป็นตัวเลือก -->
              <option v-for="driver in drivers" :key="driver.id" :value="driver.id">
                {{ driver.name }} ({{ driver.license_number }})
              </option>
            </select>
          </div>

          <div class="modal-actions">
            <button type="button" @click="closeEditModal" class="btn-cancel">Cancel</button>
            <button type="submit" class="btn-save" :disabled="isSaving">
              {{ isSaving ? 'Saving...' : 'Save Changes' }}
            </button>
          </div>
        </form>
      </div>
    </div>
  </div>
</template>

<style scoped>
.vehicles-page {
  /* Removed layout logic since MainLayout handles it now */
}

.header-actions {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 1rem;
}

.filters {
  display: flex;
  gap: 12px;
  margin-bottom: 16px;
  padding: 12px;
  background: #f9fafb;
  border-radius: 8px;
}

.filters select,
.filters input {
  padding: 8px 12px;
  border: 1px solid #e5e7eb;
  border-radius: 6px;
  font-size: 14px;
}

.filters input {
  flex: 1;
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

table {
  width: 100%;
  border-collapse: collapse;
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

.action-cell {
  display: flex;
  gap: 0.5rem;
}

.btn-edit,
.btn-delete {
  padding: 0.4rem 0.8rem;
  border: none;
  border-radius: 4px;
  font-size: 0.85rem;
  font-weight: 500;
  cursor: pointer;
  transition: opacity 0.2s;
}

.btn-edit {
  background-color: #ebf8ff;
  color: #3182ce;
}
.btn-edit:hover {
  opacity: 0.8;
}

.btn-delete {
  background-color: #fed7d7;
  color: #e53e3e;
}
.btn-delete:hover {
  opacity: 0.8;
}

.status-badge {
  padding: 0.35rem 0.75rem;
  border-radius: 9999px;
  font-size: 0.8rem;
  font-weight: 600;
  color: #fff;
}

.status-active {
  background-color: #48bb78;
}
.status-idle {
  background-color: #a0aec0;
}
.status-maintenance {
  background-color: #ecc94b;
  color: #744210;
}
.status-retired {
  background-color: #f56565;
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
  max-width: 400px;
  box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.1);
}

.modal-content h3 {
  margin-top: 0;
  margin-bottom: 1.5rem;
  color: #2d3748;
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

.form-group select {
  width: 100%;
  padding: 0.6rem;
  border: 1px solid #cbd5e0;
  border-radius: 4px;
  background-color: #fff;
  font-size: 0.95rem;
}

.modal-actions {
  display: flex;
  justify-content: flex-end;
  gap: 1rem;
  margin-top: 2rem;
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
</style>
