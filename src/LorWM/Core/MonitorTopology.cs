namespace LorWM.Core;

public static class MonitorTopology
{
    public static DisplayMonitor? ByLargestIntersection(
        RectI windowFrame,
        IReadOnlyList<DisplayMonitor> monitors,
        nint nearestMonitorHandle)
    {
        DisplayMonitor? best = null;
        long bestArea = 0;

        foreach (var monitor in monitors)
        {
            var area = windowFrame.IntersectionArea(monitor.Bounds);
            if (area > bestArea ||
                (area == bestArea && area > 0 && monitor.Handle == nearestMonitorHandle))
            {
                best = monitor;
                bestArea = area;
            }
        }

        return bestArea > 0
            ? best
            : monitors.FirstOrDefault(monitor => monitor.Handle == nearestMonitorHandle)
                ?? monitors.FirstOrDefault(monitor => monitor.IsPrimary)
                ?? monitors.FirstOrDefault();
    }

    public static DisplayMonitor? Adjacent(
        DisplayMonitor current,
        IReadOnlyList<DisplayMonitor> monitors,
        HorizontalDirection direction)
    {
        DisplayMonitor? best = null;
        (int BeamPenalty, double PrimaryGap, double PerpendicularGap, double CenterDistance) bestScore =
            (int.MaxValue, double.MaxValue, double.MaxValue, double.MaxValue);

        foreach (var candidate in monitors)
        {
            if (candidate.Handle == current.Handle)
            {
                continue;
            }

            var deltaX = candidate.Bounds.CenterX - current.Bounds.CenterX;
            if ((direction == HorizontalDirection.Left && deltaX >= 0) ||
                (direction == HorizontalDirection.Right && deltaX <= 0))
            {
                continue;
            }

            var overlapsVertically = candidate.Bounds.Top < current.Bounds.Bottom &&
                                     candidate.Bounds.Bottom > current.Bounds.Top;
            var primaryGap = (double)(direction == HorizontalDirection.Left
                ? Math.Max(0, current.Bounds.Left - candidate.Bounds.Right)
                : Math.Max(0, candidate.Bounds.Left - current.Bounds.Right));
            var perpendicularGap = IntervalGap(
                current.Bounds.Top,
                current.Bounds.Bottom,
                candidate.Bounds.Top,
                candidate.Bounds.Bottom);
            var deltaY = candidate.Bounds.CenterY - current.Bounds.CenterY;
            var centerDistance = Math.Sqrt((deltaX * deltaX) + (deltaY * deltaY));
            var score = (overlapsVertically ? 0 : 1, primaryGap, perpendicularGap, centerDistance);

            if (score.CompareTo(bestScore) < 0)
            {
                best = candidate;
                bestScore = score;
            }
        }

        return best;
    }

    private static double IntervalGap(double firstStart, double firstEnd, double secondStart, double secondEnd) =>
        Math.Max(0, Math.Max(firstStart, secondStart) - Math.Min(firstEnd, secondEnd));
}
