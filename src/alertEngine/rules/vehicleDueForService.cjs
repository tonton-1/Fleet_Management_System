const { AlertRule } = require('../ruleInterface.cjs')

class VehicleDueForServiceRule extends AlertRule {
  constructor() {
    super()
    this.name = 'รถยนต์ถึงกำหนดรับบริการ'
    this.severity = 'WARNING'
  }

  async check(pool) {
    const [vehicles] = await pool.query(`
      SELECT id, license_plate, mileage_km, next_service_km
      FROM vehicles
      WHERE next_service_km IS NOT NULL
        AND mileage_km >= next_service_km
        AND status != 'RETIRED'
    `)

    return vehicles.map((v) => ({
      id: `alert_vds_${v.id}`,
      rule_name: this.name,
      severity: this.severity,
      affected_resource_type: 'VEHICLE',
      affected_resource_id: v.id,
      message: `ยานพาหนะ ${v.license_plate} มีระยะทาง ${v.mileage_km} กม. เกินกำหนดการรับบริการครั้งต่อไป (${v.next_service_km} กม.)`,
      created_at: new Date(),
    }))
  }
}

module.exports = { VehicleDueForServiceRule }
