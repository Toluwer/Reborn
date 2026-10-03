# Reborn

A dark, minimalist UI library for Roblox, implemented in a single Luau module.

![version](https://img.shields.io/badge/version-v0.8.0-0070f3)

## Features

- Draggable, resizable window with minimize and viewport snapping
- Sidebar tabs with optional icons and one- or two-column layouts
- Toggles, sliders, dropdowns, keybinds, color pickers, text inputs, buttons, paragraphs
- Multi-select dropdowns, keybind modes (`Always` / `Toggle` / `Hold`), hover tooltips
- Config system: flags, `GetConfig` / `SetConfig`, JSON save / load / delete / list with executor filesystem persistence
- Toast notifications (including sticky ones via `Duration <= 0`)
- Configurable theme
- 120+ Lucide icons built in, preloaded on startup
- Randomized instance names, hidden parenting (`gethui` / `protect_gui`), no console output
- Zero runtime dependencies — one file, plain instances

## Installation

### Executor

```lua
local Reborn = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/Toluwer/Reborn/main/src/Reborn.luau"
))()
```

### Roblox Studio

Sync the included Rojo project:

```sh
rojo serve default.project.json
```

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Reborn = require(ReplicatedStorage:WaitForChild("Reborn"))
```

Alternatively, create a ModuleScript named `Reborn` and paste `src/Reborn.luau` into it.

## Quick start

```lua
local Reborn = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/Toluwer/Reborn/main/src/Reborn.luau"
))()

local Window = Reborn:CreateWindow({
    Title = "Reborn",
    Size = Vector2.new(700, 530),
})

local Main = Window:Tab("Main", "home")
local Section = Main:Section("Overview")

Section:Paragraph("Hello from Reborn.")
Section:Button({
    Text = "Show notification",
    Primary = true,
    Callback = function()
        Reborn:Notify("Hi", "It works.")
    end,
})

local Visuals = Window:Tab("Visuals", "eye")
Visuals:SetColumns(2)
Visuals:Section("ESP")
Visuals:Section("Environment")
```

A full example is available at [`examples/basic.luau`](examples/basic.luau).

## API

### Reborn

| Member / method | Description |
| --- | --- |
| `Reborn:CreateWindow(config) -> Window` | Creates the window. `config`: `Title`, `Size` (Vector2), `Theme` (partial overrides), `Parent` (ScreenGui/Instance). All fields optional. |
| `Reborn:Notify(config)` | Shows a toast. Accepts a table (`Title`, `Description`, `Type` (`"info" / "success" / "error"`), `Duration`) or a shorthand: `Notify("Title", "Description")`. |
| `Reborn.NotificationsEnabled` | Set `false` to mute all toasts. |
| `Reborn.Theme` | Default theme table. Pass overrides via `CreateWindow`. |
| `Reborn:Destroy()` | Destroys all windows and disconnects all input connections. |

### Window

| Method | Description |
| --- | --- |
| `Window:Tab(name, icon?) -> Tab` | Adds a sidebar tab with an optional icon name (see Icons below). The first tab is active by default. |
| `Window:Notify(config)` | Same as `Reborn:Notify`. |
| `Window:Search(query)` | Filters rows by label and dropdown option text. `""` clears the filter. |
| `Window:SetTitle(text)` | Updates the header title. |
| `Window:Toggle()` / `Window:SetVisible(bool)` | Hides or reopens the window. |
| `Window:Minimize()` | Collapses the window to its header bar. |
| `Window:GetConfig() -> table` | Snapshots all flagged element values into a `{ flag = value }` table. |
| `Window:SetConfig(table)` | Applies values by flag without firing callbacks. |
| `Window:SaveConfig(name) -> bool` | Encodes the current config as JSON. Persists to `reborn/<title>/<name>.json` via the executor's `writefile` when available, otherwise keeps it in memory. |
| `Window:LoadConfig(name) -> table?` | Reads and applies a saved config. Returns the applied table, or `nil` if not found. |
| `Window:DeleteConfig(name) -> bool` | Removes a saved config from disk and memory. |
| `Window:ListConfigs() -> {string}` | Lists known config names (filesystem entries when `listfiles` exists, plus in-memory ones). |
| `Window:Destroy()` | Destroys the ScreenGui and disconnects input. |

### Tab

| Method | Description |
| --- | --- |
| `Tab:Section(name, badge?) -> Section` | Adds a section. `badge` renders a small chip next to the title. |
| `Tab:SetColumns(2)` | Switches the page to a two-column layout. Existing sections are redistributed. |

### Icons

Tab icons and all built-in glyphs come from the [Lucide](https://lucide.dev) icon set, embedded as Roblox-hosted sprite assets:

```lua
Window:Tab("Combat", "crosshair")
Window:Tab("Visuals", "eye")
```

A selection of available names: `home`, `crosshair`, `eye`, `settings`, `swords`, `shield`, `target`, `zap`, `star`, `flame`, `skull`, `ghost`, `bomb`, `palette`, `sparkles`, `moon`, `sun`, `cpu`, `wifi`, `lock`, `key`, `terminal`, `radar`, `gamepad-2`, `joystick`, `users`, `heart`, `gem`, `crown`. Any unknown name is ignored and the tab renders without an icon.

### Section

Every component takes a config table and returns an object with a `Set` method. `Set(value, fire)` re-fires the callback only when `fire` is `true`. All config fields are optional; omitted values fall back to defaults (e.g. sliders default to `0–100`, dropdowns select the first option).

Every component also accepts `Tooltip` (hover hint), and every returned object exposes `SetVisible(bool)`, `SetTooltip(text)` and `Destroy()`. Dropdown options keep their original types — a numeric option comes back as a number.

Each component also accepts a string with an optional callback:

```lua
Section:Toggle("Enable ESP", function(value) end)
Section:Button("Rejoin", function() end)
Section:Paragraph("Some text.")
```

| Component | Config | Object |
| --- | --- | --- |
| `Toggle` | `Text`, `Value` (bool), `Flag`, `Tooltip`, `Callback(value)` | `Set(value, fire?)` |
| `Slider` | `Text`, `Min`, `Max`, `Step`, `Value`, `Suffix`, `Flag`, `Tooltip`, `Callback(value)` | `Set(value, fire?)` |
| `Dropdown` | `Text`, `Options` (list), `Value`, `Multi` (bool), `Flag`, `Tooltip`, `Callback(selected or list)` | `Set(value, fire?)` |
| `Keybind` | `Text`, `Value`, `Mode` (`"Always" / "Toggle" / "Hold"`), `Flag`, `Tooltip`, `Callback(...)` | `Set(name)` |
| `ColorPicker` | `Text`, `Value` (`"#RRGGBB"` or `Color3`), `Flag`, `Tooltip`, `Callback(hex, color3)` | `Set(hex, fire?)` |
| `Input` | `Text`, `Value`, `Placeholder`, `Live` (bool), `Flag`, `Tooltip`, `Callback(text, enterPressed)` | `Set(text)` |
| `Button` | `Text`, `Primary` (bool), `Tooltip`, `Callback()` | `Set(text)` |
| `Paragraph` | `Text` | `Set(text)` |

Keybind modes: `Always` fires `Callback(name, input, gameProcessed)` on every press. `Toggle` fires `Callback(active, name, ...)` — `true` on the first press, `false` on the next. `Hold` fires `Callback(true, ...)` on down and `Callback(false, ...)` on release. While listening, `Backspace` clears the bind and `Escape` cancels.

With `Multi = true`, `Value` and the callback carry an array of the selected options in option order; clicking an option toggles it and keeps the popover open.

```lua
local dd = Section:Dropdown({
    Text = "Target filters",
    Multi = true,
    Value = { "Players" },
    Options = { "Players", "NPCs", "Team check" },
    Callback = function(list) print(#list, "selected") end,
})
```

Flags feed the config system:

```lua
Section:Toggle({ Text = "Aim assist", Value = true, Flag = "aim" })
Section:Slider({ Text = "FOV", Min = 5, Max = 120, Value = 90, Flag = "fov" })

Window:SaveConfig("main")      -- writes reborn/<title>/main.json
Window:LoadConfig("main")      -- restores every flagged value
for _, name in ipairs(Window:ListConfigs()) do print(name) end
```

### Theme

Any subset of keys may be overridden:

```lua
Reborn:CreateWindow({
    Theme = {
        Accent = Color3.fromRGB(0, 112, 243),
        Text = Color3.fromRGB(237, 237, 237),
    },
})
```

| Key | Value | Key | Value |
| --- | --- | --- | --- |
| `Background` | `#000000` | `Line` | `#262626` |
| `Surface` | `#000000` | `LineStrong` | `#333333` |
| `Overlay` | `#111111` | `Text` | `#ededed` |
| `Chip` | `#1a1a1a` | `TextMuted` | `#a1a1a1` |
| `RowHover` | `#1a1a1a` | `TextFaint` | `#888888` |
| `OptionHover` | `#262626` | `Accent` | `#0070f3` |
| `Success` | `#29d391` | `AccentHover` | `#3291ff` |
| `Error` | `#ee0000` | `ToggleOff` | `#1f1f1f` |
| `Handle` | `#ffffff` | | |

## License

[MIT](LICENSE)

Icons are from [Lucide](https://lucide.dev) (ISC License), rendered via the [lucide-roblox](https://github.com/latte-soft/lucide-roblox) sprite assets.
