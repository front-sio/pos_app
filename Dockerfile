# Build stage
FROM cirrusci/flutter:stable AS build-stage
WORKDIR /app
COPY . .
RUN flutter pub get && flutter build web --release

# Serve stage
FROM nginx:alpine
COPY --from=build-stage /app/build/web /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]