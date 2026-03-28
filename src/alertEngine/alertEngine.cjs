const fs = require('fs')
const path = require('path')

class AlertEngine {
  constructor(pool) {
    this.pool = pool
    this.rules = []
    this.loadRules()
  }

  loadRules() {
    const rulesDir = path.join(__dirname, 'rules')

    if (!fs.existsSync(rulesDir)) {
      console.warn('Rules directory not found:', rulesDir)
      return
    }

    const files = fs.readdirSync(rulesDir).filter((f) => f.endsWith('.cjs'))

    for (const file of files) {
      try {
        const RuleModule = require(path.join(rulesDir, file))
        const RuleClass = RuleModule[Object.keys(RuleModule)[0]]
        const ruleInstance = new RuleClass()
        this.rules.push(ruleInstance)
        console.log(`[AlertEngine] Loaded rule: ${ruleInstance.getName()}`)
      } catch (err) {
        console.error(`[AlertEngine] Failed to load rule ${file}:`, err.message)
      }
    }

    console.log(`[AlertEngine] Total rules loaded: ${this.rules.length}`)
  }

  async evaluateAll() {
    const allAlerts = []

    for (const rule of this.rules) {
      try {
        const alerts = await rule.check(this.pool)
        if (alerts && alerts.length > 0) {
          allAlerts.push(...alerts)
        }
      } catch (err) {
        console.error(`[AlertEngine] Error running rule ${rule.getName()}:`, err.message)
      }
    }

    return allAlerts
  }

  async syncToDatabase() {
    const alerts = await this.evaluateAll()

    const connection = await this.pool.getConnection()
    try {
      await connection.beginTransaction()

      await connection.query('DELETE FROM alerts')

      if (alerts.length > 0) {
        const values = alerts.map((a) => [
          a.id,
          a.rule_name,
          a.severity,
          a.affected_resource_type,
          a.affected_resource_id,
          a.message,
          a.created_at,
        ])

        await connection.query(
          `
          INSERT INTO alerts (id, rule_name, severity, affected_resource_type, affected_resource_id, message, created_at)
          VALUES ?
        `,
          [values],
        )
      }

      await connection.commit()
      console.log(`[AlertEngine] Synced ${alerts.length} alerts to database`)
    } catch (err) {
      await connection.rollback()
      console.error('[AlertEngine] Failed to sync alerts:', err.message)
    } finally {
      connection.release()
    }
  }
}

module.exports = { AlertEngine }
