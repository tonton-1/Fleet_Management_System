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
    if (filters.value.type && v.type !== filters.value.type) return false
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

// สถานะของ Modal เพิ่ม
const isAddModalOpen = ref(false)
const addForm = ref({
  license_plate: '',
  type: 'TRUCK',
  status: 'IDLE',
  driver_id: '',
  context: {
    brand: '',
    model: '',
    year: '',
    fuel_type: 'DIESEL',
    mileage_km: 0,
    next_service_km: '',
  },
})

const openAddModal = () => {
  addForm.value = {
    license_plate: '',
    type: 'TRUCK',
    status: 'IDLE',
    driver_id: '',
    context: {
      brand: '',
      model: '',
      year: '',
      fuel_type: 'DIESEL',
      mileage_km: 0,
      next_service_km: '',
    },
  }
  isAddModalOpen.value = true
}

const closeAddModal = () => {
  isAddModalOpen.value = false
}

const saveNewVehicle = async () => {
  try {
    isSaving.value = true
    await apiClient.post('/vehicles', addForm.value)
    closeAddModal()
    await fetchVehicles()
  } catch (error) {
    alert('Failed to create vehicle: ' + (error.response?.data?.error?.message || error.message))
  } finally {
    isSaving.value = false
  }
}

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

const statusLabels = {
  ACTIVE: 'ใช้งาน',
  IDLE: 'ว่าง',
  MAINTENANCE: 'ซ่อมบำรุง',
  RETIRED: 'เลิกใช้',
}

const getStatusLabel = (status) => statusLabels[status] || status

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
    <div v-if="isLoading" class="loading-message">
      <div class="spinner"></div>
      <span>กำลังโหลดข้อมูล...</span>
    </div>
    <div v-else-if="errorMessage" class="error-message">{{ errorMessage }}</div>
    <div v-else class="table-container">
      <div class="header-actions">
        <h2>ยานพาหนะ</h2>
        <button v-if="isAdmin" @click="openAddModal" class="btn-add">
          <svg
            xmlns="http://www.w3.org/2000/svg"
            fill="none"
            viewBox="0 0 24 24"
            stroke-width="2"
            stroke="currentColor"
          >
            <path stroke-linecap="round" stroke-linejoin="round" d="M12 4.5v15m6-6h-15" />
          </svg>
          เพิ่มยานพาหนะ
        </button>
      </div>

      <div class="filters">
        <select v-model="filters.status">
          <option value="">ทุกสถานะ</option>
          <option value="IDLE">ว่าง</option>
          <option value="ACTIVE">ใช้งาน</option>
          <option value="MAINTENANCE">ซ่อมบำรุง</option>
          <option value="RETIRED">เลิกใช้</option>
        </select>
        <select v-model="filters.type">
          <option value="">ทุกประเภท</option>
          <option value="TRUCK">รถบรรทุก</option>
          <option value="VAN">รถตู้</option>
          <option value="MOTORCYCLE">มอเตอร์ไซค์</option>
          <option value="PICKUP">รถกระบะ</option>
        </select>
        <input type="text" v-model="filters.search" placeholder="ค้นหาป้ายทะเบียน ยี่ห้อ รุ่น..." />
      </div>

      <table>
        <thead>
          <tr>
            <th>ยานพาหนะ</th>
            <th>ประเภท</th>
            <th>สถานะ</th>
            <th>คนขับ</th>
            <th>ข้อมูล</th>
            <th>เลขไมล์</th>
            <th>จัดการ</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="vehicle in filteredVehicles" :key="vehicle.id">
            <td>
              <div class="vehicle-info">
                <span class="license-plate">{{ vehicle.license_plate }}</span>
              </div>
            </td>
            <td>
              <span class="type-badge">{{ vehicle.type }}</span>
            </td>
            <td>
              <span :class="['status-badge', `status-${vehicle.status.toLowerCase()}`]">
                {{ getStatusLabel(vehicle.status) }}
              </span>
            </td>
            <td>{{ vehicle.driver_name || '-' }}</td>
            <td>
              <span class="vehicle-detail"
                >{{ vehicle.brand || '-' }} {{ vehicle.model || '' }}</span
              >
            </td>
            <td>
              <span class="mileage">{{ vehicle.mileage_km?.toLocaleString() || 0 }} กม.</span>
            </td>
            <td class="action-cell">
              <button @click="openEditModal(vehicle)" class="btn-edit">
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
                    d="m16.862 4.487 1.687-1.688a1.875 1.875 0 1 1 2.652 2.652L10.582 16.07a4.5 4.5 0 0 1-1.897 1.13L6 18l.8-2.685a4.5 4.5 0 0 1 1.13-1.897l8.932-8.931Zm0 0L19.5 7.125M18 14v4.75A2.25 2.25 0 0 1 15.75 21H5.25A2.25 2.25 0 0 1 3 18.75V8.25A2.25 2.25 0 0 1 5.25 6H10"
                  />
                </svg>
                แก้ไข
              </button>
              <button
                v-if="isAdmin"
                @click="deleteVehicle(vehicle.id, vehicle.license_plate)"
                class="btn-delete"
              >
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
                    d="m14.74 9-.346 9m-4.788 0L9.26 9m9.968-3.21c.342.052.682.107 1.022.166m-1.022-.165L18.16 19.673a2.25 2.25 0 0 1-2.244 2.077H8.084a2.25 2.25 0 0 1-2.244-2.077L4.772 5.79m14.456 0a48.108 48.108 0 0 0-3.478-.397m-12 .562c.34-.059.68-.114 1.022-.165m0 0a48.11 48.11 0 0 1 3.478-.397m7.5 0v-.916c0-1.18-.91-2.164-2.09-2.201a51.964 51.964 0 0 0-3.32 0c-1.18.037-2.09 1.022-2.09 2.201v.916m7.5 0a48.667 48.667 0 0 0-7.5 0"
                  />
                </svg>
                ลบ
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

    <!-- Modal สำหรับเพิ่มยานพาหนะใหม่ -->
    <div v-if="isAddModalOpen" class="modal-overlay">
      <div class="modal-content modal-lg">
        <h3>เพิ่มยานพาหนะใหม่</h3>
        <form @submit.prevent="saveNewVehicle">
          <div class="form-grid">
            <div class="form-group">
              <label for="add-license">ป้ายทะเบียน *</label>
              <input
                id="add-license"
                v-model="addForm.license_plate"
                required
                placeholder="เช่น กท-1234"
              />
            </div>

            <div class="form-group">
              <label for="add-type">ประเภท *</label>
              <select id="add-type" v-model="addForm.type" required>
                <option value="TRUCK">TRUCK</option>
                <option value="VAN">VAN</option>
                <option value="MOTORCYCLE">MOTORCYCLE</option>
                <option value="PICKUP">PICKUP</option>
              </select>
            </div>

            <div class="form-group">
              <label for="add-status">สถานะ</label>
              <select id="add-status" v-model="addForm.status">
                <option value="IDLE">IDLE</option>
                <option value="ACTIVE">ACTIVE</option>
                <option value="MAINTENANCE">MAINTENANCE</option>
                <option value="RETIRED">RETIRED</option>
              </select>
            </div>

            <div class="form-group">
              <label for="add-driver">มอบหมายคนขับ</label>
              <select id="add-driver" v-model="addForm.driver_id">
                <option value="">-- ไม่มีคนขับ --</option>
                <option v-for="driver in drivers" :key="driver.id" :value="driver.id">
                  {{ driver.name }} ({{ driver.license_number }})
                </option>
              </select>
            </div>

            <div class="form-group">
              <label for="add-brand">ยี่ห้อ</label>
              <input id="add-brand" v-model="addForm.context.brand" placeholder="เช่น Isuzu" />
            </div>

            <div class="form-group">
              <label for="add-model">รุ่น</label>
              <input id="add-model" v-model="addForm.context.model" placeholder="เช่น D-Max" />
            </div>

            <div class="form-group">
              <label for="add-year">ปี</label>
              <input
                id="add-year"
                v-model="addForm.context.year"
                type="number"
                placeholder="เช่น 2024"
              />
            </div>

            <div class="form-group">
              <label for="add-fuel">ประเภทน้ำมัน</label>
              <select id="add-fuel" v-model="addForm.context.fuel_type">
                <option value="DIESEL">DIESEL</option>
                <option value="GASOLINE">GASOLINE</option>
                <option value="ELECTRIC">ELECTRIC</option>
                <option value="HYBRID">HYBRID</option>
              </select>
            </div>

            <div class="form-group">
              <label for="add-mileage">เลขไมล์ (กม.)</label>
              <input id="add-mileage" v-model.number="addForm.context.mileage_km" type="number" />
            </div>

            <div class="form-group">
              <label for="add-next-service">กำหนดรับบริการครั้งต่อไป (กม.)</label>
              <input
                id="add-next-service"
                v-model.number="addForm.context.next_service_km"
                type="number"
                placeholder="เช่น 50000"
              />
            </div>
          </div>

          <div class="modal-actions">
            <button type="button" @click="closeAddModal" class="btn-cancel">ยกเลิก</button>
            <button type="submit" class="btn-save" :disabled="isSaving">
              {{ isSaving ? 'กำลังบันทึก...' : 'บันทึก' }}
            </button>
          </div>
        </form>
      </div>
    </div>
  </div>
</template>

<style scoped>
.vehicles-page {
  padding: 24px;
  max-width: 1400px;
  margin: 0 auto;
  font-family:
    'Inter',
    -apple-system,
    BlinkMacSystemFont,
    'Segoe UI',
    Roboto,
    sans-serif;
  color: #374151;
}

.header-actions {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 24px;
}

h2 {
  font-size: 28px;
  font-weight: 700;
  color: #111827;
  margin: 0;
  letter-spacing: -0.025em;
}

.btn-add {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 10px 18px;
  background: #3b82f6;
  color: white;
  border: none;
  border-radius: 8px;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s ease-in-out;
  box-shadow:
    0 4px 6px -1px rgba(59, 130, 246, 0.2),
    0 2px 4px -2px rgba(59, 130, 246, 0.2);
}

.btn-add svg {
  width: 20px;
  height: 20px;
}

.btn-add:hover {
  background: #2563eb;
  transform: translateY(-1px);
  box-shadow:
    0 6px 8px -1px rgba(59, 130, 246, 0.3),
    0 4px 6px -2px rgba(59, 130, 246, 0.2);
}

.filters {
  display: flex;
  gap: 16px;
  margin-bottom: 24px;
  padding: 16px 20px;
  background: white;
  border: 1px solid #e5e7eb;
  border-radius: 12px;
  flex-wrap: wrap;
  box-shadow: 0 1px 2px 0 rgba(0, 0, 0, 0.05);
}

.filters select,
.filters input {
  padding: 10px 14px;
  border: 1px solid #d1d5db;
  border-radius: 8px;
  font-size: 14px;
  background: #f9fafb;
  color: #374151;
  transition: all 0.2s;
  box-sizing: border-box;
}

.filters select:hover,
.filters input:hover {
  border-color: #9ca3af;
}

.filters select:focus,
.filters input:focus {
  outline: none;
  background: white;
  border-color: #3b82f6;
  box-shadow: 0 0 0 4px rgba(59, 130, 246, 0.1);
}

.filters input {
  flex: 1;
  min-width: 240px;
}

.table-container {
  background: white;
  border-radius: 12px;
  box-shadow:
    0 4px 6px -1px rgba(0, 0, 0, 0.05),
    0 2px 4px -2px rgba(0, 0, 0, 0.05);
  border: 1px solid #f3f4f6;
  overflow: hidden;
}

table {
  width: 100%;
  border-collapse: collapse;
}

thead {
  background: #f9fafb;
  border-bottom: 1px solid #e5e7eb;
}

th {
  padding: 16px 24px;
  text-align: left;
  font-size: 12px;
  font-weight: 600;
  color: #6b7280;
  text-transform: uppercase;
  letter-spacing: 0.05em;
}

td {
  padding: 16px 24px;
  font-size: 14px;
  color: #111827;
  border-bottom: 1px solid #f3f4f6;
  vertical-align: middle;
}

tbody tr {
  transition: background-color 0.15s ease;
}

tbody tr:hover {
  background-color: #f9fafb;
}

tbody tr:last-child td {
  border-bottom: none;
}

.vehicle-info {
  display: flex;
  flex-direction: column;
}

.license-plate {
  font-weight: 700;
  color: #111827;
  font-size: 15px;
}

.type-badge {
  display: inline-block;
  padding: 4px 10px;
  background: #eff6ff;
  color: #1d4ed8;
  border-radius: 6px;
  font-size: 12px;
  font-weight: 600;
  letter-spacing: 0.025em;
}

.status-badge {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  padding: 4px 12px;
  border-radius: 20px;
  font-size: 12px;
  font-weight: 600;
}

.status-badge::before {
  content: '';
  width: 6px;
  height: 6px;
  border-radius: 50%;
}

.status-badge.status-active {
  background: #ecfdf5;
  color: #059669;
}
.status-badge.status-active::before {
  background: #059669;
}

.status-badge.status-idle {
  background: #eff6ff;
  color: #2563eb;
}
.status-badge.status-idle::before {
  background: #2563eb;
}

.status-badge.status-maintenance {
  background: #fffbeb;
  color: #d97706;
}
.status-badge.status-maintenance::before {
  background: #d97706;
}

.status-badge.status-retired {
  background: #f3f4f6;
  color: #4b5563;
}
.status-badge.status-retired::before {
  background: #6b7280;
}

.vehicle-detail {
  color: #4b5563;
  font-size: 14px;
}

.mileage {
  font-weight: 500;
  color: #4b5563;
  background: #f3f4f6;
  padding: 4px 10px;
  border-radius: 6px;
  font-size: 13px;
}

.action-cell {
  display: flex;
  gap: 8px;
}

.btn-edit,
.btn-delete {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  padding: 8px 12px;
  border: none;
  border-radius: 6px;
  font-size: 13px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s;
}

.btn-edit svg,
.btn-delete svg {
  width: 16px;
  height: 16px;
}

.btn-edit {
  background: #eff6ff;
  color: #2563eb;
}
.btn-edit:hover {
  background: #dbecfe;
}

.btn-delete {
  background: #fef2f2;
  color: #dc2626;
}
.btn-delete:hover {
  background: #fee2e2;
}

.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(17, 24, 39, 0.6);
  backdrop-filter: blur(4px);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
  padding: 20px;
  animation: fadeIn 0.2s ease-out;
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
  background: white;
  border-radius: 16px;
  width: 100%;
  max-width: 480px;
  max-height: 90vh;
  overflow-y: auto;
  box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.25);
  animation: slideUp 0.3s ease-out;
}

.modal-content.modal-lg {
  max-width: 650px;
}

@keyframes slideUp {
  from {
    opacity: 0;
    transform: translateY(20px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

.modal-content h3 {
  font-size: 20px;
  font-weight: 600;
  color: #111827;
  margin: 0;
  padding: 24px 24px 16px;
  border-bottom: 1px solid #f3f4f6;
}

form {
  padding: 24px;
}

/* Grid layout for complex forms */
.form-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 16px 20px;
}

.form-group {
  margin-bottom: 16px;
}
.form-grid .form-group {
  margin-bottom: 0; /* Let gap handle spacing */
}

.form-group label {
  display: block;
  font-size: 13px;
  font-weight: 600;
  color: #4b5563;
  margin-bottom: 6px;
}

.form-group input,
.form-group select {
  width: 100%;
  padding: 10px 14px;
  border: 1px solid #d1d5db;
  border-radius: 8px;
  font-size: 14px;
  color: #111827;
  background: #fff;
  transition: all 0.2s;
  box-sizing: border-box;
}

.form-group input:hover,
.form-group select:hover {
  border-color: #9ca3af;
}

.form-group input:focus,
.form-group select:focus {
  outline: none;
  border-color: #3b82f6;
  box-shadow: 0 0 0 4px rgba(59, 130, 246, 0.1);
}

.modal-actions {
  display: flex;
  gap: 12px;
  justify-content: flex-end;
  margin-top: 32px;
  padding-top: 20px;
  border-top: 1px solid #f3f4f6;
  grid-column: 1 / -1;
}

.btn-cancel,
.btn-save {
  padding: 10px 20px;
  border-radius: 8px;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s;
}

.btn-cancel {
  background: white;
  color: #4b5563;
  border: 1px solid #d1d5db;
}

.btn-cancel:hover {
  background: #f9fafb;
  color: #111827;
}

.btn-save {
  background: #3b82f6;
  color: white;
  border: none;
  box-shadow: 0 4px 6px -1px rgba(59, 130, 246, 0.2);
}

.btn-save:hover:not(:disabled) {
  background: #2563eb;
}

.btn-save:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.loading-message,
.error-message {
  text-align: center;
  padding: 80px 40px;
  color: #4b5563;
  background: white;
  border-radius: 12px;
  box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.05);
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 16px;
  font-size: 15px;
  font-weight: 500;
}

.spinner {
  width: 36px;
  height: 36px;
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

.error-message {
  color: #dc2626;
  background: #fef2f2;
}

@media (max-width: 768px) {
  .filters {
    flex-direction: column;
  }

  .filters input,
  .filters select {
    min-width: 100%;
    width: 100%;
  }

  .table-container {
    overflow-x: auto;
  }

  .form-grid {
    grid-template-columns: 1fr;
  }

  .modal-content {
    margin: 0 16px;
    height: auto;
    max-height: 90vh;
  }
}
</style>
