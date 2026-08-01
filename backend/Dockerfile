FROM node:22-alpine AS deps
WORKDIR /app
COPY package*.json ./
# `npm install` (not `npm ci`) so the build works from a fresh clone that
# hasn't committed package-lock.json yet.
RUN npm install --omit=dev

FROM node:22-alpine AS runner
WORKDIR /app
ENV NODE_ENV=production
COPY --from=deps /app/node_modules ./node_modules
COPY . .
EXPOSE 4000
CMD ["node", "src/server.js"]
