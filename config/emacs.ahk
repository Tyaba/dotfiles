;;
;; An autohotkey script that provides emacs-like keybinding on Windows
;;
;; 注意: hoge;commentではなくhoge ;commentのように" ;"でコメントアウトすること
#InstallKeybdHook
#UseHook

; The following line is a contribution of NTEmacs wiki http://www49.atwiki.jp/ntemacs/pages/20.html
SetKeyDelay 0

; turns to be 1 when ctrl-x is pressed
is_pre_x = 0
; turns to be 1 when ctrl-space is pressed
is_pre_spc = 0

; Applications you want to disable emacs-like keybindings
; (Please comment out applications you don't use)
is_target()
{
  IfWinActive,ahk_class ConsoleWindowClass; Cygwin
    Return 1
  IfWinActive,ahk_class VMwareUnityHostWndClass
    Return 1
  IfWinActive,ahk_exe Code.exe ; vscode
    Return 1
  IfWinActive,ahk_exe Cursor.exe ; cursor
    Return 1
  If WinActive("ahk_exe Code - Insiders.exe")
    Return 1
  IfWinActive,ahk_exe WindowsTerminal.exe ; windows terminal
    Return 1
  IfWinActive,ahk_exe blender.exe ; blender
    Return 1
  Return 0
}

; -------- prefix x functions BEGINS --------
delete_char()
{
  Send {Del}
  global is_pre_spc = 0
  Return
}
delete_backward_char()
{
  Send {BS}
  global is_pre_spc = 0
  Return
}
kill_line()
{
  Send {ShiftDown}{END}{SHIFTUP}
  Sleep 50 ;[ms] this value depends on your environment
  Send ^x
  global is_pre_spc = 0
  Return
}
open_line()
{
  Send {END}{Enter}{Up}
  global is_pre_spc = 0
  Return
}
quit()
{
  Send {ESC}
  global is_pre_spc = 0
  Return
}
newline()
{
  Send {Enter}
  global is_pre_spc = 0
  Return
}
indent_for_tab_command()
{
  Send {Tab}
  global is_pre_spc = 0
  Return
}
newline_and_indent()
{
  Send {Enter}{Tab}
  global is_pre_spc = 0
  Return
}
isearch_forward()
{
  Send ^f
  global is_pre_spc = 0
  Return
}
isearch_backward()
{
  Send ^f
  global is_pre_spc = 0
  Return
}
kill_region()
{
  Send ^x
  global is_pre_spc = 0
  Return
}
kill_ring_save()
{
  Send ^c
  global is_pre_spc = 0
  Return
}
yank()
{
  Send ^v
  global is_pre_spc = 0
  Return
}
undo()
{
  Send ^z
  global is_pre_spc = 0
  Return
}
find_file()
{
  Send ^o
  global is_pre_x = 0
  Return
}
save_buffer()
{
  Send, ^s
  global is_pre_x = 0
  Return
}
send_ctrl_e()
{
  Send ^e
  global is_pre_x = 0
  Return
}
send_ctrl_w()
{
  Send ^w
  global is_pre_x = 0
  Return
}
send_ctrl_p()
{
  Send ^p
  global is_pre_x = 0
  Return
}
send_ctrl_n()
{
  Send ^n
  global is_pre_x = 0
  Return
}
; -------- prefix x functions ENDS --------

move_beginning_of_line()
{
  global
  if is_pre_spc
    Send +{HOME}
  Else
    Send {HOME}
  Return
}
move_end_of_line()
{
  global
  if is_pre_spc
    Send +{END}
  Else
    Send {END}
  Return
}
previous_line()
{
  global
  if is_pre_spc
    Send +{Up}
  Else
    Send {Up}
  Return
}
next_line()
{
  global
  if is_pre_spc
    Send +{Down}
  Else
    Send {Down}
  Return
}
forward_char()
{
  global
  if is_pre_spc
    Send +{Right}
  Else
    Send {Right}
  Return
}
backward_char()
{
  global
  if is_pre_spc
    Send +{Left}
  Else
    Send {Left}
  Return
}
scroll_up()
{
  global
  if is_pre_spc
    Send +{PgUp}
  Else
    Send {PgUp}
  Return
}
scroll_down()
{
  global
  if is_pre_spc
    Send +{PgDn}
  Else
    Send {PgDn}
  Return
}
convert_language()
{
  ; "!"はAlt、"``"は`のエスケープ
  ; なぜか機能しなくなったのでPowerToysのKeyboard Managerで代用
  Send {Blind}{vkF3sc029}
  Return
}
hiragana_transform()
{
  Send {F6}
  Return
}
katakana_transform()
{
  Send {F7}
  Return
}

^x::
  If is_target()
    Send %A_ThisHotkey%
  Else
    is_pre_x = 1
  Return
^f::
  If is_target()
    Send %A_ThisHotkey%
  Else
  {
    If is_pre_x
      find_file()
    Else
      forward_char()
  }
  Return
^c::
  If is_target()
    Send %A_ThisHotkey%
  Else
  {
    If is_pre_x
      send_ctrl_w()
  }
  Return
^d::
  If is_target()
    Send %A_ThisHotkey%
  Else
    delete_char()
  Return
^h::
  If is_target()
    Send %A_ThisHotkey%
  Else
    delete_backward_char()
  Return
^k::
  If is_target()
    Send %A_ThisHotkey%
  Else
    kill_line()
  Return
;; ^o::
;;   If is_target()
;;     Send %A_ThisHotkey%
;;   Else
;;     open_line()
;;   Return
^g::
  If is_target()
    Send %A_ThisHotkey%
  Else
    quit()
  Return
;; ^j::
;;   If is_target()
;;     Send %A_ThisHotkey%
;;   Else
;;     newline_and_indent()
;;   Return
^m::
  If is_target()
    Send %A_ThisHotkey%
  Else
    newline()
  Return
^i::
  If is_target()
    Send %A_ThisHotkey%
  Else
    indent_for_tab_command()
  Return
^s::
  If is_target()
    Send %A_ThisHotkey%
  Else
  {
    If is_pre_x
      save_buffer()
    Else
      isearch_forward()
  }
  Return
^r::
  If is_target()
    Send %A_ThisHotkey%
  Else
    isearch_backward()
  Return
^w::
  If is_target()
    Send %A_ThisHotkey%
  Else
  {
    If is_pre_x
      send_ctrl_w()
    Else
      kill_region()
  }
  Return
!w::
  If is_target()
    Send %A_ThisHotkey%
  Else
    kill_ring_save()
  Return
^y::
  If is_target()
    Send %A_ThisHotkey%
  Else
    yank()
  Return
^/::
  If is_target()
    Send %A_ThisHotkey%
  Else
    undo()
  Return

;$^{Space}::
;^vk20sc039::
^vk20::
  If is_target()
    Send {CtrlDown}{Space}{CtrlUp}
  Else
  {
    If is_pre_spc
      is_pre_spc = 0
    Else
      is_pre_spc = 1
  }
  Return
^@::
  If is_target()
    Send %A_ThisHotkey%
  Else
  {
    If is_pre_spc
      is_pre_spc = 0
    Else
      is_pre_spc = 1
  }
  Return
^a::
  If is_target()
    Send %A_ThisHotkey%
  Else
    move_beginning_of_line()
  Return
^e::
  If is_target()
    Send %A_ThisHotkey%
  Else
    ; notion等でctrl eしたいときはc-x c-eでできるようにしておく
    If is_pre_x
      send_ctrl_e()
    Else
      move_end_of_line()
  Return
^p::
  If is_target()
    Send %A_ThisHotkey%
  Else
  {
    If is_pre_x
      send_ctrl_p()
    Else
      previous_line()
  }
  Return
^n::
  If is_target()
    Send %A_ThisHotkey%
  Else
  {
    If is_pre_x
      send_ctrl_n()
    Else
      next_line()
  }
  Return
^b::
  If is_target()
    Send %A_ThisHotkey%
  Else
    backward_char()
  Return
^v::
  If is_target()
    Send %A_ThisHotkey%
  Else
    scroll_down()
  Return
!v::
  If is_target()
    Send %A_ThisHotkey%
  Else
    scroll_up()
  Return
; 非アプリ依存な設定
^\::
  convert_language()
  Return
^6::
  hiragana_transform()
  Return
^7::
  katakana_transform()
  Return
