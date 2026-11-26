return function(Reborn, Core, Theme, Icons, Notifications, Components, attachConfig, createNavigation, createPopovers, createLifecycle, createInput, createComponentContext, bindKeybinds, createTooltip)
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
    local MARK = Core.MARK
    local randomName = Core.randomName
    local nextOrder = Core.nextOrder
    local protectGui = Core.protectGui
    local clearOld = Core.clearOld
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
        for i = #Reborn._windows, 1, -1 do
            local existing = Reborn._windows[i]
            if not existing.Gui or existing.Gui.Parent == nil or existing.Gui.Parent == parent then
                existing:Destroy()
            end
        end
        clearOld(parent)

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
        local function snapPillRest()
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
                killTween(windowFrame, "GroupTransparency")
                windowFrame.GroupTransparency = 0
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
                local v = viewportSize()
                local tw = pillRestW + 2
                local morph = tween(windowFrame, 0.36, {
                    Size = UDim2.new(0, tw, 0, GEO.PillH + 2),
                    Position = UDim2.new(0, rnd(v.X / 2 - tw / 2), 0, 13),
                }, Enum.EasingStyle.Quint)
                tween(winCorner, 0.36, { CornerRadius = UDim.new(0, GEO.PillH / 2 + 1) }, Enum.EasingStyle.Quint)
                tween(faceCorner, 0.36, { CornerRadius = UDim.new(0, GEO.PillH / 2) }, Enum.EasingStyle.Quint)
                tween(windowFrame, 0.24, { BackgroundColor3 = theme.Surface })
                completed(morph, function()
                    if generation == morphGeneration and state.min and not state.destroyed and windowFrame.Parent then
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
                windowFrame.GroupTransparency = 1
                return
            end
            local exit = tween(windowFrame, 0.20, { GroupTransparency = 1 }, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
            completed(exit, function()
                if state.closed and state.closeGeneration == generation and not state.destroyed and windowFrame.Parent then
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
            killTween(windowFrame, "GroupTransparency")
            windowFrame.Visible = true
            tween(windowFrame, 0.22, { GroupTransparency = 0 }, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
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
            local exit = tween(card, 0.15, { Position = UDim2.new(0.5, 0, 0.5, 8), GroupTransparency = 1 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
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
            confirmGeneration = confirmGeneration + 1
            card.Size = UDim2.new(0, math.min(420, W - 48), 0, 156)
            if not card.Visible then
                scrim.BackgroundTransparency = 1
                card.Position = UDim2.new(0.5, 0, 0.5, 8)
                card.GroupTransparency = 1
            end
            scrim.Visible = true
            card.Visible = true
            tween(scrim, 0.20, { BackgroundTransparency = 0.42 })
            tween(card, 0.23, { Position = UDim2.new(0.5, 0, 0.5, 0), GroupTransparency = 0 }, Enum.EasingStyle.Quart)
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
