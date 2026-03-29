import apiClient from './axios'

export const chartsApi = {
  getVehiclesByStatus() {
    return apiClient.get('/charts/vehicles-by-status')
  },
  getTripDistanceTrend() {
    return apiClient.get('/charts/trip-distance-trend')
  },
}
