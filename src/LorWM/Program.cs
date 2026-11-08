using LorWM.App;
using LorWM.Windows;

namespace LorWM;

internal static class Program
{
    [STAThread]
    private static void Main()
    {
        NativeMethods.SetProcessDpiAwarenessContext(NativeMethods.DpiAwarenessContextPerMonitorAwareV2);

        using var singleInstance = new Mutex(initiallyOwned: true, @"Local\LorWM", out var isFirstInstance);
        if (!isFirstInstance)
        {
            return;
        }

        ApplicationConfiguration.Initialize();
        Application.Run(new TrayApplicationContext());
    }
}
