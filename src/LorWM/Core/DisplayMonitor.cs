namespace LorWM.Core;

public sealed record DisplayMonitor(
    nint Handle,
    RectI Bounds,
    RectI WorkArea,
    bool IsPrimary,
    string DeviceName);

public enum HorizontalDirection
{
    Left,
    Right,
}
