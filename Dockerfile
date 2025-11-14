# Etapa 1: Build
FROM cirrusci/flutter:stable AS build

# Directorio de trabajo
WORKDIR /app

# Copiar los archivos del proyecto al contenedor
COPY . .

# Obtener dependencias de Flutter
RUN flutter pub get

# Construir versión web
RUN flutter build web --release

# Etapa 2: Producción con Nginx
FROM nginx:alpine

# Copiar la web compilada al directorio de Nginx
COPY --from=build /app/build/web /usr/share/nginx/html

# Exponer el puerto 80
EXPOSE 80

# Iniciar Nginx en primer plano
CMD ["nginx", "-g", "daemon off;"]
