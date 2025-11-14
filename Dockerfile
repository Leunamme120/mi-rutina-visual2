# Etapa 1: Build de Flutter Web con Dart 3.4+
FROM ghcr.io/cirruslabs/flutter:3.24.1 AS build
WORKDIR /app

# Copiar el proyecto
COPY . .

# Descargar dependencias
RUN flutter pub get

# Compilar Flutter Web
RUN flutter build web --release

# Etapa 2: Servir con Nginx
FROM nginx:alpine
COPY --from=build /app/build/web /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]

EXPOSE 80

# Iniciar Nginx en primer plano
CMD ["nginx", "-g", "daemon off;"]

