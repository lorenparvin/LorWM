using LorWM.Windows;

namespace LorWM.App;

internal sealed class TrayApplicationContext : ApplicationContext
{
    private readonly NotifyIcon _trayIcon;
    private readonly HotkeyWindow _hotkeyWindow;
    private readonly Icon _applicationIcon;
    private readonly StartupRegistration _startupRegistration = new();
    private readonly ToolStripMenuItem _runOnStartupItem;
    private readonly WindowManager _windowManager = new();

    public TrayApplicationContext()
    {
        var menu = new ContextMenuStrip();
        _runOnStartupItem = new ToolStripMenuItem("Run on startup")
        {
            Checked = IsStartupEnabled(),
        };
        _runOnStartupItem.Click += ToggleRunOnStartup;
        menu.Items.Add(_runOnStartupItem);
        menu.Items.Add(new ToolStripSeparator());
        menu.Items.Add("Exit LorWM", null, (_, _) => ExitThread());
        menu.Opening += (_, _) => _runOnStartupItem.Checked = IsStartupEnabled();

        _applicationIcon = LoadApplicationIcon();
        _trayIcon = new NotifyIcon
        {
            ContextMenuStrip = menu,
            Icon = _applicationIcon,
            Text = "LorWM window manager",
            Visible = true,
        };

        _hotkeyWindow = new HotkeyWindow(HandleHotkey, HotkeyDefinition.All);
    }

    private static Icon LoadApplicationIcon()
    {
        using var stream = typeof(TrayApplicationContext).Assembly
            .GetManifestResourceStream("LorWM.Assets.LorWM.ico");
        if (stream is null)
        {
            return (Icon)SystemIcons.Application.Clone();
        }

        using var resourceIcon = new Icon(stream);
        return (Icon)resourceIcon.Clone();
    }

    private bool IsStartupEnabled()
    {
        try
        {
            return _startupRegistration.IsEnabled;
        }
        catch
        {
            return false;
        }
    }

    private void ToggleRunOnStartup(object? sender, EventArgs eventArgs)
    {
        var enabled = !_runOnStartupItem.Checked;

        try
        {
            _startupRegistration.SetEnabled(enabled);
            _runOnStartupItem.Checked = enabled;
        }
        catch (Exception exception)
        {
            _trayIcon.ShowBalloonTip(
                5000,
                "LorWM could not update the startup setting",
                exception.Message,
                ToolTipIcon.Warning);
        }
    }

    private void HandleHotkey(HotkeyAction action)
    {
        try
        {
            _windowManager.Execute(action);
        }
        catch (Exception exception)
        {
            _trayIcon.ShowBalloonTip(5000, "LorWM could not move the window", exception.Message, ToolTipIcon.Warning);
        }
    }

    protected override void ExitThreadCore()
    {
        _hotkeyWindow.Dispose();
        _runOnStartupItem.Click -= ToggleRunOnStartup;
        _trayIcon.Visible = false;
        _trayIcon.ContextMenuStrip?.Dispose();
        _trayIcon.Dispose();
        _applicationIcon.Dispose();
        base.ExitThreadCore();
    }
}
