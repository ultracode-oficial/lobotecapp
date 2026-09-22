#!/bin/bash

chown -R www-data:www-data /var/www/html && \
grep -q "APP_KEY=base64" .env || php artisan key:generate && \
php artisan config:cache && \
php artisan route:cache && \
php artisan jwt:secret --no-interaction && \
php artisan jwt:generate-certs --no-interaction && \
php artisan migrate --force && \
php artisan db:seed --force && \
exec /usr/bin/supervisord -c /etc/supervisord.conf &\
while [ true ]
do
  php /var/www/html/artisan schedule:run --verbose --no-interaction &
  sleep 60
done