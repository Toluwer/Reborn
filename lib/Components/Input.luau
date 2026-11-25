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
