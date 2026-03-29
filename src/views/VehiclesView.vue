<script setup>
import { ref, onMounted, computed, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import apiClient from '../api/axios'
import Swal from 'sweetalert2'

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

// สถานะของ Modal แก้ไขสถานะ/คนขับ
const isEditModalOpen = ref(false)
const editForm = ref({
  id: '',
  license_plate: '',
  status: '',
  driver_id: '',
})

// สถานะของ Modal แก้ไขรายละเอียดรถ (Admin Only)
const isEditDetailsModalOpen = ref(false)
const editDetailsForm = ref({
  id: '',
  license_plate: '',
  type: '',
  brand: '',
  model: '',
  year: '',
  fuel_type: '',
  mileage_km: 0,
  next_service_km: '',
})

// Validation State
const fieldErrors = ref({})
const isSaving = ref(false)

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
  fieldErrors.value = {}
  isAddModalOpen.value = true
}

const closeAddModal = () => {
  isAddModalOpen.value = false
}

const saveNewVehicle = async () => {
  try {
    isSaving.value = true
    fieldErrors.value = {}

    await apiClient.post('/vehicles', addForm.value)
    closeAddModal()
    await fetchVehicles()

    Swal.fire({
      title: 'สำเร็จ!',
      text: 'เพิ่มยานพาหนะใหม่เรียบร้อยแล้ว',
      icon: 'success',
      confirmButtonText: 'ตกลง',
      confirmButtonColor: '#3b82f6',
    })
  } catch (error) {
     console.log('🚨 API Error Response:', error.response?.data)
    const errorResponse = error.response?.data?.error
    if (errorResponse && errorResponse.code === 'VALIDATION_ERROR' && errorResponse.details) {
      fieldErrors.value = errorResponse.details
    } else {
      Swal.fire({
        title: 'ผิดพลาด',
        text: errorResponse?.message || error.message,
        icon: 'error',
        confirmButtonText: 'ตกลง',
        confirmButtonColor: '#ef4444',
      })
    }
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
  const result = await Swal.fire({
    title: 'ยืนยันการลบ?',
    text: `คุณต้องการลบยานพาหนะ ${licensePlate} ใช่หรือไม่?`,
    icon: 'warning',
    showCancelButton: true,
    confirmButtonColor: '#ef4444',
    cancelButtonColor: '#64748b',
    confirmButtonText: 'ใช่, ลบเลย',
    cancelButtonText: 'ยกเลิก',
  })

  if (!result.isConfirmed) return

  try {
    await apiClient.delete(`/vehicles/${id}`)
    // ลบรถคันนั้นออกจากรายการในหน้าจอโดยไม่ต้องโหลดใหม่ทั้งหมด
    vehicles.value = vehicles.value.filter((v) => v.id !== id)

    Swal.fire({
      title: 'ลบสำเร็จ!',
      text: `ลบยานพาหนะ ${licensePlate} เรียบร้อยแล้ว`,
      icon: 'success',
      confirmButtonColor: '#3b82f6',
    })
  } catch (error) {
    Swal.fire({
      title: 'เกิดข้อผิดพลาด',
      text: error.response?.data?.error?.message || 'ไม่สามารถลบยานพาหนะได้',
      icon: 'error',
      confirmButtonColor: '#ef4444',
    })
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

    Swal.fire({
      title: 'อัปเดตสำเร็จ!',
      text: 'บันทึกข้อมูลสถานะและคนขับเรียบร้อยแล้ว',
      icon: 'success',
      confirmButtonText: 'ตกลง',
      confirmButtonColor: '#3b82f6',
      timer: 1500,
    })
  } catch (error) {
    Swal.fire({
      title: 'ผิดพลาด',
      text: error.response?.data?.error?.message || 'ไม่สามารถอัปเดตข้อมูลได้',
      icon: 'error',
      confirmButtonColor: '#ef4444',
    })
    console.error('Failed to update vehicle status/driver:', error)
  } finally {
    isSaving.value = false
  }
}

// ฟังก์ชันสำหรับจัดการ Modal แก้ไขรายละเอียดแบบเต็มรูปแบบ (Admin)
const openEditDetailsModal = (vehicle) => {
  editDetailsForm.value = {
    id: vehicle.id,
    license_plate: vehicle.license_plate,
    type: vehicle.type || 'TRUCK',
    brand: vehicle.brand || '',
    model: vehicle.model || '',
    year: vehicle.year || '',
    fuel_type: vehicle.fuel_type || 'DIESEL',
    mileage_km: vehicle.mileage_km || 0,
    next_service_km: vehicle.next_service_km || '',
  }
  fieldErrors.value = {}
  isEditDetailsModalOpen.value = true
}

const closeEditDetailsModal = () => {
  isEditDetailsModalOpen.value = false
}

const saveVehicleDetails = async () => {
  try {
    isSaving.value = true
    fieldErrors.value = {}
    
    await apiClient.patch(`/vehicles/${editDetailsForm.value.id}/details`, editDetailsForm.value)
    
    await fetchVehicles()
    closeEditDetailsModal()
    
    Swal.fire({
      title: 'อัปเดตสำเร็จ!',
      text: 'แก้ไขรายละเอียดข้อมูลรถเรียบร้อยแล้ว',
      icon: 'success',
      confirmButtonText: 'ตกลง',
      confirmButtonColor: '#3b82f6',
      timer: 1500,
    })
  } catch (error) {
    console.log('🚨 API Error Response:', error.response?.data)
    const errorResponse = error.response?.data?.error
    if (errorResponse && errorResponse.code === 'VALIDATION_ERROR' && errorResponse.details) {
      fieldErrors.value = errorResponse.details
    } else {
      Swal.fire({
        title: 'เกิดข้อผิดพลาด',
        text: errorResponse?.message || error.message,
        icon: 'error',
        confirmButtonText: 'ตกลง',
        confirmButtonColor: '#ef4444',
      })
    }
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
            <th>ป้ายทะเบียน</th>
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
                สถานะ
              </button>
              <button v-if="isAdmin" @click="openEditDetailsModal(vehicle)" class="btn-edit-details">
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke-width="1.5"
                  stroke="currentColor"
                >
                  <path stroke-linecap="round" stroke-linejoin="round" d="m11.25 11.25.041-.02a.75.75 0 0 1 1.063.852l-.708 2.836a.75.75 0 0 0 1.063.853l.041-.021M21 12a9 9 0 1 1-18 0 9 9 0 0 1 18 0Zm-9-3.75h.008v.008H12V8.25Z" />
                </svg>
                รายละเอียด
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

    <!-- Modal สำหรับแก้ไขสถานะ/คนขับ -->
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

    <!-- Modal สำหรับแก้ไขรายละเอียดแบบเต็มสูบ (Admin Only) -->
    <div v-if="isEditDetailsModalOpen" class="modal-overlay">
      <div class="modal-content modal-lg">
        <h3>แก้ไขรายละเอียดรถ ({{ editDetailsForm.license_plate }})</h3>
        <form @submit.prevent="saveVehicleDetails">
          <div class="form-grid">
            <div class="form-group">
              <label for="edit-license">ป้ายทะเบียน <span class="required">*</span></label>
              <input
                id="edit-license"
                v-model="editDetailsForm.license_plate"
                :class="{ 'has-error': fieldErrors.license_plate }"
              />
              <span v-if="fieldErrors.license_plate" class="error-text">{{ fieldErrors.license_plate }}</span>
            </div>

            <div class="form-group">
              <label for="edit-type">ประเภท <span class="required">*</span></label>
              <select id="edit-type" v-model="editDetailsForm.type" :class="{ 'has-error': fieldErrors.type }">
                <option value="TRUCK">TRUCK</option>
                <option value="VAN">VAN</option>
                <option value="MOTORCYCLE">MOTORCYCLE</option>
                <option value="PICKUP">PICKUP</option>
              </select>
              <span v-if="fieldErrors.type" class="error-text">{{ fieldErrors.type }}</span>
            </div>

            <div class="form-group">
              <label for="edit-brand">ยี่ห้อ</label>
              <input id="edit-brand" v-model="editDetailsForm.brand" :class="{ 'has-error': fieldErrors.brand }" />
              <span v-if="fieldErrors.brand" class="error-text">{{ fieldErrors.brand }}</span>
            </div>

            <div class="form-group">
              <label for="edit-model">รุ่น</label>
              <input id="edit-model" v-model="editDetailsForm.model" :class="{ 'has-error': fieldErrors.model }" />
              <span v-if="fieldErrors.model" class="error-text">{{ fieldErrors.model }}</span>
            </div>

            <div class="form-group">
              <label for="edit-year">ปี</label>
              <input
                id="edit-year"
                v-model="editDetailsForm.year"
                type="number"
                :class="{ 'has-error': fieldErrors.year }"
              />
              <span v-if="fieldErrors.year" class="error-text">{{ fieldErrors.year }}</span>
            </div>

            <div class="form-group">
              <label for="edit-fuel">ประเภทน้ำมัน</label>
              <select id="edit-fuel" v-model="editDetailsForm.fuel_type" :class="{ 'has-error': fieldErrors.fuel_type }">
                <option value="DIESEL">DIESEL</option>
                <option value="GASOLINE">GASOLINE</option>
                <option value="ELECTRIC">ELECTRIC</option>
                <option value="HYBRID">HYBRID</option>
              </select>
              <span v-if="fieldErrors.fuel_type" class="error-text">{{ fieldErrors.fuel_type }}</span>
            </div>

            <div class="form-group">
              <label for="edit-mileage">เลขไมล์ (กม.)</label>
              <input id="edit-mileage" v-model.number="editDetailsForm.mileage_km" type="number" :class="{ 'has-error': fieldErrors.mileage_km }" />
              <span v-if="fieldErrors.mileage_km" class="error-text">{{ fieldErrors.mileage_km }}</span>
            </div>

            <div class="form-group">
              <label for="edit-next-service">กำหนดรับบริการครั้งต่อไป (กม.)</label>
              <input
                id="edit-next-service"
                v-model.number="editDetailsForm.next_service_km"
                type="number"
                :class="{ 'has-error': fieldErrors.next_service_km }"
              />
              <span v-if="fieldErrors.next_service_km" class="error-text">{{ fieldErrors.next_service_km }}</span>
            </div>
          </div>

          <div class="modal-actions">
            <button type="button" @click="closeEditDetailsModal" class="btn-cancel">ยกเลิก</button>
            <button type="submit" class="btn-save" :disabled="isSaving">
              {{ isSaving ? 'กำลังบันทึก...' : 'บันทึก' }}
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
              <label for="add-license">ป้ายทะเบียน <span class="required">*</span></label>
              <input
                id="add-license"
                v-model="addForm.license_plate"
                :class="{ 'has-error': fieldErrors.license_plate }"
                placeholder="เช่น กท-1234"
              />
              <span v-if="fieldErrors.license_plate" class="error-text">{{ fieldErrors.license_plate }}</span>
            </div>

            <div class="form-group">
              <label for="add-type">ประเภท <span class="required">*</span></label>
              <select id="add-type" v-model="addForm.type" :class="{ 'has-error': fieldErrors.type }">
                <option value="TRUCK">TRUCK</option>
                <option value="VAN">VAN</option>
                <option value="MOTORCYCLE">MOTORCYCLE</option>
                <option value="PICKUP">PICKUP</option>
              </select>
              <span v-if="fieldErrors.type" class="error-text">{{ fieldErrors.type }}</span>
            </div>

            <div class="form-group">
              <label for="add-status">สถานะ</label>
              <select id="add-status" v-model="addForm.status" :class="{ 'has-error': fieldErrors.status }">
                <option value="IDLE">IDLE</option>
                <option value="ACTIVE">ACTIVE</option>
                <option value="MAINTENANCE">MAINTENANCE</option>
                <option value="RETIRED">RETIRED</option>
              </select>
              <span v-if="fieldErrors.status" class="error-text">{{ fieldErrors.status }}</span>
            </div>

            <div class="form-group">
              <label for="add-driver">มอบหมายคนขับ</label>
              <select id="add-driver" v-model="addForm.driver_id" :class="{ 'has-error': fieldErrors.driver_id }">
                <option value="">-- ไม่มีคนขับ --</option>
                <option v-for="driver in drivers" :key="driver.id" :value="driver.id">
                  {{ driver.name }} ({{ driver.license_number }})
                </option>
              </select>
              <span v-if="fieldErrors.driver_id" class="error-text">{{ fieldErrors.driver_id }}</span>
            </div>

            <div class="form-group">
              <label for="add-brand">ยี่ห้อ</label>
              <input id="add-brand" v-model="addForm.context.brand" :class="{ 'has-error': fieldErrors.brand }" placeholder="เช่น Isuzu" />
              <span v-if="fieldErrors.brand" class="error-text">{{ fieldErrors.brand }}</span>
            </div>

            <div class="form-group">
              <label for="add-model">รุ่น</label>
              <input id="add-model" v-model="addForm.context.model" :class="{ 'has-error': fieldErrors.model }" placeholder="เช่น D-Max" />
              <span v-if="fieldErrors.model" class="error-text">{{ fieldErrors.model }}</span>
            </div>

            <div class="form-group">
              <label for="add-year">ปี</label>
              <input
                id="add-year"
                v-model="addForm.context.year"
                type="number"
                :class="{ 'has-error': fieldErrors.year }"
                placeholder="เช่น 2024"
              />
              <span v-if="fieldErrors.year" class="error-text">{{ fieldErrors.year }}</span>
            </div>

            <div class="form-group">
              <label for="add-fuel">ประเภทน้ำมัน</label>
              <select id="add-fuel" v-model="addForm.context.fuel_type" :class="{ 'has-error': fieldErrors.fuel_type }">
                <option value="DIESEL">DIESEL</option>
                <option value="GASOLINE">GASOLINE</option>
                <option value="ELECTRIC">ELECTRIC</option>
                <option value="HYBRID">HYBRID</option>
              </select>
              <span v-if="fieldErrors.fuel_type" class="error-text">{{ fieldErrors.fuel_type }}</span>
            </div>

            <div class="form-group">
              <label for="add-mileage">เลขไมล์ (กม.)</label>
              <input id="add-mileage" v-model.number="addForm.context.mileage_km" type="number" :class="{ 'has-error': fieldErrors.mileage_km }" />
              <span v-if="fieldErrors.mileage_km" class="error-text">{{ fieldErrors.mileage_km }}</span>
            </div>

            <div class="form-group">
              <label for="add-next-service">กำหนดรับบริการครั้งต่อไป (กม.)</label>
              <input
                id="add-next-service"
                v-model.number="addForm.context.next_service_km"
                type="number"
                :class="{ 'has-error': fieldErrors.next_service_km }"
                placeholder="เช่น 50000"
              />
              <span v-if="fieldErrors.next_service_km" class="error-text">{{ fieldErrors.next_service_km }}</span>
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
  width: 100%;
}

.header-actions {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 2rem;
}

h2 {
  margin: 0;
  color: #1a202c;
  font-size: 1.75rem;
  font-weight: 700;
}

.btn-add {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 12px 20px;
  background: linear-gradient(135deg, #3b82f6 0%, #2563eb 100%);
  color: white;
  border: none;
  border-radius: 12px;
  font-size: 15px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
  box-shadow: 0 4px 12px rgba(37, 99, 235, 0.2);
}

.btn-add svg {
  width: 20px;
  height: 20px;
}
.btn-add:hover {
  transform: translateY(-2px);
  box-shadow: 0 8px 16px rgba(37, 99, 235, 0.3);
}

.filters {
  display: flex;
  gap: 16px;
  margin-bottom: 24px;
  padding: 1.5rem;
  background: #f8fafc;
  border: 1px solid rgba(226, 232, 240, 0.8);
  border-radius: 12px;
  flex-wrap: wrap;
}

.filters select,
.filters input {
  padding: 12px 16px;
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  font-size: 14px;
  background: #f8fafc;
  color: #334155;
  transition: all 0.2s;
  flex: 1;
  min-width: 150px;
}

.filters input {
  min-width: 280px;
  flex: 2;
}

.filters select:hover,
.filters input:hover {
  border-color: #cbd5e1;
  background: #fff;
}
.filters select:focus,
.filters input:focus {
  outline: none;
  background: white;
  border-color: #3b82f6;
  box-shadow: 0 0 0 4px rgba(59, 130, 246, 0.1);
}

.has-error {
  border-color: #ef4444 !important;
  background-color: #fef2f2 !important;
}

.error-text {
  display: block;
  font-size: 12px;
  color: #ef4444;
  margin-top: 4px;
  font-weight: 500;
}

.required {
  color: #ef4444;
}

.table-container {
  background-color: #fff;
  padding: 2.5rem;
  border-radius: 12px;
  box-shadow:
    0 10px 15px -3px rgba(0, 0, 0, 0.05),
    0 4px 6px -2px rgba(0, 0, 0, 0.025);
  overflow-x: auto;
}

table {
  width: 100%;
  border-collapse: separate;
  border-spacing: 0;
}

thead {
  background: #f8fafc;
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
  font-size: 14px;
  color: #334155;
  border-bottom: 1px solid #f1f5f9;
  vertical-align: middle;
}

tbody tr {
  transition: all 0.2s ease;
}
tbody tr:hover {
  background-color: #f8fafc;
}
tbody tr:last-child td {
  border-bottom: none;
}

.license-plate {
  font-weight: 700;
  color: #0f172a;
  font-size: 15px;
}

.type-badge {
  display: inline-block;
  padding: 6px 12px;
  background: #f1f5f9;
  color: #475569;
  border-radius: 8px;
  font-size: 12px;
  font-weight: 600;
  letter-spacing: 0.025em;
  border: 1px solid #e2e8f0;
}

.status-badge {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  padding: 6px 14px;
  border-radius: 20px;
  font-size: 12px;
  font-weight: 600;
}
.status-badge::before {
  content: '';
  width: 8px;
  height: 8px;
  border-radius: 50%;
  box-shadow: inset 0 0 0 2px rgba(255, 255, 255, 0.5);
}

.status-badge.status-active {
  background: #dcfce7;
  color: #166534;
  border: 1px solid #bbf7d0;
}
.status-badge.status-active::before {
  background: #22c55e;
}

.status-badge.status-idle {
  background: #dbeafe;
  color: #1e40af;
  border: 1px solid #bfdbfe;
}
.status-badge.status-idle::before {
  background: #3b82f6;
}

.status-badge.status-maintenance {
  background: #fef3c7;
  color: #92400e;
  border: 1px solid #fde68a;
}
.status-badge.status-maintenance::before {
  background: #f59e0b;
}

.status-badge.status-retired {
  background: #f1f5f9;
  color: #475569;
  border: 1px solid #e2e8f0;
}
.status-badge.status-retired::before {
  background: #94a3b8;
}

.vehicle-detail {
  color: #64748b;
  font-size: 14px;
  font-weight: 500;
}

.mileage {
  font-weight: 600;
  color: #334155;
  background: #f1f5f9;
  padding: 6px 12px;
  border-radius: 8px;
  font-size: 13px;
  border: 1px solid #e2e8f0;
}

.action-cell {
  display: flex;
  gap: 8px;
}

.btn-edit,
.btn-edit-details,
.btn-delete {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  padding: 8px 14px;
  border: none;
  border-radius: 8px;
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
  background: white;
  color: #3b82f6;
  border: 1px solid #bfdbfe;
}
.btn-edit:hover {
  background: #eff6ff;
  border-color: #3b82f6;
}

.btn-edit-details {
  background: #eff6ff;
  color: #2563eb;
  border: 1px solid #dbeafe;
}
.btn-edit-details:hover {
  background: #dbeafe;
  color: #1d4ed8;
}

.btn-delete {
  background: white;
  color: #ef4444;
  border: 1px solid #fecaca;
}
.btn-delete:hover {
  background: #fef2f2;
  border-color: #ef4444;
}

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
  background: white;
  border-radius: 20px;
  width: 100%;
  max-width: 480px;
  max-height: 90vh;
  overflow-y: auto;
  box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.25);
  animation: slideUp 0.4s cubic-bezier(0.16, 1, 0.3, 1);
}

.modal-content.modal-lg {
  max-width: 650px;
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
  font-size: 22px;
  font-weight: 700;
  color: #0f172a;
  margin: 0;
  padding: 24px 32px;
  border-bottom: 1px solid #e2e8f0;
  background: #f8fafc;
  position: sticky;
  top: 0;
  z-index: 10;
}

form {
  padding: 32px;
}

.form-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 20px 24px;
}
.form-group {
  margin-bottom: 20px;
}
.form-grid .form-group {
  margin-bottom: 0;
}

.form-group label {
  display: block;
  font-size: 13px;
  font-weight: 600;
  color: #475569;
  margin-bottom: 8px;
}

.form-group input,
.form-group select {
  width: 100%;
  padding: 12px 16px;
  border: 1px solid #cbd5e1;
  border-radius: 10px;
  font-size: 14px;
  color: #0f172a;
  background: #fff;
  transition: all 0.2s;
  box-sizing: border-box;
}

.form-group input:hover,
.form-group select:hover {
  border-color: #94a3b8;
}
.form-group input:focus,
.form-group select:focus {
  outline: none;
  border-color: #3b82f6;
  box-shadow: 0 0 0 4px rgba(59, 130, 246, 0.15);
}

.modal-actions {
  display: flex;
  gap: 12px;
  justify-content: flex-end;
  margin-top: 32px;
  padding-top: 24px;
  border-top: 1px solid #e2e8f0;
  grid-column: 1 / -1;
}

.btn-cancel,
.btn-save {
  padding: 12px 24px;
  border-radius: 10px;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s;
}

.btn-cancel {
  background: white;
  color: #64748b;
  border: 1px solid #cbd5e1;
}
.btn-cancel:hover {
  background: #f1f5f9;
  color: #0f172a;
  border-color: #94a3b8;
}

.btn-save {
  background: linear-gradient(135deg, #3b82f6 0%, #2563eb 100%);
  color: white;
  border: none;
  box-shadow: 0 4px 12px rgba(37, 99, 235, 0.2);
}
.btn-save:hover:not(:disabled) {
  transform: translateY(-1px);
  box-shadow: 0 6px 16px rgba(37, 99, 235, 0.3);
}
.btn-save:disabled {
  opacity: 0.6;
  cursor: not-allowed;
  transform: none;
  box-shadow: none;
}

.loading-message,
.error-message {
  text-align: center;
  padding: 80px 40px;
  color: #64748b;
  background: white;
  border-radius: 16px;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.03);
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 16px;
  font-size: 15px;
  font-weight: 500;
}

.spinner {
  width: 40px;
  height: 40px;
  border: 3px solid #f1f5f9;
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
  color: #ef4444;
  background: #fef2f2;
  border: 1px solid #fecaca;
}

@media (max-width: 768px) {
  .vehicles-page {
    padding: 16px;
  }
  .filters {
    flex-direction: column;
    padding: 16px;
  }
  .filters input,
  .filters select {
    min-width: 100%;
    width: 100%;
  }
  .table-container {
    overflow-x: auto;
    border-radius: 12px;
  }
  .form-grid {
    grid-template-columns: 1fr;
    gap: 16px;
  }
  .modal-content {
    margin: 0 16px;
    height: auto;
    max-height: 90vh;
  }
  form {
    padding: 20px;
  }
  .modal-content h3 {
    padding: 20px;
  }
}
</style>
