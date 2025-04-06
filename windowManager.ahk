#Requires AutoHotkey v2.0

;defining utility functions
PxMidpoint(x1, x2)
{
    return (x1 + x2) / 2
}

PxDistance(x1, x2)
{
    return Abs(x1 - x2)
}

GetWindowWidthBySnapState(Hotkey, MonitorWidth, &LeftmostWindowPxVal, RightmostWindowPxVal)
{
    OneThirdDistance := Round((MonitorWidth / 3))
    TwoThirdsDistance := Round((MonitorWidth / 3) * 2)
    OneHalfDistance := Round((MonitorWidth / 2))

    DistanceFromEdge := Hotkey == '#!Left' ? PxDistance(MonitorWidth, RightmostWindowPxVal) : 
                            Hotkey == '#!Right' ? PxDistance(0, LeftmostWindowPxVal) : 0

     MsgBox("RightmostWindowPxVal `t" RightmostWindowPxVal
             "`nDistanceFromEdge `t" DistanceFromEdge)

    if(DistanceFromEdge == OneHalfDistance) { ;halfposition

        NewWidth := TwoThirdsDistance
        LeftmostWindowPxVal := GetXCoordinateFromArrowKeyPress(Hotkey, TwoThirdsDistance, MonitorWidth)

    } else if(DistanceFromEdge == OneThirdDistance) { ;twothirdsposition

        NewWidth := OneThirdDistance
        LeftmostWindowPxVal := GetXCoordinateFromArrowKeyPress(Hotkey, OneThirdDistance, MonitorWidth)

    } else if(DistanceFromEdge == TwoThirdsDistance) { ;onethirdposition

        NewWidth := OneHalfDistance
        LeftmostWindowPxVal := GetXCoordinateFromArrowKeyPress(Hotkey, OneHalfDistance, MonitorWidth)

    } else {

        NewWidth := OneHalfDistance
        LeftmostWindowPxVal := GetXCoordinateFromArrowKeyPress(Hotkey, OneHalfDistance, MonitorWidth)
        
    }

    return NewWidth
}

GetXCoordinateFromArrowKeyPress(Hotkey, Distance, MonitorWidth)
{
    if(Hotkey == '#!Left') {
        return 0
    }

    if(Hotkey == '#!Right') {

        NewXCoordinate := MonitorWidth - Distance

        return NewXCoordinate
    }
}

;just looks at corner position for now could be improved to look at screen areas
;https://stackoverflow.com/questions/59883798/determine-which-monitor-the-focus-window-is-on
GetActiveMonitorNumber(XOffset?)
{
    WinGetPos(&windowXPos, &windowYPos, &windowWidthPX, &windowHeightPX, "A")

    AdjustedXPos := windowXPos + (XOffset ?? 0)

    Loop MonitorGetCount() {

        MonitorGetWorkArea(A_Index, &WL, &WT, &WR, &WB)

        xPosInWorkArea := (WL <= AdjustedXPos && AdjustedXPos <= WR)
        yPosInWorkArea := (WT <= windowYPos && windowYPos <= WB)

        ; MsgBox("windowXPos `t" windowXPos
        ;      "`nAdjustedXPos `t" AdjustedXPos
        ;     "`nWL `t" WL
        ;     "`nWT `t" WT
        ;     "`nWR `t" WR
        ;     "`nWB `t" WB
        ;     "`nxPosInWorkArea `t" xPosInWorkArea
        ;     "`nPosInWorkArea `t" yPosInWorkArea)

        if(xPosInWorkArea && yPosInWorkArea) {
            return A_Index
        }

    }

    return 1 ;primary monitor number
}

GetLeftMonitorNumber(XOffset)
{
    ActiveMonitorNumber := GetActiveMonitorNumber(XOffset)

    if(ActiveMonitorNumber == 1) {
        return MonitorGetCount()
    } else {
        return ActiveMonitorNumber--
    }
}

GetRightMonitorNumber(XOffset)
{
    ActiveMonitorNumber := GetActiveMonitorNumber(XOffset)

    if(ActiveMonitorNumber == MonitorGetCount()) {
        return 1 ;primary monitor number
    } else {
        return ActiveMonitorNumber++
    }
}

CalculateWindowOffset(&XOffset, &YOffset, &WindowWidthDelta, &WindowHeightDelta)
{

    WinGetClientPos(&OutX, &OutY, &OutWidth, &OutHeight, "A")
    WinGetPos(&WindowXPos, &WindowYPos, &WindowWidthPX, &WindowHeightPX, "A")

    XOffset := PxDistance(WindowXPos, OutX)
    YOffset := PxDistance(WindowYPos, OutY)
    WindowWidthDelta := PxDistance(WindowWidthPX, OutWidth)
    WindowHeightDelta := PxDistance(WindowHeightPX, OutHeight)

    MsgBox("WinGetClientPos" 
            "`n x: `t" OutX
            "`n y: `t" OutY
            "`n width: `t" OutWidth
            "`n height: `t" OutHeight

            "`n WinGetPos" 
            "`n x: `t" WindowXPos
            "`n y: `t" WindowYPos
            "`n width: `t" WindowWidthPX
            "`n height: `t" WindowHeightPX)

}

;defining hotkeys
;move windows on same screen
#!Left::
{
    CalculateWindowOffset(&XOffset, &YOffset, &WindowWidthDelta, &WindowHeightDelta)

    ActiveMonitorNumber := GetActiveMonitorNumber(XOffset)

    MonitorGetWorkArea(ActiveMonitorNumber, &Left, &Top, &Right, &Bottom)
    WinGetPos(&WindowXPos, &WindowYPos, &WindowWidthPX, &WindowHeightPX, "A")

    ScreenWidth := PxDistance(Right, Left)
    ScreenHeight := PxDistance(Bottom, Top)

    RightmostPxValIncludingBorders := WindowXPos + WindowWidthPX - (WindowWidthDelta / 2)

    if(ScreenWidth > ScreenHeight) {
        NewWindowWidth := GetWindowWidthBySnapState("#!Left", ScreenWidth, &WindowXPos, RightmostPxValIncludingBorders)
    } else {
        NewWindowWidth := ScreenWidth / 2
    }

    NewWindowWidth += WindowWidthDelta
    NewWindowHeight := ScreenHeight + WindowHeightDelta

    NewXPos := Left - XOffset

    WinMove(NewXPos, Top, NewWindowWidth, NewWindowHeight, "A", , , )

}

#!Right::
{

    ActiveMonitorNumber := GetActiveMonitorNumber()

    MonitorGetWorkArea(ActiveMonitorNumber, &Left, &Top, &Right, &Bottom)
    WinGetPos(&WindowXPos, &WindowYPos, &WindowWidthPX, &WindowHeightPX, "A")

    ScreenWidth := PxDistance(Right, Left)
    ScreenHeight := PxDistance(Bottom, Top)

    if(ScreenWidth > ScreenHeight) {
        NewWindowWidth := GetWindowWidthBySnapState("#!Right", ScreenWidth, &WindowXPos, WindowXPos + WindowWidthPX)
    } else {
        NewWindowWidth := ScreenWidth / 2
        WindowXPos := PxMidpoint(Right, Left)
    }

    WinMove(WindowXPos, Top, NewWindowWidth, ScreenHeight, "A", , , )

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

;thirds on same screen
^!Left::
{
    
    ActiveMonitorNumber := GetActiveMonitorNumber()

    MonitorGetWorkArea(ActiveMonitorNumber, &Left, &Top, &Right, &Bottom)

    OneThirdDistance := PxDistance(Right, Left) / 3

    WinMove(Left, Top, Round(OneThirdDistance), PxDistance(Bottom, Top), "A", , , )

}

^!Up::
{

    ActiveMonitorNumber := GetActiveMonitorNumber()

    MonitorGetWorkArea(ActiveMonitorNumber, &Left, &Top, &Right, &Bottom)

    OneThirdDistance := PxDistance(Right, Left) / 3
    OneThirdOffset := Round(OneThirdDistance) + Left

    WinMove(OneThirdOffset, Top, Round(OneThirdDistance), PxDistance(Bottom, Top), "A", , , )
    
}

^!Right::
{
    
    ActiveMonitorNumber := GetActiveMonitorNumber()

    MonitorGetWorkArea(ActiveMonitorNumber, &Left, &Top, &Right, &Bottom)

    OneThirdDistance := PxDistance(Right, Left) / 3
    TwoThirdsOffset := Round(OneThirdDistance * 2) + Left

    WinMove(TwoThirdsOffset, Top, Round(OneThirdDistance), PxDistance(Bottom, Top), "A", , , )

}

;move windows between different screens
#^!Left::
{

    CalculateWindowOffset(&XOffset, &YOffset, &WindowWidthDelta, &WindowHeightDelta)
    
    LeftMonitorNumber := GetLeftMonitorNumber(XOffset)

    MonitorGetWorkArea(LeftMonitorNumber, &Left, &Top, &Right, &Bottom)

    WinMove(Left, Top, PxDistance(Right, Left), PxDistance(Bottom, Top), "A", , , )

}

#^!Right::
{

    CalculateWindowOffset(&XOffset, &YOffset, &WindowWidthDelta, &WindowHeightDelta)

    RightMonitorNumber := GetRightMonitorNumber(XOffset)

    MonitorGetWorkArea(RightMonitorNumber, &Left, &Top, &Right, &Bottom)

    WinMove(Left, Top, PxDistance(Right, Left), PxDistance(Bottom, Top), "A", , , )
    
}