<script setup>
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import axios from 'axios'

const router = useRouter()

// ตัวแปรสำหรับผูกกับฟอร์ม
const username = ref('')
const password = ref('')
const rememberMe = ref(false)

// ตัวแปรสำหรับจัดการสถานะ
const isLoading = ref(false)
const errorMessage = ref('')

// ฟังก์ชันสำหรับจัดการการ Login
const handleLogin = async () => {
  if (!username.value || !password.value) {
    errorMessage.value = 'Please enter both username and password.'
    return
  }

  isLoading.value = true
  errorMessage.value = ''

  try {
    // --- เรียก API /auth/login ด้วย axios ---
    const response = await axios.post('http://localhost:3000/auth/login', {
      username: username.value,
      password: password.value,
    })

    // --- Login สำเร็จ ---
    // ข้อมูลที่ได้กลับมาจะอยู่ใน response.data
    const { access_token, refresh_token } = response.data
    console.log('Login successful, received token:', access_token)

    // เก็บ Token ลงใน localStorage
    localStorage.setItem('accessToken', access_token)
    localStorage.setItem('refreshToken', refresh_token)

    // ไปยังหน้าที่ต้องการหลัง Login สำเร็จ
    router.push('/dashboard')
  } catch (error) {
    // axios จะโยน error อัตโนมัติสำหรับ status code ที่ไม่ใช่ 2xx
    // ข้อมูล error จาก server จะอยู่ใน error.response.data
    errorMessage.value = error.response?.data?.error?.message || 'An unexpected error occurred.'
    console.error('Login failed:', error)
  } finally {
    isLoading.value = false
  }
}
</script>

<template>
  <div class="login-page">
    <div class="login-panel">
      <div class="login-header">
        <!-- คุณสามารถใส่ Logo ของคุณตรงนี้ได้ -->
        <!-- <img src="@/assets/logo.svg" alt="Fleet Management Logo" class="logo" /> -->
        <h1>Fleet Management Platform</h1>
        <p>Sign in to monitor and manage your fleet.</p>
      </div>

      <form @submit.prevent="handleLogin" class="login-form">
        <div class="form-group">
          <label for="username">Username</label>
          <input
            type="text"
            id="username"
            v-model="username"
            placeholder="e.g., admin"
            :disabled="isLoading"
            required
          />
        </div>

        <div class="form-group">
          <label for="password">Password</label>
          <input
            type="password"
            id="password"
            v-model="password"
            placeholder="••••••••"
            :disabled="isLoading"
            required
          />
        </div>

        <div class="form-options">
          <label class="remember-me">
            <input type="checkbox" v-model="rememberMe" :disabled="isLoading" />
            <span>Remember me</span>
          </label>
          <a href="#" class="forgot-password">Forgot password?</a>
        </div>

        <p v-if="errorMessage" class="error-message">{{ errorMessage }}</p>

        <button type="submit" class="login-button" :disabled="isLoading">
          <span v-if="isLoading">Signing In...</span>
          <span v-else>Sign In</span>
        </button>
      </form>
    </div>
  </div>
</template>

<style scoped>
.login-page {
  display: flex;
  justify-content: center;
  align-items: center;
  min-height: 100vh;
  background-color: #f0f2f5;
  font-family:
    -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, 'Open Sans',
    'Helvetica Neue', sans-serif;
}

.login-panel {
  width: 100%;
  max-width: 400px;
  padding: 40px 30px;
  background-color: #ffffff;
  border-radius: 8px;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
  box-sizing: border-box;
}

.login-form {
  display: flex;
  flex-direction: column;
}

.login-header {
  text-align: center;
  margin-bottom: 25px;
}

.logo {
  height: 40px;
  margin-bottom: 15px;
}

.login-header h1 {
  font-size: 24px;
  font-weight: 600;
  color: #1a202c;
  margin: 0 0 5px 0;
}

.login-header p {
  font-size: 14px;
  color: #718096;
}

.form-group {
  margin-bottom: 20px;
}

.form-group label {
  display: block;
  font-size: 14px;
  font-weight: 500;
  color: #4a5568;
  margin-bottom: 8px;
}

.form-group input {
  width: 100%;
  padding: 10px 12px;
  font-size: 14px;
  border: 1px solid #cbd5e0;
  border-radius: 6px;
  box-sizing: border-box;
  transition: border-color 0.2s;
}

.form-group input:focus {
  outline: none;
  border-color: #4299e1;
  box-shadow: 0 0 0 1px #4299e1;
}

.form-options {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20px;
}

.remember-me {
  display: flex;
  align-items: center;
  font-size: 14px;
  color: #4a5568;
}

.remember-me input {
  margin-right: 8px;
}

.forgot-password {
  font-size: 14px;
  color: #4299e1;
  text-decoration: none;
  transition: color 0.2s;
}

.forgot-password:hover {
  text-decoration: underline;
  color: #2b6cb0;
}

.login-button {
  width: 100%;
  padding: 12px;
  font-size: 16px;
  font-weight: 600;
  color: #ffffff;
  background-color: #3182ce;
  border: none;
  border-radius: 6px;
  cursor: pointer;
  transition: background-color 0.2s;
}

.login-button:hover {
  background-color: #2b6cb0;
}

.login-button:disabled {
  background-color: #a0aec0;
  cursor: not-allowed;
}

.error-message {
  color: #e53e3e;
  background-color: #fed7d7;
  border: 1px solid #fbb6b6;
  border-radius: 6px;
  padding: 10px;
  text-align: center;
  font-size: 14px;
  margin-bottom: 20px;
}
</style>
