return function(ctx)
    local UserInputService = ctx.UserInputService
    local rnd = ctx.rnd
    local clamp = ctx.clamp
    local toWidth = ctx.toWidth
    local New = ctx.New
    local corner = ctx.corner
    local fmtNum = ctx.fmtNum
    local theme = ctx.theme
    local GEO = ctx.GEO
    local F = ctx.F
    local connect = ctx.connect
    local makeRow = ctx.makeRow
    local setRowDim = ctx.setRowDim
    local registerSearch = ctx.registerSearch
    local finishElement = ctx.finishElement

    local function addSlider(section, cfg)
        cfg = cfg or {}
        local row, face = makeRow(section, GEO.SliderH, toWidth(cfg.Width, nil))

        local top = New("Frame", {
            Position = UDim2.new(0, GEO.RowPad, 0, 10),
            Size = UDim2.new(1, -GEO.RowPad * 2, 0, 16),
            BackgroundTransparency = 1,
            Parent = row,
        })
        local lblTop = New("TextLabel", {
            Size = UDim2.new(1, -80, 1, 0),
            BackgroundTransparency = 1,
            FontFace = F.Medium,
            TextSize = 13,
            TextColor3 = theme.Text,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Text = tostring(cfg.Text or ""),
            Parent = top,
        })
        local val = New("TextLabel", {
            AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, 0, 0, 0),
            Size = UDim2.new(0, 74, 1, 0),
            BackgroundTransparency = 1,
            FontFace = F.Medium,
            TextSize = 12,
            TextColor3 = theme.TextMuted,
            TextXAlignment = Enum.TextXAlignment.Right,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Text = "",
            Parent = top,
        })

        local track = New("TextButton", {
            Position = UDim2.new(0, GEO.RowPad, 0, 34),
            Size = UDim2.new(1, -GEO.RowPad * 2, 0, GEO.SliderTrackH),
            BackgroundTransparency = 1,
            Text = "",
            AutoButtonColor = false,
            Parent = row,
        })
        local rail = New("Frame", {
            Position = UDim2.new(0, 0, 0, (GEO.SliderTrackH - GEO.RailH) / 2),
            Size = UDim2.new(1, 0, 0, GEO.RailH),
            BackgroundColor3 = theme.LineStrong,
            BorderSizePixel = 0,
            Parent = track,
        })
        corner(rail, GEO.RailH / 2)
        local fill = New("Frame", {
            Position = UDim2.new(0, 0, 0, (GEO.SliderTrackH - GEO.RailH) / 2),
            Size = UDim2.new(0, 0, 0, GEO.RailH),
            BackgroundColor3 = theme.Accent,
            BorderSizePixel = 0,
            Parent = track,
        })
        corner(fill, GEO.RailH / 2)
        local handle = New("Frame", {
            Position = UDim2.new(0, 0, 0, (GEO.SliderTrackH - GEO.HandleD) / 2),
            Size = UDim2.new(0, GEO.HandleD, 0, GEO.HandleD),
            BackgroundColor3 = theme.Handle,
            BorderSizePixel = 0,
            ZIndex = 2,
            Parent = track,
        })
        corner(handle, GEO.HandleD / 2)

        local min = tonumber(cfg.Min) or 0
        local max = tonumber(cfg.Max) or 100
        if max <= min then max = min + 1 end
        local step = tonumber(cfg.Step) or 1
        if step <= 0 then step = 1 end
        local function snap(raw)
            return clamp(min + rnd((raw - min) / step) * step, min, max)
        end
        local value = snap(tonumber(cfg.Value) or min)
        local suffix = cfg.Suffix or ""
        local sld = { Value = value }

        local function render()
            sld.Value = value
            if type(cfg.Format) == "function" then
                val.Text = tostring(cfg.Format(value))
            else
                val.Text = fmtNum(value) .. suffix
            end

            local width = track.AbsoluteSize.X
            if width < GEO.HandleD then return end
            local progress = (value - min) / (max - min)
            local offset = rnd(progress * width)
            fill.Size = UDim2.new(0, offset, 0, GEO.RailH)
            handle.Position = UDim2.new(0, clamp(offset - GEO.HandleD / 2, 0, width - GEO.HandleD), 0, (GEO.SliderTrackH - GEO.HandleD) / 2)
        end
        track:GetPropertyChangedSignal("AbsoluteSize"):Connect(render)
        render()

        local dragging = false
        local disabled = false
        local function fromX(x)
            local tw = track.AbsoluteSize.X
            if tw < 1 then return end
            local p = clamp((x - track.AbsolutePosition.X) / tw, 0, 1)
            local nextValue = snap(min + (max - min) * p)
            if nextValue == value then return end
            value = nextValue
            render()
            if cfg.Callback then cfg.Callback(value) end
        end
        track.InputBegan:Connect(function(input)
            if disabled then return end
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                fromX(input.Position.X)
            end
        end)
        connect(row, UserInputService.InputChanged, function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                fromX(input.Position.X)
            end
        end)
        connect(row, UserInputService.InputEnded, function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end)
        registerSearch(row, cfg.Text, section)

        function sld:Set(v, fire)
            value = snap(tonumber(v) or min)
            sld.Value = value
            render()
            if fire and cfg.Callback then cfg.Callback(value) end
        end
        function sld:SetRange(mn, mx)
            mn = tonumber(mn)
            mx = tonumber(mx)
            if mn == nil or mx == nil or mx <= mn then return false end
            min = mn
            max = mx
            value = snap(clamp(value, min, max))
            sld.Value = value
            render()
            return true
        end
        local function setEnabled(v)
            disabled = not v
            if disabled then dragging = false end
            setRowDim(row, face, disabled)
            lblTop.TextTransparency = disabled and 0.5 or 0
            val.TextTransparency = disabled and 0.5 or 0
            rail.BackgroundTransparency = disabled and 0.6 or 0
            fill.BackgroundTransparency = disabled and 0.6 or 0
            handle.BackgroundTransparency = disabled and 0.55 or 0
        end
        return finishElement("Slider", sld, cfg, row, { track }, nil, setEnabled)
    end

    return addSlider
end
