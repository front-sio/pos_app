# Stage 1: Build Flutter Web App
FROM ghcr.io/cirruslabs/flutter:stable AS build

WORKDIR /app

# Copy pubspec files first for better caching
COPY pubspec.yaml pubspec.lock ./

# Get dependencies (cached if pubspec hasn't changed)
RUN flutter pub get

# Copy source code
COPY lib ./lib
COPY web ./web
COPY assets ./assets

# Build for web with optimizations
RUN flutter build web \
    --release \
    --no-tree-shake-icons

# Stage 2: Serve with Nginx
FROM nginx:alpine

# Copy built web app
COPY --from=build /app/build/web /usr/share/nginx/html

# Copy nginx configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Expose port
EXPOSE 80

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --quiet --tries=1 --spider http://localhost/health || exit 1

# Start nginx
CMD ["nginx", "-g", "daemon off;"]