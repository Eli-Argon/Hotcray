#!/usr/bin/env bash
# Downloads the programs Hotcray runs on, into this folder (same files as
# get-binaries.ps1, so one USB stick works on Windows and Linux):
#   bin/kanata                 kanata (Linux)
#   bin/kanata.exe             kanata (Windows, keyboard hook build "winIOv2")
#   bin/kanata_wintercept.exe  kanata for the optional Interception driver
#   Hotcray.exe                AutoHotkey v2 (renamed: runs Hotcray.ahk)
#
# Every download is checked against a known SHA-256 hash. To upgrade, change
# the versions AND hashes below (hashes: the release's "sha256sums" file).
set -euo pipefail
ROOT="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
KANATA=v1.11.0
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$ROOT/bin"

fetch() { # url sha256 zipmember:destination...
  local url="$1" sha="$2"; shift 2
  local zip="$TMP/$(basename "$url")"
  echo "Downloading $url"
  curl -fsSL --retry 3 -o "$zip" "$url"
  echo "$sha  $zip" | sha256sum -c --quiet - || { echo "Checksum mismatch for $url" >&2; exit 1; }
  local dir="$TMP/$(basename "$url" .zip)"
  mkdir -p "$dir"
  unzip -q -o "$zip" -d "$dir"
  for pair in "$@"; do
    local member="${pair%%:*}" dest="${pair#*:}"
    local src; src="$(find "$dir" -name "$member" -type f | head -n1)"
    [ -n "$src" ] || { echo "$member not found in $url" >&2; exit 1; }
    cp "$src" "$ROOT/$dest"
    echo "  -> $dest"
  done
}

fetch "https://github.com/jtroo/kanata/releases/download/$KANATA/linux-binaries-x64.zip" \
  d9f634afb4c7f078cc2aacf3998fd65b432d4d83296cc48a89f941525459b4e2 \
  kanata_linux_x64:bin/kanata
fetch "https://github.com/jtroo/kanata/releases/download/$KANATA/windows-binaries-x64.zip" \
  db43d06e7f8d0578bc77585bc24bb385cc99862e942e5554dbf3dec02bf081e9 \
  kanata_windows_tty_winIOv2_x64.exe:bin/kanata.exe \
  kanata_windows_tty_wintercept_x64.exe:bin/kanata_wintercept.exe
fetch "https://github.com/AutoHotkey/AutoHotkey/releases/download/v2.0.19/AutoHotkey_2.0.19.zip" \
  4e0d0e65655066a646a210951320feaef0729a3597177131adaec4066bef5869 \
  AutoHotkey64.exe:Hotcray.exe
chmod +x "$ROOT/bin/kanata"
echo
echo "Done. Start Hotcray with: linux/hotcray.sh"
