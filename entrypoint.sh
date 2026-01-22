#!/bin/bash
set -e

# --- STEP 3: Pre-stop delay + graceful shutdown ---
graceful_shutdown() {
  echo "SIGTERM received. Allowing ALB to drain connections..."
  sleep 10
}

trap graceful_shutdown SIGTERM SIGINT

# --- App startup ---
#python manage.py migrate --noinput

exec gunicorn diary_project.wsgi:application \
  --bind 0.0.0.0:8000 \
  --graceful-timeout 30 \
  --timeout 30
