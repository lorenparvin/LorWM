using Microsoft.Win32;
using System.Reflection;

namespace LorWM.App;

internal sealed class StartupRegistration
{
    private const string RunKeyPath = @"Software\Microsoft\Windows\CurrentVersion\Run";
    private const string StartupApprovedKeyPath = @"Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run";
    private const string ValueName = "LorWM";

    private readonly string _command;

    public StartupRegistration()
    {
        _command = CreateCommand(
            Environment.ProcessPath ?? throw new InvalidOperationException("The LorWM executable path is unavailable."),
            Assembly.GetEntryAssembly()?.Location);
    }

    public bool IsEnabled
    {
        get
        {
            using var runKey = Registry.CurrentUser.OpenSubKey(RunKeyPath);
            if (runKey?.GetValue(ValueName) is not string command
                || !command.Equals(_command, StringComparison.OrdinalIgnoreCase))
            {
                return false;
            }

            using var startupApprovedKey = Registry.CurrentUser.OpenSubKey(StartupApprovedKeyPath);
            return IsStartupApproved(startupApprovedKey?.GetValue(ValueName));
        }
    }

    public void SetEnabled(bool enabled)
    {
        if (enabled)
        {
            using var key = Registry.CurrentUser.CreateSubKey(RunKeyPath, writable: true);
            key.SetValue(ValueName, _command, RegistryValueKind.String);
            ClearStartupApproval();
            return;
        }

        using var existingKey = Registry.CurrentUser.OpenSubKey(RunKeyPath, writable: true);
        existingKey?.DeleteValue(ValueName, throwOnMissingValue: false);
        ClearStartupApproval();
    }

    internal static bool IsStartupApproved(object? value) =>
        value is not byte[] { Length: > 0 } approval || (approval[0] & 1) == 0;

    internal static string CreateCommand(string processPath, string? entryAssemblyPath)
    {
        var command = Quote(processPath);
        if (Path.GetFileNameWithoutExtension(processPath).Equals("dotnet", StringComparison.OrdinalIgnoreCase)
            && !string.IsNullOrWhiteSpace(entryAssemblyPath))
        {
            command += $" {Quote(entryAssemblyPath)}";
        }

        return command;
    }

    private static string Quote(string path) => $"\"{path}\"";

    private static void ClearStartupApproval()
    {
        using var key = Registry.CurrentUser.OpenSubKey(StartupApprovedKeyPath, writable: true);
        key?.DeleteValue(ValueName, throwOnMissingValue: false);
    }
}
