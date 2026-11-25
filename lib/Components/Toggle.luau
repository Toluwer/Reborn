return function(ctx)
    local toWidth = ctx.toWidth
    local New = ctx.New
    local corner = ctx.corner
    local tween = ctx.tween
    local theme = ctx.theme
    local GEO = ctx.GEO
    local makeRow = ctx.makeRow
    local setRowDim = ctx.setRowDim
    local rowLabel = ctx.rowLabel
    local overlayBtn = ctx.overlayBtn
    local registerSearch = ctx.registerSearch
    local finishElement = ctx.finishElement

    local function addToggle(section, cfg)
        cfg = cfg or {}
        local row, face = makeRow(section, GEO.RowH, toWidth(cfg.Width, nil))
        local lbl = rowLabel(row, cfg.Text, 66)
        local btn = overlayBtn(row)

        local track = New("Frame", {
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -GEO.RowPad, 0.5, 0),
            Size = UDim2.new(0, GEO.SwitchW, 0, GEO.SwitchH),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ZIndex = 5,
            Parent = row,
        })
        corner(track, GEO.SwitchH / 2)
        local trackFace = New("Frame", {
            Position = UDim2.new(0, 0, 0, 0),
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundColor3 = theme.ToggleOff,
            BorderSizePixel = 0,
            Parent = track,
        })
        corner(trackFace, GEO.SwitchH / 2)
        local knob = New("Frame", {
            Position = UDim2.new(0, 3, 0, 3),
            Size = UDim2.new(0, GEO.Knob, 0, GEO.Knob),
            BackgroundColor3 = theme.Handle,
            BorderSizePixel = 0,
            ZIndex = 6,
            Parent = track,
        })
        corner(knob, GEO.Knob / 2)

        local value = cfg.Value and true or false
        local tog = { Value = value }

        local function render(fire, instant)
            local nx = value and (GEO.SwitchW - GEO.Knob - 3) or 3
            local c = value and theme.Accent or theme.ToggleOff
            if instant then
                knob.Position = UDim2.new(0, nx, 0, 3)
                trackFace.BackgroundColor3 = c
            else
                tween(knob, 0.16, { Position = UDim2.new(0, nx, 0, 3) })
                tween(trackFace, 0.16, { BackgroundColor3 = c })
            end
            tog.Value = value
            if fire and cfg.Callback then cfg.Callback(value) end
        end
        local disabled = false
        btn.Activated:Connect(function()
            if disabled then return end
            value = not value
            render(true)
        end)
        render(false, true)
        registerSearch(row, cfg.Text, section)

        function tog:Set(v, fire)
            value = v and true or false
            render(fire and true or false)
        end
        local function setEnabled(v)
            disabled = not v
            setRowDim(row, face, disabled)
            lbl.TextTransparency = disabled and 0.5 or 0
            if disabled then
                knob.BackgroundTransparency = 0.45
                trackFace.BackgroundTransparency = 0.45
            else
                knob.BackgroundTransparency = 0
                trackFace.BackgroundTransparency = 0
                render(false, true)
            end
        end
        return finishElement("Toggle", tog, cfg, row, { btn }, nil, setEnabled)
    end

    return addToggle
end
