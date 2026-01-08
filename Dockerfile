# Stage 1: build (for both frontend/backend)
FROM node:20-alpine AS builder
WORKDIR /app

ARG APP_TYPE
COPY package*.json ./
RUN npm install

COPY . ./

# Only build if frontend
RUN if [ "$APP_TYPE" = "frontend" ]; then npm run build; fi

# Stage 2: production
FROM nginx:alpine AS frontend
WORKDIR /usr/share/nginx/html
COPY --from=builder /app/dist ./
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]

FROM node:20-alpine AS backend
WORKDIR /app
COPY --from=builder /app ./
EXPOSE 3000
CMD ["node", "server.js"]
