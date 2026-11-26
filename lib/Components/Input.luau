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
