const { AlertRule } = require('../ruleInterface')

class LicenseExpiringSoonRule extends AlertRule {
  constructor() {
    super()
    this.name = 'License Expiring Soon'
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
      message: `Driver ${d.name}'s license (${d.license_number}) expires on ${d.license_expires_at} (within 30 days)`,
      created_at: new Date(),
    }))
  }
}

module.exports = { LicenseExpiringSoonRule }
