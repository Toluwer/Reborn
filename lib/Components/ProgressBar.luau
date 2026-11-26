return function(ctx)
    local New = ctx.New
    local corner = ctx.corner
    local tween = ctx.tween
    local killTween = ctx.killTween
    local theme = ctx.theme
    local GEO = ctx.GEO
    local F = ctx.F

    local function finiteNumber(raw)
        local value = tonumber(raw)
        if value and value == value and math.abs(value) < math.huge then return value end
    end

    local function addProgressBar(section, cfg)
        cfg = cfg or {}
        local min = finiteNumber(cfg.Min) or 0
        local max = finiteNumber(cfg.Max) or 100
        if max <= min or not finiteNumber(max - min) then min, max = 0, 100 end
        local value = math.clamp(finiteNumber(cfg.Value) or min, min, max)
        local showValue = cfg.ShowValue ~= false
        local duration = math.clamp(finiteNumber(cfg.Duration) or 0.20, 0, 2)
        local row, face = ctx.makeRow(section, 48, ctx.toWidth(cfg.Width, nil))
        local label = New("TextLabel", {
            Position = UDim2.fromOffset(GEO.RowPad, 8),
            Size = UDim2.new(showValue and 0.65 or 1, -GEO.RowPad, 0, 16),
            BackgroundTransparency = 1,
            FontFace = F.Medium,
            TextSize = 13,
            TextColor3 = theme.Text,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Text = tostring(cfg.Text or ""),
            Parent = row,
        })
        local display = New("TextLabel", {
            AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, -GEO.RowPad, 0, 8),
            Size = UDim2.new(0.35, -GEO.RowPad, 0, 16),
            BackgroundTransparency = 1,
            FontFace = F.Medium,
            TextSize = 12,
            TextColor3 = theme.TextMuted,
            TextXAlignment = Enum.TextXAlignment.Right,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Visible = showValue,
            Parent = row,
        })
        local track = New("Frame", {
            Position = UDim2.fromOffset(GEO.RowPad, 31),
            Size = UDim2.new(1, -GEO.RowPad * 2, 0, GEO.RailH),
            BackgroundColor3 = theme.LineStrong,
            BorderSizePixel = 0,
            ClipsDescendants = true,
            Parent = row,
        })
        corner(track, GEO.RailH / 2)
        local fill = New("Frame", {
            Size = UDim2.new(0, 0, 1, 0),
            BackgroundColor3 = typeof(cfg.Color) == "Color3" and cfg.Color or theme.Accent,
            BorderSizePixel = 0,
            Parent = track,
        })
        corner(fill, GEO.RailH / 2)

        local bar = { Value = value, Min = min, Max = max }
        local destroyed = false
        local function render(animate)
            local fraction = math.clamp((value - min) / (max - min), 0, 1)
            bar.Value = value
            bar.Min = min
            bar.Max = max
            if showValue then
                if type(cfg.Format) == "function" then
                    local ok, text = pcall(cfg.Format, value, fraction)
                    if destroyed then return end
                    display.Text = ok and tostring(text) or ctx.fmtNum(value)
                elseif cfg.Suffix ~= nil then
                    display.Text = ctx.fmtNum(value) .. tostring(cfg.Suffix)
                else
                    display.Text = tostring(math.floor(fraction * 100 + 0.5)) .. "%"
                end
            end
            local size = UDim2.fromScale(fraction, 1)
            if animate and duration > 0 then
                tween(fill, duration, { Size = size }, Enum.EasingStyle.Quart)
            else
                killTween(fill, "Size")
                fill.Size = size
            end
        end

        function bar:Set(nextValue, animate)
            if destroyed then return end
            nextValue = finiteNumber(nextValue)
            if nextValue == nil then return end
            nextValue = math.clamp(nextValue, min, max)
            if value == nextValue and animate ~= false then return end
            value = nextValue
            render(animate ~= false)
        end

        function bar:SetRange(mn, mx)
            if destroyed then return false end
            mn, mx = finiteNumber(mn), finiteNumber(mx)
            if not mn or not mx or mx <= mn or not finiteNumber(mx - mn) then return false end
            min, max = mn, mx
            value = math.clamp(value, min, max)
            render(false)
            return true
        end

        function bar:SetText(text)
            if destroyed then return end
            label.Text = tostring(text or "")
            ctx.registerSearch(row, label.Text, section)
        end

        function bar:SetColor(color)
            if destroyed or typeof(color) ~= "Color3" then return end
            fill.BackgroundColor3 = color
        end

        row.Destroying:Connect(function()
            destroyed = true
            killTween(fill, "Size")
        end)
        render(false)
        ctx.registerSearch(row, label.Text, section)
        local function setEnabled(enabled)
            ctx.setRowDim(row, face, not enabled)
            label.TextTransparency = enabled and 0 or 0.5
            display.TextTransparency = enabled and 0 or 0.5
            track.BackgroundTransparency = enabled and 0 or 0.6
            fill.BackgroundTransparency = enabled and 0 or 0.6
        end
        return ctx.finishElement("ProgressBar", bar, cfg, row, { row }, nil, setEnabled)
    end

    return addProgressBar
end
