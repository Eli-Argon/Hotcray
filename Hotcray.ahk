; ╔══════════════════════════════════════════════════════════════════════════╗
; ║  HOTCRAY — Windows companion (AutoHotkey v2)                             ║
; ║                                                                          ║
; ║  kanata (bin\kanata.exe + hotcray.kbd) does ALL the key remapping.       ║
; ║  This script is the part of Hotcray you see and click:                   ║
; ║    * starts kanata invisibly, restarts it if it ever dies (watchdog),    ║
; ║      stops it when you exit;                                             ║
; ║    * one tray icon: blue = Latin, red = Cyrillic, grey = paused;         ║
; ║    * per-application keys (` in Explorer / VS Code / browsers...);       ║
; ║    * keeps CapsLock and NumLock off, keeps Windows on the English (US)   ║
; ║      layout that kanata expects;                                         ║
; ║    * start with Windows, run as administrator (tray menu).               ║
; ║                                                                          ║
; ║  WHY THIS CANNOT BREAK YOUR TYPING (unlike the old Hotcray):             ║
; ║  This script installs NO keyboard hook. It only reacts to F13…F19,       ║
; ║  keys that no keyboard has and that kanata "presses" as signals. They    ║
; ║  are registered with RegisterHotKey, so if this script is busy or hangs, ║
; ║  the signals simply wait in a queue — your keys are never delayed and    ║
; ║  never fall through. (The old Hotcray evaluated `#If GetKeyState(...)`   ║
; ║  for every key press inside AutoHotkey's hook; whenever the script or    ║
; ║  the PC was busy, Windows timed the hook out and let the original key    ║
; ║  through, or removed the hook — that is the bug you saw.)                ║
; ╚══════════════════════════════════════════════════════════════════════════╝
;
; HOW TO RUN
;   * Portable: put AutoHotkey v2's AutoHotkey64.exe next to this file and
;     rename it to Hotcray.exe — double-clicking Hotcray.exe then runs
;     Hotcray.ahk automatically (get-binaries.ps1 does this for you).
;   * Or: double-click Hotcray.ahk if AutoHotkey v2 is installed.
;
; FILES (all relative to this script, so the folder can live on a USB stick)
;   bin\kanata.exe        kanata (winIOv2 console build; runs hidden)
;   hotcray.kbd           the layout (edit this to change keys)
;   Hotcray.ini           settings (created on first run; tray menu edits it)
;   icons\*.ico           tray icons
;   logs\                 kanata's config-check output

#Requires AutoHotkey v2.0
#SingleInstance Force
#Warn All, StdOut
Persistent
SetWorkingDir A_ScriptDir
; Sent keys (Ctrl+`, F12, ...) must not wait; they also never pass through
; kanata, because kanata ignores keys injected by other programs.
SendMode "Input"
SetTitleMatchMode 2

;@Ahk2Exe-SetName Hotcray
;@Ahk2Exe-SetDescription Hotcray keyboard layout (kanata companion)
;@Ahk2Exe-SetMainIcon icons\Hotcray.ico
;@Ahk2Exe-SetCompanyName Argon Systems
;@Ahk2Exe-SetCopyright Eli Argon
;@Ahk2Exe-SetVersion 2.0.0

global VERSION := "2.0.0"


; ════════════════════════════════════════════════════════════════════════════
;  SETTINGS  (Hotcray.ini — every value can also be changed in the tray menu)
; ════════════════════════════════════════════════════════════════════════════
global INI := A_ScriptDir "\Hotcray.ini"
global DEFAULTS := Map(
    "KanataExe",        "bin\kanata.exe",   ; or bin\kanata_wintercept.exe (see README)
    "Config",           "hotcray.kbd",
    "RunAsAdmin",       "0",   ; 1 = remapping also works in admin windows (Task Manager, regedit...)
    "EnforceUSLayout",  "1",   ; keep Windows on "English (US)", which hotcray.kbd assumes
    "ShowOSD",          "1",   ; small "EN"/"УК" pop-up when switching language
    "RestartOnUnlock",  "1",   ; restart kanata after sleep/lock (Windows can drop keyboard hooks there)
    "Terminal",         "auto" ; auto | wt | gitbash | pwsh | powershell | cmd | <full path to an exe>
)

Setting(key) {
    global INI, DEFAULTS
    try
        return IniRead(INI, "Hotcray", key)
    return DEFAULTS[key]
}
SetSetting(key, value) {
    global INI
    try IniWrite(value, INI, "Hotcray", key)
    catch
        TrayTip("Could not write " INI " (read-only drive?). The setting applies until exit.", "Hotcray", "Iconx")
}
AbsPath(p) => RegExMatch(p, "^[A-Za-z]:\\|^\\\\") ? p : A_ScriptDir "\" p

; Write default settings on first run so they are easy to find and edit.
if !FileExist(INI) {
    for k, v in DEFAULTS
        try IniWrite(v, INI, "Hotcray", k)
}

; Restart elevated if requested (a non-elevated kanata cannot type into
; elevated windows; Windows blocks that).
if Setting("RunAsAdmin") = "1" && !A_IsAdmin {
    try {
        Run('*RunAs "' A_AhkPath '" /restart "' A_ScriptFullPath '"')
        ExitApp
    }
    ; UAC refused: continue without admin rights.
}


; ════════════════════════════════════════════════════════════════════════════
;  PER-APPLICATION ACTIONS — edit freely
; ════════════════════════════════════════════════════════════════════════════
; kanata sends a signal for these physical keys; the functions decide what
; they do depending on the active window.

; ` (backtick, left of 1)
OnBacktick() {
    if WinActive("ahk_class CabinetWClass") || WinActive("ahk_class ExploreWClass")
        return ExplorerTerminalToggle(WinActive("A"))
    if IsTrackedTerminal(WinActive("A"))
        return TerminalBackToExplorer(WinActive("A"))
    if WinActive("ahk_exe Code.exe") || WinActive("ahk_exe VSCodium.exe") || WinActive("ahk_exe Cursor.exe")
        return Send("^``")                  ; VS Code: toggle its terminal
    if IsBrowser()
        return Send("{F12}")                ; developer tools
    SendText("``")                          ; everywhere else: a normal backtick
}

; NumLock key
OnNumLock() {
    if WinActive("ahk_exe firefox.exe") {
        Send("{F6}")                        ; focus address bar
        Sleep(200)
        Send("yt{Enter}")                   ; "yt" keyword: toggle YouTube controls
    }
}

; Numpad + (NumpadAdd)
OnNumpadAdd() {
    if WinActive("ahk_exe firefox.exe")
        return Send("c")                    ; YouTube: captions
    Send("{NumpadAdd}")
}

; Numpad 0 / Ins
OnNumpad0() {
    if WinActive("ahk_exe firefox.exe")
        return Send("f")                    ; YouTube: full screen
    Send("{Insert}")
}

IsBrowser() {
    for exe in ["firefox.exe", "chrome.exe", "msedge.exe", "brave.exe", "opera.exe", "vivaldi.exe", "librewolf.exe", "zen.exe"]
        if WinActive("ahk_exe " exe)
            return true
    return false
}


; ════════════════════════════════════════════════════════════════════════════
;  ` IN EXPLORER: terminal in the current folder, toggled
; ════════════════════════════════════════════════════════════════════════════
; First ` in an Explorer window: opens a terminal in that folder.
; ` again (in that terminal): minimises it and returns to the Explorer window.
; ` in the Explorer window again: brings the same terminal back.
; (To type a real backtick in the terminal: AltGr+' as always.)
global Terminals := Map()   ; terminal hwnd -> {explorer: hwnd, path: string}

ExplorerTerminalToggle(explorerHwnd) {
    global Terminals
    path := ExplorerPath(explorerHwnd)
    for term, info in Terminals.Clone() {
        if !WinExist("ahk_id " term) {
            Terminals.Delete(term)
            continue
        }
        if info.explorer = explorerHwnd && info.path = path {
            WinRestore("ahk_id " term)      ; no-op if it is not minimised
            WinActivate("ahk_id " term)
            return
        }
    }
    term := OpenTerminal(path)
    if term
        Terminals[term] := {explorer: explorerHwnd, path: path}
}

IsTrackedTerminal(hwnd) {
    global Terminals
    return hwnd && Terminals.Has(hwnd)
}

TerminalBackToExplorer(term) {
    global Terminals
    explorer := Terminals[term].explorer
    WinMinimize("ahk_id " term)
    if WinExist("ahk_id " explorer)
        WinActivate("ahk_id " explorer)
}

; Folder shown in an Explorer window; handles Windows 11 tabs.
; (Technique by Lexikos, AutoHotkey forum.)
ExplorerPath(hwnd) {
    activeTab := 0
    try activeTab := ControlGetHwnd("ShellTabWindowClass1", "ahk_id " hwnd)
    try {
        for w in ComObject("Shell.Application").Windows {
            if w.hwnd != hwnd
                continue
            if activeTab {
                static IID_IShellBrowser := "{000214E2-0000-0000-C000-000000000046}"
                shellBrowser := ComObjQuery(w, IID_IShellBrowser, IID_IShellBrowser)
                ComCall(3, shellBrowser, "uint*", &thisTab := 0)   ; IOleWindow::GetWindow
                if thisTab != activeTab
                    continue
            }
            p := w.Document.Folder.Self.Path
            if DirExist(p)          ; "This PC", "Quick access" etc. are not folders
                return p
        }
    }
    return EnvGet("USERPROFILE")
}

; Starts the configured terminal in `path`; returns its window (or 0).
OpenTerminal(path) {
    classes := ["CASCADIA_HOSTING_WINDOW_CLASS", "ConsoleWindowClass", "mintty"]
    before := Map()
    for cls in classes
        for h in WinGetList("ahk_class " cls)
            before[h] := true

    choice := Setting("Terminal")
    wt := EnvGet("LOCALAPPDATA") "\Microsoft\WindowsApps\wt.exe"
    gitbash := ""
    for p in [EnvGet("ProgramFiles") "\Git\git-bash.exe", EnvGet("LOCALAPPDATA") "\Programs\Git\git-bash.exe"]
        if FileExist(p) {
            gitbash := p
            break
        }
    if choice = "auto"
        choice := FileExist(wt) ? "wt" : gitbash ? "gitbash" : "powershell"
    ; wt treats a trailing \" as an escaped quote; "C:\" becomes "C:\."
    wtPath := SubStr(path, -1) = "\" ? path "." : path
    try {
        switch choice {
            case "wt":         Run('"' wt '" -w new -d "' wtPath '"')
            case "gitbash":    Run('"' gitbash '" --cd="' path '"')
            case "pwsh":       Run("pwsh.exe", path)
            case "powershell": Run("powershell.exe", path)
            case "cmd":        Run(A_ComSpec, path)
            default:           Run('"' choice '"', path)
        }
    } catch as e {
        TrayTip("Could not start the terminal (" choice "):`n" e.Message, "Hotcray", "Iconx")
        return 0
    }
    ; Wait up to 5 s for a new terminal window to appear.
    deadline := A_TickCount + 5000
    while A_TickCount < deadline {
        for cls in classes
            for h in WinGetList("ahk_class " cls)
                if !before.Has(h)
                    return h
        Sleep(100)
    }
    return 0
}


; ════════════════════════════════════════════════════════════════════════════
;  KANATA PROCESS: start, stop, check, watchdog
; ════════════════════════════════════════════════════════════════════════════
global KanataPid := 0
global WantRunning := false     ; false = the user paused Hotcray from the tray
global Crashes := []            ; tick counts of recent unexpected exits
global State := "stopped"       ; lat | cyr | off | stopped

KanataExe() => AbsPath(Setting("KanataExe"))
KanataCfg() => AbsPath(Setting("Config"))

LogDir() {
    d := A_ScriptDir "\logs"
    try {
        DirCreate(d)
        FileAppend("", d "\.write-test")
        FileDelete(d "\.write-test")
        return d
    }
    d := A_Temp "\Hotcray"
    DirCreate(d)
    return d
}

; Validates the config with `kanata --check`. Returns "" if fine, else the error.
CheckConfig() {
    exe := KanataExe(), cfg := KanataCfg()
    if !FileExist(exe)
        return "kanata not found: " exe "`nRun get-binaries.ps1, or see README."
    if !FileExist(cfg)
        return "Config not found: " cfg
    logFile := LogDir() "\kanata-check.log"
    try FileDelete(logFile)
    code := RunWait(A_ComSpec ' /c ""' exe '" --check --cfg "' cfg '" > "' logFile '" 2>&1"', A_ScriptDir, "Hide")
    if code = 0
        return ""
    out := ""
    try out := FileRead(logFile, "UTF-8")
    ; strip ANSI colour codes
    out := RegExReplace(out, "\x1B\[[0-9;]*m")
    return "hotcray.kbd has an error (details in " logFile "):`n`n" SubStr(out, -1500)
}

StartKanata() {
    global KanataPid, WantRunning, State
    WantRunning := true
    if KanataPid && ProcessExist(KanataPid)
        return true
    KillStrayKanatas()
    err := CheckConfig()
    if err {
        WantRunning := false
        SetState("stopped")
        MsgBox(err, "Hotcray — kanata not started", "Iconx")
        return false
    }
    try {
        ; Hidden console build: no window at all.
        ; --no-wait: exit immediately on error instead of "press enter".
        Run('"' KanataExe() '" --cfg "' KanataCfg() '" --no-wait --quiet', A_ScriptDir, "Hide", &pid)
    } catch as e {
        WantRunning := false
        SetState("stopped")
        MsgBox("Could not start kanata:`n" e.Message, "Hotcray", "Iconx")
        return false
    }
    KanataPid := pid
    SetState("lat")     ; kanata starts in the Latin layer (and signals F13 too)
    ResetLockKeys()
    return true
}

StopKanata() {
    global KanataPid, WantRunning
    WantRunning := false
    if KanataPid
        try ProcessClose(KanataPid)
    KanataPid := 0
    SetState("stopped")
    try SetScrollLockState("Off")
}

RestartKanata(*) {
    err := CheckConfig()
    if err {
        ; Keep the running (old, working) kanata.
        MsgBox(err "`n`nThe previous configuration stays active.", "Hotcray — config not reloaded", "Iconx")
        return
    }
    StopKanata()
    Sleep(300)
    StartKanata()
}

; Two kanata processes would remap every key twice. Close leftovers of ours
; (e.g. after this script was killed) and warn about foreign ones.
KillStrayKanatas() {
    ours := KanataExe()
    try {
        for p in ComObjGet("winmgmts:").ExecQuery("SELECT ProcessId, ExecutablePath FROM Win32_Process WHERE Name LIKE 'kanata%'") {
            if p.ExecutablePath = ours {
                try ProcessClose(p.ProcessId)
            } else
                TrayTip("Another kanata is running:`n" p.ExecutablePath "`nKeys may be remapped twice.", "Hotcray", "Icon!")
        }
    }
}

Watchdog() {
    global KanataPid, WantRunning, Crashes
    if !WantRunning || (KanataPid && ProcessExist(KanataPid))
        return
    ; kanata died although it should be running.
    now := A_TickCount
    Crashes.Push(now)
    while Crashes.Length && now - Crashes[1] > 60000
        Crashes.RemoveAt(1)
    if Crashes.Length >= 3 {
        WantRunning := false
        SetState("stopped")
        TrayTip("kanata stopped 3 times within a minute; not restarting.`nTray menu → Resume to try again.", "Hotcray", "Iconx")
        return
    }
    KanataPid := 0
    TrayTip("kanata stopped unexpectedly and was restarted.", "Hotcray", "Icon!")
    StartKanata()
}

; Windows may silently drop keyboard hooks while locked/asleep, and keys held
; during a lock can get stuck. A fresh kanata after unlock/resume avoids both.
OnSessionChange(wParam, *) {
    if wParam = 8 && Setting("RestartOnUnlock") = "1" && WantRunning   ; WTS_SESSION_UNLOCK
        SetTimer(RestartKanata, -1500)
}
OnPower(wParam, *) {
    if (wParam = 7 || wParam = 18) && Setting("RestartOnUnlock") = "1" && WantRunning   ; resume
        SetTimer(RestartKanata, -3000)
}


; ════════════════════════════════════════════════════════════════════════════
;  STATE, TRAY ICON, ON-SCREEN INDICATOR
; ════════════════════════════════════════════════════════════════════════════
SetState(s) {
    global State
    State := s
    icon := Map("lat", "Latin.ico", "cyr", "Cyrillic.ico", "off", "Off.ico", "stopped", "Off.ico")[s]
    tip := Map("lat", "Latin", "cyr", "Cyrillic", "off", "paused (ScrollLock)", "stopped", "stopped")[s]
    try TraySetIcon(A_ScriptDir "\icons\" icon)
    A_IconTip := "Hotcray — " tip
    UpdateMenu()
}

ShowOSD(text, color) {
    static g := 0, t := 0, hide := 0
    if Setting("ShowOSD") != "1"
        return
    if !g {
        ; Tool window, never activated, click-through, always on top.
        g := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x08000020")
        g.MarginX := 10, g.MarginY := 4
        g.SetFont("s14 bold cWhite", "Segoe UI")
        t := g.AddText("Center w48", "")
        hide := (*) => g.Hide()
    }
    g.BackColor := color
    t.Value := text
    ; Near the text cursor if the app reports it, else near the mouse.
    CoordMode("Caret", "Screen"), CoordMode("Mouse", "Screen")
    if !CaretGetPos(&x, &y)
        MouseGetPos(&x, &y)
    g.Show("x" (x + 12) " y" (y + 20) " NoActivate AutoSize")
    WinSetTransparent(220, g)
    SetTimer(hide, -700)     ; re-arming the same timer: a new pop-up gets its full 0.7 s
}

; Signals from kanata (see SIGNALS in hotcray.kbd)
SigLatin(*) {
    SetState("lat")
    ShowOSD("EN", "1F5FAF")
    EnsureUSLayout()
}
SigCyrillic(*) {
    SetState("cyr")
    ShowOSD("УК", "A01F1F")
    EnsureUSLayout()
}
SigPaused(*) {
    SetState("off")
    ShowOSD("OFF", "606060")
}

; Register F13…F19 with the modifier combinations kanata may send them with
; (e.g. Win+F14 during Win+Space). Explicit combinations keep these as
; RegisterHotKey hotkeys: no keyboard hook is ever installed.
RegisterSignals() {
    handlers := Map(
        "F13", SigLatin, "F14", SigCyrillic, "F15", SigPaused,
        "F16", (*) => OnBacktick(), "F17", (*) => OnNumLock(),
        "F18", (*) => OnNumpadAdd(), "F19", (*) => OnNumpad0())
    for key, fn in handlers
        for mods in ["", "+", "#", "+#", "^", "!", "^+", "!+"]
            Hotkey(mods key, fn)
}


; ════════════════════════════════════════════════════════════════════════════
;  LOCK KEYS AND KEYBOARD LAYOUT
; ════════════════════════════════════════════════════════════════════════════
; kanata never passes CapsLock/NumLock through, so they only need to be
; switched off once; the timer is a safety net. ScrollLock light: on = paused.
ResetLockKeys() {
    try SetCapsLockState("Off")
    try SetNumLockState("Off")
    try SetScrollLockState("Off")
}
LockKeysTimer() {
    global State
    if State = "lat" || State = "cyr" {
        if GetKeyState("CapsLock", "T")
            SetCapsLockState("Off")
        if GetKeyState("NumLock", "T")
            SetNumLockState("Off")
    }
}

; kanata sends key codes for Latin letters, which only mean "the right
; letters" with the English (US) layout. Hotcray has its own Latin/Cyrillic
; switch, so Windows should stay on English (US). Loads the layout for this
; session if it isn't installed (nothing is changed permanently).
EnsureUSLayout() {
    global State
    static hkl := DllCall("LoadKeyboardLayoutW", "Str", "00000409", "UInt", 0, "Ptr")
    if Setting("EnforceUSLayout") != "1" || !(State = "lat" || State = "cyr") || !hkl
        return
    hwnd := DllCall("GetForegroundWindow", "Ptr")
    if !hwnd
        return
    tid := DllCall("GetWindowThreadProcessId", "Ptr", hwnd, "Ptr", 0, "UInt")
    if DllCall("GetKeyboardLayout", "UInt", tid, "Ptr") != hkl
        try PostMessage(0x50, 0, hkl, , "ahk_id " hwnd)   ; WM_INPUTLANGCHANGEREQUEST
}


; ════════════════════════════════════════════════════════════════════════════
;  START WITH WINDOWS
; ════════════════════════════════════════════════════════════════════════════
; Normal: a shortcut in the Startup folder. As administrator: a scheduled
; task (a Startup shortcut would show a UAC prompt at every log-on).
StartupLink() => A_Startup "\Hotcray.lnk"
LaunchTarget() => A_IsCompiled ? A_ScriptFullPath : A_AhkPath
LaunchArgs() => A_IsCompiled ? "" : '"' A_ScriptFullPath '"'

global AutostartCache := ""
AutostartEnabled(refresh := false) {
    global AutostartCache
    if refresh || AutostartCache = ""
        AutostartCache := FileExist(StartupLink()) || TaskExists()
    return AutostartCache
}
TaskExists() => RunWait('schtasks.exe /Query /TN "Hotcray"', , "Hide") = 0
ToggleAutostart(*) {
    if AutostartEnabled(true) {
        try FileDelete(StartupLink())
        if TaskExists()
            Schtasks('/Delete /TN "Hotcray" /F')
    } else if Setting("RunAsAdmin") = "1" {
        Schtasks('/Create /TN "Hotcray" /SC ONLOGON /RL HIGHEST /F /TR "\"' LaunchTarget() '\" ' StrReplace(LaunchArgs(), '"', '\"') '"')
    } else {
        FileCreateShortcut(LaunchTarget(), StartupLink(), A_ScriptDir, LaunchArgs(), "Hotcray keyboard layout", A_ScriptDir "\icons\Hotcray.ico")
    }
    AutostartEnabled(true)
    UpdateMenu()
}
; Creating/deleting a "highest privileges" task needs admin rights (UAC prompt).
Schtasks(args) {
    try RunWait((A_IsAdmin ? "" : "*RunAs ") "schtasks.exe " args, , "Hide")
}


; ════════════════════════════════════════════════════════════════════════════
;  TRAY MENU
; ════════════════════════════════════════════════════════════════════════════
ToggleSetting(key) {
    SetSetting(key, Setting(key) = "1" ? "0" : "1")
    UpdateMenu()
}
TogglePause(*) {
    global WantRunning
    if WantRunning && State != "off"
        StopKanata()
    else {
        ; Also resumes from ScrollLock-pause: a fresh kanata starts active.
        StopKanata()
        StartKanata()
    }
}
OpenFile(path) {
    try Run('"' path '"')
    catch
        Run('notepad.exe "' path '"')
}
ExitHotcray(*) => ExitApp()

BuildMenu() {
    m := A_TrayMenu
    m.Delete()
    m.Add("Hotcray " VERSION, (*) => 0)
    m.Disable("Hotcray " VERSION)
    m.Add()
    m.Add("Pause", TogglePause)
    m.Add("Reload config", RestartKanata)
    m.Add("Edit config", (*) => OpenFile(KanataCfg()))
    m.Add("Key map (cheat sheet)", (*) => OpenFile(A_ScriptDir "\docs\LAYOUT.md"))
    m.Add("Open logs folder", (*) => Run('"' LogDir() '"'))
    m.Add()
    m.Add("Start with Windows", ToggleAutostart)
    m.Add("Run as administrator", ToggleAdmin)
    m.Add("Keep Windows on English (US)", (*) => ToggleSetting("EnforceUSLayout"))
    m.Add("Language pop-up", (*) => ToggleSetting("ShowOSD"))
    m.Add("Restart kanata after sleep/lock", (*) => ToggleSetting("RestartOnUnlock"))
    m.Add()
    m.Add("Exit", ExitHotcray)
    m.Default := "Pause"      ; double-click the icon = pause/resume
    m.ClickCount := 2
}
ToggleAdmin(*) {
    ToggleSetting("RunAsAdmin")
    ; Autostart must switch between Startup shortcut and scheduled task.
    if AutostartEnabled(true) {
        ToggleAutostart()
        ToggleAutostart()
    }
    if MsgBox("Restart Hotcray now to apply?", "Hotcray", "YesNo Icon?") = "Yes"
        Reload()
}
UpdateMenu() {
    global State
    m := A_TrayMenu
    try {
        paused := State = "off" || State = "stopped"
        paused ? m.Check("Pause") : m.Uncheck("Pause")
        AutostartEnabled() ? m.Check("Start with Windows") : m.Uncheck("Start with Windows")
        for item, key in Map("Run as administrator", "RunAsAdmin", "Keep Windows on English (US)", "EnforceUSLayout",
                             "Language pop-up", "ShowOSD", "Restart kanata after sleep/lock", "RestartOnUnlock")
            Setting(key) = "1" ? m.Check(item) : m.Uncheck(item)
    }
}


; ════════════════════════════════════════════════════════════════════════════
;  MAIN
; ════════════════════════════════════════════════════════════════════════════
OnExitHandler(*) {
    StopKanata()
}

BuildMenu()
SetState("stopped")
RegisterSignals()
OnExit(OnExitHandler)
OnMessage(0x02B1, OnSessionChange)      ; WM_WTSSESSION_CHANGE
DllCall("Wtsapi32\WTSRegisterSessionNotification", "Ptr", A_ScriptHwnd, "UInt", 0)
OnMessage(0x0218, OnPower)              ; WM_POWERBROADCAST
StartKanata()
SetTimer(Watchdog, 2000)
SetTimer(LockKeysTimer, 1000)
SetTimer(EnsureUSLayout, 500)
