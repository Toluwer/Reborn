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
