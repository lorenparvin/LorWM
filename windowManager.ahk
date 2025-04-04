#Requires AutoHotkey v2.0

;defining utility functions

;get current window state (unplaced, already in start position, onethird, twothirds)
GetCurrentWindowState(hotkey)
{

}

;just looks at corner position for now could be improved to look at screen areas
;https://stackoverflow.com/questions/59883798/determine-which-monitor-the-focus-window-is-on
GetActiveMonitorNumber()
{
    WinGetClientPos(&windowXPos, &windowYPos, &windowWidthPX, &windowHeightPX, "A")

    Loop MonitorGetCount() {

        MonitorGetWorkArea(A_Index, &WL, &WT, &WR, &WB)

        xPosInWorkArea := (WL <= windowXPos && windowXPos <= WR)
        yPosInWorkArea := (WT <= windowYPos && windowYPos <= WB)

        if(xPosInWorkArea && yPosInWorkArea) {
            return A_Index
        }

    }

    return 1 ;default to primary monitor
}


;defining hotkeys
;move windows on same screen
#!Left::
{

    ActiveMonitorNumber := GetActiveMonitorNumber()

    MonitorGetWorkArea(ActiveMonitorNumber, &Left, &Top, &Right, &Bottom)

    WinMove(Left, Top, Abs(Right - Left) / 2, Bottom, "A", , , )

    ;WinGetClientPos(&x, &Y, &W, &H, "A")

    ;MsgBox("x position " x)

}