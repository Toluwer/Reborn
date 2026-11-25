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
