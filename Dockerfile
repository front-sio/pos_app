FROM flutter:3.19 AS build-stage

WORKDIR /app

COPY pubspec.yaml pubspec.yaml
RUN flutter pub get

COPY . .

RUN flutter build web --release

FROM nginx:alpine
COPY --from=build-stage /app/build/web /usr/share/nginx/html

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
