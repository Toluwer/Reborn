local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local TextService = game:GetService("TextService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

local Reborn = {
        Version = "0.8.3",
        NotificationsEnabled = true,
        _windows = {},
        _configs = {},
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
        Sidebar      = 156,
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
        SliderTrackH = 18,
        RailH        = 6,
        HandleD      = 14,
        OptH         = 30,
        ChipH        = 22,
        ChipMinW     = 46,
        Swatch       = 22,
        PopW         = 204,
        SVH          = 140,
        HueW         = 14,
        FieldW       = 180,
        FieldH       = 30,
        ToastW       = 294,
        PillH        = 34,
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
        return New("UICorner", { CornerRadius = UDim.new(0, r), Parent = inst })
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

local function feather(inst, r, color, pl, pt, pr, pb)
        pl, pt, pr, pb = pl or 0, pt or 0, pr or 0, pb or 0
        local ring = New("Frame", {
                Position = UDim2.new(0, -1 - pl, 0, -1 - pt),
                Size = UDim2.new(1, 2 + pl + pr, 1, 2 + pt + pb),
                BackgroundColor3 = color,
                BackgroundTransparency = 0.5,
                BorderSizePixel = 0,
                Parent = inst,
        })
        corner(ring, r + 1)
        return ring
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

local function fmtNum(n)
        if math.abs(n - math.floor(n + 0.5)) < 1e-6 then
                return string.format("%d", math.floor(n + 0.5))
        end
        local s = string.format("%.2f", n)
        s = s:gsub("0+$", "")
        s = s:gsub("%.$", "")
        return s
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

local orderBase = math.random(100000, 800000)
local orderSeq = 0
local function nextOrder()
        orderSeq = orderSeq + 1
        return math.min(orderBase + orderSeq, 900000)
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
                if desc == "" then return 38 end
                local lines = 1
                local w = measureText(desc, 12, F.Regular)
                lines = math.max(1, math.ceil(w / math.max(GEO.ToastW - 39, 40)))
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
                desc.Visible = desc.Text ~= ""

                local hit = New("TextButton", {
                        Position = UDim2.new(0, -12, 0, -11),
                        Size = UDim2.new(1, 24, 1, 22),
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
                local dur = tonumber(cfg.Duration) or 3.6
                if dur > 0 and dur < 3600 then
                        task.delay(dur, function() dismiss(item) end)
                end
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
                DisplayOrder = nextOrder(),
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
                elements = {},
        }

        local Window = nil

        local windowFrame = New("Frame", {
                Name = randomName(),
                Size = UDim2.new(0, W, 0, H),
                BackgroundColor3 = theme.LineStrong,
                BorderSizePixel = 0,
                Parent = gui,
        })
        local winCorner = corner(windowFrame, GEO.WindowRadius)
        local winRing = feather(windowFrame, GEO.WindowRadius, theme.LineStrong)
        local windowFace = New("Frame", {
                Position = UDim2.new(0, 1, 0, 1),
                Size = UDim2.new(1, -2, 1, -2),
                BackgroundColor3 = theme.Surface,
                BorderSizePixel = 0,
                ClipsDescendants = true,
                Parent = windowFrame,
        })
        local faceCorner = corner(windowFace, GEO.WindowRadius - 1)

        local function recenter()
                if state.dragged or state.closed or state.min then return end
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
                Parent = windowFace,
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
        local titleLbl = New("TextLabel", {
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

        local searchWrap = New("Frame", {
                Position = UDim2.new(0, 0, 0, 7),
                Size = UDim2.new(0, 0, 0, GEO.SearchH),
                BackgroundColor3 = theme.LineStrong,
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Visible = false,
                Parent = cluster,
        })
        corner(searchWrap, 6)
        local seh = feather(searchWrap, 6, theme.LineStrong)
        seh.BackgroundTransparency = 1
        local searchBox = New("TextBox", {
                Position = UDim2.new(0, 1, 0, 1),
                Size = UDim2.new(1, -2, 1, -2),
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
                Parent = searchWrap,
        })
        corner(searchBox, 5)
        padding(searchBox, 0, 9, 0, 9)

        local searchBtn = New("TextButton", {
                Position = UDim2.new(0, GEO.SearchW + 9, 0, 9),
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
                Parent = windowFace,
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
        padding(tabsHolder, 10, 10, 10, 10)
        list(tabsHolder, 3)

        local content = New("ScrollingFrame", {
                Position = UDim2.new(0, GEO.Sidebar + 1, 0, 0),
                Size = UDim2.new(1, -(GEO.Sidebar + 1), 1, 0),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                ScrollBarThickness = 8,
                ScrollBarImageColor3 = theme.LineStrong,
                ScrollingDirection = Enum.ScrollingDirection.Y,
                CanvasSize = UDim2.new(0, 0, 0, 0),
                AutomaticCanvasSize = Enum.AutomaticSize.Y,
                Parent = bodyGroup,
        })

        local pillTitleText = tostring(config.Title or "Reborn")
        local pillTitleW = rnd(measureText(pillTitleText, 13, F.Semibold))
        local pillRestW = 24 + pillTitleW
        local pill = New("TextButton", {
                AnchorPoint = Vector2.new(0.5, 0),
                Position = UDim2.new(0.5, 0, 0, 14),
                Size = UDim2.new(0, pillRestW, 0, GEO.PillH),
                BackgroundColor3 = theme.Surface,
                BorderSizePixel = 0,
                Text = "",
                AutoButtonColor = false,
                ClipsDescendants = true,
                Visible = false,
                ZIndex = 40,
                Parent = gui,
        })
        corner(pill, GEO.PillH / 2)
        local pillContent = New("Frame", {
                AnchorPoint = Vector2.new(0.5, 0),
                Position = UDim2.new(0.5, 0, 0, 0),
                Size = UDim2.new(0, pillRestW, 1, 0),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Parent = pill,
        })
        local pillTitle = New("TextLabel", {
                AnchorPoint = Vector2.new(0, 0.5),
                Position = UDim2.new(0, 12, 0.5, 0),
                Size = UDim2.new(0, pillTitleW, 0, 16),
                BackgroundTransparency = 1,
                Font = F.Semibold,
                TextSize = 13,
                TextColor3 = theme.Text,
                TextXAlignment = Enum.TextXAlignment.Left,
                Text = pillTitleText,
                Parent = pillContent,
        })
        local pillHint = New("TextLabel", {
                AnchorPoint = Vector2.new(0, 0.5),
                Position = UDim2.new(0, 22 + pillTitleW, 0.5, 0),
                Size = UDim2.new(0, 0, 0, 15),
                AutomaticSize = Enum.AutomaticSize.X,
                BackgroundTransparency = 1,
                Font = F.Regular,
                TextSize = 12,
                TextColor3 = theme.TextMuted,
                TextTransparency = 1,
                TextXAlignment = Enum.TextXAlignment.Left,
                Text = "Click to open",
                Parent = pillContent,
        })
        local pillClear = false
        local function snapPillRest()
                pill.Size = UDim2.new(0, pillRestW, 0, GEO.PillH)
                pillContent.Size = UDim2.new(0, pillRestW, 1, 0)
                pillHint.TextTransparency = 1
                pill.BackgroundColor3 = theme.Surface
        end
        pill.MouseEnter:Connect(function()
                local key = Window and Window.ToggleKey or config.ToggleKey
                local hint = key and ("Click or " .. tostring(key) .. " to open") or "Click to open"
                pillHint.Text = hint
                local w = 22 + pillTitleW + rnd(measureText(hint, 12, F.Regular)) + 12
                tween(pill, 0.2, { Size = UDim2.new(0, w, 0, GEO.PillH) }, Enum.EasingStyle.Quint)
                tween(pillContent, 0.2, { Size = UDim2.new(0, w, 1, 0) }, Enum.EasingStyle.Quint)
                tween(pillHint, 0.2, { TextTransparency = pillClear and 0.55 or 0 })
                tween(pill, 0.2, { BackgroundColor3 = theme.Overlay })
        end)
        pill.MouseLeave:Connect(function()
                tween(pill, 0.2, { Size = UDim2.new(0, pillRestW, 0, GEO.PillH) }, Enum.EasingStyle.Quint)
                tween(pillContent, 0.2, { Size = UDim2.new(0, pillRestW, 1, 0) }, Enum.EasingStyle.Quint)
                tween(pillHint, 0.2, { TextTransparency = 1 })
                tween(pill, 0.2, { BackgroundColor3 = theme.Surface })
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

        local closeAllPops, closeSearch

        local grip = New("TextButton", {
                AnchorPoint = Vector2.new(1, 1),
                Position = UDim2.new(1, -1, 1, -1),
                Size = UDim2.new(0, 20, 0, 20),
                BackgroundTransparency = 1,
                Text = "",
                AutoButtonColor = false,
                ZIndex = 25,
                Parent = windowFace,
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
                if m and state.closed then return end
                state.min = m
                if m then
                        closeAllPops()
                        if searchWrap.Size.X.Offset > 0 then closeSearch() end
                        grip.Visible = false
                        header.Visible = false
                        bodyGroup.Visible = false
                        minIcon.Visible = false
                        plusIcon.Visible = true
                        state.minPos = { x = windowFrame.Position.X.Offset, y = windowFrame.Position.Y.Offset }
                        killTween(windowFrame, "Position")
                        killTween(windowFrame, "Size")
                        local v = viewportSize()
                        local tw = pillRestW + 2
                        tween(windowFrame, 0.36, {
                                Size = UDim2.new(0, tw, 0, GEO.PillH + 2),
                                Position = UDim2.new(0, rnd(v.X / 2 - tw / 2), 0, 13),
                        }, Enum.EasingStyle.Quint)
                        tween(winCorner, 0.36, { CornerRadius = UDim.new(0, GEO.PillH / 2 + 1) }, Enum.EasingStyle.Quint)
                        tween(faceCorner, 0.36, { CornerRadius = UDim.new(0, GEO.PillH / 2) }, Enum.EasingStyle.Quint)
                        tween(winRing, 0.24, { BackgroundTransparency = 1 })
                        tween(windowFrame, 0.24, { BackgroundColor3 = theme.Surface })
                        task.delay(0.38, function()
                                if state.min then
                                        windowFrame.Visible = false
                                        snapPillRest()
                                        pill.Visible = true
                                end
                        end)
                else
                        grip.Visible = true
                        header.Visible = true
                        bodyGroup.Visible = true
                        minIcon.Visible = true
                        plusIcon.Visible = false
                        killTween(windowFrame, "Position")
                        killTween(windowFrame, "Size")
                        local v = viewportSize()
                        if not windowFrame.Visible then
                                local tw = pillRestW + 2
                                windowFrame.Position = UDim2.new(0, rnd(v.X / 2 - tw / 2), 0, 13)
                                windowFrame.Size = UDim2.new(0, tw, 0, GEO.PillH + 2)
                                windowFrame.Visible = true
                        end
                        pill.Visible = false
                        snapPillRest()
                        local tx, ty
                        if state.minPos then
                                tx, ty = state.minPos.x, state.minPos.y
                        else
                                tx, ty = rnd(v.X / 2 - W / 2), rnd(v.Y / 2 - H / 2)
                        end
                        tween(windowFrame, 0.34, { Size = UDim2.new(0, W, 0, H), Position = UDim2.new(0, tx, 0, ty) }, Enum.EasingStyle.Quint)
                        tween(winCorner, 0.34, { CornerRadius = UDim.new(0, GEO.WindowRadius) }, Enum.EasingStyle.Quint)
                        tween(faceCorner, 0.34, { CornerRadius = UDim.new(0, GEO.WindowRadius - 1) }, Enum.EasingStyle.Quint)
                        tween(winRing, 0.3, { BackgroundTransparency = 0.5 })
                        tween(windowFrame, 0.3, { BackgroundColor3 = theme.LineStrong })
                end
        end

        local function closeWindow()
                if state.closed then return end
                state.closed = true
                closeAllPops()
                if state.min then
                        state.min = false
                        pill.Visible = false
                        grip.Visible = true
                        header.Visible = true
                        bodyGroup.Visible = true
                        minIcon.Visible = true
                        plusIcon.Visible = false
                        killTween(windowFrame, "Position")
                        killTween(windowFrame, "Size")
                        killTween(windowFrame, "BackgroundColor3")
                        killTween(winCorner, "CornerRadius")
                        killTween(faceCorner, "CornerRadius")
                        killTween(winRing, "BackgroundTransparency")
                        windowFrame.Size = UDim2.new(0, W, 0, H)
                        winCorner.CornerRadius = UDim.new(0, GEO.WindowRadius)
                        faceCorner.CornerRadius = UDim.new(0, GEO.WindowRadius - 1)
                        winRing.BackgroundTransparency = 0.5
                        windowFrame.BackgroundColor3 = theme.LineStrong
                        if state.minPos then
                                windowFrame.Position = UDim2.new(0, state.minPos.x, 0, state.minPos.y)
                        end
                end
                local px, py = windowFrame.Position.X.Offset, windowFrame.Position.Y.Offset
                tween(windowFrame, 0.18, { Position = UDim2.new(0, px, 0, py + 14) })
                task.delay(0.2, function()
                        if state.closed then windowFrame.Visible = false end
                end)
        end

        minBtn.Activated:Connect(function()
                setMinimized(not state.min)
        end)

        local pillHoldGen = 0
        local pillHoldFired = false
        pill.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        pillHoldFired = false
                        pillHoldGen = pillHoldGen + 1
                        local gen = pillHoldGen
                        task.delay(3, function()
                                if gen ~= pillHoldGen or state.min ~= true or state.closed then return end
                                pillHoldFired = true
                                pillClear = not pillClear
                                local bg = pillClear and 0.45 or 0
                                local tx = pillClear and 0.4 or 0
                                tween(pill, 0.5, { BackgroundTransparency = bg }, Enum.EasingStyle.Quint)
                                tween(pillTitle, 0.5, { TextTransparency = tx }, Enum.EasingStyle.Quint)
                                if pillHint.TextTransparency < 1 then
                                        tween(pillHint, 0.5, { TextTransparency = pillClear and 0.55 or 0 }, Enum.EasingStyle.Quint)
                                end
                        end)
                end
        end)
        connect(UserInputService.InputEnded, function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        pillHoldGen = pillHoldGen + 1
                end
        end)
        pill.Activated:Connect(function()
                if not pillHoldFired then
                        setMinimized(false)
                end
        end)

        local function reopen()
                if not state.closed then return end
                state.closed = false
                if state.min then setMinimized(false) end
                closeAllPops()
                recenter()
                windowFrame.Visible = true
                local tx, ty = windowFrame.Position.X.Offset, windowFrame.Position.Y.Offset
                windowFrame.Position = UDim2.new(0, tx, 0, ty + 14)
                tween(windowFrame, 0.22, { Position = UDim2.new(0, tx, 0, ty) }, Enum.EasingStyle.Quint)
        end

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

        local searchOpen = false
        local function openSearch()
                searchOpen = true
                searchWrap.Visible = true
                tween(searchWrap, 0.18, { Size = UDim2.new(0, GEO.SearchW, 0, GEO.SearchH) })
                tween(searchWrap, 0.15, { BackgroundTransparency = 0 })
                tween(searchBox, 0.15, { BackgroundTransparency = 0 })
                tween(seh, 0.15, { BackgroundTransparency = 0.5 })
                searchBox:CaptureFocus()
        end

        closeSearch = function()
                searchOpen = false
                searchBox.Text = ""
                applyFilter("")
                searchBox:ReleaseFocus()
                tween(searchWrap, 0.18, { Size = UDim2.new(0, 0, 0, GEO.SearchH) })
                tween(searchWrap, 0.15, { BackgroundTransparency = 1 })
                tween(searchBox, 0.15, { BackgroundTransparency = 1 })
                tween(seh, 0.15, { BackgroundTransparency = 1 })
                task.delay(0.2, function()
                        if not searchOpen and searchWrap.Size.X.Offset <= 0 then
                                searchWrap.Visible = false
                        end
                end)
        end

        searchBtn.Activated:Connect(function()
                if searchWrap.Size.X.Offset > 0 then
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
                        BackgroundColor3 = theme.Line,
                        BorderSizePixel = 0,
                        ZIndex = 1,
                        Parent = section.Rows,
                })
                corner(row, 8)
                local rh = feather(row, 8, theme.Line)
                local face = New("Frame", {
                        Position = UDim2.new(0, 1, 0, 1),
                        Size = UDim2.new(1, -2, 1, -2),
                        BackgroundColor3 = theme.Surface,
                        BorderSizePixel = 0,
                        Parent = row,
                })
                corner(face, 7)
                row.MouseEnter:Connect(function()
                        tween(face, 0.12, { BackgroundColor3 = theme.RowHover })
                        tween(row, 0.12, { BackgroundColor3 = theme.LineStrong })
                        tween(rh, 0.12, { BackgroundColor3 = theme.LineStrong })
                end)
                row.MouseLeave:Connect(function()
                        tween(face, 0.12, { BackgroundColor3 = theme.Surface })
                        tween(row, 0.12, { BackgroundColor3 = theme.Line })
                        tween(rh, 0.12, { BackgroundColor3 = theme.Line })
                end)
                return row, face
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

        local tipWrap = New("Frame", {
                Size = UDim2.new(0, 0, 0, 28),
                BackgroundColor3 = theme.LineStrong,
                BorderSizePixel = 0,
                Visible = false,
                ZIndex = 60,
                Parent = gui,
        })
        corner(tipWrap, 6)
        local tph = feather(tipWrap, 6, theme.LineStrong)
        local tipFace = New("Frame", {
                Position = UDim2.new(0, 1, 0, 1),
                Size = UDim2.new(1, -2, 1, -2),
                BackgroundColor3 = theme.Overlay,
                BorderSizePixel = 0,
                Parent = tipWrap,
        })
        corner(tipFace, 5)
        local tipTxt = New("TextLabel", {
                Position = UDim2.new(0, 10, 0, 0),
                Size = UDim2.new(1, -20, 1, 0),
                BackgroundTransparency = 1,
                Font = F.Regular,
                TextSize = 12,
                TextColor3 = theme.TextMuted,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd,
                Text = "",
                Parent = tipFace,
        })

        local tipState = { gen = 0, armed = false }
        local function hideTip()
                tipState.gen = tipState.gen + 1
                if not tipState.armed then return end
                tipState.armed = false
                local gen = tipState.gen
                tween(tipWrap, 0.1, { BackgroundTransparency = 1 })
                tween(tph, 0.1, { BackgroundTransparency = 1 })
                tween(tipTxt, 0.1, { TextTransparency = 1 })
                task.delay(0.12, function()
                        if tipState.gen == gen and tipWrap.Parent then tipWrap.Visible = false end
                end)
        end
        local function showTip(text, row)
                local clean = tostring(text or "")
                if clean == "" then return end
                local rp, rs = row.AbsolutePosition, row.AbsoluteSize
                local vy = viewportSize()
                local tw = clamp(measureText(clean, 12, F.Regular) + 22, 44, 320)
                local x = rp.X + rs.X + 12
                if x + tw > vy.X - 10 then x = rp.X - 12 - tw end
                if x < 10 then x = 10 end
                local cy = clamp(rp.Y + rs.Y / 2, 22, vy.Y - 22)
                tipTxt.Text = clean
                tipWrap.Size = UDim2.new(0, tw, 0, 28)
                tipWrap.Position = UDim2.new(0, x, 0, cy + 4)
                tipWrap.Rotation = 0
                tipWrap.Visible = true
                tipWrap.BackgroundTransparency = 0
                tph.BackgroundTransparency = 0.5
                tipTxt.TextTransparency = 0
                tween(tipWrap, 0.14, { Position = UDim2.new(0, x, 0, cy) }, Enum.EasingStyle.Quint)
        end
        local function tipHover(row, cfg, hosts)
                for _, host in ipairs(hosts) do
                        host.MouseEnter:Connect(function()
                                if cfg.Tooltip and tostring(cfg.Tooltip) ~= "" then
                                        tipState.gen = tipState.gen + 1
                                        local gen = tipState.gen
                                        task.delay(0.55, function()
                                                if tipState.gen == gen then
                                                        tipState.armed = true
                                                        showTip(cfg.Tooltip, row)
                                                end
                                        end)
                                end
                        end)
                        host.MouseLeave:Connect(function()
                                tipState.gen = tipState.gen + 1
                                hideTip()
                        end)
                end
        end

        local function destroyElement(entry)
                for i, e in ipairs(state.elements) do
                        if e == entry then
                                table.remove(state.elements, i)
                                break
                        end
                end
                for i = #state.searchRows, 1, -1 do
                        if state.searchRows[i].frame == entry.row then table.remove(state.searchRows, i) end
                end
                if entry.kind == "Keybind" then
                        for i = #state.keybinds, 1, -1 do
                                if state.keybinds[i] == entry.el then table.remove(state.keybinds, i) end
                        end
                        if state.listening == entry.el then state.listening = nil end
                end
                if entry.pop then
                        for i = #state.openPops, 1, -1 do
                                if state.openPops[i].pop == entry.pop then table.remove(state.openPops, i) end
                        end
                end
                if entry.row then pcall(function() entry.row:Destroy() end) end
                if entry.pop then pcall(function() entry.pop:Destroy() end) end
        end

        local function finishElement(kind, el, cfg, row, hosts, pop)
                el._kind = kind
                el.Flag = cfg.Flag
                local entry = { kind = kind, el = el, cfg = cfg, row = row, pop = pop }
                function el:SetVisible(v)
                        v = v and true or false
                        if row then row.Visible = v end
                        if pop and not v then pop.Visible = false end
                        entry.hidden = not v
                end
                function el:SetTooltip(text)
                        cfg.Tooltip = text
                        if not text or tostring(text) == "" then hideTip() end
                end
                function el:Destroy()
                        hideTip()
                        destroyElement(entry)
                end
                table.insert(state.elements, entry)
                if hosts and #hosts > 0 then
                        tipHover(row, cfg, hosts)
                end
                return el
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
                if searchWrap.Size.X.Offset > 0 then closeSearch() end
                if not scrim then
                        scrim = New("Frame", {
                                Size = UDim2.new(1, 0, 1, 0),
                                BackgroundColor3 = Color3.new(0, 0, 0),
                                BackgroundTransparency = 1,
                                BorderSizePixel = 0,
                                ZIndex = 30,
                                Visible = false,
                                Parent = windowFace,
                        })
                        card = New("Frame", {
                                AnchorPoint = Vector2.new(0.5, 0.5),
                                Position = UDim2.new(0.5, 0, 0.5, 0),
                                Size = UDim2.new(0, 420, 0, 156),
                                BackgroundColor3 = theme.LineStrong,
                                BorderSizePixel = 0,
                                Visible = false,
                                ZIndex = 31,
                                Parent = windowFace,
                        })
                        corner(card, 8)
                        feather(card, 8, theme.LineStrong)
                        local cardFace = New("Frame", {
                                Position = UDim2.new(0, 1, 0, 1),
                                Size = UDim2.new(1, -2, 1, -2),
                                BackgroundColor3 = theme.Overlay,
                                BorderSizePixel = 0,
                                Parent = card,
                        })
                        corner(cardFace, 7)
                        New("TextLabel", {
                                Position = UDim2.new(0, 20, 0, 20),
                                Size = UDim2.new(1, -40, 0, 16),
                                BackgroundTransparency = 1,
                                Font = F.Semibold,
                                TextSize = 14,
                                TextColor3 = theme.Text,
                                TextXAlignment = Enum.TextXAlignment.Left,
                                Text = "Close UI",
                                Parent = cardFace,
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
                                Parent = cardFace,
                        })
                        local cancelWrap = New("Frame", {
                                Position = UDim2.new(0, 24, 0, 100),
                                Size = UDim2.new(0.5, -29, 0, 36),
                                BackgroundColor3 = theme.Line,
                                BorderSizePixel = 0,
                                Parent = cardFace,
                        })
                        corner(cancelWrap, 6)
                        local cbh = feather(cancelWrap, 6, theme.Line)
                        local cancelB = New("TextButton", {
                                Position = UDim2.new(0, 1, 0, 1),
                                Size = UDim2.new(1, -2, 1, -2),
                                BackgroundColor3 = theme.RowHover,
                                BackgroundTransparency = 1,
                                Text = "Cancel",
                                Font = F.Semibold,
                                TextSize = 13,
                                TextColor3 = theme.TextMuted,
                                AutoButtonColor = false,
                                BorderSizePixel = 0,
                                Parent = cancelWrap,
                        })
                        corner(cancelB, 5)
                        local closeWrap = New("Frame", {
                                Position = UDim2.new(0.5, 5, 0, 100),
                                Size = UDim2.new(0.5, -29, 0, 36),
                                BackgroundColor3 = theme.Error,
                                BorderSizePixel = 0,
                                Parent = cardFace,
                        })
                        corner(closeWrap, 6)
                        feather(closeWrap, 6, theme.Error)
                        local closeB = New("TextButton", {
                                Position = UDim2.new(0, 1, 0, 1),
                                Size = UDim2.new(1, -2, 1, -2),
                                BackgroundColor3 = theme.Error,
                                Text = "Close",
                                Font = F.Semibold,
                                TextSize = 13,
                                TextColor3 = Color3.new(1, 1, 1),
                                AutoButtonColor = false,
                                BorderSizePixel = 0,
                                Parent = closeWrap,
                        })
                        corner(closeB, 5)
                        cancelB.MouseEnter:Connect(function()
                                tween(cancelB, 0.12, { BackgroundTransparency = 0 })
                                tween(cancelB, 0.12, { TextColor3 = theme.Text })
                                tween(cancelWrap, 0.12, { BackgroundColor3 = theme.LineStrong })
                                tween(cbh, 0.12, { BackgroundColor3 = theme.LineStrong })
                        end)
                        cancelB.MouseLeave:Connect(function()
                                tween(cancelB, 0.12, { BackgroundTransparency = 1 })
                                tween(cancelB, 0.12, { TextColor3 = theme.TextMuted })
                                tween(cancelWrap, 0.12, { BackgroundColor3 = theme.Line })
                                tween(cbh, 0.12, { BackgroundColor3 = theme.Line })
                        end)
                        closeB.MouseEnter:Connect(function()
                                tween(closeB, 0.12, { BackgroundColor3 = Color3.fromRGB(255, 51, 51) })
                                tween(closeWrap, 0.12, { BackgroundColor3 = Color3.fromRGB(255, 51, 51) })
                        end)
                        closeB.MouseLeave:Connect(function()
                                tween(closeB, 0.12, { BackgroundColor3 = theme.Error })
                                tween(closeWrap, 0.12, { BackgroundColor3 = theme.Error })
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
                return x, y, popH
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
                        BackgroundColor3 = theme.LineStrong,
                        BorderSizePixel = 0,
                        ZIndex = 5,
                        Parent = row,
                })
                corner(track, GEO.SwitchH / 2)
                local th = feather(track, GEO.SwitchH / 2, theme.LineStrong)
                local trackFace = New("Frame", {
                        Position = UDim2.new(0, 1, 0, 1),
                        Size = UDim2.new(1, -2, 1, -2),
                        BackgroundColor3 = theme.ToggleOff,
                        BorderSizePixel = 0,
                        Parent = track,
                })
                corner(trackFace, GEO.SwitchH / 2 - 1)
                local knob = New("Frame", {
                        Position = UDim2.new(0, 3, 0, 3),
                        Size = UDim2.new(0, GEO.Knob, 0, GEO.Knob),
                        BackgroundColor3 = theme.Handle,
                        BorderSizePixel = 0,
                        ZIndex = 6,
                        Parent = track,
                })
                corner(knob, GEO.Knob / 2)
                feather(knob, GEO.Knob / 2, theme.Handle)

                local value = cfg.Value and true or false
                local tog = { Value = value }

                local function render(fire, instant)
                        local nx = value and (GEO.SwitchW - GEO.Knob - 3) or 3
                        local c = value and theme.Accent or theme.ToggleOff
                        local b = value and theme.Accent or theme.LineStrong
                        if instant then
                                knob.Position = UDim2.new(0, nx, 0, 3)
                                trackFace.BackgroundColor3 = c
                                track.BackgroundColor3 = b
                                th.BackgroundColor3 = b
                        else
                                tween(knob, 0.16, { Position = UDim2.new(0, nx, 0, 3) })
                                tween(trackFace, 0.16, { BackgroundColor3 = c })
                                tween(track, 0.16, { BackgroundColor3 = b })
                                tween(th, 0.16, { BackgroundColor3 = b })
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
                return finishElement("Toggle", tog, cfg, row, { btn })
        end

        local function addSlider(section, cfg)
                cfg = cfg or {}
                local row = makeRow(section, GEO.SliderH)

                local top = New("Frame", {
                        Position = UDim2.new(0, GEO.RowPad, 0, 10),
                        Size = UDim2.new(1, -GEO.RowPad * 2, 0, 16),
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
                        Position = UDim2.new(0, GEO.RowPad, 0, 34),
                        Size = UDim2.new(1, -GEO.RowPad * 2, 0, GEO.SliderTrackH),
                        BackgroundTransparency = 1,
                        Text = "",
                        AutoButtonColor = false,
                        Parent = row,
                })
                local rail = New("Frame", {
                        Position = UDim2.new(0, 0, 0, (GEO.SliderTrackH - GEO.RailH) / 2),
                        Size = UDim2.new(1, 0, 0, GEO.RailH),
                        BackgroundColor3 = theme.LineStrong,
                        BorderSizePixel = 0,
                        Parent = track,
                })
                corner(rail, GEO.RailH / 2)
                local fill = New("Frame", {
                        Position = UDim2.new(0, 0, 0, (GEO.SliderTrackH - GEO.RailH) / 2),
                        Size = UDim2.new(0, 0, 0, GEO.RailH),
                        BackgroundColor3 = theme.Accent,
                        BorderSizePixel = 0,
                        Parent = track,
                })
                corner(fill, GEO.RailH / 2)
                local handle = New("Frame", {
                        Position = UDim2.new(0, 0, 0, (GEO.SliderTrackH - GEO.HandleD) / 2),
                        Size = UDim2.new(0, GEO.HandleD, 0, GEO.HandleD),
                        BackgroundColor3 = theme.Handle,
                        BorderSizePixel = 0,
                        ZIndex = 2,
                        Parent = track,
                })
                corner(handle, GEO.HandleD / 2)
                feather(handle, GEO.HandleD / 2, theme.Handle)

                local min = cfg.Min or 0
                local max = cfg.Max or 100
                if max <= min then max = min + 1 end
                local step = tonumber(cfg.Step) or 1
                if step <= 0 then step = 1 end
                local function snap(raw)
                        return clamp(min + rnd((raw - min) / step) * step, min, max)
                end
                local value = snap(cfg.Value or min)
                local suffix = cfg.Suffix or ""
                local sld = { Value = value }

                local renderTries = 0
                local function render()
                        local tw = track.AbsoluteSize.X
                        if tw < GEO.HandleD then
                                if renderTries < 8 then
                                        renderTries = renderTries + 1
                                        task.defer(render)
                                end
                                return
                        end
                        renderTries = 0
                        local p = (value - min) / (max - min)
                        local px = rnd(p * tw)
                        fill.Size = UDim2.new(0, px, 0, GEO.RailH)
                        handle.Position = UDim2.new(0, clamp(px - GEO.HandleD / 2, 0, tw - GEO.HandleD), 0, (GEO.SliderTrackH - GEO.HandleD) / 2)
                        val.Text = fmtNum(value) .. suffix
                        sld.Value = value
                end
                track:GetPropertyChangedSignal("AbsoluteSize"):Connect(render)
                task.defer(render)

                local dragging = false
                local function fromX(x)
                        local tw = track.AbsoluteSize.X
                        if tw < 1 then return end
                        local p = clamp((x - track.AbsolutePosition.X) / tw, 0, 1)
                        value = snap(min + (max - min) * p)
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
                        value = snap(tonumber(v) or min)
                        sld.Value = value
                        render()
                        if fire and cfg.Callback then cfg.Callback(value) end
                end
                return finishElement("Slider", sld, cfg, row, { track })
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
                local multi = cfg.Multi and true or false
                local origOf = {}
                local optTexts = {}
                for i, opt in ipairs(options) do
                        local t = tostring(opt)
                        optTexts[i] = t
                        if origOf[t] == nil then origOf[t] = opt end
                end
                local sel = {}
                local dd
                if multi then
                        for _, v in ipairs(cfg.Value or {}) do sel[tostring(v)] = true end
                        dd = { Value = {} }
                else
                        dd = { Value = (cfg.Value ~= nil and cfg.Value) or options[1] or "" }
                end
                local popH = 10 + math.max(#options, 1) * GEO.OptH
                local pop = New("Frame", {
                        Position = UDim2.new(0, 0, 1, 6),
                        Size = UDim2.new(1, 0, 0, popH),
                        BackgroundColor3 = theme.LineStrong,
                        BorderSizePixel = 0,
                        Visible = false,
                        ZIndex = 25,
                        Parent = row,
                })
                corner(pop, 8)
                feather(pop, 8, theme.LineStrong)
                local popFace = New("Frame", {
                        Position = UDim2.new(0, 1, 0, 1),
                        Size = UDim2.new(1, -2, 1, -2),
                        BackgroundColor3 = theme.Overlay,
                        BorderSizePixel = 0,
                        Parent = pop,
                })
                corner(popFace, 7)
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
                        Parent = popFace,
                })
                list(listScroll, 0)
                if #options == 0 then
                        New("TextLabel", {
                                Position = UDim2.new(0, 10, 0, 0),
                                Size = UDim2.new(1, -16, 0, GEO.OptH),
                                BackgroundTransparency = 1,
                                Font = F.Medium,
                                TextSize = 13,
                                TextColor3 = theme.TextFaint,
                                TextXAlignment = Enum.TextXAlignment.Left,
                                Text = "No options",
                                Parent = listScroll,
                        })
                end
                local optBtns = {}
                local function syncValue()
                        local vals = {}
                        for i, opt in ipairs(options) do
                                if sel[optTexts[i]] then table.insert(vals, origOf[optTexts[i]]) end
                        end
                        dd.Value = vals
                end
                local function displayText()
                        if multi then
                                local names = {}
                                for i = 1, #optTexts do
                                        if sel[optTexts[i]] then table.insert(names, optTexts[i]) end
                                end
                                return table.concat(names, ", ")
                        end
                        return tostring(dd.Value)
                end
                local function refreshChecks()
                        for _, other in ipairs(optBtns) do
                                local on = multi and (sel[other._text] and true or false) or (other._text == tostring(dd.Value))
                                other._chk.Visible = on
                                other._txt.TextColor3 = on and theme.Text or theme.TextMuted
                        end
                end
                local function fit()
                        local vw = clamp(measureText(displayText(), 13, F.Medium), 24, 160)
                        val.Size = UDim2.new(0, vw, 0, 16)
                        lbl.Size = UDim2.new(1, -(GEO.RowPad + 47 + vw), 0, 16)
                end

                local function setOpen(o)
                        if dd._open == o then return end
                        dd._open = o
                        if o then
                                closeAllPops(pop)
                                local x, y, cappedH = mountPop(row, pop, popH, row.AbsoluteSize.X)
                                listScroll.CanvasPosition = Vector2.new(0, 0)
                                pop.Visible = true
                                pop.Position = UDim2.new(0, x, 0, y + 6)
                                tween(pop, 0.15, { Position = UDim2.new(0, x, 0, y) }, Enum.EasingStyle.Quint)
                                tween(chev, 0.18, { Rotation = 180 })
                                registerPop(row, pop, setOpen, cappedH)
                        else
                                tween(pop, 0.12, { Position = UDim2.new(0, pop.Position.X.Offset, 0, pop.Position.Y.Offset + 4) })
                                task.delay(0.14, function()
                                        if not dd._open and pop.Parent then pop.Visible = false end
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
                                if multi then
                                        if sel[otext] then sel[otext] = nil else sel[otext] = true end
                                        syncValue()
                                        val.Text = displayText()
                                        fit()
                                        refreshChecks()
                                        local out = {}
                                        for i2, v2 in ipairs(dd.Value) do out[i2] = v2 end
                                        if cfg.Callback then cfg.Callback(out) end
                                else
                                        dd.Value = origOf[otext] ~= nil and origOf[otext] or otext
                                        val.Text = otext
                                        fit()
                                        for _, other in ipairs(optBtns) do
                                                local on = other._text == otext
                                                other._chk.Visible = on
                                                other._txt.TextColor3 = on and theme.Text or theme.TextMuted
                                        end
                                        setOpen(false)
                                        if cfg.Callback then cfg.Callback(dd.Value) end
                                end
                        end)
                        table.insert(optBtns, { _btn = ob, _txt = ot, _chk = chk, _text = otext })
                        if (multi and sel[otext]) or (not multi and otext == tostring(dd.Value)) then
                                if not multi then val.Text = otext end
                                ot.TextColor3 = theme.Text
                                chk.Visible = true
                        end
                end
                if multi then syncValue() end
                fit()

                local btn = overlayBtn(row)
                btn.Activated:Connect(function()
                        setOpen(not dd._open)
                end)
                local searchText = tostring(cfg.Text or "")
                if #optTexts > 0 then searchText = searchText .. " " .. table.concat(optTexts, " ") end
                registerSearch(row, searchText, section)

                function dd:Set(v, fire)
                        if multi then
                                sel = {}
                                for _, x in ipairs(type(v) == "table" and v or {}) do sel[tostring(x)] = true end
                                syncValue()
                        else
                                dd.Value = v ~= nil and v or ""
                        end
                        val.Text = displayText()
                        fit()
                        refreshChecks()
                        if not multi then setOpen(false) end
                        if fire and cfg.Callback then
                                if multi then
                                        local out = {}
                                        for i2, v2 in ipairs(dd.Value) do out[i2] = v2 end
                                        cfg.Callback(out)
                                else
                                        cfg.Callback(dd.Value)
                                end
                        end
                end
                return finishElement("Dropdown", dd, cfg, row, { btn }, pop)
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
                if ok and code and code ~= Enum.KeyCode.None then return code, nil end
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
                        BackgroundColor3 = theme.LineStrong,
                        BorderSizePixel = 0,
                        Text = "",
                        AutoButtonColor = false,
                        ZIndex = 5,
                        Parent = row,
                })
                corner(chip, 4)
                local ch = feather(chip, 4, theme.LineStrong)
                local chipFace = New("Frame", {
                        Position = UDim2.new(0, 1, 0, 1),
                        Size = UDim2.new(1, -2, 1, -2),
                        BackgroundColor3 = theme.Chip,
                        BorderSizePixel = 0,
                        ZIndex = 1,
                        Parent = chip,
                })
                corner(chipFace, 3)
                local txt = New("TextLabel", {
                        Position = UDim2.new(0, 8, 0, 0),
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
                        local w = rnd(math.max(GEO.ChipMinW, measureText(txt.Text, 11, F.Mono) + 18))
                        chip.Size = UDim2.new(0, w, 0, GEO.ChipH)
                        lbl.Size = UDim2.new(1, -(GEO.RowPad + 22 + w), 0, 16)
                end
                txt:GetPropertyChangedSignal("Text"):Connect(fitChip)
                task.defer(fitChip)

                local mode = tostring(cfg.Mode or "Always")
                if mode ~= "Toggle" and mode ~= "Hold" then mode = "Always" end
                local kb = {
                        Name = cfg.Value or "None",
                        KeyCode = nil,
                        UserInputType = nil,
                        Callback = cfg.Callback,
                        Mode = mode,
                        Active = false,
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
                        killTween(chip, "BackgroundColor3")
                        killTween(chip, "BackgroundTransparency")
                        killTween(ch, "BackgroundColor3")
                        killTween(txt, "TextColor3")
                        chip.BackgroundTransparency = 0
                        chip.BackgroundColor3 = theme.LineStrong
                        ch.BackgroundColor3 = theme.LineStrong
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
                        kb.Active = false
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
                        kb._chip = chip
                        kb._prev = txt.Text
                        txt.Text = "· · ·"
                        tween(chip, 0.12, { BackgroundColor3 = theme.Accent })
                        tween(ch, 0.12, { BackgroundColor3 = theme.Accent })
                        tween(txt, 0.12, { TextColor3 = theme.Accent })
                        pulseTween = TweenService:Create(chip, TweenInfo.new(1, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1, true), { BackgroundTransparency = 0.6 })
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
                        kb.Active = false
                        txt.Text = tostring(name)
                end
                return finishElement("Keybind", kb, cfg, row, { chip })
        end

        local function addColorPicker(section, cfg)
                cfg = cfg or {}
                local row = makeRow(section, GEO.RowH)
                local hexW = rnd(math.max(44, measureText("#0070F3", 12, F.Mono)))
                rowLabel(row, cfg.Text, hexW + 9 + GEO.Swatch + 22)

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
                        BackgroundColor3 = theme.LineStrong,
                        BorderSizePixel = 0,
                        ZIndex = 6,
                        Parent = trigger,
                })
                corner(swatch, 6)
                feather(swatch, 6, theme.LineStrong)
                local swatchFace = New("Frame", {
                        Position = UDim2.new(0, 1, 0, 1),
                        Size = UDim2.new(1, -2, 1, -2),
                        BackgroundColor3 = theme.Accent,
                        BorderSizePixel = 0,
                        ZIndex = 1,
                        Parent = swatch,
                })
                corner(swatchFace, 5)

                local popH = 22 + GEO.SVH + 10 + GEO.Swatch
                local pop = New("Frame", {
                        AnchorPoint = Vector2.new(1, 0),
                        Position = UDim2.new(1, -GEO.RowPad, 0, GEO.RowH + 6),
                        Size = UDim2.new(0, GEO.PopW, 0, popH),
                        BackgroundColor3 = theme.LineStrong,
                        BorderSizePixel = 0,
                        Visible = false,
                        ZIndex = 25,
                        Parent = row,
                })
                corner(pop, 8)
                feather(pop, 8, theme.LineStrong)
                local popFace = New("Frame", {
                        Position = UDim2.new(0, 1, 0, 1),
                        Size = UDim2.new(1, -2, 1, -2),
                        BackgroundColor3 = theme.Overlay,
                        BorderSizePixel = 0,
                        Parent = pop,
                })
                corner(popFace, 7)
                padding(popFace, 10, 10, 10, 10)

                local sv = New("Frame", {
                        Size = UDim2.new(1, -(GEO.HueW + 10), 0, GEO.SVH),
                        BackgroundColor3 = Color3.new(0, 0, 0),
                        BorderSizePixel = 0,
                        Parent = popFace,
                })
                corner(sv, 8)
                local svHue = New("Frame", {
                        Size = UDim2.new(1, 0, 1, 0),
                        BackgroundColor3 = Color3.new(1, 1, 1),
                        BorderSizePixel = 0,
                        Parent = sv,
                })
                corner(svHue, 8)
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
                corner(svDark, 8)
                New("UIGradient", {
                        Transparency = NumberSequence.new({
                                NumberSequenceKeypoint.new(0, 1),
                                NumberSequenceKeypoint.new(1, 0),
                        }),
                        Rotation = 90,
                        Parent = svDark,
                })
                local dot = New("Frame", {
                        Size = UDim2.new(0, 14, 0, 14),
                        BackgroundColor3 = Color3.new(0, 0, 0),
                        BorderSizePixel = 0,
                        ZIndex = 3,
                        Parent = sv,
                })
                corner(dot, 7)
                feather(dot, 7, Color3.new(0, 0, 0))
                local dotFace = New("Frame", {
                        Position = UDim2.new(0, 1, 0, 1),
                        Size = UDim2.new(1, -2, 1, -2),
                        BackgroundColor3 = Color3.new(1, 1, 1),
                        BorderSizePixel = 0,
                        Parent = dot,
                })
                corner(dotFace, 6)

                local hue = New("Frame", {
                        AnchorPoint = Vector2.new(1, 0),
                        Position = UDim2.new(1, 0, 0, 0),
                        Size = UDim2.new(0, GEO.HueW, 0, GEO.SVH),
                        BackgroundColor3 = Color3.new(1, 1, 1),
                        BorderSizePixel = 0,
                        Parent = popFace,
                })
                corner(hue, 7)
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
                        Rotation = 90,
                        Parent = hue,
                })
                local hdot = New("Frame", {
                        Position = UDim2.new(0, -2, 0, 0),
                        Size = UDim2.new(0, 18, 0, 18),
                        BackgroundColor3 = Color3.new(0, 0, 0),
                        BorderSizePixel = 0,
                        ZIndex = 3,
                        Parent = hue,
                })
                corner(hdot, 9)
                feather(hdot, 9, Color3.new(0, 0, 0))
                local hdotFace = New("Frame", {
                        Position = UDim2.new(0, 1, 0, 1),
                        Size = UDim2.new(1, -2, 1, -2),
                        BackgroundColor3 = Color3.new(1, 1, 1),
                        BorderSizePixel = 0,
                        Parent = hdot,
                })
                corner(hdotFace, 8)

                local preview = New("Frame", {
                        Position = UDim2.new(0, 0, 0, GEO.SVH + 10),
                        Size = UDim2.new(0, GEO.Swatch, 0, GEO.Swatch),
                        BackgroundColor3 = theme.LineStrong,
                        BorderSizePixel = 0,
                        Parent = popFace,
                })
                corner(preview, 6)
                feather(preview, 6, theme.LineStrong)
                local previewFace = New("Frame", {
                        Position = UDim2.new(0, 1, 0, 1),
                        Size = UDim2.new(1, -2, 1, -2),
                        BackgroundColor3 = theme.Accent,
                        BorderSizePixel = 0,
                        Parent = preview,
                })
                corner(previewFace, 5)
                New("TextLabel", {
                        Position = UDim2.new(0, GEO.Swatch + 10, 0, GEO.SVH + 10),
                        Size = UDim2.new(0, 0, 0, GEO.Swatch),
                        BackgroundTransparency = 1,
                        Font = F.Mono,
                        TextSize = 11,
                        TextColor3 = theme.TextFaint,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        Text = "HEX",
                        Parent = popFace,
                })
                local hexVal = New("TextLabel", {
                        AnchorPoint = Vector2.new(1, 0),
                        Position = UDim2.new(1, 0, 0, GEO.SVH + 10),
                        Size = UDim2.new(0, rnd(math.max(52, measureText("#0070F3", 12, F.Mono))), 0, GEO.Swatch),
                        BackgroundTransparency = 1,
                        Font = F.Mono,
                        TextSize = 12,
                        TextColor3 = theme.TextMuted,
                        TextXAlignment = Enum.TextXAlignment.Right,
                        TextTruncate = Enum.TextTruncate.AtEnd,
                        Text = "#0070F3",
                        Parent = popFace,
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
                        local svw = GEO.PopW - 22 - GEO.HueW - 10
                        dot.Position = UDim2.new(0, clamp(rnd(s * svw) - 7, 0, svw - 14), 0, clamp(rnd((1 - v) * GEO.SVH) - 7, 0, GEO.SVH - 14))
                        hdot.Position = UDim2.new(0, -2, 0, clamp(rnd(h * GEO.SVH) - 9, 0, GEO.SVH - 18))
                        swatchFace.BackgroundColor3 = color
                        previewFace.BackgroundColor3 = color
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
                                        active = apply
                                        apply(input)
                                end
                        end)
                end
                local function applySV(input)
                        local r, sz = sv.AbsolutePosition, sv.AbsoluteSize
                        if sz.X < 1 or sz.Y < 1 then return end
                        s = clamp((input.Position.X - r.X) / sz.X, 0, 1)
                        v = 1 - clamp((input.Position.Y - r.Y) / sz.Y, 0, 1)
                        render(true)
                end
                local function applyHue(input)
                        local r, sz = hue.AbsolutePosition, hue.AbsoluteSize
                        if sz.Y < 1 then return end
                        h = clamp((input.Position.Y - r.Y) / sz.Y, 0, 1)
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
                                local x, y, cappedH = mountPop(row, pop, popH, GEO.PopW, true)
                                pop.Visible = true
                                pop.Position = UDim2.new(0, x, 0, y + 6)
                                tween(pop, 0.15, { Position = UDim2.new(0, x, 0, y) }, Enum.EasingStyle.Quint)
                                registerPop(row, pop, setOpen, cappedH, GEO.PopW, true)
                        else
                                active = nil
                                tween(pop, 0.12, { Position = UDim2.new(0, pop.Position.X.Offset, 0, pop.Position.Y.Offset + 4) })
                                task.delay(0.14, function()
                                        if not open and pop.Parent then pop.Visible = false end
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
                return finishElement("ColorPicker", cp, cfg, row, { trigger }, pop)
        end

        local function addInput(section, cfg)
                cfg = cfg or {}
                local row = makeRow(section, GEO.RowH)
                rowLabel(row, cfg.Text, 202)

                local field = New("Frame", {
                        AnchorPoint = Vector2.new(1, 0.5),
                        Position = UDim2.new(1, -GEO.RowPad, 0.5, 0),
                        Size = UDim2.new(0, GEO.FieldW, 0, GEO.FieldH),
                        BackgroundColor3 = theme.LineStrong,
                        BorderSizePixel = 0,
                        ZIndex = 5,
                        Parent = row,
                })
                corner(field, 6)
                local fh = feather(field, 6, theme.LineStrong)
                local box = New("TextBox", {
                        Position = UDim2.new(0, 1, 0, 1),
                        Size = UDim2.new(1, -2, 1, -2),
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
                        ZIndex = 2,
                        Parent = field,
                })
                corner(box, 5)
                padding(box, 0, 10, 0, 10)

                box.Focused:Connect(function()
                        tween(field, 0.12, { BackgroundColor3 = theme.Accent })
                        tween(fh, 0.12, { BackgroundColor3 = theme.Accent })
                end)
                box.FocusLost:Connect(function(enter)
                        tween(field, 0.12, { BackgroundColor3 = theme.LineStrong })
                        tween(fh, 0.12, { BackgroundColor3 = theme.LineStrong })
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
                return finishElement("Input", inp, cfg, row, { field, box })
        end

        local function addButton(section, cfg)
                cfg = cfg or {}
                local primary = cfg.Primary and true or false
                local shell = New("Frame", {
                        Size = UDim2.new(1, 0, 0, GEO.RowH),
                        BackgroundColor3 = primary and theme.Accent or theme.Line,
                        BorderSizePixel = 0,
                        ZIndex = 1,
                        Parent = section.Rows,
                })
                corner(shell, 8)
                local bh = feather(shell, 8, primary and theme.Accent or theme.Line)
                local btn = New("TextButton", {
                        Position = UDim2.new(0, 1, 0, 1),
                        Size = UDim2.new(1, -2, 1, -2),
                        BackgroundColor3 = primary and theme.Accent or theme.RowHover,
                        BackgroundTransparency = primary and 0 or 1,
                        Text = tostring(cfg.Text or "Button"),
                        Font = F.Semibold,
                        TextSize = 13,
                        TextColor3 = primary and Color3.new(1, 1, 1) or theme.TextMuted,
                        AutoButtonColor = false,
                        BorderSizePixel = 0,
                        ZIndex = 2,
                        Parent = shell,
                })
                corner(btn, 7)
                if primary then
                        btn.MouseEnter:Connect(function()
                                tween(btn, 0.13, { BackgroundColor3 = theme.AccentHover })
                                tween(shell, 0.13, { BackgroundColor3 = theme.AccentHover })
                                tween(bh, 0.13, { BackgroundColor3 = theme.AccentHover })
                        end)
                        btn.MouseLeave:Connect(function()
                                tween(btn, 0.13, { BackgroundColor3 = theme.Accent })
                                tween(shell, 0.13, { BackgroundColor3 = theme.Accent })
                                tween(bh, 0.13, { BackgroundColor3 = theme.Accent })
                        end)
                else
                        btn.MouseEnter:Connect(function()
                                tween(btn, 0.13, { BackgroundTransparency = 0 })
                                tween(btn, 0.13, { TextColor3 = theme.Text })
                                tween(shell, 0.13, { BackgroundColor3 = theme.LineStrong })
                                tween(bh, 0.13, { BackgroundColor3 = theme.LineStrong })
                        end)
                        btn.MouseLeave:Connect(function()
                                tween(btn, 0.13, { BackgroundTransparency = 1 })
                                tween(btn, 0.13, { TextColor3 = theme.TextMuted })
                                tween(shell, 0.13, { BackgroundColor3 = theme.Line })
                                tween(bh, 0.13, { BackgroundColor3 = theme.Line })
                        end)
                end
                btn.Activated:Connect(function()
                        if cfg.Callback then cfg.Callback() end
                end)
                registerSearch(shell, cfg.Text, section)
                local b = { Button = btn }
                function b:Set(text)
                        btn.Text = tostring(text)
                end
                return finishElement("Button", b, cfg, shell, { btn })
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
                return finishElement("Paragraph", p, cfg, lbl, { lbl })
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
                if badge then
                        local btext = string.upper(tostring(badge))
                        local badgeW = measureText(btext, 10, F.Bold) + 10
                        local bd = New("Frame", {
                                Position = UDim2.new(0, titleW + 10, 0, -1),
                                Size = UDim2.new(0, badgeW, 0, 16),
                                BackgroundColor3 = theme.Accent,
                                BackgroundTransparency = 0.6,
                                BorderSizePixel = 0,
                                Parent = head,
                        })
                        corner(bd, 4)
                        feather(bd, 4, theme.Accent, 5, 2, 5, 2)
                        local bdFace = New("Frame", {
                                Position = UDim2.new(0, 1, 0, 1),
                                Size = UDim2.new(1, -2, 1, -2),
                                BackgroundColor3 = theme.Surface,
                                BorderSizePixel = 0,
                                Parent = bd,
                        })
                        corner(bdFace, 3)
                        New("TextLabel", {
                                Position = UDim2.new(0, 5, 0, 2),
                                Size = UDim2.new(1, -10, 1, -4),
                                BackgroundTransparency = 1,
                                Font = F.Bold,
                                TextSize = 10,
                                TextColor3 = theme.Accent,
                                Text = btext,
                                Parent = bd,
                        })
                end

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
                local padL = 12
                local ic = nil
                if iconName and ICONS[iconName] then
                        ic = icon(btn, iconName, 16, theme.TextMuted)
                        ic.AnchorPoint = Vector2.new(0, 0.5)
                        ic.Position = UDim2.new(0, -26, 0.5, 0)
                        ic.ZIndex = 2
                        padding(btn, 0, 12, 0, 38)
                        padL = 38
                else
                        padding(btn, 0, 12, 0, 12)
                end
                local tbh = feather(btn, 8, theme.RowHover, padL, 0, 12, 0)
                tbh.BackgroundTransparency = 1

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
                        tween(tbh, 0.12, { BackgroundTransparency = active and 0.5 or 1 })
                        btn.Font = active and F.Semibold or F.Medium
                end
                btn.MouseEnter:Connect(function()
                        if not page.Visible then
                                tween(btn, 0.12, { BackgroundTransparency = 0 })
                                tween(btn, 0.12, { TextColor3 = theme.Text })
                                tween(tbh, 0.12, { BackgroundTransparency = 0.5 })
                                if ic then tween(ic, 0.12, { ImageColor3 = theme.Text }) end
                        end
                end)
                btn.MouseLeave:Connect(function()
                        if not page.Visible then
                                tween(btn, 0.12, { BackgroundTransparency = 1 })
                                tween(btn, 0.12, { TextColor3 = theme.TextMuted })
                                tween(tbh, 0.12, { BackgroundTransparency = 1 })
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
                        killTween(page, "Position")
                        page.Position = UDim2.new(0, 8, 0, 0)
                        tween(page, 0.16, { Position = UDim2.new(0, 0, 0, 0) }, Enum.EasingStyle.Quint)
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
                        elseif input.KeyCode == Enum.KeyCode.Backspace then
                                state.listening._commit("None", nil, nil)
                        else
                                state.listening._commit(keyDisplayName(input.KeyCode.Name), input.KeyCode, nil)
                        end
                        return
                end
                if not gameProcessed then
                        for _, kb in ipairs(state.keybinds) do
                                local matched = false
                                if kb.KeyCode and kb.KeyCode ~= Enum.KeyCode.None and input.KeyCode == kb.KeyCode then matched = true end
                                if kb.UserInputType and input.UserInputType == kb.UserInputType then matched = true end
                                if matched and kb.Callback then
                                        if kb.Mode == "Toggle" then
                                                kb.Active = not kb.Active
                                                kb.Callback(kb.Active, kb.Name, input, gameProcessed)
                                        elseif kb.Mode == "Hold" then
                                                kb.Active = true
                                                kb.Callback(true, kb.Name, input, gameProcessed)
                                        else
                                                kb.Callback(kb.Name, input, gameProcessed)
                                        end
                                end
                        end
                end
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        local m = Vector2.new(input.Position.X, input.Position.Y)
                        for i = #state.openPops, 1, -1 do
                                local p = state.openPops[i]
                                if not inRect(p.row, m) and not inRect(p.pop, m) then
                                        p.close()
                                end
                        end
                        if state.listening and not gameProcessed then
                                local chip = state.listening._chip
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
        connect(UserInputService.InputEnded, function(input, gameProcessed)
                for _, kb in ipairs(state.keybinds) do
                        if kb.Mode == "Hold" and kb.Active and kb.Callback then
                                local matched = false
                                if kb.KeyCode and kb.KeyCode ~= Enum.KeyCode.None and input.KeyCode == kb.KeyCode then matched = true end
                                if kb.UserInputType and input.UserInputType == kb.UserInputType then matched = true end
                                if matched then
                                        kb.Active = false
                                        kb.Callback(false, kb.Name, input, gameProcessed)
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

        function Window:SetTitle(text)
                Window.Title = tostring(text or "")
                titleLbl.Text = Window.Title
        end

        local function sanitizeName(s)
                return (tostring(s):gsub("[^%w%-_]", "-"))
        end
        local function cfgDir()
                return "reborn/" .. sanitizeName(config.Title or "Reborn")
        end
        local function cfgPath(name)
                return cfgDir() .. "/" .. sanitizeName(name or "default") .. ".json"
        end
        local function fsAvailable()
                return type(writefile) == "function" and type(readfile) == "function" and type(isfile) == "function"
        end

        function Window:GetConfig()
                local out = {}
                for _, e in ipairs(state.elements) do
                        local el, k, flag = e.el, e.kind, e.cfg.Flag
                        if flag and not e.hidden then
                                if k == "Toggle" then
                                        out[flag] = el.Value and true or false
                                elseif k == "Slider" then
                                        out[flag] = el.Value
                                elseif k == "Dropdown" then
                                        if type(el.Value) == "table" then
                                                local c = {}
                                                for i, v in ipairs(el.Value) do c[i] = v end
                                                out[flag] = c
                                        else
                                                out[flag] = el.Value
                                        end
                                elseif k == "Keybind" then
                                        out[flag] = el.Name
                                elseif k == "ColorPicker" then
                                        out[flag] = el.Hex
                                elseif k == "Input" then
                                        out[flag] = el.Text
                                end
                        end
                end
                return out
        end

        function Window:SetConfig(vals)
                if type(vals) ~= "table" then return end
                for _, e in ipairs(state.elements) do
                        local flag = e.cfg.Flag
                        if flag and vals[flag] ~= nil then
                                if e.kind == "Keybind" or e.kind == "Input" then
                                        e.el:Set(vals[flag])
                                else
                                        e.el:Set(vals[flag], false)
                                end
                        end
                end
        end

        function Window:SaveConfig(name)
                name = tostring(name or "default")
                local okJson, json = pcall(function() return HttpService:JSONEncode(self:GetConfig()) end)
                if not okJson or type(json) ~= "string" then return false end
                if fsAvailable() then
                        if type(isfolder) == "function" and type(makefolder) == "function" then
                                pcall(function()
                                        if not isfolder("reborn") then makefolder("reborn") end
                                        if not isfolder(cfgDir()) then makefolder(cfgDir()) end
                                end)
                        end
                        local ok = pcall(function() writefile(cfgPath(name), json) end)
                        if not ok then return false end
                else
                        Reborn._configs[cfgPath(name)] = json
                end
                return true
        end

        function Window:LoadConfig(name)
                name = tostring(name or "default")
                local json = nil
                if fsAvailable() then
                        local ok, content = pcall(function()
                                if isfile(cfgPath(name)) then return readfile(cfgPath(name)) end
                                return nil
                        end)
                        if ok then json = content end
                end
                if json == nil then json = Reborn._configs[cfgPath(name)] end
                if type(json) ~= "string" then return nil end
                local ok, tbl = pcall(function() return HttpService:JSONDecode(json) end)
                if not ok or type(tbl) ~= "table" then return nil end
                self:SetConfig(tbl)
                return tbl
        end

        function Window:DeleteConfig(name)
                name = tostring(name or "default")
                Reborn._configs[cfgPath(name)] = nil
                if fsAvailable() and type(delfile) == "function" then
                        pcall(function()
                                if isfile(cfgPath(name)) then delfile(cfgPath(name)) end
                        end)
                end
                return true
        end

        function Window:ListConfigs()
                local out, seen = {}, {}
                if type(listfiles) == "function" then
                        local ok, files = pcall(function() return listfiles(cfgDir()) end)
                        if ok and type(files) == "table" then
                                for _, f in ipairs(files) do
                                        local base = tostring(f):match("([^%/\\]+)%.json$")
                                        if base and not seen[base] then
                                                seen[base] = true
                                                table.insert(out, base)
                                        end
                                end
                        end
                end
                for path in pairs(Reborn._configs) do
                        local base = path:match("^" .. cfgDir():gsub("%W", "%%%0") .. "/(.+)%.json$")
                        if base and not seen[base] then
                                seen[base] = true
                                table.insert(out, base)
                        end
                end
                table.sort(out)
                return out
        end

        function Window:SetVisible(v)
                if v then
                        if state.min then setMinimized(false) else reopen() end
                else
                        closeWindow()
                end
        end

        function Window:Toggle()
                if state.min then
                        setMinimized(false)
                elseif state.closed then
                        reopen()
                else
                        setMinimized(true)
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
