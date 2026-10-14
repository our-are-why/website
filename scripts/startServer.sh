#!/bin/sh

# Usage: startServer.sh
#   Serves public/ with static-web-server, using the settings in sws.toml.
#   It listens on the container's port 8000, which startContainer.sh maps
#   to http://localhost:3000 on the host. Stop it with Ctrl+C.

set -eu

# Run from the project root, wherever this script is called from, because
# sws.toml gives the site's folder as a relative path
cd "$(dirname "$0")/.."

echo "Serving public/ at http://localhost:3000 (Ctrl+C to stop)"
exec static-web-server --config-file sws.toml
