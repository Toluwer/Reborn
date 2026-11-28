return function(Core, Theme, Icons, Components, state, theme, inputRouter, lifecycle, popovers)
    local F = Theme.Fonts
    local GEO = Theme.Geometry
    local New = Core.New
    local corner = Core.corner
    local tween = Core.tween
    local killTween = Core.killTween
    local closeAllPops = popovers.CloseAll

    local disabledRows = setmetatable({}, { __mode = "k" })

    local function setRowDim(row, face, d)
        disabledRows[row] = d or nil
        killTween(face, "BackgroundColor3")
        face.BackgroundColor3 = theme.Overlay
        face.BackgroundTransparency = d and 0.3 or 0
    end

    local function makeRow(section, h, w)
        local row = New("Frame", {
            Size = w and UDim2.new(w.Scale, w.Offset, 0, h) or UDim2.new(1, 0, 0, h),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ZIndex = 1,
            Parent = section.Rows,
        })
        corner(row, 6)
        local face = New("Frame", {
            Position = UDim2.new(0, 0, 0, 0),
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundColor3 = theme.Overlay,
            BorderSizePixel = 0,
            Parent = row,
        })
        corner(face, 6)
        row.MouseEnter:Connect(function()
            if disabledRows[row] then return end
            tween(face, 0.12, { BackgroundColor3 = theme.RowHover })
        end)
        row.MouseLeave:Connect(function()
            tween(face, 0.12, { BackgroundColor3 = theme.Overlay })
        end)
        return row, face
    end

    local function rowLabel(row, text, clear)
        local lbl = New("TextLabel", {
            AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.new(0, GEO.RowPad, 0.5, 0),
            Size = UDim2.new(1, -(GEO.RowPad + (clear or 60)), 0, 16),
            BackgroundTransparency = 1,
            FontFace = F.Medium,
            TextSize = 13,
            TextColor3 = theme.Text,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Text = tostring(text or ""),
            ZIndex = 5,
            Parent = row,
        })
        return lbl
    end

    local function overlayBtn(row)
        return New("TextButton", {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Text = "",
            AutoButtonColor = false,
            ZIndex = 10,
            Parent = row,
        })
    end

    local context = {
        F = F,
        GEO = GEO,
        MOUSE_NAMES = Core.MOUSE_NAMES,
        New = New,
        TweenService = Core.TweenService,
        UserInputService = Core.UserInputService,
        input = inputRouter,
        clamp = Core.clamp,
        closeAllPops = closeAllPops,
        colorToHex = Core.colorToHex,
        connect = lifecycle.Connect,
        corner = corner,
        finishElement = lifecycle.Finish,
        fmtNum = Core.fmtNum,
        hexToColor = Core.hexToColor,
        icon = Icons.Create,
        killTween = killTween,
        completed = Core.completed,
        fade = Core.fade,
        list = Core.list,
        makeRow = makeRow,
        measureText = Core.measureText,
        mountPop = popovers.Mount,
        nextOrder = Core.nextOrder,
        normCfg = Core.normCfg,
        overlayBtn = overlayBtn,
        padding = Core.padding,
        registerPop = popovers.Register,
        registerSearch = lifecycle.RegisterSearch,
        rnd = Core.rnd,
        rowLabel = rowLabel,
        setRowDim = setRowDim,
        state = state,
        theme = theme,
        toWidth = Core.toWidth,
        tween = tween,
        unregisterPop = popovers.Unregister,
    }

    context.addToggle = Components.Toggle(context)
    context.addSlider = Components.Slider(context)
    context.addProgressBar = Components.ProgressBar(context)
    context.addDropdown = Components.Dropdown(context)
    context.addKeybind = Components.Keybind(context)
    context.addColorPicker = Components.ColorPicker(context)
    context.addInput = Components.Input(context)
    context.addButton = Components.Button(context)
    context.addParagraph = Components.Paragraph(context)
    context.addImage = Components.Image(context)
    context.addList = Components.List(context)
    context.addRowContainer = Components.Row(context)

    return context
end
