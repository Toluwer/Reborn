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
            if type(index) ~= "number" then return false end
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
