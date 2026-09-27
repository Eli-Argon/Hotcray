#!/usr/bin/env python3
"""Automated tests for hotcray.kbd, using kanata's official simulator.

The simulator (`kanata_simulated_input`) feeds a list of fake key presses to
the real kanata engine and prints every key kanata would send to the OS.
Each test below says "press these keys" and "expect exactly this output".

Usage:
    python3 tests/sim_tests.py [path/to/kanata_simulated_input]

The simulator is built from kanata's source (see .github/workflows/ci.yml):
    cargo build --release -p kanata-sim
The simulator runs on Linux, so Windows behaviour is tested by swapping the
(platform (win ...)) and (platform (linux)) blocks in a temporary copy.
"""
import os
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SIM = sys.argv[1] if len(sys.argv) > 1 else shutil.which("kanata_simulated_input") or "kanata_simulated_input"

# ---------------------------------------------------------------------------
# Test cases: (name, platform, xkb, input, expected output)
#   platform: "win" or "linux";  xkb: HOTCRAY_LINUX_XKB=yes
#   input:  simulator syntax: d:key = press, u:key = release, t:N = wait N ms
#   expected: space-separated events as printed by the simulator:
#             ↓Key / ↑Key for key codes, U:x for unicode characters.
#   The start-up signal (F13 on Windows, Caps on Linux+xkb) is stripped.
# ---------------------------------------------------------------------------
T = []
def test(name, platform, inp, exp, xkb=False):
    T.append((name, platform, xkb, inp, exp))

# --- Latin layer --------------------------------------------------------------
test("latin: k types e", "win", "d:k u:k t:5", "↓E ↑E")
test("latin: Shift+k types E", "win", "d:lsft d:k u:k u:lsft t:5", "↓LShift ↓E ↑E ↑LShift")
test("latin: Ctrl+k is Ctrl+K (QWERTY shortcuts)", "win", "d:lctl d:k u:k u:lctl t:5", "↓LCtrl ↓K ↑K ↑LCtrl")
test("latin: LCtrl+d is Ctrl+H", "win", "d:lctl d:d u:d u:lctl t:5", "↓LCtrl ↓H ↑H ↑LCtrl")
test("latin: RCtrl+d stays Ctrl+D", "win", "d:rctl d:d u:d u:rctl t:5", "↓RCtrl ↓D ↑D ↑RCtrl")
test("latin: LCtrl+q is Alt+C", "win", "d:lctl d:q u:q u:lctl t:5", "↓LCtrl ↑LCtrl ↓LAlt ↓C ↑LAlt ↑C ↓LCtrl ↑LCtrl")
test("latin: p types /", "win", "d:p u:p t:5", "↓Slash ↑Slash")
test("latin: Shift+p types \\", "win", "d:lsft d:p u:p u:lsft t:5", "↓LShift ↑LShift ↓Bslash ↑Bslash ↓LShift ↑LShift")
test("latin: [ types «", "win", "d:lbrc u:lbrc t:5", "U:«")
test("latin: CapsLock is Backspace", "win", "d:caps u:caps t:5", "↓BSpace ↑BSpace")
test("latin: \\ is Alt+D", "win", "d:bksl u:bksl t:5", "↓LAlt ↓D ↑LAlt ↑D")
test("latin: ` is the per-app signal F16", "win", "d:grv u:grv t:5", "↓F16 ↑F16")
test("latin: Shift+` is №", "win", "d:lsft d:grv u:grv u:lsft t:5", "↓LShift U:№ ↑LShift")

# --- Cyrillic -----------------------------------------------------------------
W_SPC = "d:lmet t:5 d:spc u:spc u:lmet t:5 "
test("Win+Space switches to Cyrillic, signals F14", "win", W_SPC, "↓LGui ↓F14 ↑LGui ↑F14")
test("cyrillic: a types у", "win", W_SPC + "d:a u:a t:5", "↓LGui ↓F14 ↑LGui ↑F14 U:у")
test("cyrillic: Shift+a types У", "win", W_SPC + "d:lsft d:a u:a u:lsft t:5", "↓LGui ↓F14 ↑LGui ↑F14 ↓LShift U:У ↑LShift")
test("cyrillic: v types і (no more ы/і toggle)", "win", W_SPC + "d:v u:v d:v u:v t:5", "↓LGui ↓F14 ↑LGui ↑F14 U:і U:і")
test("cyrillic: Ctrl+c is Ctrl+C", "win", W_SPC + "d:lctl d:c u:c u:lctl t:5", "↓LGui ↓F14 ↑LGui ↑F14 ↓LCtrl ↓C ↑C ↑LCtrl")
test("cyrillic: Shift+1 types ы", "win", W_SPC + "d:lsft d:1 u:1 u:lsft t:5", "↓LGui ↓F14 ↑LGui ↑F14 ↓LShift U:ы ↑LShift")
test("cyrillic: 1 types 1", "win", W_SPC + "d:1 u:1 t:5", "↓LGui ↓F14 ↑LGui ↑F14 ↓Kb1 ↑Kb1")
test("cyrillic: \\ types й", "win", W_SPC + "d:bksl u:bksl t:5", "↓LGui ↓F14 ↑LGui ↑F14 U:й")
test("Win+Space twice returns to Latin (F13)", "win", W_SPC + W_SPC + "d:k u:k t:5", "↓LGui ↓F14 ↑LGui ↑F14 ↓LGui ↓F13 ↑LGui ↑F13 ↓E ↑E")

# --- Linux, xkb strategy ----------------------------------------------------------
test("xkb: Win+Space sends Shift+Caps (OS layout 2)", "linux", W_SPC, "↓LGui ↓LShift ↓CapsLock ↑LGui ↑LShift ↑CapsLock", xkb=True)
test("xkb: cyrillic a (у) is key E of the Ukrainian layout", "linux", W_SPC + "d:a u:a t:5", "↓LGui ↓LShift ↓CapsLock ↑LGui ↑LShift ↑CapsLock ↓E ↑E", xkb=True)
test("xkb: cyrillic z (.) is the / key", "linux", W_SPC + "d:z u:z t:5", "↓LGui ↓LShift ↓CapsLock ↑LGui ↑LShift ↑CapsLock ↓Slash ↑Slash", xkb=True)
test("xkb: AltGr+, (;) flips to English and back", "linux", W_SPC + "d:ralt d:comm u:comm u:ralt t:30",
     "↓LGui ↓LShift ↓CapsLock ↑LGui ↑LShift ↑CapsLock ↓CapsLock ↓SColon ↑SColon ↑CapsLock ↓LShift ↓CapsLock ↑LShift ↑CapsLock", xkb=True)
test("xkb: latin symbols need no flip", "linux", "d:ralt d:comm u:comm u:ralt t:30", "↓SColon ↑SColon", xkb=True)
test("linux: ` sends a TCP message, not a key", "linux", "d:grv u:grv t:5", "")

# --- AltGr symbols & accents -----------------------------------------------------
test("sym: AltGr+i is (", "win", "d:ralt d:i u:i u:ralt t:5", "↓LShift ↓Kb9 ↑LShift ↑Kb9")
test("sym: AltGr+Shift+i is [", "win", "d:ralt d:lsft d:i u:i u:lsft u:ralt t:5", "↓LShift ↑LShift ↓LBracket ↑LBracket ↓LShift ↑LShift")
test("accent: e + AltGr+Shift+s = é (one character)", "win", "d:k u:k t:10 d:ralt d:lsft d:s u:s u:lsft u:ralt t:5",
     "↓E ↑E ↓LShift ↓BSpace ↑LShift ↑BSpace U:é")
test("accent: E + AltGr+Shift+s = É", "win", "d:lsft d:k u:k u:lsft t:10 d:ralt d:lsft d:s u:s u:lsft u:ralt t:5",
     "↓LShift ↓E ↑E ↑LShift ↓LShift ↓BSpace ↑LShift ↑BSpace U:É")
test("accent: E + accent with Shift still held = É", "win", "d:lsft d:k u:k t:10 d:ralt d:s u:s u:ralt u:lsft t:5",
     "↓LShift ↓E ↑E ↓BSpace ↑BSpace ↑LShift U:É")
test("accent: after space = combining accent", "win", "d:spc u:spc t:10 d:ralt d:lsft d:s u:s u:lsft u:ralt t:5",
     "↓Space ↑Space ↓LShift U:\u0301 ↑LShift")
test("accent: letter too old = combining accent", "win", "d:k u:k t:3500 d:ralt d:lsft d:s u:s u:lsft u:ralt t:5",
     "↓E ↑E ↓LShift U:\u0301 ↑LShift")
test("accent: in Cyrillic mode = combining accent", "win", W_SPC + "d:ralt d:lsft d:f u:f u:lsft u:ralt t:5",
     "↓LGui ↓F14 ↑LGui ↑F14 ↓LShift U:\u0308 ↑LShift")

# --- Navigation (Left Alt) ------------------------------------------------------
test("nav: LAlt+j is a plain Left arrow (no Ctrl events!)", "win", "d:lalt t:5 d:j u:j u:lalt t:5", "↓Left ↑Left")
test("nav: LAlt tap is Esc", "win", "d:lalt t:50 u:lalt t:5", "↓Escape ↑Escape")
test("nav: LAlt+LCtrl+j is Ctrl+Left", "win", "d:lalt t:5 d:lctl d:j u:j u:lctl u:lalt t:5", "↓LCtrl ↓Left ↑Left ↑LCtrl")
test("nav: LAlt+;+j selects (Shift+Left)", "win", "d:lalt t:5 d:scln d:j u:j u:scln u:lalt t:5", "↓LShift ↓Left ↑Left ↑LShift")
test("nav: LAlt+c is Ctrl+C", "win", "d:lalt t:5 d:c u:c u:lalt t:5", "↓LCtrl ↓C ↑LCtrl ↑C")
test("nav: LAlt+Shift+z is Ctrl+Y", "win", "d:lalt t:5 d:lsft d:z u:z u:lsft u:lalt t:5", "↓LShift ↑LShift ↓LCtrl ↓Y ↑LCtrl ↑Y ↓LShift ↑LShift")
test("nav: LAlt+RAlt+j is Alt+Left", "win", "d:lalt t:5 d:ralt d:j u:j u:ralt u:lalt t:5", "↓LAlt ↓Left ↑LAlt ↑Left")
test("nav: LAlt+RAlt+s is Ctrl+PgUp", "win", "d:lalt t:5 d:ralt d:s u:s u:ralt u:lalt t:5", "↓LCtrl ↓PgUp ↑LCtrl ↑PgUp")

# --- Win key ----------------------------------------------------------------------
test("win: Win+e stays Win+E (QWERTY)", "win", "d:lmet t:5 d:e u:e u:lmet t:5", "↓LGui ↓E ↑E ↑LGui")
test("win: Win+Tab+Tab = Alt held, Tab, Tab", "win", "d:lmet t:5 d:tab u:tab t:10 d:tab u:tab t:10 u:lmet t:5",
     "↓LGui ↓LAlt ↑LGui ↓Tab ↑Tab ↓Tab ↑Tab ↑LAlt ↑LAlt")

# --- Pause (ScrollLock) --------------------------------------------------------------
test("ScrollLock pauses: keys pass through", "win", "d:slck u:slck t:5 d:k u:k d:caps u:caps t:5",
     "↓ScrollLock ↑ScrollLock ↓F15 ↑F15 ↓K ↑K ↓CapsLock ↑CapsLock")
test("ScrollLock again resumes", "win", "d:slck u:slck t:5 d:slck u:slck t:5 d:k u:k t:5",
     "↓ScrollLock ↑ScrollLock ↓F15 ↑F15 ↓ScrollLock ↑ScrollLock ↓F13 ↑F13 ↓E ↑E")
test("RShift+Esc pauses (keyboards without ScrollLock)", "win", "d:rsft d:esc u:esc u:rsft t:5 d:k u:k t:5",
     "↓RShift ↓ScrollLock ↑ScrollLock ↓F15 ↑RShift ↑F15 ↓K ↑K")

# --- Numpad ---------------------------------------------------------------------------
test("numpad: 7 is Volume Up", "win", "d:kp7 u:kp7 t:5", "↓VolUp ↑VolUp")
test("numpad: 8 is Up regardless of NumLock", "win", "d:kp8 u:kp8 t:5", "↓Up ↑Up")
test("numpad: NumLock goes to the companion (F17)", "win", "d:nlck u:nlck t:5", "↓F17 ↑F17")



def windows_variant(src: Path, dst_dir: Path) -> Path:
    """Copy the config, swapping the Windows and Linux platform blocks."""
    text = src.read_text(encoding="utf-8")
    text = text.replace("(platform (linux)", "(platform (TMP)")
    text = text.replace("(platform (win winiov2 wintercept)", "(platform (linux)")
    text = text.replace("(platform (TMP)", "(platform (win)")
    out = dst_dir / "hotcray.kbd"
    out.write_text(text, encoding="utf-8")
    shutil.copy(src.parent / "hotcray-diacritics.kbd", dst_dir)
    return out


def run(cfg: Path, inp: str, xkb: bool) -> str:
    with tempfile.NamedTemporaryFile("w", suffix=".txt", delete=False, encoding="utf-8") as f:
        # Let the start-up signal finish first, and give the engine time to
        # flush the last releases at the end.
        f.write("t:50 " + inp + " t:100")
        sim_file = f.name
    env = dict(os.environ)
    env["HOTCRAY_LINUX_XKB"] = "yes" if xkb else ""
    try:
        p = subprocess.run([SIM, "-c", str(cfg), "-s", sim_file], capture_output=True,
                           text=True, encoding="utf-8", env=env, timeout=60)
    finally:
        os.unlink(sim_file)
    if "config file is valid" not in p.stdout + p.stderr:
        raise RuntimeError("simulator failed:\n" + p.stdout + p.stderr)
    events = []
    for line in (p.stdout + p.stderr).splitlines():
        m = re.match(r"^out:(.*)$", line)
        if m:
            events.append(m.group(1).strip())
        m = re.match(r"^outU:(.*)$", line)
        if m:
            events.append("U:" + m.group(1))
    return events


def strip_startup(events, platform, xkb):
    if platform == "win":
        start = ["↓F13", "↑F13"]
    elif xkb:
        start = ["↓CapsLock", "↑CapsLock"]
    else:
        start = ["↓LCtrl", "↑LCtrl"]
    if events[:len(start)] == start:
        events = events[len(start):]
    return events


def main():
    tmp = Path(tempfile.mkdtemp())
    configs = {"linux": ROOT / "hotcray.kbd", "win": windows_variant(ROOT / "hotcray.kbd", tmp)}
    failed = 0
    for name, platform, xkb, inp, exp in T:
        got = strip_startup(run(configs[platform], inp, xkb), platform, xkb)
        want = exp.split()
        ok = got == want
        failed += not ok
        print(("PASS " if ok else "FAIL ") + name)
        if not ok:
            print("     expected:", " ".join(want))
            print("     got:     ", " ".join(got))
    shutil.rmtree(tmp)
    print(f"\n{len(T) - failed}/{len(T)} passed")
    sys.exit(1 if failed else 0)


if __name__ == "__main__":
    main()
