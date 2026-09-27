#!/usr/bin/env python3
"""Hotcray — Linux companion.

The Linux counterpart of Hotcray.ahk. kanata does all the key remapping;
this program:
  * configures the OS keyboard layouts for Cyrillic (English + Ukrainian,
    "Caps Lock = first layout, Shift+Caps Lock = last layout") and puts the
    previous settings back when it exits;
  * starts kanata, restarts it if it dies, stops it on exit;
  * shows a tray icon (blue = Latin, red = Cyrillic, grey = paused) if the
    desktop supports it (GTK + AppIndicator), otherwise works without one;
  * answers kanata's per-application keys (` in VS Code / browsers / Dolphin,
    Firefox numpad keys), by asking kanata to press virtual keys.

Only the Python standard library is required. The tray icon additionally
needs PyGObject + (Ayatana)AppIndicator3, which most desktops ship.

Normally started through linux/hotcray.sh; run with --help for options.
"""
import argparse
import glob
import json
import os
import shutil
import signal
import socket
import subprocess
import sys
import threading
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
PORT = int(os.environ.get("HOTCRAY_PORT", "37373"))
STATE_DIR = Path(os.environ.get("XDG_STATE_HOME", Path.home() / ".local" / "state")) / "hotcray"
PIDFILE = STATE_DIR / "companion.pid"
LOGFILE = STATE_DIR / "kanata.log"
SAVED_XKB = STATE_DIR / "saved-xkb.json"
AUTOSTART = Path(os.environ.get("XDG_CONFIG_HOME", Path.home() / ".config")) / "autostart" / "hotcray.desktop"

BASE_LAYERS = {"lat", "cyr", "off"}


def log(*a):
    print("[hotcray]", *a, flush=True)


def run(cmd, **kw):
    """Run a command, return (exit code, stdout). Never raises."""
    try:
        p = subprocess.run(cmd, capture_output=True, text=True, timeout=10, **kw)
        return p.returncode, p.stdout.strip()
    except Exception as e:  # noqa: BLE001 - missing tools are normal here
        return 127, str(e)


def notify(summary, body="", urgency="normal"):
    if shutil.which("notify-send"):
        run(["notify-send", "-a", "Hotcray", "-u", urgency, "-i", str(ROOT / "icons" / "hotcray.png"), summary, body])
    log(summary, body)


# ═══════════════════════════════════════════════════════════════════════════
#  OS keyboard layouts (xkb): English + Ukrainian, Caps / Shift+Caps select
# ═══════════════════════════════════════════════════════════════════════════
# The option has two names; grp:shift_caps_switch exists in old and new
# xkeyboard-config versions, grp:caps_select only in new ones.
XKB_OPTION = "grp:shift_caps_switch"


class Xkb:
    """Applies/restores the layout settings for the running desktop."""

    def __init__(self):
        desk = os.environ.get("XDG_CURRENT_DESKTOP", "").lower()
        session = os.environ.get("XDG_SESSION_TYPE", "").lower()
        if any(d in desk for d in ("gnome", "unity", "budgie", "pantheon")) and shutil.which("gsettings"):
            self.kind = "gnome"
        elif "kde" in desk and (shutil.which("kwriteconfig6") or shutil.which("kwriteconfig5")):
            self.kind = "kde"
        elif session == "x11" and shutil.which("setxkbmap") and os.environ.get("DISPLAY"):
            self.kind = "x11"
        else:
            self.kind = None
        self.applied = False

    # -- GNOME -------------------------------------------------------------
    def _gget(self, key):
        return run(["gsettings", "get", "org.gnome.desktop.input-sources", key])[1]

    def _gset(self, key, value):
        return run(["gsettings", "set", "org.gnome.desktop.input-sources", key, value])[0] == 0

    # -- KDE ---------------------------------------------------------------
    def _kde(self, *args):
        tool = shutil.which("kwriteconfig6") or shutil.which("kwriteconfig5")
        return run([tool, "--file", "kxkbrc", "--group", "Layout", *args])[0] == 0

    def _kread(self, key):
        tool = shutil.which("kreadconfig6") or shutil.which("kreadconfig5")
        return run([tool, "--file", "kxkbrc", "--group", "Layout", "--key", key])[1] if tool else ""

    def _kde_reload(self):
        run(["dbus-send", "--session", "--type=signal", "--reply-timeout=100", "--dest=org.kde.keyboard",
             "/Layouts", "org.kde.keyboard.reloadConfig"])

    def apply(self):
        """Returns True if the OS now has us,ua + the Caps option."""
        if not self.kind:
            return False
        saved = {}
        ok = False
        if self.kind == "gnome":
            saved = {"sources": self._gget("sources"), "xkb-options": self._gget("xkb-options"),
                     "per-window": self._gget("per-window")}
            ok = (self._gset("sources", "[('xkb', 'us'), ('xkb', 'ua')]")
                  and self._gset("xkb-options", f"['{XKB_OPTION}']")
                  and self._gset("per-window", "false"))
        elif self.kind == "kde":
            saved = {k: self._kread(k) for k in ("LayoutList", "VariantList", "Options", "ResetOldOptions", "Use")}
            ok = (self._kde("--key", "LayoutList", "us,ua") and self._kde("--key", "VariantList", ",")
                  and self._kde("--key", "Options", XKB_OPTION) and self._kde("--key", "ResetOldOptions", "true")
                  and self._kde("--key", "Use", "true"))
            self._kde_reload()
        elif self.kind == "x11":
            saved = {"query": run(["setxkbmap", "-query"])[1]}
            ok = run(["setxkbmap", "-layout", "us,ua", "-variant", ",", "-option", "", "-option", XKB_OPTION])[0] == 0
        if saved and not SAVED_XKB.exists():   # keep the oldest (true original) settings
            SAVED_XKB.write_text(json.dumps({"kind": self.kind, "saved": saved}))
        self.applied = ok
        return ok

    def restore(self):
        if not SAVED_XKB.exists():
            return
        try:
            data = json.loads(SAVED_XKB.read_text())
        except ValueError:
            SAVED_XKB.unlink(missing_ok=True)
            return
        kind, saved = data.get("kind"), data.get("saved", {})
        if kind == "gnome":
            for k, v in saved.items():
                if v:
                    self._gset(k, v)
        elif kind == "kde":
            for k, v in saved.items():
                self._kde("--key", k, v)
            self._kde_reload()
        elif kind == "x11":
            q = dict(line.split(":", 1) for line in saved.get("query", "").splitlines() if ":" in line)
            cmd = ["setxkbmap", "-layout", q.get("layout", "us").strip(), "-option", ""]
            if q.get("variant", "").strip():
                cmd += ["-variant", q["variant"].strip()]
            for opt in q.get("options", "").strip().split(","):
                if opt:
                    cmd += ["-option", opt]
            run(cmd)
        SAVED_XKB.unlink(missing_ok=True)
        self.applied = False


# ═══════════════════════════════════════════════════════════════════════════
#  Active window (for the per-application keys)
# ═══════════════════════════════════════════════════════════════════════════
def active_window_class():
    """Lower-case class/app-id of the focused window, or '' if unknown."""
    if os.environ.get("SWAYSOCK") and shutil.which("swaymsg"):
        code, out = run(["swaymsg", "-t", "get_tree"])
        if code == 0:
            def walk(n):
                if n.get("focused"):
                    return n.get("app_id") or (n.get("window_properties") or {}).get("class") or ""
                for c in n.get("nodes", []) + n.get("floating_nodes", []):
                    r = walk(c)
                    if r:
                        return r
                return ""
            try:
                return walk(json.loads(out)).lower()
            except ValueError:
                pass
    if os.environ.get("HYPRLAND_INSTANCE_SIGNATURE") and shutil.which("hyprctl"):
        code, out = run(["hyprctl", "activewindow", "-j"])
        if code == 0:
            try:
                return json.loads(out).get("class", "").lower()
            except ValueError:
                pass
    if shutil.which("kdotool"):
        code, out = run(["kdotool", "getactivewindow", "getwindowclassname"])
        if code == 0 and out:
            return out.lower()
    if os.environ.get("DISPLAY") and shutil.which("xprop"):
        code, out = run(["xprop", "-root", "_NET_ACTIVE_WINDOW"])
        wid = out.split()[-1] if code == 0 and out else ""
        if wid.startswith("0x") and wid != "0x0":
            code, out = run(["xprop", "-id", wid, "WM_CLASS"])
            if code == 0 and "=" in out:
                # WM_CLASS(STRING) = "instance", "Class"
                return out.split("=", 1)[1].split(",")[-1].strip().strip('"').lower()
    return ""


# Per-application decisions. Return the name of a kanata virtual key
# (defvirtualkeys in hotcray.kbd) to press, or None for "do nothing".
VSCODE = ("code", "code-oss", "vscodium", "cursor")
BROWSERS = ("firefox", "librewolf", "chromium", "google-chrome", "brave-browser", "microsoft-edge", "vivaldi", "zen")


def is_app(cls, names):
    return any(n in cls for n in names)


def on_app_key(key):
    cls = active_window_class()
    firefox = "firefox" in cls or "librewolf" in cls
    if key == "grv":
        if is_app(cls, VSCODE):
            return "out-c-grv"      # toggle VS Code's terminal
        if is_app(cls, BROWSERS):
            return "out-f12"        # developer tools
        if "dolphin" in cls:
            return "out-f4"         # Dolphin's built-in terminal panel
        return "out-grv"
    if key == "nlck":
        return "out-ff-yt" if firefox else None
    if key == "kp+":
        return "out-c" if firefox else "out-kp+"
    if key == "kp0":
        return "out-f" if firefox else "out-ins"
    return None


# ═══════════════════════════════════════════════════════════════════════════
#  kanata process + TCP connection
# ═══════════════════════════════════════════════════════════════════════════
def kanata_binary():
    for p in (ROOT / "bin" / "kanata", ROOT / "bin" / "kanata_linux_x64"):
        if p.exists():
            return p
    found = shutil.which("kanata")
    return Path(found) if found else None


def have_device_access():
    events = glob.glob("/dev/input/event*")
    return os.access("/dev/uinput", os.W_OK) and bool(events) and all(os.access(e, os.R_OK) for e in events)


class Kanata:
    def __init__(self, xkb_mode):
        self.proc = None
        self.xkb_mode = xkb_mode
        self.want = False
        self.crashes = []
        self.lock = threading.Lock()

    def check_config(self):
        exe = kanata_binary()
        if not exe:
            return "kanata not found. Run ./get-binaries.sh first."
        code, out = run([str(exe), "--check", "--cfg", str(ROOT / "hotcray.kbd")])
        return "" if code == 0 else out[-1500:]

    def start(self):
        with self.lock:
            self.want = True
            if self.proc and self.proc.poll() is None:
                return True
            err = self.check_config()
            if err:
                self.want = False
                notify("Hotcray: kanata not started", err, "critical")
                return False
            env = dict(os.environ, HOTCRAY_LINUX_XKB="yes" if self.xkb_mode else "")
            cmd = [str(kanata_binary()), "--cfg", str(ROOT / "hotcray.kbd"),
                   "--port", f"127.0.0.1:{PORT}", "--no-wait", "--quiet"]
            if not have_device_access():
                # Temporary use on someone else's PC: needs sudo each time.
                # For your own PC run `linux/hotcray.sh --setup-permissions` once.
                cmd = ["sudo", "-n", "env", f"HOTCRAY_LINUX_XKB={env['HOTCRAY_LINUX_XKB']}"] + cmd
            logf = open(LOGFILE, "ab")
            self.proc = subprocess.Popen(cmd, env=env, stdout=logf, stderr=subprocess.STDOUT,
                                         stdin=subprocess.DEVNULL, start_new_session=True)
            log("kanata started, pid", self.proc.pid)
            return True

    def stop(self):
        with self.lock:
            self.want = False
            p, self.proc = self.proc, None
        if p and p.poll() is None:
            p.terminate()
            try:
                p.wait(5)
            except subprocess.TimeoutExpired:
                p.kill()

    def watchdog(self, on_state):
        while True:
            time.sleep(2)
            with self.lock:
                dead = self.want and self.proc is not None and self.proc.poll() is not None
            if not dead:
                continue
            now = time.time()
            self.crashes = [t for t in self.crashes if now - t < 60] + [now]
            if len(self.crashes) >= 3:
                self.want = False
                on_state("stopped")
                notify("Hotcray: kanata keeps stopping", f"Not restarting. See {LOGFILE}", "critical")
                continue
            notify("Hotcray: kanata stopped unexpectedly", "Restarting it.")
            self.proc = None
            self.start()


class Link:
    """TCP connection to kanata: receives layer changes / messages."""

    def __init__(self, on_layer, on_message):
        self.on_layer, self.on_message = on_layer, on_message
        self.sock = None
        self.send_lock = threading.Lock()

    def send(self, obj):
        with self.send_lock:
            if self.sock:
                try:
                    self.sock.sendall((json.dumps(obj) + "\n").encode())
                except OSError:
                    pass

    def tap(self, vkey):
        self.send({"ActOnFakeKey": {"name": vkey, "action": "Tap"}})

    def loop(self):
        while True:
            try:
                s = socket.create_connection(("127.0.0.1", PORT), timeout=3)
                s.settimeout(None)
                self.sock = s
                buf = b""
                while True:
                    chunk = s.recv(4096)
                    if not chunk:
                        break
                    buf += chunk
                    while b"\n" in buf:
                        line, buf = buf.split(b"\n", 1)
                        self.handle(line)
            except OSError:
                pass
            self.sock = None
            time.sleep(1)

    def handle(self, line):
        try:
            msg = json.loads(line)
        except ValueError:
            return
        if not isinstance(msg, dict):
            return
        if "LayerChange" in msg:
            layer = msg["LayerChange"].get("new", "")
            if layer in BASE_LAYERS:
                self.on_layer(layer)
        elif "MessagePush" in msg:
            m = msg["MessagePush"].get("message")
            if isinstance(m, str):
                self.on_message(m)


# ═══════════════════════════════════════════════════════════════════════════
#  Tray icon (optional) and main program
# ═══════════════════════════════════════════════════════════════════════════
class App:
    def __init__(self, args):
        self.args = args
        self.xkb = Xkb()
        self.xkb_mode = False
        self.state = "stopped"
        self.kanata = None
        self.link = Link(self.set_state_from_kanata, self.on_message)
        self.tray = None
        self.glib = None

    # --- state ---------------------------------------------------------
    def set_state_from_kanata(self, layer):
        self.set_state(layer)

    def set_state(self, state):
        self.state = state
        if self.tray:
            self.glib.idle_add(self.tray.update, state)

    def on_message(self, m):
        if m.startswith("app:"):
            vkey = on_app_key(m[4:])
            if vkey:
                self.link.tap(vkey)

    # --- lifecycle -----------------------------------------------------
    def start(self):
        if not self.args.no_xkb:
            self.xkb_mode = self.xkb.apply()
        if not self.xkb_mode:
            log("OS layout switching not configured; Cyrillic will be typed as unicode "
                "(needs IBus, Ctrl+Shift+U). Supported: GNOME, KDE, X11.")
            if self.xkb.kind == "x11":
                run(["setxkbmap", "us"])
        self.kanata = Kanata(self.xkb_mode)
        if self.kanata.start():
            self.set_state("lat")
            self.fix_lock_keys()

    def pause(self):
        self.kanata.stop()
        self.xkb.restore()
        self.set_state("stopped")

    def resume(self):
        if not self.args.no_xkb:
            self.xkb_mode = self.xkb.apply()
        self.kanata.xkb_mode = self.xkb_mode
        if self.kanata.start():
            self.set_state("lat")

    def reload(self):
        err = self.kanata.check_config()
        if err:
            notify("Hotcray: config not reloaded", err, "critical")
            return
        self.kanata.stop()
        self.resume()

    def quit(self, *_):
        if self.kanata:
            self.kanata.stop()
        self.xkb.restore()
        PIDFILE.unlink(missing_ok=True)
        os._exit(0)

    def fix_lock_keys(self):
        # kanata swallows CapsLock/NumLock, so they only need turning off once.
        def led(name):
            for f in glob.glob(f"/sys/class/leds/*::{name}/brightness"):
                try:
                    if Path(f).read_text().strip() != "0":
                        return True
                except OSError:
                    pass
            return False
        time.sleep(3)   # kanata's start-up delay
        if led("numlock"):
            self.link.tap("out-nlck")
        if led("capslock"):
            if not self.xkb_mode:
                self.link.tap("out-caps")
            elif shutil.which("xdotool") and os.environ.get("DISPLAY"):
                run(["xdotool", "key", "Caps_Lock"])

    # --- main ----------------------------------------------------------
    def main(self):
        STATE_DIR.mkdir(parents=True, exist_ok=True)
        if PIDFILE.exists():
            try:
                os.kill(int(PIDFILE.read_text()), 0)
                sys.exit("Hotcray is already running (linux/hotcray.sh --stop to stop it).")
            except (OSError, ValueError):
                pass
        PIDFILE.write_text(str(os.getpid()))
        self.xkb.restore()    # left over from a crash
        signal.signal(signal.SIGTERM, self.quit)
        signal.signal(signal.SIGINT, self.quit)
        threading.Thread(target=self.link.loop, daemon=True).start()
        self.start()
        threading.Thread(target=self.kanata.watchdog, args=(self.set_state,), daemon=True).start()
        if not self.args.no_tray and self.try_tray():
            self.tray.run()
        else:
            notify("Hotcray started", "ScrollLock (or Right Shift+Esc) pauses. linux/hotcray.sh --stop quits.")
            while True:
                signal.pause()

    def try_tray(self):
        try:
            import gi
            gi.require_version("Gtk", "3.0")
            from gi.repository import GLib, Gtk
            ind = None
            for name in ("AyatanaAppIndicator3", "AppIndicator3"):
                try:
                    gi.require_version(name, "0.1")
                    ind = __import__("gi.repository", fromlist=[name]).__dict__[name]
                    break
                except (ValueError, ImportError, KeyError):
                    continue
            if ind is None:
                return False
        except (ImportError, ValueError):
            return False
        self.glib = GLib
        self.tray = Tray(self, Gtk, GLib, ind)
        return True


class Tray:
    ICONS = {"lat": "latin", "cyr": "cyrillic", "off": "off", "stopped": "off"}
    TIPS = {"lat": "Latin", "cyr": "Cyrillic", "off": "paused (ScrollLock)", "stopped": "stopped"}

    def __init__(self, app, Gtk, GLib, AI):
        self.app, self.Gtk, self.GLib = app, Gtk, GLib
        self.ind = AI.Indicator.new("hotcray", str(ROOT / "icons" / "off.png"),
                                    AI.IndicatorCategory.APPLICATION_STATUS)
        self.ind.set_status(AI.IndicatorStatus.ACTIVE)
        menu = Gtk.Menu()
        self.status_item = Gtk.MenuItem(label="Hotcray")
        self.status_item.set_sensitive(False)
        menu.append(self.status_item)
        menu.append(Gtk.SeparatorMenuItem())
        self.pause_item = Gtk.MenuItem(label="Pause")
        self.pause_item.connect("activate", lambda *_: self.toggle_pause())
        menu.append(self.pause_item)
        for label, fn in (("Reload config", lambda *_: threading.Thread(target=app.reload).start()),
                          ("Edit config", lambda *_: run(["xdg-open", str(ROOT / "hotcray.kbd")])),
                          ("Key map (cheat sheet)", lambda *_: run(["xdg-open", str(ROOT / "docs" / "LAYOUT.md")])),
                          ("Open log", lambda *_: run(["xdg-open", str(LOGFILE)]))):
            item = Gtk.MenuItem(label=label)
            item.connect("activate", fn)
            menu.append(item)
        menu.append(Gtk.SeparatorMenuItem())
        self.auto_item = Gtk.CheckMenuItem(label="Start at log-in")
        self.auto_item.set_active(AUTOSTART.exists())
        self.auto_item.connect("toggled", lambda w: set_autostart(w.get_active()))
        menu.append(self.auto_item)
        menu.append(Gtk.SeparatorMenuItem())
        q = Gtk.MenuItem(label="Quit")
        q.connect("activate", app.quit)
        menu.append(q)
        menu.show_all()
        self.ind.set_menu(menu)
        self.update(app.state)

    def toggle_pause(self):
        target = self.app.resume if self.app.state in ("off", "stopped") else self.app.pause
        threading.Thread(target=target).start()

    def update(self, state):
        self.ind.set_icon_full(str(ROOT / "icons" / f"{self.ICONS[state]}.png"), self.TIPS[state])
        self.status_item.set_label("Hotcray — " + self.TIPS[state])
        self.pause_item.set_label("Resume" if state in ("off", "stopped") else "Pause")
        return False

    def run(self):
        self.GLib.unix_signal_add(self.GLib.PRIORITY_DEFAULT, signal.SIGTERM, self.app.quit)
        self.GLib.unix_signal_add(self.GLib.PRIORITY_DEFAULT, signal.SIGINT, self.app.quit)
        self.Gtk.main()


def set_autostart(enable):
    if enable:
        AUTOSTART.parent.mkdir(parents=True, exist_ok=True)
        AUTOSTART.write_text(
            "[Desktop Entry]\nType=Application\nName=Hotcray\nComment=Keyboard layout (kanata)\n"
            f"Exec=\"{ROOT / 'linux' / 'hotcray.sh'}\"\nIcon={ROOT / 'icons' / 'hotcray.png'}\n"
            "X-GNOME-Autostart-enabled=true\nTerminal=false\n")
        if not have_device_access():
            notify("Hotcray: autostart needs permissions",
                   "Run once: linux/hotcray.sh --setup-permissions (otherwise kanata needs sudo at every start).")
    else:
        AUTOSTART.unlink(missing_ok=True)


def main():
    ap = argparse.ArgumentParser(description="Hotcray Linux companion (see README.md)")
    ap.add_argument("--no-tray", action="store_true", help="don't show a tray icon")
    ap.add_argument("--no-xkb", action="store_true",
                    help="don't touch the OS layouts; type Cyrillic as unicode (needs IBus)")
    ap.add_argument("--autostart", choices=["on", "off"], help="enable/disable start at log-in and exit")
    args = ap.parse_args()
    if args.autostart:
        set_autostart(args.autostart == "on")
        print("autostart", args.autostart, "-", AUTOSTART)
        return
    App(args).main()


if __name__ == "__main__":
    main()
