# LorWM

LorWM is a Windows-only, hotkey-driven window manager inspired by Rectangle for macOS. It is a clean C# implementation built as a lightweight WinForms tray application with no visible main window.

It uses a system-wide `WH_KEYBOARD_LL` hook so it can override Windows-reserved shortcuts, then moves ordinary top-level windows with `SetWindowPos`. It does not simulate input, inject DLLs, draw overlays, or inspect game processes.

## Hotkeys

| Hotkey | Action |
|---|---|
| Win + Alt + Left | Snap left; repeated presses cycle 1/2, 2/3, and 1/3 widths |
| Win + Alt + Right | Snap right with the same width cycle |
| Win + Alt + Up | Snap to the top half |
| Win + Alt + Down | Snap to the bottom half |
| Win + Alt + F | Fill the current monitor's work area |
| Ctrl + Alt + Left | Snap to the left third |
| Ctrl + Alt + Up | Snap to the middle third |
| Ctrl + Alt + Right | Snap to the right third |
| Win + Ctrl + Alt + Left | Fill the spatially adjacent monitor to the left |
| Win + Ctrl + Alt + Right | Fill the spatially adjacent monitor to the right |

Hotkeys require the exact listed modifiers. Holding a trigger key does not repeatedly move the window; release and press it again to advance the left/right width cycle.

## How it works

Windows reserves several of the original `Win + Alt` combinations, so they cannot reliably be claimed with `RegisterHotKey`. LorWM instead installs one `WH_KEYBOARD_LL` hook for the current desktop session.

The hook:

- Tracks modifier and trigger-key state without generating input.
- Matches only the configured combinations and passes unrelated keyboard events onward.
- Suppresses the key-down and key-up events for a matched trigger so Windows does not also perform its built-in action.
- Posts the matching action to the WinForms message loop immediately; no monitor discovery or window movement occurs inside the hook callback.
- Is removed with `UnhookWindowsHookEx` when LorWM exits.

The hook callback executes inside LorWM. It is not injected into other applications.

## Window and monitor behavior

- Snapping targets the monitor work area, leaving space for the taskbar and other app bars.
- Maximized windows are restored before LorWM applies a new position.
- The current monitor is the display with the largest intersection with the window's visible DWM frame. The nearest monitor is used as a fallback.
- Adjacent monitors are selected from their physical desktop coordinates rather than Windows enumeration order.
- Moving to another monitor fills that monitor's work area.
- At a desktop's leftmost or rightmost edge, monitor movement does nothing instead of wrapping around.
- Invisible resize borders are compensated for so the visible window frame aligns with the requested region.

## Build and run

Requirements:

- Windows 10 or Windows 11.
- .NET 10 SDK to build from source.
- .NET 10 Desktop Runtime to run a framework-dependent build.

```powershell
dotnet build LorWM.sln -c Release
dotnet run --project src/LorWM/LorWM.csproj -c Release
```

The release executable is written to `src/LorWM/bin/Release/net10.0-windows/LorWM.exe`.

LorWM appears in the notification area and does not open a main window. Right-click its tray icon and select **Exit LorWM** to stop it. Only one copy runs per Windows session.

## Releases

Because `main` requires pull requests, every push to `main` creates a SemVer-tagged GitHub Release. The first release uses the `VersionPrefix` declared in the application project (`0.1.0`). Later releases increment the latest strict `vMAJOR.MINOR.PATCH` tag's patch component by default.

For an intentional minor or major release, raise `VersionPrefix` in `src/LorWM/LorWM.csproj` as part of the pull request. When the declared version is higher than the latest release tag, the workflow uses it exactly instead of applying a patch increment.

Each release contains a self-contained `win-x64` ZIP, so users do not need to install the .NET runtime.

Run the dependency-free geometry, monitor-selection, and hotkey-matching checks with:

```powershell
dotnet run --project tests/LorWM.Tests/LorWM.Tests.csproj -c Release
```

## Architecture

- `App/` owns the tray lifetime, hotkey definitions, matching, and hidden message window.
- `Core/` contains platform-independent snapping geometry and spatial monitor selection.
- `Windows/` contains Win32 interop, monitor enumeration, DWM frame handling, and window placement.
- `tests/LorWM.Tests/` is a dependency-free executable test harness for the core algorithms and hotkey matcher.

The process is Per-Monitor V2 DPI-aware, so placement uses physical desktop coordinates correctly across mixed-DPI displays. Window placement uses `MonitorFromWindow`, `GetMonitorInfo`, `DwmGetWindowAttribute(DWMWA_EXTENDED_FRAME_BOUNDS)`, `GetWindowRect`, and `SetWindowPos`.

## Compatibility note

`WH_KEYBOARD_LL` is a documented Windows API and does not require DLL injection, but it is still a system-wide low-level keyboard hook. Software that treats any global input hook as sensitive may block or object to LorWM. No compatibility with a particular game or anti-cheat product is guaranteed.

LorWM normally runs without elevation. Windows may prevent a non-elevated process from moving windows owned by elevated applications.
