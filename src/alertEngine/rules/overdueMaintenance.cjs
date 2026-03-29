const { AlertRule } = require('../ruleInterface.cjs')

class OverdueMaintenanceRule extends AlertRule {
  constructor() {
    super()
    this.name = 'เลยกำหนดการซ่อมบำรุง'
    this.severity = 'CRITICAL'
  }

  async check(pool) {
    const [maintenances] = await pool.query(`
      SELECT m.id, m.vehicle_id, m.scheduled_at, m.type, v.license_plate
      FROM maintenance m
      JOIN vehicles v ON m.vehicle_id = v.id
      WHERE m.status = 'SCHEDULED'
        AND DATE(m.scheduled_at) < DATE_SUB(CURDATE(), INTERVAL 3 DAY)
    `)

    return maintenances.map((m) => ({
      id: `alert_om_${m.id}`,
      rule_name: this.name,
      severity: this.severity,
      affected_resource_type: 'MAINTENANCE',
      affected_resource_id: m.id,
      message: `การซ่อมบำรุงสำหรับยานพาหนะ ${m.license_plate} (${m.type}) วันที่ ${m.scheduled_at} เลยกำหนดมาแล้วกว่า 3 วัน`,
      created_at: new Date(),
    }))
  }
}

module.exports = { OverdueMaintenanceRule }
