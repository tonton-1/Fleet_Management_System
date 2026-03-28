import apiClient from './axios'

export const alertsApi = {
  getAlerts(params = {}) {
    return apiClient.get('/alerts', { params })
  },
}
