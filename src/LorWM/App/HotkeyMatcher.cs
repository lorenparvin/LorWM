using LorWM.Windows;

namespace LorWM.App;

internal sealed class HotkeyMatcher
{
    private const uint ModifierMask =
        NativeMethods.ModAlt |
        NativeMethods.ModControl |
        NativeMethods.ModShift |
        NativeMethods.ModWin;

    private readonly Dictionary<Keys, List<HotkeyDefinition>> _definitionsByTrigger;

    internal HotkeyMatcher(IEnumerable<HotkeyDefinition> definitions)
    {
        _definitionsByTrigger = definitions
            .GroupBy(definition => definition.Key)
            .ToDictionary(group => group.Key, group => group.ToList());
    }

    internal HotkeyDefinition? Match(Keys trigger, IReadOnlySet<Keys> pressedKeys)
    {
        if (!_definitionsByTrigger.TryGetValue(trigger, out var candidates))
        {
            return null;
        }

        var activeModifiers = GetActiveModifiers(pressedKeys);
        return candidates.FirstOrDefault(definition =>
            (definition.Modifiers & ModifierMask) == activeModifiers);
    }

    internal static uint GetActiveModifiers(IReadOnlySet<Keys> pressedKeys)
    {
        uint modifiers = 0;

        if (ContainsAny(pressedKeys, Keys.Menu, Keys.LMenu, Keys.RMenu))
        {
            modifiers |= NativeMethods.ModAlt;
        }

        if (ContainsAny(pressedKeys, Keys.ControlKey, Keys.LControlKey, Keys.RControlKey))
        {
            modifiers |= NativeMethods.ModControl;
        }

        if (ContainsAny(pressedKeys, Keys.ShiftKey, Keys.LShiftKey, Keys.RShiftKey))
        {
            modifiers |= NativeMethods.ModShift;
        }

        if (ContainsAny(pressedKeys, Keys.LWin, Keys.RWin))
        {
            modifiers |= NativeMethods.ModWin;
        }

        return modifiers;
    }

    private static bool ContainsAny(IReadOnlySet<Keys> pressedKeys, params Keys[] keys) =>
        keys.Any(pressedKeys.Contains);
}
