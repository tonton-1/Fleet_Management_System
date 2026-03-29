import apiClient from './axios'

export const maintenanceApi = {
  getAll() {
    return apiClient.get('/maintenance')
  },
}
