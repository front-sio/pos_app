# Stage 1: Build Flutter Web App
FROM ghcr.io/cirruslabs/flutter:stable AS build

WORKDIR /app

# Copy dependencies
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

# Copy the rest
COPY . .

# Build optimized web bundle
RUN flutter build web --release --no-tree-shake-icons

# Stage 2: Serve using Nginx
FROM nginx:alpine

# Remove default nginx page
RUN rm -rf /usr/share/nginx/html/*

# Copy built Flutter web output
COPY --from=build /app/build/web /usr/share/nginx/html

# Copy custom nginx config
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
