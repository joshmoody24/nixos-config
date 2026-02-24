#!/bin/bash
# Ubuntu system setup script (idempotent)
# Applies system-level config that home-manager can't handle on non-NixOS
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/../.." && pwd)"

# --- keyd ---
if ! command -v keyd &>/dev/null && ! command -v keyd.rvaiya &>/dev/null; then
  echo "Installing keyd..."
  sudo add-apt-repository -y ppa:keyd-team/ppa
  sudo apt update
  sudo apt install -y keyd
fi

sudo mkdir -p /etc/keyd
sudo cp "$REPO_DIR/shared/dotfiles/keyd/default.conf" /etc/keyd/default.conf
sudo systemctl enable --now keyd
sudo systemctl restart keyd
echo "keyd config applied."

# --- /etc/hosts (redo local development) ---
HOSTS_FILE="$REPO_DIR/shared/dotfiles/redo/hosts/redo-hosts"
MARKER_START="# BEGIN redo-hosts"
MARKER_END="# END redo-hosts"

if grep -q "$MARKER_START" /etc/hosts; then
  # Replace existing block
  sudo sed -i "/$MARKER_START/,/$MARKER_END/d" /etc/hosts
fi

echo "Updating /etc/hosts with redo entries..."
printf '%s\n%s\n%s\n' "$MARKER_START" "$(cat "$HOSTS_FILE")" "$MARKER_END" | sudo tee -a /etc/hosts >/dev/null
echo "redo hosts applied."


# --- Allow non-root processes to bind to ports 80+ (needed for caddy HTTPS) ---
SYSCTL_CONF="/etc/sysctl.d/99-unprivileged-ports.conf"
SYSCTL_LINE="net.ipv4.ip_unprivileged_port_start=80"
if ! grep -q "$SYSCTL_LINE" "$SYSCTL_CONF" 2>/dev/null; then
  echo "$SYSCTL_LINE" | sudo tee "$SYSCTL_CONF" >/dev/null
  sudo sysctl -p "$SYSCTL_CONF"
  echo "unprivileged port binding enabled (ports 80+)."
fi

# --- Allow unprivileged user namespaces (needed for Nix-installed Chrome/Electron sandboxing) ---
USERNS_CONF="/etc/sysctl.d/99-userns.conf"
USERNS_LINE="kernel.apparmor_restrict_unprivileged_userns=0"
if ! grep -q "$USERNS_LINE" "$USERNS_CONF" 2>/dev/null; then
  echo "$USERNS_LINE" | sudo tee "$USERNS_CONF" >/dev/null
  sudo sysctl -p "$USERNS_CONF"
  echo "unprivileged user namespaces enabled (Chrome/Electron sandbox)."
fi
