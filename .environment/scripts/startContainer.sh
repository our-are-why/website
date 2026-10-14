#!/bin/sh

# Usage: startContainer.sh [code-server-host-port] [image-name]
#   code-server-host-port  defaults to 8081, leaving 8080 to the main project
#   image-name             defaults to the project directory's name,
#                          lowercased
#
# The caller guarantees:
#   - the project is inside the folder that holds .apple-container
#   - that folder has .coder-local and .coder-config, which become the
#     container's ~/.local and ~/.config

set -eu

# Run from the project root, wherever this script is called from
cd "$(dirname "$0")/../.."

code_server_port=${1:-8081}
image_name=${2:-$(basename "$PWD" | tr '[:upper:]' '[:lower:]')}

# The folder that holds .apple-container, found by walking up from here
root=$PWD
until [ -d "$root/.apple-container" ] || [ "$root" = / ]; do
  root=$(dirname "$root")
done

# Claude Code and code-server together outgrow `container`'s default of 1 GB.
# CPUs and memory are limits; the VM uses them as it needs them.
# Host port 3000 -> 8000, static-web-server's preview of ./public.
container run -it --rm \
  --cpus 4 \
  --memory 6G \
  -p "127.0.0.1:$code_server_port:8080" \
  -p 127.0.0.1:3000:8000 \
  -v "$root/.coder-local:/home/coder/.local" \
  -v "$root/.coder-config:/home/coder/.config" \
  -v "$PWD:/home/coder/project" \
  "$image_name"
