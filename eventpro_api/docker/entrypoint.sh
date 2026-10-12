#!/bin/sh
set -e

# Cache configuration, routes, and views if APP_KEY is present
if [ -n "$APP_KEY" ]; then
    php artisan config:cache || true
    php artisan route:cache || true
fi

# Ensure SQLite database file exists and is writable
if [ "$DB_CONNECTION" = "sqlite" ] || [ -z "$DB_CONNECTION" ]; then
    touch /var/www/html/database/database.sqlite
    chown -R www-data:www-data /var/www/html/database
    chmod -R 775 /var/www/html/database
    chmod 664 /var/www/html/database/database.sqlite
fi

# Run database migrations if configured
if [ "$RUN_MIGRATIONS" = "true" ]; then
    php artisan migrate --force || true
fi

exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
