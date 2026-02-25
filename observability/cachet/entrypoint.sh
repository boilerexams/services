#!/bin/bash
set -e

echo "Waiting for database to be ready..."
until PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USERNAME" -d postgres -c '\q'; do
    echo "Database is unavailable - sleeping"
    sleep 2
done
echo "Database is up!"

echo "Creating database if not exists..."
PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USERNAME" -d postgres -c "SELECT 1 FROM pg_database WHERE datname = '$DB_DATABASE'" | grep -q 1 || PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USERNAME" -d postgres -c "CREATE DATABASE $DB_DATABASE" || true

cd /var/www/html

if [ ! -f .env ]; then
    echo "Creating .env file..."
    cp .env.example .env
fi

if ! grep -q "APP_KEY=" .env || [ -z "$(grep APP_KEY= .env | cut -d'=' -f2)" ]; then
    echo "Generating application key..."
    php artisan key:generate --force
fi

echo "Publishing Cachet assets..."
php artisan vendor:publish --tag=cachet --force

echo "Running migrations..."
php artisan migrate --force

if [ -n "$CACHET_ADMIN_USER" ] && [ -n "$CACHET_ADMIN_EMAIL" ] && [ -n "$CACHET_ADMIN_PASSWORD" ]; then
    echo "Creating admin user..."
    php artisan cachet:make:user "$CACHET_ADMIN_EMAIL" --name="$CACHET_ADMIN_USER" --password="$CACHET_ADMIN_PASSWORD" --admin || true
fi

echo "Starting supervisord..."
exec supervisord -c /etc/supervisor/conf.d/supervisord.conf
