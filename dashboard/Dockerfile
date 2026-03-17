FROM node:22-alpine

WORKDIR /app

COPY package.json package-lock.json* ./
RUN npm ci

COPY . .
RUN npm run build

# Serve static export with lightweight server
RUN npm install -g serve

EXPOSE 3000

CMD ["serve", "out", "-l", "3000", "--single"]
