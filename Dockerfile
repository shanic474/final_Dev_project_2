# Stage 1: builder
FROM node:20-alpine AS builder
WORKDIR /app

ARG APP_TYPE
COPY package*.json ./
RUN npm install
COPY . ./

# Only build frontend
RUN if [ "$APP_TYPE" = "frontend" ]; then npm run build; fi

# Install serve for frontend
RUN if [ "$APP_TYPE" = "frontend" ]; then npm install -g serve; fi

# Stage 2: production
# Frontend
FROM nginx:alpine AS frontend
WORKDIR /usr/share/nginx/html
COPY --from=builder /app/dist ./
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]

# Backend
FROM node:20-alpine AS backend
WORKDIR /app
COPY --from=builder /app ./
EXPOSE 3000
CMD ["node", "app.js"]
