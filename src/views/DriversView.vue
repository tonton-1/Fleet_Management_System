<script setup>
import { ref, onMounted, computed } from 'vue'
import apiClient from '../api/axios'

const drivers = ref([])
const isLoading = ref(true)
const errorMessage = ref('')
const currentUserRole = ref('')

// สถานะของ Modal เพิ่มคนขับ
const isAddModalOpen = ref(false)
const isSaving = ref(false)

// โมเดลข้อมูลสำหรับฟอร์ม
const newDriverForm = ref({
  name: '',
  license_number: '',
  license_expires_at: '',
  phone: '',
  status: 'ACTIVE',
})
// ตัวแปรสำหรับเก็บ error ของแต่ละฟิลด์
const fieldErrors = ref({})
// ฟังก์ชันสำหรับถอดรหัส JWT Token
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

const openAddModal = () => {
  // รีเซ็ตฟอร์มก่อนเปิด
  newDriverForm.value = {
    name: '',
    license_number: '',
    license_expires_at: '',
    phone: '',
    status: 'ACTIVE',
  }
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

    // ส่ง Request POST ไปที่ /drivers
    await apiClient.post('/drivers', newDriverForm.value)

    closeAddModal()
    alert('Driver added successfully.')

    // ดึงข้อมูลพนักงานทั้งหมดใหม่
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

// ฟังก์ชันแปลงรูปแบบวันที่ให้อ่านง่าย
const formatDate = (dateString) => {
  if (!dateString) return 'N/A'
  const date = new Date(dateString)
  return date.toLocaleDateString('en-GB', {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
  })
}

// ฟังก์ชันตรวจสอบว่าใบขับขี่หมดอายุหรือยัง
const isExpired = (dateString) => {
  if (!dateString) return false
  const expiresAt = new Date(dateString)
  const today = new Date()
  return expiresAt < today
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

  fetchDrivers()
})
</script>

<template>
  <div class="drivers-page">
    <div v-if="isLoading" class="loading-message">Loading driver data...</div>
    <div v-else-if="errorMessage" class="error-message">{{ errorMessage }}</div>
    <div v-else class="table-container">
      <div class="header-actions">
        <h2>All Drivers</h2>
        <!-- แสดงปุ่มเพิ่มพนักงานเฉพาะ Admin เท่านั้น -->
        <button v-if="isAdmin" @click="openAddModal" class="btn-add">
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
          Add Driver
        </button>
      </div>

      <table>
        <thead>
          <tr>
            <th>Name</th>
            <th>License Number</th>
            <th>Expires At</th>
            <th>Phone</th>
            <th>Status</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="driver in drivers" :key="driver.id">
            <td class="font-medium">{{ driver.name }}</td>
            <td>{{ driver.license_number }}</td>
            <td>
              <span :class="{ 'text-danger font-medium': isExpired(driver.license_expires_at) }">
                {{ formatDate(driver.license_expires_at) }}
                <span v-if="isExpired(driver.license_expires_at)" class="expired-label"
                  >(Expired)</span
                >
              </span>
            </td>
            <td>{{ driver.phone }}</td>
            <td>
              <span :class="['status-badge', `status-${driver.status.toLowerCase()}`]">
                {{ driver.status }}
              </span>
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <!-- Modal สำหรับเพิ่มข้อมูลพนักงานขับรถใหม่ -->
    <div v-if="isAddModalOpen" class="modal-overlay">
      <div class="modal-content">
        <h3>Add New Driver</h3>
        <form @submit.prevent="saveNewDriver">
          <div class="form-group">
            <label for="name">Full Name</label>
            <input
              type="text"
              id="name"
              v-model="newDriverForm.name"
              placeholder="Somchai Jaidee"
              :class="{ 'has-error': fieldErrors.name }"
            />
            <span v-if="fieldErrors.name" class="field-error-text">{{ fieldErrors.name }}</span>
          </div>

          <div class="form-group">
            <label for="license">License Number</label>
            <input
              type="text"
              id="license"
              v-model="newDriverForm.license_number"
              placeholder="9 characters e.g. D-1234567"
              :class="{ 'has-error': fieldErrors.license_number }"
            />
            <small v-if="!fieldErrors.license_number" class="form-hint"
              >Must be exactly 9 characters long.</small
            >
            <span v-if="fieldErrors.license_number" class="field-error-text">{{
              fieldErrors.license_number
            }}</span>
          </div>

          <div class="form-group">
            <label for="expires">License Expiry Date</label>
            <input
              type="date"
              id="expires"
              v-model="newDriverForm.license_expires_at"
              :class="{ 'has-error': fieldErrors.license_expires_at }"
            />
            <span v-if="fieldErrors.license_expires_at" class="field-error-text">{{
              fieldErrors.license_expires_at
            }}</span>
          </div>

          <div class="form-group">
            <label for="phone">Phone Number</label>
            <input
              type="tel"
              id="phone"
              v-model="newDriverForm.phone"
              placeholder="0812345678"
              :class="{ 'has-error': fieldErrors.phone }"
            />
            <small v-if="!fieldErrors.phone" class="form-hint">Must be exactly 10 digits.</small>
            <span v-if="fieldErrors.phone" class="field-error-text">{{ fieldErrors.phone }}</span>
          </div>

          <div class="form-group">
            <label for="status">Initial Status</label>
            <select
              id="status"
              v-model="newDriverForm.status"
              :class="{ 'has-error': fieldErrors.status }"
            >
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
.status-inactive {
  background-color: #a0aec0;
}
.status-suspended {
  background-color: #e53e3e;
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

/* Button styles */
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
  max-width: 450px;
  box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.1);
  max-height: 90vh;
  overflow-y: auto;
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

.form-group input.has-error,
.form-group select.has-error {
  border-color: #e53e3e;
  background-color: #fff5f5;
}

.form-group input:focus,
.form-group select:focus {
  outline: none;
  border-color: #3182ce;
}

.form-group input.has-error:focus,
.form-group select.has-error:focus {
  border-color: #e53e3e;
  box-shadow: 0 0 0 1px #e53e3e;
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
