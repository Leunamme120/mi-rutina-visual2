# ------------------------------
# Etapa 1: Build con Flutter
# ------------------------------
FROM ghcr.io/cirruslabs/flutter:3.38.1 AS build

WORKDIR /app

# Copiar el proyecto Flutter
COPY . .

# Obtener dependencias
RUN flutter pub get

# Compilar APK en modo release
RUN flutter build apk --release


# ------------------------------
# Etapa 2: Imagen final
# ------------------------------
FROM alpine:latest

WORKDIR /output

# Copia solo el APK generado
COPY --from=build /app/build/app/outputs/flutter-apk/app-release.apk .

# Comando por defecto
CMD ["ls", "-l", "/output"]
