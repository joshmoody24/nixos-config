# Shared by the setup helpers, which source it rather than run it.

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
