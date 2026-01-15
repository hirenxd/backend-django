#!/bin/bash
set -e

python manage.py migrate --noinput

exec gunicorn diary_project.wsgi:application \
  --bind 0.0.0.0:8000