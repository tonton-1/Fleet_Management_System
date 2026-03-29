FROM node:18-alpine

# Set working directory
WORKDIR /app

# Install dependencies first for Docker caching
COPY package*.json ./
RUN npm install

# Copy application code
COPY . .

# Expose backend port
EXPOSE 3000

# Generate Swagger Docs and Start server
CMD ["sh", "-c", "node swagger.cjs && node server.cjs"]
