using System.ComponentModel;
using System.Runtime.InteropServices;
using LorWM.Windows;

namespace LorWM.App;

internal sealed class HotkeyWindow : NativeWindow, IDisposable
{
    private readonly HashSet<Keys> _pressedKeys = [];
    private readonly HashSet<Keys> _suppressedTriggerKeys = [];
    private readonly IReadOnlyDictionary<int, HotkeyDefinition> _definitionsById;
    private readonly Action<HotkeyAction> _handler;
    private readonly HotkeyMatcher _matcher;
    private readonly NativeMethods.LowLevelKeyboardProcedure _hookProcedure;
    private nint _hookHandle;
    private bool _disposed;

    public HotkeyWindow(Action<HotkeyAction> handler, IEnumerable<HotkeyDefinition> definitions)
    {
        _handler = handler;
        _definitionsById = definitions.ToDictionary(definition => definition.Id);
        _matcher = new HotkeyMatcher(_definitionsById.Values);
        _hookProcedure = HookProcedure;

        CreateHandle(new CreateParams
        {
            Caption = "LorWM Hotkey Sink",
            Parent = NativeMethods.MessageOnlyWindow,
        });

        _hookHandle = NativeMethods.SetWindowsHookEx(
            NativeMethods.WhKeyboardLowLevel,
            _hookProcedure,
            0,
            0);
        if (_hookHandle == 0)
        {
            DestroyHandle();
            throw new Win32Exception();
        }
    }

    private nint HookProcedure(int code, nint wParam, nint lParam)
    {
        if (code != NativeMethods.HookAction)
        {
            return NativeMethods.CallNextHookEx(_hookHandle, code, wParam, lParam);
        }

        try
        {
            var message = unchecked((uint)wParam.ToInt64());
            var isKeyDown = message is NativeMethods.WmKeyDown or NativeMethods.WmSystemKeyDown;
            var isKeyUp = message is NativeMethods.WmKeyUp or NativeMethods.WmSystemKeyUp;
            if (!isKeyDown && !isKeyUp)
            {
                return NativeMethods.CallNextHookEx(_hookHandle, code, wParam, lParam);
            }

            var eventData = Marshal.PtrToStructure<NativeMethods.LowLevelKeyboardInput>(lParam);
            var key = (Keys)eventData.VirtualKeyCode;

            if (isKeyUp)
            {
                _pressedKeys.Remove(key);
                return _suppressedTriggerKeys.Remove(key)
                    ? 1
                    : NativeMethods.CallNextHookEx(_hookHandle, code, wParam, lParam);
            }

            var isFirstKeyDown = _pressedKeys.Add(key);
            if (_suppressedTriggerKeys.Contains(key))
            {
                return 1;
            }

            if (!isFirstKeyDown)
            {
                return NativeMethods.CallNextHookEx(_hookHandle, code, wParam, lParam);
            }

            var definition = _matcher.Match(key, _pressedKeys);
            if (definition is null ||
                !NativeMethods.PostMessage(Handle, NativeMethods.WmAppHotkey, definition.Id, 0))
            {
                return NativeMethods.CallNextHookEx(_hookHandle, code, wParam, lParam);
            }

            _suppressedTriggerKeys.Add(key);
            return 1;
        }
        catch
        {
            return NativeMethods.CallNextHookEx(_hookHandle, code, wParam, lParam);
        }
    }

    protected override void WndProc(ref Message message)
    {
        if (message.Msg == NativeMethods.WmAppHotkey)
        {
            if (_definitionsById.TryGetValue(message.WParam.ToInt32(), out var definition))
            {
                _handler(definition.Action);
            }
        }

        base.WndProc(ref message);
    }

    public void Dispose()
    {
        if (_disposed)
        {
            return;
        }

        if (_hookHandle != 0)
        {
            NativeMethods.UnhookWindowsHookEx(_hookHandle);
            _hookHandle = 0;
        }

        _pressedKeys.Clear();
        _suppressedTriggerKeys.Clear();
        DestroyHandle();
        _disposed = true;
    }
}
