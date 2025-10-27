# Stage 1: Build Flutter web app
FROM dart:stable AS build
WORKDIR /app
COPY pubspec.* ./
RUN dart pub get
COPY . .
RUN dart pub global activate flutter_tools && \
    flutter pub get && \
    flutter build web --release --no-tree-shake-icons

# Stage 2: Serve with Nginx (only static files)
FROM nginx:alpine
COPY --from=build /app/build/web /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]