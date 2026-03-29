import apiClient from './axios'

export const auditLogsApi = {
  getAuditLogs(params = {}) {
    return apiClient.get('/audit-logs', { params })
  },
}
