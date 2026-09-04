# Reborn

A dark, minimalist UI library for Roblox, implemented in a single Luau module.

![version](https://img.shields.io/badge/version-v0.3.0-0070f3)

## Features

- Draggable, resizable window with minimize and viewport snapping
- Sidebar tabs with one- and two-column layouts
- Toggles, sliders, dropdowns, keybinds, color pickers, text inputs, buttons, paragraphs
- Toast notifications
- Configurable theme
- Randomized instance names, hidden parenting (`gethui` / `protect_gui`), no console output
- Zero dependencies — plain instances only, no assets or external fonts

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

local Main = Window:Tab("Main")
local Section = Main:Section("Overview")

Section:Paragraph("Hello from Reborn.")
Section:Button({
    Text = "Show notification",
    Primary = true,
    Callback = function()
        Reborn:Notify("Hi", "It works.")
    end,
})

local Visuals = Window:Tab("Visuals")
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
| `Window:Tab(name) -> Tab` | Adds a sidebar tab. The first tab is active by default. |
| `Window:Notify(config)` | Same as `Reborn:Notify`. |
| `Window:Search(query)` | Filters rows by text. `""` clears the filter. |
| `Window:SetTitle(text)` | Updates the header title. |
| `Window:Toggle()` / `Window:SetVisible(bool)` | Hides or reopens the window. |
| `Window:Minimize()` | Collapses the window to its header bar. |
| `Window:Destroy()` | Destroys the ScreenGui and disconnects input. |

### Tab

| Method | Description |
| --- | --- |
| `Tab:Section(name, badge?) -> Section` | Adds a section. `badge` renders a small chip next to the title. |
| `Tab:SetColumns(2)` | Switches the page to a two-column layout. Existing sections are redistributed. |

### Section

Every component takes a config table and returns an object with a `Set` method. `Set(value, fire)` re-fires the callback only when `fire` is `true`. All config fields are optional; omitted values fall back to defaults (e.g. sliders default to `0–100`, dropdowns select the first option).

Each component also accepts a string with an optional callback:

```lua
Section:Toggle("Enable ESP", function(value) end)
Section:Button("Rejoin", function() end)
Section:Paragraph("Some text.")
```

| Component | Config | Object |
| --- | --- | --- |
| `Toggle` | `Text`, `Value` (bool), `Callback(value)` | `Set(value, fire?)` |
| `Slider` | `Text`, `Min`, `Max`, `Value`, `Suffix`, `Callback(value)` | `Set(value, fire?)` |
| `Dropdown` | `Text`, `Options` (list), `Value`, `Callback(selected)` | `Set(value, fire?)` |
| `Keybind` | `Text`, `Value`, `Callback(name, input, gameProcessed)` | `Set(name)` |
| `ColorPicker` | `Text`, `Value` (`"#RRGGBB"` or `Color3`), `Callback(hex, color3)` | `Set(hex, fire?)` |
| `Input` | `Text`, `Value`, `Placeholder`, `Live` (bool), `Callback(text, enterPressed)` | `Set(text)` |
| `Button` | `Text`, `Primary` (bool), `Callback()` | `Set(text)` |
| `Paragraph` | `Text` | `Set(text)` |

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
