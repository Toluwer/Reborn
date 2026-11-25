return function(ctx)
    local rnd = ctx.rnd
    local toWidth = ctx.toWidth
    local New = ctx.New
    local corner = ctx.corner
    local tween = ctx.tween
    local killTween = ctx.killTween
    local measureText = ctx.measureText
    local theme = ctx.theme
    local GEO = ctx.GEO
    local F = ctx.F
    local registerSearch = ctx.registerSearch
    local finishElement = ctx.finishElement

    local function addButton(section, cfg)
        cfg = cfg or {}
        local primary = cfg.Primary and true or false
        local btext = tostring(cfg.Text or "Button")
        local wUD = toWidth(cfg.Width, UDim.new(1, 0))
        if type(cfg.Width) == "string" and string.find(string.lower(cfg.Width), "auto", 1, true) then
            wUD = UDim.new(0, math.max(46, rnd(measureText(btext, 13, F.Semibold)) + 28))
        end
        local shell = New("Frame", {
            Size = UDim2.new(wUD.Scale, wUD.Offset, 0, GEO.RowH),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ZIndex = 1,
            Parent = section.Rows,
        })
        corner(shell, 6)
        local btn = New("TextButton", {
            Position = UDim2.new(0, 0, 0, 0),
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundColor3 = primary and theme.Accent or theme.Overlay,
            BackgroundTransparency = 0,
            Text = btext,
            FontFace = F.Semibold,
            TextSize = 13,
            TextColor3 = primary and Color3.new(1, 1, 1) or theme.TextMuted,
            TextTruncate = Enum.TextTruncate.AtEnd,
            AutoButtonColor = false,
            BorderSizePixel = 0,
            ZIndex = 2,
            Parent = shell,
        })
        corner(btn, 6)
        local disabled = false
        if primary then
            btn.MouseEnter:Connect(function()
                if disabled then return end
                tween(btn, 0.13, { BackgroundColor3 = theme.AccentHover })
            end)
            btn.MouseLeave:Connect(function()
                tween(btn, 0.13, { BackgroundColor3 = theme.Accent })
            end)
        else
            btn.MouseEnter:Connect(function()
                if disabled then return end
                tween(btn, 0.13, { BackgroundColor3 = theme.RowHover })
                tween(btn, 0.13, { TextColor3 = theme.Text })
            end)
            btn.MouseLeave:Connect(function()
                tween(btn, 0.13, { BackgroundColor3 = theme.Overlay })
                tween(btn, 0.13, { TextColor3 = theme.TextMuted })
            end)
        end
        btn.Activated:Connect(function()
            if disabled then return end
            if cfg.Callback then cfg.Callback() end
        end)
        registerSearch(shell, cfg.Text, section)
        local b = { Button = btn }
        function b:Set(text)
            btn.Text = tostring(text)
        end
        local function setEnabled(v)
            local d = not v
            disabled = d
            btn.TextTransparency = d and 0.5 or 0
            killTween(btn, "BackgroundTransparency")
            killTween(btn, "TextColor3")
            btn.TextColor3 = primary and Color3.new(1, 1, 1) or theme.TextMuted
            killTween(btn, "BackgroundColor3")
            btn.BackgroundColor3 = primary and theme.Accent or theme.Overlay
            btn.BackgroundTransparency = d and 0.45 or 0
        end
        return finishElement("Button", b, cfg, shell, { btn }, nil, setEnabled)
    end

    return addButton
end
