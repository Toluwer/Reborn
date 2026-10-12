# Reborn

A dark, minimalist UI library for Roblox, implemented in a single Luau module.

![version](https://img.shields.io/badge/version-v0.9.3-0070f3)

## Features

- Draggable, resizable window with a pill minimize and viewport snapping
- Drag-and-drop HUD overlays with live-updating text lines (`CreateHUD`)
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
| `Reborn:CreateHUD(config) -> HUD` | Creates a floating HUD overlay outside the window. See the HUD section below. |
| `Reborn:Notify(config)` | Shows a toast. Accepts a table (`Title`, `Description`, `Type` (`"info" / "success" / "error"`), `Duration`) or a shorthand: `Notify("Title", "Description")`. |
| `Reborn.NotificationsEnabled` | Set `false` to mute all toasts. |
| `Reborn.Theme` | Default theme table. Pass overrides via `CreateWindow`. |
| `Reborn:Destroy()` | Destroys all windows and HUDs and disconnects all input connections. |

### Window

| Method | Description |
| --- | --- |
| `Window:Tab(name, icon?) -> Tab` | Adds a sidebar tab with an optional icon name (see Icons below). The first tab is active by default. |
| `Window:Notify(config)` | Same as `Reborn:Notify`. |
| `Window:Search(query)` | Filters rows by label and dropdown option text. `""` clears the filter. |
| `Window:SetTitle(text)` | Updates the header title. |
| `Window:Toggle()` / `Window:SetVisible(bool)` | Hides or reopens the window. Restores from the minimized pill first. |
| `Window:Minimize()` | Morphs the window into a compact pill docked at the top-center of the screen — no outline, no window buttons, fully rounded pill radius. Click the pill (or hover it) to expand back. |
| `Window.ToggleKey = "Right Shift"` | Optional. Key name shown in the pill's hover hint (`"Click or Right Shift to open"`). Set it to your UI-toggle keybind. |
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

### HUD

```lua
local hud = Reborn:CreateHUD({
    Title = "LootSight",                          -- small muted header line
    Lines = {                                      -- stacked live text lines
        { Text = "$12,400 in range - 87 items", Color = "Text",  TextSize = 15 },
        { Text = "Best: Sword  $8,000 (34 studs)", Color = "Text" },
        { Text = "You carry: $2,150 (6 items)",   Color = "Accent" },
    },
    Position = "TopCenter",   -- Top/Bottom x Left/Center/Right presets
    Draggable = true,          -- drag to reposition, position remembered
})
```

A HUD is a self-contained overlay in its own ScreenGui — it lives outside the window (no window required), renders as a card in the window's surface family (`Surface` fill, stroked `LineStrong` border, feather-smoothed corners) that hugs its content, and stacks an optional small muted `Title` above the `Lines` list. Every line is a table (`Text`, `Color`, `TextSize`) or a plain string; `Color` accepts any theme key (`"Text"`, `"TextMuted"`, `"Accent"`, `"Success"`, ...) or a `Color3`, and `TextSize` defaults to 13 (clamped 8-24). `Position` presets combine Top/Bottom with Left/Center/Right (`"TopLeft"`, `"BottomCenter"`, ...; default `"TopCenter"`, 12px from the screen edge), and `Draggable` defaults to `true` — dragging converts the card to pixel coordinates, keeps it on screen, and the dropped position is remembered for the rest of the HUD's lifetime (a later `SetVisible(false)` / `SetVisible(true)` cycle restores it; re-running the script creates a fresh HUD at the preset).

| Method | Description |
| --- | --- |
| `hud:SetLine(i, text)` | Updates line `i` in place. Accepts a string (text only) or a line table (`Text` / `Color` / `TextSize` restyled live). Returns `false` for out-of-range indexes. |
| `hud:SetLines(table)` | Replaces every line (strings or tables). |
| `hud:SetTitle(text)` | Updates the header line, creating it on demand if the HUD was made without one. |
| `hud:SetVisible(bool)` | Hides / shows the card, restoring the last dragged position. |
| `hud:Destroy()` | Destroys the ScreenGui and disconnects the drag connections. |

Multiple HUDs can coexist with each other and with windows (`Reborn:Destroy()` cleans up everything); each carries its own optional `Theme` override table and `Parent` like `CreateWindow` does.

### Icons

Tab icons and all built-in glyphs come from the [Lucide](https://lucide.dev) icon set, embedded as Roblox-hosted sprite assets:

```lua
Window:Tab("Combat", "crosshair")
Window:Tab("Visuals", "eye")
```

A selection of available names: `home`, `crosshair`, `eye`, `settings`, `swords`, `shield`, `target`, `zap`, `star`, `flame`, `skull`, `ghost`, `bomb`, `palette`, `sparkles`, `moon`, `sun`, `cpu`, `wifi`, `lock`, `key`, `terminal`, `radar`, `gamepad-2`, `joystick`, `users`, `heart`, `gem`, `crown`. Any unknown name is ignored and the tab renders without an icon.

### Section

Every component takes a config table and returns an object with a `Set` method (`Image` returns `SetImage`, `List` returns `SetSelected`, and both also answer to `Set` for the config system). `Set(value, fire)` re-fires the callback only when `fire` is `true`. All config fields are optional; omitted values fall back to defaults (e.g. sliders default to `0–100`, dropdowns select the first option).

Every component also accepts `Tooltip` (hover hint), and every returned object exposes `SetVisible(bool)`, `SetTooltip(text)`, `Destroy()` and `SetEnabled(bool)`. Dropdown options keep their original types — a numeric option comes back as a number.

Each component also accepts a string with an optional callback:

```lua
Section:Toggle("Enable ESP", function(value) end)
Section:Button("Rejoin", function() end)
Section:Paragraph("Some text.")
Section:Image("rbxassetid://12345678")
```

| Component | Config | Object |
| --- | --- | --- |
| `Toggle` | `Text`, `Value` (bool), `Flag`, `Tooltip`, `Callback(value)` | `Set(value, fire?)` |
| `Slider` | `Text`, `Min`, `Max`, `Step`, `Value`, `Suffix`, `Format` (fn), `Flag`, `Tooltip`, `Callback(value)` | `Set(value, fire?)`, `SetRange(min, max)` |
| `Dropdown` | `Text`, `Options` (list), `Value`, `Multi` (bool), `Flag`, `Tooltip`, `Callback(selected or list)` | `Set(value, fire?)`, `SetOptions(options)` |
| `Keybind` | `Text`, `Value`, `Mode` (`"Always" / "Toggle" / "Hold"`), `Flag`, `Tooltip`, `Callback(...)` | `Set(name)` |
| `ColorPicker` | `Text`, `Value` (`"#RRGGBB"` or `Color3`), `Flag`, `Tooltip`, `Callback(hex, color3)` | `Set(hex, fire?)` |
| `Input` | `Text`, `Value`, `Placeholder`, `Live` (bool), `Debounce` (seconds), `Flag`, `Tooltip`, `Callback(text, enterPressed)` | `Set(text)` |
| `Button` | `Text`, `Primary` (bool), `Width`, `Tooltip`, `Callback()` | `Set(text)` |
| `Paragraph` | `Text` | `Set(text)` |
| `Image` | `Image` (asset id number, id string, or URL), `Height`, `ScaleType`, `CornerRadius`, `Tooltip`, `Callback()` | `SetImage(source)` |
| `List` | `Text`, `Height`, `MaxHeight`, `Flag`, `Tooltip`, `SelectionChanged(item, index)` | `Add(item)`, `Remove(index)`, `Clear()`, `SetItems(table)`, `SetSelected(index?, fire?)` |

Images render as full-width plates that follow the window through resize and drag. `Image` accepts a plain asset id number (`12345678`), a bare digit string, or any URL — `rbxassetid://`, `rbxthumb://`, `rbxasset://` and `https://` pass through untouched, while numbers and digit strings are normalized to `rbxassetid://`. `ScaleType` defaults to `Crop` (fills the plate with rounded corners), `Fit` letterboxes inside the plate, `Stretch` distorts to fill. While the asset loads, the plate reads as the standard surface placeholder. A `Callback` turns the plate into a clickable image button with a subtle transparency lift on hover. Flagged images join the config system — `GetConfig` snapshots the applied source string and `SetConfig` restores it.

`SetEnabled(false)` works on every element — Button, Toggle, Slider, Dropdown, Keybind, ColorPicker, Input, Image, List and Paragraph. A disabled element is visibly dimmed (labels at 50% transparency, muted plates), swallows all input (no hover effects, no clicks, keybinds stop firing, inputs stop accepting text, open popovers close and stay closed) and blocks its callback entirely — including programmatic `Set(value, true)`. `SetEnabled(true)` restores appearance and interactivity.

The List element is a scrollable container for rows that change at runtime. Items are tables — `Text` (primary), `Secondary` (smaller muted line), `Icon` (icon name), `Trailing` (right-aligned text) — or plain strings. `Add` returns the new index and touches nothing else; `Remove`/`Clear`/`SetItems` keep the selection consistent (removing the selected row clears it, earlier selections shift down). The selected row carries an accent bar and an accent tint; clicking a row fires `SelectionChanged(item, index)` (also accepted as `Callback`), and `SetSelected(index, fire?)` follows the usual Set convention — pass `nil` to deselect. The plate auto-grows with content from `Height` (default 120, min 46) up to `MaxHeight` (default 260), then scrolls; hundreds of rows are fine — each `Add` is one frame plus a height recompute, and the canvas sizes itself. A flagged List snapshots its selected index (absent when nothing is selected).

`Section:Row()` returns a horizontal container that packs 2-4 elements side by side: `row:Button(...)`, `row:Toggle(...)`, `row:Dropdown(...)`, `row:Keybind(...)` and `row:ColorPicker(...)` take the same configs as their section counterparts. Children without an explicit `Width` share the row evenly (`1/n` each); an explicit `Width` opts a child out of the split. `Gap` sets the spacing (default 8). `SetVisible`/`Destroy` work on the whole row — destroying a row destroys its children.

`Width` also works on standalone elements: a number between 0 and 1 is a fraction of the section width, a number of 1 or more is fixed pixels, `"auto"` hugs the text (Button only), and the default stays full width so existing scripts are unaffected.

Sliders: `Format = function(value) return string end` replaces the value label entirely (the `Suffix` is not appended), and `SetRange(min, max)` changes the range at runtime — the current value is re-snapped and clamped into the new range and re-rendered without firing the callback; invalid ranges (max <= min) are ignored and return `false`.

Inputs: `Debounce = seconds` (with `Live = true`) batches keystroke callbacks — the callback fires once, `Debounce` seconds after the last keystroke; pressing Enter or blurring the field fires immediately and cancels the pending update. Dropdowns: `SetOptions(options)` repopulates after creation — the current value is kept when still present (multi keeps the intersection), otherwise the first option is selected silently, the popover height and search index rebuild, and an open popover closes.

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
