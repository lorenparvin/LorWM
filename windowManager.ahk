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

;defining hotkeys
;move windows on same screen
#!Left::
{

    ActiveMonitorNumber := GetActiveMonitorNumber()

    MonitorGetWorkArea(ActiveMonitorNumber, &Left, &Top, &Right, &Bottom)
    WinGetClientPos(&WindowXPos, &WindowYPos, &WindowWidthPX, &WindowHeightPX, "A")

    ScreenWidth := PxDistance(Right, Left)
    ScreenHeight := PxDistance(Bottom, Top)

    NewWindowWidth := (ScreenWidth > ScreenHeight) ? GetWindowWidthBySnapState("#!Left", ScreenWidth, &WindowXPos, WindowXPos + WindowWidthPX) : ScreenWidth / 2

    WinMove(Left, Top, NewWindowWidth, ScreenHeight, "A", , , )

}

#!Right::
{

    ActiveMonitorNumber := GetActiveMonitorNumber()

    MonitorGetWorkArea(ActiveMonitorNumber, &Left, &Top, &Right, &Bottom)
    WinGetClientPos(&WindowXPos, &WindowYPos, &WindowWidthPX, &WindowHeightPX, "A")

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

    WinMove(Left, Top, Ceil(OneThirdDistance), PxDistance(Bottom, Top), "A", , , )

}

^!Up::
{

    ActiveMonitorNumber := GetActiveMonitorNumber()

    MonitorGetWorkArea(ActiveMonitorNumber, &Left, &Top, &Right, &Bottom)

    OneThirdDistance := PxDistance(Right, Left) / 3
    OneThirdOffset := Ceil(OneThirdDistance) + Left

    WinMove(OneThirdOffset, Top, Ceil(OneThirdDistance), PxDistance(Bottom, Top), "A", , , )
    
}

^!Right::
{
    
    ActiveMonitorNumber := GetActiveMonitorNumber()

    MonitorGetWorkArea(ActiveMonitorNumber, &Left, &Top, &Right, &Bottom)

    OneThirdDistance := PxDistance(Right, Left) / 3
    TwoThirdsOffset := Ceil(OneThirdDistance * 2) + Left

    WinMove(TwoThirdsOffset, Top, Ceil(OneThirdDistance), PxDistance(Bottom, Top), "A", , , )

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