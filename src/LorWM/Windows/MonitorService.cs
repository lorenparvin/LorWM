using System.ComponentModel;
using System.Runtime.InteropServices;
using LorWM.Core;

namespace LorWM.Windows;

internal static class MonitorService
{
    private const uint MonitorInfoPrimary = 0x00000001;

    internal static IReadOnlyList<DisplayMonitor> GetAll()
    {
        var monitors = new List<DisplayMonitor>();

        NativeMethods.MonitorEnumProcedure callback = (
            nint monitor,
            nint deviceContext,
            ref NativeMethods.NativeRect monitorRectangle,
            nint data) =>
        {
            var info = new NativeMethods.MonitorInfoEx
            {
                Size = Marshal.SizeOf<NativeMethods.MonitorInfoEx>(),
                DeviceName = string.Empty,
            };

            if (!NativeMethods.GetMonitorInfo(monitor, ref info))
            {
                throw new Win32Exception();
            }

            monitors.Add(new DisplayMonitor(
                monitor,
                ToRect(info.Monitor),
                ToRect(info.WorkArea),
                (info.Flags & MonitorInfoPrimary) != 0,
                info.DeviceName));
            return true;
        };

        if (!NativeMethods.EnumDisplayMonitors(0, 0, callback, 0))
        {
            throw new Win32Exception();
        }

        return monitors;
    }

    internal static DisplayMonitor? ForWindow(nint window, RectI visibleFrame, IReadOnlyList<DisplayMonitor> monitors)
    {
        var nearest = NativeMethods.MonitorFromWindow(window, NativeMethods.MonitorDefaultToNearest);
        return MonitorTopology.ByLargestIntersection(visibleFrame, monitors, nearest);
    }

    private static RectI ToRect(NativeMethods.NativeRect rectangle) =>
        new(rectangle.Left, rectangle.Top, rectangle.Right, rectangle.Bottom);
}
