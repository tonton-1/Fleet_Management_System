const swaggerAutogen = require('swagger-autogen')()

const doc = {
  info: {
    title: 'Fleet Management API',
    description: 'API documentation for the Fleet Management system',
    version: '1.0.0',
  },
  host: 'localhost:3000',
  schemes: ['http'],
  securityDefinitions: {
    bearerAuth: {
      type: 'apiKey',
      in: 'header',
      name: 'Authorization',
      description: 'Enter your Bearer token in the format **Bearer &lt;token&gt;**',
    },
  },
}

const outputFile = './swagger-output.json'
const routes = ['./server.cjs'] // Path to the entry point where routes are defined

/* NOTE: If you are using the express Router, you must pass in the 'routes' only the 
root file where the route starts, such as index.js, app.js, routes.js, etc ... */

swaggerAutogen(outputFile, routes, doc).then(() => {
  console.log('Swagger documentation generated successfully!')
})
