# Shared by the setup helpers, which source it rather than run it.

NIX_DAEMON_SH="/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh"

# A shell that has not logged in since nix was installed has no nix on PATH,
# and sourcing alone is a no-op in a session that sets its own PATH.
nix_on_path() {
  if ! command -v nix &>/dev/null; then
    . "$NIX_DAEMON_SH"
    export PATH="/nix/var/nix/profiles/default/bin:$PATH"
  fi
}

# apt takes seconds even when there is nothing to do, so ask dpkg first.
apt_install() {
  local pkg missing=()
  for pkg in "$@"; do
    dpkg -s "$pkg" &>/dev/null || missing+=("$pkg")
  done

  if [ ${#missing[@]} -gt 0 ]; then
    echo "Installing ${missing[*]}..."
    sudo apt install -y "${missing[@]}"
  fi
}

# Writes a system file only when its contents differ, then runs the rest of the
# arguments. Restarting a service or reloading the kernel on every apply would
# cost a dropped connection for nothing, so only a real change triggers them.
install_system_file() {
  local mode=$1 path=$2 content=$3
  shift 3

  if [ "$(sudo cat "$path" 2>/dev/null)" = "$content" ]; then
    return
  fi

  echo "Writing $path..."
  printf '%s\n' "$content" | sudo install -D -m "$mode" /dev/stdin "$path"
  "$@"
}

# Every helper is two jobs in one file: install what is missing, and keep the
# machine in sync. The phase picks which, and nothing else is a phase.
run_phase() {
  case "${1:-}" in
    bootstrap | apply) "$1" ;;
    *) echo "usage: $(basename "$0") bootstrap|apply" >&2; exit 1 ;;
  esac
}
