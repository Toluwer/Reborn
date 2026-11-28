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
