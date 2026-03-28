const { AlertRule } = require('../ruleInterface')

class TripDelayedRule extends AlertRule {
  constructor() {
    super()
    this.name = 'Trip Delayed'
    this.severity = 'WARNING'
  }

  async check(pool) {
    const [trips] = await pool.query(`
      SELECT t.id, t.started_at, t.distance_km, v.license_plate, d.name as driver_name
      FROM trips t
      JOIN vehicles v ON t.vehicle_id = v.id
      JOIN drivers d ON t.driver_id = d.id
      WHERE t.status = 'IN_PROGRESS'
        AND t.started_at IS NOT NULL
    `)

    const alerts = []
    const now = new Date()

    for (const trip of trips) {
      const startedAt = new Date(trip.started_at)
      const distanceKm = parseFloat(trip.distance_km) || 0

      const estimatedMinutes = distanceKm * 1.2
      const maxAllowedMinutes = estimatedMinutes * 1.5

      const elapsedMinutes = (now - startedAt) / (1000 * 60)

      if (elapsedMinutes > maxAllowedMinutes) {
        alerts.push({
          id: `alert_td_${trip.id}`,
          rule_name: this.name,
          severity: this.severity,
          affected_resource_type: 'TRIP',
          affected_resource_id: trip.id,
          message: `Trip ${trip.id} for vehicle ${trip.license_plate} (driver: ${trip.driver_name}) has exceeded 150% of estimated duration (${Math.round(elapsedMinutes)}min vs ${Math.round(maxAllowedMinutes)}min estimated)`,
          created_at: now,
        })
      }
    }

    return alerts
  }
}

module.exports = { TripDelayedRule }
