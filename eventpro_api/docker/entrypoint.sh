#!/bin/sh
set -e

# Cache configuration, routes, and views if APP_KEY is present
if [ -n "$APP_KEY" ]; then
    php artisan config:cache || true
    php artisan route:cache || true
fi

# Run database migrations if configured
if [ "$RUN_MIGRATIONS" = "true" ]; then
    php artisan migrate --force || true
fi

exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
