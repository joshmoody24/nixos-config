#!/usr/bin/env bash
# Installs or updates Ship of Harkinian on Linux, pinned to the same release as
# Josh's NixOS config. Run it with:
#   curl -fsSL https://raw.githubusercontent.com/joshmoody24/nixos-config/main/scripts/soh/install.sh | bash

# Everything lives in main so a half-downloaded script never runs.
main() {
  set -euo pipefail

  local -r release_url='https://raw.githubusercontent.com/joshmoody24/nixos-config/main/shared/pkgs/soh-release.json'
  local -r app_dir="$HOME/.local/share/ship-of-harkinian"
  # The same folder the NixOS package uses, so saves move between them.
  local -r data_dir="$HOME/.local/share/soh"
  local -r launcher="$HOME/.local/bin/soh"
  # Global so the EXIT trap still sees it after main returns.
  work_dir="$(mktemp -d)"
  trap 'rm -rf "$work_dir"' EXIT

  local -r release="$(curl -fsSL "$release_url")"
  local -r version="$(json_field "$release" version)"
  local -r appimage_url="$(json_field "$release" linux url)"
  local -r appimage_sha256="$(json_field "$release" linux sha256)"

  install_game
  install_launcher
  local new_roms=()
  request_roms

  echo
  echo -e "\e[32mShip of Harkinian $version is installed.\e[0m Start it from your app menu or by running: soh"
  if ((${#new_roms[@]} > 0)); then
    echo 'Starting the game. It sets up your new ROMs first, then asks "Run SoH?"; click Yes.'
  else
    echo 'Starting the game.'
  fi
  # Passing ROMs makes the game process them even when it already has game data from
  # another ROM; otherwise it only looks for ROMs on its very first run.
  setsid "$launcher" "${new_roms[@]}" >/dev/null 2>&1 < /dev/null &
}

json_field() {
  python3 -c 'import json, sys; value = json.loads(sys.argv[1])
for key in sys.argv[2:]: value = value[key]
print(value)' "$@"
}

install_game() {
  local -r appimage="$work_dir/soh.appimage"
  echo "Downloading Ship of Harkinian $version..."
  curl -fL --progress-bar -o "$appimage" "$appimage_url"
  local -r actual_sha256="$(sha256sum "$appimage" | cut -d' ' -f1)"
  if [[ "$actual_sha256" != "$appimage_sha256" ]]; then
    echo "Download of $appimage_url has SHA256 $actual_sha256, expected $appimage_sha256" >&2
    exit 1
  fi

  # Unpacking once means the game runs without FUSE, which newer Fedora lacks.
  echo "Extracting to $app_dir..."
  chmod +x "$appimage"
  (cd "$work_dir" && "$appimage" --appimage-extract >/dev/null)
  rm -rf "$app_dir"
  mkdir -p "$(dirname "$app_dir")"
  mv "$work_dir/squashfs-root" "$app_dir"
}

install_launcher() {
  mkdir -p "$(dirname "$launcher")" "$HOME/.local/share/applications" "$data_dir"
  # The AppImage build saves to the working directory unless SHIP_HOME says otherwise.
  cat > "$launcher" <<EOF
#!/usr/bin/env bash
export SHIP_HOME="\${SHIP_HOME:-$data_dir}"
mkdir -p "\$SHIP_HOME"
cd "\$SHIP_HOME"
exec "$app_dir/AppRun" "\$@"
EOF
  chmod +x "$launcher"

  cat > "$HOME/.local/share/applications/soh.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=Ship of Harkinian
Exec=$launcher
Icon=$app_dir/sohIcon.png
Terminal=false
Categories=Game;
EOF
}

installed_roms() {
  find "$data_dir" -maxdepth 1 -type f \( -iname '*.z64' -o -iname '*.n64' -o -iname '*.v64' \) -printf '%f\n' | sort
}

is_rom_name() {
  [[ "${1,,}" =~ \.(z64|n64|v64)$ ]]
}

# Prints the extracted ROM's path.
extract_rom_from_zip() {
  python3 - "$1" "$work_dir" <<'EOF'
import os, re, sys, zipfile
with zipfile.ZipFile(sys.argv[1]) as archive:
    names = [n for n in archive.namelist() if re.search(r'\.(z64|n64|v64)$', n, re.I)]
    if not names:
        sys.exit('No .z64, .n64, or .v64 file inside the zip')
    destination = os.path.join(sys.argv[2], os.path.basename(names[0]))
    with archive.open(names[0]) as source, open(destination, 'wb') as target:
        target.write(source.read())
    print(destination)
EOF
}

free_rom_path() {
  local -r name="$1"
  local -r base="${name%.*}" extension="${name##*.}"
  local candidate suffix
  for suffix in '' $(seq 2 99); do
    candidate="$data_dir/$base${suffix:+-$suffix}.$extension"
    if [[ ! -e "$candidate" ]]; then
      echo "$candidate"
      return
    fi
  done
}

# Prints the installed file name, or nothing if this exact ROM is already installed.
add_rom() {
  local -r source="$1"
  local -r download="$work_dir/rom-download"
  local local_path
  if [[ "$source" =~ ^https?:// ]]; then
    echo 'Downloading ROM...' >&2
    curl -fL --progress-bar -o "$download" "$source" || { echo "Couldn't download $source" >&2; return 1; }
    local_path="$download"
  elif [[ -f "$source" ]]; then
    local_path="$source"
  else
    echo "No file at $source" >&2
    return 1
  fi

  # Download links often hide the file type, so sniff for a zip instead of trusting the name.
  local rom_path source_name
  if [[ "$(head -c 2 "$local_path")" == 'PK' ]]; then
    rom_path="$(extract_rom_from_zip "$local_path")" || return 1
    source_name="$(basename "$rom_path")"
  else
    rom_path="$local_path"
    source_name="$(basename "${source%%\?*}")"
  fi
  # The game reads byte order from the ROM header, so the extension only has to be
  # one it scans for.
  local -r rom_name="$(is_rom_name "$source_name" && echo "$source_name" || echo 'oot.z64')"

  local -r hash="$(sha256sum "$rom_path" | cut -d' ' -f1)"
  local installed
  while read -r installed; do
    if [[ -n "$installed" && "$(sha256sum "$data_dir/$installed" | cut -d' ' -f1)" == "$hash" ]]; then
      echo "Already installed as $installed, skipping" >&2
      return 0
    fi
  done < <(installed_roms)

  local -r destination="$(free_rom_path "$rom_name")"
  cp "$rom_path" "$destination"
  echo -e "\e[32mAdded $(basename "$destination")\e[0m" >&2
  echo "$destination"
}

# Fills new_roms with the paths of ROMs added this run.
request_roms() {
  local -r installed="$(installed_roms | paste -sd, - | sed 's/,/, /g')"
  echo
  if [[ -n "$installed" ]]; then
    echo "Installed ROMs: $installed"
  else
    echo 'Ship of Harkinian needs your own copy of the Ocarina of Time ROM.'
    echo 'Paste a download link or a file path (you can drag the file into this window).'
    echo 'Add a Master Quest ROM too if you want both versions.'
  fi

  local answer source added
  while true; do
    local have_rom='' prompt='ROM link or path'
    if [[ -n "$installed" ]] || ((${#new_roms[@]} > 0)); then
      have_rom=1
      prompt='Another ROM link or path (or press Enter to finish)'
    fi
    # stdin is this script when piped from curl, so ask the terminal directly.
    read -r -p "$prompt: " answer < /dev/tty
    source="$(normalize_source "$answer")"
    if [[ -z "$source" ]]; then
      [[ -n "$have_rom" ]] && return
      continue
    fi
    if added="$(add_rom "$source")"; then
      [[ -n "$added" ]] && new_roms+=("$added")
    else
      echo -e "\e[31mThat didn't work.\e[0m" >&2
    fi
  done
}

# Undoes what terminals do to dragged-in files: quotes, trailing spaces, file:// URIs.
normalize_source() {
  python3 - "$1" <<'EOF'
import sys, urllib.parse
value = sys.argv[1].strip().strip('"\'')
if value.startswith('file://'):
    value = urllib.parse.unquote(urllib.parse.urlparse(value).path)
print(value)
EOF
}

main "$@"
