#!/bin/bash
set -e

cd /var/www/html

if [ ! -f .env ]; then
    cp .env.example .env
fi

if grep -q "APP_KEY=base64:" .env; then
    :
else
    php artisan key:generate --force
fi

composer install --no-dev -o --no-interaction || true
composer update cachethq/core --no-interaction --no-dev || true

php artisan vendor:publish --tag=cachet --force || true

until php artisan migrate --force; do
    echo "Waiting for database..."
    sleep 2
done

if [ -n "$CACHET_ADMIN_EMAIL" ] && [ -n "$CACHET_ADMIN_PASSWORD" ]; then
    php artisan cachet:make:user \
        --email="$CACHET_ADMIN_EMAIL" \
        --password="$CACHET_ADMIN_PASSWORD" \
        --username="$CACHET_ADMIN_USER" \
        --admin=true || true
fi

exec "$@"
