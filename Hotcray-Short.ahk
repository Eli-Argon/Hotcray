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
;@Ahk2Exe-SetName Hotcray-Short
;@Ahk2Exe-SetDescription AHK hotkeys
;@Ahk2Exe-SetMainIcon Hotcray-Short.ico
;@Ahk2Exe-SetCompanyName Argon Systems
;@Ahk2Exe-SetCopyright Eli Argon
;@Ahk2Exe-SetVersion 1.2.0

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
    Static bCharToggle

    If (A_PriorHotkey == A_ThisHotkey) {
        bCharToggle := !bCharToggle
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
VKC0::
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
VKC0::Send !{F4}

#IfWinActive ahk_class Chrome_WidgetWin_1 ahk_exe Code.exe
VKC0::Send ^{VKC0}

#IfWinActive ahk_class MozillaWindowClass ahk_exe firefox.exe
VKC0::Send {F12}
NumLock::
Send {F6}
Sleep 200
Send yt{Enter}  ; Toggle visibility of YouTube video controls
return
NumpadAdd::Send c
NumpadIns::Send t

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

; Capslock::Backspace
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

; NumpadClear::Space
; NumpadHome::Volume_Up
; NumpadEnd::Volume_Down

<^t::Send ^t
<^s::Send ^h        ; LCtrl + D   =>  Ctrl + H          Find and replace
<^q::Send !c        ; LCtrl + Q   =>  Alt + C           VSCode: match case                          ;!!!!!!!!!!   FOR COLEMAK LAYOUT   !!!!!!!!;
<^w::Send !w        ; LCtrl + W   =>  Alt + W           VSCode: match whole word
<^f::Send !p        ; LCtrl + E   =>  Alt + R           VSCode: use regex

VKDC::Send !s       ; \           =>  Alt + D           Explorer, Firefox: focus address bar


;••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••;
;••••••••••••••••••••••••••  Latin (Colemak): a, b, c, h, m, q, v, w, x, z are unchanged  •••••••••••••••••••••••••••••••••••••••;
;••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••;
#If !GetKeyState("LAlt", "P") and isLatin

; e::Send f
; r::Send p
; t::Send g
; y::Send j
; u::Send l
; i::Send u
; o::Send y
; p::Send \
; [::Send «  ;  « {U+00AB} Left-pointing double-angle quotation mark
; ]::Send »  ;  » {U+00BB} Right-pointing double-angle quotation mark

; s::Send r
; d::Send s
; f::Send t
; g::Send d
; j::Send n
; k::Send e
; l::Send i
; `;::Send o
; '::Send {#}

; n::Send k
; /::Send _
; - - - - - - - - - Latin SHIFT states - - - - - - - - - - - - - - - - ;
; +e::Send F
; +r::Send P
; +t::Send G
; +y::Send J
; +u::Send L
; +i::Send U
; +o::Send Y
; +p::Send /
; +[::Send •  ;  • {U+2022} (Bullet)
; +]::Send ◦  ;  ◦ {U+25E6} (White bullet)

; +s::Send R
; +d::Send S
; +f::Send T
; +g::Send D
; +j::Send N
; +k::Send E
; +l::Send I
; +`;::Send O
; +'::Send *

; +n::Send K
; +,::Send ?
; +.::Send {!}
; +/::Send |

;•••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••;
;••••••••••••••••••••••••••••••••••••••••••••••••••••••  Cyrillic  •••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••;
;•••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••;
#If !GetKeyState("LAlt", "P") and !isLatin

q::Send ц
w::Send ь
f::Send я
p::fCharToggle("э", "є")                         ;!!!!!!!!!!   FOR COLEMAK LAYOUT   !!!!!!!!;
g::Send ф
j::Send з
l::Send в
u::Send к
y::Send д
\::fCharToggle("ч", "\")
«::Send ш
»::Send щ

a::Send у
r::fCharToggle("и", "й")
s::Send е
t::Send о
d::Send а
h::Send л                                          ;!!!!!!!!!!   FOR COLEMAK LAYOUT   !!!!!!!!;
n::Send н
e::Send т
i::Send с
o::Send р
#::fCharToggle("ї", "ґ")

z::Send .
x::Send `,
c::Send х
v::fCharToggle("ы", "і")
b::Send ю
k::Send б
m::Send м
,::Send п
.::Send г
_::Send ж
; - - - - - - - - - Cyrillic SHIFT states - - - - - - - - - - - - - - - - ;
+q::Send Ц
+w::Send ъ
+f::Send Я
+p::fCharToggle("Э", "Є")
+g::Send Ф
+j::Send З
+l::Send В
+u::Send К
+y::Send Д
+\::fCharToggle("Ч", "/")
+«::Send Ш
+»::Send Щ

+a::Send У
+r::fCharToggle("И", "Й")
+s::Send Е
+t::Send О
+d::Send А
+h::Send Л                                                            ;!!!!!!!!!!   FOR COLEMAK LAYOUT   !!!!!!!!;
+n::Send Н
+e::Send Т
+i::Send С
+o::Send Р
+#::fCharToggle("Ї", "Ґ")

+z::Send {!}
+x::Send ?
+c::Send Х
+v::fCharToggle("Ы", "І")
+b::Send Ю
+k::Send Б
+m::Send М
+,::Send П
+.::Send Г
+_::Send Ж

;•••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••;
;•••••••••••••••••••••••••••••••••••  Characters not dependent on Latin-Cyrillic switch  •••••••••••••••••••••••••••••••••••••••••;
;•••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••;
#If !GetKeyState("LAlt", "P")
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;  SHIFT  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; +`::Send №  ;  № {U+2116} Numero sign

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;  AltGR  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;   >!`::
; <^>!`::Send ∞  ;  ∞ {U+    } Infinity sign
;   >!1::
; <^>!1::Send ¹  ;  ¹ {U+00B9} Superscript one
;   >!2::
; <^>!2::Send ²  ;  ² {U+00B2} Superscript two
;   >!3::
; <^>!3::Send ³  ;  ³ {U+00B3} Superscript three
;   >!4::
; <^>!4::Send √  ;  √ {U+221A} Square root
;   >!5::
; <^>!5::Send ·  ;  · {U+00B7} Middle dot
;   >!6::
; <^>!6::Send ×  ;  × {U+00D7} Multiplication sign
;   >!7::
; <^>!7::Send ÷  ;  ÷ {U+00F7} Division sign
;   >!8::
; <^>!8::Send {+}
;   >!9::
; <^>!9::Send −  ;  − {U+2212} Minus sign
;   >!0::
; <^>!0::Send ±  ;  ± {U+00B1} Plus-minus sign
;   >!-::
; <^>!-::Send ≈  ;  ≈ {U+2248} Almost equal to
;   >!=::
; <^>!=::Send ≠  ;  ≠ {U+2260} Not equal to

;   >!q::
; <^>!q::Send 9
;   >!w::
; <^>!w::Send 8
;   >!e::
; <^>!e::Send 7
;   >!r::
; <^>!r::Send 6
;   >!t::
; <^>!t::Send 5
;   >!y::
; <^>!y::Send þ  ;  þ {U+00FE} (Small thorn)
;   >!u::
; <^>!u::Send ð  ;  ð {U+00F0} (Small eth)
;   >!i::
; <^>!i::Send (
;   >!o::
; <^>!o::Send )
;   >!p::
; <^>!p::Send `%  ;  % {U+0025} (Percent sign)
;   >![::
; <^>![::Send ≥
;   >!]::
; <^>!]::Send ≤


;   >!a::
; <^>!a::Send 0
;   >!s::
; <^>!s::Send 1
;   >!d::
; <^>!d::Send 2
;   >!f::
; <^>!f::Send 3
;   >!g::
; <^>!g::Send 4
;   >!h::
; <^>!h::Send ‑  ;  ‑ {U+2011} Non-breaking hyphen
;   >!j::
; <^>!j::Send {+}
;   >!k::
; <^>!k::Send `=
;   >!l::
; <^>!l::Send "
;   >!;::
; <^>!;::Send '
;   >!'::
; <^>!'::Send ``  ;  Backtick (grave accent)
                                                        
;   >!z::
; <^>!z::Send æ   ;  æ {U+00E6} Small ash
;   >!x::
; <^>!x::Send œ   ;  œ {U+0153}
;   >!c::
; <^>!c::Send ©
;   >!v::
; <^>!v::Send ™
;   >!b::
; <^>!b::Send –   ;  – {U+2013} En dash
;   >!n::
; <^>!n::Send —   ;  — {U+2014} Em dash
;   >!m::
; <^>!m::Send -   ;  Hyphen-minus
;   >!,::
; <^>!,::Send `;
;   >!.::
; <^>!.::Send :
;   >!/::
; <^>!/::Send &

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

;   +>!q::
; +<^>!q::Send ̊
;   +>!w::
; +<^>!w::Send ̨
;   +>!e::
; +<^>!e::Send ̌
;   +>!r::
; +<^>!r::Send ̂
;   +>!t::
; +<^>!t::Send ̋
;   +>!y::
; +<^>!y::Send Þ
;   +>!u::
; +<^>!u::Send Ð
;   +>!i::
; +<^>!i::Send [
;   +>!o::
; +<^>!o::Send ]
;   +>!p::
; +<^>!p::Send °  ; Degree sign
; ;   +>![::
; ; +<^>![::Send
; ;   +>!]::
; ; +<^>!]::Send

;   +>!a::
; +<^>!a::Send ̀
;   +>!s::
; +<^>!s::Send ́
;   +>!d::
; +<^>!d::Send ̃
;   +>!f::
; +<^>!f::Send ̈
;   +>!g::
; +<^>!g::Send ß
;   +>!h::
; +<^>!h::Send ̧
;   +>!j::
; +<^>!j::Send <
;   +>!k::
; +<^>!k::Send >
;   +>!l::
; +<^>!l::Send {{}
;   +>!;::
; +<^>!;::Send {}}
;   +>!'::
; +<^>!'::Send ̄  ; ̄   {U+0304} (Combining macron)
                                                                                                
;   +>!z::
; +<^>!z::Send Æ
;   +>!x::
; +<^>!x::Send Œ
;   +>!c::
; +<^>!c::Send ₴  ;  Hryvnia
;   +>!v::
; +<^>!v::Send €  ;  Euro
;   +>!b::
; +<^>!b::Send £  ;  Pound
;   +>!n::
; +<^>!n::Send ₽  ;  Ruble
;   +>!m::
; +<^>!m::Send {^}
;   +>!,::
; +<^>!,::Send $
;   +>!.::
; +<^>!.::Send @
;   +>!/::
; +<^>!/::Send ~


;•••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••;
;•••••••••••••••••••••••••••••••••••••••••••••  LAlt (navigation, cursor, misc)  •••••••••••••••••••••••••••••••••••••••••••••••••••;
;•••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••;
#If GetKeyState("LAlt", "P")
                                                                   ;!!!!!!!!!!   FOR COLEMAK LAYOUT   !!!!!!!!;
*m::Send {Delete}
*q::Send ^+g            ; LAlt + Q          =>  Ctrl + Shift + T      Firefox: undo close tab
*j::Send ^\             ; LAlt + Y          =>  Ctrl + P              VSCode: go to file
*l::Send ^d             ; LAlt + U          =>  Ctrl + G              VSCode: go to line
*y::Send +{F10}         ; LAlt + O          =>  Shift + F10           Context menu
*\::Send !s             ; LAlt + P          =>  Alt + D               Explorer, Firefox: focus address bar

*d::Send ^e^«           ; LAlt + G          =>  Ctrl + K + Ctrl + [   VSCode: fold region recursively
*h::Send ^e^»           ; LAlt + H          =>  Ctrl + K + Ctrl + ]   VSCode: unfold region recursively

*+z::Send ^j            ; LAlt + Shift + Z  =>  Ctrl + Y              Redo action
*b::Send ^_             ; LAlt + B          =>  Ctrl + /              VSCode: toggle comment

; — — — — — — — — — — — — — — — — — — — — — — — — — — — — — — — — — — — — — ;
*n::
If GetKeyState("o", "P")
  Send +{Left}                         ; LAlt + ; + J              =>  Shift + Left
else Send {Left}
return
*+n::Send +{Left}                      ; LAlt + Shift + J          =>  Shift + Left
*<^n::
If GetKeyState("o", "P")
    Send ^+{Left}                      ; LAlt + LCtrl + ; + J      =>  Ctrl + Shift + Left
else Send ^{Left}                      ; LAlt + LCtrl + J          =>  Ctrl + Left
return
*<^+n::Send ^+{Left}                   ; LAlt + LCtrl + Shift + J  =>  Ctrl + Shift + Left

*>!n::
*<^>!n::
If GetKeyState("o", "P")
  Send !+{Left}                        ; LAlt + AltGr + ; + J      =>  Alt + Shift + Left
else Send !{Left}                      ; LAlt + AltGr + J          =>  Alt + Left
return
*>!+n::
*<^>!+n::Send !+{Left}                 ; LAlt + AltGr + Shift + J  =>  Alt + Shift + Left

; – – – – – – – – – – – – – – – – – – – – – – – – – – – – – – – – – – – – – ;
*i::
If GetKeyState("o", "P")
  Send +{Right}
else Send {Right}
return
*+i::Send +{Right}
*<^i::
If GetKeyState("o", "P")
    Send ^+{Right}
else Send ^{Right}
return
*<^+i::Send ^+{Right}                                               ;!!!!!!!!!!   FOR COLEMAK LAYOUT   !!!!!!!!;

*>!i::
*<^>!i::
If GetKeyState("o", "P")
  Send !+{Right}
else Send !{Right}
return
*>!+i::
*<^>!+i::Send !+{Right}

; – – – – – – – – – – – – – – – – – – – – – – – – – – – – – – – – – – – – – ;
*u::
If GetKeyState("o", "P")
  Send +{Up}
else Send {Up}
return
*+u::Send +{Up}
*<^u::
If GetKeyState("o", "P")
    Send ^+{Up}
else Send ^{Up}
return
*<^+u::Send ^+{Up}

*>!u::
*<^>!u::
If GetKeyState("o", "P")
  Send !+{Up}
else Send !{Up}
return
*>!+u::
*<^>!+u::Send !+{Up}

; – – – – – – – – – – – – – – – – – – – – – – – – – – – – – – – – – – – – – ;
*e::
If GetKeyState("o", "P")
  Send +{Down}
else Send {Down}
return
*+e::Send +{Down}
*<^e::
If GetKeyState("o", "P")                                               ;!!!!!!!!!!   FOR COLEMAK LAYOUT   !!!!!!!!;
    Send ^+{Down}
else Send ^{Down}
return
*<^+e::Send ^+{Down}

*>!e:: 
*<^>!e::
If GetKeyState("o", "P")
  Send !+{Down}
else Send !{Down}
return
*>!+e::
*<^>!+e::Send !+{Down}

; – – – – – – – – – – – – – – – – – – – – – – – – – – – – – – – – – – – – – ;
*,::Send ^!{Down}       ; LAlt + ,          => Ctrl + Alt + Down
*+,::Send ^!+{Down}     ; LAlt + Shift + ,  => Ctrl + Alt + Shift + Down
*.::Send ^!{Up}         ; LAlt + .          => Ctrl + Alt + Up
*+.::Send ^!+{Up}       ; LAlt + Shift + .  => Ctrl + Alt + Shift + Up

;<==<==<==<==<==<==<==<==<==<==<==<==<==<==<==<==   Left side navigation: Home, End, PgUp, PgDn   <==<==<==<==<==<==<==<==<==<==<==<==<==<==

*r::
If GetKeyState("o", "P")
  Send +{Home}
else Send {Home}             ; LAlt + S          =>  Home
return
*+r::Send +{Home}            ; LAlt + Shift + S  =>  Shift + Home
*>!r::
*<^>!r::Send ^{PgUp}         ; LAlt + AltGr + S  =>  Ctrl + PageUp             Previous tab

*t::
If GetKeyState("o", "P")
  Send +{End}
else Send {End}              ; LAlt + F          =>  End
return
*+t::Send +{End}             ; LAlt + Shift + F  =>  Shift + End
*>!t::
*<^>!t::Send ^{PgDn}         ; LAlt + AltGr + F  =>  Ctrl + PageDown           Next tab


*f::Send {PgUp}              ; LAlt + E          =>  PageUp
*>!f::
*<^>!f::Send ^+{PgUp}        ; LAlt + AltGr + E  =>  Ctrl + Shift + PageUp     Firefox, VSCode: move tab left

*s::Send {PgDn}              ; LAlt + D          =>  PageDown
*>!s::
*<^>!s::Send ^+{PgDn}        ; LAlt + AltGr + D  =>  Ctrl + Shift + PageDown   Firefox, VSCode: move tab right

#If