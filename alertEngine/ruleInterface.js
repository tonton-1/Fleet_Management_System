class AlertRule {
  constructor(config = {}) {
    this.name = 'BaseRule'
    this.severity = 'WARNING'
    this.config = config
  }

  async check(db) {
    throw new Error('Rule must implement check(db) method')
  }

  getName() {
    return this.name
  }

  getSeverity() {
    return this.severity
  }
}

module.exports = { AlertRule }
