#!/usr/bin/env bash
# Start kd-web in the Codespace and make its port public for the workshop.
set -uo pipefail

PORT=3000
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_DIR="$REPO_ROOT/kd-web"

# Ensure the production build exists (e.g. after a rebuild that skipped postCreate).
if [ ! -f "$APP_DIR/build/index.js" ]; then
  echo "==> Building kd-web ..."
  (cd "$APP_DIR" && npm install && npm run build)
fi

# Make the forwarded port public so workshop attendees can reach the app.
if command -v gh >/dev/null 2>&1 && [ -n "${CODESPACE_NAME:-}" ]; then
  echo "==> Making port ${PORT} public ..."
  gh codespace ports visibility "${PORT}:public" -c "$CODESPACE_NAME" \
    || echo "    (could not set visibility automatically — set port ${PORT} to 'Public' in the Ports panel)"
fi

# Start the production server if it isn't already running. Use setsid so the
# server survives after this lifecycle command (postStartCommand) exits —
# otherwise the devcontainer reaps the background process and the port closes.
if curl -sf -o /dev/null "http://localhost:${PORT}/" 2>/dev/null; then
  echo "==> kd-web already running on ${PORT}."
else
  echo "==> Starting kd-web on ${PORT} ..."
  ( cd "$APP_DIR" && HOST=0.0.0.0 PORT="${PORT}" setsid node build > /tmp/kd-web.log 2>&1 < /dev/null & )
  # Wait until it's accepting connections so the port is forwarded on return.
  for _ in $(seq 1 30); do
    curl -sf -o /dev/null "http://localhost:${PORT}/" 2>/dev/null && break
    sleep 1
  done
fi

# Print the public URL if we're in a Codespace.
if [ -n "${CODESPACE_NAME:-}" ]; then
  DOMAIN="${GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN:-app.github.dev}"
  echo "==> App URL: https://${CODESPACE_NAME}-${PORT}.${DOMAIN}"
fi
