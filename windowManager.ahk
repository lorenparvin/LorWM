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

IsNear(a, b, tol := 4) {
    return Abs(a - b) <= tol
}

GetWindowWidthBySnapState(Hotkey, MonitorWidth, MonitorLeft, &LeftmostAbs, RightmostAbs)
{
    OneThirdDistance := Round((MonitorWidth / 3))
    TwoThirdsDistance := Round((MonitorWidth / 3) * 2)
    OneHalfDistance := Round((MonitorWidth / 2))

    DistanceFromEdge := Hotkey == '#!Left' 
                            ? (MonitorLeft + MonitorWidth) - RightmostAbs
                            : LeftmostAbs - MonitorLeft

    if(IsNear(DistanceFromEdge, OneHalfDistance)) { ;halfposition

        NewWidth := TwoThirdsDistance
        LeftmostAbs := GetXCoordinateFromArrowKeyPress(Hotkey, TwoThirdsDistance, MonitorWidth, MonitorLeft)

    } else if(IsNear(DistanceFromEdge, OneThirdDistance)) { ;twothirdsposition

        NewWidth := OneThirdDistance
        LeftmostAbs := GetXCoordinateFromArrowKeyPress(Hotkey, OneThirdDistance, MonitorWidth, MonitorLeft)

    } else if(IsNear(DistanceFromEdge, TwoThirdsDistance)) { ;onethirdposition

        NewWidth := OneHalfDistance
        LeftmostAbs := GetXCoordinateFromArrowKeyPress(Hotkey, OneHalfDistance, MonitorWidth, MonitorLeft)

    } else {

        NewWidth := OneHalfDistance
        LeftmostAbs := GetXCoordinateFromArrowKeyPress(Hotkey, OneHalfDistance, MonitorWidth, MonitorLeft)
        
    }

    return NewWidth
}

GetXCoordinateFromArrowKeyPress(Hotkey, Distance, MonitorWidth, MonitorLeft)
{
    if(Hotkey == '#!Left') {
        return MonitorLeft
    }

    if(Hotkey == '#!Right') {
        return MonitorLeft + (MonitorWidth - Distance)
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

        if(xPosInWorkArea && yPosInWorkArea) {
            return A_Index
        }

    }

    return 1 ;primary monitor number
}

GetLeftMonitorNumber(XOffset)
{
    ActiveMonitorNumber := GetActiveMonitorNumber(XOffset)
    return ActiveMonitorNumber == 1 ? MonitorGetCount() : ActiveMonitorNumber - 1
}

GetRightMonitorNumber(XOffset)
{
    ActiveMonitorNumber := GetActiveMonitorNumber(XOffset)
    return ActiveMonitorNumber == MonitorGetCount() ? 1 : ActiveMonitorNumber + 1
}

CalculateWindowOffset(&XOffset, &YOffset, &WindowWidthDelta, &WindowHeightDelta)
{

    WinGetClientPos(&OutX, &OutY, &OutWidth, &OutHeight, "A")
    WinGetPos(&WindowXPos, &WindowYPos, &WindowWidthPX, &WindowHeightPX, "A")

    XOffset := PxDistance(WindowXPos, OutX)
    YOffset := PxDistance(WindowYPos, OutY)
    WindowWidthDelta := PxDistance(WindowWidthPX, OutWidth)
    WindowHeightDelta := PxDistance(WindowHeightPX, OutHeight)

}

AdjustValuesForOffset(&XPos, XOffset, &YPos, YOffset, &Width, WidthDelta, &Height, HeightDelta)
{
    XPos -= XOffset
    YPos -= YOffset
    Width += WidthDelta
    Height += HeightDelta
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

    if(ScreenWidth > ScreenHeight) {
        LeftmostAbs := WindowXPos + XOffset
        RightmostAbs := WindowXPos + WindowWidthPX - (WindowWidthDelta - XOffset)
        NewWindowWidth := GetWindowWidthBySnapState("#!Left", ScreenWidth, Left, &LeftmostAbs, RightmostAbs)
        NewXPos := LeftmostAbs
    } else {
        NewWindowWidth := Round(ScreenWidth / 2)
        NewXPos := Left
    }

    AdjustValuesForOffset(&NewXPos, XOffset, &Top, YOffset, &NewWindowWidth, WindowWidthDelta, &ScreenHeight, WindowHeightDelta)

    WinMove(NewXPos, Top, NewWindowWidth, ScreenHeight, "A", , , )

}

#!Right::
{

    CalculateWindowOffset(&XOffset, &YOffset, &WindowWidthDelta, &WindowHeightDelta)

    ActiveMonitorNumber := GetActiveMonitorNumber(XOffset)

    MonitorGetWorkArea(ActiveMonitorNumber, &Left, &Top, &Right, &Bottom)
    WinGetPos(&WindowXPos, &WindowYPos, &WindowWidthPX, &WindowHeightPX, "A")

    ScreenWidth := PxDistance(Right, Left)
    ScreenHeight := PxDistance(Bottom, Top)

    if(ScreenWidth > ScreenHeight) {
        LeftmostAbs := WindowXPos + XOffset
        RightmostAbs := WindowXPos + WindowWidthPX - (WindowWidthDelta - XOffset)
        NewWindowWidth := GetWindowWidthBySnapState("#!Right", ScreenWidth, Left, &LeftmostAbs, RightmostAbs)
        NewXPos := LeftmostAbs
    } else {
        NewWindowWidth := Round(ScreenWidth / 2)
        NewXPos := PxMidpoint(Right, Left)
    }

    AdjustValuesForOffset(&NewXPos, XOffset, &Top, YOffset, &NewWindowWidth, WindowWidthDelta, &ScreenHeight, WindowHeightDelta)

    WinMove(NewXPos, Top, NewWindowWidth, ScreenHeight, "A", , , )

}

#!Up::
{

    CalculateWindowOffset(&XOffset, &YOffset, &WindowWidthDelta, &WindowHeightDelta)

    ActiveMonitorNumber := GetActiveMonitorNumber(XOffset)

    MonitorGetWorkArea(ActiveMonitorNumber, &Left, &Top, &Right, &Bottom)

    ScreenWidth := PxDistance(Right, Left)

    HalfScreenHeight := (PxDistance(Bottom, Top) / 2)

    AdjustValuesForOffset(&Left, XOffset, &Top, YOffset, &ScreenWidth, WindowWidthDelta, &HalfScreenHeight, WindowHeightDelta)

    WinMove(Left, Top, ScreenWidth, HalfScreenHeight, "A", , , )

}

#!Down::
{

    CalculateWindowOffset(&XOffset, &YOffset, &WindowWidthDelta, &WindowHeightDelta)

    ActiveMonitorNumber := GetActiveMonitorNumber(XOffset)

    MonitorGetWorkArea(ActiveMonitorNumber, &Left, &Top, &Right, &Bottom)

    ScreenWidth := PxDistance(Right, Left)

    HalfScreenHeight := (PxDistance(Bottom, Top) / 2)

    YPositionHalfwayDownScreen := PxMidpoint(Bottom, Top)

    AdjustValuesForOffset(&Left, XOffset, &YPositionHalfwayDownScreen, YOffset, &ScreenWidth, WindowWidthDelta, &HalfScreenHeight, WindowHeightDelta)

    WinMove(Left, YPositionHalfwayDownScreen, ScreenWidth, HalfScreenHeight, "A", , , )

}

#!f::
{
    CalculateWindowOffset(&XOffset, &YOffset, &WindowWidthDelta, &WindowHeightDelta)

    ActiveMonitorNumber := GetActiveMonitorNumber(XOffset)

    MonitorGetWorkArea(ActiveMonitorNumber, &Left, &Top, &Right, &Bottom)

    ScreenWidth := PxDistance(Right, Left)

    ScreenHeight := PxDistance(Bottom, Top)

    AdjustValuesForOffset(&Left, XOffset, &Top, YOffset, &ScreenWidth, WindowWidthDelta, &ScreenHeight, WindowHeightDelta)

    WinMove(Left, Top, ScreenWidth, ScreenHeight, "A", , , )

}

;thirds on same screen
^!Left::
{

    CalculateWindowOffset(&XOffset, &YOffset, &WindowWidthDelta, &WindowHeightDelta)
    
    ActiveMonitorNumber := GetActiveMonitorNumber(XOffset)

    MonitorGetWorkArea(ActiveMonitorNumber, &Left, &Top, &Right, &Bottom)

    OneThirdDistance := Round(PxDistance(Right, Left) / 3)

    ScreenHeight := PxDistance(Bottom, Top)

    AdjustValuesForOffset(&Left, XOffset, &Top, YOffset, &OneThirdDistance, WindowWidthDelta, &ScreenHeight, WindowHeightDelta)

    WinMove(Left, Top, OneThirdDistance, ScreenHeight, "A", , , )

}

^!Up::
{

    CalculateWindowOffset(&XOffset, &YOffset, &WindowWidthDelta, &WindowHeightDelta)

    ActiveMonitorNumber := GetActiveMonitorNumber(XOffset)

    MonitorGetWorkArea(ActiveMonitorNumber, &Left, &Top, &Right, &Bottom)

    OneThirdDistance := Round(PxDistance(Right, Left) / 3)
    OneThirdOffset := Round(OneThirdDistance) + Left

    ScreenHeight := PxDistance(Bottom, Top)

    AdjustValuesForOffset(&OneThirdOffset, XOffset, &Top, YOffset, &OneThirdDistance, WindowWidthDelta, &ScreenHeight, WindowHeightDelta)

    WinMove(OneThirdOffset, Top, OneThirdDistance, ScreenHeight, "A", , , )
    
}

^!Right::
{

    CalculateWindowOffset(&XOffset, &YOffset, &WindowWidthDelta, &WindowHeightDelta)
    
    ActiveMonitorNumber := GetActiveMonitorNumber(XOffset)

    MonitorGetWorkArea(ActiveMonitorNumber, &Left, &Top, &Right, &Bottom)

    OneThirdDistance := Round(PxDistance(Right, Left) / 3)
    TwoThirdsOffset := Round(OneThirdDistance * 2) + Left

    ScreenHeight := PxDistance(Bottom, Top)

    AdjustValuesForOffset(&TwoThirdsOffset, XOffset, &Top, YOffset, &OneThirdDistance, WindowWidthDelta, &ScreenHeight, WindowHeightDelta)

    WinMove(TwoThirdsOffset, Top, OneThirdDistance, ScreenHeight, "A", , , )

}

;move windows between different screens
#^!Left::
{

    CalculateWindowOffset(&XOffset, &YOffset, &WindowWidthDelta, &WindowHeightDelta)
    
    LeftMonitorNumber := GetLeftMonitorNumber(XOffset)

    MonitorGetWorkArea(LeftMonitorNumber, &Left, &Top, &Right, &Bottom)

    ScreenWidth := PxDistance(Right, Left)

    ScreenHeight := PxDistance(Bottom, Top)

    AdjustValuesForOffset(&Left, XOffset, &Top, YOffset, &ScreenWidth, WindowWidthDelta, &ScreenHeight, WindowHeightDelta)

    WinMove(Left, Top, ScreenWidth, ScreenHeight, "A", , , )

}

#^!Right::
{

    CalculateWindowOffset(&XOffset, &YOffset, &WindowWidthDelta, &WindowHeightDelta)

    RightMonitorNumber := GetRightMonitorNumber(XOffset)

    MonitorGetWorkArea(RightMonitorNumber, &Left, &Top, &Right, &Bottom)

    ScreenWidth := PxDistance(Right, Left)

    ScreenHeight := PxDistance(Bottom, Top)

    AdjustValuesForOffset(&Left, XOffset, &Top, YOffset, &ScreenWidth, WindowWidthDelta, &ScreenHeight, WindowHeightDelta)

    WinMove(Left, Top, ScreenWidth, ScreenHeight, "A", , , )
    
}