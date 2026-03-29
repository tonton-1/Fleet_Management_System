const { AlertRule } = require('../ruleInterface.cjs')

class LicenseExpiringSoonRule extends AlertRule {
  constructor() {
    super()
    this.name = 'ใบอนุญาตใกล้หมดอายุ'
    this.severity = 'WARNING'
  }

  async check(pool) {
    const [drivers] = await pool.query(`
      SELECT id, name, license_number, license_expires_at
      FROM drivers
      WHERE status = 'ACTIVE'
        AND license_expires_at BETWEEN CURDATE() AND DATE_ADD(CURDATE(), INTERVAL 30 DAY)
    `)

    return drivers.map((d) => ({
      id: `alert_les_${d.id}`,
      rule_name: this.name,
      severity: this.severity,
      affected_resource_type: 'DRIVER',
      affected_resource_id: d.id,
      message: `ใบอนุญาตของพนักงานขับรถ ${d.name} (${d.license_number}) จะหมดอายุในวันที่ ${d.license_expires_at} (ภายใน 30 วัน)`,
      created_at: new Date(),
    }))
  }
}

module.exports = { LicenseExpiringSoonRule }
