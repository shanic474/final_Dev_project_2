# ======================
# Stage 1: Build
# ======================
FROM node:20-alpine AS builder
WORKDIR /app

ARG APP_TYPE

COPY package*.json ./
RUN npm config set fetch-retry-mintimeout 20000 \
 && npm config set fetch-retry-maxtimeout 120000 \
 && npm config set network-timeout 600000 \
 && npm install

COPY . .

# Build only frontend
RUN if [ "$APP_TYPE" = "frontend" ]; then npm run build; fi


# ======================
# Stage 2: Frontend
# ======================
FROM nginx:alpine AS frontend
WORKDIR /usr/share/nginx/html
COPY --from=builder /app/dist .
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]


# ======================
# Stage 3: Backend
# ======================
FROM node:20-alpine AS backend
WORKDIR /app
COPY --from=builder /app .
EXPOSE 3000
CMD ["node", "app.js"]
