#!/bin/sh
# Reactive Resume boot for Railway. Runs as root so it can fix the volume, seeds the administrator in the background
# once the app reports healthy (the app applies its own migrations before it listens), then hands over to the stock
# entrypoint, which drops to the `node` user.
set -eu

fail() { echo "reactive-resume boot: $*" >&2; exit 1; }

: "${DATABASE_URL:?set DATABASE_URL}"
: "${AUTH_SECRET:?set AUTH_SECRET}"
: "${ADMIN_PASSWORD:?set ADMIN_PASSWORD}"
: "${API_KEY:?set API_KEY}"
: "${RAILWAY_PUBLIC_DOMAIN:?RAILWAY_PUBLIC_DOMAIN is empty: the service needs a public domain}"
[ "${#AUTH_SECRET}" -ge 32 ] || fail "AUTH_SECRET must be at least 32 characters"
[ "${#ADMIN_PASSWORD}" -ge 8 ] && [ "${#ADMIN_PASSWORD}" -le 64 ] || fail "ADMIN_PASSWORD must be 8 to 64 characters"
[ "${#API_KEY}" -ge 32 ] || fail "API_KEY must be at least 32 characters"

export APP_URL="https://$RAILWAY_PUBLIC_DOMAIN"
export LOCAL_STORAGE_PATH="${LOCAL_STORAGE_PATH:-/app/data}"
export PORT="${PORT:-3000}"

# Railway mounts the volume root-owned; the app always runs as node.
chown node:node "$LOCAL_STORAGE_PATH"

export PG_MODULE="$(ls -d /app/node_modules/.pnpm/pg@*/node_modules/pg | head -1)"
export BCRYPT_MODULE="$(ls -d /app/node_modules/.pnpm/bcryptjs@*/node_modules/bcryptjs | head -1)"
[ -n "$PG_MODULE" ] && [ -n "$BCRYPT_MODULE" ] || fail "pg or bcryptjs not found in the image"

( node /app/railway-seed.cjs || echo "reactive-resume boot: SEED FAILED" >&2 ) &

exec docker-entrypoint.sh "$@"
