# Claude Code Base Action Dockerfile
# Bun-based TypeScript execution environment

# Stage 1: Base Bun environment
FROM --platform=linux/arm64 oven/bun:1 AS base
WORKDIR /app

# Stage 2: Dependencies
FROM base AS deps
COPY package.json bun.lock* ./
RUN bun install --frozen-lockfile --production

# Stage 3: Development dependencies
FROM base AS dev-deps
COPY package.json bun.lock* ./
RUN bun install --frozen-lockfile

# Stage 4: Development environment
FROM base AS development
COPY package.json bun.lock* ./
RUN bun install --frozen-lockfile
COPY . .

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=20s --retries=3 \
  CMD bun --version || exit 1

CMD ["bun", "run", "test"]

# Stage 5: Builder
FROM dev-deps AS builder
COPY . .
RUN bun run typecheck
RUN bun run format:check

# Stage 6: Production
FROM base AS production
COPY --from=deps /app/node_modules ./node_modules
COPY . .

# Create non-root user
RUN adduser --disabled-password --gecos '' action
USER action

CMD ["bun", "run", "src/index.ts"]