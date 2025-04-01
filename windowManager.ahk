#Requires AutoHotkey v2.0

;defining utility functions

;get current window state (unplaced, already in start position, onethird, twothirds)
GetCurrentWindowState()
{

}
;get current window size/position
;implementation not required WinGetClientPos exists
;https://www.autohotkey.com/docs/v2/lib/WinGetClientPos.htm

;get screen resolution
GetScreenResolution()
{

}

;set window position
SetWindowPosition()
{
    ActiveHwnd := WinExist("A")
}


;defining hotkeys
;move windows on different screens


;move windows on same screen
#!Left::
{
    WinGetClientPos(&x, &Y, &W, &H, "A")
    MsgBox("Length " x)
}