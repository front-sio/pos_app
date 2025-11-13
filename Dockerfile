# Base image: Ubuntu (small)
FROM ubuntu:22.04

# Install dependencies
RUN apt-get update && apt-get install -y \
  curl \
  git \
  unzip \
  xz-utils \
  zip \
  libglu1-mesa \
  && rm -rf /var/lib/apt/lists/*

# Install latest Flutter stable
RUN git clone https://github.com/flutter/flutter.git /usr/local/flutter -b stable

ENV PATH="/usr/local/flutter/bin:/usr/local/flutter/bin/cache/dart-sdk/bin:${PATH}"

# Run flutter doctor to pre-cache dependencies
RUN flutter doctor

WORKDIR /app
COPY . .

# Get packages and build for web (this will use Dart 3.9 if flutter stable is >=3.19)
RUN flutter pub get && flutter build web --release

# Serve with Nginx
FROM nginx:alpine

# Copy custom nginx config for Flutter web SPA routing
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy built Flutter web app
COPY --from=0 /app/build/web /usr/share/nginx/html

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]