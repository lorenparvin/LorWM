namespace LorWM.Core;

public static class SnapLayout
{
    private const int SnapTolerance = 4;

    public static RectI CycleHorizontal(RectI workArea, RectI currentFrame, HorizontalDirection direction)
    {
        if (workArea.Width <= workArea.Height)
        {
            return Half(workArea, direction);
        }

        var oneThird = Divide(workArea.Width, 3);
        var twoThirds = Divide(workArea.Width * 2, 3);
        var oneHalf = Divide(workArea.Width, 2);
        var anchored = direction == HorizontalDirection.Left
            ? IsNear(currentFrame.Left, workArea.Left)
            : IsNear(currentFrame.Right, workArea.Right);

        var nextWidth = oneHalf;
        if (anchored && IsNear(currentFrame.Width, oneHalf))
        {
            nextWidth = twoThirds;
        }
        else if (anchored && IsNear(currentFrame.Width, twoThirds))
        {
            nextWidth = oneThird;
        }
        else if (anchored && IsNear(currentFrame.Width, oneThird))
        {
            nextWidth = oneHalf;
        }

        var x = direction == HorizontalDirection.Left
            ? workArea.Left
            : workArea.Right - nextWidth;

        return RectI.FromPositionAndSize(x, workArea.Top, nextWidth, workArea.Height);
    }

    public static RectI TopHalf(RectI workArea)
    {
        var split = Divide(workArea.Height, 2);
        return new RectI(workArea.Left, workArea.Top, workArea.Right, workArea.Top + split);
    }

    public static RectI BottomHalf(RectI workArea)
    {
        var split = Divide(workArea.Height, 2);
        return new RectI(workArea.Left, workArea.Top + split, workArea.Right, workArea.Bottom);
    }

    public static RectI Third(RectI workArea, int index)
    {
        ArgumentOutOfRangeException.ThrowIfLessThan(index, 0);
        ArgumentOutOfRangeException.ThrowIfGreaterThan(index, 2);

        var firstBoundary = workArea.Left + Divide(workArea.Width, 3);
        var secondBoundary = workArea.Left + Divide(workArea.Width * 2, 3);

        return index switch
        {
            0 => new RectI(workArea.Left, workArea.Top, firstBoundary, workArea.Bottom),
            1 => new RectI(firstBoundary, workArea.Top, secondBoundary, workArea.Bottom),
            _ => new RectI(secondBoundary, workArea.Top, workArea.Right, workArea.Bottom),
        };
    }

    public static RectI Full(RectI workArea) => workArea;

    private static RectI Half(RectI workArea, HorizontalDirection direction)
    {
        var width = Divide(workArea.Width, 2);
        var x = direction == HorizontalDirection.Left ? workArea.Left : workArea.Right - width;
        return RectI.FromPositionAndSize(x, workArea.Top, width, workArea.Height);
    }

    private static bool IsNear(int actual, int expected) => Math.Abs(actual - expected) <= SnapTolerance;

    private static int Divide(int numerator, int denominator) =>
        (int)Math.Round(numerator / (double)denominator, MidpointRounding.AwayFromZero);
}
