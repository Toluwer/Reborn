return function(ctx)
    local inputRouter = ctx.input
    local rnd = ctx.rnd
    local clamp = ctx.clamp
    local toWidth = ctx.toWidth
    local New = ctx.New
    local corner = ctx.corner
    local padding = ctx.padding
    local tween = ctx.tween
    local completed = ctx.completed
    local measureText = ctx.measureText
    local colorToHex = ctx.colorToHex
    local hexToColor = ctx.hexToColor
    local theme = ctx.theme
    local GEO = ctx.GEO
    local F = ctx.F
    local closeAllPops = ctx.closeAllPops
    local registerPop = ctx.registerPop
    local unregisterPop = ctx.unregisterPop
    local mountPop = ctx.mountPop
    local makeRow = ctx.makeRow
    local setRowDim = ctx.setRowDim
    local rowLabel = ctx.rowLabel
    local registerSearch = ctx.registerSearch
    local finishElement = ctx.finishElement

    local function addColorPicker(section, cfg)
        cfg = cfg or {}
        local row, face = makeRow(section, GEO.RowH, toWidth(cfg.Width, nil))
        local hexW = rnd(math.max(44, measureText(colorToHex(theme.Accent), 12, F.Mono)))
        local lbl = rowLabel(row, cfg.Text, hexW + 9 + GEO.Swatch + 22)

        local trigger = New("TextButton", {
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -GEO.RowPad, 0.5, 0),
            Size = UDim2.new(0, hexW + 9 + GEO.Swatch, 0, GEO.Swatch),
            BackgroundTransparency = 1,
            Text = "",
            AutoButtonColor = false,
            ZIndex = 5,
            Parent = row,
        })
        local hexLbl = New("TextLabel", {
            Size = UDim2.new(0, hexW, 1, 0),
            BackgroundTransparency = 1,
            FontFace = F.Mono,
            TextSize = 12,
            TextColor3 = theme.TextMuted,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Text = colorToHex(theme.Accent),
            ZIndex = 6,
            Parent = trigger,
        })
        local swatch = New("Frame", {
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, 0, 0.5, 0),
            Size = UDim2.new(0, GEO.Swatch, 0, GEO.Swatch),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ZIndex = 6,
            Parent = trigger,
        })
        corner(swatch, 6)
        local swatchFace = New("Frame", {
            Position = UDim2.new(0, 0, 0, 0),
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundColor3 = theme.Accent,
            BorderSizePixel = 0,
            ZIndex = 1,
            Parent = swatch,
        })
        corner(swatchFace, 6)

        local popH = 22 + GEO.SVH + 10 + GEO.Swatch
        local pop = New("Frame", {
            ClipsDescendants = true,
            AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, -GEO.RowPad, 0, GEO.RowH + 6),
            Size = UDim2.new(0, GEO.PopW, 0, popH),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Visible = false,
            ZIndex = 25,
            Parent = row,
        })
        corner(pop, 6)
        local popFace = New("Frame", {
            Position = UDim2.new(0, 0, 0, 0),
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundColor3 = theme.Overlay,
            BorderSizePixel = 0,
            Parent = pop,
        })
        corner(popFace, 6)
        padding(popFace, 10, 10, 10, 10)

        local sv = New("Frame", {
            Size = UDim2.new(1, -(GEO.HueW + 10), 0, GEO.SVH),
            BackgroundColor3 = Color3.new(0, 0, 0),
            BorderSizePixel = 0,
            Parent = popFace,
        })
        corner(sv, 8)
        local svHue = New("Frame", {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundColor3 = Color3.new(1, 1, 1),
            BorderSizePixel = 0,
            Parent = sv,
        })
        corner(svHue, 8)
        local svGrad = New("UIGradient", {
            Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.new(1, 0, 0)),
            Rotation = 0,
            Parent = svHue,
        })
        local svDark = New("Frame", {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundColor3 = Color3.new(0, 0, 0),
            BorderSizePixel = 0,
            Parent = sv,
        })
        corner(svDark, 8)
        New("UIGradient", {
            Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 1),
                NumberSequenceKeypoint.new(1, 0),
            }),
            Rotation = 90,
            Parent = svDark,
        })
        local dot = New("Frame", {
            Size = UDim2.new(0, 14, 0, 14),
            BackgroundColor3 = Color3.new(0, 0, 0),
            BorderSizePixel = 0,
            ZIndex = 3,
            Parent = sv,
        })
        corner(dot, 7)
        local dotFace = New("Frame", {
            Position = UDim2.new(0, 1, 0, 1),
            Size = UDim2.new(1, -2, 1, -2),
            BackgroundColor3 = Color3.new(1, 1, 1),
            BorderSizePixel = 0,
            Parent = dot,
        })
        corner(dotFace, 6)

        local hue = New("Frame", {
            AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, 0, 0, 0),
            Size = UDim2.new(0, GEO.HueW, 0, GEO.SVH),
            BackgroundColor3 = Color3.new(1, 1, 1),
            BorderSizePixel = 0,
            Parent = popFace,
        })
        corner(hue, 7)
        New("UIGradient", {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 0, 0)),
                ColorSequenceKeypoint.new(1 / 6, Color3.fromRGB(255, 255, 0)),
                ColorSequenceKeypoint.new(2 / 6, Color3.fromRGB(0, 255, 0)),
                ColorSequenceKeypoint.new(3 / 6, Color3.fromRGB(0, 255, 255)),
                ColorSequenceKeypoint.new(4 / 6, Color3.fromRGB(0, 0, 255)),
                ColorSequenceKeypoint.new(5 / 6, Color3.fromRGB(255, 0, 255)),
                ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 0, 0)),
            }),
            Rotation = 90,
            Parent = hue,
        })
        local hdot = New("Frame", {
            Position = UDim2.new(0, -2, 0, 0),
            Size = UDim2.new(0, 18, 0, 18),
            BackgroundColor3 = Color3.new(0, 0, 0),
            BorderSizePixel = 0,
            ZIndex = 3,
            Parent = hue,
        })
        corner(hdot, 9)
        local hdotFace = New("Frame", {
            Position = UDim2.new(0, 1, 0, 1),
            Size = UDim2.new(1, -2, 1, -2),
            BackgroundColor3 = Color3.new(1, 1, 1),
            BorderSizePixel = 0,
            Parent = hdot,
        })
        corner(hdotFace, 8)

        local preview = New("Frame", {
            Position = UDim2.new(0, 0, 0, GEO.SVH + 10),
            Size = UDim2.new(0, GEO.Swatch, 0, GEO.Swatch),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Parent = popFace,
        })
        corner(preview, 6)
        local previewFace = New("Frame", {
            Position = UDim2.new(0, 0, 0, 0),
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundColor3 = theme.Accent,
            BorderSizePixel = 0,
            Parent = preview,
        })
        corner(previewFace, 6)
        New("TextLabel", {
            Position = UDim2.new(0, GEO.Swatch + 10, 0, GEO.SVH + 10),
            Size = UDim2.new(0, 0, 0, GEO.Swatch),
            BackgroundTransparency = 1,
            FontFace = F.Mono,
            TextSize = 11,
            TextColor3 = theme.TextFaint,
            TextXAlignment = Enum.TextXAlignment.Left,
            Text = "HEX",
            Parent = popFace,
        })
        local hexVal = New("TextLabel", {
            AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, 0, 0, GEO.SVH + 10),
            Size = UDim2.new(0, rnd(math.max(52, measureText(colorToHex(theme.Accent), 12, F.Mono))), 0, GEO.Swatch),
            BackgroundTransparency = 1,
            FontFace = F.Mono,
            TextSize = 12,
            TextColor3 = theme.TextMuted,
            TextXAlignment = Enum.TextXAlignment.Right,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Text = colorToHex(theme.Accent),
            Parent = popFace,
        })

        local startColor = hexToColor(cfg.Value) or theme.Accent
        local h, s, v = Color3.toHSV(startColor)
        local cp = { Hex = colorToHex(startColor) }

        local renderedHue
        local function render(fire)
            local color = Color3.fromHSV(h, s, v)
            local hex = colorToHex(color)
            if renderedHue ~= h then
                renderedHue = h
                svGrad.Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromHSV(h, 1, 1))
                hdot.Position = UDim2.new(0, -2, 0, clamp(rnd(h * GEO.SVH) - 9, 0, GEO.SVH - 18))
            end
            local svw = GEO.PopW - 22 - GEO.HueW - 10
            dot.Position = UDim2.new(0, clamp(rnd(s * svw) - 7, 0, svw - 14), 0, clamp(rnd((1 - v) * GEO.SVH) - 7, 0, GEO.SVH - 14))
            swatchFace.BackgroundColor3 = color
            previewFace.BackgroundColor3 = color
            if hexLbl.Text ~= hex then
                hexLbl.Text = hex
                hexVal.Text = hex
            end
            cp.Hex = hex
            cp.Color = color
            if fire and cfg.Callback then cfg.Callback(hex, color) end
        end

        local open = false
        local function bindPad(el, apply)
            el.InputBegan:Connect(function(input)
                if not open then return end
                if inputRouter.Begin(row, input, apply) then
                    apply(input)
                end
            end)
        end
        local function applySV(input)
            local r, sz = sv.AbsolutePosition, sv.AbsoluteSize
            if sz.X < 1 or sz.Y < 1 then return end
            local saturation = clamp((input.Position.X - r.X) / sz.X, 0, 1)
            local brightness = 1 - clamp((input.Position.Y - r.Y) / sz.Y, 0, 1)
            if s == saturation and v == brightness then return end
            s, v = saturation, brightness
            render(true)
        end
        local function applyHue(input)
            local r, sz = hue.AbsolutePosition, hue.AbsoluteSize
            if sz.Y < 1 then return end
            local hueValue = clamp((input.Position.Y - r.Y) / sz.Y, 0, 1)
            if h == hueValue then return end
            h = hueValue
            render(true)
        end
        bindPad(sv, applySV)
        bindPad(hue, applyHue)

        local transition = 0
        local direction = -1
        local function setOpen(o)
            if open == o then return end
            open = o
            transition = transition + 1
            local generation = transition
            if o then
                closeAllPops(pop)
                local x, y, cappedH = mountPop(row, pop, popH, GEO.PopW, true)
                direction = y < row.AbsolutePosition.Y and 1 or -1
                if not pop.Visible then
                    pop.Position = UDim2.new(0, x, 0, y + direction * 6)
                end
                pop.Visible = true
                tween(pop, 0.22, { Position = UDim2.new(0, x, 0, y) }, Enum.EasingStyle.Quart)
                registerPop(row, pop, setOpen, cappedH, GEO.PopW, true)
            else
                inputRouter.Cancel(row)
                unregisterPop(pop)
                local pos = pop.Position
                local exit = tween(pop, 0.15, { Position = UDim2.new(0, pos.X.Offset, 0, pos.Y.Offset + direction * 4) }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
                completed(exit, function()
                    if generation == transition and not open and pop.Parent then
                        pop.Visible = false
                    end
                end)
            end
        end
        local disabled = false
        trigger.Activated:Connect(function()
            if disabled then return end
            setOpen(not open)
        end)
        registerSearch(row, cfg.Text, section)
        render(false)

        function cp:Set(hex, fire)
            local color = hexToColor(hex)
            if not color then return end
            h, s, v = Color3.toHSV(color)
            render(fire and true or false)
        end
        local function setEnabled(v)
            disabled = not v
            setRowDim(row, face, disabled)
            if disabled and open then setOpen(false) end
            lbl.TextTransparency = disabled and 0.5 or 0
            hexLbl.TextTransparency = disabled and 0.5 or 0
            swatchFace.BackgroundTransparency = disabled and 0.45 or 0
        end
        return finishElement("ColorPicker", cp, cfg, row, { trigger }, pop, setEnabled)
    end

    return addColorPicker
end
