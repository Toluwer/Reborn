return function(Core, Theme, theme, state, gui, viewportSize)
    local New = Core.New
    local corner = Core.corner
    local F = Theme.Fonts
    local clamp = Core.clamp
    local measureText = Core.measureText
    local tween = Core.tween
    local killTween = Core.killTween
    local completed = Core.completed

    local tipWrap = New("Frame", {
        Size = UDim2.new(0, 0, 0, 28),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Visible = false,
        ZIndex = 60,
        Parent = gui,
    })
    corner(tipWrap, 6)
    local tipFace = New("Frame", {
        Position = UDim2.new(0, 0, 0, 0),
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = theme.Overlay,
        BorderSizePixel = 0,
        Parent = tipWrap,
    })
    corner(tipFace, 6)
    local tipTxt = New("TextLabel", {
        Position = UDim2.new(0, 10, 0, 0),
        Size = UDim2.new(1, -20, 1, 0),
        BackgroundTransparency = 1,
        FontFace = F.Regular,
        TextSize = 12,
        TextColor3 = theme.TextMuted,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Text = "",
        Parent = tipFace,
    })

    local tipState = { gen = 0, armed = false }
    local function hideTip()
        tipState.gen = tipState.gen + 1
        if not tipState.armed then return end
        tipState.armed = false
        tween(tipFace, 0.1, { BackgroundTransparency = 1 })
        local exit = tween(tipTxt, 0.1, { TextTransparency = 1 })
        completed(exit, function()
            if not tipState.armed and tipWrap.Parent and not state.destroyed then tipWrap.Visible = false end
        end)
    end
    local function showTip(text, row)
        local clean = tostring(text or "")
        if clean == "" then return end
        local rp, rs = row.AbsolutePosition, row.AbsoluteSize
        local vy = viewportSize()
        local generation = tipState.gen
        local tw = clamp(measureText(clean, 12, F.Regular) + 22, 44, 320)
        if generation ~= tipState.gen or state.destroyed or state.closed or state.min or not gui.Enabled or not row.Parent then return end
        local x = rp.X + rs.X + 12
        if x + tw > vy.X - 10 then x = rp.X - 12 - tw end
        if x < 10 then x = 10 end
        local cy = clamp(rp.Y + rs.Y / 2, 22, vy.Y - 22)
        killTween(tipFace, "BackgroundTransparency")
        killTween(tipTxt, "TextTransparency")
        killTween(tipWrap, "Position")
        tipTxt.Text = clean
        tipWrap.Size = UDim2.new(0, tw, 0, 28)
        tipWrap.Position = UDim2.new(0, x, 0, cy + 4)
        tipWrap.Rotation = 0
        tipWrap.Visible = true
        tipFace.BackgroundTransparency = 0
        tipTxt.TextTransparency = 0
        tween(tipWrap, 0.14, { Position = UDim2.new(0, x, 0, cy) }, Enum.EasingStyle.Quint)
    end
    local function tipHover(row, cfg, hosts)
        for _, host in ipairs(hosts) do
            host.MouseEnter:Connect(function()
                if cfg.Tooltip and tostring(cfg.Tooltip) ~= "" then
                    tipState.gen = tipState.gen + 1
                    local gen = tipState.gen
                    task.delay(0.55, function()
                        if tipState.gen ~= gen or state.destroyed or state.closed or state.min or not gui.Enabled or not row.Parent then return end
                        local ancestor = row
                        while ancestor and ancestor ~= gui do
                            if ancestor:IsA("GuiObject") and not ancestor.Visible then return end
                            ancestor = ancestor.Parent
                        end
                        if ancestor ~= gui then return end
                        tipState.armed = true
                        showTip(cfg.Tooltip, row)
                    end)
                end
            end)
            host.MouseLeave:Connect(function()
                tipState.gen = tipState.gen + 1
                hideTip()
            end)
        end
    end

    local function dispose()
        tipState.gen = tipState.gen + 1
        tipState.armed = false
        if tipWrap.Parent then tipWrap.Visible = false end
    end

    return hideTip, tipHover, dispose
end
