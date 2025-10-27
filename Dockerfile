# === Stage 1: Build ===
FROM flutter:3.19 AS build-stage

WORKDIR /app

COPY pubspec.yaml pubspec.yaml
RUN flutter pub get

COPY . .

RUN flutter build web --release

# === Stage 2: Serve ===
FROM nginx:alpine AS serve-stage
WORKDIR /usr/share/nginx/html
COPY --from=build-stage /app/build/web .

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
