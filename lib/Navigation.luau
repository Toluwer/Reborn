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
