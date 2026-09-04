--[[
        Reborn v0.1.0 — dark minimalist UI library for Roblox
        -----------------------------------------------------
        Vercel/Geist-inspired design language: pure #000 surfaces, 1px hairlines,
        one blue accent (#0070f3), Geist-style type scale (mapped to Gotham),
        8/6/4px radii and integer-pixel geometry throughout (every measurement is
        the exact port of the HTML concept in /concept/reborn-ui-concept.html).

        Single-file on purpose — works with loadstring() and require():

          local Reborn = loadstring(game:HttpGet(
            "https://raw.githubusercontent.com/Toluwer/Reborn/main/src/Reborn.luau"
          ))()

          local Window = Reborn:CreateWindow({ Title = "Reborn" })
          local Main   = Window:Tab("Main")
          local Sec    = Main:Section("Overview")
          Sec:Toggle({ Text = "Enable feature", Callback = function(v) end })

        Repo: https://github.com/Toluwer/Reborn
]]

-- ============================================================
--  Services
-- ============================================================
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local TextService = game:GetService("TextService")
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")

local Reborn = {
        Version = "0.1.0",
        NotificationsEnabled = true,
        _windows = {},
}

-- ============================================================
--  Theme — maps 1:1 to the concept's CSS variables
-- ============================================================
local DEFAULT_THEME = {
        Background   = Color3.fromRGB(0, 0, 0),     -- page black
        Surface      = Color3.fromRGB(0, 0, 0),     -- window / sidebar / content
        Overlay      = Color3.fromRGB(17, 17, 17),  -- popovers / toasts / fields (#111)
        Chip         = Color3.fromRGB(26, 26, 26),  -- keybind chip bg (#1a1a1a)
        RowHover     = Color3.fromRGB(26, 26, 26),  -- row + tab hover fill (#1a1a1a)
        OptionHover  = Color3.fromRGB(38, 38, 38),  -- dropdown option hover (#262626)
        Line         = Color3.fromRGB(38, 38, 38),  -- hairline dividers (#262626)
        LineStrong   = Color3.fromRGB(51, 51, 51),  -- component borders (#333)
        Text         = Color3.fromRGB(237, 237, 237),
        TextMuted    = Color3.fromRGB(161, 161, 161),
        TextFaint    = Color3.fromRGB(136, 136, 136),
        Accent       = Color3.fromRGB(0, 112, 243),  -- #0070f3
        AccentHover  = Color3.fromRGB(50, 145, 255), -- #3291ff
        Success      = Color3.fromRGB(41, 211, 145), -- #29d391
        Error        = Color3.fromRGB(238, 0, 0),    -- #ee0000
        ToggleOff    = Color3.fromRGB(31, 31, 31),   -- #1f1f1f
        Handle       = Color3.fromRGB(255, 255, 255),-- knob / slider handle (control geometry)
}

Reborn.Theme = DEFAULT_THEME

-- Geist -> Gotham type scale (sizes stay integers)
local F = {
        Regular  = Enum.Font.Gotham,
        Medium   = Enum.Font.GothamMedium,
        Semibold = Enum.Font.GothamSemibold,
        Bold     = Enum.Font.GothamBold,
        Mono     = Enum.Font.Code,
}

-- Geometry constants (px, ported from the concept)
local GEO = {
        WindowMaxW   = 700,
        WindowMaxH   = 530,
        WindowRadius = 8,
        Header       = 47,   -- 46px content + 1px divider
        HeaderPad    = 14,   -- left padding
        WinBtn       = 44,   -- caption button size (w)
        WinBtnH      = 36,
        SearchW      = 150,
        SearchH      = 32,
        Sidebar      = 155,  -- + 1px divider = 156
        TabH         = 34,
        ContentPadT  = 16,
        ContentPadS  = 18,
        ContentPadB  = 22,
        SectionGap   = 20,
        RowH         = 38,
        RowPad       = 12,
        RowGap       = 7,
        SwitchW      = 44,
        SwitchH      = 24,
        Knob         = 18,
        SliderH      = 61,
        SliderTrackH = 17,
        RailH        = 5,
        HandleD      = 13,
        OptH         = 30,
        ChipH        = 22,
        ChipMinW     = 46,
        Swatch       = 22,
        PopW         = 172, -- color picker popover
        SVH          = 92,
        HueH         = 10,
        FieldW       = 180,
        FieldH       = 30,
        ToastW       = 294,
        Launcher     = 46,
        GridGap      = 8,   -- two-column gutter
}

-- ============================================================
--  Utilities
-- ============================================================
local function rnd(x) return math.floor(x + 0.5) end
local function clamp(v, a, b)
        if v < a then return a elseif v > b then return b end
        return v
end

-- Element constructor
local function New(className, props)
        local inst = Instance.new(className)
        local parent = nil
        if props then
                for k, v in pairs(props) do
                        if k == "Parent" then parent = v else inst[k] = v end
                end
        end
        if parent then inst.Parent = parent end
        return inst
end

local function corner(inst, r)
        New("UICorner", { CornerRadius = UDim.new(0, r), Parent = inst })
end

local function stroke(inst, color, transparency, thickness)
        return New("UIStroke", {
                Color = color,
                Transparency = transparency or 0,
                Thickness = thickness or 1,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                Parent = inst,
        })
end

local function padding(inst, t, r, b, l)
        local p = New("UIPadding", { Parent = inst })
        if t then p.PaddingTop = UDim.new(0, t) end
        if r then p.PaddingRight = UDim.new(0, r) end
        if b then p.PaddingBottom = UDim.new(0, b) end
        if l then p.PaddingLeft = UDim.new(0, l) end
        return p
end

local function list(parent, gap, sortOrder)
        return New("UIListLayout", {
                Padding = UDim.new(0, gap or 0),
                SortOrder = sortOrder or Enum.SortOrder.LayoutOrder,
                Parent = parent,
        })
end

local function tween(inst, time, props, style, dir)
        local t = TweenService:Create(inst, TweenInfo.new(
                time,
                style or Enum.EasingStyle.Quad,
                dir or Enum.EasingDirection.Out
        ), props)
        t:Play()
        return t
end

-- Text measurement (for section headers / badges laid out manually)
local function measureText(text, size, font)
        local ok, w = pcall(function()
                return TextService:GetTextSize(text, size, font, Vector2.new(4096, size * 2)).X
        end)
        if ok and w then return w end
        return rnd(#text * size * 0.58)
end

-- Color helpers
local function colorToHex(c)
        local function to(v) return string.format("%02X", clamp(math.floor(v * 255 + 0.5), 0, 255)) end
        return "#" .. to(c.R) .. to(c.G) .. to(c.B)
end

local function hexToColor(hex)
        local h = tostring(hex):gsub("#", "")
        local r = tonumber(h:sub(1, 2), 16) or 0
        local g = tonumber(h:sub(3, 4), 16) or 0
        local b = tonumber(h:sub(5, 6), 16) or 0
        return Color3.fromRGB(r, g, b)
end

-- Key name prettifying: "RightShift" -> "Right Shift", "F5" -> "F5"
local function keyDisplayName(name)
        return (name:gsub("(%l)(%u)", "%1 %2"))
end

local MOUSE_NAMES = {
        [Enum.UserInputType.MouseButton1] = "Left Mouse",
        [Enum.UserInputType.MouseButton2] = "Right Mouse",
        [Enum.UserInputType.MouseButton3] = "Middle Mouse",
}

-- ============================================================
--  Icons — pure geometry (rotated bars), no font/glyph dependency
-- ============================================================
-- Each icon = { SetColor(color), SetTransparency(t), Frames = {...} }

local function iconBars(parent, bars)
        local frames = {}
        for _, b in ipairs(bars) do
                local f = New("Frame", {
                        Position = UDim2.new(0, b.x, 0, b.y),
                        Size = UDim2.new(0, b.w, 0, b.h),
                        Rotation = b.rot or 0,
                        BackgroundColor3 = Color3.new(1, 1, 1),
                        BorderSizePixel = 0,
                        Parent = parent,
                })
                table.insert(frames, f)
        end
        local icon = { Frames = frames }
        function icon.SetColor(color)
                for _, f in ipairs(frames) do f.BackgroundColor3 = color end
        end
        function icon.SetTransparency(t)
                for _, f in ipairs(frames) do f.BackgroundTransparency = t end
        end
        return icon
end

-- 18x18 chevron pointing down (rotate container 180 for "up")
local function iconChevron(parent)
        local c = New("Frame", {
                Size = UDim2.new(0, 18, 0, 18),
                BackgroundTransparency = 1,
                Parent = parent,
        })
        local icon = iconBars(c, {
                { x = 2, y = 9, w = 8, h = 2, rot = 45 },
                { x = 8, y = 9, w = 8, h = 2, rot = -45 },
        })
        icon.Container = c
        return icon
end

-- 18x18 window caption glyphs
local function iconMinus(parent)
        local c = New("Frame", { Size = UDim2.new(0, 18, 0, 18), BackgroundTransparency = 1, Parent = parent })
        return iconBars(c, { { x = 1, y = 8, w = 16, h = 2 } })
end

local function iconPlus(parent)
        local c = New("Frame", { Size = UDim2.new(0, 18, 0, 18), BackgroundTransparency = 1, Parent = parent })
        return iconBars(c, {
                { x = 1, y = 8, w = 16, h = 2 },
                { x = 8, y = 1, w = 2, h = 16 },
        })
end

local function iconClose(parent)
        local c = New("Frame", { Size = UDim2.new(0, 18, 0, 18), BackgroundTransparency = 1, Parent = parent })
        return iconBars(c, {
                { x = 1, y = 8, w = 16, h = 2, rot = 45 },
                { x = 1, y = 8, w = 16, h = 2, rot = -45 },
        })
end

local function iconSearch(parent)
        local c = New("Frame", { Size = UDim2.new(0, 18, 0, 18), BackgroundTransparency = 1, Parent = parent })
        local ring = New("Frame", {
                Position = UDim2.new(0, 2, 0, 2),
                Size = UDim2.new(0, 12, 0, 12),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Parent = c,
        })
        corner(ring, 6)
        local ringStroke = stroke(ring, Color3.new(1, 1, 1), 0, 2)
        local bars = iconBars(c, { { x = 11, y = 13, w = 6, h = 2, rot = 45 } })
        local icon = { Frames = bars.Frames, _ringStroke = ringStroke }
        function icon.SetColor(color)
                bars.SetColor(color)
                ringStroke.Color = color
        end
        function icon.SetTransparency(t)
                bars.SetTransparency(t)
                ringStroke.Transparency = t
        end
        return icon
end

-- 12x12 checkmark (dropdown selection)
local function iconCheck(parent)
        local c = New("Frame", { Size = UDim2.new(0, 12, 0, 12), BackgroundTransparency = 1, Parent = parent })
        local icon = iconBars(c, {
                { x = 0, y = 7, w = 6, h = 2, rot = 45 },
                { x = 3, y = 5, w = 9, h = 2, rot = -45 },
        })
        icon.Container = c
        return icon
end

-- 15x15 toast glyphs (white geometry inside a colored circle)
local function glyphInfo(parent)
        return iconBars(parent, { { x = 6, y = 1, w = 2, h = 2 }, { x = 6, y = 5, w = 2, h = 8 } })
end

local function glyphWarn(parent)
        return iconBars(parent, { { x = 6, y = 2, w = 2, h = 8 }, { x = 6, y = 11, w = 2, h = 2 } })
end

local function glyphCheck(parent)
        return iconBars(parent, {
                { x = 2, y = 7, w = 7, h = 2, rot = 45 },
                { x = 4, y = 5, w = 10, h = 2, rot = -45 },
        })
end

-- ============================================================
--  GUI parent resolution (executor gethui / CoreGui / PlayerGui)
-- ============================================================
local function resolveParent(config)
        if config and config.Parent then return config.Parent end
        local ok, hidden = pcall(function()
                if gethui then return gethui() end
                return nil
        end)
        if ok and type(hidden) == "Instance" then return hidden end
        local okCore = pcall(function()
                local probe = Instance.new("Folder")
                probe.Parent = game:GetService("CoreGui")
                probe:Destroy()
        end)
        if okCore then return game:GetService("CoreGui") end
        local player = Players.LocalPlayer
        if player then
                local pg = player:FindFirstChild("PlayerGui")
                if pg then return pg end
                local okWait, waited = pcall(function()
                        return player:WaitForChild("PlayerGui", 5)
                end)
                if okWait and waited then return waited end
        end
        error("Reborn: no usable GUI parent (no gethui, no CoreGui access, no LocalPlayer) — pass config.Parent")
end

-- ============================================================
--  Toast system (standalone — works with or without a window)
-- ============================================================
local TOAST_TYPES = {
        info    = { color = DEFAULT_THEME.Accent,  glyph = glyphInfo },
        success = { color = DEFAULT_THEME.Success, glyph = glyphCheck },
        error   = { color = DEFAULT_THEME.Error,   glyph = glyphWarn },
}

local function buildToastLayer(gui, theme)
        local layer = New("Frame", {
                AnchorPoint = Vector2.new(1, 0),
                Position = UDim2.new(1, -18, 0, 18),
                Size = UDim2.new(0, GEO.ToastW, 1, -36),
                BackgroundTransparency = 1,
                ClipsDescendants = false,
                ZIndex = 50,
                Parent = gui,
        })
        local state = { items = {} }

        local function relayout(animate)
                local y = 0
                for _, item in ipairs(state.items) do
                        local h = item.toast.AbsoluteSize.Y
                        if animate then
                                tween(item.toast, 0.22, { Position = UDim2.new(0, 0, 0, y) })
                        else
                                item.toast.Position = UDim2.new(0, 0, 0, y)
                        end
                        y = y + h + 8
                end
        end

        local function dismiss(item)
                if item.closed then return end
                item.closed = true
                for i, it in ipairs(state.items) do
                        if it == item then table.remove(state.items, i) break end
                end
                tween(item.toast, 0.24, {
                        Position = UDim2.new(0, GEO.ToastW + 14, 0, item.toast.Position.Y.Offset),
                        GroupTransparency = 1,
                })
                task.delay(0.26, function()
                        if item.toast then item.toast:Destroy() end
                end)
                relayout(true)
        end

        local function notify(cfg)
                cfg = cfg or {}
                local kind = TOAST_TYPES[cfg.Type] or TOAST_TYPES.info
                local toast = New("CanvasGroup", {
                        Position = UDim2.new(0, GEO.ToastW + 18, 0, 0),
                        Size = UDim2.new(0, GEO.ToastW, 0, 0),
                        AutomaticSize = Enum.AutomaticSize.Y,
                        BackgroundColor3 = theme.Overlay,
                        BackgroundTransparency = 0.06,
                        BorderSizePixel = 0,
                        GroupTransparency = 1,
                        Parent = layer,
                })
                corner(toast, 8)
                stroke(toast, theme.LineStrong)
                padding(toast, 11, 12, 11, 12)

                -- icon
                local ic = New("Frame", {
                        Position = UDim2.new(0, 0, 0, 1),
                        Size = UDim2.new(0, 15, 0, 15),
                        BackgroundColor3 = kind.color,
                        BorderSizePixel = 0,
                        Parent = toast,
                })
                corner(ic, 8)
                kind.glyph(ic).SetColor(Color3.new(1, 1, 1))

                -- text column
                local title = New("TextLabel", {
                        Position = UDim2.new(0, 27, 0, 0),
                        Size = UDim2.new(1, -27, 0, 16),
                        BackgroundTransparency = 1,
                        Font = F.Semibold,
                        TextSize = 13,
                        TextColor3 = theme.Text,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        Text = tostring(cfg.Title or "Notification"),
                        TextTruncate = Enum.TextTruncate.AtEnd,
                        Parent = toast,
                })
                local desc = New("TextLabel", {
                        Position = UDim2.new(0, 27, 0, 18),
                        Size = UDim2.new(1, -27, 0, 0),
                        AutomaticSize = Enum.AutomaticSize.Y,
                        BackgroundTransparency = 1,
                        Font = F.Regular,
                        TextSize = 12,
                        TextColor3 = theme.TextMuted,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        TextYAlignment = Enum.TextYAlignment.Top,
                        TextWrapped = true,
                        Text = tostring(cfg.Description or ""),
                        Parent = toast,
                })

                -- click-to-dismiss overlay
                local hit = New("TextButton", {
                        Size = UDim2.new(1, 0, 1, 0),
                        BackgroundTransparency = 1,
                        Text = "",
                        AutoButtonColor = false,
                        ZIndex = 10,
                        Parent = toast,
                })
                local item = { toast = toast, closed = false }
                hit.Activated:Connect(function() dismiss(item) end)
                table.insert(state.items, item)
                while #state.items > 5 do
                        dismiss(state.items[1])
                end
                relayout(false)
                tween(toast, 0.22, { Position = UDim2.new(0, 0, 0, toast.Position.Y.Offset), GroupTransparency = 0 })
                task.delay(cfg.Duration or 3.6, function() dismiss(item) end)
                return item
        end

        return { Layer = layer, Notify = notify }
end

-- standalone notify (no window yet / window destroyed)
function Reborn:Notify(cfg)
        if not self.NotificationsEnabled then return end
        if #self._windows > 0 then
                local w = self._windows[#self._windows]
                w:Notify(cfg)
                return
        end
        if not self._toastGui or not self._toastGui.Parent then
                self._toastGui = New("ScreenGui", {
                        Name = "RebornToasts",
                        ResetOnSpawn = false,
                        IgnoreGuiInset = true,
                        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
                        DisplayOrder = 999,
                        Parent = resolveParent(nil),
                })
                self._toastLayer = buildToastLayer(self._toastGui, DEFAULT_THEME)
        end
        self._toastLayer.Notify(cfg)
end

-- ============================================================
--  Window
-- ============================================================
function Reborn:CreateWindow(config)
        config = config or {}

        local theme = {}
        for k, v in pairs(DEFAULT_THEME) do theme[k] = v end
        if config.Theme then
                for k, v in pairs(config.Theme) do theme[k] = v end
        end

        local parent = resolveParent(config)
        local old = parent:FindFirstChild("RebornUI")
        if old then old:Destroy() end

        local gui = New("ScreenGui", {
                Name = "RebornUI",
                ResetOnSpawn = false,
                IgnoreGuiInset = true,
                ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
                DisplayOrder = 999,
                Parent = parent,
        })

        local conns = {}
        local function connect(signal, fn)
                local c = signal:Connect(fn)
                table.insert(conns, c)
                return c
        end

        local camera = workspace.CurrentCamera or workspace:WaitForChild("Camera")

        -- --- geometry: even-pixel window clamped to the viewport (port of the
        --     concept's round(down, min(700, 96vw), 2px) logic) ---
        local function computeSize()
                local v = camera.ViewportSize
                local w = config.Size and config.Size.X or GEO.WindowMaxW
                local h = config.Size and config.Size.Y or GEO.WindowMaxH
                w = math.floor(math.min(w, v.X * 0.96) / 2) * 2
                h = math.floor(math.min(h, v.Y * 0.88) / 2) * 2
                return w, h
        end
        local W, H = computeSize()

        local state = {
                dragged  = false,
                min      = false,
                closed   = false,
                listening = nil,   -- keybind chip in capture mode
                openPops = {},     -- open popovers { row, pop, close() }
                keybinds = {},     -- bound { name, keyCode|userInputType, callback }
                searchRows = {},   -- { frame, text, section }
                sections = {},
                tabs = {},
        }

        -- ---------- window shell ----------
        local windowFrame = New("CanvasGroup", {
                Name = "RebornWindow",
                Size = UDim2.new(0, W, 0, H),
                BackgroundColor3 = theme.Surface,
                BorderSizePixel = 0,
                GroupTransparency = 1,
                ClipsDescendants = true,
                Parent = gui,
        })
        corner(windowFrame, GEO.WindowRadius)
        stroke(windowFrame, theme.LineStrong)

        local function recenter()
                if state.dragged or state.closed then return end
                local v = camera.ViewportSize
                windowFrame.Position = UDim2.new(0, rnd(v.X / 2 - W / 2), 0, rnd(v.Y / 2 - H / 2))
        end
        recenter()
        -- intro: fade + rise (port of winIn .4s)
        windowFrame.Position = UDim2.new(0, windowFrame.Position.X.Offset, 0, windowFrame.Position.Y.Offset + 12)
        tween(windowFrame, 0.4, {
                GroupTransparency = 0,
                Position = UDim2.new(0, windowFrame.Position.X.Offset, 0, windowFrame.Position.Y.Offset - 12),
        }, Enum.EasingStyle.Quint)

        connect(camera:GetPropertyChangedSignal("ViewportSize"), function()
                recenter()
        end)

        -- ---------- header (47px: 46 content + 1px divider) ----------
        local header = New("Frame", {
                Size = UDim2.new(1, 0, 0, GEO.Header),
                BackgroundColor3 = theme.Surface,
                BorderSizePixel = 0,
                ZIndex = 20,
                Parent = windowFrame,
        })
        New("Frame", { -- bottom hairline
                Position = UDim2.new(0, 0, 1, -1),
                Size = UDim2.new(1, 0, 0, 1),
                BackgroundColor3 = theme.Line,
                BorderSizePixel = 0,
                Parent = header,
        })

        local clusterW = GEO.SearchW + 9 + GEO.WinBtn + 9 + GEO.WinBtn + 9 + GEO.WinBtn

        local dragZone = New("Frame", {
                Position = UDim2.new(0, GEO.HeaderPad, 0, 0),
                Size = UDim2.new(1, -GEO.HeaderPad - clusterW - 9 - 12, 0, GEO.Header),
                BackgroundTransparency = 1,
                Parent = header,
        })
        New("TextLabel", {
                Position = UDim2.new(0, 0, 0, 15),
                Size = UDim2.new(0, 0, 0, 16),
                AutomaticSize = Enum.AutomaticSize.X,
                BackgroundTransparency = 1,
                Font = F.Semibold,
                TextSize = 14,
                TextColor3 = theme.Text,
                TextXAlignment = Enum.TextXAlignment.Left,
                Text = tostring(config.Title or "Reborn"),
                Parent = dragZone,
        })

        local cluster = New("Frame", {
                AnchorPoint = Vector2.new(1, 0),
                Position = UDim2.new(1, -12, 0, 0),
                Size = UDim2.new(0, clusterW, 0, GEO.Header),
                BackgroundTransparency = 1,
                Parent = header,
        })

        -- caption button factory (44x36, radius 6, Lucide-style geometry icons)
        local function captionBtn(x, buildIcon, isClose)
                local b = New("TextButton", {
                        Position = UDim2.new(0, x, 0, 5),
                        Size = UDim2.new(0, GEO.WinBtn, 0, GEO.WinBtnH),
                        BackgroundTransparency = 1,
                        Text = "",
                        AutoButtonColor = false,
                        Parent = cluster,
                })
                corner(b, 6)
                local icon = buildIcon(b)
                icon.SetColor(theme.TextFaint)
                b.MouseEnter:Connect(function()
                        b.BackgroundTransparency = 0
                        if isClose then
                                b.BackgroundColor3 = theme.Error
                                b.BackgroundTransparency = 0.88
                                icon.SetColor(theme.Error)
                        else
                                b.BackgroundColor3 = theme.RowHover
                                icon.SetColor(theme.Text)
                        end
                end)
                b.MouseLeave:Connect(function()
                        b.BackgroundTransparency = 1
                        icon.SetColor(theme.TextFaint)
                end)
                return b, icon
        end

        -- search field (collapsed by default, expands like the concept)
        local searchBox = New("TextBox", {
                Position = UDim2.new(0, 0, 0, 7),
                Size = UDim2.new(0, 0, 0, GEO.SearchH),
                BackgroundColor3 = theme.Overlay,
                BackgroundTransparency = 1,
                Text = "",
                PlaceholderText = "search…",
                PlaceholderColor3 = theme.TextFaint,
                Font = F.Regular,
                TextSize = 12,
                TextColor3 = theme.Text,
                TextXAlignment = Enum.TextXAlignment.Left,
                ClearTextOnFocus = false,
                BorderSizePixel = 0,
                ClipsDescendants = true,
                Parent = cluster,
        })
        corner(searchBox, 7)
        local searchStroke = stroke(searchBox, theme.LineStrong, 1)
        padding(searchBox, 0, 9, 0, 9)

        local searchBtn = captionBtn(GEO.SearchW + 9, iconSearch, false)
        local minBtn, minIcon = captionBtn(GEO.SearchW + 9 + GEO.WinBtn + 9, iconMinus, false)
        local plusIcon = iconPlus(minBtn)
        plusIcon.SetColor(theme.TextFaint)
        for _, f in ipairs(plusIcon.Frames) do f.Visible = false end
        local closeBtn = captionBtn(GEO.SearchW + 9 + GEO.WinBtn * 2 + 18, iconClose, true)

        -- ---------- body (sidebar + content), wrapped for minimize fade ----------
        local bodyGroup = New("CanvasGroup", {
                Position = UDim2.new(0, 0, 0, GEO.Header),
                Size = UDim2.new(1, 0, 1, -GEO.Header),
                BackgroundTransparency = 1,
                GroupTransparency = 0,
                Parent = windowFrame,
        })

        -- ---------- sidebar ----------
        local sidebar = New("Frame", {
                Size = UDim2.new(0, GEO.Sidebar, 1, 0),
                BackgroundColor3 = theme.Surface,
                BorderSizePixel = 0,
                Parent = bodyGroup,
        })
        New("Frame", { -- right hairline (155 + 1 = 156)
                Position = UDim2.new(0, GEO.Sidebar, 0, 0),
                Size = UDim2.new(0, 1, 1, 0),
                BackgroundColor3 = theme.Line,
                BorderSizePixel = 0,
                Parent = sidebar,
        })

        local tabsHolder = New("Frame", {
                Size = UDim2.new(1, 0, 1, -49),
                BackgroundTransparency = 1,
                ClipsDescendants = true,
                Parent = sidebar,
        })
        padding(tabsHolder, 10, 10, 8, 10)
        list(tabsHolder, 3)

        local sideBottom = New("Frame", {
                AnchorPoint = Vector2.new(0, 1),
                Position = UDim2.new(0, 0, 1, -49),
                Size = UDim2.new(1, 0, 0, 49),
                BackgroundTransparency = 1,
                Parent = sidebar,
        })
        New("Frame", {
                Size = UDim2.new(1, 0, 0, 1),
                BackgroundColor3 = theme.Line,
                BorderSizePixel = 0,
                Parent = sideBottom,
        })
        padding(sideBottom, 11, 12, 11, 12)
        local profile = config.Profile or {}
        local pname = profile.Name or (Players.LocalPlayer and Players.LocalPlayer.Name) or "player"
        local initial = profile.Initial or pname:sub(1, 1):upper()
        local avatar = New("Frame", {
                Size = UDim2.new(0, 27, 0, 27),
                BackgroundColor3 = theme.Accent,
                BorderSizePixel = 0,
                Parent = sideBottom,
        })
        corner(avatar, 6)
        New("TextLabel", {
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Font = F.Semibold,
                TextSize = 11,
                TextColor3 = Color3.new(1, 1, 1),
                Text = initial,
                Parent = avatar,
        })
        New("TextLabel", {
                Position = UDim2.new(0, 36, 0, 12),
                Size = UDim2.new(1, -40, 0, 14),
                BackgroundTransparency = 1,
                Font = F.Medium,
                TextSize = 12,
                TextColor3 = theme.Text,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd,
                Text = pname,
                Parent = sideBottom,
        })

        -- ---------- content (scrolling) ----------
        local content = New("ScrollingFrame", {
                Position = UDim2.new(0, GEO.Sidebar + 1, 0, 0),
                Size = UDim2.new(1, -(GEO.Sidebar + 1), 1, 0),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                ScrollBarThickness = 9,
                ScrollBarImageColor3 = Color3.fromRGB(46, 46, 46),
                ScrollingDirection = Enum.ScrollingDirection.Y,
                CanvasSize = UDim2.new(0, 0, 0, 0),
                AutomaticCanvasSize = Enum.AutomaticSize.Y,
                Parent = bodyGroup,
        })

        -- ---------- launcher (reopen pill after close) ----------
        local launcher = New("CanvasGroup", {
                AnchorPoint = Vector2.new(1, 1),
                Position = UDim2.new(1, -22, 1, -14),
                Size = UDim2.new(0, GEO.Launcher, 0, GEO.Launcher),
                BackgroundColor3 = theme.Overlay,
                BorderSizePixel = 0,
                GroupTransparency = 1,
                Visible = false,
                ZIndex = 40,
                Parent = gui,
        })
        corner(launcher, 23)
        stroke(launcher, theme.LineStrong)
        do
                local d = New("Frame", {
                        Position = UDim2.new(0, 16, 0, 16),
                        Size = UDim2.new(0, 14, 0, 14),
                        Rotation = 45,
                        BackgroundColor3 = theme.Accent,
                        BorderSizePixel = 0,
                        Parent = launcher,
                })
        end
        launcher.MouseEnter:Connect(function()
                launcher.BackgroundColor3 = theme.Chip
        end)
        launcher.MouseLeave:Connect(function()
                launcher.BackgroundColor3 = theme.Overlay
        end)

        -- ---------- toasts ----------
        local toastLayer = buildToastLayer(gui, theme)

        -- ============================================================
        --  Drag / minimize / close / reopen
        -- ============================================================
        local dragState = nil
        dragZone.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        state.dragged = true
                        local p = windowFrame.Position
                        dragState = { sx = input.Position.X, sy = input.Position.Y, ox = p.X.Offset, oy = p.Y.Offset }
                end
        end)
        connect(UserInputService.InputChanged, function(input)
                if dragState and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                        local v = camera.ViewportSize
                        local nx = clamp(dragState.ox + (input.Position.X - dragState.sx), -W + 140, v.X - 140)
                        local ny = clamp(dragState.oy + (input.Position.Y - dragState.sy), 0, v.Y - GEO.Header)
                        windowFrame.Position = UDim2.new(0, rnd(nx), 0, rnd(ny))
                end
        end)
        connect(UserInputService.InputEnded, function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        dragState = nil
                end
        end)

        local function setMinimized(m)
                if state.min == m then return end
                state.min = m
                for _, f in ipairs(minIcon.Frames) do f.Visible = not m end
                for _, f in ipairs(plusIcon.Frames) do f.Visible = m end
                if m then
                        tween(bodyGroup, 0.18, { GroupTransparency = 1 })
                        tween(windowFrame, 0.26, { Size = UDim2.new(0, W, 0, GEO.Header) }, Enum.EasingStyle.Quint)
                else
                        tween(bodyGroup, 0.18, { GroupTransparency = 0 })
                        tween(windowFrame, 0.26, { Size = UDim2.new(0, W, 0, H) }, Enum.EasingStyle.Quint)
                end
        end

        local function closeWindow()
                if state.closed then return end
                state.closed = true
                tween(windowFrame, 0.16, { GroupTransparency = 1 })
                task.delay(0.18, function()
                        if state.closed then windowFrame.Visible = false end
                end)
                launcher.Visible = true
                launcher.GroupTransparency = 1
                launcher.Position = UDim2.new(1, -22, 1, -14)
                tween(launcher, 0.18, { GroupTransparency = 0, Position = UDim2.new(1, -22, 1, -22) })
        end

        minBtn.Activated:Connect(function()
                setMinimized(not state.min)
        end)

        local function reopen()
                if not state.closed then return end
                state.closed = false
                recenter()
                windowFrame.Visible = true
                windowFrame.GroupTransparency = 1
                tween(windowFrame, 0.2, { GroupTransparency = 0 })
                tween(launcher, 0.14, { GroupTransparency = 1 })
                task.delay(0.16, function()
                        if not state.closed then launcher.Visible = false end
                end)
        end

        closeBtn.Activated:Connect(closeWindow)

        launcher.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        reopen()
                end
        end)

        -- ============================================================
        --  Search filter
        -- ============================================================
        local function applyFilter(q)
                q = tostring(q or ""):lower()
                for _, e in ipairs(state.searchRows) do
                        local match = q == "" or (e.text ~= nil and e.text:lower():find(q, 1, true) ~= nil)
                        e.frame.Visible = match
                end
                for _, sec in ipairs(state.sections) do
                        local any = false
                        for _, e in ipairs(state.searchRows) do
                                if e.section == sec and e.frame.Visible then
                                        any = true
                                        break
                                end
                        end
                        sec.Frame.Visible = any
                end
        end

        local function openSearch()
                tween(searchBox, 0.18, { Size = UDim2.new(0, GEO.SearchW, 0, GEO.SearchH) })
                tween(searchBox, 0.15, { BackgroundTransparency = 0 })
                tween(searchStroke, 0.15, { Transparency = 0 })
                searchBox:CaptureFocus()
        end

        local function closeSearch()
                searchBox.Text = ""
                applyFilter("")
                searchBox:ReleaseFocus()
                tween(searchBox, 0.18, { Size = UDim2.new(0, 0, 0, GEO.SearchH) })
                tween(searchBox, 0.15, { BackgroundTransparency = 1 })
                tween(searchStroke, 0.15, { Transparency = 1 })
        end

        searchBtn.Activated:Connect(function()
                if searchBox.Size.X.Offset > 0 then
                        closeSearch()
                else
                        openSearch()
                end
        end)
        searchBox:GetPropertyChangedSignal("Text"):Connect(function()
                applyFilter(searchBox.Text)
        end)
        searchBox.FocusLost:Connect(function()
                closeSearch()
        end)

        -- ============================================================
        --  Rows
        -- ============================================================
        local function makeRow(section, h)
                local row = New("Frame", {
                        Size = UDim2.new(1, 0, 0, h),
                        BackgroundColor3 = theme.RowHover,
                        BackgroundTransparency = 1,
                        BorderSizePixel = 0,
                        ZIndex = 1,
                        Parent = section.Rows,
                })
                corner(row, 8)
                local s = stroke(row, theme.Line)
                row.MouseEnter:Connect(function()
                        row.BackgroundTransparency = 0
                        s.Color = theme.LineStrong
                end)
                row.MouseLeave:Connect(function()
                        row.BackgroundTransparency = 1
                        s.Color = theme.Line
                end)
                return row, s
        end

        local function rowLabel(row, text, h)
                local lbl = New("TextLabel", {
                        AnchorPoint = Vector2.new(0, 0.5),
                        Position = UDim2.new(0, GEO.RowPad, 0.5, 0),
                        Size = UDim2.new(0, 0, 0, h or 16),
                        AutomaticSize = Enum.AutomaticSize.X,
                        BackgroundTransparency = 1,
                        Font = F.Medium,
                        TextSize = 13,
                        TextColor3 = theme.Text,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        TextTruncate = Enum.TextTruncate.AtEnd,
                        Text = tostring(text or ""),
                        ZIndex = 5,
                        Parent = row,
                })
                return lbl
        end

        local function overlayBtn(row)
                return New("TextButton", {
                        Size = UDim2.new(1, 0, 1, 0),
                        BackgroundTransparency = 1,
                        Text = "",
                        AutoButtonColor = false,
                        ZIndex = 10,
                        Parent = row,
                })
        end

        local function registerSearch(frame, text, section)
                table.insert(state.searchRows, { frame = frame, text = text, section = section })
        end

        local function closeAllPops(except)
                for i = #state.openPops, 1, -1 do
                        if state.openPops[i].pop ~= except then
                                state.openPops[i].close()
                        end
                end
        end

        local function registerPop(row, pop, setOpen)
                table.insert(state.openPops, { row = row, pop = pop, close = function() setOpen(false) end })
        end
        local function unregisterPop(pop)
                for i, p in ipairs(state.openPops) do
                        if p.pop == pop then
                                table.remove(state.openPops, i)
                                break
                        end
                end
        end

        -- ============================================================
        --  Components
        -- ============================================================

        -- ---------- Toggle ----------
        local function addToggle(section, cfg)
                cfg = cfg or {}
                local row = makeRow(section, GEO.RowH)
                rowLabel(row, cfg.Text)
                local btn = overlayBtn(row)

                local track = New("Frame", {
                        AnchorPoint = Vector2.new(1, 0.5),
                        Position = UDim2.new(1, -GEO.RowPad, 0.5, 0),
                        Size = UDim2.new(0, GEO.SwitchW, 0, GEO.SwitchH),
                        BackgroundColor3 = theme.ToggleOff,
                        BorderSizePixel = 0,
                        ZIndex = 5,
                        Parent = row,
                })
                corner(track, GEO.SwitchH / 2)
                local ts = stroke(track, theme.LineStrong)
                local knob = New("Frame", {
                        Position = UDim2.new(0, 3, 0, 2),
                        Size = UDim2.new(0, GEO.Knob, 0, GEO.Knob),
                        BackgroundColor3 = theme.Handle,
                        BorderSizePixel = 0,
                        ZIndex = 6,
                        Parent = track,
                })
                corner(knob, GEO.Knob / 2)

                local value = cfg.Value and true or false
                local tog = { Value = value }

                local function render(fire, instant)
                        local nx = value and (GEO.SwitchW - GEO.Knob - 3) or 3
                        if instant then
                                knob.Position = UDim2.new(0, nx, 0, 2)
                        else
                                tween(knob, 0.18, { Position = UDim2.new(0, nx, 0, 2) }, Enum.EasingStyle.Quad)
                        end
                        track.BackgroundColor3 = value and theme.Accent or theme.ToggleOff
                        ts.Color = value and theme.Accent or theme.LineStrong
                        tog.Value = value
                        if fire and cfg.Callback then cfg.Callback(value) end
                end
                btn.Activated:Connect(function()
                        value = not value
                        render(true)
                end)
                render(false, true)
                registerSearch(row, cfg.Text, section)

                function tog:Set(v, fire)
                        value = v and true or false
                        render(fire and true or false)
                end
                return tog
        end

        -- ---------- Slider ----------
        local function addSlider(section, cfg)
                cfg = cfg or {}
                local row = makeRow(section, GEO.SliderH)
                padding(row, 10, GEO.RowPad, 10, GEO.RowPad)

                local top = New("Frame", {
                        Size = UDim2.new(1, 0, 0, 16),
                        BackgroundTransparency = 1,
                        Parent = row,
                })
                New("TextLabel", {
                        Size = UDim2.new(0, 0, 1, 0),
                        AutomaticSize = Enum.AutomaticSize.X,
                        BackgroundTransparency = 1,
                        Font = F.Medium,
                        TextSize = 13,
                        TextColor3 = theme.Text,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        Text = tostring(cfg.Text or ""),
                        Parent = top,
                })
                local val = New("TextLabel", {
                        AnchorPoint = Vector2.new(1, 0),
                        Position = UDim2.new(1, 0, 0, 0),
                        Size = UDim2.new(0, 0, 1, 0),
                        AutomaticSize = Enum.AutomaticSize.X,
                        BackgroundTransparency = 1,
                        Font = F.Medium,
                        TextSize = 12,
                        TextColor3 = theme.TextMuted,
                        TextXAlignment = Enum.TextXAlignment.Right,
                        Text = "",
                        Parent = top,
                })

                local track = New("TextButton", {
                        Position = UDim2.new(0, 0, 0, 24),
                        Size = UDim2.new(1, 0, 0, GEO.SliderTrackH),
                        BackgroundTransparency = 1,
                        Text = "",
                        AutoButtonColor = false,
                        Parent = row,
                })
                local rail = New("Frame", {
                        Position = UDim2.new(0, 0, 0, 6),
                        Size = UDim2.new(1, 0, 0, GEO.RailH),
                        BackgroundColor3 = theme.LineStrong,
                        BorderSizePixel = 0,
                        Parent = track,
                })
                corner(rail, 3)
                local fill = New("Frame", {
                        Position = UDim2.new(0, 0, 0, 6),
                        Size = UDim2.new(0, 0, 0, GEO.RailH),
                        BackgroundColor3 = theme.Accent,
                        BorderSizePixel = 0,
                        Parent = track,
                })
                corner(fill, 3)
                local handle = New("Frame", {
                        Position = UDim2.new(0, 0, 0, 2),
                        Size = UDim2.new(0, GEO.HandleD, 0, GEO.HandleD),
                        BackgroundColor3 = theme.Handle,
                        BorderSizePixel = 0,
                        ZIndex = 2,
                        Parent = track,
                })
                corner(handle, 7)

                local min = cfg.Min or 0
                local max = cfg.Max or 100
                if max <= min then max = min + 1 end
                local value = clamp(math.floor(cfg.Value or min), min, max)
                local suffix = cfg.Suffix or ""
                local sld = { Value = value }

                local function render()
                        local tw = track.AbsoluteSize.X
                        if tw < GEO.HandleD then
                                task.defer(render)
                                return
                        end
                        local p = (value - min) / (max - min)
                        local px = rnd(p * tw)
                        fill.Size = UDim2.new(0, px, 0, GEO.RailH)
                        handle.Position = UDim2.new(0, clamp(px - 6, 0, tw - GEO.HandleD), 0, 2)
                        val.Text = tostring(value) .. suffix
                        sld.Value = value
                end
                track:GetPropertyChangedSignal("AbsoluteSize"):Connect(render)
                task.defer(render)

                local dragging = false
                local function fromX(x)
                        local tw = track.AbsoluteSize.X
                        if tw < 1 then return end
                        local p = clamp((x - track.AbsolutePosition.X) / tw, 0, 1)
                        value = clamp(rnd(min + (max - min) * p), min, max)
                        render()
                        if cfg.Callback then cfg.Callback(value) end
                end
                track.InputBegan:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                                dragging = true
                                fromX(input.Position.X)
                        end
                end)
                connect(UserInputService.InputChanged, function(input)
                        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                                fromX(input.Position.X)
                        end
                end)
                connect(UserInputService.InputEnded, function(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                                dragging = false
                        end
                end)
                registerSearch(row, cfg.Text, section)

                function sld:Set(v, fire)
                        value = clamp(math.floor(v), min, max)
                        render()
                        if fire and cfg.Callback then cfg.Callback(value) end
                end
                return sld
        end

        -- ---------- Dropdown ----------
        local function addDropdown(section, cfg)
                cfg = cfg or {}
                local row = makeRow(section, GEO.RowH)
                rowLabel(row, cfg.Text)

                local chev = iconChevron(row)
                chev.Container.AnchorPoint = Vector2.new(1, 0.5)
                chev.Container.Position = UDim2.new(1, -GEO.RowPad, 0.5, 0)
                chev.SetColor(theme.TextFaint)

                local val = New("TextLabel", {
                        AnchorPoint = Vector2.new(1, 0.5),
                        Position = UDim2.new(1, -GEO.RowPad - 18 - 7, 0.5, 0),
                        Size = UDim2.new(0, 0, 0, 16),
                        AutomaticSize = Enum.AutomaticSize.X,
                        BackgroundTransparency = 1,
                        Font = F.Medium,
                        TextSize = 13,
                        TextColor3 = theme.TextMuted,
                        TextXAlignment = Enum.TextXAlignment.Right,
                        Text = "",
                        ZIndex = 5,
                        Parent = row,
                })

                local options = cfg.Options or {}
                local popH = 10 + #options * GEO.OptH
                local pop = New("CanvasGroup", {
                        Position = UDim2.new(0, 0, 1, 6),
                        Size = UDim2.new(1, 0, 0, popH),
                        BackgroundColor3 = theme.Overlay,
                        BorderSizePixel = 0,
                        GroupTransparency = 1,
                        Visible = false,
                        ZIndex = 25,
                        Parent = row,
                })
                corner(pop, 8)
                stroke(pop, theme.LineStrong)
        padding(pop, 5)
        list(pop, 0)

        local dd = { Value = cfg.Value or (options[1]) }
                local optBtns = {}

                local function setOpen(o)
                        if dd._open == o then return end
                        dd._open = o
                        row.ZIndex = o and 30 or 1
                        if o then
                                closeAllPops(pop)
                                pop.Visible = true
                                pop.Position = UDim2.new(0, 0, 1, 10)
                                tween(pop, 0.16, { GroupTransparency = 0, Position = UDim2.new(0, 0, 1, 6) })
                                tween(chev.Container, 0.18, { Rotation = 180 })
                                registerPop(row, pop, setOpen)
                        else
                                tween(pop, 0.14, { GroupTransparency = 1, Position = UDim2.new(0, 0, 1, 10) })
                                task.delay(0.16, function()
                                        if not dd._open then pop.Visible = false end
                                end)
                                tween(chev.Container, 0.18, { Rotation = 0 })
                                unregisterPop(pop)
                        end
                end

                for i, opt in ipairs(options) do
                        local otext = tostring(opt)
                        local ob = New("TextButton", {
                                Size = UDim2.new(1, 0, 0, GEO.OptH),
                                BackgroundTransparency = 1,
                                BackgroundColor3 = theme.OptionHover,
                                Text = otext,
                                Font = F.Medium,
                                TextSize = 13,
                                TextColor3 = theme.TextMuted,
                                TextXAlignment = Enum.TextXAlignment.Left,
                                AutoButtonColor = false,
                                LayoutOrder = i,
                                Parent = pop,
                        })
                        corner(ob, 6)
                        padding(ob, 0, 10, 0, 10)
                        local chk = iconCheck(ob)
                        chk.Container.AnchorPoint = Vector2.new(1, 0.5)
                        chk.Container.Position = UDim2.new(1, -10, 0.5, 0)
                        chk.SetColor(theme.Accent)
                        for _, f in ipairs(chk.Frames) do f.Visible = false end

                        ob.MouseEnter:Connect(function()
                                ob.BackgroundTransparency = 0
                                ob.TextColor3 = theme.Text
                        end)
                        ob.MouseLeave:Connect(function()
                                ob.BackgroundTransparency = 1
                                ob.TextColor3 = theme.TextMuted
                        end)
                        ob.Activated:Connect(function()
                                dd.Value = otext
                                val.Text = otext
                                for _, other in ipairs(optBtns) do
                                        local sel = other._text == otext
                                        for _, f in ipairs(other._chk.Frames) do f.Visible = sel end
                                        other._btn.TextColor3 = sel and theme.Text or theme.TextMuted
                                end
                                setOpen(false)
                                if cfg.Callback then cfg.Callback(otext) end
                        end)
                        table.insert(optBtns, { _btn = ob, _chk = chk, _text = otext })
                        if otext == tostring(dd.Value) then
                                val.Text = otext
                                ob.TextColor3 = theme.Text
                                for _, f in ipairs(chk.Frames) do f.Visible = true end
                        end
                end

                local btn = overlayBtn(row)
                btn.Activated:Connect(function()
                        setOpen(not dd._open)
                end)
                registerSearch(row, cfg.Text, section)

                function dd:Set(v, fire)
                        local vtext = tostring(v)
                        dd.Value = vtext
                        val.Text = vtext
                        for _, other in ipairs(optBtns) do
                                local sel = other._text == vtext
                                for _, f in ipairs(other._chk.Frames) do f.Visible = sel end
                                other._btn.TextColor3 = sel and theme.Text or theme.TextMuted
                        end
                        setOpen(false)
                        if fire and cfg.Callback then cfg.Callback(vtext) end
                end
                return dd
        end

        -- ---------- Keybind ----------
        local function bindFromString(s)
                if type(s) ~= "string" then return nil, nil end
                for uit, name in pairs(MOUSE_NAMES) do
                        if name == s then return nil, uit end
                end
                local joined = s:gsub("%s", "")
                local ok, code = pcall(function()
                        return Enum.KeyCode[joined]
                end)
                if ok and code then return code, nil end
                return nil, nil
        end

        local function addKeybind(section, cfg)
                cfg = cfg or {}
                local row = makeRow(section, GEO.RowH)
                rowLabel(row, cfg.Text)

                local chip = New("TextButton", {
                        AnchorPoint = Vector2.new(1, 0.5),
                        Position = UDim2.new(1, -GEO.RowPad, 0.5, 0),
                        Size = UDim2.new(0, 0, 0, GEO.ChipH),
                        AutomaticSize = Enum.AutomaticSize.X,
                        BackgroundColor3 = theme.Chip,
                        BorderSizePixel = 0,
                        Text = "",
                        AutoButtonColor = false,
                        ZIndex = 5,
                        Parent = row,
                })
                corner(chip, 4)
                local cs = stroke(chip, theme.LineStrong)
                New("Frame", { -- min-width spacer (46px, like the concept)
                        Size = UDim2.new(0, GEO.ChipMinW, 0, 1),
                        BackgroundTransparency = 1,
                        Parent = chip,
                })
                local txt = New("TextLabel", {
                        Size = UDim2.new(0, 0, 1, 0),
                        AutomaticSize = Enum.AutomaticSize.X,
                        BackgroundTransparency = 1,
                        Font = F.Mono,
                        TextSize = 11,
                        TextColor3 = theme.TextMuted,
                        Text = tostring(cfg.Value or "None"),
                        Parent = chip,
                })
                padding(txt, 0, 9, 0, 9)

                local kb = {
                        Name = cfg.Value or "None",
                        KeyCode = nil,
                        UserInputType = nil,
                        Callback = cfg.Callback,
                }
                do
                        local code, uit = bindFromString(kb.Name)
                        kb.KeyCode = code
                        kb.UserInputType = uit
                end
                local pulseTween = nil

                local function stopListen()
                        if pulseTween then
                                pulseTween:Cancel()
                                pulseTween = nil
                        end
                        cs.Transparency = 0
                        cs.Color = theme.LineStrong
                        txt.TextColor3 = theme.TextMuted
                        state.listening = nil
                end
                local function cancelListen()
                        if state.listening ~= kb then return end
                        txt.Text = kb._prev or kb.Name
                        stopListen()
                end
                local function commitBind(name, keyCode, uit)
                        kb.Name = name
                        kb.KeyCode = keyCode
                        kb.UserInputType = uit
                        txt.Text = name
                        stopListen()
                end
                local function startListen()
                        if state.listening then
                                state.listening._cancel()
                        end
                        state.listening = kb
                        kb._cancel = cancelListen
                        kb._commit = commitBind
                        kb._prev = txt.Text
                        txt.Text = "· · ·"
                        cs.Color = theme.Accent
                        txt.TextColor3 = theme.Accent
                        pulseTween = TweenService:Create(cs, TweenInfo.new(1, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1, true), { Transparency = 0.6 })
                        pulseTween:Play()
                end

                chip.InputBegan:Connect(function(input)
                        local it = input.UserInputType
                        if it == Enum.UserInputType.MouseButton1 or it == Enum.UserInputType.MouseButton2 or it == Enum.UserInputType.MouseButton3 then
                                if state.listening == kb then
                                        commitBind(MOUSE_NAMES[it] or "Mouse", nil, it)
                                elseif not state.listening then
                                        startListen()
                                end
                        end
                end)

                table.insert(state.keybinds, kb)
                kb.Chip = chip -- outside-click cancel needs the chip rect
                registerSearch(row, cfg.Text, section)

                function kb:Set(name)
                        local code, uit = bindFromString(name)
                        kb.Name = tostring(name)
                        kb.KeyCode = code
                        kb.UserInputType = uit
                        txt.Text = tostring(name)
                end
                return kb
        end

        -- ---------- ColorPicker ----------
        local function addColorPicker(section, cfg)
                cfg = cfg or {}
                local row = makeRow(section, GEO.RowH)
                rowLabel(row, cfg.Text)

                local trigger = New("TextButton", {
                        AnchorPoint = Vector2.new(1, 0.5),
                        Position = UDim2.new(1, -GEO.RowPad, 0.5, 0),
                        Size = UDim2.new(0, 0, 0, GEO.Swatch),
                        AutomaticSize = Enum.AutomaticSize.X,
                        BackgroundTransparency = 1,
                        Text = "",
                        AutoButtonColor = false,
                        ZIndex = 5,
                        Parent = row,
                })
                list(trigger, 9)
                local hexLbl = New("TextLabel", {
                        Size = UDim2.new(0, 0, 1, 0),
                        AutomaticSize = Enum.AutomaticSize.X,
                        BackgroundTransparency = 1,
                        Font = F.Mono,
                        TextSize = 12,
                        TextColor3 = theme.TextMuted,
                        Text = "#0070F3",
                        Parent = trigger,
                })
                local swatch = New("Frame", {
                        Size = UDim2.new(0, GEO.Swatch, 0, GEO.Swatch),
                        BackgroundColor3 = theme.Accent,
                        BorderSizePixel = 0,
                        Parent = trigger,
                })
                corner(swatch, 6)
                stroke(swatch, theme.LineStrong)

                local popH = 10 + GEO.SVH + 9 + GEO.HueH + 9 + 14 + 10
                local pop = New("CanvasGroup", {
                        AnchorPoint = Vector2.new(1, 0),
                        Position = UDim2.new(1, -GEO.RowPad, 0, GEO.RowH + 6),
                        Size = UDim2.new(0, GEO.PopW, 0, popH),
                        BackgroundColor3 = theme.Overlay,
                        BorderSizePixel = 0,
                        GroupTransparency = 1,
                        Visible = false,
                        ZIndex = 25,
                        Parent = row,
                })
                corner(pop, 8)
                stroke(pop, theme.LineStrong)
                padding(pop, 10)

                local sv = New("Frame", {
                        Size = UDim2.new(1, 0, 0, GEO.SVH),
                        BackgroundColor3 = Color3.new(0, 0, 0),
                        BorderSizePixel = 0,
                        Parent = pop,
                })
                corner(sv, 6)
                local svHue = New("Frame", {
                        Size = UDim2.new(1, 0, 1, 0),
                        BackgroundColor3 = Color3.new(1, 1, 1),
                        BorderSizePixel = 0,
                        Parent = sv,
                })
                corner(svHue, 6)
                local svGrad = New("UIGradient", {
                        Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.new(1, 0, 0)),
                        Rotation = 0,
                        Parent = svHue,
                })
                local svDark = New("Frame", {
                        Size = UDim2.new(1, 0, 1, 0),
                        BackgroundColor3 = Color3.new(0, 0, 0),
                        BorderSizePixel = 0,
                        Parent = sv,
                })
                corner(svDark, 6)
                New("UIGradient", {
                        Transparency = NumberSequence.new({
                                NumberSequenceKeypoint.new(0, 1),
                                NumberSequenceKeypoint.new(1, 0),
                        }),
                        Rotation = 90,
                        Parent = svDark,
                })
                local dot = New("Frame", {
                        Size = UDim2.new(0, 12, 0, 12),
                        BackgroundTransparency = 1,
                        BorderSizePixel = 0,
                        ZIndex = 3,
                        Parent = sv,
                })
                corner(dot, 6)
                stroke(dot, Color3.new(1, 1, 1), 0, 2)

                local hue = New("Frame", {
                        Position = UDim2.new(0, 0, 0, GEO.SVH + 9),
                        Size = UDim2.new(1, 0, 0, GEO.HueH),
                        BackgroundColor3 = Color3.new(1, 1, 1),
                        BorderSizePixel = 0,
                        Parent = pop,
                })
                corner(hue, 5)
                New("UIGradient", {
                        Color = ColorSequence.new({
                                ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 0, 0)),
                                ColorSequenceKeypoint.new(1 / 6, Color3.fromRGB(255, 255, 0)),
                                ColorSequenceKeypoint.new(2 / 6, Color3.fromRGB(0, 255, 0)),
                                ColorSequenceKeypoint.new(3 / 6, Color3.fromRGB(0, 255, 255)),
                                ColorSequenceKeypoint.new(4 / 6, Color3.fromRGB(0, 0, 255)),
                                ColorSequenceKeypoint.new(5 / 6, Color3.fromRGB(255, 0, 255)),
                                ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 0, 0)),
                        }),
                        Rotation = 0,
                        Parent = hue,
                })
                local hdot = New("Frame", {
                        Position = UDim2.new(0, 0, 0, -1),
                        Size = UDim2.new(0, 12, 0, 12),
                        BackgroundTransparency = 1,
                        BorderSizePixel = 0,
                        ZIndex = 3,
                        Parent = hue,
                })
                corner(hdot, 6)
                stroke(hdot, Color3.new(1, 1, 1), 0, 2)

                New("TextLabel", { -- "HEX" caption
                        Position = UDim2.new(0, 0, 0, GEO.SVH + 9 + GEO.HueH + 9),
                        Size = UDim2.new(0, 0, 0, 14),
                        BackgroundTransparency = 1,
                        Font = F.Mono,
                        TextSize = 11,
                        TextColor3 = theme.TextFaint,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        Text = "HEX",
                        Parent = pop,
                })
                local hexVal = New("TextLabel", {
                        AnchorPoint = Vector2.new(1, 0),
                        Position = UDim2.new(1, 0, 0, GEO.SVH + 9 + GEO.HueH + 9),
                        Size = UDim2.new(0, 0, 0, 14),
                        AutomaticSize = Enum.AutomaticSize.X,
                        BackgroundTransparency = 1,
                        Font = F.Mono,
                        TextSize = 11,
                        TextColor3 = theme.TextMuted,
                        TextXAlignment = Enum.TextXAlignment.Right,
                        Text = "#0070F3",
                        Parent = pop,
                })

                local startColor
                if type(cfg.Value) == "string" then
                        startColor = hexToColor(cfg.Value)
                elseif typeof and typeof(cfg.Value) == "Color3" then
                        startColor = cfg.Value
                elseif cfg.Value and cfg.Value.R then
                        startColor = cfg.Value
                else
                        startColor = theme.Accent
                end
                local h, s, v = Color3.toHSV(startColor)
                local cp = { Hex = colorToHex(startColor) }

                local function render(fire)
                        local color = Color3.fromHSV(h, s, v)
                        local hex = colorToHex(color)
                        svGrad.Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromHSV(h, 1, 1))
                        local svw = sv.AbsoluteSize.X
                        if svw < 12 then svw = GEO.PopW - 20 end
                        dot.Position = UDim2.new(0, clamp(rnd(s * svw) - 6, 0, svw - 12), 0, clamp(rnd((1 - v) * GEO.SVH) - 6, 0, GEO.SVH - 12))
                        hdot.Position = UDim2.new(0, clamp(rnd(h / 360 * svw) - 6, 0, svw - 12), 0, -1)
                        swatch.BackgroundColor3 = color
                        hexLbl.Text = hex
                        hexVal.Text = hex
                        cp.Hex = hex
                        cp.Color = color
                        if fire and cfg.Callback then cfg.Callback(hex, color) end
                end

                local active = nil
                local function bindPad(el, apply)
                        el.InputBegan:Connect(function(input)
                                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                                        active = { el = el, apply = apply }
                                        apply(input)
                                end
                        end)
                end
                connect(UserInputService.InputChanged, function(input)
                        if active and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                                local el = active.el
                                local r = el.AbsolutePosition
                                local sz = el.AbsoluteSize
                                local insetY = GuiService:GetGuiInset().Y
                                local lx = input.Position.X - r.X
                                local ly = input.Position.Y + insetY - r.Y
                                if active.apply == "sv" then
                                        s = clamp(lx / sz.X, 0, 1)
                                        v = 1 - clamp(ly / sz.Y, 0, 1)
                                else
                                        h = clamp(lx / sz.X, 0, 1) * 360
                                end
                                render(true)
                        end
                end)
                connect(UserInputService.InputEnded, function(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                                active = nil
                        end
                end)
                bindPad(sv, "sv")
                bindPad(hue, "hue")

                local open = false
                local function setOpen(o)
                        if open == o then return end
                        open = o
                        row.ZIndex = o and 30 or 1
                        if o then
                                closeAllPops(pop)
                                pop.Visible = true
                                pop.Position = UDim2.new(1, -GEO.RowPad, 0, GEO.RowH + 10)
                                tween(pop, 0.16, { GroupTransparency = 0, Position = UDim2.new(1, -GEO.RowPad, 0, GEO.RowH + 6) })
                                registerPop(row, pop, setOpen)
                        else
                                tween(pop, 0.14, { GroupTransparency = 1, Position = UDim2.new(1, -GEO.RowPad, 0, GEO.RowH + 10) })
                                task.delay(0.16, function()
                                        if not open then pop.Visible = false end
                                end)
                                unregisterPop(pop)
                        end
                end
                trigger.Activated:Connect(function()
                        setOpen(not open)
                end)
                registerSearch(row, cfg.Text, section)
                render(false)

                function cp:Set(hex, fire)
                        local c = hexToColor(hex)
                        h, s, v = Color3.toHSV(c)
                        render(fire and true or false)
                end
                return cp
        end

        -- ---------- Input ----------
        local function addInput(section, cfg)
                cfg = cfg or {}
                local row = makeRow(section, GEO.RowH)
                rowLabel(row, cfg.Text)

                local box = New("TextBox", {
                        AnchorPoint = Vector2.new(1, 0.5),
                        Position = UDim2.new(1, -GEO.RowPad, 0.5, 0),
                        Size = UDim2.new(0, GEO.FieldW, 0, GEO.FieldH),
                        BackgroundColor3 = theme.Field,
                        BorderSizePixel = 0,
                        Text = tostring(cfg.Value or ""),
                        PlaceholderText = tostring(cfg.Placeholder or ""),
                        PlaceholderColor3 = theme.TextFaint,
                        Font = F.Regular,
                        TextSize = 13,
                        TextColor3 = theme.Text,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        ClearTextOnFocus = false,
                        ClipsDescendants = true,
                        ZIndex = 5,
                        Parent = row,
                })
                corner(box, 6)
                local bs = stroke(box, theme.LineStrong)
                padding(box, 0, 10, 0, 10)

                box.Focused:Connect(function()
                        bs.Color = theme.Accent
                        box.BackgroundColor3 = theme.Chip
                end)
                box.FocusLost:Connect(function(enter)
                        bs.Color = theme.LineStrong
                        box.BackgroundColor3 = theme.Field
                        if cfg.Callback then cfg.Callback(box.Text, enter and true or false) end
                end)
                registerSearch(row, cfg.Text, section)

                local inp = { Text = box.Text }
                function inp:Set(text)
                        box.Text = tostring(text)
                        inp.Text = box.Text
                end
                box:GetPropertyChangedSignal("Text"):Connect(function()
                        inp.Text = box.Text
                    if cfg.Live and cfg.Callback then cfg.Callback(box.Text, false) end
                end)
                return inp
        end

        -- ---------- Button ----------
        local function addButton(section, cfg)
                cfg = cfg or {}
                local btn = New("TextButton", {
                        Size = UDim2.new(1, 0, 0, GEO.RowH),
                        Text = tostring(cfg.Text or "Button"),
                        Font = F.Semibold,
                        TextSize = 13,
                        AutoButtonColor = false,
                        BorderSizePixel = 0,
                        ZIndex = 1,
                        Parent = section.Rows,
                })
                corner(btn, 8)
                local s
                if cfg.Primary then
                        btn.BackgroundColor3 = theme.Accent
                        btn.BackgroundColor3 = theme.Accent
                        btn.TextColor3 = Color3.new(1, 1, 1)
                        btn.MouseEnter:Connect(function()
                                tween(btn, 0.13, { BackgroundColor3 = theme.AccentHover })
                        end)
                        btn.MouseLeave:Connect(function()
                                tween(btn, 0.13, { BackgroundColor3 = theme.Accent })
                        end)
                else
                        btn.BackgroundColor3 = theme.RowHover
                        btn.BackgroundTransparency = 1
                        btn.TextColor3 = theme.TextMuted
                        s = stroke(btn, theme.Line)
                        btn.MouseEnter:Connect(function()
                                btn.BackgroundTransparency = 0
                                btn.TextColor3 = theme.Text
                                s.Color = theme.LineStrong
                        end)
                        btn.MouseLeave:Connect(function()
                                btn.BackgroundTransparency = 1
                                btn.TextColor3 = theme.TextMuted
                                s.Color = theme.Line
                        end)
                end
                btn.Activated:Connect(function()
                        if cfg.Callback then cfg.Callback() end
                end)
                registerSearch(btn, cfg.Text, section)
                local b = { Button = btn }
                function b:Set(text)
                        btn.Text = tostring(text)
                end
                return b
        end

        -- ---------- Paragraph ----------
        local function addParagraph(section, cfg)
                cfg = cfg or {}
                local lbl = New("TextLabel", {
                        Size = UDim2.new(1, 0, 0, 0),
                        AutomaticSize = Enum.AutomaticSize.Y,
                        BackgroundTransparency = 1,
                        Font = F.Regular,
                        TextSize = 13,
                        TextColor3 = theme.TextMuted,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        TextYAlignment = Enum.TextYAlignment.Top,
                        TextWrapped = true,
                        Text = tostring(cfg.Text or ""),
                        Parent = section.Rows,
                })
                padding(lbl, 2, 2, 2, 2)
                registerSearch(lbl, cfg.Text, section)
                local p = { Label = lbl }
                function p:Set(text)
                        lbl.Text = tostring(text)
                end
                return p
        end

        -- ============================================================
        --  Sections / Tabs
        -- ============================================================
        local function newSection(tab, name, badge)
                local parent = tab.Page
                if tab.Columns then
                        parent = tab.Columns[tab._nextCol]
                        tab._nextCol = tab._nextCol == 1 and 2 or 1
                end

                local sec = New("Frame", {
                        Size = UDim2.new(1, 0, 0, 0),
                        AutomaticSize = Enum.AutomaticSize.Y,
                        BackgroundTransparency = 1,
                        Parent = parent,
                })

                -- header: title + optional badge + flex line (measured, manual layout)
                local head = New("Frame", {
                        Position = UDim2.new(0, 2, 0, 0),
                        Size = UDim2.new(1, -4, 0, 14),
                        BackgroundTransparency = 1,
                        Parent = sec,
                })
                local titleText = string.upper(tostring(name or ""))
                local titleW = measureText(titleText, 11, F.Semibold)
                New("TextLabel", {
                        Size = UDim2.new(0, 0, 0, 14),
                        AutomaticSize = Enum.AutomaticSize.X,
                        BackgroundTransparency = 1,
                        Font = F.Semibold,
                        TextSize = 11,
                        TextColor3 = theme.TextFaint,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        Text = titleText,
                        Parent = head,
                })
                local badgeW = 0
                if badge then
                        local btext = string.upper(tostring(badge))
                        badgeW = measureText(btext, 10, F.Bold) + 10
                        local bd = New("Frame", {
                                Position = UDim2.new(0, titleW + 10, 0, -1),
                                Size = UDim2.new(0, badgeW, 0, 16),
                                BackgroundTransparency = 1,
                                Parent = head,
                        })
                        corner(bd, 4)
                        stroke(bd, theme.Accent, 0.6)
                        padding(bd, 2, 5, 2, 5)
                        New("TextLabel", {
                                Size = UDim2.new(1, 0, 1, 0),
                                BackgroundTransparency = 1,
                                Font = F.Bold,
                                TextSize = 10,
                                TextColor3 = theme.Accent,
                                Text = btext,
                                Parent = bd,
                        })
                        badgeW = badgeW + 10 + 2
                end
                New("Frame", {
                        Position = UDim2.new(0, titleW + badgeW + 2, 0, 7),
                        Size = UDim2.new(1, -(titleW + badgeW + 4), 0, 1),
                        BackgroundColor3 = theme.Line,
                        BorderSizePixel = 0,
                        Parent = head,
                })

                local rows = New("Frame", {
                        Position = UDim2.new(0, 0, 0, 23),
                        Size = UDim2.new(1, 0, 0, 0),
                        AutomaticSize = Enum.AutomaticSize.Y,
                        BackgroundTransparency = 1,
                        Parent = sec,
                })
                list(rows, GEO.RowGap)

                local section = { Frame = sec, Rows = rows, _tab = tab }
                table.insert(state.sections, section)

                function section:Toggle(cfg2) return addToggle(section, cfg2) end
                function section:Slider(cfg2) return addSlider(section, cfg2) end
                function section:Dropdown(cfg2) return addDropdown(section, cfg2) end
                function section:Keybind(cfg2) return addKeybind(section, cfg2) end
                function section:ColorPicker(cfg2) return addColorPicker(section, cfg2) end
                function section:Input(cfg2) return addInput(section, cfg2) end
                function section:Button(cfg2) return addButton(section, cfg2) end
                function section:Paragraph(cfg2) return addParagraph(section, cfg2) end
                return section
        end

        local function addTab(name)
                local btn = New("TextButton", {
                        Size = UDim2.new(1, 0, 0, GEO.TabH),
                        BackgroundTransparency = 1,
                        BackgroundColor3 = theme.RowHover,
                        Text = tostring(name or "Tab"),
                        Font = F.Medium,
                        TextSize = 13,
                        TextColor3 = theme.TextMuted,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        AutoButtonColor = false,
                        Parent = tabsHolder,
                })
                corner(btn, 8)
                padding(btn, 0, 12, 0, 12)

                local page = New("Frame", {
                        Size = UDim2.new(1, 0, 0, 0),
                        AutomaticSize = Enum.AutomaticSize.Y,
                        BackgroundTransparency = 1,
                        Visible = false,
                        Parent = content,
                })
                padding(page, GEO.ContentPadT, GEO.ContentPadS, GEO.ContentPadB, GEO.ContentPadS)
                local pageList = list(page, GEO.SectionGap)

                local tab = {
                        Name = name,
                        Button = btn,
                        Page = page,
                        Columns = nil,
                        _nextCol = 1,
                        _pageList = pageList,
                }

                local function setActive(active)
                        btn.BackgroundTransparency = active and 0 or 1
                        btn.TextColor3 = active and theme.Text or theme.TextMuted
                        btn.Font = active and F.Semibold or F.Medium
                end
                btn.MouseEnter:Connect(function()
                        if not page.Visible then
                                btn.BackgroundTransparency = 0
                                btn.TextColor3 = theme.Text
                        end
                end)
                btn.MouseLeave:Connect(function()
                        if not page.Visible then
                                btn.BackgroundTransparency = 1
                                btn.TextColor3 = theme.TextMuted
                        end
                end)
                btn.Activated:Connect(function()
                        for _, t in ipairs(state.tabs) do
                                t.Page.Visible = (t == tab)
                                t._setActive(false)
                        end
                        tab._setActive(true)
                        page.Visible = true
                        content.CanvasPosition = Vector2.new(0, 0)
                end)
                tab._setActive = setActive

                -- two-column mode (Vercel dashboard grid): equal columns + 8px gutter.
                -- Window W is even and (W - 200) is even, so each column is a whole
                -- number of pixels — row borders stay on the pixel grid.
                function tab:SetColumns(n)
                        if n ~= 2 then return end
                        if tab.Columns then return end
                        pageList:Destroy()
                        local colW = (W - 192 - GEO.GridGap) / 2
                        tab.Columns = {}
                        for i = 1, 2 do
                                local col = New("Frame", {
                                        Position = UDim2.new(0, (i - 1) * (colW + GEO.GridGap), 0, 0),
                                        Size = UDim2.new(0, colW, 0, 0),
                                        AutomaticSize = Enum.AutomaticSize.Y,
                                        BackgroundTransparency = 1,
                                        Parent = page,
                                })
                                list(col, GEO.SectionGap)
                                tab.Columns[i] = col
                        end
                        -- move existing sections into alternating columns
                        -- snapshot first: reparenting mutates GetChildren order
                        local kids = {}
                        for _, child in ipairs(page:GetChildren()) do
                                if child ~= tab.Columns[1] and child ~= tab.Columns[2] and child:IsA("GuiObject") and not child:IsA("UIListLayout") then
                                        table.insert(kids, child)
                                end
                        end
                        local nextCol = 1
                        for _, child in ipairs(kids) do
                                child.Size = UDim2.new(1, 0, 0, 0)
                                child.Position = UDim2.new(0, 0, 0, 0)
                                child.Parent = tab.Columns[nextCol]
                                nextCol = nextCol == 1 and 2 or 1
                        end
                        tab._nextCol = nextCol
                end

                function tab:Section(name2, badge2)
                        return newSection(tab, name2, badge2)
                end

                table.insert(state.tabs, tab)
                if #state.tabs == 1 then
                        page.Visible = true
                        setActive(true)
                end
                return tab
        end

        -- ============================================================
        --  Global input router (keybind capture, bound keys, outside click)
        -- ============================================================
        local function inRect(el, m)
                local p, sz = el.AbsolutePosition, el.AbsoluteSize
                return m.X >= p.X - 1 and m.X <= p.X + sz.X + 1 and m.Y >= p.Y - 1 and m.Y <= p.Y + sz.Y + 1
        end

        connect(UserInputService.InputBegan, function(input, gameProcessed)
                -- 1. keybind capture mode (keys; Escape cancels)
                if state.listening and input.UserInputType == Enum.UserInputType.Keyboard then
                        if input.KeyCode == Enum.KeyCode.Escape then
                                state.listening._cancel()
                        else
                                state.listening._commit(keyDisplayName(input.KeyCode.Name), input.KeyCode, nil)
                        end
                        return
                end
                -- 2. bound keys fire
                if not gameProcessed then
                        for _, kb in ipairs(state.keybinds) do
                                local matched = false
                                if kb.KeyCode and input.KeyCode == kb.KeyCode then matched = true end
                                if kb.UserInputType and input.UserInputType == kb.UserInputType then matched = true end
                                if matched and kb.Callback then
                                        kb.Callback(kb.Name, input, gameProcessed)
                                end
                        end
                end
                -- 3. outside click closes popovers / cancels listening
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        local m
                        if input.UserInputType == Enum.UserInputType.Touch then
                                local insetY = GuiService:GetGuiInset().Y
                                m = Vector2.new(input.Position.X, input.Position.Y + insetY)
                        else
                                m = UserInputService:GetMouseLocation()
                        end
                        for i = #state.openPops, 1, -1 do
                                local p = state.openPops[i]
                                if not inRect(p.row, m) and not inRect(p.pop, m) then
                                        p.close()
                                end
                        end
                        if state.listening and not gameProcessed then
                                local chip = state.listening._chip
                                if chip == nil then
                                        chip = state.listening.Chip
                                end
                                if chip == nil or not inRect(chip, m) then
                                        state.listening._cancel()
                                end
                        end
                end
                -- 4. Escape closes open popovers
                if input.KeyCode == Enum.KeyCode.Escape then
                        for i = #state.openPops, 1, -1 do
                                state.openPops[i].close()
                        end
                end
        end)

        -- ============================================================
        --  Public window API
        -- ============================================================
        local Window = {
                Title = tostring(config.Title or "Reborn"),
                Theme = theme,
                Gui = gui,
        }

        function Window:Tab(name)
                return addTab(name)
        end

        function Window:Notify(cfg)
                if not Reborn.NotificationsEnabled then return end
                toastLayer.Notify(cfg)
        end

        function Window:Search(q)
                applyFilter(q)
        end

        function Window:SetTitle(t)
                Window.Title = tostring(t)
                local lbl = dragZone:FindFirstChildOfClass("TextLabel")
                if lbl then lbl.Text = tostring(t) end
        end

        function Window:SetVisible(v)
                if v then
                        reopen()
                else
                        closeWindow()
                end
        end

        function Window:Toggle()
                if state.closed then
                        reopen()
                else
                        closeWindow()
                end
        end

        function Window:Minimize()
                setMinimized(true)
        end

        function Window:Destroy()
                for _, c in ipairs(conns) do
                        pcall(function() c:Disconnect() end)
                end
                for i, w in ipairs(Reborn._windows) do
                        if w == Window then
                                table.remove(Reborn._windows, i)
                                break
                        end
                end
                gui:Destroy()
        end

        table.insert(Reborn._windows, Window)
        return Window
end

function Reborn:Destroy()
        for _, w in ipairs(self._windows) do
                pcall(function() w:Destroy() end)
        end
        self._windows = {}
end

return Reborn
