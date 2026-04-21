<script setup>
import { ref, onMounted, computed, onUnmounted } from 'vue'
import apiClient from '../api/axios'
import Swal from 'sweetalert2'

const drivers = ref([])
const filters = ref({
  status: '',
  search: '',
})

const isStatusOpen = ref(false)

const statusOptions = [
  { value: '', label: 'ทุกสถานะ', colorClass: 'status-gray' },
  { value: 'ACTIVE', label: 'ใช้งาน', colorClass: 'status-active' },
  { value: 'INACTIVE', label: 'ไม่ใช้งาน', colorClass: 'status-inactive' },
  { value: 'SUSPENDED', label: 'ถูกระงับ', colorClass: 'status-suspended' },
]

const currentStatusOption = computed(() => {
  return statusOptions.find(o => o.value === filters.value.status) || statusOptions[0]
})

const selectStatus = (val) => {
  filters.value.status = val
  isStatusOpen.value = false
}

const closeDropdowns = (e) => {
  if (!e.target.closest('.custom-dropdown.status-filter')) {
    isStatusOpen.value = false
  }
}

const filteredDrivers = computed(() => {
  return drivers.value.filter((d) => {
    if (filters.value.status && d.status !== filters.value.status) return false
    if (filters.value.search) {
      const s = filters.value.search.toLowerCase()
      if (
        !d.name.toLowerCase().includes(s) &&
        !d.license_number.toLowerCase().includes(s) &&
        !(d.phone && d.phone.includes(s))
      ) {
        return false
      }
    }
    return true
  })
})
const isLoading = ref(true)
const errorMessage = ref('')
const currentUserRole = ref('')

// สถานะของ Modal เพิ่มคนขับ
const isAddModalOpen = ref(false)
const isSaving = ref(false)

// สถานะของ Modal แก้ไขคนขับ
const isEditModalOpen = ref(false)
const editingDriverId = ref(null)
const isUpdating = ref(false)

// โมเดลข้อมูลสำหรับฟอร์มเพิ่ม
const newDriverForm = ref({
  name: '',
  license_number: '',
  license_expires_at: '',
  phone: '',
  status: 'ACTIVE',
})

// โมเดลข้อมูลสำหรับฟอร์มแก้ไข
const editDriverForm = ref({
  name: '',
  license_number: '',
  license_expires_at: '',
  phone: '',
  status: 'ACTIVE',
})

const fieldErrors = ref({})
const editFieldErrors = ref({})

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

const fetchDrivers = async () => {
  try {
    isLoading.value = true
    const response = await apiClient.get('/drivers')
    drivers.value = response.data
  } catch (error) {
    errorMessage.value = error.response?.data?.error?.message || 'Failed to fetch drivers data.'
    console.error('Failed to fetch drivers:', error)
  } finally {
    isLoading.value = false
  }
}

// ---- ADD DRIVER ----
const openAddModal = () => {
  newDriverForm.value = { name: '', license_number: '', license_expires_at: '', phone: '', status: 'ACTIVE' }
  fieldErrors.value = {}
  isAddModalOpen.value = true
}

const closeAddModal = () => {
  isAddModalOpen.value = false
  fieldErrors.value = {}
}

const saveNewDriver = async () => {
  try {
    isSaving.value = true
    fieldErrors.value = {}
    await apiClient.post('/drivers', newDriverForm.value)
    closeAddModal()
    alert('Driver added successfully.')
    await fetchDrivers()
  } catch (error) {
    const errorResponse = error.response?.data?.error
    if (errorResponse && errorResponse.details) {
      fieldErrors.value = errorResponse.details
    } else {
      alert(errorResponse?.message || 'Failed to add new driver.')
    }
    console.error('Failed to add driver:', error)
  } finally {
    isSaving.value = false
  }
}

// ---- EDIT DRIVER ----
const openEditModal = (driver) => {
  editingDriverId.value = driver.id
  // Format date to YYYY-MM-DD for input[type=date]
  const rawDate = driver.license_expires_at
  const formattedDate = rawDate ? rawDate.substring(0, 10) : ''
  editDriverForm.value = {
    name: driver.name,
    license_number: driver.license_number,
    license_expires_at: formattedDate,
    phone: driver.phone,
    status: driver.status,
  }
  editFieldErrors.value = {}
  isEditModalOpen.value = true
}

const closeEditModal = () => {
  isEditModalOpen.value = false
  editingDriverId.value = null
  editFieldErrors.value = {}
}

const saveEditDriver = async () => {
  try {
    isUpdating.value = true
    editFieldErrors.value = {}
    await apiClient.patch(`/drivers/${editingDriverId.value}`, editDriverForm.value)
    closeEditModal()
    Swal.fire({
      icon: 'success',
      title: 'อัปเดตสำเร็จ',
      text: 'แก้ไขข้อมูลคนขับเรียบร้อยแล้ว',
      confirmButtonColor: '#38a169',
      confirmButtonText: 'ตกลง',
      timer: 2000
    })
    await fetchDrivers()
  } catch (error) {
    const errorResponse = error.response?.data?.error
    if (errorResponse && errorResponse.details) {
      editFieldErrors.value = errorResponse.details
    } else {
      Swal.fire({
        icon: 'error',
        title: 'อัปเดตไม่สำเร็จ',
        text: errorResponse?.message || 'ไม่สามารถแก้ไขข้อมูลคนขับได้',
        confirmButtonColor: '#e53e3e',
        confirmButtonText: 'ปิด',
      })
    }
    console.error('Failed to update driver:', error)
  } finally {
    isUpdating.value = false
  }
}

// ---- DELETE DRIVER ----
const deleteDriver = async (driver) => {
  const result = await Swal.fire({
    title: 'ยืนยันการลบ?',
    html: `ต้องการลบคนขับ <strong>${driver.name}</strong> ออกจากระบบ?<br><small style="color:#718096">การดำเนินการนี้ไม่สามารถย้อนกลับได้</small>`,
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
    await apiClient.delete(`/drivers/${driver.id}`)
    await Swal.fire({
      title: 'ลบสำเร็จ!',
      text: `ลบ "${driver.name}" ออกจากระบบแล้ว`,
      icon: 'success',
      timer: 2000,
      timerProgressBar: true,
      showConfirmButton: false,
    })
    await fetchDrivers()
  } catch (error) {
    const msg = error.response?.data?.error?.message || 'Failed to delete driver.'
    Swal.fire({
      title: 'ไม่สามารถลบได้',
      text: msg,
      icon: 'error',
      confirmButtonColor: '#3182ce',
    })
    console.error('Failed to delete driver:', error)
  }
}

// ---- HELPERS ----
const formatDate = (dateString) => {
  if (!dateString) return 'N/A'
  const date = new Date(dateString)
  return date.toLocaleDateString('en-GB', { year: 'numeric', month: 'short', day: 'numeric' })
}

const isExpired = (dateString) => {
  if (!dateString) return false
  return new Date(dateString) < new Date()
}

const isAdmin = computed(() => currentUserRole.value === 'ADMIN')

onMounted(() => {
  const token = localStorage.getItem('accessToken')
  if (token) {
    const decoded = decodeToken(token)
    if (decoded && decoded.role) {
      currentUserRole.value = decoded.role
    }
  }
  document.addEventListener('click', closeDropdowns)
  fetchDrivers()
})

onUnmounted(() => {
  document.removeEventListener('click', closeDropdowns)
})
</script>

<template>
  <div class="drivers-page">
    <div v-if="isLoading" class="loading-message">Loading driver data...</div>
    <div v-else-if="errorMessage" class="error-message">{{ errorMessage }}</div>
    <div v-else class="table-container">
      <div class="header-actions">
        <h2>All Drivers</h2>
        <button v-if="isAdmin" @click="openAddModal" class="btn-add">
          <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="icon-small">
            <path stroke-linecap="round" stroke-linejoin="round" d="M12 4.5v15m7.5-7.5h-15" />
          </svg>
          Add Driver
        </button>
      </div>

      <div class="filters">
        <div class="custom-dropdown status-filter">
          <div class="dropdown-trigger" @click="isStatusOpen = !isStatusOpen">
            <span v-if="currentStatusOption.value !== ''" :class="['dot-indicator', currentStatusOption.colorClass]"></span>
            <span>{{ currentStatusOption.label }}</span>
            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2" class="chevron" :class="{ 'chevron-up': isStatusOpen }">
              <path stroke-linecap="round" stroke-linejoin="round" d="M19 9l-7 7-7-7" />
            </svg>
          </div>
          <Transition name="fade-slide">
            <div v-if="isStatusOpen" class="dropdown-menu">
              <div 
                v-for="opt in statusOptions" 
                :key="opt.value" 
                class="dropdown-item"
                :class="{ 'active': filters.status === opt.value }"
                @click="selectStatus(opt.value)"
              >
                <span v-if="opt.value !== ''" :class="['dot-indicator', opt.colorClass]"></span>
                <span v-else class="dot-indicator empty-dot"></span>
                {{ opt.label }}
                <!-- Checkmark -->
                <svg v-if="filters.status === opt.value" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2" class="check-icon">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M5 13l4 4L19 7" />
                </svg>
              </div>
            </div>
          </Transition>
        </div>
        
        <input type="text" v-model="filters.search" placeholder="ค้นหารายชื่อ, ใบขับขี่, หรือเบอร์โทร..." class="search-input" />
      </div>

      <div class="table-scroll-wrapper">
        <table>
          <thead>
            <tr>
              <th>Name</th>
              <th>License Number</th>
              <th>Expires At</th>
              <th>Phone</th>
              <th>Status</th>
              <th v-if="isAdmin">Actions</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="driver in filteredDrivers" :key="driver.id">
              <td class="font-medium">{{ driver.name }}</td>
              <td>{{ driver.license_number }}</td>
              <td>
                <span :class="{ 'text-danger font-medium': isExpired(driver.license_expires_at) }">
                  {{ formatDate(driver.license_expires_at) }}
                  <span v-if="isExpired(driver.license_expires_at)" class="expired-label">(Expired)</span>
                </span>
              </td>
              <td>{{ driver.phone }}</td>
              <td>
                <span :class="['status-badge', `status-${driver.status.toLowerCase()}`]">
                  {{ driver.status }}
                </span>
              </td>
              <td v-if="isAdmin" class="action-cell">
                <button @click="openEditModal(driver)" class="btn-edit" title="Edit">
                  <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" style="width: 1.25rem; height: 1.25rem;">
                    <path stroke-linecap="round" stroke-linejoin="round" d="m16.862 4.487 1.687-1.688a1.875 1.875 0 1 1 2.652 2.652L10.582 16.07a4.5 4.5 0 0 1-1.897 1.13L6 18l.8-2.685a4.5 4.5 0 0 1 1.13-1.897l8.932-8.931Zm0 0L19.5 7.125M18 14v4.75A2.25 2.25 0 0 1 15.75 21H5.25A2.25 2.25 0 0 1 3 18.75V8.25A2.25 2.25 0 0 1 5.25 6H10" />
                  </svg>
                </button>
                <button @click="deleteDriver(driver)" class="btn-delete" title="Delete">
                  <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" style="width: 1.25rem; height: 1.25rem;">
                    <path stroke-linecap="round" stroke-linejoin="round" d="m14.74 9-.346 9m-4.788 0L9.26 9m9.968-3.21c.342.052.682.107 1.022.166m-1.022-.165L18.16 19.673a2.25 2.25 0 0 1-2.244 2.077H8.084a2.25 2.25 0 0 1-2.244-2.077L4.772 5.79m14.456 0a48.108 48.108 0 0 0-3.478-.397m-12 .562c.34-.059.68-.114 1.022-.165m0 0a48.11 48.11 0 0 1 3.478-.397m7.5 0v-.916c0-1.18-.91-2.164-2.09-2.201a51.964 51.964 0 0 0-3.32 0c-1.18.037-2.09 1.022-2.09 2.201v.916m7.5 0a48.667 48.667 0 0 0-7.5 0" />
                  </svg>
                </button>
              </td>
            </tr>
            <tr v-if="filteredDrivers.length === 0">
              <td :colspan="isAdmin ? 6 : 5" class="empty-row">No drivers found.</td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <!-- Modal เพิ่มคนขับใหม่ -->
    <div v-if="isAddModalOpen" class="modal-overlay">
      <div class="modal-content">
        <h3>Add New Driver</h3>
        <form @submit.prevent="saveNewDriver">
          <div class="form-group">
            <label for="name">Full Name</label>
            <input type="text" id="name" v-model="newDriverForm.name" placeholder="Somchai Jaidee" :class="{ 'has-error': fieldErrors.name }" />
            <span v-if="fieldErrors.name" class="field-error-text">{{ fieldErrors.name }}</span>
          </div>
          <div class="form-group">
            <label for="license">License Number</label>
            <input type="text" id="license" v-model="newDriverForm.license_number" placeholder="e.g. D-1234567" :class="{ 'has-error': fieldErrors.license_number }" />
            <small v-if="!fieldErrors.license_number" class="form-hint">Must be exactly 9 characters long.</small>
            <span v-if="fieldErrors.license_number" class="field-error-text">{{ fieldErrors.license_number }}</span>
          </div>
          <div class="form-group">
            <label for="expires">License Expiry Date</label>
            <input type="date" id="expires" v-model="newDriverForm.license_expires_at" :class="{ 'has-error': fieldErrors.license_expires_at }" />
            <span v-if="fieldErrors.license_expires_at" class="field-error-text">{{ fieldErrors.license_expires_at }}</span>
          </div>
          <div class="form-group">
            <label for="phone">Phone Number</label>
            <input type="tel" id="phone" v-model="newDriverForm.phone" placeholder="0812345678" :class="{ 'has-error': fieldErrors.phone }" />
            <small v-if="!fieldErrors.phone" class="form-hint">Must be exactly 10 digits.</small>
            <span v-if="fieldErrors.phone" class="field-error-text">{{ fieldErrors.phone }}</span>
          </div>
          <div class="form-group">
            <label for="status">Initial Status</label>
            <select id="status" v-model="newDriverForm.status" :class="{ 'has-error': fieldErrors.status }">
              <option value="ACTIVE">ACTIVE</option>
              <option value="INACTIVE">INACTIVE</option>
              <option value="SUSPENDED">SUSPENDED</option>
            </select>
            <span v-if="fieldErrors.status" class="field-error-text">{{ fieldErrors.status }}</span>
          </div>
          <div class="modal-actions">
            <button type="button" @click="closeAddModal" class="btn-cancel">Cancel</button>
            <button type="submit" class="btn-save" :disabled="isSaving">
              {{ isSaving ? 'Saving...' : 'Save Driver' }}
            </button>
          </div>
        </form>
      </div>
    </div>

    <!-- Modal แก้ไขข้อมูลคนขับ -->
    <div v-if="isEditModalOpen" class="modal-overlay">
      <div class="modal-content">
        <h3>Edit Driver</h3>
        <form @submit.prevent="saveEditDriver">
          <div class="form-group">
            <label>Full Name</label>
            <input type="text" v-model="editDriverForm.name" :class="{ 'has-error': editFieldErrors.name }" />
            <span v-if="editFieldErrors.name" class="field-error-text">{{ editFieldErrors.name }}</span>
          </div>
          <div class="form-group">
            <label>License Number</label>
            <input type="text" v-model="editDriverForm.license_number" :class="{ 'has-error': editFieldErrors.license_number }" />
            <span v-if="editFieldErrors.license_number" class="field-error-text">{{ editFieldErrors.license_number }}</span>
          </div>
          <div class="form-group">
            <label>License Expiry Date</label>
            <input type="date" v-model="editDriverForm.license_expires_at" :class="{ 'has-error': editFieldErrors.license_expires_at }" />
            <span v-if="editFieldErrors.license_expires_at" class="field-error-text">{{ editFieldErrors.license_expires_at }}</span>
          </div>
          <div class="form-group">
            <label>Phone Number</label>
            <input type="tel" v-model="editDriverForm.phone" :class="{ 'has-error': editFieldErrors.phone }" />
            <span v-if="editFieldErrors.phone" class="field-error-text">{{ editFieldErrors.phone }}</span>
          </div>
          <div class="form-group">
            <label>Status</label>
            <select v-model="editDriverForm.status" :class="{ 'has-error': editFieldErrors.status }">
              <option value="ACTIVE">ACTIVE</option>
              <option value="INACTIVE">INACTIVE</option>
              <option value="SUSPENDED">SUSPENDED</option>
            </select>
            <span v-if="editFieldErrors.status" class="field-error-text">{{ editFieldErrors.status }}</span>
          </div>
          <div class="modal-actions">
            <button type="button" @click="closeEditModal" class="btn-cancel">Cancel</button>
            <button type="submit" class="btn-save" :disabled="isUpdating">
              {{ isUpdating ? 'Updating...' : 'Update Driver' }}
            </button>
          </div>
        </form>
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

.filters {
  display: flex;
  gap: 16px;
  margin-bottom: 24px;
  background: white;
  border-radius: 12px;
  flex-wrap: wrap;
}

.search-input {
  padding: 12px 16px;
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  font-size: 14px;
  background: #f8fafc;
  color: #334155;
  transition: all 0.2s;
  flex: 2;
  min-width: 280px;
  box-sizing: border-box;
}

.search-input:hover {
  border-color: #cbd5e1;
  background: #fff;
}
.search-input:focus {
  outline: none;
  background: white;
  border-color: #3b82f6;
  box-shadow: 0 0 0 4px rgba(59, 130, 246, 0.1);
}

.custom-dropdown {
  position: relative;
  flex: 1;
  min-width: 150px;
  user-select: none;
}

.dropdown-trigger {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  background-color: white;
  border: 1px solid #e2e8f0;
  padding: 12px 16px;
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

.dot-indicator.status-gray { background-color: #94a3b8; }
.dot-indicator.status-active { background-color: #48bb78; }
.dot-indicator.status-inactive { background-color: #a0aec0; }
.dot-indicator.status-suspended { background-color: #e53e3e; }

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
  box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.05), 0 4px 6px -2px rgba(0, 0, 0, 0.025);
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
}

tbody tr:last-child td {
  border-bottom: none;
}

.font-medium {
  font-weight: 500;
}

.text-danger {
  color: #e53e3e;
}

.expired-label {
  font-size: 0.75rem;
  margin-left: 0.25rem;
}

.empty-row {
  text-align: center;
  color: #a0aec0;
  padding: 2rem;
}

.status-badge {
  padding: 0.35rem 0.75rem;
  border-radius: 9999px;
  font-size: 0.8rem;
  font-weight: 600;
  color: #fff;
}

.status-active { background-color: #48bb78; }
.status-inactive { background-color: #a0aec0; }
.status-suspended { background-color: #e53e3e; }

.loading-message, .error-message {
  text-align: center;
  padding: 2rem;
  background-color: white;
  border-radius: 8px;
}

.error-message { color: #e53e3e; }

/* Action buttons */
.action-cell {
  display: flex;
  gap: 0.5rem;
  white-space: nowrap;
}

.btn-edit {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  padding: 0.4rem;
  background-color: #ebf8ff;
  color: #2b6cb0;
  border: 1px solid #bee3f8;
  border-radius: 6px;
  cursor: pointer;
  transition: all 0.2s;
}
.btn-edit:hover {
  background-color: #bee3f8;
  color: #1a365d;
}

.btn-delete {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  padding: 0.4rem;
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

/* Add button */
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
}
.icon-small { width: 18px; height: 18px; }

/* Modal Styles */
.modal-overlay {
  position: fixed;
  top: 0; left: 0; right: 0; bottom: 0;
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
  from { opacity: 0; }
  to { opacity: 1; }
}

.modal-content {
  background-color: white;
  padding: 2rem;
  border-radius: 20px;
  width: 100%;
  max-width: 480px;
  box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.25);
  max-height: 90vh;
  overflow-y: auto;
  animation: slideUp 0.4s cubic-bezier(0.16, 1, 0.3, 1);
}

@keyframes slideUp {
  from { opacity: 0; transform: translateY(30px) scale(0.95); }
  to { opacity: 1; transform: translateY(0) scale(1); }
}

@media (max-width: 768px) {
  .filters {
    flex-direction: column;
  }
  .search-input,
  .custom-dropdown {
    min-width: 100%;
    width: 100%;
  }
}

.modal-content h3 {
  margin-top: 0;
  margin-bottom: 1.5rem;
  color: #2d3748;
  font-size: 1.3rem;
  font-weight: 700;
}

.form-group { margin-bottom: 1.25rem; }

.form-group label {
  display: block;
  font-size: 0.9rem;
  font-weight: 500;
  margin-bottom: 0.5rem;
  color: #4a5568;
}

.form-group input,
.form-group select {
  width: 100%;
  padding: 0.7rem 0.9rem;
  border: 1px solid #cbd5e0;
  border-radius: 6px;
  background-color: #fff;
  font-size: 0.95rem;
  box-sizing: border-box;
  transition: border-color 0.2s, box-shadow 0.2s;
}

.form-group input:focus,
.form-group select:focus {
  outline: none;
  border-color: #3182ce;
  box-shadow: 0 0 0 3px rgba(49, 130, 206, 0.1);
}

.form-group input.has-error,
.form-group select.has-error {
  border-color: #e53e3e;
  background-color: #fff5f5;
}

.field-error-text {
  display: block;
  font-size: 0.8rem;
  color: #e53e3e;
  margin-top: 0.4rem;
}

.form-hint {
  display: block;
  font-size: 0.75rem;
  color: #718096;
  margin-top: 0.25rem;
}

.modal-actions {
  display: flex;
  justify-content: flex-end;
  gap: 1rem;
  margin-top: 2rem;
}

.btn-cancel {
  padding: 0.6rem 1.25rem;
  border: 1px solid #cbd5e0;
  background-color: white;
  color: #4a5568;
  border-radius: 8px;
  cursor: pointer;
  font-weight: 500;
  transition: all 0.2s;
}
.btn-cancel:hover { background-color: #f7fafc; }

.btn-save {
  padding: 0.6rem 1.25rem;
  background: linear-gradient(135deg, #3b82f6 0%, #2563eb 100%);
  color: white;
  border: none;
  border-radius: 8px;
  cursor: pointer;
  font-weight: 600;
  transition: all 0.2s;
}
.btn-save:hover { opacity: 0.9; }
.btn-save:disabled { background: #a0aec0; cursor: not-allowed; }
</style>
