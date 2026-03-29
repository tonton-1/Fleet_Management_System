<script setup>
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import axios from 'axios'
import { startTokenExpirationWatcher } from '../utils/tokenExpiration'

const router = useRouter()

const username = ref('')
const password = ref('')
const rememberMe = ref(false)
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
  <div class="login-page">
    <!-- Background decorative elements -->
    <div class="bg-shape bg-shape-1"></div>
    <div class="bg-shape bg-shape-2"></div>
    <div class="bg-shape bg-shape-3"></div>

    <div class="login-container">
      <!-- Left panel: Branding -->
      <div class="brand-panel">
        <div class="brand-content">
          <div class="brand-icon">
            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" d="M8.25 18.75a1.5 1.5 0 0 1-3 0m3 0a1.5 1.5 0 0 0-3 0m3 0h6m-9 0H3.375a1.125 1.125 0 0 1-1.125-1.125V14.25m17.25 4.5a1.5 1.5 0 0 1-3 0m3 0a1.5 1.5 0 0 0-3 0m3 0h1.125c.621 0 1.129-.504 1.09-1.124a17.902 17.902 0 0 0-3.213-9.193 2.056 2.056 0 0 0-1.58-.86H14.25M16.5 18.75h-2.25m0-11.177v-.958c0-.568-.422-1.048-.987-1.106a48.554 48.554 0 0 0-10.026 0 1.106 1.106 0 0 0-.987 1.106v7.635m12-6.677v6.677m0 4.5v-4.5m0 0h-12" />
            </svg>
          </div>
          <h1 class="brand-title">Fleet<span>Track</span></h1>
          <p class="brand-subtitle">Fleet Management Platform</p>

          <div class="brand-stats">
            <div class="brand-stat">
              <span class="stat-number">99.9%</span>
              <span class="stat-label">Uptime</span>
            </div>
            <div class="brand-divider"></div>
            <div class="brand-stat">
              <span class="stat-number">24/7</span>
              <span class="stat-label">Monitoring</span>
            </div>
            <div class="brand-divider"></div>
            <div class="brand-stat">
              <span class="stat-number">Real-time</span>
              <span class="stat-label">Tracking</span>
            </div>
          </div>

          <div class="feature-list">
            <div class="feature-item">
              <div class="feature-dot"></div>
              <span>Real-time vehicle tracking & monitoring</span>
            </div>
            <div class="feature-item">
              <div class="feature-dot"></div>
              <span>Smart maintenance scheduling</span>
            </div>
            <div class="feature-item">
              <div class="feature-dot"></div>
              <span>Driver performance analytics</span>
            </div>
            <div class="feature-item">
              <div class="feature-dot"></div>
              <span>Automated alerts & notifications</span>
            </div>
          </div>
        </div>
      </div>

      <!-- Right panel: Login form -->
      <div class="form-panel">
        <div class="form-wrapper">
          <div class="form-header">
            <h2>Welcome back</h2>
            <p>Sign in to your account to continue</p>
          </div>

          <form @submit.prevent="handleLogin" class="login-form">
            <!-- Username -->
            <div class="field-group">
              <label for="username">Username</label>
              <div class="input-wrap" :class="{ focused: username }">
                <div class="input-icon">
                  <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M15.75 6a3.75 3.75 0 1 1-7.5 0 3.75 3.75 0 0 1 7.5 0ZM4.501 20.118a7.5 7.5 0 0 1 14.998 0A17.933 17.933 0 0 1 12 21.75c-2.676 0-5.216-.584-7.499-1.632Z" />
                  </svg>
                </div>
                <input
                  type="text"
                  id="username"
                  v-model="username"
                  placeholder="Enter your username"
                  :disabled="isLoading"
                  autocomplete="username"
                  required
                />
              </div>
            </div>

            <!-- Password -->
            <div class="field-group">
              <label for="password">Password</label>
              <div class="input-wrap" :class="{ focused: password }">
                <div class="input-icon">
                  <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M16.5 10.5V6.75a4.5 4.5 0 1 0-9 0v3.75m-.75 11.25h10.5a2.25 2.25 0 0 0 2.25-2.25v-6.75a2.25 2.25 0 0 0-2.25-2.25H6.75a2.25 2.25 0 0 0-2.25 2.25v6.75a2.25 2.25 0 0 0 2.25 2.25Z" />
                  </svg>
                </div>
                <input
                  :type="showPassword ? 'text' : 'password'"
                  id="password"
                  v-model="password"
                  placeholder="Enter your password"
                  :disabled="isLoading"
                  autocomplete="current-password"
                  required
                />
                <button
                  type="button"
                  class="toggle-password"
                  @click="showPassword = !showPassword"
                  :disabled="isLoading"
                  tabindex="-1"
                >
                  <!-- Eye open -->
                  <svg v-if="!showPassword" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M2.036 12.322a1.012 1.012 0 0 1 0-.639C3.423 7.51 7.36 4.5 12 4.5c4.638 0 8.573 3.007 9.963 7.178.07.207.07.431 0 .639C20.577 16.49 16.64 19.5 12 19.5c-4.638 0-8.573-3.007-9.963-7.178Z" />
                    <path stroke-linecap="round" stroke-linejoin="round" d="M15 12a3 3 0 1 1-6 0 3 3 0 0 1 6 0Z" />
                  </svg>
                  <!-- Eye closed -->
                  <svg v-else xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M3.98 8.223A10.477 10.477 0 0 0 1.934 12C3.226 16.338 7.244 19.5 12 19.5c.993 0 1.953-.138 2.863-.395M6.228 6.228A10.451 10.451 0 0 1 12 4.5c4.756 0 8.773 3.162 10.065 7.498a10.522 10.522 0 0 1-4.293 5.774M6.228 6.228 3 3m3.228 3.228 3.65 3.65m7.894 7.894L21 21m-3.228-3.228-3.65-3.65m0 0a3 3 0 1 0-4.243-4.243m4.242 4.242L9.88 9.88" />
                  </svg>
                </button>
              </div>
            </div>

            <!-- Options -->
            <div class="form-options">
              <label class="remember-me">
                <input type="checkbox" v-model="rememberMe" :disabled="isLoading" />
                <span class="checkbox-custom"></span>
                <span>Remember me</span>
              </label>
              <a href="#" class="forgot-password">Forgot password?</a>
            </div>

            <!-- Error -->
            <transition name="shake">
              <div v-if="errorMessage" class="error-banner">
                <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M12 9v3.75m-9.303 3.376c-.866 1.5.217 3.374 1.948 3.374h14.71c1.73 0 2.813-1.874 1.948-3.374L13.949 3.378c-.866-1.5-3.032-1.5-3.898 0L2.697 16.126ZM12 15.75h.007v.008H12v-.008Z" />
                </svg>
                <span>{{ errorMessage }}</span>
              </div>
            </transition>

            <!-- Submit -->
            <button type="submit" class="login-btn" :disabled="isLoading">
              <span v-if="isLoading" class="btn-loading">
                <svg class="spinner" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                  <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                  <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                </svg>
                Signing in...
              </span>
              <span v-else class="btn-content">
                Sign In
                <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M13.5 4.5 21 12m0 0-7.5 7.5M21 12H3" />
                </svg>
              </span>
            </button>
          </form>

          <p class="form-footer">
            Fleet Management System &copy; {{ new Date().getFullYear() }}
          </p>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
/* ─── Base ─── */
.login-page {
  display: flex;
  justify-content: center;
  align-items: center;
  min-height: 100vh;
  background-color: #f3f4f6;
  font-family: 'Segoe UI', system-ui, -apple-system, sans-serif;
  position: relative;
  overflow: hidden;
}

/* ─── Background shapes ─── */
.bg-shape {
  position: absolute;
  border-radius: 50%;
  pointer-events: none;
}
.bg-shape-1 {
  width: 600px;
  height: 600px;
  background: radial-gradient(circle, rgba(79, 70, 229, 0.08) 0%, transparent 70%);
  top: -200px;
  left: -200px;
}
.bg-shape-2 {
  width: 400px;
  height: 400px;
  background: radial-gradient(circle, rgba(5, 150, 105, 0.06) 0%, transparent 70%);
  bottom: -100px;
  right: -100px;
}
.bg-shape-3 {
  width: 300px;
  height: 300px;
  background: radial-gradient(circle, rgba(217, 119, 6, 0.05) 0%, transparent 70%);
  top: 50%;
  right: 30%;
}

/* ─── Main Container ─── */
.login-container {
  display: flex;
  width: 100%;
  max-width: 960px;
  min-height: 580px;
  background: #ffffff;
  border-radius: 20px;
  box-shadow:
    0 4px 6px rgba(0, 0, 0, 0.04),
    0 20px 50px rgba(0, 0, 0, 0.10);
  overflow: hidden;
  margin: 24px;
  animation: slideUp 0.4s ease-out;
}

@keyframes slideUp {
  from { opacity: 0; transform: translateY(20px); }
  to   { opacity: 1; transform: translateY(0); }
}

/* ─── Brand Panel (left) ─── */
.brand-panel {
  flex: 1;
  background: linear-gradient(145deg, #3730a3 0%, #4f46e5 50%, #6366f1 100%);
  padding: 48px 40px;
  display: flex;
  align-items: center;
  position: relative;
  overflow: hidden;
}

.brand-panel::before {
  content: '';
  position: absolute;
  top: -80px;
  right: -80px;
  width: 280px;
  height: 280px;
  background: rgba(255, 255, 255, 0.05);
  border-radius: 50%;
}
.brand-panel::after {
  content: '';
  position: absolute;
  bottom: -60px;
  left: -60px;
  width: 220px;
  height: 220px;
  background: rgba(255, 255, 255, 0.04);
  border-radius: 50%;
}

.brand-content {
  position: relative;
  z-index: 1;
  color: white;
  width: 100%;
}

.brand-icon {
  width: 56px;
  height: 56px;
  background: rgba(255, 255, 255, 0.15);
  border-radius: 14px;
  display: flex;
  align-items: center;
  justify-content: center;
  margin-bottom: 20px;
  backdrop-filter: blur(4px);
}
.brand-icon svg {
  width: 30px;
  height: 30px;
  color: white;
}

.brand-title {
  font-size: 32px;
  font-weight: 700;
  letter-spacing: -0.5px;
  margin: 0 0 4px 0;
  color: white;
}
.brand-title span {
  color: #a5b4fc;
}

.brand-subtitle {
  font-size: 13px;
  color: rgba(255, 255, 255, 0.65);
  margin: 0 0 32px 0;
  font-weight: 400;
  letter-spacing: 0.3px;
}

/* Stats row */
.brand-stats {
  display: flex;
  align-items: center;
  gap: 20px;
  margin-bottom: 32px;
  padding: 16px 0;
  border-top: 1px solid rgba(255,255,255,0.12);
  border-bottom: 1px solid rgba(255,255,255,0.12);
}
.brand-stat {
  display: flex;
  flex-direction: column;
  gap: 2px;
}
.stat-number {
  font-size: 15px;
  font-weight: 700;
  color: white;
}
.stat-label {
  font-size: 11px;
  color: rgba(255,255,255,0.55);
  text-transform: uppercase;
  letter-spacing: 0.5px;
}
.brand-divider {
  width: 1px;
  height: 32px;
  background: rgba(255,255,255,0.2);
}

/* Feature list */
.feature-list {
  display: flex;
  flex-direction: column;
  gap: 12px;
}
.feature-item {
  display: flex;
  align-items: center;
  gap: 10px;
  font-size: 13.5px;
  color: rgba(255, 255, 255, 0.8);
}
.feature-dot {
  width: 6px;
  height: 6px;
  border-radius: 50%;
  background: #a5b4fc;
  flex-shrink: 0;
}

/* ─── Form Panel (right) ─── */
.form-panel {
  flex: 0 0 420px;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 48px 44px;
}

.form-wrapper {
  width: 100%;
}

.form-header {
  margin-bottom: 28px;
}
.form-header h2 {
  font-size: 24px;
  font-weight: 700;
  color: #111827;
  margin: 0 0 6px 0;
  letter-spacing: -0.3px;
}
.form-header p {
  font-size: 14px;
  color: #6b7280;
  margin: 0;
}

/* ─── Form Fields ─── */
.login-form {
  display: flex;
  flex-direction: column;
  gap: 18px;
}

.field-group {
  display: flex;
  flex-direction: column;
  gap: 6px;
}
.field-group label {
  font-size: 13px;
  font-weight: 600;
  color: #374151;
  letter-spacing: 0.1px;
}

.input-wrap {
  position: relative;
  display: flex;
  align-items: center;
}

.input-icon {
  position: absolute;
  left: 12px;
  color: #9ca3af;
  display: flex;
  align-items: center;
  pointer-events: none;
  transition: color 0.2s;
}
.input-icon svg {
  width: 17px;
  height: 17px;
}

.input-wrap input {
  width: 100%;
  padding: 10px 40px 10px 40px;
  font-size: 14px;
  color: #111827;
  background: #f9fafb;
  border: 1.5px solid #e5e7eb;
  border-radius: 10px;
  box-sizing: border-box;
  transition: all 0.2s ease;
  outline: none;
}
.input-wrap input::placeholder {
  color: #d1d5db;
}
.input-wrap input:focus {
  background: #ffffff;
  border-color: #4f46e5;
  box-shadow: 0 0 0 3px rgba(79, 70, 229, 0.1);
}
.input-wrap input:focus ~ .input-icon,
.input-wrap:focus-within .input-icon {
  color: #4f46e5;
}
.input-wrap input:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.toggle-password {
  position: absolute;
  right: 12px;
  background: none;
  border: none;
  color: #9ca3af;
  cursor: pointer;
  padding: 4px;
  display: flex;
  align-items: center;
  border-radius: 4px;
  transition: color 0.2s;
}
.toggle-password:hover {
  color: #4f46e5;
}
.toggle-password svg {
  width: 17px;
  height: 17px;
}

/* ─── Form Options ─── */
.form-options {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-top: -4px;
}

.remember-me {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 13px;
  color: #4b5563;
  cursor: pointer;
  user-select: none;
}
.remember-me input[type="checkbox"] {
  display: none;
}
.checkbox-custom {
  width: 16px;
  height: 16px;
  border: 1.5px solid #d1d5db;
  border-radius: 4px;
  background: #f9fafb;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.15s ease;
  flex-shrink: 0;
}
.remember-me input[type="checkbox"]:checked + .checkbox-custom {
  background: #4f46e5;
  border-color: #4f46e5;
}
.remember-me input[type="checkbox"]:checked + .checkbox-custom::after {
  content: '';
  display: block;
  width: 9px;
  height: 5px;
  border-left: 2px solid white;
  border-bottom: 2px solid white;
  transform: rotate(-45deg) translate(1px, -1px);
}

.forgot-password {
  font-size: 13px;
  color: #4f46e5;
  text-decoration: none;
  font-weight: 500;
  transition: color 0.2s;
}
.forgot-password:hover {
  color: #3730a3;
  text-decoration: underline;
}

/* ─── Error Banner ─── */
.error-banner {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 10px 14px;
  background: #fef2f2;
  border: 1px solid #fecaca;
  border-radius: 10px;
  color: #dc2626;
  font-size: 13.5px;
}
.error-banner svg {
  width: 18px;
  height: 18px;
  flex-shrink: 0;
  color: #ef4444;
}

.shake-enter-active {
  animation: shake 0.4s ease;
}
@keyframes shake {
  0%, 100% { transform: translateX(0); }
  20%       { transform: translateX(-6px); }
  40%       { transform: translateX(6px); }
  60%       { transform: translateX(-4px); }
  80%       { transform: translateX(4px); }
}

/* ─── Submit Button ─── */
.login-btn {
  width: 100%;
  padding: 12px;
  font-size: 14.5px;
  font-weight: 600;
  color: #ffffff;
  background: linear-gradient(135deg, #4f46e5 0%, #4338ca 100%);
  border: none;
  border-radius: 10px;
  cursor: pointer;
  transition: all 0.2s ease;
  box-shadow: 0 2px 8px rgba(79, 70, 229, 0.35);
  margin-top: 4px;
}
.login-btn:hover:not(:disabled) {
  background: linear-gradient(135deg, #4338ca 0%, #3730a3 100%);
  box-shadow: 0 4px 14px rgba(79, 70, 229, 0.45);
  transform: translateY(-1px);
}
.login-btn:active:not(:disabled) {
  transform: translateY(0);
}
.login-btn:disabled {
  opacity: 0.65;
  cursor: not-allowed;
  box-shadow: none;
  transform: none;
}

.btn-content,
.btn-loading {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
}
.btn-content svg {
  width: 16px;
  height: 16px;
  transition: transform 0.2s;
}
.login-btn:hover:not(:disabled) .btn-content svg {
  transform: translateX(3px);
}

.spinner {
  width: 18px;
  height: 18px;
  animation: spin 0.8s linear infinite;
}
@keyframes spin {
  from { transform: rotate(0deg); }
  to   { transform: rotate(360deg); }
}

/* ─── Footer ─── */
.form-footer {
  margin-top: 28px;
  text-align: center;
  font-size: 12px;
  color: #9ca3af;
}

/* ─── Responsive ─── */
@media (max-width: 720px) {
  .brand-panel {
    display: none;
  }
  .form-panel {
    flex: 1;
    padding: 40px 28px;
  }
  .login-container {
    margin: 16px;
    min-height: auto;
  }
}
</style>