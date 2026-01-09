#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

echo "Applying database migrations..."
python manage.py migrate --noinput
python manage.py collectstatic --noinput
echo "Starting Gunicorn (WSGI)..."
# Using WSGI avoids the 'missing 1 required positional argument' error
exec gunicorn diary_project.wsgi:application \
    --workers 3 \
    --bind 0.0.0.0:8000

