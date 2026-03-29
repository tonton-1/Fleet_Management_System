import Swal from 'sweetalert2'
import router from '../router'

let expirationTimer = null
let warningTimer = null

function parseJwt(token) {
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
  } catch {
    return null
  }
}

function showExpiredAlert(redirectUrl = '/') {
  Swal.fire({
    title: 'เซสชันหมดอายุ',
    text: 'กรุณาเข้าสู่ระบบใหม่อีกครั้ง',
    icon: 'error',
    showConfirmButton: true,
    allowOutsideClick: false,
  }).then(() => {
    logoutAndRedirect(redirectUrl)
  })
}

function logoutAndRedirect(redirectUrl) {
  localStorage.removeItem('accessToken')
  localStorage.removeItem('refreshToken')
  localStorage.removeItem('token')
  router.push(redirectUrl)
}

export function startTokenExpirationWatcher() {
  function checkTokenExpiration() {
    const token = localStorage.getItem('accessToken')
    if (!token) return

    const decoded = parseJwt(token)
    if (!decoded || !decoded.exp) return

    const now = Math.floor(Date.now() / 1000)
    const expiresIn = decoded.exp - now

    if (expiresIn <= 0) {
      showExpiredAlert('/')
      return
    }

    if (warningTimer) clearTimeout(warningTimer)
    if (expirationTimer) clearTimeout(expirationTimer)

    const warningTime = 60
    if (expiresIn > warningTime) {
      warningTimer = setTimeout(
        () => {
          showExpiredAlert('/')
        },
        (expiresIn - warningTime) * 1000,
      )
    } else if (expiresIn > 0) {
      showExpiredAlert('/')
      return
    }
  }

  checkTokenExpiration()
  setInterval(checkTokenExpiration, 10000)
}

export function stopTokenExpirationWatcher() {
  if (warningTimer) clearTimeout(warningTimer)
  if (expirationTimer) clearTimeout(expirationTimer)
  warningTimer = null
  expirationTimer = null
}
