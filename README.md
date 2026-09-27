# Hotcray 2

A personal keyboard layout for **Windows and Linux**: Colemak-style Latin,
Ukrainian-first Cyrillic, a symbols layer on AltGr and a navigation layer on
Left Alt. It is portable (runs from a USB stick without installing anything)
and you can switch it off with one key.

Hotcray 1 was an AutoHotkey script. Hotcray 2 uses
**[kanata](https://github.com/jtroo/kanata)**, a dedicated keyboard remapper,
for all key handling. A small companion program adds the tray icon and the
per-program shortcuts.

* **Key map:** [docs/LAYOUT.md](docs/LAYOUT.md)
* **New to kanata?** [docs/KANATA-PRIMER.md](docs/KANATA-PRIMER.md)
* **The layout itself:** [hotcray.kbd](hotcray.kbd) (heavily commented)

---

## Quick start

### Windows
1. Download **Hotcray-portable.zip** from
   [Releases](../../releases) and unzip it anywhere (e.g. a USB stick).
   *Or* clone this repository and run
   `powershell -ExecutionPolicy Bypass -File .\get-binaries.ps1`, which downloads
   kanata and AutoHotkey v2 (checksum-verified) into the folder.
2. Double-click **Hotcray.exe**. A blue **H** appears in the tray. That's it.
3. Optional (tray menu): **Start with Windows**, **Run as administrator**
   (needed if you want the layout inside admin windows such as Task Manager).
4. **If you used Hotcray 1** on this PC: quit it, switch Windows to plain
   *English (US)* (the old `hotcray5` layout is no longer needed), and run
   `legacy\Remove old scancode map.reg` (then restart). kanata now does the
   CapsLock/numpad remaps itself and must see the real keys.

### Linux
1. Unzip the release (or clone + `./get-binaries.sh`).
2. Run `linux/hotcray.sh`.
   * On your own PC, run `linux/hotcray.sh --setup-permissions` once (then log
     out/in), so kanata doesn't need sudo. Then
     `linux/hotcray.sh --autostart on` starts it at log-in.
   * On someone else's PC it asks for sudo once per session instead.
3. `linux/hotcray.sh --stop` stops it.

### Daily use
| | |
|---|---|
| Latin ⇄ Cyrillic | **Win + Space** |
| Pause for someone else (keyboard 100 % normal) | **ScrollLock**, or **Right Shift + Esc** if there is no ScrollLock. The Scroll Lock light is on while paused. |
| Stop / pause from the mouse | tray icon → Pause (double-click the icon toggles) |
| Emergency: kill kanata | hold **Left Ctrl + Space + Esc** |

Tray icon: **blue** = Latin, **red** = Cyrillic, **grey** = paused/stopped,
plus a short EN / УК / OFF pop-up near the cursor (can be turned off).
On Linux with GNOME/KDE, the panel's own layout indicator also shows EN/UK.

---

## How it fits together

```
 keyboard ─► kanata (hotcray.kbd) ─► every program
                 │  F13…F19 (Windows) / TCP messages (Linux)
                 ▼
          companion: Hotcray.ahk (Windows) / linux/hotcray-companion.py
          tray icon · per-program keys · starts/restarts kanata
```

| File | What it is |
|---|---|
| `hotcray.kbd` | The layout. Edit this. |
| `hotcray-diacritics.kbd` | Generated accent rules (`tools/gen_diacritics.py`) |
| `Hotcray.ahk` | Windows companion (AutoHotkey v2). `Hotcray.exe` = AutoHotkey64.exe renamed, which runs `Hotcray.ahk` automatically |
| `Hotcray.ini` | Windows settings, created on first start (all in the tray menu) |
| `linux/` | Linux start script + companion |
| `bin/` | kanata for Windows and Linux (downloaded, not in git) |
| `tests/sim_tests.py` | 52 automated tests of the layout in kanata's simulator (run by GitHub on every push) |
| `legacy/` | Hotcray 1, kept for reference |

Publishing a release: push a tag, e.g. `git tag v2.0.0 && git push --tags`.
GitHub Actions tests everything and attaches `Hotcray-portable.zip`
(Windows + Linux, ready to use) to the release.

---

## Reliability: why Hotcray 1 dropped keys, and what changed

**The cause in Hotcray 1.** It used AutoHotkey's keyboard hook with
`#If GetKeyState(...)` / `#If isLatin` conditions. For *every* key press,
the hook had to wait for the script's main thread to evaluate those
conditions. Whenever that thread was busy (the Explorer hotkey's COM calls,
`Sleep 200`, a busy PC), Windows' hook timeout expired. Windows then passed the
original key through, and after repeated timeouts it silently removed the hook.
That is exactly "keys fall through, the script hangs and has to be restarted".

**Hotcray 2:**
* kanata's hook only puts the key in a queue and returns at once. It never
  waits for any logic, so a busy PC delays keys but does not leak them.
* The companion installs **no keyboard hook at all**. It only listens for
  F13–F19 via `RegisterHotKey`, so a slow companion can never affect typing.
* The companion is a **watchdog**: if kanata dies it is restarted (and it gives
  up with a message after 3 crashes a minute, e.g. a broken config). It also
  restarts kanata after unlock/resume from sleep, where Windows is known to
  drop hooks. It closes a leftover second kanata so keys are never remapped
  twice.
* Configs are checked before every (re)start; a bad edit keeps the old layout.

**Maximum reliability (your own Windows PC): the Interception driver.**
The default build uses a Windows keyboard hook, which is portable (no
install) but ultimately still a hook. The Interception driver works below
Windows' input system, so keys cannot fall through at all:
1. Download *Interception* (github.com/oblitum/Interception, releases),
   run `command line installer\install-interception.exe /install` as
   administrator, reboot.
2. Copy `Interception\library\x64\interception.dll` into `bin\`.
3. In `Hotcray.ini` set `KanataExe=bin\kanata_wintercept.exe`, restart Hotcray.

Known driver issue: after very many plug/unplug or sleep cycles the keyboard
can stop responding until reboot. Don't use it on other people's PCs.

**What is still possible:** during a kanata restart (reload, unlock, crash)
there are well under a second of unremapped keys. Admin windows need *Run as
administrator* (Windows forbids normal programs to type into them). On Linux,
kanata grabs the keyboard device exclusively, so nothing can fall through
there.

---

## Answers to specific questions

**Left Alt + I/J/K/L arrows didn't work in dict.cc's suggestion list, why?**
Hotcray 1 made Left Alt a held *Ctrl*. For each arrow, AutoHotkey released
Ctrl, pressed the arrow and pressed Ctrl again, so the web page received
extra "Control up/down" key events. Suggestion lists like dict.cc's treat any
non-arrow key as "the user is typing" and rebuild the list, which throws
away the highlighted row. (I could not open dict.cc from my build
environment to confirm, but this is the only difference between your arrows
and real ones.) In Hotcray 2, Left Alt is a layer key, not Ctrl, so an arrow is
just an arrow. The simulator test "LAlt+j is a plain Left arrow (no Ctrl
events!)" guards this.

**Accents: real characters instead of combining marks?** Yes, typed the same way.
`e` then AltGr+Shift+S now deletes the `e` and types `é` (U+00E9). This
covers all 200 letter+accent pairs that exist as single characters. The invisible
combining accent is only used where no such character exists (e.g. q̃), after
a space, in Cyrillic mode, or if the letter is more than 3 s old. The age
limit is a safety measure: kanata can't see mouse clicks, and a Backspace in
another field must not delete something.

**Russian letters:** ы Ы э Э ъ Ъ ё Ё are on **Shift + 1…8** in Cyrillic mode.
Every Ukrainian letter has its own key; there are no double-tap toggles anymore.
Still two layouts only (Win+Space). See [LAYOUT.md](docs/LAYOUT.md#cyrillic-ukrainian-first).

**Per-program hotkeys** (kanata can't do these alone): ` in Explorer opens
(or brings back) a terminal in the current folder, including Windows 11
tabs. ` in that terminal returns to Explorer. In VS Code it toggles VS Code's terminal,
in browsers it opens dev tools, and elsewhere it types `. Edit `OnBacktick()` in
`Hotcray.ahk` to change this; the terminal is set by `Terminal=` in
`Hotcray.ini`.

**macOS:** not included. kanata on macOS needs the Karabiner virtual keyboard
driver installed (not portable, needs admin approval). Typing Cyrillic there
needs extra OS layouts, and Ctrl/Cmd work differently. That is not "very simple
and 100 % safe", as you required.

---

## Things that are different or worse than Hotcray 1

You asked to be told. Most were unavoidable trade-offs or follow from your
requests:

1. **Left Alt is no longer a real Ctrl for the mouse.** Left Alt + letters,
   Tab, numbers, arrows… still send Ctrl + that key. But Left Alt + click,
   Left Alt + mouse wheel (zoom) and Left Alt + drag no longer act as Ctrl.
   Making Left Alt a real Ctrl again would bring back the dict.cc problem. Use
   the real Ctrl for those.
2. **Tap Left Alt → Esc** only if released within 1 s (it was any length).
3. **Holding a Cyrillic letter doesn't auto-repeat** (kanata types unicode
   characters once). Latin letters, digits and symbols repeat as usual.
4. **Cyrillic Shift + 1…8** no longer type ! @ # $ % ^ & * (Russian letters are
   there now). ! and ? are Shift+Z/X; the rest are on AltGr.
5. **Shift+W in Cyrillic is Ь**, ъ moved to Shift+5. / « » in Cyrillic mode moved to
   AltGr+Shift+6 / [ / ].
6. **` in a terminal opened from Explorer minimises it** and returns to Explorer.
   Hotcray 1 closed Git Bash; closing loses the shell's state. Type a
   real backtick there with AltGr+'.
7. **Windows must stay on English (US).** kanata types Latin letters as key
   codes, not characters. The companion enforces this (and loads the US layout
   for the session on foreign PCs). You can turn that off in the tray.
8. **Numpad digits are gone completely** (you asked for this): the numpad is
   arrows/navigation whatever the NumLock state.
9. **Linux limitations:**
   * Cyrillic uses the OS layouts English + Ukrainian, which the script
     configures automatically on GNOME, KDE and X11 (and restores on exit).
     Elsewhere (e.g. sway) Cyrillic falls back to unicode typing, which only
     works in apps that support IBus (Ctrl+Shift+U).
   * Rare symbols (« ✔ • ∞ ₴ …) are always typed as unicode on Linux, with
     the same IBus limitation.
   * Per-program keys need to know the active window. That works on X11, sway,
     Hyprland and KDE (with `kdotool`), but not on GNOME Wayland, where ` just
     types `.
   * No "open terminal in the current folder" on Linux (Dolphin: F4 panel).
   * While paused (ScrollLock) with Hotcray's layouts active, the physical
     CapsLock key selects the English layout instead of locking capitals.
10. **Admin windows** need *Run as administrator* in the tray (same as Hotcray 1).

---

## Troubleshooting

* **Nothing happens / keys unchanged:** is the icon grey? Press ScrollLock or
  double-click the icon. Tray → *Open logs folder* → `kanata-check.log`.
* **Wrong letters in Latin mode:** Windows isn't on English (US). Tray →
  *Keep Windows on English (US)* must be checked.
* **Keys dead in one program:** it's probably elevated (admin). Tray → *Run as
  administrator*.
* **A key gets stuck:** tap it again; still stuck → tray → *Reload config*.
* **Linux: `sudo: a password is required`** when autostarted: run
  `linux/hotcray.sh --setup-permissions` once and log out/in.

## License

See [LICENSE](LICENSE). kanata (LGPL-3.0) and AutoHotkey (GPL-2.0) are
downloaded separately and keep their own licenses.
