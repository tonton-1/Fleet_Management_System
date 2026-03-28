class AlertRule {
  constructor() {
    this.name = 'BaseRule'
    this.severity = 'WARNING'
  }

  async check(pool) {
    throw new Error('Rule must implement check(pool) method')
  }

  getName() {
    return this.name
  }

  getSeverity() {
    return this.severity
  }
}

module.exports = { AlertRule }
