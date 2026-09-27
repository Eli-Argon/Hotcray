#!/usr/bin/env bash
# Hotcray for Linux — start/stop/set-up script.
#
#   linux/hotcray.sh                      start Hotcray (tray icon if available)
#   linux/hotcray.sh --stop               stop Hotcray (kanata + companion)
#   linux/hotcray.sh --setup-permissions  one-time, needs sudo: lets kanata run
#                                         without sudo (required for autostart)
#   linux/hotcray.sh --autostart on|off   start at log-in (XDG autostart)
#   linux/hotcray.sh --foreground         start in this terminal (logs visible)
#   linux/hotcray.sh --no-xkb             don't touch OS layouts (Cyrillic via
#                                         unicode/IBus instead)
#
# Everything else is in linux/hotcray-companion.py.
set -euo pipefail
HERE="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
ROOT="$(dirname "$HERE")"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/hotcray"
PIDFILE="$STATE_DIR/companion.pid"

die() { echo "hotcray: $*" >&2; command -v notify-send >/dev/null && notify-send -u critical Hotcray "$*" || true; exit 1; }

have_access() {
  [ -w /dev/uinput ] || return 1
  for e in /dev/input/event*; do [ -r "$e" ] || return 1; done
}

case "${1:-}" in
  -h|--help)
    sed -n '2,15p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;

  --stop)
    if [ -f "$PIDFILE" ] && kill "$(cat "$PIDFILE")" 2>/dev/null; then echo "Hotcray stopped."; else echo "Hotcray is not running."; fi
    exit 0 ;;

  --setup-permissions)
    # Standard kanata setup (https://github.com/jtroo/kanata/wiki/Avoid-using-sudo-on-Linux):
    # members of `input` may read keyboards, members of `uinput` may create
    # the virtual keyboard kanata types with.
    set -x
    sudo groupadd -f uinput
    sudo usermod -aG input,uinput "$USER"
    echo 'KERNEL=="uinput", MODE="0660", GROUP="uinput", OPTIONS+="static_node=uinput"' \
      | sudo tee /etc/udev/rules.d/99-hotcray-uinput.rules >/dev/null
    echo uinput | sudo tee /etc/modules-load.d/hotcray-uinput.conf >/dev/null
    sudo modprobe uinput
    sudo udevadm control --reload-rules
    sudo udevadm trigger
    set +x
    echo "Done. Log out and back in (group membership), then start Hotcray."
    exit 0 ;;

  --autostart)
    exec python3 "$HERE/hotcray-companion.py" --autostart "${2:-on}" ;;
esac

command -v python3 >/dev/null || die "python3 is required."
[ -x "$ROOT/bin/kanata" ] || command -v kanata >/dev/null || die "kanata not found. Run ./get-binaries.sh first."

if ! have_access; then
  # Someone else's computer: use sudo for this session only.
  if [ -t 0 ]; then
    echo "kanata needs access to the keyboard devices; asking for sudo (only for this session)."
    echo "On your own PC run '$0 --setup-permissions' once instead."
    sudo -v || die "sudo refused."
  else
    die "kanata has no access to /dev/uinput and /dev/input. Run '$0 --setup-permissions' once (or start from a terminal)."
  fi
fi

mkdir -p "$STATE_DIR"
if [ "${1:-}" = "--foreground" ]; then
  shift
  exec python3 "$HERE/hotcray-companion.py" "$@"
fi
setsid python3 "$HERE/hotcray-companion.py" "$@" >>"$STATE_DIR/companion.log" 2>&1 < /dev/null &
echo "Hotcray started (log: $STATE_DIR/companion.log). Stop with: $0 --stop"
