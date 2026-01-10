# Stage 1: build (for both frontend/backend)
FROM node:20-alpine AS builder
WORKDIR /app

ARG APP_TYPE

# Copy package.json and package-lock.json first to use Docker cache
COPY package*.json ./

# Set npm timeout and retries to avoid network issues
RUN npm config set fetch-retry-mintimeout 20000 \
 && npm config set fetch-retry-maxtimeout 120000 \
 && npm config set network-timeout 600000 \
 && npm config set registry https://registry.npmmirror.com/ \
 && npm install

# Copy the rest of the app
COPY . ./

# Only build frontend apps
RUN if [ "$APP_TYPE" = "frontend" ]; then npm run build; fi

# Install serve globally for frontend static serving
RUN if [ "$APP_TYPE" = "frontend" ]; then npm install -g serve; fi

# Stage 2: production for frontend
FROM nginx:alpine AS frontend
WORKDIR /usr/share/nginx/html
COPY --from=builder /app/dist ./
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]

# Stage 2: production for backend
FROM node:20-alpine AS backend
WORKDIR /app
COPY --from=builder /app ./
EXPOSE 3000
CMD ["node", "server.js"]
