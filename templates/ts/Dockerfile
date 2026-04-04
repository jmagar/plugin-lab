# Target path relative to plugin root: Dockerfile
# syntax=docker/dockerfile:1

FROM node:24-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY tsconfig.json ./
COPY my_plugin_mcp/ ./my_plugin_mcp/
RUN npm run build

FROM node:24-alpine AS runtime
WORKDIR /app
ENV NODE_ENV=production
COPY package*.json ./
RUN npm ci --omit=dev && npm cache clean --force
COPY --from=builder /app/dist ./dist
COPY entrypoint.sh ./entrypoint.sh
RUN addgroup -g 1000 app && adduser -D -u 1000 -G app app \
  && mkdir -p /data /app/logs && chown -R app:app /app
USER 1000:1000
EXPOSE 9000
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget -q --spider http://localhost:9000/health || exit 1
ENTRYPOINT ["./entrypoint.sh"]
