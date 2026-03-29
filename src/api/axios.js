import axios from 'axios'
import router from '../router'
import { stopTokenExpirationWatcher } from '../utils/tokenExpiration'

const apiClient = axios.create({
  baseURL: 'http://localhost:3000', // Set the base URL for all requests
  headers: {
    'Content-Type': 'application/json',
  },
})

// Add a request interceptor to include the token in headers
apiClient.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('accessToken')
    if (token) {
      config.headers['Authorization'] = `Bearer ${token}`
    }
    return config
  },
  (error) => {
    return Promise.reject(error)
  },
)

// Add a response interceptor to handle errors globally
apiClient.interceptors.response.use(
  (response) => {
    return response
  },
  async (error) => {
    const originalRequest = error.config

    // Log the error JSON structure exactly as requested
    if (error.response && error.response.data && error.response.data.error) {
      console.error(JSON.stringify(error.response.data, null, 2))
    } else {
      console.error('Unhandled Error:', error.message)
    }

    // 2. จัดการ Token หมดอายุ (401) และพยายาม Refresh
    if (error.response && error.response.status === 401 && !originalRequest._retry) {
      originalRequest._retry = true // ป้องกันการวนลูปไม่รู้จบ

      try {
        const refreshToken = localStorage.getItem('refreshToken')
        if (refreshToken) {
          // ลองนำ Refresh Token ไปขอ Access Token ใหม่จาก Backend
          const res = await axios.post('http://localhost:3000/auth/refresh', {
            refresh_token: refreshToken,
          })

          if (res.status === 200) {
            // สำเร็จ: บันทึก Token ใหม่ และลองรัน Request เดิมที่ล้มเหลวไปอีกครั้ง
            localStorage.setItem('accessToken', res.data.access_token)

            // แอบอัปเดต Header ใน Request เก่าด้วย Token ใหม่
            originalRequest.headers['Authorization'] = `Bearer ${res.data.access_token}`

            return apiClient(originalRequest)
          }
        }
      } catch (refreshError) {
        console.error('Refresh Token failed or expired:', refreshError)
      }

      // ถ้า Refresh ไม่ผ่าน หรือไม่มี Refresh Token ให้เคลียร์ข้อมูลแล้วเด้งไปหน้า Login
      stopTokenExpirationWatcher()
      localStorage.removeItem('accessToken')
      localStorage.removeItem('refreshToken')
      router.push('/')
    }

    return Promise.reject(error)
  },
)

export default apiClient
