const express = require('express')
const mysql = require('mysql2/promise')
const bcrypt = require('bcrypt')
const jwt = require('jsonwebtoken')
const cors = require('cors')
const path = require('path')
const crypto = require('crypto')
const fs = require('fs')
require('dotenv').config()

const app = express()
app.use(express.json())
app.use(cors())
app.use(express.static(path.join(__dirname, 'public')))

// --- Scalar API Reference ---
const swaggerDocumentPath = path.join(__dirname, 'swagger-output.json')
if (fs.existsSync(swaggerDocumentPath)) {
  const swaggerDocument = require('./swagger-output.json')

  // Use dynamic import for Scalar since it is an ESM module
  import('@scalar/express-api-reference')
    .then(({ apiReference }) => {
      app.use(
        '/docs',
        apiReference({
          spec: {
            content: swaggerDocument,
          },
          theme: 'moon',
          layout: 'modern',
        }),
      )
    })
    .catch((err) => {
      console.error('Failed to load Scalar API Reference:', err)
    })
}
// ----------------------------

// Create DB connection pool
const pool = mysql.createPool({
  host: process.env.DB_HOST,
  port: process.env.DB_PORT,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0,
})

// Common Error Schema Response Helper
const sendError = (res, statusCode, code, message, details = {}) => {
  return res.status(statusCode).json({
    error: {
      code,
      message,
      details,
    },
  })
}

// Middleware to authenticate JWT
const authenticateToken = (req, res, next) => {
  const authHeader = req.headers['authorization']
  const token = authHeader && authHeader.split(' ')[1]

  if (!token) {
    return sendError(res, 401, 'UNAUTHORIZED', 'Access token is missing or invalid')
  }

  jwt.verify(token, process.env.JWT_ACCESS_SECRET, (err, user) => {
    if (err) {
      return sendError(
        res,
        401,
        'UNAUTHORIZED',
        'Token is invalid or expired. Please refresh the token.',
      )
    }
    req.user = user
    next()
  })
}

// Middleware to protect routes by role
const requireRole = (...allowedRoles) => {
  return (req, res, next) => {
    if (!req.user || !req.user.role) {
      return sendError(res, 403, 'FORBIDDEN', 'User role is missing or undefined')
    }
    if (!allowedRoles.includes(req.user.role)) {
      return sendError(
        res,
        403,
        'FORBIDDEN',
        `Access restricted to ${allowedRoles.join(' or ')} only`,
      )
    }
    next()
  }
}

// Audit Log Helper (Append-only)
const logAudit = async (req, action, resourceType, resourceId, result, detail = null) => {
  try {
    const id = crypto.randomUUID()
    const userId = req?.user?.id || null

    await pool.query(
      `INSERT INTO audit_logs (id, user_id, action, resource_type, resource_id, result, detail, ip_address)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        id,
        userId,
        action,
        resourceType,
        resourceId,
        result,
        detail ? JSON.stringify(detail) : null,
        req?.ip || null,
      ],
    )
  } catch (err) {
    console.error('[Audit] Failed to log:', err.message)
  }
}

// POST /auth/login endpoint
app.post('/auth/login', async (req, res) => {
  /*
    #swagger.tags = ['Auth']
    #swagger.summary = 'User Login'
    #swagger.description = 'Authenticate and receive a JWT access and refresh token.'
    #swagger.parameters['body'] = {
        in: 'body',
        description: 'Credentials to login',
        required: true,
        schema: {
            username: "admin",
            password: "password123"
        }
    }
  */
  const { username, password } = req.body

  if (!username || !password) {
    return sendError(res, 400, 'BAD_REQUEST', 'Username and password are required')
  }

  try {
    const [rows] = await pool.query('SELECT * FROM users WHERE username = ?', [username])

    if (rows.length === 0) {
      await logAudit(req, 'LOGIN_FAIL', 'AUTH', null, 'FAIL', { username })
      return sendError(res, 401, 'UNAUTHORIZED', 'Invalid username or password')
    }

    const user = rows[0]
    const match = await bcrypt.compare(password, user.password_hash)

    if (!match) {
      await logAudit(req, 'LOGIN_FAIL', 'AUTH', null, 'FAIL', { username })
      return sendError(res, 401, 'UNAUTHORIZED', 'Invalid username or password')
    }

    const payload = { id: user.id, username: user.username, role: user.role }
    const accessToken = jwt.sign(payload, process.env.JWT_ACCESS_SECRET, { expiresIn: '15m' })
    const refreshToken = jwt.sign(payload, process.env.JWT_REFRESH_SECRET, { expiresIn: '7d' })

    req.user = user // set for audit logger
    await logAudit(req, 'LOGIN_SUCCESS', 'AUTH', user.id, 'SUCCESS', { username, role: user.role })

    res.json({
      access_token: accessToken,
      refresh_token: refreshToken,
    })
  } catch (error) {
    console.error(error)
    return sendError(res, 500, 'INTERNAL_SERVER_ERROR', 'An error occurred during login')
  }
})

// POST /vehicles endpoint
app.post('/vehicles', authenticateToken, async (req, res) => {
  /*
    #swagger.tags = ['Vehicles']
    #swagger.summary = 'Register New Vehicle'
    #swagger.description = 'Add a new vehicle to the fleet management system.'
    #swagger.parameters['body'] = {
        in: 'body',
        description: 'New vehicle payload',
        required: true,
        schema: {
            license_plate: "กค 1234",
            type: "TRUCK",
            status: "IDLE",
            driver_id: "drv_001",
            context: {
                brand: "Isuzu",
                model: "D-Max",
                year: "2022",
                fuel_type: "DIESEL",
                mileage_km: 15400,
                last_service_km: 10000,
                next_service_km: 20000
            }
        }
    }
  */
  try {
    const { id, license_plate, type, status = 'IDLE', driver_id, context = {} } = req.body

    const {
      brand,
      model,
      year,
      fuel_type,
      mileage_km = 0,
      last_service_km,
      next_service_km,
    } = context

    // Field Validation
    const details = {}
    if (!license_plate) details.license_plate = 'license_plate is required'
    if (!type) details.type = 'type is required'

    const validTypes = ['TRUCK', 'VAN', 'MOTORCYCLE', 'PICKUP']
    if (type && !validTypes.includes(type)) {
      details.type = `type must be one of: ${validTypes.join(', ')}`
    }

    const validStatuses = ['ACTIVE', 'IDLE', 'MAINTENANCE', 'RETIRED']
    if (status && !validStatuses.includes(status)) {
      details.status = `status must be one of: ${validStatuses.join(', ')}`
    }

    const validFuelTypes = ['DIESEL', 'GASOLINE', 'ELECTRIC', 'HYBRID']
    if (fuel_type && !validFuelTypes.includes(fuel_type)) {
      details.fuel_type = `fuel_type must be one of: ${validFuelTypes.join(', ')}`
    }

    // Number format validation for mileage and service formats
    if (year && isNaN(parseInt(year))) details.year = 'year must be a valid number'
    if (mileage_km && isNaN(parseInt(mileage_km)))
      details.mileage_km = 'mileage_km must be a valid number'
    if (last_service_km && isNaN(parseInt(last_service_km)))
      details.last_service_km = 'last_service_km must be a valid number'
    if (next_service_km && isNaN(parseInt(next_service_km)))
      details.next_service_km = 'next_service_km must be a valid number'

    // If any validation fails, return 400 VALIDATION_ERROR using the universal error schema
    if (Object.keys(details).length > 0) {
      return sendError(
        res,
        400,
        'VALIDATION_ERROR',
        'Invalid data format or missing required fields',
        details,
      )
    }

    let finalId = id
    if (!finalId) {
      const [rows] = await pool.query(
        "SELECT id FROM vehicles WHERE id LIKE 'veh_%' ORDER BY CAST(SUBSTRING(id, 5) AS UNSIGNED) DESC LIMIT 1",
      )
      if (rows.length > 0) {
        const lastId = rows[0].id
        finalId = `veh_${String(parseInt(lastId.substring(4), 10) + 1).padStart(3, '0')}`
      } else {
        finalId = 'veh_001'
      }
    }

    const query = `
      INSERT INTO vehicles (
        id, license_plate, type, status, driver_id, brand, model, 
        year, fuel_type, mileage_km, last_service_km, next_service_km
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `

    const values = [
      finalId,
      license_plate,
      type,
      status,
      driver_id || null,
      brand || null,
      model || null,
      year ? parseInt(year) : null,
      fuel_type || null,
      parseInt(mileage_km),
      last_service_km ? parseInt(last_service_km) : null,
      next_service_km ? parseInt(next_service_km) : null,
    ]

    await pool.query(query, values)

    // Fetch and return immediately
    const [rows] = await pool.query('SELECT * FROM vehicles WHERE id = ?', [finalId])

    // Format JSON response to match requested nested structure
    const dbVeh = rows[0]
    const responsePayload = {
      id: dbVeh.id,
      license_plate: dbVeh.license_plate,
      type: dbVeh.type,
      status: dbVeh.status,
      driver_id: dbVeh.driver_id,
      context: {
        brand: dbVeh.brand,
        model: dbVeh.model,
        year: dbVeh.year,
        fuel_type: dbVeh.fuel_type,
        mileage_km: dbVeh.mileage_km,
        last_service_km: dbVeh.last_service_km,
        next_service_km: dbVeh.next_service_km,
      },
    }

    res.status(201).json(responsePayload)

    await logAudit(req, 'CREATE_VEHICLE', 'VEHICLE', finalId, 'SUCCESS', { license_plate, type })
  } catch (error) {
    console.error(error)
    if (error.code === 'ER_DUP_ENTRY') {
      return sendError(res, 409, 'CONFLICT', 'License plate already exists', {
        license_plate: req.body.license_plate,
      })
    }
    if (error.code === 'ER_NO_REFERENCED_ROW_2') {
      return sendError(res, 400, 'VALIDATION_ERROR', 'Invalid driver_id provided', {
        driver_id: req.body.driver_id,
      })
    }
    return sendError(res, 500, 'INTERNAL_SERVER_ERROR', 'Database execution failed', {
      detail: error.message,
    })
  }
})

// GET /dashboard endpoint
app.get('/dashboard', authenticateToken, async (req, res) => {
  /*
    #swagger.tags = ['Dashboard']
    #swagger.summary = 'Get Dashboard Overview Stats'
    #swagger.description = 'Fetch real-time stats for fleet, trips, and maintenance alerts.'
    #swagger.responses[200] = {
        description: 'Dashboard stats payload'
    }
  */
  try {
    const [fleetStats] = await pool.query(`
      SELECT 
        COUNT(*) as total_vehicles,
        SUM(CASE WHEN status = 'ACTIVE' THEN 1 ELSE 0 END) as active_vehicles,
        SUM(CASE WHEN status = 'MAINTENANCE' THEN 1 ELSE 0 END) as maintenance_vehicles
      FROM vehicles
    `)

    const [activeTripsStats] = await pool.query(`
      SELECT 
        COUNT(*) as active_trips_count,
        COALESCE(SUM(distance_km), 0) as total_distance_today
      FROM trips 
      WHERE DATE(created_at) = CURDATE() 
        AND status IN ('SCHEDULED', 'IN_PROGRESS')
    `)

    const [overdueMaintenance] = await pool.query(`
      SELECT COUNT(*) as overdue_count
      FROM maintenance
      WHERE status = 'OVERDUE'
        OR (status = 'SCHEDULED' AND DATE(scheduled_at) < CURDATE())
    `)

    const [activeTrips] = await pool.query(`
      SELECT t.id, t.origin, t.destination, t.status, v.license_plate, d.name as driver_name
      FROM trips t
      LEFT JOIN vehicles v ON t.vehicle_id = v.id
      LEFT JOIN drivers d ON t.driver_id = d.id
      WHERE t.status IN ('SCHEDULED', 'IN_PROGRESS')
      ORDER BY t.created_at DESC
      LIMIT 10
    `)

    const [maintenanceAlerts] = await pool.query(`
      SELECT id, license_plate, mileage_km, next_service_km, status
      FROM vehicles
      WHERE next_service_km IS NOT NULL AND (next_service_km - mileage_km) <= 1500
         OR status = 'MAINTENANCE'
      ORDER BY (next_service_km - mileage_km) ASC
      LIMIT 10
    `)

    res.json({
      stats: {
        ...fleetStats[0],
        active_trips_count: activeTripsStats[0].active_trips_count || 0,
        total_distance_today: activeTripsStats[0].total_distance_today || 0,
        overdue_maintenance_count: overdueMaintenance[0].overdue_count || 0,
      },
      active_trips: activeTrips,
      maintenance_alerts: maintenanceAlerts,
    })
  } catch (err) {
    console.error(err)
    return sendError(res, 500, 'INTERNAL_SERVER_ERROR', 'Failed to fetch dashboard data')
  }
})

// GET /charts/vehicles-by-status endpoint
app.get('/charts/vehicles-by-status', authenticateToken, async (req, res) => {
  /*
    #swagger.tags = ['Charts']
    #swagger.summary = 'Vehicle Status Chart'
    #swagger.description = 'Counts of vehicles grouped by their operational status.'
  */
  try {
    const [results] = await pool.query(`
      SELECT status, COUNT(*) as count
      FROM vehicles
      GROUP BY status
    `)

    const data = {
      ACTIVE: 0,
      IDLE: 0,
      MAINTENANCE: 0,
      RETIRED: 0,
    }

    results.forEach((row) => {
      if (data.hasOwnProperty(row.status)) {
        data[row.status] = row.count
      }
    })

    res.json(data)
  } catch (err) {
    console.error(err)
    return sendError(res, 500, 'INTERNAL_SERVER_ERROR', 'Failed to fetch vehicles by status')
  }
})

// GET /charts/trip-distance-trend endpoint
app.get('/charts/trip-distance-trend', authenticateToken, async (req, res) => {
  /*
    #swagger.tags = ['Charts']
    #swagger.summary = 'Trip Distance Trend'
    #swagger.description = 'Distance covered over the last 7 days.'
  */
  try {
    const [results] = await pool.query(`
      SELECT 
        DATE(created_at) as date,
        SUM(distance_km) as total_distance
      FROM trips
      WHERE created_at >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)
        AND status = 'COMPLETED'
      GROUP BY DATE(created_at)
      ORDER BY date ASC
    `)

    const last7Days = []
    for (let i = 6; i >= 0; i--) {
      const d = new Date()
      d.setDate(d.getDate() - i)
      const dateStr = d.toISOString().split('T')[0]
      last7Days.push(dateStr)
    }

    const data = last7Days.map((date) => {
      const found = results.find((r) => {
        const rDate = new Date(r.date).toISOString().split('T')[0]
        return rDate === date
      })
      return {
        date,
        distance: found ? parseFloat(found.total_distance) : 0,
      }
    })

    res.json(data)
  } catch (err) {
    console.error(err)
    return sendError(res, 500, 'INTERNAL_SERVER_ERROR', 'Failed to fetch trip distance trend')
  }
})

// GET /drivers endpoint
app.get('/drivers', authenticateToken, async (req, res) => {
  /*
    #swagger.tags = ['Drivers']
    #swagger.summary = 'List All Drivers'
    #swagger.description = 'Fetch all registered drivers sorted by name.'
  */
  try {
    const [rows] = await pool.query('SELECT * FROM drivers ORDER BY name ASC')
    res.json(rows)
  } catch (err) {
    console.error(err)
    return sendError(res, 500, 'INTERNAL_SERVER_ERROR', 'Failed to fetch drivers')
  }
})

// POST /drivers endpoint
app.post('/drivers', authenticateToken, async (req, res) => {
  /*
    #swagger.tags = ['Drivers']
    #swagger.summary = 'Register New Driver'
    #swagger.description = 'Add a new driver to the system. Phone must be 10 digits and license must be 9 digits.'
    #swagger.parameters['body'] = {
        in: 'body',
        description: 'New driver payload',
        required: true,
        schema: {
            name: "Somchai Jaidee",
            license_number: "123456789",
            license_expires_at: "2030-12-31",
            phone: "0812345678",
            status: "ACTIVE"
        }
    }
  */
  try {
    const { id, name, license_number, license_expires_at, phone, status = 'ACTIVE' } = req.body

    // Field Validation
    const details = {}
    if (!name) details.name = 'name is required'
    if (!license_number) {
      details.license_number = 'license_number is required'
    } else if (license_number.length !== 9) {
      details.license_number = 'license_number must be exactly 9 characters'
    }
    if (!license_expires_at) details.license_expires_at = 'license_expires_at is required'

    if (!phone) {
      details.phone = 'phone is required'
    } else if (phone.length !== 10) {
      details.phone = 'phone must be exactly 10 digits'
    }

    const validStatuses = ['ACTIVE', 'INACTIVE', 'SUSPENDED']
    if (status && !validStatuses.includes(status)) {
      details.status = `status must be one of: ${validStatuses.join(', ')}`
    }

    if (Object.keys(details).length > 0) {
      return sendError(
        res,
        400,
        'VALIDATION_ERROR',
        'Invalid data format or missing required fields',
        details,
      )
    }

    let finalId = id
    if (!finalId) {
      const [rows] = await pool.query(
        "SELECT id FROM drivers WHERE id LIKE 'drv_%' ORDER BY CAST(SUBSTRING(id, 5) AS UNSIGNED) DESC LIMIT 1",
      )
      if (rows.length > 0) {
        const lastId = rows[0].id
        const numberPart = parseInt(lastId.substring(4), 10)
        const nextNumber = numberPart + 1
        finalId = `drv_${String(nextNumber).padStart(3, '0')}`
      } else {
        finalId = 'drv_001'
      }
    }

    const query = `
      INSERT INTO drivers (
        id, name, license_number, license_expires_at, phone, status
      ) VALUES (?, ?, ?, ?, ?, ?)
    `

    // We expect license_expires_at format: YYYY-MM-DD
    const values = [finalId, name, license_number, license_expires_at, phone, status]

    await pool.query(query, values)

    // Fetch and return immediately
    const [rows] = await pool.query('SELECT * FROM drivers WHERE id = ?', [finalId])
    res.status(201).json(rows[0])
  } catch (error) {
    console.error(error)
    if (error.code === 'ER_DUP_ENTRY') {
      return sendError(res, 409, 'CONFLICT', 'License number already exists', {
        license_number: req.body.license_number,
      })
    }
    return sendError(res, 500, 'INTERNAL_SERVER_ERROR', 'Database execution failed', {
      detail: error.message,
    })
  }
})

// PATCH /drivers/:id endpoint - Full update (ADMIN only)
app.patch('/drivers/:id', authenticateToken, requireRole('ADMIN'), async (req, res) => {
  /*
    #swagger.tags = ['Drivers']
    #swagger.summary = 'Update Driver Info (Admin)'
    #swagger.parameters['body'] = {
        in: 'body',
        description: 'Update fields',
        schema: {
            name: "Somchai Jaidee",
            license_number: "123456789",
            license_expires_at: "2030-12-31",
            phone: "0812345678",
            status: "INACTIVE"
        }
    }
  */
  const { id } = req.params
  const { name, license_number, license_expires_at, phone, status } = req.body

  try {
    const [driver] = await pool.query('SELECT * FROM drivers WHERE id = ?', [id])
    if (driver.length === 0) return sendError(res, 404, 'NOT_FOUND', 'Driver not found')

    // Cannot change status if driver has IN_PROGRESS trip
    if (status && status !== driver[0].status) {
      const [activeTrips] = await pool.query(
        'SELECT id FROM trips WHERE driver_id = ? AND status = ?',
        [id, 'IN_PROGRESS'],
      )
      if (activeTrips.length > 0) {
        return sendError(
          res,
          409,
          'CONFLICT',
          'Cannot change status of a driver currently on an active trip',
        )
      }
    }

    const newName = name || driver[0].name
    const newLicense = license_number || driver[0].license_number
    const newExpiry = license_expires_at || driver[0].license_expires_at
    const newPhone = phone || driver[0].phone
    const newStatus = status || driver[0].status

    await pool.query(
      `UPDATE drivers SET name = ?, license_number = ?, license_expires_at = ?, phone = ?, status = ?, updated_at = NOW() WHERE id = ?`,
      [newName, newLicense, newExpiry, newPhone, newStatus, id],
    )

    await logAudit(req, 'UPDATE_DRIVER', 'DRIVER', id, 'SUCCESS', { name: newName, status: newStatus })
    res.json({ message: 'Driver updated successfully' })
  } catch (err) {
    console.error(err)
    if (err.code === 'ER_DUP_ENTRY') {
      return sendError(res, 409, 'CONFLICT', 'License number already in use by another driver')
    }
    return sendError(res, 500, 'INTERNAL_SERVER_ERROR', 'Failed to update driver')
  }
})

// DELETE /drivers/:id endpoint
app.delete('/drivers/:id', authenticateToken, requireRole('ADMIN'), async (req, res) => {
  /*
    #swagger.tags = ['Drivers']
    #swagger.summary = 'Delete Driver'
  */
  const { id } = req.params
  try {
    const [driver] = await pool.query('SELECT id FROM drivers WHERE id = ?', [id])
    if (driver.length === 0) return sendError(res, 404, 'NOT_FOUND', 'Driver not found')

    // Cannot delete if driver has IN_PROGRESS trip
    const [activeTrips] = await pool.query(
      'SELECT id FROM trips WHERE driver_id = ? AND status = ?',
      [id, 'IN_PROGRESS'],
    )
    if (activeTrips.length > 0) {
      return sendError(res, 409, 'CONFLICT', 'Cannot delete driver currently on an active trip')
    }

    await pool.query('DELETE FROM drivers WHERE id = ?', [id])
    res.status(204).send()
  } catch (err) {
    console.error(err)
    return sendError(res, 500, 'INTERNAL_SERVER_ERROR', 'Failed to delete driver')
  }
})

// POST /auth/refresh endpoint
app.post('/auth/refresh', (req, res) => {
  /*
    #swagger.tags = ['Auth']
    #swagger.summary = 'Refresh Access Token'
    #swagger.parameters['body'] = {
        in: 'body',
        description: 'Previously acquired refresh token',
        required: true,
        schema: { refresh_token: "eyJhbGciOiJIUz..." }
    }
  */
  const { refresh_token } = req.body
  if (!refresh_token) return sendError(res, 401, 'UNAUTHORIZED', 'Refresh token required')

  jwt.verify(refresh_token, process.env.JWT_SECRET || 'secret123', (err, user) => {
    if (err) return sendError(res, 403, 'FORBIDDEN', 'Invalid refresh token')

    const accessToken = jwt.sign(
      { userId: user.userId, username: user.username, role: user.role },
      process.env.JWT_SECRET || 'secret123',
      { expiresIn: '15m' },
    )
    res.json({ access_token: accessToken })
  })
})

// Helper route to create a test user
app.post('/auth/register', async (req, res) => {
  /*
    #swagger.tags = ['Auth']
    #swagger.summary = 'Register User'
    #swagger.description = 'Helper route to register users (Test only).'
    #swagger.parameters['body'] = {
        in: 'body',
        description: 'Desired user credentials',
        schema: { username: "newadmin", password: "password123" }
    }
  */
  const { username, password } = req.body
  if (!username || !password)
    return sendError(res, 400, 'BAD_REQUEST', 'Missing username or password')

  try {
    const hash = await bcrypt.hash(password, 10)
    const id = crypto.randomUUID()
    await pool.query('INSERT INTO users (id, username, password_hash) VALUES (?, ?, ?)', [
      id,
      username,
      hash,
    ])
    res.json({ message: 'User created successfully' })
  } catch (err) {
    return sendError(res, 500, 'INTERNAL_SERVER_ERROR', err.message)
  }
})

// GET /vehicles endpoint
app.get('/vehicles', authenticateToken, async (req, res) => {
  /*
    #swagger.tags = ['Vehicles']
    #swagger.summary = 'List All Vehicles'
    #swagger.description = 'Fetch all fleet vehicles including current status and assigned drivers.'
  */
  try {
    const query = `
            SELECT v.*, d.name AS driver_name 
            FROM vehicles v
            LEFT JOIN drivers d ON v.driver_id = d.id
            ORDER BY v.updated_at DESC
        `
    const [rows] = await pool.query(query)
    res.json(rows)
  } catch (err) {
    console.error(err)
    return sendError(res, 500, 'INTERNAL_SERVER_ERROR', 'Failed to fetch vehicles', {
      detail: err.message,
    })
  }
})

// PATCH /vehicles/:id endpoint (Req 2.2 & 2.5)
app.patch('/vehicles/:id', authenticateToken, async (req, res) => {
  /*
    #swagger.tags = ['Vehicles']
    #swagger.summary = 'Update Vehicle Status & Driver'
    #swagger.description = 'Update vehicle operational status and driver assignment.'
    #swagger.parameters['body'] = {
        in: 'body',
        description: 'Fields to update',
        schema: {
            status: "MAINTENANCE",
            driver_id: "drv_002"
        }
    }
  */
  const { id } = req.params
  const { status, driver_id } = req.body

  try {
    const [vehicle] = await pool.query('SELECT * FROM vehicles WHERE id = ?', [id])
    if (vehicle.length === 0) return sendError(res, 404, 'NOT_FOUND', 'Vehicle not found')

    const currentData = vehicle[0]

    // Requirement 2.5: Block manual status change if IN_PROGRESS
    if (status && status !== currentData.status) {
      if (currentData.status === 'IN_PROGRESS') {
        return sendError(
          res,
          409,
          'CONFLICT',
          'Cannot change status of a vehicle currently IN_PROGRESS',
        )
      }
    }

    // Requirement 2.2: Cannot assign driver with expired license
    if (driver_id && driver_id !== currentData.driver_id) {
      const [driver] = await pool.query('SELECT license_expires_at FROM drivers WHERE id = ?', [
        driver_id,
      ])
      if (driver.length === 0) return sendError(res, 404, 'NOT_FOUND', 'Driver not found')
      const expiresAt = new Date(driver[0].license_expires_at)
      if (expiresAt < new Date()) {
        return sendError(res, 400, 'BAD_REQUEST', 'Cannot assign a driver with an expired license')
      }
    }

    const newStatus = status || currentData.status
    const newDriverId = driver_id !== undefined ? driver_id : currentData.driver_id

    await pool.query(
      'UPDATE vehicles SET status = ?, driver_id = ?, updated_at = NOW() WHERE id = ?',
      [newStatus, newDriverId, id],
    )

    if (status && status !== currentData.status) {
      await logAudit(req, 'UPDATE_VEHICLE_STATUS', 'VEHICLE', id, 'SUCCESS', {
        old_status: currentData.status,
        new_status: status,
      })
    }
    if (driver_id && driver_id !== currentData.driver_id) {
      await logAudit(req, 'ASSIGN_DRIVER', 'VEHICLE', id, 'SUCCESS', {
        old_driver_id: currentData.driver_id,
        new_driver_id: driver_id,
      })
    }

    res.json({ message: 'Vehicle updated successfully' })
  } catch (err) {
    console.error(err)
    return sendError(res, 500, 'INTERNAL_SERVER_ERROR', 'Failed to update vehicle')
  }
})

// PATCH /vehicles/:id/details endpoint (ADMIN only)
app.patch('/vehicles/:id/details', authenticateToken, requireRole('ADMIN'), async (req, res) => {
  /*
    #swagger.tags = ['Vehicles']
    #swagger.summary = 'Update Vehicle Info (Admin)'
    #swagger.description = 'Update internal vehicle configuration (License, Type, etc).'
    #swagger.parameters['body'] = {
        in: 'body',
        description: 'New configuration payload',
        schema: {
            license_plate: "ญข 9999",
            type: "VAN",
            brand: "Toyota",
            model: "Commuter",
            year: 2023,
            fuel_type: "DIESEL",
            mileage_km: 18000,
            next_service_km: 25000
        }
    }
  */
  const { id } = req.params
  const { license_plate, type, brand, model, year, fuel_type, mileage_km, next_service_km } = req.body

  try {
    const [vehicle] = await pool.query('SELECT * FROM vehicles WHERE id = ?', [id])
    if (vehicle.length === 0) return sendError(res, 404, 'NOT_FOUND', 'Vehicle not found')

    // Field Validation
    const details = {}
    if (!license_plate) details.license_plate = 'license_plate is required'
    if (!type) details.type = 'type is required'

    const validTypes = ['TRUCK', 'VAN', 'MOTORCYCLE', 'PICKUP']
    if (type && !validTypes.includes(type)) {
      details.type = `type must be one of: ${validTypes.join(', ')}`
    }

    const validFuelTypes = ['DIESEL', 'GASOLINE', 'ELECTRIC', 'HYBRID']
    if (fuel_type && !validFuelTypes.includes(fuel_type)) {
      details.fuel_type = `fuel_type must be one of: ${validFuelTypes.join(', ')}`
    }

    if (year !== null && year !== undefined && year !== '' && isNaN(parseInt(year))) details.year = 'year must be a valid number'
    if (mileage_km !== null && mileage_km !== undefined && mileage_km !== '' && isNaN(parseInt(mileage_km))) details.mileage_km = 'mileage_km must be a valid number'
    if (next_service_km !== null && next_service_km !== undefined && next_service_km !== '' && isNaN(parseInt(next_service_km))) details.next_service_km = 'next_service_km must be a valid number'

    if (Object.keys(details).length > 0) {
      return sendError(res, 400, 'VALIDATION_ERROR', 'Invalid data', details)
    }

    const query = `
      UPDATE vehicles
      SET license_plate = ?, type = ?, brand = ?, model = ?, 
          year = ?, fuel_type = ?, mileage_km = ?, next_service_km = ?, updated_at = NOW()
      WHERE id = ?
    `
    const values = [
      license_plate, 
      type, 
      brand || null, 
      model || null, 
      year ? parseInt(year) : null, 
      fuel_type || null, 
      mileage_km !== '' ? parseInt(mileage_km) || 0 : 0, 
      next_service_km ? parseInt(next_service_km) : null, 
      id
    ]

    await pool.query(query, values)
    await logAudit(req, 'UPDATE_VEHICLE_DETAILS', 'VEHICLE', id, 'SUCCESS', { license_plate, type })

    res.json({ message: 'Vehicle details updated successfully' })
  } catch (error) {
    console.error(error)
    if (error.code === 'ER_DUP_ENTRY') {
      return sendError(res, 409, 'CONFLICT', 'License plate already exists', { license_plate })
    }
    return sendError(res, 500, 'INTERNAL_SERVER_ERROR', 'Failed to update vehicle details')
  }
})

// DELETE /vehicles/:id endpoint
app.delete('/vehicles/:id', authenticateToken, requireRole('ADMIN'), async (req, res) => {
  /*
    #swagger.tags = ['Vehicles']
    #swagger.summary = 'Delete Vehicle'
  */
  const { id } = req.params
  try {
    const [vehicle] = await pool.query('SELECT id FROM vehicles WHERE id = ?', [id])
    if (vehicle.length === 0) {
      return sendError(res, 404, 'NOT_FOUND', 'Vehicle not found')
    }

    // Requirement 2.2: Cannot delete vehicle with IN_PROGRESS trip
    const [activeTrips] = await pool.query(
      'SELECT id FROM trips WHERE vehicle_id = ? AND status = ?',
      [id, 'IN_PROGRESS'],
    )
    if (activeTrips.length > 0) {
      return sendError(
        res,
        409,
        'CONFLICT',
        'Cannot delete vehicle currently in progress on a trip',
      )
    }

    await pool.query('DELETE FROM vehicles WHERE id = ?', [id])

    await logAudit(req, 'DELETE_VEHICLE', 'VEHICLE', id, 'SUCCESS', { vehicle_id: id })

    res.status(204).send()
  } catch (err) {
    console.error(err)
    return sendError(res, 500, 'INTERNAL_SERVER_ERROR', 'Failed to delete vehicle', {
      detail: err.message,
    })
  }
})

// GET /vehicles/:id/history endpoint
app.get('/vehicles/:id/history', authenticateToken, async (req, res) => {
  /*
    #swagger.tags = ['Vehicles']
    #swagger.summary = 'Vehicle Use History'
    #swagger.description = 'Fetch prior trips and maintenance logs for this specific vehicle.'
  */
  try {
    const { id } = req.params

    const [vehicle] = await pool.query('SELECT id FROM vehicles WHERE id = ?', [id])
    if (vehicle.length === 0) {
      return sendError(res, 404, 'NOT_FOUND', 'Vehicle not found')
    }

    const query = `
            SELECT 
                'TRIP' AS record_type,
                id AS record_id,
                status,
                started_at AS event_date,
                origin AS detail_1,
                destination AS detail_2
            FROM trips 
            WHERE vehicle_id = ?
            
            UNION ALL
            
            SELECT 
                'MAINTENANCE' AS record_type,
                id AS record_id,
                status,
                scheduled_at AS event_date,
                type AS detail_1,
                NULL AS detail_2
            FROM maintenance
            WHERE vehicle_id = ?
            
            ORDER BY event_date DESC
        `

    const [history] = await pool.query(query, [id, id])

    res.json({ vehicle_id: id, history })
  } catch (err) {
    console.error(err)
    return sendError(res, 500, 'INTERNAL_SERVER_ERROR', 'Failed to fetch vehicle history', {
      detail: err.message,
    })
  }
})

// ==========================================
// MAINTENANCE ENDPOINTS
// ==========================================

app.get('/maintenance', authenticateToken, async (req, res) => {
  /*
    #swagger.tags = ['Maintenance']
    #swagger.summary = 'Get Maintenance Records'
    #swagger.description = 'Fetch all maintenance records combined with vehicle details.'
  */
  try {
    const query = `
      SELECT 
        m.*,
        v.license_plate,
        v.type as vehicle_type
      FROM maintenance m
      LEFT JOIN vehicles v ON m.vehicle_id = v.id
      ORDER BY m.scheduled_at ASC
    `
    const [rows] = await pool.query(query)
    res.json(rows)
  } catch (err) {
    console.error(err)
    return sendError(res, 500, 'INTERNAL_SERVER_ERROR', 'Failed to fetch maintenance data')
  }
})

// ==========================================
// TRIPS MANAGEMENT ENDPOINTS
// ==========================================

// GET /trips endpoint
app.get('/trips', authenticateToken, async (req, res) => {
  /*
    #swagger.tags = ['Trips']
    #swagger.summary = 'List All Trips'
    #swagger.description = 'Fetch a list of all historical and active trips.'
  */
  try {
    const query = `
      SELECT 
        t.*, 
        v.license_plate AS vehicle_license_plate, 
        d.name AS driver_name 
      FROM trips t
      LEFT JOIN vehicles v ON t.vehicle_id = v.id
      LEFT JOIN drivers d ON t.driver_id = d.id
      ORDER BY t.created_at DESC
    `
    const [rows] = await pool.query(query)
    res.json(rows)
  } catch (err) {
    console.error(err)
    return sendError(res, 500, 'INTERNAL_SERVER_ERROR', 'Failed to fetch trips data', {
      detail: err.message,
    })
  }
})

// GET /trips/:id endpoint (Fetch trip details + checkpoints)
app.get('/trips/:id', authenticateToken, async (req, res) => {
  /*
    #swagger.tags = ['Trips']
    #swagger.summary = 'Get Trip Details'
    #swagger.description = 'Fetch specific trip details along with its checkpoints.'
  */
  const { id } = req.params
  try {
    const tripQuery = `
      SELECT 
        t.*, 
        v.license_plate AS vehicle_license_plate, 
        d.name AS driver_name 
      FROM trips t
      LEFT JOIN vehicles v ON t.vehicle_id = v.id
      LEFT JOIN drivers d ON t.driver_id = d.id
      WHERE t.id = ?
    `
    const [tripRows] = await pool.query(tripQuery, [id])

    if (tripRows.length === 0) {
      return sendError(res, 404, 'NOT_FOUND', 'Trip not found')
    }

    const checkpointsQuery = `
      SELECT * 
      FROM checkpoints 
      WHERE trip_id = ? 
      ORDER BY sequence ASC
    `
    const [checkpointsRows] = await pool.query(checkpointsQuery, [id])

    const tripData = tripRows[0]
    tripData.checkpoints = checkpointsRows

    res.json(tripData)
  } catch (err) {
    console.error(err)
    return sendError(res, 500, 'INTERNAL_SERVER_ERROR', 'Failed to fetch trip details', {
      detail: err.message,
    })
  }
})

// POST /trips endpoint (Create new trip and checkpoints)
app.post('/trips', authenticateToken, requireRole('ADMIN', 'DISPATCHER'), async (req, res) => {
  /*
    #swagger.tags = ['Trips']
    #swagger.summary = 'Create New Trip'
    #swagger.description = 'Dispatch a new trip with a specified vehicle, driver, and checkpoints.'
    #swagger.parameters['body'] = {
        in: 'body',
        description: 'New trip payload',
        required: true,
        schema: {
            vehicle_id: "veh_001",
            driver_id: "drv_001",
            origin: "Bangkok",
            destination: "Chiang Mai",
            distance_km: 700,
            cargo_type: "GENERAL",
            cargo_weight_kg: 5000,
            checkpoints: [
                { location_name: "Ayutthaya", latitude: 14.35, longitude: 100.56, purpose: "Rest" },
                { location_name: "Nakhon Sawan", latitude: 15.69, longitude: 100.12, purpose: "Refuel" }
            ]
        }
    }
  */
  const connection = await pool.getConnection() // Use connection for Transaction

  try {
    await connection.beginTransaction() // Start Transaction

    const {
      id,
      vehicle_id,
      driver_id,
      origin,
      destination,
      distance_km,
      cargo_type,
      cargo_weight_kg,
      checkpoints = [],
    } = req.body

    // 1. Validation
    const details = {}
    if (!vehicle_id) details.vehicle_id = 'vehicle_id is required'
    if (!driver_id) details.driver_id = 'driver_id is required'
    if (!origin) details.origin = 'origin is required'
    if (!destination) details.destination = 'destination is required'

    const validCargoTypes = ['GENERAL', 'FRAGILE', 'HAZARDOUS', 'REFRIGERATED']
    if (cargo_type && !validCargoTypes.includes(cargo_type)) {
      details.cargo_type = `cargo_type must be one of: ${validCargoTypes.join(', ')}`
    }

    if (Object.keys(details).length > 0) {
      await connection.rollback()
      return sendError(res, 400, 'VALIDATION_ERROR', 'Invalid data format', details)
    }

    // 2. Check if Vehicle is available (Not in maintenance or retired)
    const [vehicle] = await connection.query('SELECT status FROM vehicles WHERE id = ?', [
      vehicle_id,
    ])
    if (vehicle.length === 0) throw new Error('Vehicle not found')
    if (['MAINTENANCE', 'RETIRED'].includes(vehicle[0].status)) {
      await connection.rollback()
      return sendError(
        res,
        409,
        'CONFLICT',
        'Vehicle is not available for a new trip (Maintenance/Retired)',
      )
    }

    // 3. Check if Driver is available (Active and License not expired)
    const [driver] = await connection.query(
      'SELECT status, license_expires_at FROM drivers WHERE id = ?',
      [driver_id],
    )
    if (driver.length === 0) throw new Error('Driver not found')
    if (driver[0].status !== 'ACTIVE') {
      await connection.rollback()
      return sendError(res, 409, 'CONFLICT', 'Driver is not active')
    }
    if (new Date(driver[0].license_expires_at) < new Date()) {
      await connection.rollback()
      return sendError(res, 409, 'CONFLICT', 'Driver license has expired')
    }

    // 4. Generate Trip ID if not provided
    let finalTripId = id
    if (!finalTripId) {
      const [rows] = await connection.query(`
        SELECT id FROM trips 
        WHERE id LIKE 'trp_%'
        ORDER BY CAST(SUBSTRING(id, 5) AS UNSIGNED) DESC 
        LIMIT 1
      `)
      if (rows.length > 0) {
        const lastNum = parseInt(rows[0].id.substring(4), 10)
        finalTripId = `trp_${(lastNum + 1).toString().padStart(3, '0')}`
      } else {
        finalTripId = 'trp_001'
      }
    }

    // 5. Insert Trip
    const insertTripQuery = `
      INSERT INTO trips (
        id, vehicle_id, driver_id, status, origin, destination, 
        distance_km, cargo_type, cargo_weight_kg
      ) VALUES (?, ?, ?, 'SCHEDULED', ?, ?, ?, ?, ?)
    `
    await connection.query(insertTripQuery, [
      finalTripId,
      vehicle_id,
      driver_id,
      origin,
      destination,
      distance_km || null,
      cargo_type || null,
      cargo_weight_kg || null,
    ])

    // 6. Insert Checkpoints (if any)
    if (checkpoints.length > 0) {
      // Generate chk_XXX IDs: หา ID ล่าสุดของ checkpoints ก่อน
      const [lastChkRow] = await connection.query(`
        SELECT id FROM checkpoints 
        WHERE id LIKE 'chk_%'
        ORDER BY CAST(SUBSTRING(id, 5) AS UNSIGNED) DESC 
        LIMIT 1
      `)
      let chkCounter = lastChkRow.length > 0 ? parseInt(lastChkRow[0].id.substring(4), 10) : 0

      const checkpointValues = checkpoints.map((cp, index) => {
        chkCounter++
        const chkId = `chk_${chkCounter.toString().padStart(3, '0')}`
        return [
          chkId,
          finalTripId,
          index + 1,
          'PENDING',
          cp.location_name,
          cp.latitude || null,
          cp.longitude || null,
          cp.purpose || null,
          cp.notes || null,
        ]
      })

      const insertCheckpointsQuery = `
        INSERT INTO checkpoints (
          id, trip_id, sequence, status, location_name, 
          latitude, longitude, purpose, notes
        ) VALUES ?
      `
      await connection.query(insertCheckpointsQuery, [checkpointValues])
    }

    await connection.commit() // Commit Transaction

    await logAudit(req, 'CREATE_TRIP', 'TRIP', finalTripId, 'SUCCESS', {
      origin,
      destination,
      vehicle_id,
      driver_id,
      checkpoints_count: checkpoints.length,
    })

    res.status(201).json({ message: 'Trip created successfully', trip_id: finalTripId })
  } catch (error) {
    await connection.rollback() // Rollback if any error occurs
    console.error('Create Trip Error:', error)
    return sendError(res, 500, 'INTERNAL_SERVER_ERROR', 'Failed to create trip', {
      detail: error.message,
    })
  } finally {
    connection.release() // Return connection back to pool
  }
})

// PATCH /trips/:id/status endpoint (Update Trip Status & Handle Side Effects)
app.patch(
  '/trips/:id/status',
  authenticateToken,
  requireRole('ADMIN', 'DISPATCHER'),
  async (req, res) => {
    /*
      #swagger.tags = ['Trips']
      #swagger.summary = 'Update Trip Status'
      #swagger.description = 'Change trip execution status (e.g. SCHEDULED -> IN_PROGRESS).'
      #swagger.parameters['body'] = {
          in: 'body',
          description: 'Trip status change',
          required: true,
          schema: { status: "IN_PROGRESS" }
      }
    */
    const { id } = req.params
    const { status } = req.body
    const validStatuses = ['SCHEDULED', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED']

    if (!status || !validStatuses.includes(status)) {
      return sendError(
        res,
        400,
        'VALIDATION_ERROR',
        `Status must be one of: ${validStatuses.join(', ')}`,
      )
    }

    let connection
    try {
      connection = await pool.getConnection()
      await connection.beginTransaction()

      // 1. Fetch current trip details
      const [tripRows] = await connection.query(
        'SELECT status, vehicle_id, distance_km FROM trips WHERE id = ? FOR UPDATE',
        [id],
      )
      if (tripRows.length === 0) {
        await connection.rollback()
        return sendError(res, 404, 'NOT_FOUND', 'Trip not found')
      }
      const currentTrip = tripRows[0]

      // Prevent invalid transitions (e.g., from COMPLETED to IN_PROGRESS)
      if (currentTrip.status === 'COMPLETED' || currentTrip.status === 'CANCELLED') {
        await connection.rollback()
        return sendError(
          res,
          409,
          'CONFLICT',
          `Cannot change status of a ${currentTrip.status} trip`,
        )
      }

      // 2. Prepare update query based on the new status
      let updateQuery = 'UPDATE trips SET status = ?'
      let queryParams = [status]

      if (status === 'IN_PROGRESS' && currentTrip.status === 'SCHEDULED') {
        updateQuery += ', started_at = NOW()'

        // Update vehicle status to indicate it's busy
        await connection.query('UPDATE vehicles SET status = ? WHERE id = ?', [
          'ACTIVE',
          currentTrip.vehicle_id,
        ])
      } else if (status === 'COMPLETED' && currentTrip.status === 'IN_PROGRESS') {
        updateQuery += ', ended_at = NOW()'

        // Update vehicle: Set to IDLE and add distance to mileage (in transaction)
        const distance = parseFloat(currentTrip.distance_km) || 0
        const [vehicleRows] = await connection.query(
          'SELECT mileage_km, next_service_km FROM vehicles WHERE id = ?',
          [currentTrip.vehicle_id],
        )

        if (vehicleRows.length > 0) {
          const currentMileage = parseInt(vehicleRows[0].mileage_km) || 0
          const nextService = parseInt(vehicleRows[0].next_service_km) || 0
          const newMileage = currentMileage + distance

          await connection.query(
            "UPDATE vehicles SET status = 'IDLE', mileage_km = ? WHERE id = ?",
            [newMileage, currentTrip.vehicle_id],
          )

          // Auto-create maintenance if mileage exceeds next_service_km (in transaction)
          if (nextService > 0 && newMileage >= nextService) {
            const [existingMaint] = await connection.query(
              `SELECT id FROM maintenance 
               WHERE vehicle_id = ? AND status IN ('SCHEDULED', 'IN_PROGRESS')`,
              [currentTrip.vehicle_id],
            )

            if (existingMaint.length === 0) {
              // Generate mnt_XXX ID
              const [lastMntRow] = await connection.query(`
                SELECT id FROM maintenance 
                WHERE id LIKE 'mnt_%'
                ORDER BY CAST(SUBSTRING(id, 5) AS UNSIGNED) DESC 
                LIMIT 1
              `)
              const lastMntNum = lastMntRow.length > 0 ? parseInt(lastMntRow[0].id.substring(4), 10) : 0
              const maintId = `mnt_${(lastMntNum + 1).toString().padStart(3, '0')}`
              await connection.query(
                `INSERT INTO maintenance (id, vehicle_id, status, type, scheduled_at) 
                 VALUES (?, ?, 'SCHEDULED', 'INSPECTION', NOW())`,
                [maintId, currentTrip.vehicle_id],
              )
            }
          }
        }
      } else if (status === 'CANCELLED') {
        updateQuery += ', ended_at = NOW()'

        // If it was in progress, release the vehicle and update mileage
        if (currentTrip.status === 'IN_PROGRESS') {
          const distance = parseFloat(currentTrip.distance_km) || 0

          // Update vehicle: Set to IDLE and add distance to mileage (in transaction)
          const [vehicleRows] = await connection.query(
            'SELECT mileage_km, next_service_km FROM vehicles WHERE id = ?',
            [currentTrip.vehicle_id],
          )

          if (vehicleRows.length > 0) {
            const currentMileage = parseInt(vehicleRows[0].mileage_km) || 0
            const nextService = parseInt(vehicleRows[0].next_service_km) || 0
            const newMileage = currentMileage + distance

            await connection.query(
              "UPDATE vehicles SET status = 'IDLE', mileage_km = ? WHERE id = ?",
              [newMileage, currentTrip.vehicle_id],
            )

            // Auto-create maintenance if mileage exceeds next_service_km (in transaction)
            if (nextService > 0 && newMileage >= nextService) {
              const [existingMaint] = await connection.query(
                `SELECT id FROM maintenance 
                 WHERE vehicle_id = ? AND status IN ('SCHEDULED', 'IN_PROGRESS')`,
                [currentTrip.vehicle_id],
              )

              if (existingMaint.length === 0) {
                // Generate mnt_XXX ID
                const [lastMntRow2] = await connection.query(`
                  SELECT id FROM maintenance 
                  WHERE id LIKE 'mnt_%'
                  ORDER BY CAST(SUBSTRING(id, 5) AS UNSIGNED) DESC 
                  LIMIT 1
                `)
                const lastMntNum2 = lastMntRow2.length > 0 ? parseInt(lastMntRow2[0].id.substring(4), 10) : 0
                const maintId2 = `mnt_${(lastMntNum2 + 1).toString().padStart(3, '0')}`
                await connection.query(
                  `INSERT INTO maintenance (id, vehicle_id, status, type, scheduled_at) 
                   VALUES (?, ?, 'SCHEDULED', 'INSPECTION', NOW())`,
                  [maintId2, currentTrip.vehicle_id],
                )
              }
            }
          }
        }
      }

      updateQuery += ', updated_at = NOW() WHERE id = ?'
      queryParams.push(id)

      // 3. Execute the update
      await connection.query(updateQuery, queryParams)

      await connection.commit()

      await logAudit(req, 'UPDATE_TRIP_STATUS', 'TRIP', id, 'SUCCESS', {
        old_status: currentTrip.status,
        new_status: status,
      })

      res.json({ message: `Trip status updated to ${status} successfully` })
    } catch (error) {
      await connection.rollback()
      console.error('Update Trip Status Error:', error)
      return sendError(res, 500, 'INTERNAL_SERVER_ERROR', 'Failed to update trip status', {
        detail: error.message,
      })
    } finally {
      if (connection) connection.release()
    }
  },
)

// DELETE /trips/:id endpoint (ADMIN only)
app.delete('/trips/:id', authenticateToken, requireRole('ADMIN'), async (req, res) => {
  /*
    #swagger.tags = ['Trips']
    #swagger.summary = 'Delete Trip'
    #swagger.description = 'Remove trip and its associated checkpoints.'
  */
  const { id } = req.params
  try {
    const [trip] = await pool.query('SELECT id, status FROM trips WHERE id = ?', [id])
    if (trip.length === 0) return sendError(res, 404, 'NOT_FOUND', 'Trip not found')

    // ไม่อนุญาตให้ลบทริปที่กำลังวิ่งอยู่
    if (trip[0].status === 'IN_PROGRESS') {
      return sendError(res, 409, 'CONFLICT', 'Cannot delete a trip that is currently IN_PROGRESS')
    }

    // ลบ checkpoints ที่เชื่อมกับทริปนี้ก่อน
    await pool.query('DELETE FROM checkpoints WHERE trip_id = ?', [id])
    // ลบทริป
    await pool.query('DELETE FROM trips WHERE id = ?', [id])

    await logAudit(req, 'DELETE_TRIP', 'TRIP', id, 'SUCCESS', { trip_id: id })

    res.status(204).send()
  } catch (err) {
    console.error(err)
    return sendError(res, 500, 'INTERNAL_SERVER_ERROR', 'Failed to delete trip')
  }
})

// PATCH /checkpoints/:id/status endpoint (Update Checkpoint Status)
app.patch('/checkpoints/:id/status', authenticateToken, async (req, res) => {
  /*
    #swagger.tags = ['Checkpoints']
    #swagger.summary = 'Update Checkpoint Status'
    #swagger.description = 'Update sequential status of a trip checkpoint (PENDING -> ARRIVED -> DEPARTED).'
    #swagger.parameters['body'] = {
        in: 'body',
        description: 'Checkpoint status updates',
        required: true,
        schema: {
            status: "ARRIVED",
            notes: "Driver took a 30m break."
        }
    }
  */
  const { id } = req.params
  const { status, notes } = req.body
  const validStatuses = ['PENDING', 'ARRIVED', 'DEPARTED', 'SKIPPED']

  if (!status || !validStatuses.includes(status)) {
    return sendError(
      res,
      400,
      'VALIDATION_ERROR',
      `Status must be one of: ${validStatuses.join(', ')}`,
    )
  }

  const connection = await pool.getConnection()

  try {
    await connection.beginTransaction()

    // 1. หาข้อมูลของ Checkpoint ตัวที่กำลังจะอัปเดต (เพื่อดู sequence และ trip_id)
    const [targetCpRows] = await connection.query(
      'SELECT trip_id, sequence, status as current_status FROM checkpoints WHERE id = ? FOR UPDATE',
      [id],
    )

    if (targetCpRows.length === 0) {
      await connection.rollback()
      return sendError(res, 404, 'NOT_FOUND', 'Checkpoint not found')
    }

    const targetCp = targetCpRows[0]
    const { trip_id, sequence, current_status } = targetCp

    // 2. กฎ: ARRIVED ต้องมาก่อน DEPARTED เสมอ
    if (status === 'DEPARTED' && current_status !== 'ARRIVED') {
      await connection.rollback()
      return sendError(
        res,
        400,
        'VALIDATION_ERROR',
        'Cannot depart from a checkpoint before arriving.',
      )
    }

    // 3. กฎ: ต้องทำตาม Sequence (ห้ามข้าม!)
    // หาจุดแวะ "ก่อนหน้า" ตัวมันทั้งหมด (sequence น้อยกว่า)
    const [incompletePrevCheckpoints] = await connection.query(
      `SELECT location_name, sequence 
       FROM checkpoints 
       WHERE trip_id = ? 
       AND sequence < ? 
       AND status NOT IN ('DEPARTED', 'SKIPPED')
       ORDER BY sequence ASC
       LIMIT 1`,
      [trip_id, sequence],
    )

    // ถ้าเจอจุดแวะก่อนหน้าที่ "ยังไม่เสร็จ" แม้แต่จุดเดียว
    if (incompletePrevCheckpoints.length > 0) {
      await connection.rollback()
      const blocker = incompletePrevCheckpoints[0]
      return sendError(
        res,
        400,
        'VALIDATION_ERROR',
        `Cannot update this checkpoint. Checkpoint #${blocker.sequence} ('${blocker.location_name}') is not yet completed.`,
      )
    }

    // 4. ถ้าผ่านทุกด่าน ก็ทำการอัปเดตได้เลย
    let updateQuery = 'UPDATE checkpoints SET status = ?'
    let queryParams = [status]

    if (status === 'ARRIVED') {
      updateQuery += ', arrived_at = NOW()'
    } else if (status === 'DEPARTED') {
      updateQuery += ', departed_at = NOW()'
    }

    if (notes !== undefined) {
      updateQuery += ', notes = ?'
      queryParams.push(notes)
    }

    updateQuery += ' WHERE id = ?'
    queryParams.push(id)

    await connection.query(updateQuery, queryParams)

    await connection.commit()

    await logAudit(req, 'UPDATE_CHECKPOINT_STATUS', 'CHECKPOINT', id, 'SUCCESS', {
      trip_id,
      sequence,
      old_status: current_status,
      new_status: status,
    })

    res.json({ message: `Checkpoint status updated to ${status} successfully` })
  } catch (error) {
    await connection.rollback()
    console.error('Update Checkpoint Status Error:', error)
    return sendError(res, 500, 'INTERNAL_SERVER_ERROR', 'Failed to update checkpoint status', {
      detail: error.message,
    })
  } finally {
    connection.release()
  }
})

const { AlertEngine } = require('./src/alertEngine/alertEngine.cjs')

let alertEngine

const ALERT_INTERVAL_MS = 60 * 1000

async function startAlertEngine() {
  alertEngine = new AlertEngine(pool)
  await alertEngine.syncToDatabase()

  setInterval(async () => {
    try {
      await alertEngine.syncToDatabase()
    } catch (err) {
      console.error('[AlertEngine] Periodic sync failed:', err.message)
    }
  }, ALERT_INTERVAL_MS)
}

app.get('/alerts', authenticateToken, async (req, res) => {
  /*
    #swagger.tags = ['System']
    #swagger.summary = 'Get Alerts'
    #swagger.description = 'Fetch system-generated alerts (WARNING/CRITICAL).'
  */
  try {
    const { severity, resource_type } = req.query

    let query = 'SELECT * FROM alerts WHERE 1=1'
    const params = []

    if (severity && ['WARNING', 'CRITICAL'].includes(severity.toUpperCase())) {
      query += ' AND severity = ?'
      params.push(severity.toUpperCase())
    }

    if (resource_type) {
      query += ' AND affected_resource_type = ?'
      params.push(resource_type.toUpperCase())
    }

    query += ' ORDER BY created_at DESC'

    const [rows] = await pool.query(query, params)
    res.json(rows)
  } catch (err) {
    console.error(err)
    return sendError(res, 500, 'INTERNAL_SERVER_ERROR', 'Failed to fetch alerts')
  }
})

// GET /audit-logs endpoint (Read-only, Append-only)
app.get('/audit-logs', authenticateToken, async (req, res) => {
  /*
    #swagger.tags = ['System']
    #swagger.summary = 'Get Audit Logs'
    #swagger.description = 'Fetch append-only security and operational audit logs.'
  */
  try {
    const { action, resource_type, start_date, end_date, limit = 100 } = req.query

    const userRole = req.user?.role
    const currentUserId = req.user?.id

    let query = 'SELECT * FROM audit_logs WHERE 1=1'
    const params = []

    // DISPATCHER can only see their own logs, ADMIN can see all
    if (userRole === 'DISPATCHER') {
      query += ' AND user_id = ?'
      params.push(currentUserId)
    } else if (req.query.user_id) {
      // ADMIN can filter by user_id, but DISPATCHER cannot
      query += ' AND user_id = ?'
      params.push(req.query.user_id)
    }

    if (action) {
      query += ' AND action = ?'
      params.push(action)
    }

    if (resource_type) {
      query += ' AND resource_type = ?'
      params.push(resource_type)
    }

    if (start_date) {
      query += ' AND created_at >= ?'
      params.push(start_date)
    }

    if (end_date) {
      query += ' AND created_at <= ?'
      params.push(end_date)
    }

    query += ' ORDER BY created_at DESC LIMIT ?'
    params.push(parseInt(limit) || 100)

    const [rows] = await pool.query(query, params)
    res.json(rows)
  } catch (err) {
    console.error(err)
    return sendError(res, 500, 'INTERNAL_SERVER_ERROR', 'Failed to fetch audit logs')
  }
})

const PORT = process.env.PORT || 3000
app.listen(PORT, async () => {
  console.log(`Server running on port ${PORT}`)
  try {
    await startAlertEngine()
  } catch (err) {
    console.error('Failed to start alert engine:', err.message)
  }
})
