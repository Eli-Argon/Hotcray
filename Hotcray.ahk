#NoEnv
#Warn
#SingleInstance Force
#UseHook
#MenuMaskKey VKFF
SetWorkingDir %A_ScriptDir%
SendMode Input
StringCaseSense On
AutoTrim Off
SetCapsLockState AlwaysOff
SetNumLockState AlwaysOff
;@Ahk2Exe-SetName Hotcray
;@Ahk2Exe-SetDescription AHK hotkeys
;@Ahk2Exe-SetMainIcon Hotcray.ico
;@Ahk2Exe-SetCompanyName Argon Systems
;@Ahk2Exe-SetCopyright Eli Argon
;@Ahk2Exe-SetVersion 1.5.1

;@Ahk2Exe-AddResource Latin.ico, 301
;@Ahk2Exe-AddResource Cyrillic.ico, 302

isLatin := true
;@Ahk2Exe-IgnoreBegin
Menu, Tray, Icon, Latin.ico
;@Ahk2Exe-IgnoreEnd
/*@Ahk2Exe-Keep
Menu, Tray, Icon, %A_ScriptFullPath%, -301
*/

;##########################################################################################################################################;
;######################################################  Functions  #######################################################################;
;##########################################################################################################################################;

fAbort(isCondition, sFuncName, sNote, dVars:="") {
    Local

	If isCondition {
		sAbortMessage := % sFuncName ": " sNote
		. "`n`nA_LineNumber: """ A_LineNumber """`nErrorLevel: """ ErrorLevel """`nA_LastError: """ A_LastError """`n"
		For sName, sValue in dVars
			sAbortMessage .= "`n" sName ": """ sValue """"
		MsgBox, 16,, % sAbortMessage
		ExitApp
	}
}

fCharToggle(charA, charB) {
    Local
    Static bCharToggle := true

    If (A_PriorHotkey == A_ThisHotkey) {
        If A_PriorKey in Space,LShift,RShift,LAlt,RAlt,LControl,RControl,LWin,RWin,Backspace
            bCharToggle := true
        else bCharToggle := !bCharToggle
        If ( A_PriorKey != "Backspace" )
            Send {Backspace}
        If bCharToggle
            Send %charA%
        else Send %charB%
    } else {
        Send %charA%
        bCharToggle := true
    }
}

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~;
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~  App specific hotkeys  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~;
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~;

#IfWinActive ahk_class CabinetWClass ahk_exe Explorer.EXE
`::
If not WinExist("ahk_class mintty ahk_exe mintty.exe") {
    hwnd := WinActive("ahk_class CabinetWClass ahk_exe Explorer.EXE")
    If (hwnd)
        For win in ComObjCreate("Shell.Application").Windows
            If (win.hwnd == hwnd)
                pOpenDir := win.Document.Folder.Self.Path
    Run, % "C:\Program Files\Git\git-bash.exe --cd=" pOpenDir, , UseErrorLevel
    fAbort((ErrorLevel != 0), A_ThisFunc, "Error running ""git-bash.exe"".")
} else if not WinActive("ahk_class mintty ahk_exe mintty.exe")
    WinActivate
return

#IfWinActive ahk_class mintty ahk_exe mintty.exe
`::Send !{F4}

#IfWinActive ahk_class Chrome_WidgetWin_1 ahk_exe Code.exe
`::Send ^``

#IfWinActive ahk_class MozillaWindowClass ahk_exe firefox.exe
`::Send {F12}
NumLock::
Send {F6}
Sleep 200
Send yt{Enter}  ; Toggle visibility of YouTube video controls
return
NumpadAdd::Send c
NumpadIns::Send f

#IfWinActive

;&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&;
;&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&  Remappings & Hotkeys  &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&;
;&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&;

*LAlt::Send {Blind}{RCtrl DownR}
*LAlt Up::
If (A_PriorKey == "LAlt")
    Send {Escape}
Send {Blind}{RCtrl Up}
return

Capslock::Backspace
>!Capslock::
<^>!Capslock::Send {Backspace}

#Space::
isLatin := !isLatin
;@Ahk2Exe-IgnoreBegin
If isLatin
    Menu, Tray, Icon, Latin.ico
else Menu, Tray, Icon, Cyrillic.ico
;@Ahk2Exe-IgnoreEnd

/*@Ahk2Exe-Keep
If isLatin
    Menu, Tray, Icon, %A_ScriptFullPath%, -301
else Menu, Tray, Icon, %A_ScriptFullPath%, -302
*/
return

+Space::
<^Space::
>!Space::
>!<^Space::Send {Space}

<#Tab::AltTab       ; LWin + Tab  =>  Alt + Tab
<#`::Send #{Tab}

NumpadClear::Space
NumpadHome::Volume_Up
NumpadEnd::Volume_Down

<^d::Send ^h        ; LCtrl + D   =>  Ctrl + H          Find and replace
<^q::Send !c        ; LCtrl + Q   =>  Alt + C           VSCode: match case
<^w::Send !w        ; LCtrl + W   =>  Alt + W           VSCode: match whole word
<^e::Send !r        ; LCtrl + E   =>  Alt + R           VSCode: use regex

VKDC::Send !d       ; \           =>  Alt + D           Explorer, Firefox: focus address bar


;••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••;
;••••••••••••••••••••••••••  Latin (Colemak): a, b, c, h, m, q, v, w, x, z are unchanged  •••••••••••••••••••••••••••••••••••••••;
;••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••;
#If !GetKeyState("LAlt", "P") and isLatin

e::Send f
r::Send p
t::Send g
y::Send j
u::Send l
i::Send u
o::Send y
p::Send /
[::Send «  ;  « {U+00AB} Left-pointing double-angle quotation mark
]::Send »  ;  » {U+00BB} Right-pointing double-angle quotation mark

s::Send r
d::Send s
f::Send t
g::Send d
j::Send n
k::Send e
l::Send i
`;::Send o
'::Send {#}

n::Send k
/::Send _
; - - - - - - - - - Latin SHIFT states - - - - - - - - - - - - - - - - ;
+e::Send F
+r::Send P
+t::Send G
+y::Send J
+u::Send L
+i::Send U
+o::Send Y
+p::Send \
+[::Send •  ;  • {U+2022} (Bullet)
+]::Send ◦  ;  ◦ {U+25E6} (White bullet)

+s::Send R
+d::Send S
+f::Send T
+g::Send D
+j::Send N
+k::Send E
+l::Send I
+`;::Send O
+'::Send *

+n::Send K
+,::Send ?
+.::Send {!}
+/::Send |

;•••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••;
;••••••••••••••••••••••••••••••••••••••••••••••••••••••  Cyrillic  •••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••;
;•••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••;
#If !GetKeyState("LAlt", "P") and !isLatin

q::Send ц
w::Send ь
e::Send я
r::fCharToggle("э", "є")
t::Send ф
y::Send з
u::Send в
i::Send к
o::Send д
p::fCharToggle("ч", "/")
[::fCharToggle("ш", "«")
]::fCharToggle("щ", "»")

a::Send у
s::fCharToggle("и", "й")
d::Send е
f::Send о
g::Send а
h::Send л
j::Send н
k::Send т
l::Send с
`;::Send р
'::fCharToggle("ї", "ґ")

z::Send .
x::Send `,
c::Send х
v::fCharToggle("ы", "і")
b::Send ю
n::Send б
m::Send м
,::Send п
.::Send г
/::Send ж
; - - - - - - - - - Cyrillic SHIFT states - - - - - - - - - - - - - - - - ;
+q::Send Ц
+w::Send ъ
+e::Send Я
+r::fCharToggle("Э", "Є")
+t::Send Ф
+y::Send З
+u::Send В
+i::Send К
+o::Send Д
+p::fCharToggle("Ч", "\")
+[::Send Ш
+]::Send Щ

+a::Send У
+s::fCharToggle("И", "Й")
+d::Send Е
+f::Send О
+g::Send А
+h::Send Л
+j::Send Н
+k::Send Т
+l::Send С
+`;::Send Р
+'::fCharToggle("Ї", "Ґ")

+z::Send {!}
+x::Send ?
+c::Send Х
+v::fCharToggle("Ы", "І")
+b::Send Ю
+n::Send Б
+m::Send М
+,::Send П
+.::Send Г
+/::Send Ж

;•••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••;
;•••••••••••••••••••••••••••••••••••  Characters not dependent on Latin-Cyrillic switch  •••••••••••••••••••••••••••••••••••••••••;
;•••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••;
#If !GetKeyState("LAlt", "P")
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;  SHIFT  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

+`::Send №  ;  № {U+2116} Numero sign

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;  AltGR  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  >!`::
<^>!`::Send ∞  ;  ∞ {U+    } Infinity sign
  >!1::
<^>!1::Send ¹  ;  ¹ {U+00B9} Superscript one
  >!2::
<^>!2::Send ²  ;  ² {U+00B2} Superscript two
  >!3::
<^>!3::Send ³  ;  ³ {U+00B3} Superscript three
  >!4::
<^>!4::Send √  ;  √ {U+221A} Square root
  >!5::
<^>!5::Send ·  ;  · {U+00B7} Middle dot
  >!6::
<^>!6::Send ×  ;  × {U+00D7} Multiplication sign
  >!7::
<^>!7::Send ÷  ;  ÷ {U+00F7} Division sign
  >!8::
<^>!8::Send {+}
  >!9::
<^>!9::Send −  ;  − {U+2212} Minus sign
  >!0::
<^>!0::Send ±  ;  ± {U+00B1} Plus-minus sign
  >!-::
<^>!-::Send ≈  ;  ≈ {U+2248} Almost equal to
  >!=::
<^>!=::Send ≠  ;  ≠ {U+2260} Not equal to

  >!q::
<^>!q::Send 9
  >!w::
<^>!w::Send 8
  >!e::
<^>!e::Send 7
  >!r::
<^>!r::Send 6
  >!t::
<^>!t::Send 5
  >!y::
<^>!y::Send þ  ;  þ {U+00FE} (Small thorn)
  >!u::
<^>!u::Send ð  ;  ð {U+00F0} (Small eth)
  >!i::
<^>!i::Send (
  >!o::
<^>!o::Send )
  >!p::
<^>!p::Send `%  ;  % {U+0025} (Percent sign)
  >![::
<^>![::Send ≥
  >!]::
<^>!]::Send ≤


  >!a::
<^>!a::Send 0
  >!s::
<^>!s::Send 1
  >!d::
<^>!d::Send 2
  >!f::
<^>!f::Send 3
  >!g::
<^>!g::Send 4
  >!h::
<^>!h::Send ‑  ;  ‑ {U+2011} Non-breaking hyphen
  >!j::
<^>!j::Send {+}
  >!k::
<^>!k::Send `=
  >!l::
<^>!l::Send "
  >!;::
<^>!;::Send '
  >!'::
<^>!'::Send ``  ;  Backtick (grave accent)
                                                        
  >!z::
<^>!z::Send æ   ;  æ {U+00E6} Small ash
  >!x::
<^>!x::Send œ   ;  œ {U+0153}
  >!c::
<^>!c::Send ©
  >!v::
<^>!v::Send ™
  >!b::
<^>!b::Send –   ;  – {U+2013} En dash
  >!n::
<^>!n::Send —   ;  — {U+2014} Em dash
  >!m::
<^>!m::Send -   ;  Hyphen-minus
  >!,::
<^>!,::Send `;
  >!.::
<^>!.::Send :
  >!/::
<^>!/::Send &

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Shift + AltGR  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;   +>!`::
; +<^>!`::Send
  +>!1::
+<^>!1::Send ಠ_ಠ
  +>!2::
+<^>!2::Send ¯\_(ツ)_/¯
  +>!3::
+<^>!3::Send ¯\(☯෴☯)/¯
  +>!4::
+<^>!4::Send (☞ ಠ_ಠ)☞
  +>!5::
+<^>!5::Send ᕦ(ಠ_ಠ)ᕤ

  +>!q::
+<^>!q::Send ̊
  +>!w::
+<^>!w::Send ̨
  +>!e::
+<^>!e::Send ̌
  +>!r::
+<^>!r::Send ̂
  +>!t::
+<^>!t::Send ̋
  +>!y::
+<^>!y::Send Þ
  +>!u::
+<^>!u::Send Ð
  +>!i::
+<^>!i::Send [
  +>!o::
+<^>!o::Send ]
  +>!p::
+<^>!p::Send °  ; Degree sign
;   +>![::
; +<^>![::Send
;   +>!]::
; +<^>!]::Send

  +>!a::
+<^>!a::Send ̀
  +>!s::
+<^>!s::Send ́
  +>!d::
+<^>!d::Send ̃
  +>!f::
+<^>!f::Send ̈
  +>!g::
+<^>!g::Send ß
  +>!h::
+<^>!h::Send ̧
  +>!j::
+<^>!j::Send <
  +>!k::
+<^>!k::Send >
  +>!l::
+<^>!l::Send {{}
  +>!;::
+<^>!;::Send {}}
  +>!'::
+<^>!'::Send ̄  ; ̄   {U+0304} (Combining macron)
                                                                                                
  +>!z::
+<^>!z::Send Æ
  +>!x::
+<^>!x::Send Œ
  +>!c::
+<^>!c::Send ₴  ;  Hryvnia
  +>!v::
+<^>!v::Send €  ;  Euro
  +>!b::
+<^>!b::Send £  ;  Pound
  +>!n::
+<^>!n::Send ₽  ;  Ruble
  +>!m::
+<^>!m::Send {^}
  +>!,::
+<^>!,::Send $
  +>!.::
+<^>!.::Send @
  +>!/::
+<^>!/::Send ~


;•••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••;
;•••••••••••••••••••••••••••••••••••••••••••••  LAlt (navigation, cursor, misc)  •••••••••••••••••••••••••••••••••••••••••••••••••••;
;•••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••;
#If GetKeyState("LAlt", "P")

*m::Send {Delete}
*q::Send ^+t            ; LAlt + Q          =>  Ctrl + Shift + T      Firefox: undo close tab
*y::Send ^p             ; LAlt + Y          =>  Ctrl + P              VSCode: go to file
*u::Send ^g             ; LAlt + U          =>  Ctrl + G              VSCode: go to line
*o::Send +{F10}         ; LAlt + O          =>  Shift + F10           Context menu
*p::Send !d             ; LAlt + P          =>  Alt + D               Explorer, Firefox: focus address bar

*g::Send ^k^[           ; LAlt + G          =>  Ctrl + K + Ctrl + [   VSCode: fold region recursively
*h::Send ^k^]           ; LAlt + H          =>  Ctrl + K + Ctrl + ]   VSCode: unfold region recursively

*+z::Send ^y            ; LAlt + Shift + Z  =>  Ctrl + Y              Redo action
*b::Send ^/             ; LAlt + B          =>  Ctrl + /              VSCode: toggle comment

; — — — — — — — — — — — — — — — — — — — — — — — — — — — — — — — — — — — — — ;
*j::
If GetKeyState(";", "P")
  Send +{Left}                         ; LAlt + ; + J              =>  Shift + Left
else Send {Left}
return
*+j::Send +{Left}                      ; LAlt + Shift + J          =>  Shift + Left
*<^j::
If GetKeyState(";", "P")
    Send ^+{Left}                      ; LAlt + LCtrl + ; + J      =>  Ctrl + Shift + Left
else Send ^{Left}                      ; LAlt + LCtrl + J          =>  Ctrl + Left
return
*<^+j::Send ^+{Left}                   ; LAlt + LCtrl + Shift + J  =>  Ctrl + Shift + Left

*>!j::
*<^>!j::
If GetKeyState(";", "P")
  Send !+{Left}                        ; LAlt + AltGr + ; + J      =>  Alt + Shift + Left
else Send !{Left}                      ; LAlt + AltGr + J          =>  Alt + Left
return
*>!+j::
*<^>!+j::Send !+{Left}                 ; LAlt + AltGr + Shift + J  =>  Alt + Shift + Left

; – – – – – – – – – – – – – – – – – – – – – – – – – – – – – – – – – – – – – ;
*l::
If GetKeyState(";", "P")
  Send +{Right}
else Send {Right}
return
*+l::Send +{Right}
*<^l::
If GetKeyState(";", "P")
    Send ^+{Right}
else Send ^{Right}
return
*<^+l::Send ^+{Right}

*>!l::
*<^>!l::
If GetKeyState(";", "P")
  Send !+{Right}
else Send !{Right}
return
*>!+l::
*<^>!+l::Send !+{Right}

; – – – – – – – – – – – – – – – – – – – – – – – – – – – – – – – – – – – – – ;
*i::
If GetKeyState(";", "P")
  Send +{Up}
else Send {Up}
return
*+i::Send +{Up}
*<^i::
If GetKeyState(";", "P")
    Send ^+{Up}
else Send ^{Up}
return
*<^+i::Send ^+{Up}

*>!i::
*<^>!i::
If GetKeyState(";", "P")
  Send !+{Up}
else Send !{Up}
return
*>!+i::
*<^>!+i::Send !+{Up}

; – – – – – – – – – – – – – – – – – – – – – – – – – – – – – – – – – – – – – ;
*k::
If GetKeyState(";", "P")
  Send +{Down}
else Send {Down}
return
*+k::Send +{Down}
*<^k::
If GetKeyState(";", "P")
    Send ^+{Down}
else Send ^{Down}
return
*<^+k::Send ^+{Down}

*>!k:: 
*<^>!k::
If GetKeyState(";", "P")
  Send !+{Down}
else Send !{Down}
return
*>!+k::
*<^>!+k::Send !+{Down}

; – – – – – – – – – – – – – – – – – – – – – – – – – – – – – – – – – – – – – ;
*,::Send ^!{Down}       ; LAlt + ,          => Ctrl + Alt + Down
*+,::Send ^!+{Down}     ; LAlt + Shift + ,  => Ctrl + Alt + Shift + Down
*.::Send ^!{Up}         ; LAlt + .          => Ctrl + Alt + Up
*+.::Send ^!+{Up}       ; LAlt + Shift + .  => Ctrl + Alt + Shift + Up

;<==<==<==<==<==<==<==<==<==<==<==<==<==<==<==<==   Left side navigation: Home, End, PgUp, PgDn   <==<==<==<==<==<==<==<==<==<==<==<==<==<==

*s::
If GetKeyState(";", "P")
  Send +{Home}
else Send {Home}             ; LAlt + S          =>  Home
return
*+s::Send +{Home}            ; LAlt + Shift + S  =>  Shift + Home
*>!s::
*<^>!s::Send ^{PgUp}         ; LAlt + AltGr + S  =>  Ctrl + PageUp             Previous tab

*f::
If GetKeyState(";", "P")
  Send +{End}
else Send {End}              ; LAlt + F          =>  End
return
*+f::Send +{End}             ; LAlt + Shift + F  =>  Shift + End
*>!f::
*<^>!f::Send ^{PgDn}         ; LAlt + AltGr + F  =>  Ctrl + PageDown           Next tab


*e::Send {PgUp}              ; LAlt + E          =>  PageUp
*>!e::
*<^>!e::Send ^+{PgUp}        ; LAlt + AltGr + E  =>  Ctrl + Shift + PageUp     Firefox, VSCode: move tab left

*d::Send {PgDn}              ; LAlt + D          =>  PageDown
*>!d::
*<^>!d::Send ^+{PgDn}        ; LAlt + AltGr + D  =>  Ctrl + Shift + PageDown   Firefox, VSCode: move tab right

#If