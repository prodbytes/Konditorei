#!/usr/bin/env bash
set -euo pipefail

# Start the kd-web SvelteKit app in dev mode.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$SCRIPT_DIR/../kd-web"

cd "$APP_DIR"
exec npm run dev
