#Requires AutoHotkey v2.0

;defining utility functions
PxMidpoint(x1, x2)
{
    return (x1 + x2) / 2
}

PxDistance(x1, x2)
{
    return (Abs(x1) + Abs(x2))
}

;get current window state (unplaced, already in start position, onethird, twothirds)
GetCurrentWindowState(Hotkey, MonitorWidth, &LeftmostWindowPxVal, &RightmostWindowPxVal)
{

    TwoThirdsDistance := (MonitorWidth / 3) * 2
    OneThirdDistance := (MonitorWidth / 3)
    OneHalfDistance := (MonitorWidth / 2)

    if(Hotkey == '#!Left') {
        
        DistanceFromRightSide := MonitorWidth - RightmostWindowPxVal

        if(DistanceFromRightSide == OneHalfDistance) { ;halfposition

            RightmostWindowPxVal := TwoThirdsDistance

        } else if(DistanceFromRightSide == OneThirdDistance) { ;twothirdsposition

            RightmostWindowPxVal := OneThirdDistance

        } else if(DistanceFromRightSide == TwoThirdsDistance) { ;onethirdposition

            RightmostWindowPxVal := OneHalfDistance

        }

    }
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

    return 1 ;primary monitor number
}

GetLeftMonitorNumber()
{
    ActiveMonitorNumber := GetActiveMonitorNumber()

    if(ActiveMonitorNumber == 1) {
        return MonitorGetCount()
    } else {
        return ActiveMonitorNumber--
    }
}

GetRightMonitorNumber()
{
    ActiveMonitorNumber := GetActiveMonitorNumber()

    if(ActiveMonitorNumber == MonitorGetCount()) {
        return 1 ;primary monitor number
    } else {
        return ActiveMonitorNumber++
    }
}


;WinGetClientPos(&x, &Y, &W, &H, "A") ;saving this for future reference

;defining hotkeys
;move windows on same screen
#!Left::
{

    ActiveMonitorNumber := GetActiveMonitorNumber()

    MonitorGetWorkArea(ActiveMonitorNumber, &Left, &Top, &Right, &Bottom)

    ;GetCurrentWindowState

    WinMove(Left, Top, PxDistance(Right, Left) / 2, PxDistance(Bottom, Top), "A", , , )

}

#!Right::
{

    ActiveMonitorNumber := GetActiveMonitorNumber()

    MonitorGetWorkArea(ActiveMonitorNumber, &Left, &Top, &Right, &Bottom)

    WinMove(PxMidpoint(Right, Left), Top, PxDistance(Right, Left) / 2, PxDistance(Bottom, Top), "A", , , )

}

#!Up::
{

    ActiveMonitorNumber := GetActiveMonitorNumber()

    MonitorGetWorkArea(ActiveMonitorNumber, &Left, &Top, &Right, &Bottom)

    WinMove(Left, Top, PxDistance(Right, Left), PxDistance(Bottom, Top) / 2, "A", , , )

}

#!Down::
{

    ActiveMonitorNumber := GetActiveMonitorNumber()

    MonitorGetWorkArea(ActiveMonitorNumber, &Left, &Top, &Right, &Bottom)

    WinMove(Left, PxMidpoint(Bottom, Top), PxDistance(Right, Left), PxDistance(Bottom, Top) / 2, "A", , , )

}

#!f::
{

    ActiveMonitorNumber := GetActiveMonitorNumber()

    MonitorGetWorkArea(ActiveMonitorNumber, &Left, &Top, &Right, &Bottom)

    WinMove(Left, Top, PxDistance(Right, Left), PxDistance(Bottom, Top), "A", , , )

}

;move windows between different screens
#^!Left::
{

    LeftMonitorNumber := GetLeftMonitorNumber()

    MonitorGetWorkArea(LeftMonitorNumber, &Left, &Top, &Right, &Bottom)

    WinMove(Left, Top, PxDistance(Right, Left), PxDistance(Bottom, Top), "A", , , )

}

#^!Right::
{

    RightMonitorNumber := GetRightMonitorNumber()

    MonitorGetWorkArea(RightMonitorNumber, &Left, &Top, &Right, &Bottom)

    WinMove(Left, Top, PxDistance(Right, Left), PxDistance(Bottom, Top), "A", , , )
    
}