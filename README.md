# Reborn

Dark, minimalist UI library for Roblox — Vercel/Geist-inspired design language, ported pixel-for-pixel from an interactive HTML concept ([`concept/reborn-ui-concept.html`](concept/reborn-ui-concept.html)).

- **Pure black surfaces** (`#000000`), 1px hairline borders (`#262626` / `#333`)
- **One accent**: `#0070f3` (Vercel blue)
- **Geist-style type scale** (mapped to Gotham) with integer text sizes and line heights
- **8 / 6 / 4px radius scale**
- **Integer-pixel geometry** — the window snaps to even pixel sizes, rows/controls sit on whole pixels, so hairlines and corners rasterize clean
- **Single file** — works with `loadstring()` and `require()`

![components](https://img.shields.io/badge/components-toggle%20%7C%20slider%20%7C%20dropdown%20%7C%20keybind%20%7C%20color--picker%20%7C%20input%20%7C%20button-0a0a0a)
![status](https://img.shields.io/badge/status-v0.1.0-0070f3)

---

## Installation

### Executor (single file)

```lua
local Reborn = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/Toluwer/Reborn/main/src/Reborn.luau"
))()
```

### Roblox Studio (Rojo)

The repo ships a Rojo project. Sync it and the library lands at `ReplicatedStorage.Reborn`:

```sh
rojo serve default.project.json
```

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Reborn = require(ReplicatedStorage:WaitForChild("Reborn"))
```

(No Rojo? Create a ModuleScript named `Reborn`, paste `src/Reborn.luau` into it, same require.)

---

## Quick start

```lua
local Reborn = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/Toluwer/Reborn/main/src/Reborn.luau"
))()

local Window = Reborn:CreateWindow({
    Title = "Reborn",
    Size = Vector2.new(700, 530),   -- optional; auto-clamped to the viewport
    Profile = { Name = "guest_1337", Initial = "G" },
})

local Main = Window:Tab("Main")
local Section = Main:Section("Overview")

Section:Paragraph({ Text = "Hello from Reborn." })
Section:Button({
    Text = "Show notification",
    Primary = true,
    Callback = function()
        Reborn:Notify({ Title = "Hi", Description = "It works.", Type = "success" })
    end,
})

local Visuals = Window:Tab("Visuals")
Visuals:SetColumns(2)               -- two-column dashboard layout
Visuals:Section("ESP")              -- -> column 1
Visuals:Section("Environment")      -- -> column 2
```

Full runnable demo: [`examples/basic.luau`](examples/basic.luau).

---

## API reference

### Reborn

| Member / method | Description |
| --- | --- |
| `Reborn:CreateWindow(config) -> Window` | Creates the window (one per ScreenGui). `config`: `Title`, `Size` (Vector2), `Profile` (`{ Name, Initial }`), `Theme` (partial overrides), `Parent` (explicit ScreenGui/Instance). |
| `Reborn:Notify(config)` | Toast without needing a window reference. `config`: `Title`, `Description`, `Type` (`"info" / "success" / "error"`), `Duration`. |
| `Reborn.NotificationsEnabled` | Set `false` to mute all toasts. |
| `Reborn.Theme` | Default theme table (read-only reference — pass overrides via `CreateWindow`). |
| `Reborn:Destroy()` | Destroys all windows + disconnects all input connections. |

### Window

| Method | Description |
| --- | --- |
| `Window:Tab(name) -> Tab` | Adds a sidebar tab. The first tab is active by default. |
| `Window:Notify(config)` | Same as `Reborn:Notify`, scoped to this window's toast layer. |
| `Window:Search(query)` | Filters rows by text (same as the header search box). `""` clears. |
| `Window:SetTitle(text)` | Updates the header title. |
| `Window:Toggle()` / `Window:SetVisible(bool)` | Hide (fade + launcher pill) / reopen. |
| `Window:Minimize()` | Collapses the window to its header bar. |
| `Window:Destroy()` | Destroys the ScreenGui and disconnects input. |

### Tab

| Method | Description |
| --- | --- |
| `Tab:Section(name, badge?) -> Section` | Adds a section. `badge` renders a small accent chip next to the title (e.g. `"Beta"`). |
| `Tab:SetColumns(2)` | Switches the page to a **two-column layout** — sections flow side-by-side (Vercel dashboard grid, equal widths, 8px gutter). Call it any time; existing sections are redistributed. |

### Section — components

Every component takes a config table and returns an object with a `Set` method.

| Component | Config | Object |
| --- | --- | --- |
| `Toggle` | `Text`, `Value` (bool), `Callback(value)` | `Set(value, fire?)` |
| `Slider` | `Text`, `Min`, `Max`, `Value`, `Suffix` (e.g. `"ms"`), `Callback(value)` | `Set(value, fire?)` |
| `Dropdown` | `Text`, `Options` (list), `Value`, `Callback(selected)` | `Set(value, fire?)` |
| `Keybind` | `Text`, `Value` (`"Right Mouse"`, `"Right Shift"`, `"E"`, …), `Callback(name, input, gameProcessed)` — fires when the bound key is pressed | `Set(name)` |
| `ColorPicker` | `Text`, `Value` (`"#RRGGBB"` or `Color3`), `Callback(hex, color3)` — fires live while dragging | `Set(hex, fire?)` |
| `Input` | `Text`, `Value`, `Placeholder`, `Live` (bool), `Callback(text, enterPressed)` | `Set(text)` |
| `Button` | `Text`, `Primary` (bool — accent style), `Callback()` | `Set(text)` |
| `Paragraph` | `Text` | `Set(text)` |

`Set(value, fire)` only re-fires the callback when `fire` is `true`.

### Theme

```lua
Reborn:CreateWindow({
    Theme = {
        Accent = Color3.fromRGB(0, 112, 243),  -- any subset of keys
        Text   = Color3.fromRGB(237, 237, 237),
    },
})
```

Default values (each maps to the concept's CSS variables):

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

---

## Design notes

- **Pixel discipline**: the window is `round(down, min(700, 96vw), 2)` × `round(down, min(530, 88vh), 2)` — always even. All row heights, control sizes and paddings are integers; two-column widths are `(contentWidth - 8) / 2`, which stays whole because the geometry is kept even. Hairlines + small radii therefore rasterize without jaggies. Keep this invariant if you fork.
- **White is only control geometry** (toggle knob, slider handle) — accent color is always blue.
- The HTML concept in `concept/` is the living design reference: every CSS variable maps to a `Theme` key, every row is a `Frame + UICorner + UIStroke`, and the sidebar is a vertical list layout.

## Roadmap

- [ ] Slider keyboard (arrow-key) support
- [ ] `Window:SetScale` (UIScale) with integer snapping
- [ ] Config serialize/deserialize helpers
- [ ] Search: fuzzy matching

## License

[MIT](LICENSE)
