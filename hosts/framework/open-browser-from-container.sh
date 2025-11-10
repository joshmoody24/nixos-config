#!/usr/bin/env bash
# Wrapper to open URLs from distrobox container on the host system

URL="$1"

# Check if we're in a container (has /run/host mount)
if [ -d /run/host ]; then
    # In container - invoke host's xdg-open with proper environment
    # Set PATH so xdg-open can find browsers on the host
    exec /run/host/run/current-system/sw/bin/bash -c "export DISPLAY=:0 && export PATH=/run/host/run/current-system/sw/bin:\$PATH && /run/host/run/current-system/sw/bin/xdg-open '$URL'"
else
    # On host - use normal xdg-open
    exec /run/current-system/sw/bin/xdg-open "$URL"
fi
