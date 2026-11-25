return function(ctx)
    local TweenService = ctx.TweenService
    local rnd = ctx.rnd
    local toWidth = ctx.toWidth
    local New = ctx.New
    local corner = ctx.corner
    local tween = ctx.tween
    local killTween = ctx.killTween
    local measureText = ctx.measureText
    local MOUSE_NAMES = ctx.MOUSE_NAMES
    local theme = ctx.theme
    local GEO = ctx.GEO
    local F = ctx.F
    local state = ctx.state
    local makeRow = ctx.makeRow
    local setRowDim = ctx.setRowDim
    local rowLabel = ctx.rowLabel
    local registerSearch = ctx.registerSearch
    local finishElement = ctx.finishElement

    local function bindFromString(s)
        if type(s) ~= "string" then return nil, nil end
        for uit, name in pairs(MOUSE_NAMES) do
            if name == s then return nil, uit end
        end
        local joined = s:gsub("%s", "")
        local ok, code = pcall(function()
            return Enum.KeyCode[joined]
        end)
        if ok and code and code ~= Enum.KeyCode.None then return code, nil end
        return nil, nil
    end

    local function addKeybind(section, cfg)
        cfg = cfg or {}
        local row, face = makeRow(section, GEO.RowH, toWidth(cfg.Width, nil))
        local lbl = rowLabel(row, cfg.Text, GEO.ChipMinW + 22)

        local chip = New("TextButton", {
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -GEO.RowPad, 0.5, 0),
            Size = UDim2.new(0, GEO.ChipMinW, 0, GEO.ChipH),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Text = "",
            AutoButtonColor = false,
            ZIndex = 5,
            Parent = row,
        })
        corner(chip, 4)
        local chipFace = New("Frame", {
            Position = UDim2.new(0, 0, 0, 0),
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundColor3 = theme.Chip,
            BorderSizePixel = 0,
            ZIndex = 1,
            Parent = chip,
        })
        corner(chipFace, 4)
        local txt = New("TextLabel", {
            Position = UDim2.new(0, 8, 0, 0),
            Size = UDim2.new(1, -16, 1, 0),
            BackgroundTransparency = 1,
            FontFace = F.Mono,
            TextSize = 11,
            TextColor3 = theme.TextMuted,
            TextXAlignment = Enum.TextXAlignment.Center,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Text = tostring(cfg.Value or "None"),
            ZIndex = 2,
            Parent = chip,
        })
        local function fitChip()
            local w = rnd(math.max(GEO.ChipMinW, measureText(txt.Text, 11, F.Mono) + 18))
            chip.Size = UDim2.new(0, w, 0, GEO.ChipH)
            lbl.Size = UDim2.new(1, -(GEO.RowPad + 22 + w), 0, 16)
        end
        txt:GetPropertyChangedSignal("Text"):Connect(fitChip)
        task.defer(fitChip)

        local mode = tostring(cfg.Mode or "Always")
        if mode ~= "Toggle" and mode ~= "Hold" then mode = "Always" end
        local kb = {
            Name = cfg.Value or "None",
            KeyCode = nil,
            UserInputType = nil,
            Callback = cfg.Callback,
            Mode = mode,
            Active = false,
        }
        do
            local code, uit = bindFromString(kb.Name)
            kb.KeyCode = code
            kb.UserInputType = uit
        end
        local pulseTween = nil
        row.Destroying:Connect(function()
            if pulseTween then
                pulseTween:Cancel()
                pulseTween = nil
            end
        end)

        local function stopListen()
            if pulseTween then
                pulseTween:Cancel()
                pulseTween = nil
            end
            killTween(chipFace, "BackgroundColor3")
            killTween(chipFace, "BackgroundTransparency")
            killTween(txt, "TextColor3")
            chipFace.BackgroundTransparency = 0
            chipFace.BackgroundColor3 = theme.Chip
            txt.TextColor3 = theme.TextMuted
            state.listening = nil
        end
        local function cancelListen()
            if state.listening ~= kb then return end
            txt.Text = kb._prev or kb.Name
            stopListen()
        end
        local function commitBind(name, keyCode, uit)
            kb.Name = name
            kb.KeyCode = keyCode
            kb.UserInputType = uit
            kb.Active = false
            txt.Text = name
            stopListen()
        end
        local function startListen()
            if state.listening then
                state.listening._cancel()
            end
            state.listening = kb
            kb._cancel = cancelListen
            kb._commit = commitBind
            kb._chip = chip
            kb._prev = txt.Text
            txt.Text = "· · ·"
            tween(chipFace, 0.12, { BackgroundColor3 = theme.RowHover })
            tween(txt, 0.12, { TextColor3 = theme.Accent })
            pulseTween = TweenService:Create(chipFace, TweenInfo.new(1, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1, true), { BackgroundTransparency = 0.6 })
            pulseTween:Play()
        end

        local disabled = false
        chip.InputBegan:Connect(function(input)
            if disabled then return end
            local it = input.UserInputType
            if it == Enum.UserInputType.MouseButton1 or it == Enum.UserInputType.MouseButton2 or it == Enum.UserInputType.MouseButton3 then
                if state.listening == kb then
                    commitBind(MOUSE_NAMES[it] or "Mouse", nil, it)
                elseif not state.listening then
                    startListen()
                end
            end
        end)

        table.insert(state.keybinds, kb)
        kb.Chip = chip
        registerSearch(row, cfg.Text, section)

        function kb:Set(name)
            local code, uit = bindFromString(name)
            kb.Name = tostring(name)
            kb.KeyCode = code
            kb.UserInputType = uit
            kb.Active = false
            txt.Text = tostring(name)
        end
        local function setEnabled(v)
            disabled = not v
            setRowDim(row, face, disabled)
            if disabled then
                if state.listening == kb then cancelListen() end
                kb.Callback = nil
                kb.Active = false
                chipFace.BackgroundTransparency = 0.45
            else
                kb.Callback = cfg.Callback
                chipFace.BackgroundTransparency = 0
            end
            lbl.TextTransparency = disabled and 0.5 or 0
            txt.TextTransparency = disabled and 0.5 or 0
        end
        return finishElement("Keybind", kb, cfg, row, { chip }, nil, setEnabled)
    end

    return addKeybind
end
