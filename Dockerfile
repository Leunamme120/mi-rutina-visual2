FROM ghcr.io/cirruslabs/flutter:3.24.1 AS build

WORKDIR /app

COPY . .

RUN flutter pub get
RUN flutter build web --release

FROM nginx:alpine
COPY --from=build /app/build/web /usr/share/nginx/html
