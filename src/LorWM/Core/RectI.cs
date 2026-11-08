namespace LorWM.Core;

public readonly record struct RectI(int Left, int Top, int Right, int Bottom)
{
    public int Width => Math.Max(0, Right - Left);
    public int Height => Math.Max(0, Bottom - Top);
    public long Area => (long)Width * Height;
    public double CenterX => Left + (Width / 2d);
    public double CenterY => Top + (Height / 2d);

    public static RectI FromPositionAndSize(int x, int y, int width, int height) =>
        new(x, y, x + width, y + height);

    public long IntersectionArea(RectI other)
    {
        var width = Math.Max(0, Math.Min(Right, other.Right) - Math.Max(Left, other.Left));
        var height = Math.Max(0, Math.Min(Bottom, other.Bottom) - Math.Max(Top, other.Top));
        return (long)width * height;
    }
}
