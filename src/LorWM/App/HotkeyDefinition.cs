using LorWM.Windows;

namespace LorWM.App;

internal sealed record HotkeyDefinition(
    int Id,
    HotkeyAction Action,
    uint Modifiers,
    Keys Key,
    string DisplayName)
{
    public static IReadOnlyList<HotkeyDefinition> All { get; } =
    [
        new(1, HotkeyAction.SnapLeft, NativeMethods.ModWin | NativeMethods.ModAlt, Keys.Left, "Win+Alt+Left"),
        new(2, HotkeyAction.SnapRight, NativeMethods.ModWin | NativeMethods.ModAlt, Keys.Right, "Win+Alt+Right"),
        new(3, HotkeyAction.SnapTop, NativeMethods.ModWin | NativeMethods.ModAlt, Keys.Up, "Win+Alt+Up"),
        new(4, HotkeyAction.SnapBottom, NativeMethods.ModWin | NativeMethods.ModAlt, Keys.Down, "Win+Alt+Down"),
        new(5, HotkeyAction.FillWorkArea, NativeMethods.ModWin | NativeMethods.ModAlt, Keys.F, "Win+Alt+F"),
        new(6, HotkeyAction.LeftThird, NativeMethods.ModControl | NativeMethods.ModAlt, Keys.Left, "Ctrl+Alt+Left"),
        new(7, HotkeyAction.MiddleThird, NativeMethods.ModControl | NativeMethods.ModAlt, Keys.Up, "Ctrl+Alt+Up"),
        new(8, HotkeyAction.RightThird, NativeMethods.ModControl | NativeMethods.ModAlt, Keys.Right, "Ctrl+Alt+Right"),
        new(9, HotkeyAction.MoveToLeftMonitor, NativeMethods.ModWin | NativeMethods.ModControl | NativeMethods.ModAlt, Keys.Left, "Win+Ctrl+Alt+Left"),
        new(10, HotkeyAction.MoveToRightMonitor, NativeMethods.ModWin | NativeMethods.ModControl | NativeMethods.ModAlt, Keys.Right, "Win+Ctrl+Alt+Right"),
    ];
}
