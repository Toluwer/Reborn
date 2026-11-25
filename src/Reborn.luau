local Theme = (function()
        local DEFAULT_THEME = {
                Background   = Color3.fromRGB(17, 17, 17),
                Surface      = Color3.fromRGB(24, 24, 24),
                Overlay      = Color3.fromRGB(36, 36, 36),
                Chip         = Color3.fromRGB(24, 24, 24),
                RowHover     = Color3.fromRGB(45, 45, 45),
                OptionHover  = Color3.fromRGB(45, 45, 45),
                Line         = Color3.fromRGB(48, 48, 48),
                LineStrong   = Color3.fromRGB(56, 56, 56),
                Text         = Color3.fromRGB(244, 244, 244),
                TextMuted    = Color3.fromRGB(170, 170, 170),
                TextFaint    = Color3.fromRGB(119, 119, 119),
                Accent       = Color3.fromRGB(44, 103, 197),
                AccentHover  = Color3.fromRGB(59, 120, 215),
                Success      = Color3.fromRGB(41, 211, 145),
                Error        = Color3.fromRGB(230, 60, 60),
                ToggleOff    = Color3.fromRGB(45, 45, 45),
                Handle       = Color3.fromRGB(244, 244, 244),
        }

        local INTER = "rbxassetid://12187365364"

        local F = {
                Regular  = Font.new(INTER, Enum.FontWeight.Regular),
                Medium   = Font.new(INTER, Enum.FontWeight.Medium),
                Semibold = Font.new(INTER, Enum.FontWeight.SemiBold),
                Bold     = Font.new(INTER, Enum.FontWeight.Bold),
                Mono     = Font.fromEnum(Enum.Font.Code),
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
                Sidebar      = 160,
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
                ImageH       = 96,
                ImageMinH    = 24,
                ImageMaxH    = 400,
                ListH        = 120,
                ListMaxH     = 260,
                ListMinH     = 46,
        }

        return { Default = DEFAULT_THEME, Fonts = F, Geometry = GEO }
end)()

local createCore = (function()
        return function(Theme)
                local F = Theme.Fonts

                local TweenService = game:GetService("TweenService")
                local UserInputService = game:GetService("UserInputService")
                local TextService = game:GetService("TextService")
                local Players = game:GetService("Players")
                local HttpService = game:GetService("HttpService")

                local function rnd(x) return math.floor(x + 0.5) end
                local function clamp(v, a, b)
                        if v < a then return a elseif v > b then return b end
                        return v
                end

                local function toWidth(w, def)
                        if type(w) == "number" then
                                if w > 0 and w < 1 then return UDim.new(w, 0) end
                                if w >= 1 then return UDim.new(0, rnd(w)) end
                        end
                        return def
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
                        if font == F.Mono then
                                local ok, w = pcall(function()
                                        return TextService:GetTextSize(text, size, Enum.Font.Code, Vector2.new(4096, size * 2)).X
                                end)
                                if ok and w then return w end
                        else
                                local params = Instance.new("GetTextBoundsParams")
                                params.Text = text
                                params.Size = size
                                params.Font = font
                                params.Width = 4096
                                local ok, bounds = pcall(function()
                                        return TextService:GetTextBoundsAsync(params)
                                end)
                                params:Destroy()
                                if ok and bounds then return bounds.X end
                                local fallback = font.Weight == Enum.FontWeight.Bold and Enum.Font.GothamBold
                                        or font.Weight == Enum.FontWeight.SemiBold and Enum.Font.GothamSemibold
                                        or font.Weight == Enum.FontWeight.Medium and Enum.Font.GothamMedium
                                        or Enum.Font.Gotham
                                local measured, w = pcall(function()
                                        return TextService:GetTextSize(text, size, fallback, Vector2.new(4096, size * 2)).X
                                end)
                                if measured and w then return w end
                        end
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

                local function clearOld(parent, mark)
                        for _, child in ipairs(parent:GetChildren()) do
                                if child:GetAttribute(mark or MARK) then child:Destroy() end
                        end
                end

                local function normCfg(a, b)
                        if type(a) == "string" then a = { Text = a } end
                        if type(b) == "function" and a and a.Callback == nil then a.Callback = b end
                        return a or {}
                end

                return {
                        TweenService = TweenService,
                        UserInputService = UserInputService,
                        TextService = TextService,
                        Players = Players,
                        HttpService = HttpService,
                        rnd = rnd,
                        clamp = clamp,
                        toWidth = toWidth,
                        New = New,
                        corner = corner,
                        padding = padding,
                        list = list,
                        tween = tween,
                        killTween = killTween,
                        measureText = measureText,
                        colorToHex = colorToHex,
                        hexToColor = hexToColor,
                        keyDisplayName = keyDisplayName,
                        fmtNum = fmtNum,
                        MOUSE_NAMES = MOUSE_NAMES,
                        resolveParent = resolveParent,
                        MARK = MARK,
                        randomName = randomName,
                        nextOrder = nextOrder,
                        protectGui = protectGui,
                        clearOld = clearOld,
                        normCfg = normCfg,
                }
        end
end)()

local createIcons = (function()
        return function(Core)
                local New = Core.New

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

                return { Map = ICONS, Create = icon }
        end
end)()

local createNotifications = (function()
        return function(Reborn, Core, Theme, Icons)
                local DEFAULT_THEME = Theme.Default
                local F = Theme.Fonts
                local GEO = Theme.Geometry
                local icon = Icons.Create
                local New = Core.New
                local corner = Core.corner
                local padding = Core.padding
                local tween = Core.tween
                local measureText = Core.measureText
                local resolveParent = Core.resolveParent
                local MARK = Core.MARK
                local randomName = Core.randomName
                local protectGui = Core.protectGui
                local clearOld = Core.clearOld

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
                                padding(toast, 11, 12, 11, 12)

                                local ic = icon(toast, kind.name, 16, kind.color)
                                ic.Position = UDim2.new(0, 0, 0, 0)

                                local title = New("TextLabel", {
                                        Position = UDim2.new(0, 27, 0, 0),
                                        Size = UDim2.new(1, -27, 0, 16),
                                        BackgroundTransparency = 1,
                                        FontFace = F.Semibold,
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
                                        FontFace = F.Regular,
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

                return { Build = buildToastLayer, Normalize = normNotify }
        end
end)()

local createWindow = (function()
        return function(Reborn, Core, Theme, Icons, Notifications, Components)
                local DEFAULT_THEME = Theme.Default
                local F = Theme.Fonts
                local GEO = Theme.Geometry
                local ICONS = Icons.Map
                local icon = Icons.Create
                local buildToastLayer = Notifications.Build
                local normNotify = Notifications.Normalize
                local TweenService = Core.TweenService
                local UserInputService = Core.UserInputService
                local HttpService = Core.HttpService
                local rnd = Core.rnd
                local clamp = Core.clamp
                local toWidth = Core.toWidth
                local New = Core.New
                local corner = Core.corner
                local padding = Core.padding
                local list = Core.list
                local tween = Core.tween
                local killTween = Core.killTween
                local measureText = Core.measureText
                local colorToHex = Core.colorToHex
                local hexToColor = Core.hexToColor
                local keyDisplayName = Core.keyDisplayName
                local fmtNum = Core.fmtNum
                local MOUSE_NAMES = Core.MOUSE_NAMES
                local resolveParent = Core.resolveParent
                local MARK = Core.MARK
                local randomName = Core.randomName
                local nextOrder = Core.nextOrder
                local protectGui = Core.protectGui
                local clearOld = Core.clearOld
                local normCfg = Core.normCfg

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

                        local windowFrame = New("CanvasGroup", {
                                GroupTransparency = 0,
                                Name = randomName(),
                                Size = UDim2.new(0, W, 0, H),
                                BackgroundColor3 = theme.Surface,
                                BorderSizePixel = 0,
                                Parent = gui,
                        })
                        local winCorner = corner(windowFrame, GEO.WindowRadius)
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
                                FontFace = F.Semibold,
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
                                AnchorPoint = Vector2.new(1, 0),
                                Position = UDim2.new(0, GEO.SearchW, 0, 7),
                                Size = UDim2.new(0, 0, 0, GEO.SearchH),
                                BackgroundColor3 = theme.Overlay,
                                BackgroundTransparency = 0,
                                BorderSizePixel = 0,
                                ClipsDescendants = true,
                                Visible = false,
                                Parent = cluster,
                        })
                        corner(searchWrap, 6)
                        local searchBox = New("TextBox", {
                                AnchorPoint = Vector2.new(1, 0),
                                Position = UDim2.new(1, 0, 0, 0),
                                Size = UDim2.new(0, GEO.SearchW, 1, 0),
                                BackgroundTransparency = 1,
                                TextTransparency = 1,
                                Text = "",
                                PlaceholderText = "search…",
                                PlaceholderColor3 = theme.TextFaint,
                                FontFace = F.Regular,
                                TextSize = 12,
                                TextColor3 = theme.Text,
                                TextXAlignment = Enum.TextXAlignment.Left,
                                ClearTextOnFocus = false,
                                BorderSizePixel = 0,
                                ClipsDescendants = true,
                                Parent = searchWrap,
                        })
                        corner(searchBox, 6)
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
                                BackgroundColor3 = theme.Background,
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
                                FontFace = F.Semibold,
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
                                FontFace = F.Regular,
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
                                if state.closed then return end
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
                                if state.closed then return end
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
                                        tween(windowFrame, 0.3, { BackgroundColor3 = theme.Surface })
                                end
                        end

                        local function closeWindow()
                                if state.closed then return end
                                state.closed = true
                                dragState = nil
                                resizeState = nil
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
                                        windowFrame.Size = UDim2.new(0, W, 0, H)
                                        winCorner.CornerRadius = UDim.new(0, GEO.WindowRadius)
                                        faceCorner.CornerRadius = UDim.new(0, GEO.WindowRadius - 1)
                                        windowFrame.BackgroundColor3 = theme.Surface
                                        if state.minPos then
                                                windowFrame.Position = UDim2.new(0, state.minPos.x, 0, state.minPos.y)
                                        end
                                end
                                killTween(windowFrame, "Position")
                                killTween(windowFrame, "Size")
                                state.closeGeneration = (state.closeGeneration or 0) + 1
                                local generation = state.closeGeneration
                                if not windowFrame.Visible then
                                        windowFrame.GroupTransparency = 1
                                        return
                                end
                                local exit = tween(windowFrame, 0.20, { GroupTransparency = 1 }, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
                                exit.Completed:Once(function(playback)
                                        if playback == Enum.PlaybackState.Completed and state.closed and state.closeGeneration == generation and windowFrame.Parent then
                                                windowFrame.Visible = false
                                        end
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
                                if not state.closed or state.unloading then return end
                                state.closed = false
                                if state.min then setMinimized(false) end
                                closeAllPops()
                                state.closeGeneration = (state.closeGeneration or 0) + 1
                                killTween(windowFrame, "GroupTransparency")
                                windowFrame.Visible = true
                                tween(windowFrame, 0.22, { GroupTransparency = 0 }, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
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
                        local searchGeneration = 0
                        local searchPress = nil
                        local searchLostDuringPress = false

                        local function openSearch()
                                if searchOpen or state.closed or state.min then return end
                                searchGeneration = searchGeneration + 1
                                searchBox.Text = ""
                                searchOpen = true
                                searchWrap.Visible = true
                                tween(searchWrap, 0.25, { Size = UDim2.new(0, GEO.SearchW, 0, GEO.SearchH) }, Enum.EasingStyle.Quart)
                                tween(searchBox, 0.20, { TextTransparency = 0 }, Enum.EasingStyle.Sine)
                                searchBox:CaptureFocus()
                        end

                        closeSearch = function()
                                if not searchOpen then return end
                                searchOpen = false
                                searchGeneration = searchGeneration + 1
                                local generation = searchGeneration
                                searchBox:ReleaseFocus()
                                applyFilter("")
                                tween(searchBox, 0.12, { TextTransparency = 1 }, Enum.EasingStyle.Sine)
                                local exit = tween(searchWrap, 0.19, { Size = UDim2.new(0, 0, 0, GEO.SearchH) }, Enum.EasingStyle.Quart, Enum.EasingDirection.InOut)
                                exit.Completed:Once(function(playback)
                                        if playback == Enum.PlaybackState.Completed and generation == searchGeneration and not searchOpen and searchWrap.Parent then
                                                searchWrap.Visible = false
                                                searchBox.Text = ""
                                        end
                                end)
                        end

                        searchBtn.InputBegan:Connect(function(input)
                                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                                        searchPress = input
                                        searchLostDuringPress = false
                                end
                        end)
                        connect(UserInputService.InputEnded, function(input)
                                if searchPress ~= input then return end
                                task.defer(function()
                                        if searchPress ~= input then return end
                                        searchPress = nil
                                        if searchLostDuringPress and searchOpen and not searchBox:IsFocused() then
                                                closeSearch()
                                        end
                                        searchLostDuringPress = false
                                end)
                        end)
                        searchBtn.Activated:Connect(function()
                                searchPress = nil
                                searchLostDuringPress = false
                                if searchOpen then
                                        closeSearch()
                                else
                                        openSearch()
                                end
                        end)
                        searchBox:GetPropertyChangedSignal("Text"):Connect(function()
                                if searchOpen then applyFilter(searchBox.Text) end
                        end)
                        searchBox.FocusLost:Connect(function()
                                local generation = searchGeneration
                                task.defer(function()
                                        if not searchOpen or generation ~= searchGeneration or searchBox:IsFocused() then return end
                                        if searchPress then
                                                searchLostDuringPress = true
                                        else
                                                closeSearch()
                                        end
                                end)
                        end)

                        local disabledRows = setmetatable({}, { __mode = "k" })

                        local function setRowDim(row, face, d)
                                disabledRows[row] = d or nil
                                killTween(face, "BackgroundColor3")
                                face.BackgroundColor3 = theme.Overlay
                                face.BackgroundTransparency = d and 0.3 or 0
                        end

                        local function makeRow(section, h, w)
                                local row = New("Frame", {
                                        Size = w and UDim2.new(w.Scale, w.Offset, 0, h) or UDim2.new(1, 0, 0, h),
                                        BackgroundTransparency = 1,
                                        BorderSizePixel = 0,
                                        ZIndex = 1,
                                        Parent = section.Rows,
                                })
                                corner(row, 6)
                                local face = New("Frame", {
                                        Position = UDim2.new(0, 0, 0, 0),
                                        Size = UDim2.new(1, 0, 1, 0),
                                        BackgroundColor3 = theme.Overlay,
                                        BorderSizePixel = 0,
                                        Parent = row,
                                })
                                corner(face, 6)
                                row.MouseEnter:Connect(function()
                                        if disabledRows[row] then return end
                                        tween(face, 0.12, { BackgroundColor3 = theme.RowHover })
                                end)
                                row.MouseLeave:Connect(function()
                                        tween(face, 0.12, { BackgroundColor3 = theme.Overlay })
                                end)
                                return row, face
                        end

                        local function rowLabel(row, text, clear)
                                local lbl = New("TextLabel", {
                                        AnchorPoint = Vector2.new(0, 0.5),
                                        Position = UDim2.new(0, GEO.RowPad, 0.5, 0),
                                        Size = UDim2.new(1, -(GEO.RowPad + (clear or 60)), 0, 16),
                                        BackgroundTransparency = 1,
                                        FontFace = F.Medium,
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
                                if section and section._isRow then
                                        local e = section._search
                                        if e == nil then
                                                e = { frame = section.Frame, text = "", section = section._parent }
                                                section._search = e
                                                table.insert(state.searchRows, e)
                                        end
                                        local add = tostring(text or "")
                                        e.text = e.text == "" and add or (e.text .. " " .. add)
                                        return
                                end
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
                                BackgroundTransparency = 1,
                                BorderSizePixel = 0,
                                Visible = false,
                                ZIndex = 60,
                                Parent = gui,
                        })
                        corner(tipWrap, 6)
                        local tipFace = New("Frame", {
                                Position = UDim2.new(0, 0, 0, 0),
                                Size = UDim2.new(1, 0, 1, 0),
                                BackgroundColor3 = theme.Overlay,
                                BorderSizePixel = 0,
                                Parent = tipWrap,
                        })
                        corner(tipFace, 6)
                        local tipTxt = New("TextLabel", {
                                Position = UDim2.new(0, 10, 0, 0),
                                Size = UDim2.new(1, -20, 1, 0),
                                BackgroundTransparency = 1,
                                FontFace = F.Regular,
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
                                tween(tipFace, 0.1, { BackgroundTransparency = 1 })
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
                                tipFace.BackgroundTransparency = 0
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

                        local function finishElement(kind, el, cfg, row, hosts, pop, setEnabled)
                                el._kind = kind
                                el.Flag = cfg.Flag
                                el._row = row
                                local userCb = cfg.Callback
                                local entry = { kind = kind, el = el, cfg = cfg, row = row, pop = pop, disabled = false, setEnabled = setEnabled }
                                if userCb then
                                        cfg.Callback = function(...)
                                                if entry.disabled then return end
                                                return userCb(...)
                                        end
                                end
                                function el:SetEnabled(v)
                                        local d = not (v and true or false)
                                        if entry.disabled == d then return end
                                        entry.disabled = d
                                        if setEnabled then setEnabled(not d) end
                                end
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
                                if not confirmActive or state.unloading then return end
                                confirmActive = false
                                tween(scrim, 0.15, { BackgroundTransparency = 1 })
                                tween(card, 0.15, { Position = UDim2.new(0.5, 0, 0.5, 8), GroupTransparency = 1 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
                                task.delay(0.2, function()
                                        if not confirmActive then
                                                card.Visible = false
                                                scrim.Visible = false
                                        end
                                end)
                        end

                        local function unloadNow()
                                if state.closed or state.unloading or not confirmActive then return end
                                state.unloading = true
                                closeWindow()
                                task.delay(0.22, function()
                                        if state.unloading and gui.Parent then
                                                pcall(function() Reborn:Unload() end)
                                        end
                                end)
                        end

                        local function showConfirm()
                                if confirmActive or state.closed then return end
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
                                        corner(scrim, GEO.WindowRadius - 1)
                                        card = New("CanvasGroup", {
                                                GroupTransparency = 1,
                                                AnchorPoint = Vector2.new(0.5, 0.5),
                                                Position = UDim2.new(0.5, 0, 0.5, 0),
                                                Size = UDim2.new(0, 420, 0, 156),
                                                BackgroundTransparency = 1,
                                                BorderSizePixel = 0,
                                                Visible = false,
                                                ZIndex = 31,
                                                Parent = windowFace,
                                        })
                                        corner(card, 8)
                                        local cardFace = New("Frame", {
                                                Position = UDim2.new(0, 0, 0, 0),
                                                Size = UDim2.new(1, 0, 1, 0),
                                                BackgroundColor3 = theme.Overlay,
                                                BorderSizePixel = 0,
                                                Parent = card,
                                        })
                                        corner(cardFace, 8)
                                        New("TextLabel", {
                                                Position = UDim2.new(0, 20, 0, 20),
                                                Size = UDim2.new(1, -40, 0, 16),
                                                BackgroundTransparency = 1,
                                                FontFace = F.Semibold,
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
                                                FontFace = F.Regular,
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
                                                BackgroundTransparency = 1,
                                                BorderSizePixel = 0,
                                                Parent = cardFace,
                                        })
                                        corner(cancelWrap, 6)
                                        local cancelB = New("TextButton", {
                                                Position = UDim2.new(0, 0, 0, 0),
                                                Size = UDim2.new(1, 0, 1, 0),
                                                BackgroundColor3 = theme.Surface,
                                                BackgroundTransparency = 0,
                                                Text = "Cancel",
                                                FontFace = F.Semibold,
                                                TextSize = 13,
                                                TextColor3 = theme.TextMuted,
                                                AutoButtonColor = false,
                                                BorderSizePixel = 0,
                                                Parent = cancelWrap,
                                        })
                                        corner(cancelB, 6)
                                        local closeWrap = New("Frame", {
                                                Position = UDim2.new(0.5, 5, 0, 100),
                                                Size = UDim2.new(0.5, -29, 0, 36),
                                                BackgroundTransparency = 1,
                                                BorderSizePixel = 0,
                                                Parent = cardFace,
                                        })
                                        corner(closeWrap, 6)
                                        local closeB = New("TextButton", {
                                                Position = UDim2.new(0, 0, 0, 0),
                                                Size = UDim2.new(1, 0, 1, 0),
                                                BackgroundColor3 = theme.Error,
                                                Text = "Close",
                                                FontFace = F.Semibold,
                                                TextSize = 13,
                                                TextColor3 = Color3.new(1, 1, 1),
                                                AutoButtonColor = false,
                                                BorderSizePixel = 0,
                                                Parent = closeWrap,
                                        })
                                        corner(closeB, 6)
                                        cancelB.MouseEnter:Connect(function()
                                                tween(cancelB, 0.12, { BackgroundColor3 = theme.RowHover })
                                                tween(cancelB, 0.12, { TextColor3 = theme.Text })
                                        end)
                                        cancelB.MouseLeave:Connect(function()
                                                tween(cancelB, 0.12, { BackgroundColor3 = theme.Surface })
                                                tween(cancelB, 0.12, { TextColor3 = theme.TextMuted })
                                        end)
                                        closeB.MouseEnter:Connect(function()
                                                tween(closeB, 0.12, { BackgroundColor3 = Color3.fromRGB(238, 80, 80) })
                                        end)
                                        closeB.MouseLeave:Connect(function()
                                                tween(closeB, 0.12, { BackgroundColor3 = theme.Error })
                                        end)
                                        cancelB.Activated:Connect(hideConfirm)
                                        closeB.Activated:Connect(unloadNow)
                                end
                                confirmActive = true
                                card.Size = UDim2.new(0, math.min(420, W - 48), 0, 156)
                                scrim.Visible = true
                                card.Visible = true
                                scrim.BackgroundTransparency = 1
                                card.Position = UDim2.new(0.5, 0, 0.5, 8)
                                card.GroupTransparency = 1
                                tween(scrim, 0.20, { BackgroundTransparency = 0.42 })
                                tween(card, 0.23, { Position = UDim2.new(0.5, 0, 0.5, 0), GroupTransparency = 0 }, Enum.EasingStyle.Quart)
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

                        local context = {
                                F = F,
                                GEO = GEO,
                                MOUSE_NAMES = MOUSE_NAMES,
                                New = New,
                                TweenService = TweenService,
                                UserInputService = UserInputService,
                                clamp = clamp,
                                closeAllPops = closeAllPops,
                                colorToHex = colorToHex,
                                connect = connect,
                                corner = corner,
                                finishElement = finishElement,
                                fmtNum = fmtNum,
                                hexToColor = hexToColor,
                                icon = icon,
                                killTween = killTween,
                                list = list,
                                makeRow = makeRow,
                                measureText = measureText,
                                mountPop = mountPop,
                                nextOrder = nextOrder,
                                normCfg = normCfg,
                                overlayBtn = overlayBtn,
                                padding = padding,
                                registerPop = registerPop,
                                registerSearch = registerSearch,
                                rnd = rnd,
                                rowLabel = rowLabel,
                                setRowDim = setRowDim,
                                state = state,
                                theme = theme,
                                toWidth = toWidth,
                                tween = tween,
                                unregisterPop = unregisterPop,
                        }

                        local addToggle = Components.Toggle(context)
                        context.addToggle = addToggle
                        local addSlider = Components.Slider(context)
                        context.addSlider = addSlider
                        local addDropdown = Components.Dropdown(context)
                        context.addDropdown = addDropdown
                        local addKeybind = Components.Keybind(context)
                        context.addKeybind = addKeybind
                        local addColorPicker = Components.ColorPicker(context)
                        context.addColorPicker = addColorPicker
                        local addInput = Components.Input(context)
                        context.addInput = addInput
                        local addButton = Components.Button(context)
                        context.addButton = addButton
                        local addParagraph = Components.Paragraph(context)
                        context.addParagraph = addParagraph
                        local addImage = Components.Image(context)
                        context.addImage = addImage
                        local addList = Components.List(context)
                        context.addList = addList
                        local addRowContainer = Components.Row(context)
                        context.addRowContainer = addRowContainer

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
                                        FontFace = F.Semibold,
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
                                                BackgroundTransparency = 1,
                                                BorderSizePixel = 0,
                                                Parent = head,
                                        })
                                        corner(bd, 4)
                                        local bdFace = New("Frame", {
                                                Position = UDim2.new(0, 0, 0, 0),
                                                Size = UDim2.new(1, 0, 1, 0),
                                                BackgroundColor3 = theme.Overlay,
                                                BorderSizePixel = 0,
                                                Parent = bd,
                                        })
                                        corner(bdFace, 4)
                                        New("TextLabel", {
                                                Position = UDim2.new(0, 5, 0, 2),
                                                Size = UDim2.new(1, -10, 1, -4),
                                                BackgroundTransparency = 1,
                                                FontFace = F.Bold,
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
                                function section:Image(a, b) return addImage(section, normCfg(a, b)) end
                                function section:List(a, b) return addList(section, normCfg(a, b)) end
                                function section:Row(a, b) return addRowContainer(section, normCfg(a, b)) end
                                return section
                        end

                        local function addTab(name, iconName)
                                local btn = New("TextButton", {
                                        Size = UDim2.new(1, 0, 0, GEO.TabH),
                                        BackgroundTransparency = 1,
                                        BackgroundColor3 = theme.RowHover,
                                        Text = tostring(name or "Tab"),
                                        FontFace = F.Medium,
                                        TextSize = 13,
                                        TextColor3 = theme.TextMuted,
                                        TextXAlignment = Enum.TextXAlignment.Left,
                                        AutoButtonColor = false,
                                        Parent = tabsHolder,
                                })
                                corner(btn, 6)
                                local ic = nil
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
                                        btn.FontFace = active and F.Semibold or F.Medium
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
                                                elseif k == "Image" then
                                                        out[flag] = el.Image.Image
                                                elseif k == "List" then
                                                        out[flag] = el.Selected
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
        end
end)()

local Components = {}

Components.Toggle = (function()
        return function(ctx)
                local toWidth = ctx.toWidth
                local New = ctx.New
                local corner = ctx.corner
                local tween = ctx.tween
                local theme = ctx.theme
                local GEO = ctx.GEO
                local makeRow = ctx.makeRow
                local setRowDim = ctx.setRowDim
                local rowLabel = ctx.rowLabel
                local overlayBtn = ctx.overlayBtn
                local registerSearch = ctx.registerSearch
                local finishElement = ctx.finishElement

                local function addToggle(section, cfg)
                        cfg = cfg or {}
                        local row, face = makeRow(section, GEO.RowH, toWidth(cfg.Width, nil))
                        local lbl = rowLabel(row, cfg.Text, 66)
                        local btn = overlayBtn(row)

                        local track = New("Frame", {
                                AnchorPoint = Vector2.new(1, 0.5),
                                Position = UDim2.new(1, -GEO.RowPad, 0.5, 0),
                                Size = UDim2.new(0, GEO.SwitchW, 0, GEO.SwitchH),
                                BackgroundTransparency = 1,
                                BorderSizePixel = 0,
                                ZIndex = 5,
                                Parent = row,
                        })
                        corner(track, GEO.SwitchH / 2)
                        local trackFace = New("Frame", {
                                Position = UDim2.new(0, 0, 0, 0),
                                Size = UDim2.new(1, 0, 1, 0),
                                BackgroundColor3 = theme.ToggleOff,
                                BorderSizePixel = 0,
                                Parent = track,
                        })
                        corner(trackFace, GEO.SwitchH / 2)
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
                                local c = value and theme.Accent or theme.ToggleOff
                                if instant then
                                        knob.Position = UDim2.new(0, nx, 0, 3)
                                        trackFace.BackgroundColor3 = c
                                else
                                        tween(knob, 0.16, { Position = UDim2.new(0, nx, 0, 3) })
                                        tween(trackFace, 0.16, { BackgroundColor3 = c })
                                end
                                tog.Value = value
                                if fire and cfg.Callback then cfg.Callback(value) end
                        end
                        local disabled = false
                        btn.Activated:Connect(function()
                                if disabled then return end
                                value = not value
                                render(true)
                        end)
                        render(false, true)
                        registerSearch(row, cfg.Text, section)

                        function tog:Set(v, fire)
                                value = v and true or false
                                render(fire and true or false)
                        end
                        local function setEnabled(v)
                                disabled = not v
                                setRowDim(row, face, disabled)
                                lbl.TextTransparency = disabled and 0.5 or 0
                                if disabled then
                                        knob.BackgroundTransparency = 0.45
                                        trackFace.BackgroundTransparency = 0.45
                                else
                                        knob.BackgroundTransparency = 0
                                        trackFace.BackgroundTransparency = 0
                                        render(false, true)
                                end
                        end
                        return finishElement("Toggle", tog, cfg, row, { btn }, nil, setEnabled)
                end

                return addToggle
        end
end)()

Components.Slider = (function()
        return function(ctx)
                local UserInputService = ctx.UserInputService
                local rnd = ctx.rnd
                local clamp = ctx.clamp
                local toWidth = ctx.toWidth
                local New = ctx.New
                local corner = ctx.corner
                local fmtNum = ctx.fmtNum
                local theme = ctx.theme
                local GEO = ctx.GEO
                local F = ctx.F
                local connect = ctx.connect
                local makeRow = ctx.makeRow
                local setRowDim = ctx.setRowDim
                local registerSearch = ctx.registerSearch
                local finishElement = ctx.finishElement

                local function addSlider(section, cfg)
                        cfg = cfg or {}
                        local row, face = makeRow(section, GEO.SliderH, toWidth(cfg.Width, nil))

                        local top = New("Frame", {
                                Position = UDim2.new(0, GEO.RowPad, 0, 10),
                                Size = UDim2.new(1, -GEO.RowPad * 2, 0, 16),
                                BackgroundTransparency = 1,
                                Parent = row,
                        })
                        local lblTop = New("TextLabel", {
                                Size = UDim2.new(1, -80, 1, 0),
                                BackgroundTransparency = 1,
                                FontFace = F.Medium,
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
                                FontFace = F.Medium,
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
                                if type(cfg.Format) == "function" then
                                        val.Text = tostring(cfg.Format(value))
                                else
                                        val.Text = fmtNum(value) .. suffix
                                end
                                sld.Value = value
                        end
                        track:GetPropertyChangedSignal("AbsoluteSize"):Connect(render)
                        task.defer(render)

                        local dragging = false
                        local disabled = false
                        local function fromX(x)
                                local tw = track.AbsoluteSize.X
                                if tw < 1 then return end
                                local p = clamp((x - track.AbsolutePosition.X) / tw, 0, 1)
                                value = snap(min + (max - min) * p)
                                render()
                                if cfg.Callback then cfg.Callback(value) end
                        end
                        track.InputBegan:Connect(function(input)
                                if disabled then return end
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
                        function sld:SetRange(mn, mx)
                                mn = tonumber(mn)
                                mx = tonumber(mx)
                                if mn == nil or mx == nil or mx <= mn then return false end
                                min = mn
                                max = mx
                                value = snap(clamp(value, min, max))
                                sld.Value = value
                                render()
                                return true
                        end
                        local function setEnabled(v)
                                disabled = not v
                                setRowDim(row, face, disabled)
                                lblTop.TextTransparency = disabled and 0.5 or 0
                                val.TextTransparency = disabled and 0.5 or 0
                                rail.BackgroundTransparency = disabled and 0.6 or 0
                                fill.BackgroundTransparency = disabled and 0.6 or 0
                                handle.BackgroundTransparency = disabled and 0.55 or 0
                        end
                        return finishElement("Slider", sld, cfg, row, { track }, nil, setEnabled)
                end

                return addSlider
        end
end)()

Components.Dropdown = (function()
        return function(ctx)
                local clamp = ctx.clamp
                local toWidth = ctx.toWidth
                local New = ctx.New
                local corner = ctx.corner
                local list = ctx.list
                local tween = ctx.tween
                local measureText = ctx.measureText
                local theme = ctx.theme
                local GEO = ctx.GEO
                local F = ctx.F
                local icon = ctx.icon
                local state = ctx.state
                local closeAllPops = ctx.closeAllPops
                local registerPop = ctx.registerPop
                local unregisterPop = ctx.unregisterPop
                local mountPop = ctx.mountPop
                local makeRow = ctx.makeRow
                local setRowDim = ctx.setRowDim
                local rowLabel = ctx.rowLabel
                local overlayBtn = ctx.overlayBtn
                local registerSearch = ctx.registerSearch
                local finishElement = ctx.finishElement

                local function addDropdown(section, cfg)
                        cfg = cfg or {}
                        local row, face = makeRow(section, GEO.RowH, toWidth(cfg.Width, nil))
                        local lbl = rowLabel(row, cfg.Text, 118)

                        local chev = icon(row, "chevron-down", 18, theme.TextFaint)
                        chev.AnchorPoint = Vector2.new(1, 0.5)
                        chev.Position = UDim2.new(1, -GEO.RowPad, 0.5, 0)

                        local val = New("TextLabel", {
                                AnchorPoint = Vector2.new(1, 0.5),
                                Position = UDim2.new(1, -GEO.RowPad - 18 - 7, 0.5, 0),
                                Size = UDim2.new(0, 60, 0, 16),
                                BackgroundTransparency = 1,
                                FontFace = F.Medium,
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
                        local pop = New("CanvasGroup", {
                                GroupTransparency = 1,
                                ClipsDescendants = true,
                                Position = UDim2.new(0, 0, 1, 6),
                                Size = UDim2.new(1, 0, 0, popH),
                                BackgroundTransparency = 1,
                                BorderSizePixel = 0,
                                Visible = false,
                                ZIndex = 25,
                                Parent = row,
                        })
                        corner(pop, 8)
                        local popFace = New("Frame", {
                                Position = UDim2.new(0, 0, 0, 0),
                                Size = UDim2.new(1, 0, 1, 0),
                                BackgroundColor3 = theme.Overlay,
                                BorderSizePixel = 0,
                                Parent = pop,
                        })
                        corner(popFace, 6)
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
                        local emptyLbl = New("TextLabel", {
                                Position = UDim2.new(0, 10, 0, 0),
                                Size = UDim2.new(1, -16, 0, GEO.OptH),
                                BackgroundTransparency = 1,
                                FontFace = F.Medium,
                                TextSize = 13,
                                TextColor3 = theme.TextFaint,
                                TextXAlignment = Enum.TextXAlignment.Left,
                                Text = "No options",
                                Visible = #options == 0,
                                Parent = listScroll,
                        })
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

                        local transition = 0
                        local function setOpen(o)
                                if dd._open == o then return end
                                dd._open = o
                                transition = transition + 1
                                local generation = transition
                                if o then
                                        closeAllPops(pop)
                                        local x, y, cappedH = mountPop(row, pop, popH, row.AbsoluteSize.X)
                                        listScroll.CanvasPosition = Vector2.new(0, 0)
                                        local offset = y < row.AbsolutePosition.Y and 7 or -7
                                        if not pop.Visible then
                                                pop.GroupTransparency = 1
                                                pop.Position = UDim2.new(0, x, 0, y + offset)
                                        end
                                        pop.Visible = true
                                        tween(pop, 0.22, { Position = UDim2.new(0, x, 0, y) }, Enum.EasingStyle.Quart)
                                        tween(pop, 0.20, { GroupTransparency = 0 }, Enum.EasingStyle.Quad)
                                        tween(chev, 0.20, { Rotation = 180 }, Enum.EasingStyle.Quart)
                                        registerPop(row, pop, setOpen, cappedH)
                                else
                                        local pos = pop.Position
                                        local offset = pos.Y.Offset < row.AbsolutePosition.Y and 6 or -6
                                        tween(pop, 0.15, { Position = UDim2.new(0, pos.X.Offset, 0, pos.Y.Offset + offset) }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
                                        tween(pop, 0.15, { GroupTransparency = 1 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
                                        task.delay(0.16, function()
                                                if generation == transition and not dd._open and pop.Parent then pop.Visible = false end
                                        end)
                                        tween(chev, 0.17, { Rotation = 0 }, Enum.EasingStyle.Quart)
                                        unregisterPop(pop)
                                end
                        end

                        local function buildOption(i, opt)
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
                                        FontFace = F.Medium,
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
                                        if not dd._open then return end
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
                        end
                        local function syncAll()
                                if multi then syncValue() end
                                refreshChecks()
                                val.Text = displayText()
                                fit()
                        end
                        for i, opt in ipairs(options) do
                                buildOption(i, opt)
                        end
                        syncAll()

                        local disabled = false
                        local btn = overlayBtn(row)
                        btn.Activated:Connect(function()
                                if disabled then return end
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
                        function dd:SetOptions(opts)
                                if type(opts) ~= "table" then return end
                                setOpen(false)
                                options = {}
                                origOf, optTexts = {}, {}
                                for i, opt in ipairs(opts) do
                                        options[i] = opt
                                        local t = tostring(opt)
                                        optTexts[i] = t
                                        if origOf[t] == nil then origOf[t] = opt end
                                end
                                if multi then
                                        local keep = {}
                                        for _, t in ipairs(optTexts) do
                                                if sel[t] then keep[t] = true end
                                        end
                                        sel = keep
                                else
                                        local cur = tostring(dd.Value)
                                        local found = false
                                        for _, t in ipairs(optTexts) do
                                                if t == cur then found = true break end
                                        end
                                        if not found then dd.Value = options[1] ~= nil and options[1] or "" end
                                end
                                for _, b in ipairs(optBtns) do
                                        b._btn:Destroy()
                                end
                                optBtns = {}
                                for i, opt in ipairs(options) do
                                        buildOption(i, opt)
                                end
                                popH = 10 + math.max(#options, 1) * GEO.OptH
                                pop.Size = UDim2.new(1, 0, 0, popH)
                                emptyLbl.Visible = #options == 0
                                syncAll()
                                for _, e in ipairs(state.searchRows) do
                                        if e.frame == row then
                                                local st = tostring(cfg.Text or "")
                                                if #optTexts > 0 then st = st .. " " .. table.concat(optTexts, " ") end
                                                e.text = st
                                        end
                                end
                        end
                        local function setEnabled(v)
                                disabled = not v
                                setRowDim(row, face, disabled)
                                if disabled and dd._open then setOpen(false) end
                                lbl.TextTransparency = disabled and 0.5 or 0
                                val.TextTransparency = disabled and 0.5 or 0
                                chev.ImageTransparency = disabled and 0.5 or 0
                        end
                        return finishElement("Dropdown", dd, cfg, row, { btn }, pop, setEnabled)
                end

                return addDropdown
        end
end)()

Components.Keybind = (function()
        return function(ctx)
                local TweenService = ctx.TweenService
                local rnd = ctx.rnd
                local toWidth = ctx.toWidth
                local New = ctx.New
                local corner = ctx.corner
                local tween = ctx.tween
                local killTween = ctx.killTween
                local measureText = ctx.measureText
                local MOUSE_NAMES = ctx.MOUSE_NAMES
                local theme = ctx.theme
                local GEO = ctx.GEO
                local F = ctx.F
                local state = ctx.state
                local makeRow = ctx.makeRow
                local setRowDim = ctx.setRowDim
                local rowLabel = ctx.rowLabel
                local registerSearch = ctx.registerSearch
                local finishElement = ctx.finishElement

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
                        local row, face = makeRow(section, GEO.RowH, toWidth(cfg.Width, nil))
                        local lbl = rowLabel(row, cfg.Text, GEO.ChipMinW + 22)

                        local chip = New("TextButton", {
                                AnchorPoint = Vector2.new(1, 0.5),
                                Position = UDim2.new(1, -GEO.RowPad, 0.5, 0),
                                Size = UDim2.new(0, GEO.ChipMinW, 0, GEO.ChipH),
                                BackgroundTransparency = 1,
                                BorderSizePixel = 0,
                                Text = "",
                                AutoButtonColor = false,
                                ZIndex = 5,
                                Parent = row,
                        })
                        corner(chip, 4)
                        local chipFace = New("Frame", {
                                Position = UDim2.new(0, 0, 0, 0),
                                Size = UDim2.new(1, 0, 1, 0),
                                BackgroundColor3 = theme.Chip,
                                BorderSizePixel = 0,
                                ZIndex = 1,
                                Parent = chip,
                        })
                        corner(chipFace, 4)
                        local txt = New("TextLabel", {
                                Position = UDim2.new(0, 8, 0, 0),
                                Size = UDim2.new(1, -16, 1, 0),
                                BackgroundTransparency = 1,
                                FontFace = F.Mono,
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
                                killTween(chipFace, "BackgroundColor3")
                                killTween(chipFace, "BackgroundTransparency")
                                killTween(txt, "TextColor3")
                                chipFace.BackgroundTransparency = 0
                                chipFace.BackgroundColor3 = theme.Chip
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
                                tween(chipFace, 0.12, { BackgroundColor3 = theme.RowHover })
                                tween(txt, 0.12, { TextColor3 = theme.Accent })
                                pulseTween = TweenService:Create(chipFace, TweenInfo.new(1, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1, true), { BackgroundTransparency = 0.6 })
                                pulseTween:Play()
                        end

                        local disabled = false
                        chip.InputBegan:Connect(function(input)
                                if disabled then return end
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
                        local function setEnabled(v)
                                disabled = not v
                                setRowDim(row, face, disabled)
                                if disabled then
                                        if state.listening == kb then cancelListen() end
                                        kb.Callback = nil
                                        kb.Active = false
                                        chipFace.BackgroundTransparency = 0.45
                                else
                                        kb.Callback = cfg.Callback
                                        chipFace.BackgroundTransparency = 0
                                end
                                lbl.TextTransparency = disabled and 0.5 or 0
                                txt.TextTransparency = disabled and 0.5 or 0
                        end
                        return finishElement("Keybind", kb, cfg, row, { chip }, nil, setEnabled)
                end

                return addKeybind
        end
end)()

Components.ColorPicker = (function()
        return function(ctx)
                local UserInputService = ctx.UserInputService
                local rnd = ctx.rnd
                local clamp = ctx.clamp
                local toWidth = ctx.toWidth
                local New = ctx.New
                local corner = ctx.corner
                local padding = ctx.padding
                local tween = ctx.tween
                local measureText = ctx.measureText
                local colorToHex = ctx.colorToHex
                local hexToColor = ctx.hexToColor
                local theme = ctx.theme
                local GEO = ctx.GEO
                local F = ctx.F
                local connect = ctx.connect
                local closeAllPops = ctx.closeAllPops
                local registerPop = ctx.registerPop
                local unregisterPop = ctx.unregisterPop
                local mountPop = ctx.mountPop
                local makeRow = ctx.makeRow
                local setRowDim = ctx.setRowDim
                local rowLabel = ctx.rowLabel
                local registerSearch = ctx.registerSearch
                local finishElement = ctx.finishElement

                local function addColorPicker(section, cfg)
                        cfg = cfg or {}
                        local row, face = makeRow(section, GEO.RowH, toWidth(cfg.Width, nil))
                        local hexW = rnd(math.max(44, measureText(colorToHex(theme.Accent), 12, F.Mono)))
                        local lbl = rowLabel(row, cfg.Text, hexW + 9 + GEO.Swatch + 22)

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
                                FontFace = F.Mono,
                                TextSize = 12,
                                TextColor3 = theme.TextMuted,
                                TextXAlignment = Enum.TextXAlignment.Left,
                                TextTruncate = Enum.TextTruncate.AtEnd,
                                Text = colorToHex(theme.Accent),
                                ZIndex = 6,
                                Parent = trigger,
                        })
                        local swatch = New("Frame", {
                                AnchorPoint = Vector2.new(1, 0.5),
                                Position = UDim2.new(1, 0, 0.5, 0),
                                Size = UDim2.new(0, GEO.Swatch, 0, GEO.Swatch),
                                BackgroundTransparency = 1,
                                BorderSizePixel = 0,
                                ZIndex = 6,
                                Parent = trigger,
                        })
                        corner(swatch, 6)
                        local swatchFace = New("Frame", {
                                Position = UDim2.new(0, 0, 0, 0),
                                Size = UDim2.new(1, 0, 1, 0),
                                BackgroundColor3 = theme.Accent,
                                BorderSizePixel = 0,
                                ZIndex = 1,
                                Parent = swatch,
                        })
                        corner(swatchFace, 6)

                        local popH = 22 + GEO.SVH + 10 + GEO.Swatch
                        local pop = New("CanvasGroup", {
                                GroupTransparency = 1,
                                AnchorPoint = Vector2.new(1, 0),
                                Position = UDim2.new(1, -GEO.RowPad, 0, GEO.RowH + 6),
                                Size = UDim2.new(0, GEO.PopW, 0, popH),
                                BackgroundTransparency = 1,
                                BorderSizePixel = 0,
                                Visible = false,
                                ZIndex = 25,
                                Parent = row,
                        })
                        corner(pop, 6)
                        local popFace = New("Frame", {
                                Position = UDim2.new(0, 0, 0, 0),
                                Size = UDim2.new(1, 0, 1, 0),
                                BackgroundColor3 = theme.Overlay,
                                BorderSizePixel = 0,
                                Parent = pop,
                        })
                        corner(popFace, 6)
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
                                BackgroundTransparency = 1,
                                BorderSizePixel = 0,
                                Parent = popFace,
                        })
                        corner(preview, 6)
                        local previewFace = New("Frame", {
                                Position = UDim2.new(0, 0, 0, 0),
                                Size = UDim2.new(1, 0, 1, 0),
                                BackgroundColor3 = theme.Accent,
                                BorderSizePixel = 0,
                                Parent = preview,
                        })
                        corner(previewFace, 6)
                        New("TextLabel", {
                                Position = UDim2.new(0, GEO.Swatch + 10, 0, GEO.SVH + 10),
                                Size = UDim2.new(0, 0, 0, GEO.Swatch),
                                BackgroundTransparency = 1,
                                FontFace = F.Mono,
                                TextSize = 11,
                                TextColor3 = theme.TextFaint,
                                TextXAlignment = Enum.TextXAlignment.Left,
                                Text = "HEX",
                                Parent = popFace,
                        })
                        local hexVal = New("TextLabel", {
                                AnchorPoint = Vector2.new(1, 0),
                                Position = UDim2.new(1, 0, 0, GEO.SVH + 10),
                                Size = UDim2.new(0, rnd(math.max(52, measureText(colorToHex(theme.Accent), 12, F.Mono))), 0, GEO.Swatch),
                                BackgroundTransparency = 1,
                                FontFace = F.Mono,
                                TextSize = 12,
                                TextColor3 = theme.TextMuted,
                                TextXAlignment = Enum.TextXAlignment.Right,
                                TextTruncate = Enum.TextTruncate.AtEnd,
                                Text = colorToHex(theme.Accent),
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
                        local open = false
                        local function bindPad(el, apply)
                                el.InputBegan:Connect(function(input)
                                        if not open then return end
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

                        local transition = 0
                        local direction = -1
                        local function setOpen(o)
                                if open == o then return end
                                open = o
                                transition = transition + 1
                                local generation = transition
                                if o then
                                        closeAllPops(pop)
                                        local x, y, cappedH = mountPop(row, pop, popH, GEO.PopW, true)
                                        direction = y < row.AbsolutePosition.Y and 1 or -1
                                        if not pop.Visible then
                                                pop.GroupTransparency = 1
                                                pop.Position = UDim2.new(0, x, 0, y + direction * 6)
                                        end
                                        pop.Visible = true
                                        tween(pop, 0.22, { Position = UDim2.new(0, x, 0, y) }, Enum.EasingStyle.Quart)
                                        tween(pop, 0.18, { GroupTransparency = 0 }, Enum.EasingStyle.Sine)
                                        registerPop(row, pop, setOpen, cappedH, GEO.PopW, true)
                                else
                                        active = nil
                                        unregisterPop(pop)
                                        local pos = pop.Position
                                        tween(pop, 0.15, { Position = UDim2.new(0, pos.X.Offset, 0, pos.Y.Offset + direction * 4) }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
                                        local exit = tween(pop, 0.15, { GroupTransparency = 1 }, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
                                        exit.Completed:Once(function(playback)
                                                if playback == Enum.PlaybackState.Completed and generation == transition and not open and pop.Parent then
                                                        pop.Visible = false
                                                end
                                        end)
                                end
                        end
                        local disabled = false
                        trigger.Activated:Connect(function()
                                if disabled then return end
                                setOpen(not open)
                        end)
                        registerSearch(row, cfg.Text, section)
                        render(false)

                        function cp:Set(hex, fire)
                                local c = hexToColor(hex)
                                h, s, v = Color3.toHSV(c)
                                render(fire and true or false)
                        end
                        local function setEnabled(v)
                                disabled = not v
                                setRowDim(row, face, disabled)
                                if disabled and open then setOpen(false) end
                                lbl.TextTransparency = disabled and 0.5 or 0
                                hexLbl.TextTransparency = disabled and 0.5 or 0
                                swatchFace.BackgroundTransparency = disabled and 0.45 or 0
                        end
                        return finishElement("ColorPicker", cp, cfg, row, { trigger }, pop, setEnabled)
                end

                return addColorPicker
        end
end)()

Components.Input = (function()
        return function(ctx)
                local toWidth = ctx.toWidth
                local New = ctx.New
                local corner = ctx.corner
                local padding = ctx.padding
                local tween = ctx.tween
                local theme = ctx.theme
                local GEO = ctx.GEO
                local F = ctx.F
                local makeRow = ctx.makeRow
                local setRowDim = ctx.setRowDim
                local rowLabel = ctx.rowLabel
                local registerSearch = ctx.registerSearch
                local finishElement = ctx.finishElement

                local function addInput(section, cfg)
                        cfg = cfg or {}
                        local row, face = makeRow(section, GEO.RowH, toWidth(cfg.Width, nil))
                        local lbl = rowLabel(row, cfg.Text, 202)

                        local field = New("Frame", {
                                AnchorPoint = Vector2.new(1, 0.5),
                                Position = UDim2.new(1, -GEO.RowPad, 0.5, 0),
                                Size = UDim2.new(0, GEO.FieldW, 0, GEO.FieldH),
                                BackgroundTransparency = 1,
                                BorderSizePixel = 0,
                                ZIndex = 5,
                                Parent = row,
                        })
                        corner(field, 6)
                        local box = New("TextBox", {
                                Position = UDim2.new(0, 0, 0, 0),
                                Size = UDim2.new(1, 0, 1, 0),
                                BackgroundColor3 = theme.Surface,
                                BorderSizePixel = 0,
                                Text = tostring(cfg.Value or ""),
                                PlaceholderText = tostring(cfg.Placeholder or ""),
                                PlaceholderColor3 = theme.TextFaint,
                                FontFace = F.Regular,
                                TextSize = 13,
                                TextColor3 = theme.Text,
                                TextXAlignment = Enum.TextXAlignment.Left,
                                ClearTextOnFocus = false,
                                ClipsDescendants = true,
                                ZIndex = 2,
                                Parent = field,
                        })
                        corner(box, 6)
                        padding(box, 0, 10, 0, 10)

                        local debounce = tonumber(cfg.Debounce)
                        if debounce ~= nil and debounce <= 0 then debounce = nil end
                        local dbGen = 0
                        box.Focused:Connect(function()
                                tween(box, 0.12, { BackgroundColor3 = theme.RowHover })
                        end)
                        box.FocusLost:Connect(function(enter)
                                tween(box, 0.12, { BackgroundColor3 = theme.Surface })
                                dbGen = dbGen + 1
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
                                if cfg.Live and cfg.Callback then
                                        if debounce then
                                                dbGen = dbGen + 1
                                                local g = dbGen
                                                task.delay(debounce, function()
                                                        if g == dbGen and cfg.Callback then cfg.Callback(box.Text, false) end
                                                end)
                                        else
                                                cfg.Callback(box.Text, false)
                                        end
                                end
                        end)
                        local function setEnabled(v)
                                local d = not v
                                setRowDim(row, face, d)
                                lbl.TextTransparency = d and 0.5 or 0
                                box.TextEditable = not d
                                box.Active = not d
                                box.TextTransparency = d and 0.5 or 0
                                box.BackgroundTransparency = d and 0.45 or 0
                                if d then
                                        box:ReleaseFocus()
                                end
                        end
                        return finishElement("Input", inp, cfg, row, { field, box }, nil, setEnabled)
                end

                return addInput
        end
end)()

Components.Button = (function()
        return function(ctx)
                local rnd = ctx.rnd
                local toWidth = ctx.toWidth
                local New = ctx.New
                local corner = ctx.corner
                local tween = ctx.tween
                local killTween = ctx.killTween
                local measureText = ctx.measureText
                local theme = ctx.theme
                local GEO = ctx.GEO
                local F = ctx.F
                local registerSearch = ctx.registerSearch
                local finishElement = ctx.finishElement

                local function addButton(section, cfg)
                        cfg = cfg or {}
                        local primary = cfg.Primary and true or false
                        local btext = tostring(cfg.Text or "Button")
                        local wUD = toWidth(cfg.Width, UDim.new(1, 0))
                        if type(cfg.Width) == "string" and string.find(string.lower(cfg.Width), "auto", 1, true) then
                                wUD = UDim.new(0, math.max(46, rnd(measureText(btext, 13, F.Semibold)) + 28))
                        end
                        local shell = New("Frame", {
                                Size = UDim2.new(wUD.Scale, wUD.Offset, 0, GEO.RowH),
                                BackgroundTransparency = 1,
                                BorderSizePixel = 0,
                                ZIndex = 1,
                                Parent = section.Rows,
                        })
                        corner(shell, 6)
                        local btn = New("TextButton", {
                                Position = UDim2.new(0, 0, 0, 0),
                                Size = UDim2.new(1, 0, 1, 0),
                                BackgroundColor3 = primary and theme.Accent or theme.Overlay,
                                BackgroundTransparency = 0,
                                Text = btext,
                                FontFace = F.Semibold,
                                TextSize = 13,
                                TextColor3 = primary and Color3.new(1, 1, 1) or theme.TextMuted,
                                TextTruncate = Enum.TextTruncate.AtEnd,
                                AutoButtonColor = false,
                                BorderSizePixel = 0,
                                ZIndex = 2,
                                Parent = shell,
                        })
                        corner(btn, 6)
                        local disabled = false
                        if primary then
                                btn.MouseEnter:Connect(function()
                                        if disabled then return end
                                        tween(btn, 0.13, { BackgroundColor3 = theme.AccentHover })
                                end)
                                btn.MouseLeave:Connect(function()
                                        tween(btn, 0.13, { BackgroundColor3 = theme.Accent })
                                end)
                        else
                                btn.MouseEnter:Connect(function()
                                        if disabled then return end
                                        tween(btn, 0.13, { BackgroundColor3 = theme.RowHover })
                                        tween(btn, 0.13, { TextColor3 = theme.Text })
                                end)
                                btn.MouseLeave:Connect(function()
                                        tween(btn, 0.13, { BackgroundColor3 = theme.Overlay })
                                        tween(btn, 0.13, { TextColor3 = theme.TextMuted })
                                end)
                        end
                        btn.Activated:Connect(function()
                                if disabled then return end
                                if cfg.Callback then cfg.Callback() end
                        end)
                        registerSearch(shell, cfg.Text, section)
                        local b = { Button = btn }
                        function b:Set(text)
                                btn.Text = tostring(text)
                        end
                        local function setEnabled(v)
                                local d = not v
                                disabled = d
                                btn.TextTransparency = d and 0.5 or 0
                                killTween(btn, "BackgroundTransparency")
                                killTween(btn, "TextColor3")
                                btn.TextColor3 = primary and Color3.new(1, 1, 1) or theme.TextMuted
                                killTween(btn, "BackgroundColor3")
                                btn.BackgroundColor3 = primary and theme.Accent or theme.Overlay
                                btn.BackgroundTransparency = d and 0.45 or 0
                        end
                        return finishElement("Button", b, cfg, shell, { btn }, nil, setEnabled)
                end

                return addButton
        end
end)()

Components.Paragraph = (function()
        return function(ctx)
                local New = ctx.New
                local padding = ctx.padding
                local theme = ctx.theme
                local F = ctx.F
                local registerSearch = ctx.registerSearch
                local finishElement = ctx.finishElement

                local function addParagraph(section, cfg)
                        cfg = cfg or {}
                        local lbl = New("TextLabel", {
                                Size = UDim2.new(1, 0, 0, 0),
                                AutomaticSize = Enum.AutomaticSize.Y,
                                BackgroundTransparency = 1,
                                FontFace = F.Regular,
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
                        local function setEnabled(v)
                                lbl.TextTransparency = v and 0 or 0.5
                        end
                        return finishElement("Paragraph", p, cfg, lbl, { lbl }, nil, setEnabled)
                end

                return addParagraph
        end
end)()

Components.Image = (function()
        return function(ctx)
                local rnd = ctx.rnd
                local clamp = ctx.clamp
                local toWidth = ctx.toWidth
                local New = ctx.New
                local corner = ctx.corner
                local list = ctx.list
                local tween = ctx.tween
                local theme = ctx.theme
                local GEO = ctx.GEO
                local F = ctx.F
                local makeRow = ctx.makeRow
                local setRowDim = ctx.setRowDim
                local overlayBtn = ctx.overlayBtn
                local registerSearch = ctx.registerSearch
                local finishElement = ctx.finishElement

                local function toAsset(v)
                        local t = type(v)
                        if t == "number" then return "rbxassetid://" .. string.format("%.0f", v) end
                        if t == "string" then
                                local s = string.match(v, "^%s*(.-)%s*$")
                                if s == "" then return nil end
                                if string.find(s, "://", 1, true) then return s end
                                if string.match(s, "^%d+$") then return "rbxassetid://" .. s end
                                return s
                        end
                        return nil
                end

                local function toScaleType(v)
                        local s = string.lower(tostring(v or ""))
                        if string.find(s, "fit", 1, true) then return Enum.ScaleType.Fit end
                        if string.find(s, "stretch", 1, true) then return Enum.ScaleType.Stretch end
                        return Enum.ScaleType.Crop
                end

                local function addImage(section, cfg)
                        cfg = cfg or {}
                        local raw = cfg.Image ~= nil and cfg.Image or cfg.Text
                        local src = toAsset(raw)
                        local h = clamp(rnd(tonumber(cfg.Height) or GEO.ImageH), GEO.ImageMinH, GEO.ImageMaxH)
                        local st = toScaleType(cfg.ScaleType)
                        local r = clamp(rnd(tonumber(cfg.CornerRadius) or 7), 0, 8)
                        local side = (cfg.Title ~= nil) or (cfg.Subtitle ~= nil) or (cfg.Meta ~= nil)
                        local row, face = makeRow(section, h, toWidth(not side and cfg.Width, nil))
                        local artW = h - 2
                        local img = New("ImageLabel", {
                                Size = side and UDim2.new(0, artW, 1, 0) or UDim2.new(1, 0, 1, 0),
                                BackgroundTransparency = 1,
                                Image = src or "",
                                ScaleType = st,
                                BorderSizePixel = 0,
                                Parent = face,
                        })
                        corner(img, r)
                        local titleLbl, subLbl, metaLbl
                        if side then
                                local pad = 10
                                local txt = New("Frame", {
                                        Position = UDim2.new(0, artW + pad, 0, 0),
                                        Size = UDim2.new(1, -(artW + pad), 1, 0),
                                        BackgroundTransparency = 1,
                                        BorderSizePixel = 0,
                                        Parent = face,
                                })
                                local tl = list(txt, 3)
                                tl.VerticalAlignment = Enum.VerticalAlignment.Center
                                local order = 0
                                local function addLine(text, size, font, color, wrap)
                                        order = order + 1
                                        local props = {
                                                Size = UDim2.new(1, 0, 0, wrap and 0 or size + 4),
                                                BackgroundTransparency = 1,
                                                FontFace = font,
                                                TextSize = size,
                                                TextColor3 = color,
                                                TextXAlignment = Enum.TextXAlignment.Left,
                                                TextYAlignment = Enum.TextYAlignment.Center,
                                                LayoutOrder = order,
                                                Text = tostring(text or ""),
                                                BorderSizePixel = 0,
                                                Parent = txt,
                                        }
                                        if wrap then
                                                props.AutomaticSize = Enum.AutomaticSize.Y
                                                props.TextWrapped = true
                                        else
                                                props.TextTruncate = Enum.TextTruncate.AtEnd
                                        end
                                        return New("TextLabel", props)
                                end
                                if cfg.Title ~= nil then
                                        titleLbl = addLine(cfg.Title, 14, F.Semibold, theme.Text, true)
                                end
                                if cfg.Subtitle ~= nil then
                                        subLbl = addLine(cfg.Subtitle, 12, F.Regular, theme.TextMuted, true)
                                end
                                if cfg.Meta ~= nil then
                                        metaLbl = addLine(cfg.Meta, 11, F.Regular, theme.TextFaint, false)
                                end
                        end
                        local ov = nil
                        local imgDisabled = false
                        if cfg.Callback then
                                ov = overlayBtn(row)
                                ov.Activated:Connect(function()
                                        if imgDisabled then return end
                                        if cfg.Callback then cfg.Callback() end
                                end)
                                ov.MouseEnter:Connect(function()
                                        if imgDisabled then return end
                                        tween(img, 0.13, { ImageTransparency = 0.1 })
                                end)
                                ov.MouseLeave:Connect(function()
                                        tween(img, 0.13, { ImageTransparency = imgDisabled and 0.5 or 0 })
                                end)
                        end
                        registerSearch(row, raw, section)
                        local o = { Image = img }
                        function o:SetImage(v)
                                img.Image = toAsset(v) or ""
                        end
                        o.Set = o.SetImage
                        function o:SetTitle(v)
                                if titleLbl then titleLbl.Text = tostring(v or "") end
                        end
                        function o:SetSubtitle(v)
                                if subLbl then subLbl.Text = tostring(v or "") end
                        end
                        function o:SetMeta(v)
                                if metaLbl then metaLbl.Text = tostring(v or "") end
                        end
                        local function setEnabled(v)
                                imgDisabled = not v
                                setRowDim(row, face, imgDisabled)
                                img.ImageTransparency = imgDisabled and 0.5 or 0
                                if titleLbl then titleLbl.TextTransparency = imgDisabled and 0.5 or 0 end
                                if subLbl then subLbl.TextTransparency = imgDisabled and 0.5 or 0 end
                                if metaLbl then metaLbl.TextTransparency = imgDisabled and 0.5 or 0 end
                        end
                        return finishElement("Image", o, cfg, row, ov and { ov } or { img }, nil, setEnabled)
                end

                return addImage
        end
end)()

Components.List = (function()
        return function(ctx)
                local rnd = ctx.rnd
                local clamp = ctx.clamp
                local New = ctx.New
                local corner = ctx.corner
                local tween = ctx.tween
                local measureText = ctx.measureText
                local nextOrder = ctx.nextOrder
                local theme = ctx.theme
                local GEO = ctx.GEO
                local F = ctx.F
                local icon = ctx.icon
                local makeRow = ctx.makeRow
                local setRowDim = ctx.setRowDim
                local registerSearch = ctx.registerSearch
                local finishElement = ctx.finishElement

                local function addList(section, cfg)
                        cfg = cfg or {}
                        if cfg.Callback == nil and cfg.SelectionChanged ~= nil then
                                cfg.Callback = cfg.SelectionChanged
                        end
                        local baseH = clamp(rnd(tonumber(cfg.Height) or GEO.ListH), GEO.ListMinH, GEO.ListMaxH)
                        local maxH = math.max(clamp(rnd(tonumber(cfg.MaxHeight) or GEO.ListMaxH), GEO.ListMinH, 2000), baseH)
                        local row, face = makeRow(section, baseH)
                        local lbl = nil
                        if cfg.Text ~= nil and tostring(cfg.Text) ~= "" then
                                lbl = New("TextLabel", {
                                        Position = UDim2.new(0, GEO.RowPad, 0, 8),
                                        Size = UDim2.new(1, -GEO.RowPad * 2, 0, 14),
                                        BackgroundTransparency = 1,
                                        FontFace = F.Semibold,
                                        TextSize = 11,
                                        TextColor3 = theme.TextFaint,
                                        TextXAlignment = Enum.TextXAlignment.Left,
                                        TextTruncate = Enum.TextTruncate.AtEnd,
                                        Text = string.upper(tostring(cfg.Text)),
                                        ZIndex = 5,
                                        Parent = row,
                                })
                        end
                        local scroll = New("ScrollingFrame", {
                                Position = UDim2.new(0, 5, 0, lbl and 27 or 5),
                                Size = UDim2.new(1, -10, 1, lbl and -32 or -10),
                                BackgroundTransparency = 1,
                                BorderSizePixel = 0,
                                ScrollBarThickness = 4,
                                ScrollBarImageColor3 = theme.LineStrong,
                                ScrollingDirection = Enum.ScrollingDirection.Y,
                                CanvasSize = UDim2.new(0, 0, 0, 0),
                                AutomaticCanvasSize = Enum.AutomaticSize.Y,
                                ZIndex = 2,
                                Parent = face,
                        })
                        New("UIListLayout", {
                                Padding = UDim.new(0, 2),
                                SortOrder = Enum.SortOrder.LayoutOrder,
                                FillDirection = Enum.FillDirection.Vertical,
                                Parent = scroll,
                        })
                        local emptyLbl = New("TextLabel", {
                                Size = UDim2.new(1, -16, 0, GEO.OptH),
                                BackgroundTransparency = 1,
                                FontFace = F.Medium,
                                TextSize = 13,
                                TextColor3 = theme.TextFaint,
                                TextXAlignment = Enum.TextXAlignment.Left,
                                Text = "No items",
                                Parent = scroll,
                        })
                        local items = {}
                        local sumH = 0
                        local nextOrder = 1
                        local selectedRec = nil
                        local lstDisabled = false
                        local lst = { Selected = nil }

                        local function fitHeight()
                                local n = #items
                                local total = 10 + sumH + (n > 1 and (n - 1) * 2 or 0)
                                row.Size = UDim2.new(1, 0, 0, clamp(total, baseH, maxH))
                                emptyLbl.Visible = n == 0
                        end
                        local function indexOf(rec)
                                for i, r in ipairs(items) do
                                        if r == rec then return i end
                                end
                                return nil
                        end
                        local function applySel(rec, on)
                                rec._sel = on
                                rec.frame.BackgroundColor3 = theme.Accent
                                rec.frame.BackgroundTransparency = on and 0.85 or 1
                                rec.primary.TextColor3 = on and theme.Text or theme.TextMuted
                        end
                        local function selectRec(rec, fire)
                                if selectedRec and selectedRec ~= rec then
                                        applySel(selectedRec, false)
                                end
                                selectedRec = rec
                                if rec then applySel(rec, true) end
                                local i = rec ~= nil and indexOf(rec) or nil
                                lst.Selected = i
                                if fire and cfg.Callback then
                                        cfg.Callback(rec ~= nil and rec.item or nil, i)
                                end
                        end
                        local function buildItem(item)
                                if type(item) ~= "table" then item = { Text = item } end
                                local primary = tostring(item.Text or "")
                                local secondary = item.Secondary ~= nil and tostring(item.Secondary) or nil
                                local trailing = item.Trailing ~= nil and tostring(item.Trailing) or nil
                                local ih = secondary and (GEO.OptH + 10) or GEO.OptH
                                local ob = New("TextButton", {
                                        Size = UDim2.new(1, -6, 0, ih),
                                        BackgroundTransparency = 1,
                                        BackgroundColor3 = theme.Accent,
                                        Text = "",
                                        AutoButtonColor = false,
                                        LayoutOrder = nextOrder,
                                        Parent = scroll,
                                })
                                nextOrder = nextOrder + 1
                                corner(ob, 6)
                                local ic = nil
                                if item.Icon ~= nil then
                                        ic = icon(ob, tostring(item.Icon), 16, theme.TextMuted)
                                        if ic then
                                                ic.AnchorPoint = Vector2.new(0, 0.5)
                                                ic.Position = UDim2.new(0, 12, 0.5, 0)
                                                ic.ZIndex = 2
                                        end
                                end
                                local tx0 = ic ~= nil and 36 or 12
                                local trailRes = trailing and (rnd(measureText(trailing, 11, F.Regular)) + 14) or 0
                                local prim
                                if secondary then
                                        prim = New("TextLabel", {
                                                Position = UDim2.new(0, tx0, 0, 5),
                                                Size = UDim2.new(1, -(tx0 + 12 + trailRes), 0, 16),
                                                BackgroundTransparency = 1,
                                                FontFace = F.Medium,
                                                TextSize = 13,
                                                TextColor3 = theme.TextMuted,
                                                TextXAlignment = Enum.TextXAlignment.Left,
                                                TextTruncate = Enum.TextTruncate.AtEnd,
                                                Text = primary,
                                                ZIndex = 2,
                                                Parent = ob,
                                        })
                                        New("TextLabel", {
                                                Position = UDim2.new(0, tx0, 0, 21),
                                                Size = UDim2.new(1, -(tx0 + 12 + trailRes), 0, 14),
                                                BackgroundTransparency = 1,
                                                FontFace = F.Regular,
                                                TextSize = 11,
                                                TextColor3 = theme.TextFaint,
                                                TextXAlignment = Enum.TextXAlignment.Left,
                                                TextTruncate = Enum.TextTruncate.AtEnd,
                                                Text = secondary,
                                                ZIndex = 2,
                                                Parent = ob,
                                        })
                                else
                                        prim = New("TextLabel", {
                                                AnchorPoint = Vector2.new(0, 0.5),
                                                Position = UDim2.new(0, tx0, 0.5, 0),
                                                Size = UDim2.new(1, -(tx0 + 12 + trailRes), 0, 16),
                                                BackgroundTransparency = 1,
                                                FontFace = F.Medium,
                                                TextSize = 13,
                                                TextColor3 = theme.TextMuted,
                                                TextXAlignment = Enum.TextXAlignment.Left,
                                                TextTruncate = Enum.TextTruncate.AtEnd,
                                                Text = primary,
                                                ZIndex = 2,
                                                Parent = ob,
                                        })
                                end
                                if trailing then
                                        New("TextLabel", {
                                                AnchorPoint = Vector2.new(1, 0.5),
                                                Position = UDim2.new(1, -10, 0.5, 0),
                                                Size = UDim2.new(0, rnd(measureText(trailing, 11, F.Regular)) + 4, 0, 14),
                                                BackgroundTransparency = 1,
                                                FontFace = F.Regular,
                                                TextSize = 11,
                                                TextColor3 = theme.TextFaint,
                                                TextXAlignment = Enum.TextXAlignment.Right,
                                                TextTruncate = Enum.TextTruncate.AtEnd,
                                                Text = trailing,
                                                ZIndex = 2,
                                                Parent = ob,
                                        })
                                end
                                local rec
                                ob.MouseEnter:Connect(function()
                                        if lstDisabled then return end
                                        if not rec._sel then
                                                tween(ob, 0.1, { BackgroundTransparency = 0.93 })
                                        end
                                        tween(prim, 0.1, { TextColor3 = theme.Text })
                                end)
                                ob.MouseLeave:Connect(function()
                                        tween(ob, 0.1, { BackgroundTransparency = rec._sel and 0.85 or 1 })
                                        tween(prim, 0.1, { TextColor3 = rec._sel and theme.Text or theme.TextMuted })
                                end)
                                ob.Activated:Connect(function()
                                        if lstDisabled then return end
                                        selectRec(rec, true)
                                end)
                                rec = { frame = ob, primary = prim, item = item, h = ih }
                                table.insert(items, rec)
                                sumH = sumH + ih
                                fitHeight()
                                return #items
                        end

                        function lst:Add(item)
                                return buildItem(item)
                        end
                        function lst:Remove(index)
                                if type(index) ~= "number" then return false end
                                index = math.floor(index)
                                if index < 1 or index > #items then return false end
                                local rec = items[index]
                                table.remove(items, index)
                                sumH = sumH - rec.h
                                if selectedRec == rec then
                                        selectedRec = nil
                                        lst.Selected = nil
                                end
                                rec.frame:Destroy()
                                fitHeight()
                                return true
                        end
                        function lst:Clear()
                                for _, rec in ipairs(items) do
                                        rec.frame:Destroy()
                                end
                                items = {}
                                sumH = 0
                                selectedRec = nil
                                lst.Selected = nil
                                fitHeight()
                        end
                        function lst:SetItems(t)
                                lst:Clear()
                                if type(t) == "table" then
                                        for _, item in ipairs(t) do
                                                buildItem(item)
                                        end
                                end
                        end
                        function lst:SetSelected(index, fire)
                                if index == nil then
                                        selectRec(nil, fire and true or false)
                                        return
                                end
                                if type(index) ~= "number" then return end
                                index = math.floor(index)
                                if index < 1 or index > #items then return end
                                selectRec(items[index], fire and true or false)
                        end
                        function lst:Set(v, fire)
                                lst:SetSelected(v, fire)
                        end
                        registerSearch(row, cfg.Text, section)
                        local function setEnabled(v)
                                lstDisabled = not v
                                setRowDim(row, face, lstDisabled)
                                if lbl then lbl.TextTransparency = lstDisabled and 0.5 or 0 end
                                emptyLbl.TextTransparency = lstDisabled and 0.5 or 0
                                for _, rec in ipairs(items) do
                                        rec.primary.TextTransparency = lstDisabled and 0.5 or 0
                                        rec.frame.BackgroundTransparency = rec._sel and 0.85 or 1
                                end
                        end
                        return finishElement("List", lst, cfg, row, { row }, nil, setEnabled)
                end

                return addList
        end
end)()

Components.Row = (function()
        return function(ctx)
                local rnd = ctx.rnd
                local New = ctx.New
                local normCfg = ctx.normCfg
                local GEO = ctx.GEO
                local finishElement = ctx.finishElement
                local addToggle = ctx.addToggle
                local addDropdown = ctx.addDropdown
                local addKeybind = ctx.addKeybind
                local addColorPicker = ctx.addColorPicker
                local addButton = ctx.addButton

                local function addRowContainer(section, cfg)
                        cfg = cfg or {}
                        local gap = tonumber(cfg.Gap) or GEO.GridGap
                        local container = New("Frame", {
                                Size = UDim2.new(1, 0, 0, GEO.RowH),
                                BackgroundTransparency = 1,
                                BorderSizePixel = 0,
                                Parent = section.Rows,
                        })
                        New("UIListLayout", {
                                Padding = UDim.new(0, gap),
                                SortOrder = Enum.SortOrder.LayoutOrder,
                                FillDirection = Enum.FillDirection.Horizontal,
                                Parent = container,
                        })
                        local r = {
                                Frame = container,
                                Rows = container,
                                _parent = section,
                                _isRow = true,
                                _cells = {},
                                _children = {},
                        }
                        local function addCell(el, c)
                                table.insert(r._children, el)
                                table.insert(r._cells, { frame = el._row, fixed = c and c.Width ~= nil or false })
                                local n = #r._cells
                                local share = rnd(gap * (n - 1) / n)
                                for i, cell in ipairs(r._cells) do
                                        cell.frame.LayoutOrder = i
                                        if not cell.fixed then
                                                cell.frame.Size = UDim2.new(1 / n, -share, 0, cell.frame.Size.Y.Offset)
                                        end
                                end
                        end
                        function r:Button(a, b)
                                local c = normCfg(a, b)
                                local el = addButton(self, c)
                                addCell(el, c)
                                return el
                        end
                        function r:Toggle(a, b)
                                local c = normCfg(a, b)
                                local el = addToggle(self, c)
                                addCell(el, c)
                                return el
                        end
                        function r:Dropdown(a, b)
                                local c = normCfg(a, b)
                                local el = addDropdown(self, c)
                                addCell(el, c)
                                return el
                        end
                        function r:Keybind(a, b)
                                local c = normCfg(a, b)
                                local el = addKeybind(self, c)
                                addCell(el, c)
                                return el
                        end
                        function r:ColorPicker(a, b)
                                local c = normCfg(a, b)
                                local el = addColorPicker(self, c)
                                addCell(el, c)
                                return el
                        end
                        finishElement("Row", r, cfg, container, { container })
                        local baseDestroy = r.Destroy
                        function r:Destroy()
                                for _, child in ipairs(r._children) do
                                        pcall(function()
                                                child:Destroy()
                                        end)
                                end
                                baseDestroy(self)
                        end
                        return r
                end

                return addRowContainer
        end
end)()

local Reborn = {
        Version = "0.9.8",
        NotificationsEnabled = true,
        _windows = {},
        _configs = {},
}

Reborn.Theme = Theme.Default
local Core = createCore(Theme)
local Icons = createIcons(Core)
local Notifications = createNotifications(Reborn, Core, Theme, Icons)
createWindow(Reborn, Core, Theme, Icons, Notifications, Components)

function Reborn:Unload()
        for i = #self._windows, 1, -1 do
                pcall(function() self._windows[i]:Destroy() end)
        end
        self._windows = {}
        if self._toastGui then
                pcall(function() self._toastGui:Destroy() end)
                self._toastGui = nil
                self._toastLayer = nil
        end
end

Reborn.Destroy = Reborn.Unload

return Reborn
