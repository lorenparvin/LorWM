using System.ComponentModel;
using System.Runtime.InteropServices;
using LorWM.Core;

namespace LorWM.Windows;

internal readonly record struct WindowFrame(RectI OuterBounds, RectI VisibleBounds)
{
    internal static WindowFrame Read(nint window)
    {
        if (!NativeMethods.GetWindowRect(window, out var outer))
        {
            throw new Win32Exception();
        }

        var visible = outer;
        var result = NativeMethods.DwmGetWindowAttribute(
            window,
            NativeMethods.DwmwaExtendedFrameBounds,
            out var dwmBounds,
            Marshal.SizeOf<NativeMethods.NativeRect>());

        if (result >= 0 && dwmBounds.Right > dwmBounds.Left && dwmBounds.Bottom > dwmBounds.Top)
        {
            visible = dwmBounds;
        }

        return new WindowFrame(ToRect(outer), ToRect(visible));
    }

    internal RectI OuterBoundsForVisibleTarget(RectI target)
    {
        var leftInset = VisibleBounds.Left - OuterBounds.Left;
        var topInset = VisibleBounds.Top - OuterBounds.Top;
        var rightInset = OuterBounds.Right - VisibleBounds.Right;
        var bottomInset = OuterBounds.Bottom - VisibleBounds.Bottom;

        return new RectI(
            target.Left - leftInset,
            target.Top - topInset,
            target.Right + rightInset,
            target.Bottom + bottomInset);
    }

    private static RectI ToRect(NativeMethods.NativeRect rectangle) =>
        new(rectangle.Left, rectangle.Top, rectangle.Right, rectangle.Bottom);
}
