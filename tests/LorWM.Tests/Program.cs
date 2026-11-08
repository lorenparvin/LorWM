using LorWM.Core;
using LorWM.App;
using System.Windows.Forms;

var tests = new (string Name, Action Run)[]
{
    ("Left snap cycles half, two-thirds, one-third", LeftSnapCycles),
    ("Right snap cycles half, two-thirds, one-third", RightSnapCycles),
    ("Thirds cover an odd-width work area", ThirdsCoverWorkArea),
    ("Largest monitor intersection wins", LargestIntersectionWins),
    ("Spatial navigation ignores enumeration order", SpatialNavigationIgnoresEnumerationOrder),
    ("Spatial navigation prefers an aligned monitor", SpatialNavigationPrefersAlignedMonitor),
    ("Hook matcher accepts exact modifiers", HookMatcherAcceptsExactModifiers),
    ("Hook matcher rejects extra modifiers", HookMatcherRejectsExtraModifiers),
    ("Startup command quotes executable path", StartupCommandQuotesExecutablePath),
    ("Startup command supports dotnet host", StartupCommandSupportsDotnetHost),
    ("Startup registration defaults to approved", StartupRegistrationDefaultsToApproved),
    ("Startup registration respects Windows disabled state", StartupRegistrationRespectsWindowsDisabledState),
    ("Application icon is embedded and readable", ApplicationIconIsEmbeddedAndReadable),
};

var failures = 0;
foreach (var test in tests)
{
    try
    {
        test.Run();
        Console.WriteLine($"PASS {test.Name}");
    }
    catch (Exception exception)
    {
        failures++;
        Console.Error.WriteLine($"FAIL {test.Name}: {exception.Message}");
    }
}

return failures == 0 ? 0 : 1;

static void LeftSnapCycles()
{
    var work = new RectI(0, 0, 1920, 1040);
    var half = SnapLayout.CycleHorizontal(work, new RectI(200, 200, 900, 700), HorizontalDirection.Left);
    Equal(new RectI(0, 0, 960, 1040), half);
    var twoThirds = SnapLayout.CycleHorizontal(work, half, HorizontalDirection.Left);
    Equal(new RectI(0, 0, 1280, 1040), twoThirds);
    var oneThird = SnapLayout.CycleHorizontal(work, twoThirds, HorizontalDirection.Left);
    Equal(new RectI(0, 0, 640, 1040), oneThird);
    Equal(half, SnapLayout.CycleHorizontal(work, oneThird, HorizontalDirection.Left));
}

static void RightSnapCycles()
{
    var work = new RectI(-1920, 0, 0, 1040);
    var half = SnapLayout.CycleHorizontal(work, new RectI(-1000, 200, -200, 700), HorizontalDirection.Right);
    Equal(new RectI(-960, 0, 0, 1040), half);
    var twoThirds = SnapLayout.CycleHorizontal(work, half, HorizontalDirection.Right);
    Equal(new RectI(-1280, 0, 0, 1040), twoThirds);
    var oneThird = SnapLayout.CycleHorizontal(work, twoThirds, HorizontalDirection.Right);
    Equal(new RectI(-640, 0, 0, 1040), oneThird);
    Equal(half, SnapLayout.CycleHorizontal(work, oneThird, HorizontalDirection.Right));
}

static void ThirdsCoverWorkArea()
{
    var work = new RectI(10, 20, 1929, 1100);
    var left = SnapLayout.Third(work, 0);
    var middle = SnapLayout.Third(work, 1);
    var right = SnapLayout.Third(work, 2);

    Equal(work.Left, left.Left);
    Equal(left.Right, middle.Left);
    Equal(middle.Right, right.Left);
    Equal(work.Right, right.Right);
    Equal(work.Width, left.Width + middle.Width + right.Width);
}

static void LargestIntersectionWins()
{
    var left = Monitor(1, new RectI(0, 0, 1000, 1000));
    var right = Monitor(2, new RectI(1000, 0, 2000, 1000));
    var selected = MonitorTopology.ByLargestIntersection(
        new RectI(800, 100, 1600, 900),
        [left, right],
        left.Handle);

    Equal(right, selected);
}

static void SpatialNavigationIgnoresEnumerationOrder()
{
    var left = Monitor(10, new RectI(-1200, 0, 0, 900));
    var center = Monitor(20, new RectI(0, 0, 1920, 1080));
    var right = Monitor(30, new RectI(1920, 100, 3200, 1124));
    DisplayMonitor[] scrambled = [right, left, center];

    Equal(left, MonitorTopology.Adjacent(center, scrambled, HorizontalDirection.Left));
    Equal(right, MonitorTopology.Adjacent(center, scrambled, HorizontalDirection.Right));
}

static void SpatialNavigationPrefersAlignedMonitor()
{
    var current = Monitor(1, new RectI(0, 0, 1000, 1000));
    var aligned = Monitor(2, new RectI(3000, 0, 4000, 1000));
    var diagonal = Monitor(3, new RectI(1000, -1200, 2000, -200));

    Equal(aligned, MonitorTopology.Adjacent(current, [diagonal, aligned], HorizontalDirection.Right));
}

static void HookMatcherAcceptsExactModifiers()
{
    var matcher = new HotkeyMatcher(HotkeyDefinition.All);
    HashSet<Keys> pressedKeys = [Keys.LWin, Keys.RMenu, Keys.Left];

    var match = matcher.Match(Keys.Left, pressedKeys);

    Equal(HotkeyAction.SnapLeft, match?.Action);
}

static void HookMatcherRejectsExtraModifiers()
{
    var matcher = new HotkeyMatcher(HotkeyDefinition.All);
    HashSet<Keys> pressedKeys = [Keys.LWin, Keys.LMenu, Keys.LShiftKey, Keys.Left];

    Equal<HotkeyDefinition?>(null, matcher.Match(Keys.Left, pressedKeys));
}

static void StartupCommandQuotesExecutablePath()
{
    Equal(
        "\"C:\\Program Files\\LorWM\\LorWM.exe\"",
        StartupRegistration.CreateCommand(@"C:\Program Files\LorWM\LorWM.exe", @"C:\Program Files\LorWM\LorWM.dll"));
}

static void StartupCommandSupportsDotnetHost()
{
    Equal(
        "\"C:\\Program Files\\dotnet\\dotnet.exe\" \"C:\\LorWM\\LorWM.dll\"",
        StartupRegistration.CreateCommand(@"C:\Program Files\dotnet\dotnet.exe", @"C:\LorWM\LorWM.dll"));
}

static void StartupRegistrationDefaultsToApproved()
{
    Equal(true, StartupRegistration.IsStartupApproved(null));
    Equal(true, StartupRegistration.IsStartupApproved(new byte[] { 2, 0, 0, 0 }));
    Equal(true, StartupRegistration.IsStartupApproved(new byte[] { 6, 0, 0, 0 }));
}

static void StartupRegistrationRespectsWindowsDisabledState()
{
    Equal(false, StartupRegistration.IsStartupApproved(new byte[] { 3, 0, 0, 0 }));
    Equal(false, StartupRegistration.IsStartupApproved(new byte[] { 7, 0, 0, 0 }));
}

static void ApplicationIconIsEmbeddedAndReadable()
{
    using var stream = typeof(StartupRegistration).Assembly
        .GetManifestResourceStream("LorWM.Assets.LorWM.ico");
    if (stream is null)
    {
        throw new InvalidOperationException("The application icon is not embedded.");
    }

    using var icon = new System.Drawing.Icon(stream);
    Equal(true, icon.Width > 0 && icon.Height > 0);
}

static DisplayMonitor Monitor(nint handle, RectI bounds) =>
    new(handle, bounds, bounds, false, handle.ToString());

static void Equal<T>(T expected, T actual)
{
    if (!EqualityComparer<T>.Default.Equals(expected, actual))
    {
        throw new InvalidOperationException($"Expected {expected}, got {actual}.");
    }
}
