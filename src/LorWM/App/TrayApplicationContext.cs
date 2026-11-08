using LorWM.Windows;

namespace LorWM.App;

internal sealed class TrayApplicationContext : ApplicationContext
{
    private readonly NotifyIcon _trayIcon;
    private readonly HotkeyWindow _hotkeyWindow;
    private readonly WindowManager _windowManager = new();

    public TrayApplicationContext()
    {
        var menu = new ContextMenuStrip();
        menu.Items.Add("Exit LorWM", null, (_, _) => ExitThread());

        _trayIcon = new NotifyIcon
        {
            ContextMenuStrip = menu,
            Icon = SystemIcons.Application,
            Text = "LorWM window manager",
            Visible = true,
        };

        _hotkeyWindow = new HotkeyWindow(HandleHotkey, HotkeyDefinition.All);
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
        _trayIcon.Visible = false;
        _trayIcon.ContextMenuStrip?.Dispose();
        _trayIcon.Dispose();
        base.ExitThreadCore();
    }
}
