<script setup>
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import axios from 'axios'
import { startTokenExpirationWatcher } from '../utils/tokenExpiration'

const router = useRouter()

const username = ref('')
const password = ref('')
const showPassword = ref(false)

const isLoading = ref(false)
const errorMessage = ref('')

const handleLogin = async () => {
  if (!username.value || !password.value) {
    errorMessage.value = 'Please enter both username and password.'
    return
  }

  isLoading.value = true
  errorMessage.value = ''

  try {
    const response = await axios.post('http://localhost:3000/auth/login', {
      username: username.value,
      password: password.value,
    })

    const { access_token, refresh_token } = response.data
    localStorage.setItem('accessToken', access_token)
    localStorage.setItem('refreshToken', refresh_token)
    startTokenExpirationWatcher()
    router.push('/dashboard')
  } catch (error) {
    errorMessage.value = error.response?.data?.error?.message || 'An unexpected error occurred.'
    console.error('Login failed:', error)
  } finally {
    isLoading.value = false
  }
}
</script>

<template>
  <div class="login-wrapper">
    <!-- Subtle Minimal Background -->
    <div class="minimal-bg">
      <div class="shape shape-1"></div>
      <div class="shape shape-2"></div>
    </div>

    <!-- Minimal UI Container -->
    <div class="login-container">
      <div class="brand-header">
        <div class="logo-box">
          <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">
            <path stroke-linecap="round" stroke-linejoin="round" d="M8.25 18.75a1.5 1.5 0 0 1-3 0m3 0a1.5 1.5 0 0 0-3 0m3 0h6m-9 0H3.375a1.125 1.125 0 0 1-1.125-1.125V14.25m17.25 4.5a1.5 1.5 0 0 1-3 0m3 0a1.5 1.5 0 0 0-3 0m3 0h1.125c.621 0 1.129-.504 1.09-1.124a17.902 17.902 0 0 0-3.213-9.193 2.056 2.056 0 0 0-1.58-.86H14.25M16.5 18.75h-2.25m0-11.177v-.958c0-.568-.422-1.048-.987-1.106a48.554 48.554 0 0 0-10.026 0 1.106 1.106 0 0 0-.987 1.106v7.635m12-6.677v6.677m0 4.5v-4.5m0 0h-12" />
          </svg>
        </div>
        <h1 class="title">Fleet<span>Pro</span></h1>
        <p class="subtitle">Welcome back! Please enter your details.</p>
      </div>

      <form @submit.prevent="handleLogin" class="login-form">
        <!-- Username -->
        <div class="input-group">
          <label>Username</label>
          <div class="input-field" :class="{ 'focused': username }">
            <svg class="icon" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5">
              <path stroke-linecap="round" stroke-linejoin="round" d="M15.75 6a3.75 3.75 0 1 1-7.5 0 3.75 3.75 0 0 1 7.5 0ZM4.501 20.118a7.5 7.5 0 0 1 14.998 0A17.933 17.933 0 0 1 12 21.75c-2.676 0-5.216-.584-7.499-1.632Z" />
            </svg>
            <input type="text" v-model="username" placeholder="Enter your username" :disabled="isLoading" autocomplete="username" required />
          </div>
        </div>

        <!-- Password -->
        <div class="input-group">
          <label>Password</label>
          <div class="input-field" :class="{ 'focused': password }">
            <svg class="icon" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5">
              <path stroke-linecap="round" stroke-linejoin="round" d="M16.5 10.5V6.75a4.5 4.5 0 1 0-9 0v3.75m-.75 11.25h10.5a2.25 2.25 0 0 0 2.25-2.25v-6.75a2.25 2.25 0 0 0-2.25-2.25H6.75a2.25 2.25 0 0 0-2.25 2.25v6.75a2.25 2.25 0 0 0 2.25 2.25Z" />
            </svg>
            <input :type="showPassword ? 'text' : 'password'" v-model="password" placeholder="••••••••" :disabled="isLoading" autocomplete="current-password" required />
            <button type="button" class="btn-toggle" @click="showPassword = !showPassword" tabindex="-1">
              <svg v-if="!showPassword" class="icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">
                 <path stroke-linecap="round" stroke-linejoin="round" d="M2.036 12.322a1.012 1.012 0 0 1 0-.639C3.423 7.51 7.36 4.5 12 4.5c4.638 0 8.573 3.007 9.963 7.178.07.207.07.431 0 .639C20.577 16.49 16.64 19.5 12 19.5c-4.638 0-8.573-3.007-9.963-7.178Z" />
                 <path stroke-linecap="round" stroke-linejoin="round" d="M15 12a3 3 0 1 1-6 0 3 3 0 0 1 6 0Z" />
              </svg>
              <svg v-else class="icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">
                 <path stroke-linecap="round" stroke-linejoin="round" d="M3.98 8.223A10.477 10.477 0 0 0 1.934 12C3.226 16.338 7.244 19.5 12 19.5c.993 0 1.953-.138 2.863-.395M6.228 6.228A10.451 10.451 0 0 1 12 4.5c4.756 0 8.773 3.162 10.065 7.498a10.522 10.522 0 0 1-4.293 5.774M6.228 6.228 3 3m3.228 3.228 3.65 3.65m7.894 7.894L21 21m-3.228-3.228-3.65-3.65m0 0a3 3 0 1 0-4.243-4.243m4.242 4.242L9.88 9.88" />
              </svg>
            </button>
          </div>
        </div>

        <!-- Error Alert -->
        <transition name="fade">
          <div v-if="errorMessage" class="error-box">
             {{ errorMessage }}
          </div>
        </transition>

        <!-- Submit Button -->
        <button type="submit" class="btn-submit" :disabled="isLoading">
          <span v-if="isLoading" class="spinner"></span>
          <span v-else>Sign In</span>
        </button>
      </form>

 
    </div>
  </div>
</template>

<style scoped>
.login-wrapper {
  position: relative;
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  background-color: #f7f9fa; /* Very subtle grey/white */
  font-family: 'Inter', system-ui, -apple-system, sans-serif;
  overflow: hidden;
  color: #1f2937;
}

/* Very subtle background accents */
.minimal-bg {
  position: absolute;
  top: 0; left: 0; width: 100%; height: 100%;
  overflow: hidden;
  z-index: 0;
}
.shape {
  position: absolute;
  border-radius: 50%;
  filter: blur(100px);
  z-index: 0;
  pointer-events: none;
  opacity: 0.5;
}
.shape-1 {
  width: 600px; height: 600px;
  background: #dbeafe; /* Soft blue pastel */
  top: -100px; left: -150px;
}
.shape-2 {
  width: 500px; height: 500px;
  background: #eff6ff; /* Soft light blue pastel */
  bottom: -150px; right: -100px;
}

/* Minimal Container */
.login-container {
  position: relative;
  z-index: 1;
  width: 100%;
  max-width: 440px;
  background: #ffffff;
  padding: 48px;
  border-radius: 24px;
  box-shadow: 0 20px 40px -15px rgba(0, 0, 0, 0.05),
              0 0 0 1px rgba(0, 0, 0, 0.02);
  animation: slideIn 0.5s cubic-bezier(0.16, 1, 0.3, 1);
}

@keyframes slideIn {
  from { opacity: 0; transform: translateY(20px); }
  to { opacity: 1; transform: translateY(0); }
}

/* Brand Header */
.brand-header {
  text-align: center;
  margin-bottom: 40px;
}

.logo-box {
  width: 52px; height: 52px;
  margin: 0 auto 20px;
  background: #111827;
  color: #fff;
  border-radius: 14px;
  display: flex;
  align-items: center;
  justify-content: center;
  box-shadow: 0 8px 16px -6px rgba(17, 24, 39, 0.4);
}
.logo-box svg { width: 26px; height: 26px; stroke-width: 2; }

.title {
  font-size: 26px;
  font-weight: 800;
  color: #111827;
  letter-spacing: -0.03em;
  margin: 0 0 8px 0;
}
.title span {
  color: #2563eb;
}
.subtitle {
  font-size: 14px;
  color: #6b7280;
  margin: 0;
  font-weight: 400;
}

/* Form */
.login-form {
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.input-group {
  display: flex;
  flex-direction: column;
  gap: 6px;
}
.input-group label {
  font-size: 13px;
  font-weight: 600;
  color: #374151;
}

.input-field {
  position: relative;
  display: flex;
  align-items: center;
  background: #f9fafb;
  border: 1px solid #e5e7eb;
  border-radius: 12px;
  transition: all 0.2s ease;
}
.input-field:hover {
  background: #ffffff;
  border-color: #d1d5db;
}
.input-field:focus-within {
  background: #ffffff;
  border-color: #2563eb;
  box-shadow: 0 0 0 4px rgba(37, 99, 235, 0.1);
}

.input-field .icon {
  width: 20px; height: 20px;
  color: #9ca3af;
  position: absolute;
  left: 14px;
  transition: color 0.2s;
}
.input-field:focus-within .icon, .input-field.focused .icon {
  color: #2563eb;
}

.input-field input {
  width: 100%;
  padding: 12px 42px;
  background: transparent;
  border: none;
  color: #1f2937;
  font-size: 14.5px;
  outline: none;
  font-weight: 500;
}
.input-field input::placeholder {
  color: #9ca3af;
  font-weight: 400;
}

/* Password Toggle */
.btn-toggle {
  position: absolute;
  right: 12px;
  background: none;
  border: none;
  color: #9ca3af;
  cursor: pointer;
  padding: 6px;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 8px;
  transition: all 0.2s;
}
.btn-toggle:hover {
  color: #4b5563;
  background: #f3f4f6;
}
.btn-toggle .icon {
  position: relative; left: 0; width: 18px; height: 18px;
}

/* Error Alert */
.error-box {
  padding: 12px 16px;
  background: #fef2f2;
  border-radius: 12px;
  color: #dc2626;
  font-size: 13.5px;
  font-weight: 500;
  display: flex;
  align-items: center;
  gap: 8px;
}
.error-box::before {
  content: '!';
  display: flex;
  justify-content: center;
  align-items: center;
  width: 18px; height: 18px;
  background: #dc2626;
  color: white;
  border-radius: 50%;
  font-size: 12px;
  font-weight: bold;
}
.fade-enter-active, .fade-leave-active { transition: opacity 0.3s, transform 0.3s; }
.fade-enter-from, .fade-leave-to { opacity: 0; transform: translateY(-5px); }

/* Submit Button */
.btn-submit {
  width: 100%;
  padding: 14px;
  border: none;
  border-radius: 12px;
  background: #111827;
  color: #ffffff;
  font-size: 15px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s ease;
  box-shadow: 0 4px 6px -1px rgba(17, 24, 39, 0.1),
              0 2px 4px -2px rgba(17, 24, 39, 0.1);
  display: flex;
  justify-content: center;
  align-items: center;
}
.btn-submit:hover:not(:disabled) {
  background: #1f2937;
  transform: translateY(-1px);
  box-shadow: 0 10px 15px -3px rgba(17, 24, 39, 0.1),
              0 4px 6px -4px rgba(17, 24, 39, 0.1);
}
.btn-submit:active:not(:disabled) {
  transform: translateY(0);
}
.btn-submit:disabled {
  background: #9ca3af;
  cursor: not-allowed;
  box-shadow: none;
}

.spinner {
  width: 20px; height: 20px;
  border: 3px solid rgba(255,255,255,0.3);
  border-radius: 50%;
  border-top-color: white;
  animation: spin 0.8s ease-in-out infinite;
}
@keyframes spin { to { transform: rotate(360deg); } }

/* Footer */
.footer-info {
  margin-top: 32px;
  text-align: center;
  font-size: 13px;
  color: #9ca3af;
}
.footer-info a {
  color: #6b7280;
  text-decoration: underline;
  text-underline-offset: 2px;
}
.footer-info a:hover {
  color: #111827;
}

/* Responsive */
@media (max-width: 480px) {
  .login-container {
    padding: 32px 24px;
    margin: 16px;
    border-radius: 20px;
  }
}
</style>