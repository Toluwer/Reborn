# Reborn

A Luau UI library with tabs, sections, configurable controls and notifications.

## Usage

```lua
local Reborn = loadstring(game:HttpGet("https://raw.githubusercontent.com/Toluwer/Reborn/main/src/Reborn.luau"))()

local Window = Reborn:CreateWindow({
    Title = "Example",
    Size = Vector2.new(700, 530),
})

local Main = Window:Tab("Main", "home")
local Section = Main:Section("General")

Section:Toggle({
    Text = "Enabled",
    Value = false,
    Flag = "enabled",
    Callback = function(value)
        print(value)
    end,
})

Section:Button({
    Text = "Notify",
    Callback = function()
        Reborn:Notify("Reborn", "Ready")
    end,
})
```

[Full example](examples/basic.luau)

## Window

| Method | Description |
| --- | --- |
| `Tab(name, icon?)` | Create a tab. |
| `SetTitle(text)` | Change the window title. |
| `SetVisible(visible)` | Show or hide the window. |
| `Toggle()` | Minimize or restore the window. |
| `Minimize()` | Minimize to the pill. |
| `Search(query)` | Filter components. Pass an empty string to clear. |
| `Notify(config)` | Show a notification. |
| `Destroy()` | Destroy the window. |

`CreateWindow` accepts `Title`, `Size`, `Theme` and `Parent`. Minimized windows sharing a GUI parent arrange their pills in centered rows, including windows created by separate copies of the library.

Use `Reborn:Unload()` to unload the library.

## Widgets

```lua
local Widget = Reborn:CreateWidget({
    Title = "Controls",
    Width = 260,
    Position = Vector2.new(24, 80),
})

Widget:Toggle({ Text = "Enabled", Value = true })
Widget:Slider({ Text = "Intensity", Min = 0, Max = 100, Value = 65 })
```

Widgets support all components directly, with no tabs or sections. Multiple widgets can be open at once. The header collapses the widget; closing destroys it without confirmation.

Options: `Title`, `Id`, `Width`, `MinWidth`, `MaxWidth`, `MaxHeight`, `Position` (Vector2), `Resizable`, `Theme`, `Parent`, `OnClose`.

Methods: `SetCollapsed(bool)`, `ToggleCollapsed()`, `Minimize()`, `SetVisible(bool)`, `SetTitle(text)`, `SetPosition(Vector2)`, `SetWidth(number)`, `Notify(config)`, `Close()`, `Destroy()`.

Use `AddCleanup(function)` to release external connections or tasks when a widget closes. Configuration methods work per widget, using its `Id` or initial title.

[Widget example](examples/widgets.luau)

## Tabs and sections

```lua
local Settings = Window:Tab("Settings", "settings")
Settings:SetColumns(2)

local General = Settings:Section("General")
local Appearance = Settings:Section("Appearance")
```

## Components

| Component | Options |
| --- | --- |
| `Button` | Text, Primary, Width, Callback |
| `Toggle` | Text, Value, Callback |
| `Slider` | Text, Min, Max, Step, Value, Suffix, Format, Callback |
| `ProgressBar` | Text, Min, Max, Value, Color, ShowValue, Suffix, Format, Duration, Flag |
| `Dropdown` | Text, Options, Value, Multi, Callback |
| `Keybind` | Text, Value, Mode, Callback |
| `ColorPicker` | Text, Value, Callback |
| `Input` | Text, Value, Placeholder, Live, Debounce, Callback |
| `Paragraph` | Text |
| `Image` | Image, Height, ScaleType, CornerRadius, Title, Subtitle, Callback |
| `List` | Text, Height, MaxHeight, SelectionChanged |
| `Row` | Gap |

Components support `SetEnabled(bool)`, `SetVisible(bool)`, `SetTooltip(text)` and `Destroy()`.

Use `Set(value, true)` to update a toggle, slider, dropdown or color picker and fire its callback. Omit the second argument for a silent update.

Additional methods:

- Slider: `SetRange(min, max)`
- ProgressBar: `Set(value, animate?)`, `SetRange(min, max)`, `SetText(text)`, `SetColor(color)`
- Dropdown: `SetOptions(options)`
- Image: `SetImage(source)`, `SetTitle(text)`, `SetSubtitle(text)`
- List: `Add(item)`, `Remove(index)`, `Clear()`, `SetItems(items)`, `SetSelected(index, fire?)`

Progress bars are read-only. `Set(value)` animates to the new value; `Set(value, false)` updates immediately. The default label displays a percentage of the range. Use `Suffix` or `Format(value, fraction)` to display a custom value.

List items accept a string or a table with `Text`, `Secondary`, `Icon` and `Trailing`.

## Configuration

Assign a unique `Flag` to each control you want to save.

```lua
Section:Slider({
    Text = "Intensity",
    Min = 0,
    Max = 100,
    Value = 50,
    Flag = "intensity",
})

Window:SaveConfig("default")
Window:LoadConfig("default")
```

| Method | Description |
| --- | --- |
| `GetConfig()` | Return flagged values. |
| `SetConfig(values)` | Apply flagged values. |
| `SaveConfig(name)` | Save a profile. |
| `LoadConfig(name)` | Load a profile. |
| `DeleteConfig(name)` | Delete a profile. |
| `ListConfigs()` | List saved profiles. |

Profiles include hidden and disabled controls with a `Flag`. Loading applies values without firing callbacks. Profiles are saved under `reborn/<title>/<name>.json` when filesystem access is available; otherwise they are kept in memory.

## Theme

Override theme colors when creating a window.

```lua
local Window = Reborn:CreateWindow({
    Title = "Example",
    Theme = {
        Accent = Color3.fromRGB(44, 103, 197),
    },
})
```

See [Theme.luau](lib/Theme.luau) for the default colors.

## Credits

Icons: [Lucide](https://lucide.dev) (ISC), [lucide-roblox](https://github.com/latte-soft/lucide-roblox).
