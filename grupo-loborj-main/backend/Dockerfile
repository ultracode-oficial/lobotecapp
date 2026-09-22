FROM php:8.5-apache

COPY ./php.ini /usr/local/etc/php/php.ini

RUN apt-get update && apt-get install -y \
    supervisor \
    libzip-dev \
    libpq-dev \
    zip \
    unzip \
    curl \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libpng-dev \
    libwebp-dev \
    && docker-php-ext-configure zip \
    && docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp \
    && docker-php-ext-install -j$(nproc) zip pdo pdo_mysql pcntl pdo_pgsql gd

WORKDIR /var/www/html

COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

COPY . .

RUN chown -R www-data:www-data /var/www/html/public

RUN composer install

COPY 000-default.conf /etc/apache2/sites-available/000-default.conf
COPY default-ssl.conf /etc/apache2/sites-available/default-ssl.conf
COPY supervisord.conf /etc/supervisord.conf

RUN php artisan config:cache && \
    php artisan route:cache && \
    chown -R www-data:www-data /var/www/html/storage && \
    chown -R www-data:www-data /var/www/html/bootstrap/cache && \
    chmod -R 775 /var/www/html/storage && \
    chmod -R 775 /var/www/html/bootstrap/cache && \
    a2enmod rewrite

EXPOSE 80

CMD ["/bin/bash", "/var/www/html/scripts.sh"]
