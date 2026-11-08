using System.ComponentModel;
using LorWM.App;
using LorWM.Core;

namespace LorWM.Windows;

internal sealed class WindowManager
{
    internal void Execute(HotkeyAction action)
    {
        var window = NativeMethods.GetForegroundWindow();
        if (window == 0 || !NativeMethods.IsWindow(window) || !NativeMethods.IsWindowVisible(window))
        {
            return;
        }

        if (NativeMethods.IsZoomed(window))
        {
            NativeMethods.ShowWindow(window, NativeMethods.SwRestore);
        }

        var frame = WindowFrame.Read(window);
        var monitors = MonitorService.GetAll();
        var currentMonitor = MonitorService.ForWindow(window, frame.VisibleBounds, monitors);
        if (currentMonitor is null)
        {
            return;
        }

        var target = GetTarget(action, currentMonitor, monitors, frame.VisibleBounds);
        if (target is null)
        {
            return;
        }

        var outerTarget = frame.OuterBoundsForVisibleTarget(target.Value);
        if (!NativeMethods.SetWindowPos(
                window,
                0,
                outerTarget.Left,
                outerTarget.Top,
                outerTarget.Width,
                outerTarget.Height,
                NativeMethods.SwpNoZOrder | NativeMethods.SwpNoActivate | NativeMethods.SwpNoOwnerZOrder))
        {
            throw new Win32Exception();
        }
    }

    private static RectI? GetTarget(
        HotkeyAction action,
        DisplayMonitor current,
        IReadOnlyList<DisplayMonitor> monitors,
        RectI currentFrame)
    {
        return action switch
        {
            HotkeyAction.SnapLeft => SnapLayout.CycleHorizontal(current.WorkArea, currentFrame, HorizontalDirection.Left),
            HotkeyAction.SnapRight => SnapLayout.CycleHorizontal(current.WorkArea, currentFrame, HorizontalDirection.Right),
            HotkeyAction.SnapTop => SnapLayout.TopHalf(current.WorkArea),
            HotkeyAction.SnapBottom => SnapLayout.BottomHalf(current.WorkArea),
            HotkeyAction.FillWorkArea => SnapLayout.Full(current.WorkArea),
            HotkeyAction.LeftThird => SnapLayout.Third(current.WorkArea, 0),
            HotkeyAction.MiddleThird => SnapLayout.Third(current.WorkArea, 1),
            HotkeyAction.RightThird => SnapLayout.Third(current.WorkArea, 2),
            HotkeyAction.MoveToLeftMonitor => MonitorTopology.Adjacent(current, monitors, HorizontalDirection.Left)?.WorkArea,
            HotkeyAction.MoveToRightMonitor => MonitorTopology.Adjacent(current, monitors, HorizontalDirection.Right)?.WorkArea,
            _ => null,
        };
    }
}
