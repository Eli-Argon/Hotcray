# kanata primer: what you need to know, most important first

kanata is a program that sits between your keyboard and every other program.
It reads each physical key press and decides what the rest of the computer
receives. Hotcray's whole layout lives in one text file, `hotcray.kbd`.
Official guide: <https://github.com/jtroo/kanata/blob/main/docs/config.adoc>
(Hotcray uses kanata **v1.11.0**; use the guide for that version).

---

## Tier 1: know this before you use it

1. **Emergency exit:** hold **Left Ctrl + Space + Esc**. kanata quits
   immediately and the keyboard is 100 % normal again. This check runs on the
   raw keys, so it works even when the config is broken.
2. **Pause:** **ScrollLock** (or **Right Shift + Esc**) makes every key normal
   until you press it again. The tray menu's *Pause* stops kanata completely.
3. **One file:** everything is in `hotcray.kbd`. Hotcray.ahk / the Linux
   companion only handle the tray icon, starting kanata and the per-program keys.
4. **A broken config cannot lock you out.** Hotcray runs `kanata --check`
   before it starts or reloads kanata. If the file has an error, you get the
   error message and the previous layout keeps running.
5. **Layers** are like transparent sheets over the keyboard. The base layer
   is either `lat` (Latin) or `cyr` (Cyrillic). While you hold Right Alt, Left
   Alt or Win, a sheet (`sym`, `nav`, `win`) sits on top of it. A key the top
   sheet does not define falls through to the sheet below (`_` = transparent).
6. **kanata ignores keys that other programs type**, so Hotcray.ahk,
   AutoHotkey scripts, password managers and on-screen keyboards are never
   remapped.

## Tier 2: editing the layout

* **Workflow:** edit `hotcray.kbd`, save, then tray → *Reload config*. For a
  quick syntax check:
  `bin\kanata.exe --check -c hotcray.kbd` (Linux: `bin/kanata --check -c hotcray.kbd`).
* **Comments** start with `;;`. Block comments: `#| ... |#`.
* **Key names** are US‑QWERTY positions: `a`, `1`, `grv` (`), `min` (-), `eql` (=),
  `lbrc` `rbrc` ([ ]), `bksl` (\\), `scln` (;), `apos` ('), `comm` (,), `.`, `/`,
  `lsft` `rsft` `lctl` `rctl` `lalt` `ralt` `lmet` (Win), `caps`, `bspc`, `ret`,
  `spc`, `tab`, `esc`, `kp0`…`kp9`, `f1`…`f24`, `volu` `vold`.
* **Change one key:** find its layer (`deflayermap (lat)` etc.) and change the
  pair `key  action`, e.g. `caps bspc` → `caps esc`.
* **Actions you will use most:**
  | Action | Meaning |
  |---|---|
  | `a` | type the key `a` |
  | `S-a` `C-c` `A-f4` `M-e` `RA-s` | with Shift / Ctrl / Alt / Win / AltGr (combine: `C-S-t`) |
  | `(unicode ж)` | type exactly this character |
  | `(macro C-k C-lbrc)` | tap keys one after another (numbers are delays in ms) |
  | `XX` | do nothing |
  | `_` | transparent (use the layer below) |
  | `@name` | use an alias (defined in `(defalias name action ...)`) |
  | `(layer-while-held nav)` | layer on while the key is held |
  | `(layer-switch cyr)` | change the base layer |
  | `(tap-hold-press 0 1000 esc (layer-while-held nav))` | tap = Esc, hold = layer |
  | `(fork a b (lsft rsft))` | `b` if a Shift is held, else `a` |
* **Templates** (`deftemplate` / `t!`) are fill-in-the-blanks snippets.
  `(t! cy я Я e z)` = "Cyrillic key: я, Я with Shift, QWERTY `e` for
  shortcuts, `z` on the Ukrainian OS layout". Read the template's
  comment in `hotcray.kbd` to see what each argument means.
* **Accents:** don't edit `hotcray-diacritics.kbd`. Change
  `tools/gen_diacritics.py` and run it.

## Tier 3: good to understand

* **Windows builds of kanata:** Hotcray uses the *tty winIOv2* build started
  invisibly. The *wintercept* build uses the **Interception driver** (see
  README → Maximum reliability). *gui* builds have their own tray icon (not
  used; Hotcray has one icon).
* **How the parts talk:** kanata can't see which window is active. For
  per-program keys it presses F13–F19 (Windows), which Hotcray.ahk catches, or
  sends a TCP message (Linux). Look for `app-grv` and `sig-lat` in the config.
* **`(platform (win ...) ...)` and `(environment (VAR value) ...)`** make parts of
  the file apply only on Windows / Linux, or only when a variable is set. Each
  such block wraps exactly one item.
* **`switch`** is kanata's "if": `(switch (lctl rctl) X break () Y break)` =
  "X if a Ctrl is active, otherwise Y". It can also check the layer
  (`(base-layer cyr)`) and the recently typed keys (`key-history`), which is how
  accents are merged into letters.
* **Tests:** `tests/sim_tests.py` presses fake keys in kanata's simulator and
  compares the output. GitHub runs these tests after every push. Add a line
  there when you change something important.
* **Linux:** kanata needs access to `/dev/input` and `/dev/uinput`
  (`linux/hotcray.sh --setup-permissions` once, or sudo each time).
* **Live reload resets to the first layer** (Latin).

## Tier 4: exists, not used by Hotcray (yet)

Chords (several keys pressed together → one action), sequences (leader key +
typed word), home-row modifiers (tap-hold on letters), mouse keys, caps-word,
dynamic macros (record/replay), `defoverrides`, zippychord (chorded text
expansion). All are in the official guide.
