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
