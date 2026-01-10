# Stage 1: Builder (for both frontend and backend)
FROM node:20-alpine AS builder
WORKDIR /app

ARG APP_TYPE
COPY package*.json ./
RUN npm install
COPY . ./

# Only build frontend apps (client/dashboard)
RUN if [ "$APP_TYPE" = "frontend" ]; then npm run build; fi

# Install 'serve' globally for frontend apps
RUN if [ "$APP_TYPE" = "frontend" ]; then npm install -g serve; fi

# ===============================
# Stage 2: Production Images
# ===============================

# Frontend image (client/dashboard)
FROM nginx:alpine AS frontend
WORKDIR /usr/share/nginx/html
COPY --from=builder /app/dist ./
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]

# Backend image (server)
FROM node:20-alpine AS backend
WORKDIR /app
COPY --from=builder /app ./
EXPOSE 3000
CMD ["node", "app.js"]
