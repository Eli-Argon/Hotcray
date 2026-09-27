# Hotcray key map (cheat sheet)

Keys are named by where they are on a US keyboard. The layout itself is
defined in [`hotcray.kbd`](../hotcray.kbd); this page only describes it.

**Rule that applies everywhere:** with **Ctrl**, **Win** or **Left Alt**
held, the letter keys act as plain US‑QWERTY keys, in Latin *and* in
Cyrillic mode. So Ctrl + the key labelled C is always Copy.

| Switch | Keys |
|---|---|
| Latin ⇄ Cyrillic | **Win + Space** |
| Pause / resume Hotcray (normal keyboard for someone else) | **ScrollLock**, or **Right Shift + Esc** |
| Emergency exit of kanata (works even with a broken config) | hold **Left Ctrl + Space + Esc** |

Tray icon: **blue H** = Latin, **red H** = Cyrillic, **grey H** = paused or stopped.
A short **EN / УК / OFF** pop-up appears when you switch. You can turn it off in the tray menu.
The **Scroll Lock light** is on while Hotcray is paused.

---

## Latin

```
 ┌───┬───┬───┬───┬───┬───┬───┬───┬───┬───┬───┬───┬───┐
 │ ` │ 1 │ 2 │ 3 │ 4 │ 5 │ 6 │ 7 │ 8 │ 9 │ 0 │ ✔ │ ✖ │
 ├───┼───┼───┼───┼───┼───┼───┼───┼───┼───┼───┼───┼───┼─────┐
 │   │ q │ w │ f │ p │ g │ j │ l │ u │ y │ / │ « │ » │Alt+D│
 │   │   │   │   │   │   │   │   │   │   │ \ │ • │ ◦ │     │  ← Shift
 ├───┴┬──┴┬──┴┬──┴┬──┴┬──┴┬──┴┬──┴┬──┴┬──┴┬──┴┬──┴┬──┴─────┘
 │Bksp│ a │ r │ s │ t │ d │ h │ n │ e │ i │ o │ # │
 │    │   │   │   │   │   │   │   │   │   │   │ * │             ← Shift
 ├────┴┬──┴┬──┴┬──┴┬──┴┬──┴┬──┴┬──┴┬──┴┬──┴┬──┴┬──┘
 │     │ z │ x │ c │ v │ b │ k │ m │ , │ . │ _ │
 │     │   │   │   │   │   │   │   │ ? │ ! │ | │                 ← Shift
 └─────┴───┴───┴───┴───┴───┴───┴───┴───┴───┴───┘
```
* **CapsLock** is Backspace. Real CapsLock and NumLock are always off.
* **`** does something different per program (see below). **Shift + `** = №.
* **\\** = Alt+D (focus the address bar in Explorer and browsers).
* **Left Ctrl + D** = Ctrl+H (find and replace). **Left Ctrl + Q / W / E** =
  Alt+C / Alt+W / Alt+R (VS Code: match case / whole word / regex).

## Cyrillic (Ukrainian first)

```
 ┌───┬───┬───┬───┬───┬───┬───┬───┬───┬───┬───┬───┬───┐
 │ ` │ 1 │ 2 │ 3 │ 4 │ 5 │ 6 │ 7 │ 8 │ 9 │ 0 │ ґ │ ✖ │
 │   │ ы │ Ы │ э │ Э │ ъ │ Ъ │ ё │ Ё │ ( │ ) │ Ґ │   │  ← Shift (Russian-only letters)
 ├───┼───┼───┼───┼───┼───┼───┼───┼───┼───┼───┼───┼───┼───┐
 │   │ ц │ ь │ я │ є │ ф │ з │ в │ к │ д │ ч │ ш │ щ │ й │
 ├───┴┬──┴┬──┴┬──┴┬──┴┬──┴┬──┴┬──┴┬──┴┬──┴┬──┴┬──┴┬──┴───┘
 │Bksp│ у │ и │ е │ о │ а │ л │ н │ т │ с │ р │ ї │
 ├────┴┬──┴┬──┴┬──┴┬──┴┬──┴┬──┴┬──┴┬──┴┬──┴┬──┴┬──┘
 │     │ . │ , │ х │ і │ ю │ б │ м │ п │ г │ ж │
 │     │ ! │ ? │   │   │   │   │   │   │   │   │                ← Shift
 └─────┴───┴───┴───┴───┴───┴───┴───┴───┴───┴───┘
```
Every letter has its own key. You no longer press a key twice to get the second letter.

| Changed from the old Hotcray | Now |
|---|---|
| ы/і on V (press twice) | **і** on V; **ы** on Shift+1 |
| э/є on R | **є** on R; **э** on Shift+3 |
| и/й on S | **и** on S; **й** on **\\** |
| ї/ґ on ' | **ї** on '; **ґ** on **-** |
| ъ on Shift+W | **Ь** on Shift+W; **ъ** on Shift+5 |
| ё (did not exist) | Shift+7 |
| ч/`/`, ш/«, щ/» | ч, ш, щ only; / « » are on AltGr+Shift+6 / [ / ] |
| Shift+1…8 = ! @ # $ % ^ & * | Russian letters. ! and ? are on Shift+Z/X; the rest are on AltGr (below) |

The apostrophe for Ukrainian (м'ясо) is **AltGr + ;**.

## AltGr (Right Alt) — symbols, same in Latin and Cyrillic

```
 ┌─────┬─────┬─────┬─────┬─────┬─────┬─────┬─────┬─────┬─────┬─────┬─────┬─────┐
 │  ∞  │ ¹   │ ²   │ ³   │ √   │ ·   │ ×   │ ÷   │ +   │ −   │ ±   │ ≈   │ ≠   │
 │     │ k1  │ k2  │ k3  │ k4  │ k5  │ /   │ \   │ #   │ *   │     │     │     │ ← Shift
 ├─────┼─────┼─────┼─────┼─────┼─────┼─────┼─────┼─────┼─────┼─────┼─────┼─────┤
 │     │ 9   │ 8   │ 7   │ 6   │ 5   │ þ   │ ð   │ (   │ )   │ %   │ ≥   │ ≤   │
 │     │ ˚   │ ˛   │ ˇ   │ ˆ   │ ˝   │ Þ   │ Ð   │ [   │ ]   │ °   │ «   │ »   │ ← Shift
 ├─────┼─────┼─────┼─────┼─────┼─────┼─────┼─────┼─────┼─────┼─────┼─────┼─────┘
 │Bksp │ 0   │ 1   │ 2   │ 3   │ 4   │ ‑   │ +   │ =   │ "   │ '   │ `   │
 │     │ `   │ ´   │ ˜   │ ¨   │ ß   │ ¸   │ <   │ >   │ {   │ }   │ ¯   │       ← Shift
 ├─────┼─────┼─────┼─────┼─────┼─────┼─────┼─────┼─────┼─────┼─────┼─────┘
 │     │ æ   │ œ   │ ©   │ ™   │ –   │ —   │ -   │ ;   │ :   │ &   │
 │     │ Æ   │ Œ   │ ₴   │ €   │ £   │ ₽   │ ^   │ $   │ @   │ ~   │             ← Shift
 └─────┴─────┴─────┴─────┴─────┴─────┴─────┴─────┴─────┴─────┴─────┘
```
* **Accents** (marked ˚ ˛ ˇ ˆ ˝ ` ´ ˜ ¨ ¸ ¯) are typed **after** the letter:
  `e` then **AltGr+Shift+S** gives **é**. Hotcray now replaces the letter with
  the single real character (é, not e + an invisible accent), so search boxes
  and file names work. If no such character exists, or the letter was typed
  more than 3 s earlier, or you are in Cyrillic mode, you get the old
  invisible accent.
* **k1…k5** (AltGr+Shift+1…5) are the kaomoji: ಠ_ಠ  ¯\\\_(ツ)\_/¯  ¯\\(☯෴☯)/¯  (☞ ಠ_ಠ)☞  ᕦ(ಠ_ಠ)ᕤ
* **‑** (AltGr+H) is a non-breaking hyphen.
* **AltGr + F4, Tab, Enter, Esc, arrows, Home/End, PgUp/PgDn, Backspace, Delete**
  = Alt + that key. **AltGr + Tab** works like holding Alt and tapping Tab.
* **AltGr + Space** = Space.

## Left Alt — navigation

Tap **Left Alt** alone = **Esc**. Hold it:

```
 ┌───────┬───────┬───────┬───────┬───────┬───────┬───────┬───────┬───────┬───────┐
 │Reopen │       │ PgUp  │       │       │GoFile │GoLine │   ↑   │ Menu  │AddrBar│
 │ tab   │       │       │       │       │Ctrl+P │Ctrl+G │       │Sh+F10 │ Alt+D │
 ├───────┼───────┼───────┼───────┼───────┼───────┼───────┼───────┼───────┼───────┤
 │       │ Home  │ PgDn  │  End  │ Fold  │Unfold │   ←   │   ↓   │   →   │ Shift │
 │       │       │       │       │ all   │ all   │       │       │       │(hold) │
 ├───────┼───────┼───────┼───────┼───────┼───────┼───────┼───────┼───────┼───────┘
 │ Undo  │       │       │       │Comment│       │Delete │Cursor↓│Cursor↑│
 │Sh:Redo│       │       │       │Ctrl+/ │       │       │C+A+↓  │C+A+↑  │
 └───────┴───────┴───────┴───────┴───────┴───────┴───────┴───────┴───────┘
```
* Any other key = **Ctrl + that key**. Left Alt + C / V / X / A / S / T / W / Tab / 1…9
  work as Ctrl + C / V / X / A / S / T / W / Tab / 1…9.
* Combine: **+ Shift** or **+ ; held** selects; **+ Left Ctrl** moves by word;
  **+ Right Alt**: J/L = Alt+←/→ (back/forward), I/K = Alt+↑/↓,
  S/F = previous/next tab, E/D = move tab left/right.

## Win key

Works as usual (Win+E, Win+D, Win+L… use QWERTY positions), except:
**Win+Space** = Latin ⇄ Cyrillic, **Win+Tab** = Alt+Tab (keep Win held and tap Tab),
**Win+`** = Task View (the old Win+Tab).

## Numpad (independent of NumLock)

| 7 Volume + | 8 ↑ | 9 PgUp |
|---|---|---|
| **4 ←** | **5 Space** | **6 →** |
| **1 Volume −** | **2 ↓** | **3 PgDn** |
| **0** Insert (Firefox: f) | **.** Delete | **+** (Firefox: c) |

NumLock: in Firefox it runs the "yt" keyword (F6, yt, Enter). / * - Enter are unchanged.

## Per-program keys

| Key | Explorer | Terminal opened by ` | VS Code | Browsers | Elsewhere |
|---|---|---|---|---|---|
| ` | Opens a terminal in this folder, or brings it back | Minimise and go back to Explorer | Toggle terminal (Ctrl+`) | Dev tools (F12) | ` |

Terminal choice: tray → Edit `Hotcray.ini` → `Terminal=auto|wt|gitbash|pwsh|powershell|cmd|C:\path\to.exe`
(auto = Windows Terminal, else Git Bash, else PowerShell).
On Linux, ` does: VS Code → terminal, browsers → dev tools, Dolphin → terminal panel, else `.
