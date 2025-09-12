FROM php:8.4-fpm-alpine

# Устанавливаем нужные пакеты
RUN apk add --no-cache \
    curl \
    libpng-dev \
    libxml2-dev \
    zip \
    unzip \
    git \
    oniguruma-dev \
    libzip-dev

# Устанавливаем расширения PHP
RUN docker-php-ext-install \
    pdo \
    pdo_mysql \
    mysqli \
    mbstring \
    xml \
    gd \
    bcmath \
    zip

# Устанавливаем Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Устанавливаем рабочую директорию
WORKDIR /var/www/html

# Экспонируем порт
EXPOSE 9000

# Запускаем PHP-FPM
CMD ["php-fpm"]
