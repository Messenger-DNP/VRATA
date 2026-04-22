FROM ghcr.io/cirruslabs/flutter:stable AS build

WORKDIR /app

COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

COPY . .

ARG VRATA_API_BASE_URL=http://localhost:8080
RUN flutter build web --dart-define=VRATA_API_BASE_URL=$VRATA_API_BASE_URL

FROM nginx:alpine
COPY --from=build /app/build/web /usr/share/nginx/html

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]