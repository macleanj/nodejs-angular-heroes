FROM node:11-alpine AS builder
COPY . ./app
WORKDIR /app
RUN npm install
RUN npm run build:prod:en

FROM bitnami/nginx:1.16.1
LABEL description="Angular heroes build for production"
LABEL maintainer="CrossLogic Consulting - Jerome Mac Lean"
COPY --from=builder /app/dist/browser/ /app
EXPOSE 8080
