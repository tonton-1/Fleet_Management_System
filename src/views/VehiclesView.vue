<script setup>
import { ref, onMounted, computed, watch, onUnmounted } from 'vue'
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

const isStatusOpen = ref(false)
const isTypeOpen = ref(false)

const statusOptions = [
  { value: '', label: 'ทุกสถานะ', colorClass: 'status-gray' },
  { value: 'IDLE', label: 'ว่าง', colorClass: 'status-idle' },
  { value: 'ACTIVE', label: 'ใช้งาน', colorClass: 'status-active' },
  { value: 'MAINTENANCE', label: 'ซ่อมบำรุง', colorClass: 'status-maintenance' },
  { value: 'RETIRED', label: 'เลิกใช้', colorClass: 'status-retired' },
]

const typeOptions = [
  {
    value: '',
    label: 'ทุกประเภท',
    iconSvg: `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 448 512" width="16" height="16" fill="currentColor"><path d="M64 32C28.7 32 0 60.7 0 96V416c0 35.3 28.7 64 64 64H384c35.3 0 64-28.7 64-64V96c0-35.3-28.7-64-64-64H64zM192 256H48V96c0-8.8 7.2-16 16-16H192V256zm64 0V80H384c8.8 0 16 7.2 16 16V256H256zM48 320H192V432H64c-8.8 0-16-7.2-16-16V320zm208 0H400V416c0 8.8-7.2 16-16 16H256V320z"/></svg>`,
  },
  {
    value: 'TRUCK',
    label: 'รถบรรทุก',
    iconSvg: `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 640 512" width="16" height="16" fill="currentColor"><path d="M48 0C21.5 0 0 21.5 0 48V368c0 26.5 21.5 48 48 48H64c0 53 43 96 96 96s96-43 96-96H384c0 53 43 96 96 96s96-43 96-96h32c17.7 0 32-14.3 32-32s-14.3-32-32-32V288 256 237.3c0-17-6.7-33.3-18.7-45.3L512 114.7c-12-12-28.3-18.7-45.3-18.7H416V48c0-26.5-21.5-48-48-48H48zM416 160h50.7L544 237.3V256H416V160zM112 416a32 32 0 1 1 64 0 32 32 0 1 1 -64 0zm368-32a32 32 0 1 1 0 64 32 32 0 1 1 0-64z"/></svg>`,
  },
  {
    value: 'VAN',
    label: 'รถตู้',
    iconSvg: `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 640 512" width="16" height="16" fill="currentColor"><path d="M48 64C21.5 64 0 85.5 0 112v256c0 26.5 21.5 48 48 48H64c0 53 43 96 96 96s96-43 96-96H448l68.7 8.3a24.1 24.1 0 0 0 20.3-6.6l54.8-54.8a24 24 0 0 0 7-17V178.6c0-13.8-6.1-26.9-16.7-35.7L521 95C499.7 77.2 472.9 67.5 444.8 67.5H416V64c0-26.5-21.5-48-48-48H48zM576 256v66l-50.6 50.6L448 368V256h128zM416 368H256V256h160v112zM224 256v112H48V256h176zM112 416a32 32 0 1 1 64 0 32 32 0 1 1 -64 0z"/></svg>`,
  },
  {
    value: 'MOTORCYCLE',
    label: 'มอเตอร์ไซค์',
    iconSvg: `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 640 512" width="16" height="16" fill="currentColor"><path d="M288 128a64 64 0 1 0 -128 0 64 64 0 1 0 128 0zM187.3 226l-11.4 34.3c-2.3 6.9-9.1 11.7-16.4 11.7H96c-17.7 0-32-14.3-32-32s14.3-32 32-32h41.7l16.2-48.6C121 154.2 96 148.6 96 128c0-35.3 28.7-64 64-64s64 28.7 64 64c0 14.8-5.1 28.4-13.6 39.1l20.4 61.3 64-25.6V128c0-17.7 14.3-32 32-32s32 14.3 32 32v150L241 334.6c-4.4 2.2-9.7 1.5-13.5-1.9s-5.5-8.5-4-13.3l13.8-41.4-50-52.1zM112 480a80 80 0 1 1 0-160 80 80 0 1 1 0 160zm0-112a32 32 0 1 0 0 64 32 32 0 1 0 0-64zm351.6-47c43 2.1 79.5 32 87.2 74l23.5 125.6c2.6 13.9-6.6 27-20.5 29.6s-27-6.6-29.6-20.5l-19.1-102.1c-1.3-6.9-7-12.2-13.9-13.1l-60.5-8-12.8 19.3c-14.9 22.3-38 37.1-64.2 41.2V480c0 17.7-14.3 32-32 32s-32-14.3-32-32V384c0-22.1 11-42.8 29.4-55l104.4-69.6 40.1-40.1zM528 480a80 80 0 1 1 0-160 80 80 0 1 1 0 160zm0-112a32 32 0 1 0 0 64 32 32 0 1 0 0-64z"/></svg>`,
  },
  {
    value: 'PICKUP',
    label: 'รถกระบะ',
    iconSvg: `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 640 512" width="16" height="16" fill="currentColor"><path d="M64 32C28.7 32 0 60.7 0 96V304v80 16c0 17.7 14.3 32 32 32H64c0 53 43 96 96 96s96-43 96-96H384c0 53 43 96 96 96s96-43 96-96h32c17.7 0 32-14.3 32-32V304c0-22.6-10.1-44.1-27.7-58.1l-102-81.6C495 152 475.2 144 454.6 144H416V96c0-35.3-28.7-64-64-64H64zM416 208v96H320V208h96zm85.6-16l81.6 65.3c8.8 7 13.9 17.8 13.9 29.1V304H448V192h6.6c10.3 0 20.2 4 27.5 11.2l4 3.2zM112 416a32 32 0 1 1 64 0 32 32 0 1 1 -64 0zm368-32a32 32 0 1 1 0 64 32 32 0 1 1 0-64z"/></svg>`,
  },
]

const currentStatusOption = computed(() => {
  return statusOptions.find((o) => o.value === filters.value.status) || statusOptions[0]
})

const currentTypeOption = computed(() => {
  return typeOptions.find((o) => o.value === filters.value.type) || typeOptions[0]
})

const selectStatus = (val) => {
  filters.value.status = val
  isStatusOpen.value = false
}

const selectType = (val) => {
  filters.value.type = val
  isTypeOpen.value = false
}

const closeDropdowns = (e) => {
  if (!e.target.closest('.custom-dropdown.status-filter')) {
    isStatusOpen.value = false
  }
  if (!e.target.closest('.custom-dropdown.type-filter')) {
    isTypeOpen.value = false
  }
}

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

  document.addEventListener('click', closeDropdowns)
  initFiltersFromURL()
  fetchVehicles()
  fetchDrivers() // ดึงข้อมูลคนขับเตรียมไว้สำหรับ Dropdown
})

onUnmounted(() => {
  document.removeEventListener('click', closeDropdowns)
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
        <div class="filter-group">
          <label class="filter-label">สถานะ</label>
          <div class="custom-dropdown status-filter">
            <div class="dropdown-trigger" @click="isStatusOpen = !isStatusOpen">
              <span
                v-if="currentStatusOption.value !== ''"
                :class="['dot-indicator', currentStatusOption.colorClass]"
              ></span>
              <span>{{ currentStatusOption.label }}</span>
              <svg
                xmlns="http://www.w3.org/2000/svg"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
                stroke-width="2"
                class="chevron"
                :class="{ 'chevron-up': isStatusOpen }"
              >
                <path stroke-linecap="round" stroke-linejoin="round" d="M19 9l-7 7-7-7" />
              </svg>
            </div>
            <Transition name="fade-slide">
              <div v-if="isStatusOpen" class="dropdown-menu">
                <div
                  v-for="opt in statusOptions"
                  :key="opt.value"
                  class="dropdown-item"
                  :class="{ active: filters.status === opt.value }"
                  @click="selectStatus(opt.value)"
                >
                  <span v-if="opt.value !== ''" :class="['dot-indicator', opt.colorClass]"></span>
                  <span v-else class="dot-indicator empty-dot"></span>
                  {{ opt.label }}
                  <!-- Checkmark -->
                  <svg
                    v-if="filters.status === opt.value"
                    xmlns="http://www.w3.org/2000/svg"
                    fill="none"
                    viewBox="0 0 24 24"
                    stroke="currentColor"
                    stroke-width="2"
                    class="check-icon"
                  >
                    <path stroke-linecap="round" stroke-linejoin="round" d="M5 13l4 4L19 7" />
                  </svg>
                </div>
              </div>
            </Transition>
          </div>
        </div>

        <div class="filter-group">
          <label class="filter-label">ประเภท</label>
          <div class="custom-dropdown type-filter">
            <div class="dropdown-trigger" @click="isTypeOpen = !isTypeOpen">
              <span
                v-if="currentTypeOption.value !== ''"
                :class="['dot-indicator', currentTypeOption.colorClass]"
              ></span>
              <span>{{ currentTypeOption.label }}</span>
              <svg
                xmlns="http://www.w3.org/2000/svg"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
                stroke-width="2"
                class="chevron"
                :class="{ 'chevron-up': isTypeOpen }"
              >
                <path stroke-linecap="round" stroke-linejoin="round" d="M19 9l-7 7-7-7" />
              </svg>
            </div>
            <Transition name="fade-slide">
              <div v-if="isTypeOpen" class="dropdown-menu">
                <div
                  v-for="opt in typeOptions"
                  :key="opt.value"
                  class="dropdown-item"
                  :class="{ active: filters.type === opt.value }"
                  @click="selectType(opt.value)"
                >
                  <span v-if="opt.value !== ''" :class="['dot-indicator', opt.colorClass]"></span>
                  <span v-else class="dot-indicator empty-dot"></span>
                  {{ opt.label }}
                  <!-- Checkmark -->
                  <svg
                    v-if="filters.type === opt.value"
                    xmlns="http://www.w3.org/2000/svg"
                    fill="none"
                    viewBox="0 0 24 24"
                    stroke="currentColor"
                    stroke-width="2"
                    class="check-icon"
                  >
                    <path stroke-linecap="round" stroke-linejoin="round" d="M5 13l4 4L19 7" />
                  </svg>
                </div>
              </div>
            </Transition>
          </div>
        </div>

        <div class="filter-group search-group">
          <label class="filter-label">ค้นหา</label>
          <input
            type="text"
            v-model="filters.search"
            placeholder="ค้นหาป้ายทะเบียน ยี่ห้อ รุ่น..."
          />
        </div>
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
              <button
                v-if="isAdmin"
                @click="openEditDetailsModal(vehicle)"
                class="btn-edit-details"
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
                    d="m11.25 11.25.041-.02a.75.75 0 0 1 1.063.852l-.708 2.836a.75.75 0 0 0 1.063.853l.041-.021M21 12a9 9 0 1 1-18 0 9 9 0 0 1 18 0Zm-9-3.75h.008v.008H12V8.25Z"
                  />
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
              <span v-if="fieldErrors.license_plate" class="error-text">{{
                fieldErrors.license_plate
              }}</span>
            </div>

            <div class="form-group">
              <label for="edit-type">ประเภท <span class="required">*</span></label>
              <select
                id="edit-type"
                v-model="editDetailsForm.type"
                :class="{ 'has-error': fieldErrors.type }"
              >
                <option value="TRUCK">TRUCK</option>
                <option value="VAN">VAN</option>
                <option value="MOTORCYCLE">MOTORCYCLE</option>
                <option value="PICKUP">PICKUP</option>
              </select>
              <span v-if="fieldErrors.type" class="error-text">{{ fieldErrors.type }}</span>
            </div>

            <div class="form-group">
              <label for="edit-brand">ยี่ห้อ</label>
              <input
                id="edit-brand"
                v-model="editDetailsForm.brand"
                :class="{ 'has-error': fieldErrors.brand }"
              />
              <span v-if="fieldErrors.brand" class="error-text">{{ fieldErrors.brand }}</span>
            </div>

            <div class="form-group">
              <label for="edit-model">รุ่น</label>
              <input
                id="edit-model"
                v-model="editDetailsForm.model"
                :class="{ 'has-error': fieldErrors.model }"
              />
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
              <select
                id="edit-fuel"
                v-model="editDetailsForm.fuel_type"
                :class="{ 'has-error': fieldErrors.fuel_type }"
              >
                <option value="DIESEL">DIESEL</option>
                <option value="GASOLINE">GASOLINE</option>
                <option value="ELECTRIC">ELECTRIC</option>
                <option value="HYBRID">HYBRID</option>
              </select>
              <span v-if="fieldErrors.fuel_type" class="error-text">{{
                fieldErrors.fuel_type
              }}</span>
            </div>

            <div class="form-group">
              <label for="edit-mileage">เลขไมล์ (กม.)</label>
              <input
                id="edit-mileage"
                v-model.number="editDetailsForm.mileage_km"
                type="number"
                :class="{ 'has-error': fieldErrors.mileage_km }"
              />
              <span v-if="fieldErrors.mileage_km" class="error-text">{{
                fieldErrors.mileage_km
              }}</span>
            </div>

            <div class="form-group">
              <label for="edit-next-service">กำหนดรับบริการครั้งต่อไป (กม.)</label>
              <input
                id="edit-next-service"
                v-model.number="editDetailsForm.next_service_km"
                type="number"
                :class="{ 'has-error': fieldErrors.next_service_km }"
              />
              <span v-if="fieldErrors.next_service_km" class="error-text">{{
                fieldErrors.next_service_km
              }}</span>
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
              <span v-if="fieldErrors.license_plate" class="error-text">{{
                fieldErrors.license_plate
              }}</span>
            </div>

            <div class="form-group">
              <label for="add-type">ประเภท <span class="required">*</span></label>
              <select
                id="add-type"
                v-model="addForm.type"
                :class="{ 'has-error': fieldErrors.type }"
              >
                <option value="TRUCK">TRUCK</option>
                <option value="VAN">VAN</option>
                <option value="MOTORCYCLE">MOTORCYCLE</option>
                <option value="PICKUP">PICKUP</option>
              </select>
              <span v-if="fieldErrors.type" class="error-text">{{ fieldErrors.type }}</span>
            </div>

            <div class="form-group">
              <label for="add-status">สถานะ</label>
              <select
                id="add-status"
                v-model="addForm.status"
                :class="{ 'has-error': fieldErrors.status }"
              >
                <option value="IDLE">IDLE</option>
                <option value="ACTIVE">ACTIVE</option>
                <option value="MAINTENANCE">MAINTENANCE</option>
                <option value="RETIRED">RETIRED</option>
              </select>
              <span v-if="fieldErrors.status" class="error-text">{{ fieldErrors.status }}</span>
            </div>

            <div class="form-group">
              <label for="add-driver">มอบหมายคนขับ</label>
              <select
                id="add-driver"
                v-model="addForm.driver_id"
                :class="{ 'has-error': fieldErrors.driver_id }"
              >
                <option value="">-- ไม่มีคนขับ --</option>
                <option v-for="driver in drivers" :key="driver.id" :value="driver.id">
                  {{ driver.name }} ({{ driver.license_number }})
                </option>
              </select>
              <span v-if="fieldErrors.driver_id" class="error-text">{{
                fieldErrors.driver_id
              }}</span>
            </div>

            <div class="form-group">
              <label for="add-brand">ยี่ห้อ</label>
              <input
                id="add-brand"
                v-model="addForm.context.brand"
                :class="{ 'has-error': fieldErrors.brand }"
                placeholder="เช่น Isuzu"
              />
              <span v-if="fieldErrors.brand" class="error-text">{{ fieldErrors.brand }}</span>
            </div>

            <div class="form-group">
              <label for="add-model">รุ่น</label>
              <input
                id="add-model"
                v-model="addForm.context.model"
                :class="{ 'has-error': fieldErrors.model }"
                placeholder="เช่น D-Max"
              />
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
              <select
                id="add-fuel"
                v-model="addForm.context.fuel_type"
                :class="{ 'has-error': fieldErrors.fuel_type }"
              >
                <option value="DIESEL">DIESEL</option>
                <option value="GASOLINE">GASOLINE</option>
                <option value="ELECTRIC">ELECTRIC</option>
                <option value="HYBRID">HYBRID</option>
              </select>
              <span v-if="fieldErrors.fuel_type" class="error-text">{{
                fieldErrors.fuel_type
              }}</span>
            </div>

            <div class="form-group">
              <label for="add-mileage">เลขไมล์ (กม.)</label>
              <input
                id="add-mileage"
                v-model.number="addForm.context.mileage_km"
                type="number"
                :class="{ 'has-error': fieldErrors.mileage_km }"
              />
              <span v-if="fieldErrors.mileage_km" class="error-text">{{
                fieldErrors.mileage_km
              }}</span>
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
              <span v-if="fieldErrors.next_service_km" class="error-text">{{
                fieldErrors.next_service_km
              }}</span>
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

  background: #ffffff;

  border-radius: 12px;
  flex-wrap: wrap;
}

.filter-group {
  display: flex;
  flex-direction: column;
  gap: 0.4rem;
  flex: 1;
  min-width: 150px;
}
.filter-group.search-group {
  flex: 2;
  min-width: 280px;
}
.filter-label {
  font-size: 0.85rem;
  font-weight: 600;
  color: #64748b;
  margin-left: 0.5rem;
}

.filters input {
  padding: 10px 16px;
  border: 1px solid #e2e8f0;
  border-radius: 9999px; /* matching the pill logic */
  font-size: 0.85rem;
  background: white;
  color: #334155;
  transition: all 0.2s;
  width: 100%;
  box-sizing: border-box;
}

.filters input:hover {
  background-color: #f8fafc;
  border-color: #cbd5e1;
}
.filters input:focus {
  outline: none;
  background: white;
  border-color: #3b82f6;
  box-shadow: 0 0 0 3px rgba(59, 130, 246, 0.1);
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
  background-color: white;
  border: 1px solid #e2e8f0;
  padding: 10px 16px;
  border-radius: 9999px;
  color: #4a5568;
  font-size: 0.85rem;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s ease;
  width: 100%;
  justify-content: space-between;
  box-sizing: border-box;
}

.dropdown-trigger:hover {
  background-color: #f8fafc;
  border-color: #cbd5e1;
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

.dot-indicator.status-gray {
  background-color: #94a3b8;
}
.dot-indicator.status-idle {
  background-color: #3b82f6;
}
.dot-indicator.status-active {
  background-color: #22c55e;
}
.dot-indicator.status-maintenance {
  background-color: #f59e0b;
}
.dot-indicator.status-retired {
  background-color: #64748b;
}

.dot-indicator.status-truck {
  background-color: #10b981;
}
.dot-indicator.status-van {
  background-color: #8b5cf6;
}
.dot-indicator.status-motorcycle {
  background-color: #ef4444;
}
.dot-indicator.status-pickup {
  background-color: #f97316;
}

.fade-slide-enter-active,
.fade-slide-leave-active {
  transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);
}
.fade-slide-enter-from,
.fade-slide-leave-to {
  opacity: 0;
  transform: translateY(-5px);
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
  .custom-dropdown {
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
