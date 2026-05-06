# ==========================================
# Tahap 1: Build aplikasi Flutter Web
# ==========================================
FROM ubuntu:22.04 AS build-env

# Instal dependensi sistem yang dibutuhkan Flutter
RUN apt-get update && apt-get install -y curl git unzip xz-utils zip libglu1-mesa

# Kloning Flutter SDK (versi stable)
RUN git clone https://github.com/flutter/flutter.git -b stable /usr/local/flutter

# Tambahkan Flutter ke PATH
ENV PATH="/usr/local/flutter/bin:/usr/local/flutter/bin/cache/dart-sdk/bin:${PATH}"

# Set working directory
WORKDIR /app

# Salin seluruh kode frontend ke dalam container
COPY . .

# Ambil dependensi pubspec dan build web
RUN flutter pub get
RUN flutter build web --release

# ==========================================
# Tahap 2: Sajikan dengan Nginx
# ==========================================
FROM nginx:alpine

# Salin hasil build dari Tahap 1 ke folder Nginx
COPY --from=build-env /app/build/web /usr/share/nginx/html

# Buat konfigurasi Nginx kustom agar berjalan di port 8080 (standar Cloud Run)
# Konfigurasi try_files sangat penting agar routing di Flutter Web tidak error 404 saat di-refresh
RUN echo "server { \
    listen 8080; \
    location / { \
        root /usr/share/nginx/html; \
        index index.html index.htm; \
        try_files \$uri \$uri/ /index.html; \
    } \
}" > /etc/nginx/conf.d/default.conf

# Ekspos port 8080
EXPOSE 8080

# Jalankan Nginx
CMD ["nginx", "-g", "daemon off;"]