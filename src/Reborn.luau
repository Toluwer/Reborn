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

local createAnimation = (function()
    return function(TweenService)
        local liveTweens = setmetatable({}, { __mode = "k" })

        local function detachTween(registry, animation)
            for property, current in pairs(registry) do
                if current == animation then registry[property] = nil end
            end
        end

        local function tween(instance, duration, properties, style, direction)
            local registry = liveTweens[instance] or {}
            local conflicts = {}
            for property in pairs(properties) do
                local previous = registry[property]
                if previous then conflicts[previous] = true end
            end
            for previous in pairs(conflicts) do
                detachTween(registry, previous)
                previous:Cancel()
            end

            local animation = TweenService:Create(instance, TweenInfo.new(
                duration,
                style or Enum.EasingStyle.Quad,
                direction or Enum.EasingDirection.Out
            ), properties)

            liveTweens[instance] = registry
            for property in pairs(properties) do
                registry[property] = animation
            end

            animation.Completed:Once(function()
                detachTween(registry, animation)
                if next(registry) == nil and liveTweens[instance] == registry then
                    liveTweens[instance] = nil
                end
            end)
            animation:Play()
            return animation
        end

        local function killTween(instance, property)
            local registry = liveTweens[instance]
            if not registry then return end
            local animation = registry[property]
            if not animation then return end

            detachTween(registry, animation)
            animation:Cancel()
        end

        local function completed(animation, callback)
            if animation.PlaybackState == Enum.PlaybackState.Completed then
                callback()
                return
            end
            if animation.PlaybackState == Enum.PlaybackState.Cancelled then return end
            animation.Completed:Once(function(playback)
                if playback == Enum.PlaybackState.Completed then callback() end
            end)
        end

        return {
            Tween = tween,
            Cancel = killTween,
            Completed = completed,
        }
    end
end)()

local createCore = (function()
    return function(Theme, createAnimation)
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
            return New("UIPadding", {
                PaddingTop = UDim.new(0, t or 0),
                PaddingRight = UDim.new(0, r or 0),
                PaddingBottom = UDim.new(0, b or 0),
                PaddingLeft = UDim.new(0, l or 0),
                Parent = inst,
            })
        end

        local function list(parent, gap, sortOrder)
            return New("UIListLayout", {
                Padding = UDim.new(0, gap or 0),
                SortOrder = sortOrder or Enum.SortOrder.LayoutOrder,
                Parent = parent,
            })
        end

        local motion = createAnimation(TweenService)
        local tween = motion.Tween
        local killTween = motion.Cancel

        local textCache = {}
        local textCacheCount = 0
        local TEXT_CACHE_LIMIT = 512

        local function cacheWidth(key, width)
            if textCache[key] == nil then
                if textCacheCount >= TEXT_CACHE_LIMIT then
                    table.clear(textCache)
                    textCacheCount = 0
                end
                textCacheCount = textCacheCount + 1
            end
            textCache[key] = width
            return width
        end

        local function measureText(text, size, font)
            local key = tostring(font.Family) .. ":" .. tostring(font.Weight) .. ":" .. tostring(font.Style)
                .. ":" .. tostring(size) .. ":" .. text
            local cached = textCache[key]
            if cached ~= nil then return cached end
            if font == F.Mono then
                local ok, w = pcall(function()
                    return TextService:GetTextSize(text, size, Enum.Font.Code, Vector2.new(4096, size * 2)).X
                end)
                if ok and w then return cacheWidth(key, w) end
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
                if ok and bounds then return cacheWidth(key, bounds.X) end
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

        local function hexToColor(value)
            if typeof(value) == "Color3" then return value end
            if type(value) ~= "string" then return nil end
            local hex = value:match("^#?(%x%x%x%x%x%x)$")
            if not hex then return nil end
            return Color3.fromRGB(
                tonumber(hex:sub(1, 2), 16),
                tonumber(hex:sub(3, 4), 16),
                tonumber(hex:sub(5, 6), 16)
            )
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

        local function normCfg(a, b)
            local config
            if type(a) == "string" then
                config = { Text = a }
            elseif type(a) == "table" then
                config = table.clone(a)
            else
                config = {}
            end
            if type(b) == "function" and config.Callback == nil then
                config.Callback = b
            end
            return config
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
            completed = motion.Completed,
            measureText = measureText,
            colorToHex = colorToHex,
            hexToColor = hexToColor,
            keyDisplayName = keyDisplayName,
            fmtNum = fmtNum,
            MOUSE_NAMES = MOUSE_NAMES,
            resolveParent = resolveParent,
            randomName = randomName,
            nextOrder = nextOrder,
            protectGui = protectGui,
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
        local killTween = Core.killTween
        local completed = Core.completed
        local measureText = Core.measureText
        local resolveParent = Core.resolveParent
        local randomName = Core.randomName
        local protectGui = Core.protectGui

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
                        killTween(item.toast, "Position")
                        item.toast.Position = UDim2.new(0, 0, 0, y)
                    end
                    y = y + h + 8
                end
            end

            local function cancelExpiry(item)
                if not item.expiry then return end
                local expiry = item.expiry
                item.expiry = nil
                task.cancel(expiry)
            end

            local function dismiss(item)
                if item.closed then return end
                item.closed = true
                cancelExpiry(item)
                local index = table.find(state.items, item)
                if index then table.remove(state.items, index) end
                if not item.toast.Parent or not layer.Parent then return end
                local exit = tween(item.toast, 0.22, { Position = UDim2.new(0, GEO.ToastW + 18, 0, item.toast.Position.Y.Offset) })
                completed(exit, function()
                    if item.toast.Parent then item.toast:Destroy() end
                end)
                relayout(true)
            end

            local function notify(cfg)
                if not layer.Parent then return end
                cfg = cfg or {}
                local estimatedHeight = toastHeight(cfg)
                if not layer.Parent then return end
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
                local item = { toast = toast, closed = false, estH = estimatedHeight }
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
                    if not item.closed and layer.Parent and item.toast.Parent then relayout(true) end
                end)
                local dur = tonumber(cfg.Duration) or 3.6
                if dur > 0 and dur < 3600 then
                    item.expiry = task.delay(dur, function()
                        item.expiry = nil
                        dismiss(item)
                    end)
                end
                return item
            end

            layer.Destroying:Connect(function()
                for _, item in ipairs(state.items) do
                    item.closed = true
                    cancelExpiry(item)
                end
                table.clear(state.items)
            end)

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
                self._toastGui = New("ScreenGui", {
                    Name = randomName(),
                    ResetOnSpawn = false,
                    IgnoreGuiInset = true,
                    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
                    DisplayOrder = math.random(900001, 999999),
                })
                if not viaHidden then protectGui(self._toastGui) end
                self._toastGui.Parent = tparent
                self._toastLayer = buildToastLayer(self._toastGui, DEFAULT_THEME)
            end
            self._toastLayer.Notify(cfg)
        end

        return { Build = buildToastLayer, Normalize = normNotify }
    end
end)()

local attachConfig = (function()
    return function(Reborn, Core, Window, state, config)
        local HttpService = Core.HttpService

        local function sanitizeName(value)
            local name = tostring(value):gsub("[^%w%-_]", "-")
            return name ~= "" and name or "default"
        end

        local directory = "reborn/" .. sanitizeName(config.Title or "Reborn")

        local function pathFor(name)
            return directory .. "/" .. sanitizeName(name or "default") .. ".json"
        end

        local function canRead()
            return type(readfile) == "function" and type(isfile) == "function"
        end

        local function canWrite()
            return canRead() and type(writefile) == "function"
        end

        local function finite(value)
            return type(value) == "number" and value == value and math.abs(value) < math.huge
        end

        local function scalar(value)
            return type(value) == "string" or type(value) == "boolean" or finite(value)
        end

        local function snapshot(entry)
            local element = entry.el
            local kind = entry.kind

            if kind == "Toggle" then
                return element.Value == true
            elseif kind == "Slider" or kind == "ProgressBar" then
                if finite(element.Value) then return element.Value end
            elseif kind == "Dropdown" then
                if entry.cfg.Multi then
                    local values = {}
                    for _, value in ipairs(element.Value) do
                        if scalar(value) then table.insert(values, value) end
                    end
                    return values
                end
                if scalar(element.Value) then return element.Value end
            elseif kind == "Keybind" then
                return element.Name
            elseif kind == "ColorPicker" then
                return element.Hex
            elseif kind == "Input" then
                return element.Text
            elseif kind == "Image" then
                return element.Image.Image
            elseif kind == "List" then
                if element.Selected == nil then return false end
                return element.Selected
            end
            return nil
        end

        local function restore(entry, value)
            local element = entry.el
            local kind = entry.kind

            if kind == "Toggle" then
                if type(value) == "boolean" then element:Set(value, false) end
            elseif kind == "Slider" or kind == "ProgressBar" then
                local number = tonumber(value)
                if finite(number) then element:Set(number, false) end
            elseif kind == "Dropdown" then
                if entry.cfg.Multi then
                    if type(value) ~= "table" then return end
                    local values = {}
                    for _, option in ipairs(value) do
                        if not scalar(option) then return end
                        table.insert(values, option)
                    end
                    element:Set(values, false)
                elseif scalar(value) then
                    element:Set(value, false)
                end
            elseif kind == "Keybind" or kind == "Input" then
                if type(value) == "string" then element:Set(value) end
            elseif kind == "ColorPicker" then
                if type(value) == "string" then element:Set(value, false) end
            elseif kind == "Image" then
                if type(value) == "string" or finite(value) then element:SetImage(value) end
            elseif kind == "List" then
                if value == false then
                    element:SetSelected(nil, false)
                elseif finite(value) then
                    element:SetSelected(value, false)
                end
            end
        end

        local function flagOf(entry)
            local flag = entry.cfg.Flag
            if not entry.destroyed and type(flag) == "string" and flag ~= "" then
                return flag
            end
        end

        function Window:GetConfig()
            local values = {}
            for _, entry in ipairs(state.elements) do
                local flag = flagOf(entry)
                if flag then
                    local value = snapshot(entry)
                    if value ~= nil then values[flag] = value end
                end
            end
            return values
        end

        function Window:SetConfig(vals)
            if state.destroyed or type(vals) ~= "table" then return end
            for _, entry in ipairs(table.clone(state.elements)) do
                local flag = flagOf(entry)
                if flag and vals[flag] ~= nil then
                    pcall(restore, entry, vals[flag])
                end
            end
        end

        function Window:SaveConfig(name)
            if state.destroyed then return false end
            local ok, json = pcall(function()
                return HttpService:JSONEncode(self:GetConfig())
            end)
            if not ok or type(json) ~= "string" then return false end

            local path = pathFor(name)
            if not canWrite() then
                Reborn._configs[path] = json
                return true
            end

            local written = pcall(function()
                if type(isfolder) == "function" and type(makefolder) == "function" then
                    if not isfolder("reborn") then makefolder("reborn") end
                    if not isfolder(directory) then makefolder(directory) end
                end
                writefile(path, json)
            end)
            if written then Reborn._configs[path] = nil end
            return written
        end

        function Window:LoadConfig(name)
            if state.destroyed then return nil end
            local path = pathFor(name)
            local json = Reborn._configs[path]

            if json == nil and canRead() then
                local ok, content = pcall(function()
                    if isfile(path) then return readfile(path) end
                end)
                if not ok then return nil end
                json = content
            end
            if type(json) ~= "string" then return nil end

            local ok, values = pcall(function()
                return HttpService:JSONDecode(json)
            end)
            if not ok or type(values) ~= "table" then return nil end

            self:SetConfig(values)
            return values
        end

        function Window:DeleteConfig(name)
            local path = pathFor(name)
            local existed = Reborn._configs[path] ~= nil

            if type(isfile) == "function" then
                local checked, onDisk = pcall(isfile, path)
                if not checked then return false end
                if onDisk then
                    if type(delfile) ~= "function" then return false end
                    local deleted = pcall(delfile, path)
                    if not deleted then return false end
                    local verified, remains = pcall(isfile, path)
                    if not verified or remains then return false end
                    existed = true
                end
            end

            Reborn._configs[path] = nil
            return existed
        end

        function Window:ListConfigs()
            local names, seen = {}, {}
            local function add(name)
                if name and not seen[name] then
                    seen[name] = true
                    table.insert(names, name)
                end
            end

            if type(listfiles) == "function" then
                local ok, files = pcall(listfiles, directory)
                if ok and type(files) == "table" then
                    for _, file in ipairs(files) do
                        add(tostring(file):match("([^%/\\]+)%.json$"))
                    end
                end
            end

            local prefix = directory .. "/"
            for path in pairs(Reborn._configs) do
                if path:sub(1, #prefix) == prefix then
                    add(path:sub(#prefix + 1):match("^([^/]+)%.json$"))
                end
            end

            table.sort(names)
            return names
        end
    end
end)()

local createNavigation = (function()
    return function(context, tabsHolder, content, popovers)
        local F = context.F
        local GEO = context.GEO
        local New = context.New
        local corner = context.corner
        local padding = context.padding
        local list = context.list
        local measureText = context.measureText
        local theme = context.theme
        local state = context.state
        local icon = context.icon
        local tween = context.tween
        local killTween = context.killTween
        local completed = context.completed
        local normCfg = context.normCfg
        local addToggle = context.addToggle
        local addSlider = context.addSlider
        local addProgressBar = context.addProgressBar
        local addDropdown = context.addDropdown
        local addKeybind = context.addKeybind
        local addColorPicker = context.addColorPicker
        local addInput = context.addInput
        local addButton = context.addButton
        local addParagraph = context.addParagraph
        local addImage = context.addImage
        local addList = context.addList
        local addRowContainer = context.addRowContainer
        local closeAllPops = popovers.CloseAll

        local function newSection(tab, name, badge)
            local parent = tab.Page
            if tab.Columns then
                parent = tab.Columns[tab._nextCol]
                tab._nextCol = tab._nextCol == 1 and 2 or 1
            end

            local sec = New("Frame", {
                LayoutOrder = #state.sections + 1,
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
                local titleW = measureText(titleText, 11, F.Semibold)
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
            function section:ProgressBar(a, b) return addProgressBar(section, normCfg(a, b)) end
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

        local tabGeneration = 0
        local function switchTab(tab)
            local previous = state.activeTab
            if tab == previous or state.closed or state.min or state.destroyed then return end

            context.input.Cancel()
            closeAllPops()
            if state.listening then state.listening._cancel() end
            tabGeneration = tabGeneration + 1
            local generation = tabGeneration
            local incoming = tab._scroller
            local outgoing = previous and previous._scroller
            local direction = previous and (tab._index > previous._index and 1 or -1) or 1
            local reversing = outgoing and incoming.Visible

            for _, other in ipairs(state.tabs) do
                local scroller = other._scroller
                killTween(scroller, "Position")
                scroller.Interactable = false
                scroller.ScrollingEnabled = false
                if other ~= previous and other ~= tab then
                    scroller.Visible = false
                    other.Page.Visible = false
                    scroller.Position = UDim2.new(0, 0, 0, 0)
                end
            end

            state.activeTab = tab
            if previous then previous._setActive(false) end
            tab._setActive(true)

            if not outgoing then
                tab.Page.Visible = true
                incoming.Position = UDim2.new(0, 0, 0, 0)
                incoming.Visible = true
                incoming.Interactable = true
                incoming.ScrollingEnabled = true
                return
            end

            if not reversing then
                outgoing.Position = UDim2.new(0, 0, 0, 0)
                incoming.Position = UDim2.new(direction, 0, 0, 0)
                incoming.CanvasPosition = Vector2.new(0, 0)
            end

            tab.Page.Visible = true
            incoming.Visible = true
            outgoing.Visible = true

            local duration = reversing and math.max(0.12, 0.28 * math.abs(incoming.Position.X.Scale)) or 0.28
            tween(outgoing, duration, { Position = UDim2.new(-direction, 0, 0, 0) }, Enum.EasingStyle.Quart)
            local arrival = tween(incoming, duration, { Position = UDim2.new(0, 0, 0, 0) }, Enum.EasingStyle.Quart)
            completed(arrival, function()
                if generation ~= tabGeneration or state.destroyed or not incoming.Parent then return end
                outgoing.Visible = false
                previous.Page.Visible = false
                outgoing.Position = UDim2.new(0, 0, 0, 0)
                incoming.Interactable = true
                incoming.ScrollingEnabled = true
            end)
        end

        local function addTab(name, iconName)
            local btn = New("TextButton", {
                LayoutOrder = #state.tabs + 1,
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
            local ic = iconName and icon(btn, iconName, 16, theme.TextMuted)
            if ic then
                ic.AnchorPoint = Vector2.new(0, 0.5)
                ic.Position = UDim2.new(0, -26, 0.5, 0)
                ic.ZIndex = 2
                padding(btn, 0, 12, 0, 38)
            else
                padding(btn, 0, 12, 0, 12)
            end

            local scroller = New("ScrollingFrame", {
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                ClipsDescendants = true,
                ScrollBarThickness = 8,
                ScrollBarImageColor3 = theme.LineStrong,
                ScrollingDirection = Enum.ScrollingDirection.Y,
                CanvasSize = UDim2.new(0, 0, 0, 0),
                AutomaticCanvasSize = Enum.AutomaticSize.Y,
                ScrollingEnabled = false,
                Interactable = false,
                Visible = false,
                Parent = content,
            })
            local page = New("Frame", {
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                Visible = false,
                Parent = scroller,
            })
            padding(page, GEO.ContentPadT, GEO.ContentPadS, GEO.ContentPadB, GEO.ContentPadS)
            local pageList = list(page, GEO.SectionGap)

            local tab = {
                Name = name,
                Button = btn,
                Page = page,
                _scroller = scroller,
                _index = #state.tabs + 1,
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
                if state.activeTab ~= tab then
                    tween(btn, 0.12, { BackgroundTransparency = 0 })
                    tween(btn, 0.12, { TextColor3 = theme.Text })
                    if ic then tween(ic, 0.12, { ImageColor3 = theme.Text }) end
                end
            end)
            btn.MouseLeave:Connect(function()
                if state.activeTab ~= tab then
                    tween(btn, 0.12, { BackgroundTransparency = 1 })
                    tween(btn, 0.12, { TextColor3 = theme.TextMuted })
                    if ic then tween(ic, 0.12, { ImageColor3 = theme.TextMuted }) end
                end
            end)
            btn.Activated:Connect(function()
                switchTab(tab)
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
                local nextColumn = 1
                for _, section in ipairs(state.sections) do
                    if section._tab == tab then
                        local frame = section.Frame
                        frame.Size = UDim2.new(1, 0, 0, 0)
                        frame.Position = UDim2.new(0, 0, 0, 0)
                        frame.Parent = tab.Columns[nextColumn]
                        nextColumn = nextColumn == 1 and 2 or 1
                    end
                end
                tab._nextCol = nextColumn
            end

            function tab:Section(name2, badge2)
                return newSection(tab, name2, badge2)
            end

            table.insert(state.tabs, tab)
            popovers.TrackScroll(tab)
            if #state.tabs == 1 then
                state.activeTab = tab
                page.Visible = true
                scroller.Visible = true
                scroller.Interactable = true
                scroller.ScrollingEnabled = true
                setActive(true)
            end
            return tab
        end

        return addTab
    end
end)()

local createPopovers = (function()
    return function(Core, Theme, state, gui, windowFrame, connect, viewportBounds)
        local GEO = Theme.Geometry
        local killTween = Core.killTween
        local open = state.openPops

        local function find(pop)
            for index, record in ipairs(open) do
                if record.pop == pop then
                    return record, index
                end
            end
            return nil
        end

        local function unregisterPop(pop)
            local _, index = find(pop)
            if index then table.remove(open, index) end
        end

        local function registerPop(row, pop, setOpen, popH, popW, alignRight)
            unregisterPop(pop)
            table.insert(open, {
                row = row,
                pop = pop,
                popH = popH,
                popW = popW,
                alignRight = alignRight == true,
                close = function() setOpen(false) end,
            })
        end

        local function closePop(pop)
            local record = find(pop)
            if record then record.close() end
        end

        local function closeAll(except)
            for i = #open, 1, -1 do
                local record = open[i]
                if record.pop ~= except then
                    record.close()
                end
            end
        end

        local function contains(element, point)
            local position = element.AbsolutePosition
            local size = element.AbsoluteSize
            return point.X >= position.X - 1 and point.X <= position.X + size.X + 1
                and point.Y >= position.Y - 1 and point.Y <= position.Y + size.Y + 1
        end

        local function closeOutside(point)
            for i = #open, 1, -1 do
                local record = open[i]
                if not contains(record.row, point) and not contains(record.pop, point) then
                    record.close()
                end
            end
        end

        local function mountPop(row, pop, popH, popW, alignRight)
            local rp, rs = row.AbsolutePosition, row.AbsoluteSize
            local wp = windowFrame.AbsolutePosition
            local wb = wp.Y + windowFrame.AbsoluteSize.Y
            local topMin = wp.Y + GEO.Header + 8
            local viewport = viewportBounds and viewportBounds()
            if viewport then
                topMin = 8
                wb = viewport.Y
                popW = math.min(popW, math.max(1, viewport.X - 16))
            end
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
            if viewport then
                x = math.clamp(x, 8, math.max(8, viewport.X - popW - 8))
                y = math.clamp(y, topMin, math.max(topMin, wb - popH - 8))
            end
            pop.Parent = gui
            pop.ZIndex = 45
            pop.AnchorPoint = Vector2.new(0, 0)
            pop.Size = UDim2.new(0, popW, 0, popH)
            return x, y, popH
        end

        local function trackTabScroll(tab)
            local scroller = tab._scroller
            local lastCanvasY = scroller.CanvasPosition.Y
            connect(scroller:GetPropertyChangedSignal("CanvasPosition"), function()
                local cy = scroller.CanvasPosition.Y
                local d = cy - lastCanvasY
                lastCanvasY = cy
                if d == 0 or state.activeTab ~= tab then return end
                local wp = windowFrame.AbsolutePosition
                local wb = wp.Y + windowFrame.AbsoluteSize.Y
                local topMin = wp.Y + GEO.Header + 8
                for i = #open, 1, -1 do
                    local p = open[i]
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
        end

        return {
            Register = registerPop,
            Unregister = unregisterPop,
            Close = closePop,
            CloseAll = closeAll,
            CloseOutside = closeOutside,
            Contains = contains,
            Mount = mountPop,
            TrackScroll = trackTabScroll,
        }
    end
end)()

local createLifecycle = (function()
    return function(state, popovers, inputRouter)
        local entries = state.elements
        local searchRows = state.searchRows
        local byRow = {}
        local searchByRow = {}
        local connections = {}
        local query = ""
        local hideTip, tipHover

        local function remove(array, value)
            local index = table.find(array, value)
            if index then table.remove(array, index) end
        end

        local function disconnect(row)
            local scope = connections[row]
            if not scope then return end
            connections[row] = nil
            for _, connection in ipairs(scope) do
                connection:Disconnect()
            end
        end

        local function connect(row, signal, callback)
            local scope = connections[row]
            if not scope then
                scope = {}
                connections[row] = scope
            end
            local connection = signal:Connect(callback)
            table.insert(scope, connection)
            return connection
        end

        local function isVisible(row)
            local entry = byRow[row]
            return not entry or (not entry.hidden and not entry.destroyed)
        end

        local function refreshSearch()
            if state.destroyed then return end
            local matches = {}
            local groups = {}

            for _, record in ipairs(searchRows) do
                local frame = record.frame
                if frame.Parent then
                    local visible = isVisible(frame)
                    local match = visible and (query == "" or record.text:find(query, 1, true) ~= nil)
                    if record.group then
                        local group = record.group
                        frame.Visible = visible
                        if groups[group] == nil then groups[group] = false end
                        if match then groups[group] = true end
                        if match and isVisible(group) then matches[record.section] = true end
                    else
                        frame.Visible = match
                        if match and record.section then matches[record.section] = true end
                    end
                end
            end

            for group, matched in pairs(groups) do
                if group.Parent then
                    group.Visible = isVisible(group) and (query == "" or matched)
                end
            end
            for _, section in ipairs(state.sections) do
                if section.Frame.Parent then
                    section.Frame.Visible = query == "" or matches[section] == true
                end
            end
        end

        local function registerSearch(frame, text, section)
            local record = searchByRow[frame]
            if not record then
                local group = section and section._isRow and section.Frame or nil
                record = {
                    frame = frame,
                    group = group,
                    section = group and section._parent or section,
                }
                searchByRow[frame] = record
                table.insert(searchRows, record)
            end
            record.text = tostring(text or ""):lower()
            if query ~= "" then refreshSearch() end
        end

        local function unregisterSearch(frame)
            local record = searchByRow[frame]
            if not record then return end
            searchByRow[frame] = nil
            remove(searchRows, record)
            if record.group and record.group.Parent then
                local hasChildren = false
                for _, remaining in ipairs(searchRows) do
                    if remaining.group == record.group then
                        hasChildren = true
                        break
                    end
                end
                if not hasChildren then
                    record.group.Visible = query == "" and isVisible(record.group)
                end
            end
        end

        local function search(text)
            query = tostring(text or ""):lower()
            if query ~= "" then
                inputRouter.Cancel()
                popovers.CloseAll()
                if hideTip then hideTip() end
            end
            refreshSearch()
        end

        local function closeElementPopup(entry)
            if entry.pop then
                popovers.Close(entry.pop)
                entry.pop.Visible = false
            end
        end

        local function destroy(entry, external)
            if entry.destroyed then return end
            entry.destroyed = true
            entry.disabled = true

            local row = entry.row
            inputRouter.Cancel(row)
            disconnect(row)

            if entry.kind == "Keybind" then
                if state.listening == entry.el then
                    if not external and entry.el._cancel then entry.el._cancel() end
                    state.listening = nil
                end
                entry.el.Callback = nil
                entry.el.Active = false
                remove(state.keybinds, entry.el)
            end

            if not external and entry.setEnabled then
                pcall(entry.setEnabled, false)
            end

            if entry.pop then
                popovers.Unregister(entry.pop)
                entry.pop:Destroy()
            end

            unregisterSearch(row)
            byRow[row] = nil
            remove(entries, entry)

            if not external then row:Destroy() end
            if not state.destroyed then refreshSearch() end
        end

        local function finish(kind, el, cfg, row, hosts, pop, setEnabled)
            el._kind = kind
            el.Flag = cfg.Flag
            el._row = row

            local entry = {
                kind = kind,
                el = el,
                cfg = cfg,
                row = row,
                pop = pop,
                setEnabled = setEnabled,
                disabled = false,
                hidden = false,
                destroyed = false,
            }
            byRow[row] = entry
            table.insert(entries, entry)

            local callback = cfg.Callback
            if type(callback) == "function" then
                cfg.Callback = function(...)
                    if entry.disabled or entry.destroyed or state.destroyed then return end
                    return callback(...)
                end
                if kind == "Keybind" then el.Callback = cfg.Callback end
            else
                cfg.Callback = nil
                if kind == "Keybind" then el.Callback = nil end
            end

            function el:SetEnabled(value)
                local disabled = not value
                if entry.destroyed or state.destroyed or entry.disabled == disabled then return end
                entry.disabled = disabled
                if disabled then inputRouter.Cancel(row) end
                if setEnabled then setEnabled(not disabled) end
            end

            function el:SetVisible(value)
                if entry.destroyed or state.destroyed then return end
                entry.hidden = not value
                if not value then
                    inputRouter.Cancel(row)
                    closeElementPopup(entry)
                    if kind == "Row" then
                        for _, child in ipairs(entries) do
                            if child.row.Parent == row then
                                inputRouter.Cancel(child.row)
                                closeElementPopup(child)
                            end
                        end
                    end
                end
                row.Visible = not entry.hidden
                refreshSearch()
                if not value and hideTip then hideTip() end
            end

            function el:SetTooltip(text)
                if entry.destroyed or state.destroyed then return end
                cfg.Tooltip = text
                if hideTip and (not text or tostring(text) == "") then hideTip() end
            end

            function el:Destroy()
                if entry.destroyed then return end
                if hideTip and not state.destroyed then hideTip() end
                destroy(entry, false)
            end

            connect(row, row.Destroying, function()
                destroy(entry, true)
            end)

            if tipHover and hosts and #hosts > 0 then
                tipHover(row, cfg, hosts)
            end
            if query ~= "" then refreshSearch() end
            return el
        end

        local function destroyAll()
            while #entries > 0 do
                destroy(entries[#entries], true)
            end
            for row in pairs(connections) do
                disconnect(row)
            end
            table.clear(byRow)
            table.clear(searchByRow)
            table.clear(searchRows)
        end

        local function setTooltips(hide, hover)
            hideTip = hide
            tipHover = hover
        end

        return {
            Connect = connect,
            RegisterSearch = registerSearch,
            Search = search,
            Finish = finish,
            DestroyAll = destroyAll,
            SetTooltips = setTooltips,
        }
    end
end)()

local createInput = (function()
    return function(UserInputService, connect)
        local capture = nil
        local beganHandlers = {}
        local endedHandlers = {}
        local mouseButton = Enum.UserInputType.MouseButton1
        local mouseMovement = Enum.UserInputType.MouseMovement
        local touch = Enum.UserInputType.Touch

        local function isPointer(input)
            return input.UserInputType == mouseButton or input.UserInputType == touch
        end

        local function cancel(owner)
            if not capture or (owner and capture.owner ~= owner) then return end
            local previous = capture
            capture = nil
            if previous.finished then previous.finished() end
        end

        local function begin(owner, input, moved, finished)
            if not isPointer(input) or capture then return false end
            capture = {
                owner = owner,
                input = input,
                mouse = input.UserInputType == mouseButton,
                moved = moved,
                finished = finished,
            }
            return true
        end

        local function onBegan(callback)
            table.insert(beganHandlers, callback)
        end

        local function onEnded(callback)
            table.insert(endedHandlers, callback)
        end

        connect(UserInputService.InputBegan, function(input, processed)
            for _, callback in ipairs(beganHandlers) do
                callback(input, processed)
            end
        end)

        connect(UserInputService.InputChanged, function(input)
            local current = capture
            if not current then return end
            if current.mouse then
                if input.UserInputType ~= mouseMovement then return end
            elseif input ~= current.input then
                return
            end
            current.moved(input)
        end)

        connect(UserInputService.InputEnded, function(input, processed)
            local current = capture
            if current and (input == current.input or (current.mouse and input.UserInputType == mouseButton)) then
                cancel()
            end
            for _, callback in ipairs(endedHandlers) do
                callback(input, processed)
            end
        end)

        connect(UserInputService.WindowFocusReleased, function()
            cancel()
        end)

        local function destroy()
            cancel()
            table.clear(beganHandlers)
            table.clear(endedHandlers)
        end

        return {
            Begin = begin,
            Cancel = cancel,
            IsPointer = isPointer,
            OnBegan = onBegan,
            OnEnded = onEnded,
            Destroy = destroy,
        }
    end
end)()

local createComponentContext = (function()
    return function(Core, Theme, Icons, Components, state, theme, inputRouter, lifecycle, popovers)
        local F = Theme.Fonts
        local GEO = Theme.Geometry
        local New = Core.New
        local corner = Core.corner
        local tween = Core.tween
        local killTween = Core.killTween
        local closeAllPops = popovers.CloseAll

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

        local context = {
            F = F,
            GEO = GEO,
            MOUSE_NAMES = Core.MOUSE_NAMES,
            New = New,
            TweenService = Core.TweenService,
            UserInputService = Core.UserInputService,
            input = inputRouter,
            clamp = Core.clamp,
            closeAllPops = closeAllPops,
            colorToHex = Core.colorToHex,
            connect = lifecycle.Connect,
            corner = corner,
            finishElement = lifecycle.Finish,
            fmtNum = Core.fmtNum,
            hexToColor = Core.hexToColor,
            icon = Icons.Create,
            killTween = killTween,
            completed = Core.completed,
            list = Core.list,
            makeRow = makeRow,
            measureText = Core.measureText,
            mountPop = popovers.Mount,
            nextOrder = Core.nextOrder,
            normCfg = Core.normCfg,
            overlayBtn = overlayBtn,
            padding = Core.padding,
            registerPop = popovers.Register,
            registerSearch = lifecycle.RegisterSearch,
            rnd = Core.rnd,
            rowLabel = rowLabel,
            setRowDim = setRowDim,
            state = state,
            theme = theme,
            toWidth = Core.toWidth,
            tween = tween,
            unregisterPop = popovers.Unregister,
        }

        context.addToggle = Components.Toggle(context)
        context.addSlider = Components.Slider(context)
        context.addProgressBar = Components.ProgressBar(context)
        context.addDropdown = Components.Dropdown(context)
        context.addKeybind = Components.Keybind(context)
        context.addColorPicker = Components.ColorPicker(context)
        context.addInput = Components.Input(context)
        context.addButton = Components.Button(context)
        context.addParagraph = Components.Paragraph(context)
        context.addImage = Components.Image(context)
        context.addList = Components.List(context)
        context.addRowContainer = Components.Row(context)

        return context
    end
end)()

local bindKeybinds = (function()
    return function(Core, state, inputRouter, popovers, onEscape)
        local keyDisplayName = Core.keyDisplayName

        local function matchesKeybind(keybind, input)
            return (keybind.KeyCode ~= nil and keybind.KeyCode ~= Enum.KeyCode.None and input.KeyCode == keybind.KeyCode)
                or (keybind.UserInputType ~= nil and input.UserInputType == keybind.UserInputType)
        end

        inputRouter.OnBegan(function(input, gameProcessed)
            if state.destroyed then return end
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
                for _, kb in ipairs(table.clone(state.keybinds)) do
                    if state.destroyed then return end
                    if matchesKeybind(kb, input) and kb.Callback then
                        if kb.Mode == "Toggle" then
                            kb.Active = not kb.Active
                            kb.Callback(kb.Active, kb.Name, input, gameProcessed)
                        elseif kb.Mode == "Hold" then
                            if not kb.Active then
                                kb.Active = true
                                kb.Callback(true, kb.Name, input, gameProcessed)
                            end
                        else
                            kb.Callback(kb.Name, input, gameProcessed)
                        end
                    end
                end
            end
            if state.destroyed then return end
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                local m = Vector2.new(input.Position.X, input.Position.Y)
                popovers.CloseOutside(m)
                if state.listening and not gameProcessed then
                    local chip = state.listening._chip
                    if chip == nil or not popovers.Contains(chip, m) then
                        state.listening._cancel()
                    end
                end
            end
            if input.KeyCode == Enum.KeyCode.Escape then
                if onEscape then onEscape() else popovers.CloseAll() end
            end
        end)
        inputRouter.OnEnded(function(input, gameProcessed)
            for _, kb in ipairs(table.clone(state.keybinds)) do
                if state.destroyed then return end
                if kb.Mode == "Hold" and kb.Active and kb.Callback and matchesKeybind(kb, input) then
                    kb.Active = false
                    kb.Callback(false, kb.Name, input, gameProcessed)
                end
            end
        end)
    end
end)()

local createTooltip = (function()
    return function(Core, Theme, theme, state, gui, viewportSize)
        local New = Core.New
        local corner = Core.corner
        local F = Theme.Fonts
        local clamp = Core.clamp
        local measureText = Core.measureText
        local tween = Core.tween
        local killTween = Core.killTween
        local completed = Core.completed

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
            tween(tipFace, 0.1, { BackgroundTransparency = 1 })
            local exit = tween(tipTxt, 0.1, { TextTransparency = 1 })
            completed(exit, function()
                if not tipState.armed and tipWrap.Parent and not state.destroyed then tipWrap.Visible = false end
            end)
        end
        local function showTip(text, row)
            local clean = tostring(text or "")
            if clean == "" then return end
            local rp, rs = row.AbsolutePosition, row.AbsoluteSize
            local vy = viewportSize()
            local generation = tipState.gen
            local tw = clamp(measureText(clean, 12, F.Regular) + 22, 44, 320)
            if generation ~= tipState.gen or state.destroyed or state.closed or state.min or not gui.Enabled or not row.Parent then return end
            local x = rp.X + rs.X + 12
            if x + tw > vy.X - 10 then x = rp.X - 12 - tw end
            if x < 10 then x = 10 end
            local cy = clamp(rp.Y + rs.Y / 2, 22, vy.Y - 22)
            killTween(tipFace, "BackgroundTransparency")
            killTween(tipTxt, "TextTransparency")
            killTween(tipWrap, "Position")
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
                            if tipState.gen ~= gen or state.destroyed or state.closed or state.min or not gui.Enabled or not row.Parent then return end
                            local ancestor = row
                            while ancestor and ancestor ~= gui do
                                if ancestor:IsA("GuiObject") and not ancestor.Visible then return end
                                ancestor = ancestor.Parent
                            end
                            if ancestor ~= gui then return end
                            tipState.armed = true
                            showTip(cfg.Tooltip, row)
                        end)
                    end
                end)
                host.MouseLeave:Connect(function()
                    tipState.gen = tipState.gen + 1
                    hideTip()
                end)
            end
        end

        local function dispose()
            tipState.gen = tipState.gen + 1
            tipState.armed = false
            if tipWrap.Parent then tipWrap.Visible = false end
        end

        return hideTip, tipHover, dispose
    end
end)()

local createWidget = (function()
    return function(Reborn, Core, Theme, Icons, Notifications, Components, attachConfig, createPopovers, createLifecycle, createInput, createComponentContext, bindKeybinds, createTooltip)
        local New = Core.New
        local corner = Core.corner
        local tween = Core.tween
        local killTween = Core.killTween
        local completed = Core.completed
        local F = Theme.Fonts
        local GEO = Theme.Geometry
        local HEADER = 34
        local INSET = 8

        local function viewportSize()
            local camera = workspace.CurrentCamera
            return camera and camera.ViewportSize or Vector2.new(1920, 1080)
        end

        local function number(value, default)
            local n = tonumber(value)
            if n and n == n and math.abs(n) < math.huge then return n end
            return default
        end

        function Reborn:CreateWidget(config)
            config = table.clone(config or {})
            local theme = table.clone(Theme.Default)
            if type(config.Theme) == "table" then
                for key, value in pairs(config.Theme) do theme[key] = value end
            end
            local parent = Core.resolveParent(config)
            local gui = New("ScreenGui", {
                Name = "RebornWidget",
                ResetOnSpawn = false,
                IgnoreGuiInset = true,
                ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
                DisplayOrder = Core.nextOrder(),
                Parent = parent,
            })

            local connections = {}
            local cleanups = {}
            local function connect(signal, callback)
                local connection = signal:Connect(callback)
                table.insert(connections, connection)
                return connection
            end
            local state = {
                closed = false,
                min = false,
                destroyed = false,
                openPops = {},
                keybinds = {},
                searchRows = {},
                sections = {},
                elements = {},
                tabs = {},
            }
            local router = createInput(Core.UserInputService, connect)
            local maxWidth = math.max(180, number(config.MaxWidth, 420))
            local minWidth = math.clamp(number(config.MinWidth, 180), 120, maxWidth)
            local width = math.clamp(number(config.Width, 260), minWidth, maxWidth)
            local maxHeight = math.max(HEADER + 24, number(config.MaxHeight, 380))
            local offset = #Reborn._widgets * 24
            local position = typeof(config.Position) == "Vector2" and config.Position or Vector2.new(24 + offset, 70 + offset)

            local panel = New("Frame", {
                Position = UDim2.fromOffset(position.X, position.Y),
                Size = UDim2.fromOffset(width, HEADER + INSET * 2),
                BackgroundColor3 = theme.Surface,
                BorderSizePixel = 0,
                ClipsDescendants = true,
                Active = true,
                Parent = gui,
            })
            corner(panel, GEO.WindowRadius)
            local header = New("Frame", {
                Size = UDim2.new(1, 0, 0, HEADER),
                BackgroundTransparency = 1,
                Parent = panel,
            })
            local title = New("TextLabel", {
                Position = UDim2.fromOffset(12, 0),
                Size = UDim2.new(1, -84, 1, 0),
                BackgroundTransparency = 1,
                Text = tostring(config.Title or "Widget"),
                FontFace = F.Semibold,
                TextSize = 13,
                TextColor3 = theme.Text,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd,
                Parent = header,
            })
            local dragZone = New("TextButton", {
                Size = UDim2.new(1, -70, 1, 0),
                BackgroundTransparency = 1,
                Text = "",
                AutoButtonColor = false,
                Parent = header,
            })
            local function headerButton(offsetX, name)
                local button = New("TextButton", {
                    AnchorPoint = Vector2.new(1, 0.5),
                    Position = UDim2.new(1, offsetX, 0.5, 0),
                    Size = UDim2.fromOffset(26, 26),
                    BackgroundColor3 = theme.RowHover,
                    BackgroundTransparency = 1,
                    Text = "",
                    AutoButtonColor = false,
                    Parent = header,
                })
                corner(button, 5)
                local glyph = Icons.Create(button, name, 15, theme.TextMuted)
                if glyph then
                    glyph.AnchorPoint = Vector2.new(0.5, 0.5)
                    glyph.Position = UDim2.fromScale(0.5, 0.5)
                end
                button.MouseEnter:Connect(function()
                    tween(button, 0.12, { BackgroundTransparency = 0 })
                end)
                button.MouseLeave:Connect(function()
                    tween(button, 0.12, { BackgroundTransparency = 1 })
                end)
                return button, glyph
            end
            local collapseButton, chevron = headerButton(-34, "chevron-up")
            local closeButton = headerButton(-5, "x")
            local body = New("ScrollingFrame", {
                Position = UDim2.fromOffset(0, HEADER),
                Size = UDim2.new(1, 0, 1, -HEADER),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                ScrollBarThickness = 4,
                ScrollBarImageColor3 = theme.LineStrong,
                CanvasSize = UDim2.fromOffset(0, 0),
                ScrollingDirection = Enum.ScrollingDirection.Y,
                ClipsDescendants = true,
                Parent = panel,
            })
            local rows = New("Frame", {
                Position = UDim2.fromOffset(INSET, INSET),
                Size = UDim2.new(1, -INSET * 2 - 4, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                Parent = body,
            })
            local layout = Core.list(rows, GEO.RowGap)
            local grip = New("TextButton", {
                AnchorPoint = Vector2.new(1, 1),
                Position = UDim2.new(1, -2, 1, -2),
                Size = UDim2.fromOffset(15, 15),
                BackgroundTransparency = 1,
                Text = "",
                AutoButtonColor = false,
                Visible = config.Resizable ~= false,
                ZIndex = 10,
                Parent = panel,
            })
            local gripIcon = Icons.Create(grip, "grip", 12, theme.TextFaint)
            if gripIcon then gripIcon.Position = UDim2.fromOffset(1, 1) end

            local popovers = createPopovers(Core, Theme, state, gui, panel, connect, viewportSize)
            local lifecycle = createLifecycle(state, popovers, router)
            local context = createComponentContext(Core, Theme, Icons, Components, state, theme, router, lifecycle, popovers)
            local section = { Frame = rows, Rows = rows }
            table.insert(state.sections, section)
            bindKeybinds(Core, state, router, popovers)
            local hideTip, tipHover, disposeTooltip = createTooltip(Core, Theme, theme, state, gui, viewportSize)
            lifecycle.SetTooltips(hideTip, tipHover)

            local targetHeight = HEADER + INSET * 2
            local generation = 0
            local function constrainPosition()
                killTween(panel, "Position")
                local viewport = viewportSize()
                local x = math.clamp(panel.Position.X.Offset, 0, math.max(0, viewport.X - width))
                local y = math.clamp(panel.Position.Y.Offset, 0, math.max(0, viewport.Y - HEADER))
                panel.Position = UDim2.fromOffset(x, y)
            end

            local function updateLayout(animate)
                if state.destroyed then return end
                local viewport = viewportSize()
                local limit = math.max(1, math.min(maxWidth, viewport.X - INSET * 2))
                width = math.clamp(width, math.min(minWidth, limit), limit)
                local contentHeight = layout.AbsoluteContentSize.Y + INSET * 2
                body.CanvasSize = UDim2.fromOffset(0, contentHeight)
                local available = math.max(HEADER, math.min(maxHeight, viewport.Y - panel.Position.Y.Offset - INSET))
                local height = state.min and HEADER or math.min(HEADER + contentHeight, available)
                if targetHeight == height and panel.Size.X.Offset == width then
                    if state.min and panel.Size.Y.Offset == HEADER then body.Visible = false end
                    return
                end
                targetHeight = height
                local size = UDim2.fromOffset(width, height)
                if animate then
                    local transition = tween(panel, 0.20, { Size = size }, Enum.EasingStyle.Quart)
                    local current = generation
                    completed(transition, function()
                        if not state.destroyed and generation == current and state.min then body.Visible = false end
                    end)
                else
                    killTween(panel, "Size")
                    panel.Size = size
                    if state.min then body.Visible = false end
                end
            end
            local function foreground()
                if not state.destroyed then gui.DisplayOrder = Core.nextOrder() end
            end
            panel.InputBegan:Connect(function(input)
                if router.IsPointer(input) then foreground() end
            end)
            dragZone.InputBegan:Connect(function(input)
                if state.destroyed or not router.IsPointer(input) then return end
                local start = input.Position
                killTween(panel, "Position")
                local origin = panel.Position
                if router.Begin(panel, input, function(movement)
                    local delta = movement.Position - start
                    panel.Position = UDim2.fromOffset(origin.X.Offset + delta.X, origin.Y.Offset + delta.Y)
                    constrainPosition()
                    updateLayout(false)
                end) then
                    foreground()
                    hideTip()
                    popovers.CloseAll()
                end
            end)
            grip.InputBegan:Connect(function(input)
                if state.destroyed or state.min or not router.IsPointer(input) then return end
                local start = input.Position.X
                local initial = width
                if router.Begin(grip, input, function(movement)
                    width = initial + movement.Position.X - start
                    updateLayout(false)
                    constrainPosition()
                end) then
                    foreground()
                    popovers.CloseAll()
                end
            end)
            connect(layout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
                if not state.min then updateLayout(true) end
            end)
            connect(body:GetPropertyChangedSignal("CanvasPosition"), function()
                hideTip()
                popovers.CloseAll()
            end)
            local camera = workspace.CurrentCamera
            if camera then
                connect(camera:GetPropertyChangedSignal("ViewportSize"), function()
                    updateLayout(false)
                    constrainPosition()
                end)
            end

            local toastLayer
            local Widget = {
                Title = title.Text,
                Gui = gui,
                Theme = theme,
            }

            local function collapse(value)
                if state.destroyed or state.min == value then return end
                state.min = value
                generation = generation + 1
                router.Cancel()
                hideTip()
                popovers.CloseAll()
                if state.listening then state.listening._cancel() end
                if not value then body.Visible = true end
                body.Interactable = not value
                grip.Visible = not value and config.Resizable ~= false
                if chevron then
                    tween(chevron, 0.20, { Rotation = value and 180 or 0 }, Enum.EasingStyle.Quart)
                end
                updateLayout(true)
            end

            local function stop(external)
                if state.destroyed then return end
                state.destroyed = true
                state.closed = true
                generation = generation + 1
                router.Destroy()
                disposeTooltip()
                if not external then
                    if state.listening then state.listening._cancel() end
                    popovers.CloseAll()
                end
                for _, connection in ipairs(connections) do connection:Disconnect() end
                table.clear(connections)
                lifecycle.DestroyAll()
                if toastLayer then
                    toastLayer.Layer:Destroy()
                    toastLayer = nil
                end
                table.clear(state.keybinds)
                table.clear(state.openPops)
                table.clear(state.sections)
                for index = #cleanups, 1, -1 do pcall(cleanups[index]) end
                table.clear(cleanups)
                if type(config.OnClose) == "function" then pcall(config.OnClose, Widget) end
            end

            local finalized = false
            local function finalize(external)
                if finalized then return end
                finalized = true
                stop(external)
                local index = table.find(Reborn._widgets, Widget)
                if index then table.remove(Reborn._widgets, index) end
                if not external then gui:Destroy() end
            end

            function Widget:AddCleanup(callback)
                if type(callback) ~= "function" then return end
                if state.destroyed then pcall(callback) else table.insert(cleanups, callback) end
            end

            function Widget:Close()
                if state.destroyed then return end
                panel.Interactable = false
                stop()
                if finalized or not gui.Parent then return end
                killTween(panel, "Size")
                local exit = tween(panel, 0.16, { Position = panel.Position + UDim2.fromOffset(0, 8) }, Enum.EasingStyle.Sine)
                completed(exit, function() finalize(false) end)
            end

            function Widget:Destroy()
                finalize(false)
            end

            function Widget:SetCollapsed(value)
                collapse(value == true)
            end

            function Widget:Minimize()
                collapse(true)
            end

            function Widget:ToggleCollapsed()
                collapse(not state.min)
            end

            function Widget:SetVisible(value)
                if state.destroyed then return end
                if not value then
                    router.Cancel()
                    hideTip()
                    popovers.CloseAll()
                    if state.listening then state.listening._cancel() end
                end
                gui.Enabled = value == true
            end

            function Widget:Notify(a, b)
                if state.destroyed or not Reborn.NotificationsEnabled then return end
                if not toastLayer then toastLayer = Notifications.Build(gui, theme) end
                toastLayer.Notify(Notifications.Normalize(a, b))
            end

            function Widget:SetTitle(value)
                if state.destroyed then return end
                Widget.Title = tostring(value or "")
                title.Text = Widget.Title
            end

            function Widget:SetPosition(value)
                if state.destroyed or typeof(value) ~= "Vector2" then return end
                panel.Position = UDim2.fromOffset(value.X, value.Y)
                constrainPosition()
                popovers.CloseAll()
                updateLayout(false)
            end

            function Widget:SetWidth(value)
                if state.destroyed then return end
                width = number(value, width)
                popovers.CloseAll()
                updateLayout(true)
                constrainPosition()
            end

            local componentMethods = {
                Toggle = context.addToggle,
                Slider = context.addSlider,
                ProgressBar = context.addProgressBar,
                Dropdown = context.addDropdown,
                Keybind = context.addKeybind,
                ColorPicker = context.addColorPicker,
                Input = context.addInput,
                Button = context.addButton,
                Paragraph = context.addParagraph,
                Image = context.addImage,
                List = context.addList,
                Row = context.addRowContainer,
            }
            for name, add in pairs(componentMethods) do
                Widget[name] = function(_, a, b)
                    if state.destroyed then return end
                    return add(section, Core.normCfg(a, b))
                end
            end

            local profile = table.clone(config)
            profile.Title = "Widget-" .. tostring(config.Id or Widget.Title)
            attachConfig(Reborn, Core, Widget, state, profile)
            collapseButton.Activated:Connect(function() collapse(not state.min) end)
            closeButton.Activated:Connect(function() Widget:Close() end)
            gui.Destroying:Connect(function() finalize(true) end)
            table.insert(Reborn._widgets, Widget)
            updateLayout(false)
            constrainPosition()
            local target = panel.Position
            panel.Position = target - UDim2.fromOffset(0, math.min(8, target.Y.Offset))
            tween(panel, 0.20, { Position = target }, Enum.EasingStyle.Sine)
            return Widget
        end
    end
end)()

local createPillLayout = (function()
    local WIDTH = "RebornPillWidth"
    local ORDER = "RebornPillOrder"
    local GAP = 8

    return function(parent, gui, viewportSize, pillHeight, onPosition)
        local watched = {}
        local destroyed = false
        local queued = false
        local position

        local function entries()
            local result = {}
            for _, child in ipairs(parent:GetChildren()) do
                local width = child:GetAttribute(WIDTH)
                local order = child:GetAttribute(ORDER)
                if child:IsA("ScreenGui") and type(width) == "number" and width > 0 and type(order) == "number" then
                    table.insert(result, { gui = child, width = width, order = order })
                end
            end
            table.sort(result, function(a, b)
                if a.order == b.order then return a.gui.Name < b.gui.Name end
                return a.order < b.order
            end)
            return result
        end

        local function refresh()
            if destroyed or gui.Parent ~= parent or (gui:GetAttribute(WIDTH) or 0) <= 0 then return end
            local active = entries()
            local limit = math.max(1, viewportSize().X - GAP * 2)
            local first, y = 1, 14
            while first <= #active do
                local last, total = first, active[first].width
                while last < #active do
                    local extra = active[last + 1].width + GAP
                    if total + extra > limit then break end
                    total = total + extra
                    last = last + 1
                end
                local x = -total / 2
                for index = first, last do
                    local item = active[index]
                    if item.gui == gui then
                        local nextPosition = UDim2.new(0.5, x + item.width / 2, 0, y)
                        if nextPosition ~= position then
                            position = nextPosition
                            onPosition(position)
                        end
                        return
                    end
                    x = x + item.width + GAP
                end
                first = last + 1
                y = y + pillHeight + GAP
            end
        end

        local function schedule()
            if destroyed or queued then return end
            queued = true
            task.defer(function()
                queued = false
                refresh()
            end)
        end

        local function watch(child)
            if watched[child] or not child:IsA("ScreenGui") or child:GetAttribute(ORDER) == nil then return end
            watched[child] = child:GetAttributeChangedSignal(WIDTH):Connect(schedule)
        end

        for _, child in ipairs(parent:GetChildren()) do watch(child) end
        local added = parent.ChildAdded:Connect(function(child)
            watch(child)
            schedule()
        end)
        local removed = parent.ChildRemoved:Connect(function(child)
            if watched[child] then
                watched[child]:Disconnect()
                watched[child] = nil
            end
            schedule()
        end)

        local function setWidth(width)
            if destroyed then return end
            local previous = gui:GetAttribute(WIDTH) or 0
            if previous <= 0 and width > 0 then
                local order = 0
                for _, item in ipairs(entries()) do order = math.max(order, item.order) end
                gui:SetAttribute(ORDER, order + 1)
                position = nil
            end
            if previous ~= width then gui:SetAttribute(WIDTH, width) end
            if width > 0 then refresh() else position = nil end
        end

        local function destroy()
            if destroyed then return end
            destroyed = true
            added:Disconnect()
            removed:Disconnect()
            for _, connection in pairs(watched) do connection:Disconnect() end
            table.clear(watched)
            if gui.Parent then gui:SetAttribute(WIDTH, 0) end
        end

        return { SetWidth = setWidth, Refresh = refresh, Destroy = destroy }
    end
end)()

local createWindow = (function()
    return function(Reborn, Core, Theme, Icons, Notifications, Components, attachConfig, createNavigation, createPopovers, createLifecycle, createInput, createComponentContext, bindKeybinds, createTooltip, createPillLayout)
        local DEFAULT_THEME = Theme.Default
        local F = Theme.Fonts
        local GEO = Theme.Geometry
        local icon = Icons.Create
        local buildToastLayer = Notifications.Build
        local normNotify = Notifications.Normalize
        local TweenService = Core.TweenService
        local UserInputService = Core.UserInputService
        local rnd = Core.rnd
        local clamp = Core.clamp
        local toWidth = Core.toWidth
        local New = Core.New
        local corner = Core.corner
        local padding = Core.padding
        local list = Core.list
        local tween = Core.tween
        local killTween = Core.killTween
        local completed = Core.completed
        local measureText = Core.measureText
        local colorToHex = Core.colorToHex
        local hexToColor = Core.hexToColor
        local keyDisplayName = Core.keyDisplayName
        local fmtNum = Core.fmtNum
        local MOUSE_NAMES = Core.MOUSE_NAMES
        local resolveParent = Core.resolveParent
        local randomName = Core.randomName
        local nextOrder = Core.nextOrder
        local protectGui = Core.protectGui
        local normCfg = Core.normCfg

        function Reborn:CreateWindow(config)
            config = table.clone(config or {})

            local theme = table.clone(DEFAULT_THEME)
            if config.Theme then
                for key, value in pairs(config.Theme) do
                    theme[key] = value
                end
            end

            local parent, viaHidden = resolveParent(config)

            local gui = New("ScreenGui", {
                Name = randomName(),
                ResetOnSpawn = false,
                IgnoreGuiInset = true,
                ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
                DisplayOrder = nextOrder(),
            })
            gui:SetAttribute("RebornPillOrder", 0)
            gui:SetAttribute("RebornPillWidth", 0)
            if not viaHidden then protectGui(gui) end
            gui.Parent = parent

            local conns = {}

            local function connect(signal, callback)
                local connection = signal:Connect(callback)
                table.insert(conns, connection)
                return connection
            end

            local inputRouter = createInput(UserInputService, connect)

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
                BackgroundColor3 = theme.Surface,
                BorderSizePixel = 0,
                ClipsDescendants = true,
                Parent = gui,
            })
            local closedPosition
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
                if state.dragged or state.closed or state.min or state.restoring then return end
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

            local content = New("Frame", {
                Position = UDim2.new(0, GEO.Sidebar + 1, 0, 0),
                Size = UDim2.new(1, -(GEO.Sidebar + 1), 1, 0),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                ClipsDescendants = true,
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
            local pillTarget = UDim2.new(0.5, 0, 0, 14)
            local morphingToPill = false
            local hoverGeneration = 0

            local function morphPosition(width)
                return UDim2.fromOffset(
                    viewportSize().X / 2 + pillTarget.X.Offset - width / 2,
                    pillTarget.Y.Offset - 1
                )
            end

            local pillLayout = createPillLayout(parent, gui, viewportSize, GEO.PillH, function(position)
                pillTarget = position
                if pill.Visible then
                    tween(pill, 0.20, { Position = position }, Enum.EasingStyle.Quint)
                else
                    pill.Position = position
                    if morphingToPill then
                        tween(windowFrame, 0.20, { Position = morphPosition(pillRestW + 2) }, Enum.EasingStyle.Quint)
                    end
                end
            end)
            if camera then
                connect(camera:GetPropertyChangedSignal("ViewportSize"), function()
                    pillLayout.Refresh()
                    if morphingToPill then
                        tween(windowFrame, 0.20, { Position = morphPosition(pillRestW + 2) }, Enum.EasingStyle.Quint)
                    end
                end)
            end

            local function snapPillRest()
                hoverGeneration = hoverGeneration + 1
                killTween(pill, "Size")
                killTween(pillContent, "Size")
                killTween(pillHint, "TextTransparency")
                killTween(pill, "BackgroundColor3")
                pill.Size = UDim2.new(0, pillRestW, 0, GEO.PillH)
                pillContent.Size = UDim2.new(0, pillRestW, 1, 0)
                pillHint.TextTransparency = 1
                pill.BackgroundColor3 = theme.Surface
            end
            pill.MouseEnter:Connect(function()
                hoverGeneration = hoverGeneration + 1
                local generation = hoverGeneration
                if not state.min or not pill.Visible or state.destroyed then return end
                local key = Window and Window.ToggleKey or config.ToggleKey
                local hint = key and ("Click or " .. tostring(key) .. " to open") or "Click to open"
                pillHint.Text = hint
                local w = 22 + pillTitleW + rnd(measureText(hint, 12, F.Regular)) + 12
                if generation ~= hoverGeneration or not state.min or not pill.Visible or state.destroyed then return end
                pillLayout.SetWidth(w)
                tween(pill, 0.2, { Size = UDim2.new(0, w, 0, GEO.PillH) }, Enum.EasingStyle.Quint)
                tween(pillContent, 0.2, { Size = UDim2.new(0, w, 1, 0) }, Enum.EasingStyle.Quint)
                tween(pillHint, 0.2, { TextTransparency = pillClear and 0.55 or 0 })
                tween(pill, 0.2, { BackgroundColor3 = theme.Overlay })
            end)
            pill.MouseLeave:Connect(function()
                hoverGeneration = hoverGeneration + 1
                if not state.min or not pill.Visible or state.destroyed then return end
                pillLayout.SetWidth(pillRestW)
                tween(pill, 0.2, { Size = UDim2.new(0, pillRestW, 0, GEO.PillH) }, Enum.EasingStyle.Quint)
                tween(pillContent, 0.2, { Size = UDim2.new(0, pillRestW, 1, 0) }, Enum.EasingStyle.Quint)
                tween(pillHint, 0.2, { TextTransparency = 1 })
                tween(pill, 0.2, { BackgroundColor3 = theme.Surface })
            end)

            local toastLayer

            dragZone.InputBegan:Connect(function(input)
                if state.closed or state.min or state.restoring or not inputRouter.IsPointer(input) then return end
                local start = input.Position
                local origin = windowFrame.Position
                if not inputRouter.Begin(windowFrame, input, function(movement)
                    killTween(windowFrame, "Position")
                    local viewport = viewportSize()
                    local delta = movement.Position - start
                    local x = clamp(origin.X.Offset + delta.X, -W + 140, viewport.X - 140)
                    local y = clamp(origin.Y.Offset + delta.Y, 0, viewport.Y - GEO.Header)
                    windowFrame.Position = UDim2.new(0, rnd(x), 0, rnd(y))
                end) then return end
                state.dragged = true
                killTween(windowFrame, "Position")
            end)

            local popovers = createPopovers(Core, Theme, state, gui, windowFrame, connect)
            local closeAllPops = popovers.CloseAll
            local lifecycle = createLifecycle(state, popovers, inputRouter)
            local closeSearch

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
            grip.InputBegan:Connect(function(input)
                if state.closed or state.min or state.restoring or not inputRouter.IsPointer(input) then return end
                local start = input.Position
                local width, height = W, H
                if not inputRouter.Begin(grip, input, function(movement)
                    local viewport = viewportSize()
                    local delta = movement.Position - start
                    local maxWidth, maxHeight = viewport.X * 0.96, viewport.Y * 0.88
                    local minWidth, minHeight = math.min(540, maxWidth), math.min(360, maxHeight)
                    W = math.floor(clamp(width + delta.X, minWidth, maxWidth) / 2) * 2
                    H = math.floor(clamp(height + delta.Y, minHeight, maxHeight) / 2) * 2
                    windowFrame.Size = UDim2.new(0, W, 0, H)
                end) then return end
                closeAllPops()
                killTween(windowFrame, "Size")
            end)

            local morphGeneration = 0
            local function setMinimized(m)
                if state.destroyed or state.min == m then return end
                if m and state.closed then return end
                morphGeneration = morphGeneration + 1
                local generation = morphGeneration
                local wasRestoring = state.restoring
                state.restoring = not m
                state.min = m
                if m then
                    inputRouter.Cancel()
                    closeAllPops()
                    if searchWrap.Size.X.Offset > 0 then closeSearch() end
                    grip.Visible = false
                    header.Visible = false
                    bodyGroup.Visible = false
                    minIcon.Visible = false
                    plusIcon.Visible = true
                    if not wasRestoring or not state.minPos then
                        state.minPos = { x = windowFrame.Position.X.Offset, y = windowFrame.Position.Y.Offset }
                    end
                    killTween(windowFrame, "Position")
                    killTween(windowFrame, "Size")
                    local tw = pillRestW + 2
                    pillLayout.SetWidth(pillRestW)
                    morphingToPill = true
                    tween(windowFrame, 0.36, { Position = morphPosition(tw) }, Enum.EasingStyle.Quint)
                    local morph = tween(windowFrame, 0.36, {
                        Size = UDim2.new(0, tw, 0, GEO.PillH + 2),
                    }, Enum.EasingStyle.Quint)
                    tween(winCorner, 0.36, { CornerRadius = UDim.new(0, GEO.PillH / 2 + 1) }, Enum.EasingStyle.Quint)
                    tween(faceCorner, 0.36, { CornerRadius = UDim.new(0, GEO.PillH / 2) }, Enum.EasingStyle.Quint)
                    tween(windowFrame, 0.24, { BackgroundColor3 = theme.Surface })
                    completed(morph, function()
                        if generation == morphGeneration and state.min and not state.destroyed and windowFrame.Parent then
                            morphingToPill = false
                            local center = windowFrame.Position.X.Offset + windowFrame.Size.X.Offset / 2
                            local y = windowFrame.Position.Y.Offset + 1
                            killTween(windowFrame, "Position")
                            windowFrame.Visible = false
                            snapPillRest()
                            pill.Position = UDim2.new(0.5, center - viewportSize().X / 2, 0, y)
                            pill.Visible = true
                            if pill.Position ~= pillTarget then
                                tween(pill, 0.20, { Position = pillTarget }, Enum.EasingStyle.Quint)
                            end
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
                    morphingToPill = false
                    if not windowFrame.Visible then
                        local tw = pill.Size.X.Offset + 2
                        local center = v.X / 2 + pill.Position.X.Offset
                        windowFrame.Position = UDim2.fromOffset(center - tw / 2, pill.Position.Y.Offset - 1)
                        windowFrame.Size = UDim2.new(0, tw, 0, GEO.PillH + 2)
                        windowFrame.Visible = true
                    end
                    pill.Visible = false
                    killTween(pill, "Position")
                    pillLayout.SetWidth(0)
                    snapPillRest()
                    local tx, ty
                    if state.minPos then
                        tx, ty = state.minPos.x, state.minPos.y
                    else
                        tx, ty = rnd(v.X / 2 - W / 2), rnd(v.Y / 2 - H / 2)
                    end
                    local restore = tween(windowFrame, 0.34, { Size = UDim2.new(0, W, 0, H), Position = UDim2.new(0, tx, 0, ty) }, Enum.EasingStyle.Quint)
                    tween(winCorner, 0.34, { CornerRadius = UDim.new(0, GEO.WindowRadius) }, Enum.EasingStyle.Quint)
                    tween(faceCorner, 0.34, { CornerRadius = UDim.new(0, GEO.WindowRadius - 1) }, Enum.EasingStyle.Quint)
                    tween(windowFrame, 0.3, { BackgroundColor3 = theme.Surface })
                    completed(restore, function()
                        if generation == morphGeneration and not state.destroyed then
                            state.restoring = false
                        end
                    end)
                end
            end

            local function closeWindow()
                if state.closed or state.destroyed then return end
                state.closed = true
                morphGeneration = morphGeneration + 1
                morphingToPill = false
                hoverGeneration = hoverGeneration + 1
                pillLayout.SetWidth(0)
                killTween(pill, "Position")
                inputRouter.Cancel()
                closeAllPops()
                if state.min or state.restoring then
                    state.min = false
                    state.restoring = false
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
                    return
                end
                closedPosition = windowFrame.Position
                local exit = tween(windowFrame, 0.20, { Position = closedPosition + UDim2.fromOffset(0, 14) }, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
                completed(exit, function()
                    if state.closed and state.closeGeneration == generation and not state.destroyed and windowFrame.Parent then
                        windowFrame.Visible = false
                        if closedPosition then windowFrame.Position = closedPosition end
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
            inputRouter.OnEnded(function(input)
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
                if not state.closed or state.unloading or state.destroyed then return end
                state.closed = false
                if state.min then setMinimized(false) end
                closeAllPops()
                state.closeGeneration = (state.closeGeneration or 0) + 1
                killTween(windowFrame, "Position")
                local target = closedPosition or windowFrame.Position
                windowFrame.Position = target + UDim2.fromOffset(0, 14)
                windowFrame.Visible = true
                tween(windowFrame, 0.22, { Position = target }, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
            end

            local applyFilter = lifecycle.Search

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
                completed(exit, function()
                    if generation == searchGeneration and not searchOpen and not state.destroyed and searchWrap.Parent then
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
            inputRouter.OnEnded(function(input)
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

            local hideTip, tipHover, disposeTooltip = createTooltip(Core, Theme, theme, state, gui, viewportSize)
            lifecycle.SetTooltips(hideTip, tipHover)
            windowFrame:GetPropertyChangedSignal("Visible"):Connect(function()
                if not windowFrame.Visible then hideTip() end
            end)
            bodyGroup:GetPropertyChangedSignal("Visible"):Connect(function()
                if not bodyGroup.Visible then hideTip() end
            end)

            dragZone.InputBegan:Connect(function() closeAllPops() end)

            local confirmActive = false
            local confirmGeneration = 0
            local scrim, card

            local function hideConfirm()
                if not confirmActive or state.unloading then return end
                confirmActive = false
                confirmGeneration = confirmGeneration + 1
                local generation = confirmGeneration
                tween(scrim, 0.15, { BackgroundTransparency = 1 })
                local exit = tween(card, 0.15, { Position = UDim2.new(0.5, 0, 0.5, 8) }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
                completed(exit, function()
                    if generation == confirmGeneration and not confirmActive and not state.destroyed and card.Parent then
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
                        pcall(function() Window:Destroy() end)
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
                    card = New("Frame", {
                        ClipsDescendants = true,
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
                        Text = "Are you sure you want to close this window?",
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
                confirmGeneration = confirmGeneration + 1
                card.Size = UDim2.new(0, math.min(420, W - 48), 0, 156)
                if not card.Visible then
                    scrim.BackgroundTransparency = 1
                    card.Position = UDim2.new(0.5, 0, 0.5, 8)
                end
                scrim.Visible = true
                card.Visible = true
                tween(scrim, 0.20, { BackgroundTransparency = 0.42 })
                tween(card, 0.23, { Position = UDim2.new(0.5, 0, 0.5, 0) }, Enum.EasingStyle.Quart)
            end

            closeBtn.Activated:Connect(showConfirm)

            local context = createComponentContext(Core, Theme, Icons, Components, state, theme, inputRouter, lifecycle, popovers)

            local addTab = createNavigation(context, tabsHolder, content, popovers)

            bindKeybinds(Core, state, inputRouter, popovers, function()
                if confirmActive then
                    hideConfirm()
                else
                    closeAllPops()
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
                if state.destroyed or not Reborn.NotificationsEnabled then return end
                if not toastLayer then
                    toastLayer = buildToastLayer(gui, theme)
                end
                toastLayer.Notify(cfg)
            end

            function Window:Search(q)
                applyFilter(q)
            end

            function Window:SetTitle(text)
                Window.Title = tostring(text or "")
                titleLbl.Text = Window.Title
            end

            attachConfig(Reborn, Core, Window, state, config)

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

            local function cleanup()
                if state.destroyed then return end
                state.destroyed = true
                state.closed = true
                state.min = false
                morphingToPill = false
                hoverGeneration = hoverGeneration + 1
                pillLayout.Destroy()
                disposeTooltip()
                inputRouter.Destroy()
                for _, connection in ipairs(conns) do
                    connection:Disconnect()
                end
                table.clear(conns)
                lifecycle.DestroyAll()
                table.clear(state.keybinds)
                table.clear(state.openPops)
                table.clear(state.sections)
                table.clear(state.tabs)
                state.activeTab = nil
                state.listening = nil

                local index = table.find(Reborn._windows, Window)
                if index then table.remove(Reborn._windows, index) end
                if #Reborn._windows == 0 and Reborn._toastGui then
                    Reborn._toastGui:Destroy()
                    Reborn._toastGui = nil
                    Reborn._toastLayer = nil
                end
            end

            function Window:Destroy()
                if state.destroyed then return end
                cleanup()
                gui:Destroy()
            end

            gui.Destroying:Connect(cleanup)
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

Components.ProgressBar = (function()
    return function(ctx)
        local New = ctx.New
        local corner = ctx.corner
        local tween = ctx.tween
        local killTween = ctx.killTween
        local theme = ctx.theme
        local GEO = ctx.GEO
        local F = ctx.F

        local function finiteNumber(raw)
            local value = tonumber(raw)
            if value and value == value and math.abs(value) < math.huge then return value end
        end

        local function addProgressBar(section, cfg)
            cfg = cfg or {}
            local min = finiteNumber(cfg.Min) or 0
            local max = finiteNumber(cfg.Max) or 100
            if max <= min or not finiteNumber(max - min) then min, max = 0, 100 end
            local value = math.clamp(finiteNumber(cfg.Value) or min, min, max)
            local showValue = cfg.ShowValue ~= false
            local duration = math.clamp(finiteNumber(cfg.Duration) or 0.20, 0, 2)
            local row, face = ctx.makeRow(section, 48, ctx.toWidth(cfg.Width, nil))
            local label = New("TextLabel", {
                Position = UDim2.fromOffset(GEO.RowPad, 8),
                Size = UDim2.new(showValue and 0.65 or 1, -GEO.RowPad, 0, 16),
                BackgroundTransparency = 1,
                FontFace = F.Medium,
                TextSize = 13,
                TextColor3 = theme.Text,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd,
                Text = tostring(cfg.Text or ""),
                Parent = row,
            })
            local display = New("TextLabel", {
                AnchorPoint = Vector2.new(1, 0),
                Position = UDim2.new(1, -GEO.RowPad, 0, 8),
                Size = UDim2.new(0.35, -GEO.RowPad, 0, 16),
                BackgroundTransparency = 1,
                FontFace = F.Medium,
                TextSize = 12,
                TextColor3 = theme.TextMuted,
                TextXAlignment = Enum.TextXAlignment.Right,
                TextTruncate = Enum.TextTruncate.AtEnd,
                Visible = showValue,
                Parent = row,
            })
            local track = New("Frame", {
                Position = UDim2.fromOffset(GEO.RowPad, 31),
                Size = UDim2.new(1, -GEO.RowPad * 2, 0, GEO.RailH),
                BackgroundColor3 = theme.LineStrong,
                BorderSizePixel = 0,
                ClipsDescendants = true,
                Parent = row,
            })
            corner(track, GEO.RailH / 2)
            local fill = New("Frame", {
                Size = UDim2.new(0, 0, 1, 0),
                BackgroundColor3 = typeof(cfg.Color) == "Color3" and cfg.Color or theme.Accent,
                BorderSizePixel = 0,
                Parent = track,
            })
            corner(fill, GEO.RailH / 2)

            local bar = { Value = value, Min = min, Max = max }
            local destroyed = false
            local function render(animate)
                local fraction = math.clamp((value - min) / (max - min), 0, 1)
                bar.Value = value
                bar.Min = min
                bar.Max = max
                if showValue then
                    if type(cfg.Format) == "function" then
                        local ok, text = pcall(cfg.Format, value, fraction)
                        if destroyed then return end
                        display.Text = ok and tostring(text) or ctx.fmtNum(value)
                    elseif cfg.Suffix ~= nil then
                        display.Text = ctx.fmtNum(value) .. tostring(cfg.Suffix)
                    else
                        display.Text = tostring(math.floor(fraction * 100 + 0.5)) .. "%"
                    end
                end
                local size = UDim2.fromScale(fraction, 1)
                if animate and duration > 0 then
                    tween(fill, duration, { Size = size }, Enum.EasingStyle.Quart)
                else
                    killTween(fill, "Size")
                    fill.Size = size
                end
            end

            function bar:Set(nextValue, animate)
                if destroyed then return end
                nextValue = finiteNumber(nextValue)
                if nextValue == nil then return end
                nextValue = math.clamp(nextValue, min, max)
                if value == nextValue and animate ~= false then return end
                value = nextValue
                render(animate ~= false)
            end

            function bar:SetRange(mn, mx)
                if destroyed then return false end
                mn, mx = finiteNumber(mn), finiteNumber(mx)
                if not mn or not mx or mx <= mn or not finiteNumber(mx - mn) then return false end
                min, max = mn, mx
                value = math.clamp(value, min, max)
                render(false)
                return true
            end

            function bar:SetText(text)
                if destroyed then return end
                label.Text = tostring(text or "")
                ctx.registerSearch(row, label.Text, section)
            end

            function bar:SetColor(color)
                if destroyed or typeof(color) ~= "Color3" then return end
                fill.BackgroundColor3 = color
            end

            row.Destroying:Connect(function()
                destroyed = true
                killTween(fill, "Size")
            end)
            render(false)
            ctx.registerSearch(row, label.Text, section)
            local function setEnabled(enabled)
                ctx.setRowDim(row, face, not enabled)
                label.TextTransparency = enabled and 0 or 0.5
                display.TextTransparency = enabled and 0 or 0.5
                track.BackgroundTransparency = enabled and 0 or 0.6
                fill.BackgroundTransparency = enabled and 0 or 0.6
            end
            return ctx.finishElement("ProgressBar", bar, cfg, row, { row }, nil, setEnabled)
        end

        return addProgressBar
    end
end)()

Components.Slider = (function()
    return function(ctx)
        local inputRouter = ctx.input
        local rnd = ctx.rnd
        local clamp = ctx.clamp
        local toWidth = ctx.toWidth
        local New = ctx.New
        local corner = ctx.corner
        local fmtNum = ctx.fmtNum
        local theme = ctx.theme
        local GEO = ctx.GEO
        local F = ctx.F
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

            local function finiteNumber(raw)
                local value = tonumber(raw)
                if value and value == value and math.abs(value) < math.huge then return value end
            end

            local min = finiteNumber(cfg.Min) or 0
            local max = finiteNumber(cfg.Max) or 100
            if max <= min then max = min + 1 end
            if max <= min or not finiteNumber(max - min) then min, max = 0, 100 end
            local step = finiteNumber(cfg.Step) or 1
            if step <= 0 then step = 1 end

            local function snap(raw)
                raw = clamp(raw, min, max)
                local units = (raw - min) / step
                if not finiteNumber(units) then return raw end
                return clamp(min + rnd(units) * step, min, max)
            end

            local value = snap(finiteNumber(cfg.Value) or min)
            local suffix = tostring(cfg.Suffix or "")
            local sld = { Value = value }

            local function render()
                sld.Value = value
                if type(cfg.Format) == "function" then
                    val.Text = tostring(cfg.Format(value))
                else
                    val.Text = fmtNum(value) .. suffix
                end

                local width = track.AbsoluteSize.X
                if width < GEO.HandleD then return end
                local progress = (value - min) / (max - min)
                local offset = rnd(progress * width)
                fill.Size = UDim2.new(0, offset, 0, GEO.RailH)
                handle.Position = UDim2.new(0, clamp(offset - GEO.HandleD / 2, 0, width - GEO.HandleD), 0, (GEO.SliderTrackH - GEO.HandleD) / 2)
            end
            track:GetPropertyChangedSignal("AbsoluteSize"):Connect(render)
            render()

            local disabled = false
            local function fromX(x)
                local tw = track.AbsoluteSize.X
                if tw < 1 then return end
                local p = clamp((x - track.AbsolutePosition.X) / tw, 0, 1)
                local nextValue = snap(min + (max - min) * p)
                if nextValue == value then return end
                value = nextValue
                render()
                if cfg.Callback then cfg.Callback(value) end
            end
            track.InputBegan:Connect(function(input)
                if disabled then return end
                if inputRouter.Begin(row, input, function(movement)
                    fromX(movement.Position.X)
                end) then
                    fromX(input.Position.X)
                end
            end)
            registerSearch(row, cfg.Text, section)

            function sld:Set(v, fire)
                local number = finiteNumber(v)
                if number == nil then return end
                value = snap(number)
                sld.Value = value
                render()
                if fire and cfg.Callback then cfg.Callback(value) end
            end
            function sld:SetRange(mn, mx)
                mn = finiteNumber(mn)
                mx = finiteNumber(mx)
                if mn == nil or mx == nil or mx <= mn or not finiteNumber(mx - mn) then return false end
                min = mn
                max = mx
                value = snap(clamp(value, min, max))
                sld.Value = value
                render()
                return true
            end
            local function setEnabled(v)
                disabled = not v
                if disabled then inputRouter.Cancel(row) end
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
        local completed = ctx.completed
        local measureText = ctx.measureText
        local theme = ctx.theme
        local GEO = ctx.GEO
        local F = ctx.F
        local icon = ctx.icon
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

            local options = type(cfg.Options) == "table" and table.clone(cfg.Options) or {}
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
                for _, value in ipairs(type(cfg.Value) == "table" and cfg.Value or {}) do
                    sel[tostring(value)] = true
                end
                dd = { Value = {} }
            else
                local initial = cfg.Value
                if initial == nil then initial = options[1] end
                if initial == nil then initial = "" end
                dd = { Value = initial }
            end
            local popH = 10 + math.max(#options, 1) * GEO.OptH
            local pop = New("Frame", {
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
            dd._open = false
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
            local function isSelected(text)
                if multi then return sel[text] == true end
                return text == tostring(dd.Value)
            end

            local function refreshChecks()
                for _, option in ipairs(optBtns) do
                    local selected = isSelected(option._text)
                    option._chk.Visible = selected
                    option._txt.TextColor3 = selected and theme.Text or theme.TextMuted
                end
            end

            local displayedText = nil
            local function syncAll()
                if multi then syncValue() end
                refreshChecks()
                local text = displayText()
                if displayedText == text then return end
                displayedText = text
                val.Text = text
                local width = clamp(measureText(text, 13, F.Medium), 24, 160)
                if displayedText ~= text then return end
                val.Size = UDim2.new(0, width, 0, 16)
                lbl.Size = UDim2.new(1, -(GEO.RowPad + 47 + width), 0, 16)
            end

            local function emitSelection()
                if not cfg.Callback then return end
                cfg.Callback(multi and table.clone(dd.Value) or dd.Value)
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
                        pop.Position = UDim2.new(0, x, 0, y + offset)
                    end
                    pop.Visible = true
                    tween(pop, 0.22, { Position = UDim2.new(0, x, 0, y) }, Enum.EasingStyle.Quart)
                    tween(chev, 0.20, { Rotation = 180 }, Enum.EasingStyle.Quart)
                    registerPop(row, pop, setOpen, cappedH)
                else
                    local pos = pop.Position
                    local offset = pos.Y.Offset < row.AbsolutePosition.Y and 6 or -6
                    local exit = tween(pop, 0.15, { Position = UDim2.new(0, pos.X.Offset, 0, pos.Y.Offset + offset) }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
                    completed(exit, function()
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
                    tween(ot, 0.1, { TextColor3 = isSelected(otext) and theme.Text or theme.TextMuted })
                end)
                ob.Activated:Connect(function()
                    if not dd._open then return end
                    if multi then
                        sel[otext] = not sel[otext] or nil
                    else
                        local original = origOf[otext]
                        if original == nil then original = otext end
                        dd.Value = original
                    end
                    syncAll()
                    if not multi then setOpen(false) end
                    emitSelection()
                end)
                table.insert(optBtns, { _btn = ob, _txt = ot, _chk = chk, _text = otext })
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
                else
                    if v == nil then v = "" end
                    dd.Value = v
                end
                syncAll()
                if not multi then setOpen(false) end
                if fire then emitSelection() end
            end
            function dd:SetOptions(opts)
                if type(opts) ~= "table" then return end
                local unchanged = #opts == #options
                if unchanged then
                    for index, option in ipairs(options) do
                        if opts[index] ~= option then
                            unchanged = false
                            break
                        end
                    end
                end
                setOpen(false)
                if unchanged then return end
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
                    if not found then
                        local first = options[1]
                        if first == nil then first = "" end
                        dd.Value = first
                    end
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
                local searchText = tostring(cfg.Text or "")
                if #optTexts > 0 then searchText = searchText .. " " .. table.concat(optTexts, " ") end
                registerSearch(row, searchText, section)
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
                if not row.Parent then return end
                local w = rnd(math.max(GEO.ChipMinW, measureText(txt.Text, 11, F.Mono) + 18))
                chip.Size = UDim2.new(0, w, 0, GEO.ChipH)
                lbl.Size = UDim2.new(1, -(GEO.RowPad + 22 + w), 0, 16)
            end
            txt:GetPropertyChangedSignal("Text"):Connect(fitChip)
            task.defer(fitChip)

            local mode = tostring(cfg.Mode or "Always")
            if mode ~= "Toggle" and mode ~= "Hold" then mode = "Always" end
            local initial = type(cfg.Value) == "string" and cfg.Value or "None"
            local initialCode, initialInput = bindFromString(initial)
            if not initialCode and not initialInput then initial = "None" end
            txt.Text = initial
            local kb = {
                Name = initial,
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
            row.Destroying:Connect(function()
                if pulseTween then
                    pulseTween:Cancel()
                    pulseTween = nil
                end
            end)

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
                    else
                        startListen()
                    end
                end
            end)

            table.insert(state.keybinds, kb)
            kb.Chip = chip
            registerSearch(row, cfg.Text, section)

            function kb:Set(name)
                if type(name) ~= "string" then return end
                local code, uit = bindFromString(name)
                if name ~= "None" and not code and not uit then return end
                if state.listening == kb then cancelListen() end
                kb.Name = name
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
        local inputRouter = ctx.input
        local rnd = ctx.rnd
        local clamp = ctx.clamp
        local toWidth = ctx.toWidth
        local New = ctx.New
        local corner = ctx.corner
        local padding = ctx.padding
        local tween = ctx.tween
        local completed = ctx.completed
        local measureText = ctx.measureText
        local colorToHex = ctx.colorToHex
        local hexToColor = ctx.hexToColor
        local theme = ctx.theme
        local GEO = ctx.GEO
        local F = ctx.F
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
            local pop = New("Frame", {
                ClipsDescendants = true,
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

            local startColor = hexToColor(cfg.Value) or theme.Accent
            local h, s, v = Color3.toHSV(startColor)
            local cp = { Hex = colorToHex(startColor) }

            local renderedHue
            local function render(fire)
                local color = Color3.fromHSV(h, s, v)
                local hex = colorToHex(color)
                if renderedHue ~= h then
                    renderedHue = h
                    svGrad.Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromHSV(h, 1, 1))
                    hdot.Position = UDim2.new(0, -2, 0, clamp(rnd(h * GEO.SVH) - 9, 0, GEO.SVH - 18))
                end
                local svw = GEO.PopW - 22 - GEO.HueW - 10
                dot.Position = UDim2.new(0, clamp(rnd(s * svw) - 7, 0, svw - 14), 0, clamp(rnd((1 - v) * GEO.SVH) - 7, 0, GEO.SVH - 14))
                swatchFace.BackgroundColor3 = color
                previewFace.BackgroundColor3 = color
                if hexLbl.Text ~= hex then
                    hexLbl.Text = hex
                    hexVal.Text = hex
                end
                cp.Hex = hex
                cp.Color = color
                if fire and cfg.Callback then cfg.Callback(hex, color) end
            end

            local open = false
            local function bindPad(el, apply)
                el.InputBegan:Connect(function(input)
                    if not open then return end
                    if inputRouter.Begin(row, input, apply) then
                        apply(input)
                    end
                end)
            end
            local function applySV(input)
                local r, sz = sv.AbsolutePosition, sv.AbsoluteSize
                if sz.X < 1 or sz.Y < 1 then return end
                local saturation = clamp((input.Position.X - r.X) / sz.X, 0, 1)
                local brightness = 1 - clamp((input.Position.Y - r.Y) / sz.Y, 0, 1)
                if s == saturation and v == brightness then return end
                s, v = saturation, brightness
                render(true)
            end
            local function applyHue(input)
                local r, sz = hue.AbsolutePosition, hue.AbsoluteSize
                if sz.Y < 1 then return end
                local hueValue = clamp((input.Position.Y - r.Y) / sz.Y, 0, 1)
                if h == hueValue then return end
                h = hueValue
                render(true)
            end
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
                        pop.Position = UDim2.new(0, x, 0, y + direction * 6)
                    end
                    pop.Visible = true
                    tween(pop, 0.22, { Position = UDim2.new(0, x, 0, y) }, Enum.EasingStyle.Quart)
                    registerPop(row, pop, setOpen, cappedH, GEO.PopW, true)
                else
                    inputRouter.Cancel(row)
                    unregisterPop(pop)
                    local pos = pop.Position
                    local exit = tween(pop, 0.15, { Position = UDim2.new(0, pos.X.Offset, 0, pos.Y.Offset + direction * 4) }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
                    completed(exit, function()
                        if generation == transition and not open and pop.Parent then
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
                local color = hexToColor(hex)
                if not color then return end
                h, s, v = Color3.toHSV(color)
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
        local killTween = ctx.killTween
        local measureText = ctx.measureText
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
            local minWidth = 72
            local gap = 10
            local lbl = rowLabel(row, cfg.Text, minWidth + GEO.RowPad + gap)

            local field = New("Frame", {
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, -GEO.RowPad, 0.5, 0),
                Size = UDim2.new(0, minWidth, 0, GEO.FieldH),
                BackgroundTransparency = 1,
                ClipsDescendants = true,
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
                Text = cfg.Value == nil and "" or tostring(cfg.Value),
                PlaceholderText = tostring(cfg.Placeholder or ""),
                PlaceholderColor3 = theme.TextFaint,
                FontFace = F.Regular,
                TextSize = 13,
                TextColor3 = theme.Text,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextWrapped = false,
                ClearTextOnFocus = false,
                ClipsDescendants = true,
                ZIndex = 2,
                Parent = field,
            })
            corner(box, 6)
            padding(box, 0, 10, 0, 10)

            local desiredWidth = minWidth
            local targetWidth = minWidth
            local measurementVersion = 0
            local measurementQueued = false
            local destroyed = false

            local function maximumWidth()
                local width = row.AbsoluteSize.X
                if width <= 0 then return GEO.FieldW end
                local available = math.max(0, width - GEO.RowPad * 2 - gap)
                local labelReserve = math.min(64, available * 0.5)
                return math.max(0, math.floor(math.min(GEO.FieldW, available * 0.48, available - labelReserve)))
            end

            local function updateLabel()
                local reserved = field.Size.X.Offset + GEO.RowPad * 2 + gap
                lbl.Size = UDim2.new(1, -reserved, 0, 16)
            end

            local function updateWidth(animate)
                if destroyed or not row.Parent then return end
                local limit = maximumWidth()
                local width = math.min(limit, math.max(minWidth, desiredWidth))
                if width == targetWidth and field.Size.X.Offset <= limit then return end
                targetWidth = width
                local size = UDim2.new(0, width, 0, GEO.FieldH)
                if animate and field.Size.X.Offset <= limit then
                    tween(field, 0.18, { Size = size }, Enum.EasingStyle.Quart)
                else
                    killTween(field, "Size")
                    field.Size = size
                    updateLabel()
                end
            end

            local function queueMeasurement()
                measurementVersion = measurementVersion + 1
                if measurementQueued or destroyed then return end
                measurementQueued = true
                task.defer(function()
                    measurementQueued = false
                    if destroyed or not row.Parent then return end
                    local version = measurementVersion
                    local text = box.Text
                    local width = minWidth
                    if text ~= "" then
                        width = math.ceil(measureText(text, box.TextSize, box.FontFace)) + 24
                    end
                    if destroyed or not row.Parent or version ~= measurementVersion then return end
                    desiredWidth = math.clamp(width, minWidth, GEO.FieldW)
                    updateWidth(true)
                end)
            end

            field:GetPropertyChangedSignal("Size"):Connect(updateLabel)
            row:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
                updateWidth(false)
            end)
            row.Destroying:Connect(function()
                destroyed = true
                measurementVersion = measurementVersion + 1
                killTween(field, "Size")
            end)
            updateLabel()
            updateWidth(false)
            queueMeasurement()

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
                dbGen = dbGen + 1
                inp.Text = text == nil and "" or tostring(text)
                box.Text = inp.Text
            end
            box:GetPropertyChangedSignal("Text"):Connect(function()
                queueMeasurement()
                if inp.Text == box.Text then return end
                inp.Text = box.Text
                if cfg.Live and cfg.Callback then
                    if debounce then
                        dbGen = dbGen + 1
                        local g = dbGen
                        task.delay(debounce, function()
                            if g == dbGen and row.Parent and cfg.Callback then
                                cfg.Callback(box.Text, false)
                            end
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
                    dbGen = dbGen + 1
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
                lbl.Text = tostring(text or "")
                registerSearch(lbl, lbl.Text, section)
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
                local total = (lbl and 32 or 10) + sumH + math.max(0, n - 1) * 2
                local height = clamp(total, baseH, maxH)
                if row.Size.Y.Offset ~= height then
                    row.Size = UDim2.new(1, 0, 0, height)
                end
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
                local trailingWidth = trailing and rnd(measureText(trailing, 11, F.Regular)) or 0
                local trailRes = trailing and trailingWidth + 14 or 0
                local prim = New("TextLabel", {
                    AnchorPoint = secondary and Vector2.new(0, 0) or Vector2.new(0, 0.5),
                    Position = secondary and UDim2.new(0, tx0, 0, 5) or UDim2.new(0, tx0, 0.5, 0),
                    Size = UDim2.new(1, -(tx0 + 12 + trailRes), 0, 16),
                    BackgroundTransparency = 1,
                    FontFace = F.Medium,
                    TextSize = 13,
                    TextColor3 = theme.TextMuted,
                    TextTransparency = lstDisabled and 0.5 or 0,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextTruncate = Enum.TextTruncate.AtEnd,
                    Text = primary,
                    ZIndex = 2,
                    Parent = ob,
                })
                if secondary then
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
                end
                if trailing then
                    New("TextLabel", {
                        AnchorPoint = Vector2.new(1, 0.5),
                        Position = UDim2.new(1, -10, 0.5, 0),
                        Size = UDim2.new(0, trailingWidth + 4, 0, 14),
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
                return #items
            end

            function lst:Add(item)
                local index = buildItem(item)
                fitHeight()
                return index
            end
            function lst:Remove(index)
                if type(index) ~= "number" or index ~= index or math.abs(index) == math.huge then return false end
                index = math.floor(index)
                if index < 1 or index > #items then return false end
                local rec = items[index]
                table.remove(items, index)
                sumH = sumH - rec.h
                if selectedRec == rec then
                    selectedRec = nil
                end
                lst.Selected = selectedRec and indexOf(selectedRec) or nil
                rec.frame:Destroy()
                fitHeight()
                return true
            end
            local function clearItems()
                for _, rec in ipairs(items) do
                    rec.frame:Destroy()
                end
                items = {}
                sumH = 0
                selectedRec = nil
                lst.Selected = nil
                nextOrder = 1
            end
            function lst:Clear()
                clearItems()
                fitHeight()
            end
            function lst:SetItems(t)
                clearItems()
                if type(t) == "table" then
                    for _, item in ipairs(t) do
                        buildItem(item)
                    end
                end
                fitHeight()
            end
            function lst:SetSelected(index, fire)
                if index == nil then
                    selectRec(nil, fire and true or false)
                    return
                end
                if type(index) ~= "number" or index ~= index or math.abs(index) == math.huge then return end
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
            if gap ~= gap or math.abs(gap) == math.huge then gap = GEO.GridGap end
            gap = math.max(0, gap)
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
            local function layoutCells()
                local count = #r._cells
                if count == 0 then return end
                local flexible = 0
                local fixedScale, fixedOffset = 0, 0
                for _, cell in ipairs(r._cells) do
                    if cell.fixed then
                        fixedScale = fixedScale + cell.frame.Size.X.Scale
                        fixedOffset = fixedOffset + cell.frame.Size.X.Offset
                    else
                        flexible = flexible + 1
                    end
                end

                local availableScale = math.max(0, 1 - fixedScale)
                local reserved = fixedOffset + gap * (count - 1)
                local width = container.AbsoluteSize.X
                local scale = flexible > 0 and availableScale / flexible or 0
                local offset = flexible > 0 and -rnd(reserved / flexible) or 0
                if width > 0 and width * scale + offset < 0 then
                    scale, offset = 0, 0
                end
                for index, cell in ipairs(r._cells) do
                    cell.frame.LayoutOrder = index
                    if not cell.fixed then
                        cell.frame.Size = UDim2.new(scale, offset, 0, cell.frame.Size.Y.Offset)
                    end
                end
            end

            local function addCell(el, config)
                local cell = { frame = el._row, fixed = config and config.Width ~= nil or false }
                table.insert(r._children, el)
                table.insert(r._cells, cell)
                cell.frame.Destroying:Connect(function()
                    local index = table.find(r._cells, cell)
                    if index then table.remove(r._cells, index) end
                    index = table.find(r._children, el)
                    if index then table.remove(r._children, index) end
                    if container.Parent then layoutCells() end
                end)
                layoutCells()
            end
            container:GetPropertyChangedSignal("AbsoluteSize"):Connect(layoutCells)

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
                for _, child in ipairs(table.clone(r._children)) do
                    child:Destroy()
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
    _widgets = {},
    _configs = {},
}

Reborn.Theme = Theme.Default
local Core = createCore(Theme, createAnimation)
local Icons = createIcons(Core)
local Notifications = createNotifications(Reborn, Core, Theme, Icons)
createWindow(Reborn, Core, Theme, Icons, Notifications, Components, attachConfig, createNavigation, createPopovers, createLifecycle, createInput, createComponentContext, bindKeybinds, createTooltip, createPillLayout)
createWidget(Reborn, Core, Theme, Icons, Notifications, Components, attachConfig, createPopovers, createLifecycle, createInput, createComponentContext, bindKeybinds, createTooltip)

function Reborn:Unload()
    for _, widget in ipairs(table.clone(self._widgets)) do
        pcall(function() widget:Destroy() end)
    end
    table.clear(self._widgets)
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
