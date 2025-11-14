# Stage 1: Build Flutter web
FROM ghcr.io/cirruslabs/flutter:stable AS build

# Give ubuntu user permission to write to Flutter SDK directories
RUN chown -R ubuntu:ubuntu /sdks/flutter

# Switch to non-root user
USER ubuntu

# Configure git to trust Flutter SDK directory
RUN git config --global --add safe.directory /sdks/flutter

WORKDIR /app

# Copy pubspec and get dependencies first (for caching)
COPY --chown=ubuntu:ubuntu pubspec.yaml pubspec.lock ./
RUN flutter pub get

# Copy the rest of the code
COPY --chown=ubuntu:ubuntu . .

# Build Flutter web
RUN flutter build web --release --no-tree-shake-icons

# Stage 2: Serve with Nginx
FROM nginx:alpine

# Clean default html
RUN rm -rf /usr/share/nginx/html/*

# Copy built web files from previous stage
COPY --from=build /app/build/web /usr/share/nginx/html

# Copy Nginx config
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]

