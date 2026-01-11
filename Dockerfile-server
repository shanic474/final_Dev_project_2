FROM node:20-alpine

WORKDIR /app

COPY package*.json ./
RUN npm config set fetch-retry-mintimeout 20000 \
 && npm config set fetch-retry-maxtimeout 120000 \
 && npm config set network-timeout 600000 \
 && npm install

COPY . .

EXPOSE 3000
CMD ["node", "app.js"]
