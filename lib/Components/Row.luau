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
