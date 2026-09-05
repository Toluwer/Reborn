local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local TextService = game:GetService("TextService")
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")

local Reborn = {
        Version = "0.6.0",
        NotificationsEnabled = true,
        _windows = {},
}

local DEFAULT_THEME = {
        Background   = Color3.fromRGB(0, 0, 0),
        Surface      = Color3.fromRGB(0, 0, 0),
        Overlay      = Color3.fromRGB(17, 17, 17),
        Chip         = Color3.fromRGB(26, 26, 26),
        RowHover     = Color3.fromRGB(26, 26, 26),
        OptionHover  = Color3.fromRGB(38, 38, 38),
        Line         = Color3.fromRGB(38, 38, 38),
        LineStrong   = Color3.fromRGB(51, 51, 51),
        Text         = Color3.fromRGB(237, 237, 237),
        TextMuted    = Color3.fromRGB(161, 161, 161),
        TextFaint    = Color3.fromRGB(136, 136, 136),
        Accent       = Color3.fromRGB(0, 112, 243),
        AccentHover  = Color3.fromRGB(50, 145, 255),
        Success      = Color3.fromRGB(41, 211, 145),
        Error        = Color3.fromRGB(238, 0, 0),
        ToggleOff    = Color3.fromRGB(31, 31, 31),
        Handle       = Color3.fromRGB(255, 255, 255),
}

Reborn.Theme = DEFAULT_THEME

local F = {
        Regular  = Enum.Font.Gotham,
        Medium   = Enum.Font.GothamMedium,
        Semibold = Enum.Font.GothamSemibold,
        Bold     = Enum.Font.GothamBold,
        Mono     = Enum.Font.Code,
}

local GEO = {
        WindowMaxW   = 700,
        WindowMaxH   = 530,
        WindowRadius = 8,
        Header       = 47,
        HeaderPad    = 14,
        WinBtn       = 44,
        WinBtnH      = 36,
        SearchW      = 150,
        SearchH      = 32,
        Sidebar      = 155,
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
        PopW         = 172,
        SVH          = 92,
        HueH         = 10,
        FieldW       = 180,
        FieldH       = 30,
        ToastW       = 294,
        Launcher     = 46,
        GridGap      = 8,
}

local function rnd(x) return math.floor(x + 0.5) end
local function clamp(v, a, b)
        if v < a then return a elseif v > b then return b end
        return v
end

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

local liveTweens = setmetatable({}, { __mode = "kv" })

local function tween(inst, time, props, style, dir)
        local reg = liveTweens[inst]
        if reg == nil then
                reg = {}
                liveTweens[inst] = reg
        end
        for k in pairs(props) do
                local prev = reg[k]
                if prev then
                        prev:Cancel()
                        reg[k] = nil
                end
        end
        local t = TweenService:Create(inst, TweenInfo.new(
                time,
                style or Enum.EasingStyle.Quad,
                dir or Enum.EasingDirection.Out
        ), props)
        for k in pairs(props) do reg[k] = t end
        t:Play()
        return t
end

local function killTween(inst, prop)
        local reg = liveTweens[inst]
        if reg == nil then return end
        local t = reg[prop]
        if t then
                t:Cancel()
                reg[prop] = nil
        end
end

local function measureText(text, size, font)
        local ok, w = pcall(function()
                return TextService:GetTextSize(text, size, font, Vector2.new(4096, size * 2)).X
        end)
        if ok and w then return w end
        return rnd(#text * size * 0.58)
end

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

local function keyDisplayName(name)
        return (name:gsub("(%l)(%u)", "%1 %2"))
end

local MOUSE_NAMES = {
        [Enum.UserInputType.MouseButton1] = "Left Mouse",
        [Enum.UserInputType.MouseButton2] = "Right Mouse",
        [Enum.UserInputType.MouseButton3] = "Middle Mouse",
}

local ICONS = {
        activity = { 16898612629, 514, 771 },
        antenna = { 16898612629, 869, 563 },
        ["at-sign"] = { 16898612629, 453, 869 },
        battery = { 16898612629, 967, 857 },
        bell = { 16898612819, 820, 257 },
        bluetooth = { 16898612819, 771, 355 },
        bomb = { 16898612819, 257, 869 },
        bookmark = { 16898612819, 514, 918 },
        braces = { 16898612819, 147, 820 },
        bug = { 16898612819, 257, 967 },
        camera = { 16898612819, 967, 563 },
        check = { 16898612819, 710, 869 },
        ["chevron-down"] = { 16898612819, 196, 918 },
        ["chevron-left"] = { 16898612819, 404, 967 },
        ["chevron-right"] = { 16898612819, 869, 759 },
        ["chevron-up"] = { 16898612819, 710, 918 },
        ["circle-alert"] = { 16898612819, 918, 808 },
        ["circle-check"] = { 16898612819, 869, 955 },
        ["circle-help"] = { 16898613044, 820, 257 },
        ["circle-x"] = { 16898613044, 820, 306 },
        clock = { 16898613044, 771, 661 },
        cloud = { 16898613044, 918, 306 },
        code = { 16898613044, 355, 869 },
        coins = { 16898613044, 869, 612 },
        compass = { 16898613044, 514, 967 },
        copy = { 16898613044, 918, 612 },
        cpu = { 16898613044, 196, 869 },
        crosshair = { 16898613044, 453, 869 },
        crown = { 16898613044, 404, 918 },
        database = { 16898613044, 710, 869 },
        ["dollar-sign"] = { 16898613044, 820, 857 },
        download = { 16898613044, 820, 906 },
        expand = { 16898613353, 306, 771 },
        eye = { 16898613353, 771, 563 },
        ["eye-off"] = { 16898613353, 820, 514 },
        ["file-code"] = { 16898613353, 869, 49 },
        filter = { 16898613353, 612, 869 },
        flame = { 16898613353, 967, 306 },
        focus = { 16898613353, 771, 759 },
        folder = { 16898613353, 404, 967 },
        ["gamepad-2"] = { 16898613353, 710, 967 },
        gauge = { 16898613353, 771, 955 },
        gem = { 16898613353, 918, 857 },
        ghost = { 16898613353, 869, 906 },
        globe = { 16898613509, 771, 563 },
        ["grid-2x2"] = { 16898613509, 771, 98 },
        grip = { 16898613509, 869, 257 },
        ["grip-vertical"] = { 16898613509, 0, 869 },
        hammer = { 16898613509, 306, 820 },
        hand = { 16898613509, 563, 820 },
        hash = { 16898613509, 147, 771 },
        heart = { 16898613509, 661, 771 },
        home = { 16898613509, 820, 147 },
        info = { 16898613509, 612, 869 },
        joystick = { 16898613509, 196, 820 },
        key = { 16898613509, 869, 404 },
        keyboard = { 16898613509, 453, 820 },
        layers = { 16898613509, 98, 967 },
        ["layout-grid"] = { 16898613509, 918, 404 },
        lightbulb = { 16898613509, 918, 196 },
        list = { 16898613509, 869, 808 },
        ["loader-circle"] = { 16898613509, 771, 906 },
        ["locate-fixed"] = { 16898613509, 967, 759 },
        lock = { 16898613509, 918, 857 },
        ["log-out"] = { 16898613509, 820, 955 },
        map = { 16898613613, 306, 771 },
        maximize = { 16898613613, 771, 563 },
        ["message-circle"] = { 16898613613, 563, 820 },
        minimize = { 16898613613, 918, 49 },
        minus = { 16898613613, 771, 196 },
        moon = { 16898613613, 306, 918 },
        ["mouse-pointer-2"] = { 16898613613, 820, 661 },
        move = { 16898613613, 453, 820 },
        music = { 16898613613, 967, 563 },
        package = { 16898613613, 918, 196 },
        palette = { 16898613613, 453, 918 },
        ["panel-left"] = { 16898613613, 967, 453 },
        play = { 16898613699, 918, 257 },
        plus = { 16898613699, 257, 918 },
        pointer = { 16898613699, 661, 771 },
        power = { 16898613699, 820, 147 },
        puzzle = { 16898613699, 49, 918 },
        radar = { 16898613699, 820, 404 },
        radio = { 16898613699, 306, 918 },
        ["refresh-cw"] = { 16898613699, 404, 869 },
        ["rotate-ccw"] = { 16898613699, 967, 355 },
        ["rotate-cw"] = { 16898613699, 869, 453 },
        scan = { 16898613699, 967, 196 },
        search = { 16898613699, 918, 857 },
        server = { 16898613777, 771, 0 },
        settings = { 16898613777, 771, 257 },
        shield = { 16898613777, 869, 0 },
        ["shield-check"] = { 16898613777, 820, 257 },
        ["shield-half"] = { 16898613777, 306, 771 },
        shrink = { 16898613777, 355, 771 },
        skull = { 16898613777, 49, 869 },
        ["sliders-horizontal"] = { 16898613777, 820, 355 },
        sparkles = { 16898613777, 918, 49 },
        ["square-check"] = { 16898613777, 563, 918 },
        star = { 16898613777, 967, 147 },
        sun = { 16898613777, 967, 453 },
        sword = { 16898613777, 710, 967 },
        swords = { 16898613777, 967, 759 },
        target = { 16898613869, 514, 771 },
        terminal = { 16898613869, 820, 257 },
        timer = { 16898613869, 918, 0 },
        ["toggle-left"] = { 16898613869, 869, 49 },
        ["trash-2"] = { 16898613869, 257, 918 },
        ["triangle-alert"] = { 16898613869, 967, 0 },
        upload = { 16898613869, 612, 869 },
        user = { 16898613869, 661, 869 },
        users = { 16898613869, 967, 98 },
        ["volume-2"] = { 16898613869, 771, 808 },
        wand = { 16898613869, 404, 967 },
        ["wand-sparkles"] = { 16898613869, 453, 918 },
        wifi = { 16898613869, 869, 808 },
        ["wifi-off"] = { 16898613869, 918, 759 },
        wrench = { 16898613869, 820, 906 },
        x = { 16898613869, 869, 906 },
        zap = { 16898613869, 918, 906 },
        ["zoom-in"] = { 16898613869, 869, 955 },
        ["zoom-out"] = { 16898613869, 967, 906 },
}

local function icon(parent, name, size, color)
        local d = ICONS[name]
        if d == nil then return nil end
        return New("ImageLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.new(0, size, 0, size),
                Image = "rbxassetid://" .. string.format("%.0f", d[1]),
                ImageRectSize = Vector2.new(48, 48),
                ImageRectOffset = Vector2.new(d[2], d[3]),
                ImageColor3 = color or Color3.new(1, 1, 1),
                BorderSizePixel = 0,
                Parent = parent,
        })
end

task.spawn(function()
        pcall(function()
                local cp = game:GetService("ContentProvider")
                local seen, list = {}, {}
                for _, d in pairs(ICONS) do
                        local u = "rbxassetid://" .. string.format("%.0f", d[1])
                        if not seen[u] then
                                seen[u] = true
                                table.insert(list, u)
                        end
                end
                cp:PreloadAsync(list)
        end)
end)

local function resolveParent(config)
        if config and config.Parent then return config.Parent, false end
        local ok, hidden = pcall(function()
                if gethui then return gethui() end
                return nil
        end)
        if ok and type(hidden) == "Instance" then return hidden, true end
        local okCore = pcall(function()
                local probe = Instance.new("Folder")
                probe.Parent = game:GetService("CoreGui")
                probe:Destroy()
        end)
        if okCore then return game:GetService("CoreGui"), false end
        local player = Players.LocalPlayer
        if player then
                local pg = player:FindFirstChild("PlayerGui")
                if pg then return pg, false end
                local okWait, waited = pcall(function()
                        return player:WaitForChild("PlayerGui", 5)
                end)
                if okWait and waited then return waited, false end
        end
        error("Reborn: no usable GUI parent (no gethui, no CoreGui access, no LocalPlayer) — pass config.Parent")
end

local MARK = "__r"

local function randomName()
        local t = {}
        for i = 1, 12 do
                t[i] = string.char(97 + math.random(0, 25))
        end
        return table.concat(t)
end

local function protectGui(g)
        pcall(function()
                if syn and syn.protect_gui then syn.protect_gui(g) end
        end)
        pcall(function()
                if protect_gui then protect_gui(g) end
        end)
end

local function clearOld(parent)
        for _, child in ipairs(parent:GetChildren()) do
                if child:GetAttribute(MARK) then child:Destroy() end
        end
end

local TOAST_TYPES = {
        info    = { color = DEFAULT_THEME.Accent,  name = "info" },
        success = { color = DEFAULT_THEME.Success, name = "circle-check" },
        error   = { color = DEFAULT_THEME.Error,   name = "circle-x" },
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

        local function toastHeight(cfg)
                local desc = tostring(cfg.Description or "")
                local lines = 1
                if desc ~= "" then
                        local w = measureText(desc, 12)
                        lines = math.max(1, math.ceil(w / math.max(GEO.ToastW - 39, 40)))
                end
                return 22 + math.max(16, 18 + (lines * 15 + 4))
        end

        local function relayout(animate)
                local y = 0
                for _, item in ipairs(state.items) do
                        local h = item.toast.AbsoluteSize.Y
                        if h < 12 then h = item.estH or 46 end
                        if animate then
                                tween(item.toast, 0.18, { Position = UDim2.new(0, 0, 0, y) })
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
                tween(item.toast, 0.22, { Position = UDim2.new(0, GEO.ToastW + 18, 0, item.toast.Position.Y.Offset) })
                task.delay(0.24, function()
                        if item.toast then item.toast:Destroy() end
                end)
                relayout(true)
        end

        local function notify(cfg)
                cfg = cfg or {}
                local kind = TOAST_TYPES[cfg.Type] or TOAST_TYPES.info
                local toast = New("Frame", {
                        Position = UDim2.new(0, GEO.ToastW + 18, 0, 0),
                        Size = UDim2.new(0, GEO.ToastW, 0, 0),
                        AutomaticSize = Enum.AutomaticSize.Y,
                        BackgroundColor3 = theme.Overlay,
                        BackgroundTransparency = 0.06,
                        BorderSizePixel = 0,
                        Parent = layer,
                })
                corner(toast, 8)
                stroke(toast, theme.LineStrong)
                padding(toast, 11, 12, 11, 12)

                local ic = icon(toast, kind.name, 16, kind.color)
                ic.Position = UDim2.new(0, 0, 0, 0)

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

                local hit = New("TextButton", {
                        Size = UDim2.new(1, 0, 1, 0),
                        BackgroundTransparency = 1,
                        Text = "",
                        AutoButtonColor = false,
                        ZIndex = 10,
                        Parent = toast,
                })
                local item = { toast = toast, closed = false, estH = toastHeight(cfg) }
                hit.Activated:Connect(function() dismiss(item) end)
                table.insert(state.items, item)
                while #state.items > 5 do
                        dismiss(state.items[1])
                end
                relayout(false)
                local targetY = toast.Position.Y.Offset
                toast.Position = UDim2.new(0, GEO.ToastW + 18, 0, targetY)
                tween(toast, 0.24, { Position = UDim2.new(0, 0, 0, targetY) }, Enum.EasingStyle.Quint)
                task.defer(function()
                        if not item.closed then relayout(true) end
                end)
                task.delay(cfg.Duration or 3.6, function() dismiss(item) end)
                return item
        end

        return { Layer = layer, Notify = notify }
end

local function normNotify(a, b)
        if type(a) == "string" then
                local t = { Title = a }
                if type(b) == "string" then t.Description = b end
                return t
        end
        return a or {}
end

local function normCfg(a, b)
        if type(a) == "string" then a = { Text = a } end
        if type(b) == "function" and a and a.Callback == nil then a.Callback = b end
        return a or {}
end

function Reborn:Notify(a, b)
        local cfg = normNotify(a, b)
        if not self.NotificationsEnabled then return end
        if #self._windows > 0 then
                local w = self._windows[#self._windows]
                w:Notify(cfg)
                return
        end
        if not self._toastGui or not self._toastGui.Parent then
                local tparent, viaHidden = resolveParent(nil)
                clearOld(tparent)
                self._toastGui = New("ScreenGui", {
                        Name = randomName(),
                        ResetOnSpawn = false,
                        IgnoreGuiInset = true,
                        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
                        DisplayOrder = math.random(900001, 999999),
                })
                self._toastGui:SetAttribute(MARK, true)
                if not viaHidden then protectGui(self._toastGui) end
                self._toastGui.Parent = tparent
                self._toastLayer = buildToastLayer(self._toastGui, DEFAULT_THEME)
        end
        self._toastLayer.Notify(cfg)
end

function Reborn:CreateWindow(config)
        config = config or {}

        local theme = {}
        for k, v in pairs(DEFAULT_THEME) do theme[k] = v end
        if config.Theme then
                for k, v in pairs(config.Theme) do theme[k] = v end
        end

        local parent, viaHidden = resolveParent(config)
        clearOld(parent)
        for i = #Reborn._windows, 1, -1 do
                local w = Reborn._windows[i]
                if not w.Gui or w.Gui.Parent == nil then table.remove(Reborn._windows, i) end
        end

        local gui = New("ScreenGui", {
                Name = randomName(),
                ResetOnSpawn = false,
                IgnoreGuiInset = true,
                ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
                DisplayOrder = math.random(100000, 900000),
        })
        gui:SetAttribute(MARK, true)
        if not viaHidden then protectGui(gui) end
        gui.Parent = parent

        local conns = {}
        local function connect(signal, fn)
                local c = signal:Connect(fn)
                table.insert(conns, c)
                return c
        end

        local camera = workspace.CurrentCamera or workspace:FindFirstChildOfClass("Camera")
        local function viewportSize()
                local c = workspace.CurrentCamera or camera
                if c then return c.ViewportSize end
                return Vector2.new(1920, 1080)
        end

        local function computeSize()
                local v = viewportSize()
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
                listening = nil,
                openPops = {},
                keybinds = {},
                searchRows = {},
                sections = {},
                tabs = {},
        }

        local Window = nil

        local windowFrame = New("Frame", {
                Name = randomName(),
                Size = UDim2.new(0, W, 0, H),
                BackgroundColor3 = theme.Surface,
                BorderSizePixel = 0,
                ClipsDescendants = true,
                Parent = gui,
        })
        corner(windowFrame, GEO.WindowRadius)
        stroke(windowFrame, theme.LineStrong)

        local function recenter()
                if state.dragged or state.closed then return end
                killTween(windowFrame, "Position")
                local v = viewportSize()
                windowFrame.Position = UDim2.new(0, rnd(v.X / 2 - W / 2), 0, rnd(v.Y / 2 - H / 2))
        end
        recenter()
        do
                local tx, ty = windowFrame.Position.X.Offset, windowFrame.Position.Y.Offset
                windowFrame.Position = UDim2.new(0, tx, 0, ty + 14)
                tween(windowFrame, 0.38, {
                        Position = UDim2.new(0, tx, 0, ty),
                }, Enum.EasingStyle.Quint)
        end

        if camera then
                connect(camera:GetPropertyChangedSignal("ViewportSize"), function()
                        recenter()
                end)
        end

        local header = New("Frame", {
                Size = UDim2.new(1, 0, 0, GEO.Header),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                ZIndex = 20,
                Parent = windowFrame,
        })
        New("Frame", {
                Position = UDim2.new(0, 0, 1, -1),
                Size = UDim2.new(1, 0, 0, 1),
                BackgroundColor3 = theme.Line,
                BorderSizePixel = 0,
                Parent = header,
        })

        local clusterW = GEO.SearchW + 9 + 28 + 9 + GEO.WinBtn + 9 + GEO.WinBtn

        local dragZone = New("Frame", {
                Position = UDim2.new(0, GEO.HeaderPad, 0, 0),
                Size = UDim2.new(1, -GEO.HeaderPad - clusterW - 9 - 12, 0, GEO.Header),
                BackgroundTransparency = 1,
                Parent = header,
        })
        New("TextLabel", {
                AnchorPoint = Vector2.new(0, 0.5),
                Position = UDim2.new(0, 0, 0.5, 0),
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

        local function captionBtn(x, iconName, isClose)
                local b = New("TextButton", {
                        Position = UDim2.new(0, x, 0, 5),
                        Size = UDim2.new(0, GEO.WinBtn, 0, GEO.WinBtnH),
                        BackgroundTransparency = 1,
                        Text = "",
                        AutoButtonColor = false,
                        Parent = cluster,
                })
                corner(b, 6)
                local ic = icon(b, iconName, 18, theme.TextFaint)
                ic.Position = UDim2.new(0.5, -9, 0.5, -9)
                b.MouseEnter:Connect(function()
                        if isClose then
                                b.BackgroundColor3 = theme.Error
                                ic.ImageColor3 = theme.Error
                                tween(b, 0.12, { BackgroundTransparency = 0.88 })
                        else
                                b.BackgroundColor3 = theme.RowHover
                                ic.ImageColor3 = theme.Text
                                tween(b, 0.12, { BackgroundTransparency = 0 })
                        end
                end)
                b.MouseLeave:Connect(function()
                        ic.ImageColor3 = theme.TextFaint
                        tween(b, 0.12, { BackgroundTransparency = 1 })
                end)
                return b, ic
        end

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
        corner(searchBox, 6)
        local searchStroke = stroke(searchBox, theme.LineStrong, 1)
        padding(searchBox, 0, 9, 0, 9)

        local searchBtn = New("TextButton", {
                Position = UDim2.new(0, GEO.SearchW + 9, 0, 10),
                Size = UDim2.new(0, 28, 0, 28),
                BackgroundTransparency = 1,
                BackgroundColor3 = theme.RowHover,
                Text = "",
                AutoButtonColor = false,
                Parent = cluster,
        })
        corner(searchBtn, 6)
        local searchIcon = icon(searchBtn, "search", 18, theme.TextFaint)
        searchIcon.Position = UDim2.new(0.5, -9, 0.5, -9)
        searchBtn.MouseEnter:Connect(function()
                tween(searchBtn, 0.12, { BackgroundTransparency = 0 })
                tween(searchIcon, 0.12, { ImageColor3 = theme.Text })
        end)
        searchBtn.MouseLeave:Connect(function()
                tween(searchBtn, 0.12, { BackgroundTransparency = 1 })
                tween(searchIcon, 0.12, { ImageColor3 = theme.TextFaint })
        end)
        local minBtn, minIcon = captionBtn(GEO.SearchW + 9 + 28 + 9, "minus", false)
        local plusIcon = icon(minBtn, "plus", 18, theme.TextFaint)
        plusIcon.Position = UDim2.new(0.5, -9, 0.5, -9)
        plusIcon.Visible = false
        local closeBtn = captionBtn(GEO.SearchW + 9 + 28 + 9 + GEO.WinBtn + 9, "x", true)

        local bodyGroup = New("Frame", {
                Position = UDim2.new(0, 0, 0, GEO.Header),
                Size = UDim2.new(1, 0, 1, -GEO.Header),
                BackgroundTransparency = 1,
                Parent = windowFrame,
        })

        local sidebar = New("Frame", {
                Size = UDim2.new(0, GEO.Sidebar, 1, 0),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Parent = bodyGroup,
        })
        New("Frame", {
                Position = UDim2.new(0, GEO.Sidebar, 0, 0),
                Size = UDim2.new(0, 1, 1, 0),
                BackgroundColor3 = theme.Line,
                BorderSizePixel = 0,
                Parent = sidebar,
        })

        local tabsHolder = New("Frame", {
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                ClipsDescendants = true,
                Parent = sidebar,
        })
        padding(tabsHolder, 10, 10, 8, 10)
        list(tabsHolder, 3)

        local content = New("ScrollingFrame", {
                Position = UDim2.new(0, GEO.Sidebar + 1, 0, 0),
                Size = UDim2.new(1, -(GEO.Sidebar + 1), 1, 0),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                ScrollBarThickness = 8,
                ScrollBarImageColor3 = Color3.fromRGB(46, 46, 46),
                ScrollingDirection = Enum.ScrollingDirection.Y,
                CanvasSize = UDim2.new(0, 0, 0, 0),
                AutomaticCanvasSize = Enum.AutomaticSize.Y,
                Parent = bodyGroup,
        })

        local launcher = New("Frame", {
                AnchorPoint = Vector2.new(1, 1),
                Position = UDim2.new(1, -22, 1, -22),
                Size = UDim2.new(0, GEO.Launcher, 0, GEO.Launcher),
                BackgroundColor3 = theme.Overlay,
                BorderSizePixel = 0,
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
                tween(launcher, 0.12, { BackgroundColor3 = theme.Chip })
        end)
        launcher.MouseLeave:Connect(function()
                tween(launcher, 0.12, { BackgroundColor3 = theme.Overlay })
        end)

        local toastLayer = buildToastLayer(gui, theme)

        local dragState = nil
        dragZone.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        state.dragged = true
                        killTween(windowFrame, "Position")
                        local p = windowFrame.Position
                        dragState = { sx = input.Position.X, sy = input.Position.Y, ox = p.X.Offset, oy = p.Y.Offset }
                end
        end)
        connect(UserInputService.InputChanged, function(input)
                if dragState and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                        killTween(windowFrame, "Position")
                        local v = viewportSize()
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

        local closeAllPops

        local grip = New("TextButton", {
                AnchorPoint = Vector2.new(1, 1),
                Position = UDim2.new(1, -1, 1, -1),
                Size = UDim2.new(0, 20, 0, 20),
                BackgroundTransparency = 1,
                Text = "",
                AutoButtonColor = false,
                ZIndex = 25,
                Parent = windowFrame,
        })
        local gripIcon = icon(grip, "grip", 14, theme.TextFaint)
        gripIcon.Position = UDim2.new(0.5, -7, 0.5, -7)
        grip.MouseEnter:Connect(function()
                tween(gripIcon, 0.12, { ImageColor3 = theme.Text })
        end)
        grip.MouseLeave:Connect(function()
                tween(gripIcon, 0.12, { ImageColor3 = theme.TextFaint })
        end)
        local resizeState = nil
        grip.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        closeAllPops()
                        killTween(windowFrame, "Size")
                        resizeState = { sx = input.Position.X, sy = input.Position.Y, w = W, h = H }
                end
        end)
        connect(UserInputService.InputChanged, function(input)
                if resizeState and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                        local v = viewportSize()
                        local maxX = v.X * 0.96
                        local minX = math.min(540, maxX)
                        local maxY = v.Y * 0.88
                        local minY = math.min(360, maxY)
                        W = math.floor(clamp(resizeState.w + (input.Position.X - resizeState.sx), minX, maxX) / 2) * 2
                        H = math.floor(clamp(resizeState.h + (input.Position.Y - resizeState.sy), minY, maxY) / 2) * 2
                        windowFrame.Size = UDim2.new(0, W, 0, H)
                end
        end)
        connect(UserInputService.InputEnded, function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        resizeState = nil
                end
        end)

        local function setMinimized(m)
                if state.min == m then return end
                state.min = m
                grip.Visible = not m
                if m then closeAllPops() end
                minIcon.Visible = not m
                plusIcon.Visible = m
                if m then
                        tween(windowFrame, 0.26, { Size = UDim2.new(0, W, 0, GEO.Header) }, Enum.EasingStyle.Quint)
                else
                        tween(windowFrame, 0.26, { Size = UDim2.new(0, W, 0, H) }, Enum.EasingStyle.Quint)
                end
        end

        local function closeWindow()
                if state.closed then return end
                state.closed = true
                closeAllPops()
                local px, py = windowFrame.Position.X.Offset, windowFrame.Position.Y.Offset
                tween(windowFrame, 0.18, { Position = UDim2.new(0, px, 0, py + 14) })
                task.delay(0.2, function()
                        if state.closed then windowFrame.Visible = false end
                end)
                launcher.Visible = true
                launcher.Position = UDim2.new(1, -22, 1, -4)
                tween(launcher, 0.2, { Position = UDim2.new(1, -22, 1, -22) }, Enum.EasingStyle.Quint)
        end

        minBtn.Activated:Connect(function()
                setMinimized(not state.min)
        end)

        local function reopen()
                if not state.closed then return end
                state.closed = false
                closeAllPops()
                recenter()
                windowFrame.Visible = true
                local tx, ty = windowFrame.Position.X.Offset, windowFrame.Position.Y.Offset
                windowFrame.Position = UDim2.new(0, tx, 0, ty + 14)
                tween(windowFrame, 0.22, { Position = UDim2.new(0, tx, 0, ty) }, Enum.EasingStyle.Quint)
                task.delay(0.2, function()
                        if not state.closed then launcher.Visible = false end
                end)
        end

        launcher.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        reopen()
                end
        end)

        local function applyFilter(q)
                q = tostring(q or ""):lower()
                if q ~= "" then closeAllPops() end
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
                        tween(row, 0.12, { BackgroundTransparency = 0 })
                        tween(s, 0.12, { Color = theme.LineStrong })
                end)
                row.MouseLeave:Connect(function()
                        tween(row, 0.12, { BackgroundTransparency = 1 })
                        tween(s, 0.12, { Color = theme.Line })
                end)
                return row, s
        end

        local function rowLabel(row, text, clear)
                local lbl = New("TextLabel", {
                        AnchorPoint = Vector2.new(0, 0.5),
                        Position = UDim2.new(0, GEO.RowPad, 0.5, 0),
                        Size = UDim2.new(1, -(GEO.RowPad + (clear or 60)), 0, 16),
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
                table.insert(state.searchRows, { frame = frame, text = text and tostring(text) or "", section = section })
        end

        closeAllPops = function(except)
                for i = #state.openPops, 1, -1 do
                        if state.openPops[i].pop ~= except then
                                state.openPops[i].close()
                        end
                end
        end

        local function registerPop(row, pop, setOpen, popH, popW, alignRight)
                table.insert(state.openPops, { row = row, pop = pop, popH = popH, popW = popW, alignRight = alignRight and true or false, close = function() setOpen(false) end })
        end
        local function unregisterPop(pop)
                for i, p in ipairs(state.openPops) do
                        if p.pop == pop then
                                table.remove(state.openPops, i)
                                break
                        end
                end
        end

        local lastCanvasY = 0
        content:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
                local cy = content.CanvasPosition.Y
                local d = cy - lastCanvasY
                lastCanvasY = cy
                if d == 0 then return end
                local wp = windowFrame.AbsolutePosition
                local wb = wp.Y + windowFrame.AbsoluteSize.Y
                local topMin = wp.Y + GEO.Header + 8
                for i = #state.openPops, 1, -1 do
                        local p = state.openPops[i]
                        local pos = p.pop.Position
                        local ny = pos.Y.Offset - d
                        local pb = ny + (p.popH or 0)
                        if pb < topMin + 4 or ny > wb - 12 then
                                p.close()
                        else
                                killTween(p.pop, "Position")
                                p.pop.Position = UDim2.new(0, pos.X.Offset, 0, ny)
                        end
                end
        end)
        dragZone.InputBegan:Connect(function() closeAllPops() end)

        local confirmActive = false
        local scrim, card

        local function hideConfirm()
                if not confirmActive then return end
                confirmActive = false
                tween(scrim, 0.15, { BackgroundTransparency = 1 })
                tween(card, 0.15, { Position = UDim2.new(0.5, 0, 0.5, 8) })
                task.delay(0.2, function()
                        if not confirmActive then
                                card.Visible = false
                                scrim.Visible = false
                        end
                end)
        end

        local function unloadNow()
                hideConfirm()
                closeAllPops()
                local px, py = windowFrame.Position.X.Offset, windowFrame.Position.Y.Offset
                tween(windowFrame, 0.18, { Position = UDim2.new(0, px, 0, py + 14) })
                task.delay(0.2, function()
                        if Window then pcall(function() Window:Destroy() end) end
                end)
        end

        local function showConfirm()
                if confirmActive then return end
                setMinimized(false)
                closeAllPops()
                if searchBox.Size.X.Offset > 0 then closeSearch() end
                if not scrim then
                        scrim = New("Frame", {
                                Size = UDim2.new(1, 0, 1, 0),
                                BackgroundColor3 = Color3.new(0, 0, 0),
                                BackgroundTransparency = 1,
                                BorderSizePixel = 0,
                                ZIndex = 30,
                                Visible = false,
                                Parent = windowFrame,
                        })
                        card = New("Frame", {
                                AnchorPoint = Vector2.new(0.5, 0.5),
                                Position = UDim2.new(0.5, 0, 0.5, 0),
                                Size = UDim2.new(0, 420, 0, 156),
                                BackgroundColor3 = theme.Overlay,
                                BorderSizePixel = 0,
                                Visible = false,
                                ZIndex = 31,
                                Parent = windowFrame,
                        })
                        corner(card, 8)
                        stroke(card, theme.LineStrong)
                        New("TextLabel", {
                                Position = UDim2.new(0, 20, 0, 20),
                                Size = UDim2.new(1, -40, 0, 16),
                                BackgroundTransparency = 1,
                                Font = F.Semibold,
                                TextSize = 14,
                                TextColor3 = theme.Text,
                                TextXAlignment = Enum.TextXAlignment.Left,
                                Text = "Close UI",
                                Parent = card,
                        })
                        New("TextLabel", {
                                Position = UDim2.new(0, 20, 0, 44),
                                Size = UDim2.new(1, -40, 0, 40),
                                BackgroundTransparency = 1,
                                Font = F.Regular,
                                TextSize = 13,
                                TextColor3 = theme.TextMuted,
                                TextXAlignment = Enum.TextXAlignment.Left,
                                TextYAlignment = Enum.TextYAlignment.Top,
                                TextWrapped = true,
                                Text = "Are you sure you want to close the UI? Reborn will be completely unloaded.",
                                Parent = card,
                        })
                        local cancelB = New("TextButton", {
                                Position = UDim2.new(0, 24, 0, 100),
                                Size = UDim2.new(0.5, -29, 0, 36),
                                BackgroundTransparency = 1,
                                BackgroundColor3 = theme.RowHover,
                                Text = "Cancel",
                                Font = F.Semibold,
                                TextSize = 13,
                                TextColor3 = theme.TextMuted,
                                AutoButtonColor = false,
                                BorderSizePixel = 0,
                                Parent = card,
                        })
                        corner(cancelB, 6)
                        local cbs = stroke(cancelB, theme.Line)
                        local closeB = New("TextButton", {
                                Position = UDim2.new(0.5, 5, 0, 100),
                                Size = UDim2.new(0.5, -29, 0, 36),
                                BackgroundColor3 = theme.Error,
                                Text = "Close",
                                Font = F.Semibold,
                                TextSize = 13,
                                TextColor3 = Color3.new(1, 1, 1),
                                AutoButtonColor = false,
                                BorderSizePixel = 0,
                                Parent = card,
                        })
                        corner(closeB, 6)
                        cancelB.MouseEnter:Connect(function()
                                cancelB.BackgroundTransparency = 0
                                cancelB.TextColor3 = theme.Text
                                cbs.Color = theme.LineStrong
                        end)
                        cancelB.MouseLeave:Connect(function()
                                cancelB.BackgroundTransparency = 1
                                cancelB.TextColor3 = theme.TextMuted
                                cbs.Color = theme.Line
                        end)
                        closeB.MouseEnter:Connect(function()
                                closeB.BackgroundColor3 = Color3.fromRGB(255, 51, 51)
                        end)
                        closeB.MouseLeave:Connect(function()
                                closeB.BackgroundColor3 = theme.Error
                        end)
                        cancelB.Activated:Connect(hideConfirm)
                        closeB.Activated:Connect(unloadNow)
                end
                confirmActive = true
                card.Size = UDim2.new(0, math.min(420, W - 48), 0, 156)
                scrim.Visible = true
                card.Visible = true
                scrim.BackgroundTransparency = 1
                card.Position = UDim2.new(0.5, 0, 0.5, 10)
                tween(scrim, 0.16, { BackgroundTransparency = 0.42 })
                tween(card, 0.18, { Position = UDim2.new(0.5, 0, 0.5, 0) }, Enum.EasingStyle.Quint)
        end

        closeBtn.Activated:Connect(showConfirm)

        local function mountPop(row, pop, popH, popW, alignRight)
                local rp, rs = row.AbsolutePosition, row.AbsoluteSize
                local wp = windowFrame.AbsolutePosition
                local wb = wp.Y + windowFrame.AbsoluteSize.Y
                local topMin = wp.Y + GEO.Header + 8
                local capH = (wb - 8) - topMin
                if capH > 0 and popH > capH then popH = capH end
                local x = alignRight and (rp.X + rs.X - GEO.RowPad - popW) or rp.X
                local y = rp.Y + rs.Y + 6
                if y + popH > wb - 8 then
                        y = rp.Y - popH - 6
                        if y < topMin then
                                y = topMin
                        end
                end
                pop.Parent = gui
                pop.ZIndex = 45
                pop.AnchorPoint = Vector2.new(0, 0)
                pop.Size = UDim2.new(0, popW, 0, popH)
                return x, y
        end

        local function addToggle(section, cfg)
                cfg = cfg or {}
                local row = makeRow(section, GEO.RowH)
                rowLabel(row, cfg.Text, 66)
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
                        Position = UDim2.new(0, 3, 0, 3),
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
                                knob.Position = UDim2.new(0, nx, 0, 3)
                                track.BackgroundColor3 = value and theme.Accent or theme.ToggleOff
                                ts.Color = value and theme.Accent or theme.LineStrong
                        else
                                tween(knob, 0.16, { Position = UDim2.new(0, nx, 0, 3) })
                                tween(track, 0.16, { BackgroundColor3 = value and theme.Accent or theme.ToggleOff })
                                tween(ts, 0.16, { Color = value and theme.Accent or theme.LineStrong })
                        end
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
                        Size = UDim2.new(1, -80, 1, 0),
                        BackgroundTransparency = 1,
                        Font = F.Medium,
                        TextSize = 13,
                        TextColor3 = theme.Text,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        TextTruncate = Enum.TextTruncate.AtEnd,
                        Text = tostring(cfg.Text or ""),
                        Parent = top,
                })
                local val = New("TextLabel", {
                        AnchorPoint = Vector2.new(1, 0),
                        Position = UDim2.new(1, 0, 0, 0),
                        Size = UDim2.new(0, 74, 1, 0),
                        BackgroundTransparency = 1,
                        Font = F.Medium,
                        TextSize = 12,
                        TextColor3 = theme.TextMuted,
                        TextXAlignment = Enum.TextXAlignment.Right,
                        TextTruncate = Enum.TextTruncate.AtEnd,
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

        local function addDropdown(section, cfg)
                cfg = cfg or {}
                local row = makeRow(section, GEO.RowH)
                local lbl = rowLabel(row, cfg.Text, 118)

                local chev = icon(row, "chevron-down", 18, theme.TextFaint)
                chev.AnchorPoint = Vector2.new(1, 0.5)
                chev.Position = UDim2.new(1, -GEO.RowPad, 0.5, 0)

                local val = New("TextLabel", {
                        AnchorPoint = Vector2.new(1, 0.5),
                        Position = UDim2.new(1, -GEO.RowPad - 18 - 7, 0.5, 0),
                        Size = UDim2.new(0, 60, 0, 16),
                        BackgroundTransparency = 1,
                        Font = F.Medium,
                        TextSize = 13,
                        TextColor3 = theme.TextMuted,
                        TextXAlignment = Enum.TextXAlignment.Right,
                        TextTruncate = Enum.TextTruncate.AtEnd,
                        Text = "",
                        ZIndex = 5,
                        Parent = row,
                })

                local options = cfg.Options or {}
                local popH = 10 + math.max(#options, 1) * GEO.OptH
                local pop = New("Frame", {
                        Position = UDim2.new(0, 0, 1, 6),
                        Size = UDim2.new(1, 0, 0, popH),
                        BackgroundColor3 = theme.Overlay,
                        BorderSizePixel = 0,
                        Visible = false,
                        ZIndex = 25,
                        Parent = row,
                })
                corner(pop, 8)
                stroke(pop, theme.LineStrong)
                local listScroll = New("ScrollingFrame", {
                        Position = UDim2.new(0, 5, 0, 5),
                        Size = UDim2.new(1, -10, 1, -10),
                        BackgroundTransparency = 1,
                        BorderSizePixel = 0,
                        ScrollBarThickness = 4,
                        ScrollBarImageColor3 = theme.LineStrong,
                        ScrollingDirection = Enum.ScrollingDirection.Y,
                        CanvasSize = UDim2.new(0, 0, 0, 0),
                        AutomaticCanvasSize = Enum.AutomaticSize.Y,
                        Parent = pop,
                })
                list(listScroll, 0)
                if #options == 0 then
                        New("TextLabel", {
                                Size = UDim2.new(1, -6, 0, GEO.OptH),
                                BackgroundTransparency = 1,
                                Font = F.Medium,
                                TextSize = 13,
                                TextColor3 = theme.TextFaint,
                                TextXAlignment = Enum.TextXAlignment.Left,
                                Text = "No options",
                                Parent = listScroll,
                        })
                end
                local dd = { Value = cfg.Value or options[1] or "" }
                local optBtns = {}
                local function fit()
                        local vw = clamp(measureText(tostring(dd.Value), 13, F.Medium), 24, 160)
                        val.Size = UDim2.new(0, vw, 0, 16)
                        lbl.Size = UDim2.new(1, -(GEO.RowPad + 49 + vw), 0, 16)
                end

                local function setOpen(o)
                        if dd._open == o then return end
                        dd._open = o
                        if o then
                                closeAllPops(pop)
                                local x, y = mountPop(row, pop, popH, row.AbsoluteSize.X)
                                listScroll.CanvasPosition = Vector2.new(0, 0)
                                pop.Visible = true
                                pop.Position = UDim2.new(0, x, 0, y + 6)
                                tween(pop, 0.15, { Position = UDim2.new(0, x, 0, y) }, Enum.EasingStyle.Quint)
                                tween(chev, 0.18, { Rotation = 180 })
                                registerPop(row, pop, setOpen, popH)
                        else
                                tween(pop, 0.12, { Position = UDim2.new(0, pop.Position.X.Offset, 0, pop.Position.Y.Offset + 4) })
                                task.delay(0.14, function()
                                        if not dd._open then pop.Visible = false end
                                end)
                                tween(chev, 0.18, { Rotation = 0 })
                                unregisterPop(pop)
                        end
                end

                for i, opt in ipairs(options) do
                        local otext = tostring(opt)
                        local ob = New("TextButton", {
                                Size = UDim2.new(1, -6, 0, GEO.OptH),
                                BackgroundTransparency = 1,
                                BackgroundColor3 = theme.OptionHover,
                                Text = "",
                                AutoButtonColor = false,
                                LayoutOrder = i,
                                Parent = listScroll,
                        })
                        corner(ob, 6)
                        local ot = New("TextLabel", {
                                Position = UDim2.new(0, 10, 0, 0),
                                Size = UDim2.new(1, -44, 1, 0),
                                BackgroundTransparency = 1,
                                Font = F.Medium,
                                TextSize = 13,
                                TextColor3 = theme.TextMuted,
                                TextXAlignment = Enum.TextXAlignment.Left,
                                TextTruncate = Enum.TextTruncate.AtEnd,
                                Text = otext,
                                Parent = ob,
                        })
                        local chk = icon(ob, "check", 16, theme.Accent)
                        chk.AnchorPoint = Vector2.new(1, 0.5)
                        chk.Position = UDim2.new(1, -10, 0.5, 0)
                        chk.Visible = false

                        ob.MouseEnter:Connect(function()
                                tween(ob, 0.1, { BackgroundTransparency = 0 })
                                tween(ot, 0.1, { TextColor3 = theme.Text })
                        end)
                        ob.MouseLeave:Connect(function()
                                tween(ob, 0.1, { BackgroundTransparency = 1 })
                                tween(ot, 0.1, { TextColor3 = theme.TextMuted })
                        end)
                        ob.Activated:Connect(function()
                                dd.Value = otext
                                val.Text = otext
                                fit()
                                for _, other in ipairs(optBtns) do
                                        local sel = other._text == otext
                                        other._chk.Visible = sel
                                        other._txt.TextColor3 = sel and theme.Text or theme.TextMuted
                                end
                                setOpen(false)
                                if cfg.Callback then cfg.Callback(otext) end
                        end)
                        table.insert(optBtns, { _btn = ob, _txt = ot, _chk = chk, _text = otext })
                        if otext == tostring(dd.Value) then
                                val.Text = otext
                                ot.TextColor3 = theme.Text
                                chk.Visible = true
                        end
                end
                fit()

                local btn = overlayBtn(row)
                btn.Activated:Connect(function()
                        setOpen(not dd._open)
                end)
                registerSearch(row, cfg.Text, section)

                function dd:Set(v, fire)
                        local vtext = tostring(v)
                        dd.Value = vtext
                        val.Text = vtext
                        fit()
                        for _, other in ipairs(optBtns) do
                                local sel = other._text == vtext
                                other._chk.Visible = sel
                                other._txt.TextColor3 = sel and theme.Text or theme.TextMuted
                        end
                        setOpen(false)
                        if fire and cfg.Callback then cfg.Callback(vtext) end
                end
                return dd
        end

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
                local lbl = rowLabel(row, cfg.Text, GEO.ChipMinW + 22)

                local chip = New("TextButton", {
                        AnchorPoint = Vector2.new(1, 0.5),
                        Position = UDim2.new(1, -GEO.RowPad, 0.5, 0),
                        Size = UDim2.new(0, GEO.ChipMinW, 0, GEO.ChipH),
                        BackgroundColor3 = theme.Chip,
                        BorderSizePixel = 0,
                        Text = "",
                        AutoButtonColor = false,
                        ZIndex = 5,
                        Parent = row,
                })
                corner(chip, 4)
                local cs = stroke(chip, theme.LineStrong)
                local txt = New("TextLabel", {
                        Size = UDim2.new(1, -16, 1, 0),
                        BackgroundTransparency = 1,
                        Font = F.Mono,
                        TextSize = 11,
                        TextColor3 = theme.TextMuted,
                        TextXAlignment = Enum.TextXAlignment.Center,
                        TextTruncate = Enum.TextTruncate.AtEnd,
                        Text = tostring(cfg.Value or "None"),
                        ZIndex = 2,
                        Parent = chip,
                })
                local function fitChip()
                        local w = math.max(GEO.ChipMinW, txt.TextBounds.X + 18)
                        chip.Size = UDim2.new(0, rnd(w), 0, GEO.ChipH)
                        lbl.Size = UDim2.new(1, -(GEO.RowPad + 22 + w), 0, 16)
                end
                txt:GetPropertyChangedSignal("TextBounds"):Connect(fitChip)
                task.defer(fitChip)

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
                        killTween(cs, "Color")
                        killTween(txt, "TextColor3")
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
                        tween(cs, 0.12, { Color = theme.Accent })
                        tween(txt, 0.12, { TextColor3 = theme.Accent })
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
                kb.Chip = chip
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

        local function addColorPicker(section, cfg)
                cfg = cfg or {}
                local row = makeRow(section, GEO.RowH)
                rowLabel(row, cfg.Text, 118)

                local hexW = rnd(math.max(44, measureText("#0070F3", 12, F.Mono)))
                local trigger = New("TextButton", {
                        AnchorPoint = Vector2.new(1, 0.5),
                        Position = UDim2.new(1, -GEO.RowPad, 0.5, 0),
                        Size = UDim2.new(0, hexW + 9 + GEO.Swatch, 0, GEO.Swatch),
                        BackgroundTransparency = 1,
                        Text = "",
                        AutoButtonColor = false,
                        ZIndex = 5,
                        Parent = row,
                })
                local hexLbl = New("TextLabel", {
                        Size = UDim2.new(0, hexW, 1, 0),
                        BackgroundTransparency = 1,
                        Font = F.Mono,
                        TextSize = 12,
                        TextColor3 = theme.TextMuted,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        TextTruncate = Enum.TextTruncate.AtEnd,
                        Text = "#0070F3",
                        ZIndex = 6,
                        Parent = trigger,
                })
                local swatch = New("Frame", {
                        AnchorPoint = Vector2.new(1, 0.5),
                        Position = UDim2.new(1, 0, 0.5, 0),
                        Size = UDim2.new(0, GEO.Swatch, 0, GEO.Swatch),
                        BackgroundColor3 = theme.Accent,
                        BorderSizePixel = 0,
                        ZIndex = 6,
                        Parent = trigger,
                })
                corner(swatch, 6)
                stroke(swatch, theme.LineStrong)

                local popH = 10 + GEO.SVH + 9 + GEO.HueH + 9 + 14 + 10
                local pop = New("Frame", {
                        AnchorPoint = Vector2.new(1, 0),
                        Position = UDim2.new(1, -GEO.RowPad, 0, GEO.RowH + 6),
                        Size = UDim2.new(0, GEO.PopW, 0, popH),
                        BackgroundColor3 = theme.Overlay,
                        BorderSizePixel = 0,
                        Visible = false,
                        ZIndex = 25,
                        Parent = row,
                })
                corner(pop, 8)
                stroke(pop, theme.LineStrong)
                padding(pop, 10, 10, 10, 10)

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

                New("TextLabel", {
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
                        Size = UDim2.new(0, rnd(math.max(44, measureText("#0070F3", 11, F.Mono))), 0, 14),
                        BackgroundTransparency = 1,
                        Font = F.Mono,
                        TextSize = 11,
                        TextColor3 = theme.TextMuted,
                        TextXAlignment = Enum.TextXAlignment.Right,
                        TextTruncate = Enum.TextTruncate.AtEnd,
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
                        local svw = GEO.PopW - 20
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
                local function padPoint(input)
                        if input.UserInputType == Enum.UserInputType.Touch then
                                return input.Position.X, input.Position.Y + GuiService:GetGuiInset().Y
                        end
                        local m = UserInputService:GetMouseLocation()
                        return m.X, m.Y
                end
                local function bindPad(el, apply)
                        el.InputBegan:Connect(function(input)
                                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                                        active = apply
                                        apply(input)
                                end
                        end)
                end
                local function applySV(input)
                        local r, sz = sv.AbsolutePosition, sv.AbsoluteSize
                        if sz.X < 1 or sz.Y < 1 then return end
                        local lx, ly = padPoint(input)
                        s = clamp((lx - r.X) / sz.X, 0, 1)
                        v = 1 - clamp((ly - r.Y) / sz.Y, 0, 1)
                        render(true)
                end
                local function applyHue(input)
                        local r, sz = hue.AbsolutePosition, hue.AbsoluteSize
                        if sz.X < 1 then return end
                        local lx = padPoint(input)
                        h = clamp((lx - r.X) / sz.X, 0, 1) * 360
                        render(true)
                end
                connect(UserInputService.InputChanged, function(input)
                        if active and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                                active(input)
                        end
                end)
                connect(UserInputService.InputEnded, function(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                                active = nil
                        end
                end)
                bindPad(sv, applySV)
                bindPad(hue, applyHue)

                local open = false
                local function setOpen(o)
                        if open == o then return end
                        open = o
                        if o then
                                closeAllPops(pop)
                                local x, y = mountPop(row, pop, popH, GEO.PopW, true)
                                pop.Visible = true
                                pop.Position = UDim2.new(0, x, 0, y + 6)
                                tween(pop, 0.15, { Position = UDim2.new(0, x, 0, y) }, Enum.EasingStyle.Quint)
                                registerPop(row, pop, setOpen, popH, GEO.PopW, true)
                        else
                                active = nil
                                tween(pop, 0.12, { Position = UDim2.new(0, pop.Position.X.Offset, 0, pop.Position.Y.Offset + 4) })
                                task.delay(0.14, function()
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

        local function addInput(section, cfg)
                cfg = cfg or {}
                local row = makeRow(section, GEO.RowH)
                rowLabel(row, cfg.Text, 202)

                local box = New("TextBox", {
                        AnchorPoint = Vector2.new(1, 0.5),
                        Position = UDim2.new(1, -GEO.RowPad, 0.5, 0),
                        Size = UDim2.new(0, GEO.FieldW, 0, GEO.FieldH),
                        BackgroundColor3 = theme.Overlay,
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
                        tween(bs, 0.12, { Color = theme.Accent })
                end)
                box.FocusLost:Connect(function(enter)
                        tween(bs, 0.12, { Color = theme.LineStrong })
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
                                tween(btn, 0.13, { BackgroundTransparency = 0 })
                                tween(btn, 0.13, { TextColor3 = theme.Text })
                                tween(s, 0.13, { Color = theme.LineStrong })
                        end)
                        btn.MouseLeave:Connect(function()
                                tween(btn, 0.13, { BackgroundTransparency = 1 })
                                tween(btn, 0.13, { TextColor3 = theme.TextMuted })
                                tween(s, 0.13, { Color = theme.Line })
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
                padding(lbl, 2, 2, 2, 12)
                registerSearch(lbl, cfg.Text, section)
                local p = { Label = lbl }
                function p:Set(text)
                        lbl.Text = tostring(text)
                end
                return p
        end

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

                function section:Toggle(a, b) return addToggle(section, normCfg(a, b)) end
                function section:Slider(a, b) return addSlider(section, normCfg(a, b)) end
                function section:Dropdown(a, b) return addDropdown(section, normCfg(a, b)) end
                function section:Keybind(a, b) return addKeybind(section, normCfg(a, b)) end
                function section:ColorPicker(a, b) return addColorPicker(section, normCfg(a, b)) end
                function section:Input(a, b) return addInput(section, normCfg(a, b)) end
                function section:Button(a, b) return addButton(section, normCfg(a, b)) end
                function section:Paragraph(a, b) return addParagraph(section, normCfg(a, b)) end
                return section
        end

        local function addTab(name, iconName)
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
                local ic
                if iconName and ICONS[iconName] then
                        ic = icon(btn, iconName, 16, theme.TextMuted)
                        ic.AnchorPoint = Vector2.new(0, 0.5)
                        ic.Position = UDim2.new(0, -26, 0.5, 0)
                        ic.ZIndex = 2
                        padding(btn, 0, 12, 0, 38)
                else
                        padding(btn, 0, 12, 0, 12)
                end

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
                        if ic then tween(ic, 0.12, { ImageColor3 = active and theme.Text or theme.TextMuted }) end
                        tween(btn, 0.12, { BackgroundTransparency = active and 0 or 1 })
                        tween(btn, 0.12, { TextColor3 = active and theme.Text or theme.TextMuted })
                        btn.Font = active and F.Semibold or F.Medium
                end
                btn.MouseEnter:Connect(function()
                        if not page.Visible then
                                tween(btn, 0.12, { BackgroundTransparency = 0 })
                                tween(btn, 0.12, { TextColor3 = theme.Text })
                                if ic then tween(ic, 0.12, { ImageColor3 = theme.Text }) end
                        end
                end)
                btn.MouseLeave:Connect(function()
                        if not page.Visible then
                                tween(btn, 0.12, { BackgroundTransparency = 1 })
                                tween(btn, 0.12, { TextColor3 = theme.TextMuted })
                                if ic then tween(ic, 0.12, { ImageColor3 = theme.TextMuted }) end
                        end
                end)
                btn.Activated:Connect(function()
                        closeAllPops()
                        for _, t in ipairs(state.tabs) do
                                t.Page.Visible = (t == tab)
                                t._setActive(false)
                        end
                        tab._setActive(true)
                        page.Visible = true
                        content.CanvasPosition = Vector2.new(0, 0)
                end)
                tab._setActive = setActive

                function tab:SetColumns(n)
                        if n ~= 2 then return end
                        if tab.Columns then return end
                        pageList:Destroy()
                        tab.Columns = {}
                        for i = 1, 2 do
                                local col = New("Frame", {
                                        Position = UDim2.new(0.5 * (i - 1), (i == 1) and 0 or GEO.GridGap / 2, 0, 0),
                                        Size = UDim2.new(0.5, -(GEO.GridGap / 2), 0, 0),
                                        AutomaticSize = Enum.AutomaticSize.Y,
                                        BackgroundTransparency = 1,
                                        Parent = page,
                                })
                                list(col, GEO.SectionGap)
                                tab.Columns[i] = col
                        end
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

        local function inRect(el, m)
                local p, sz = el.AbsolutePosition, el.AbsoluteSize
                return m.X >= p.X - 1 and m.X <= p.X + sz.X + 1 and m.Y >= p.Y - 1 and m.Y <= p.Y + sz.Y + 1
        end

        connect(UserInputService.InputBegan, function(input, gameProcessed)
                if state.listening and input.UserInputType == Enum.UserInputType.Keyboard then
                        if input.KeyCode == Enum.KeyCode.Escape then
                                state.listening._cancel()
                        else
                                state.listening._commit(keyDisplayName(input.KeyCode.Name), input.KeyCode, nil)
                        end
                        return
                end
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
                if input.KeyCode == Enum.KeyCode.Escape then
                        if confirmActive then
                                hideConfirm()
                        else
                                for i = #state.openPops, 1, -1 do
                                        state.openPops[i].close()
                                end
                        end
                end
        end)

        Window = {
                Title = tostring(config.Title or "Reborn"),
                Theme = theme,
                Gui = gui,
        }

        function Window:Tab(name, iconName)
                return addTab(name, iconName)
        end

        function Window:Notify(a, b)
                local cfg = normNotify(a, b)
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
                if #Reborn._windows == 0 and Reborn._toastGui then
                        pcall(function() Reborn._toastGui:Destroy() end)
                        Reborn._toastGui = nil
                        Reborn._toastLayer = nil
                end
        end

        table.insert(Reborn._windows, Window)
        return Window
end

function Reborn:Destroy()
        for i = #self._windows, 1, -1 do
                pcall(function() self._windows[i]:Destroy() end)
        end
        self._windows = {}
end

return Reborn
