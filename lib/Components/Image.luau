return function(ctx)
        local rnd = ctx.rnd
        local clamp = ctx.clamp
        local toWidth = ctx.toWidth
        local New = ctx.New
        local corner = ctx.corner
        local list = ctx.list
        local tween = ctx.tween
        local theme = ctx.theme
        local GEO = ctx.GEO
        local F = ctx.F
        local makeRow = ctx.makeRow
        local setRowDim = ctx.setRowDim
        local overlayBtn = ctx.overlayBtn
        local registerSearch = ctx.registerSearch
        local finishElement = ctx.finishElement

        local function toAsset(v)
                local t = type(v)
                if t == "number" then return "rbxassetid://" .. string.format("%.0f", v) end
                if t == "string" then
                        local s = string.match(v, "^%s*(.-)%s*$")
                        if s == "" then return nil end
                        if string.find(s, "://", 1, true) then return s end
                        if string.match(s, "^%d+$") then return "rbxassetid://" .. s end
                        return s
                end
                return nil
        end

        local function toScaleType(v)
                local s = string.lower(tostring(v or ""))
                if string.find(s, "fit", 1, true) then return Enum.ScaleType.Fit end
                if string.find(s, "stretch", 1, true) then return Enum.ScaleType.Stretch end
                return Enum.ScaleType.Crop
        end

        local function addImage(section, cfg)
                cfg = cfg or {}
                local raw = cfg.Image ~= nil and cfg.Image or cfg.Text
                local src = toAsset(raw)
                local h = clamp(rnd(tonumber(cfg.Height) or GEO.ImageH), GEO.ImageMinH, GEO.ImageMaxH)
                local st = toScaleType(cfg.ScaleType)
                local r = clamp(rnd(tonumber(cfg.CornerRadius) or 7), 0, 8)
                local side = (cfg.Title ~= nil) or (cfg.Subtitle ~= nil) or (cfg.Meta ~= nil)
                local row, face = makeRow(section, h, toWidth(not side and cfg.Width, nil))
                local artW = h - 2
                local img = New("ImageLabel", {
                        Size = side and UDim2.new(0, artW, 1, 0) or UDim2.new(1, 0, 1, 0),
                        BackgroundTransparency = 1,
                        Image = src or "",
                        ScaleType = st,
                        BorderSizePixel = 0,
                        Parent = face,
                })
                corner(img, r)
                local titleLbl, subLbl, metaLbl
                if side then
                        local pad = 10
                        local txt = New("Frame", {
                                Position = UDim2.new(0, artW + pad, 0, 0),
                                Size = UDim2.new(1, -(artW + pad), 1, 0),
                                BackgroundTransparency = 1,
                                BorderSizePixel = 0,
                                Parent = face,
                        })
                        local tl = list(txt, 3)
                        tl.VerticalAlignment = Enum.VerticalAlignment.Center
                        local order = 0
                        local function addLine(text, size, font, color, wrap)
                                order = order + 1
                                local props = {
                                        Size = UDim2.new(1, 0, 0, wrap and 0 or size + 4),
                                        BackgroundTransparency = 1,
                                        FontFace = font,
                                        TextSize = size,
                                        TextColor3 = color,
                                        TextXAlignment = Enum.TextXAlignment.Left,
                                        TextYAlignment = Enum.TextYAlignment.Center,
                                        LayoutOrder = order,
                                        Text = tostring(text or ""),
                                        BorderSizePixel = 0,
                                        Parent = txt,
                                }
                                if wrap then
                                        props.AutomaticSize = Enum.AutomaticSize.Y
                                        props.TextWrapped = true
                                else
                                        props.TextTruncate = Enum.TextTruncate.AtEnd
                                end
                                return New("TextLabel", props)
                        end
                        if cfg.Title ~= nil then
                                titleLbl = addLine(cfg.Title, 14, F.Semibold, theme.Text, true)
                        end
                        if cfg.Subtitle ~= nil then
                                subLbl = addLine(cfg.Subtitle, 12, F.Regular, theme.TextMuted, true)
                        end
                        if cfg.Meta ~= nil then
                                metaLbl = addLine(cfg.Meta, 11, F.Regular, theme.TextFaint, false)
                        end
                end
                local ov = nil
                local imgDisabled = false
                if cfg.Callback then
                        ov = overlayBtn(row)
                        ov.Activated:Connect(function()
                                if imgDisabled then return end
                                if cfg.Callback then cfg.Callback() end
                        end)
                        ov.MouseEnter:Connect(function()
                                if imgDisabled then return end
                                tween(img, 0.13, { ImageTransparency = 0.1 })
                        end)
                        ov.MouseLeave:Connect(function()
                                tween(img, 0.13, { ImageTransparency = imgDisabled and 0.5 or 0 })
                        end)
                end
                registerSearch(row, raw, section)
                local o = { Image = img }
                function o:SetImage(v)
                        img.Image = toAsset(v) or ""
                end
                o.Set = o.SetImage
                function o:SetTitle(v)
                        if titleLbl then titleLbl.Text = tostring(v or "") end
                end
                function o:SetSubtitle(v)
                        if subLbl then subLbl.Text = tostring(v or "") end
                end
                function o:SetMeta(v)
                        if metaLbl then metaLbl.Text = tostring(v or "") end
                end
                local function setEnabled(v)
                        imgDisabled = not v
                        setRowDim(row, face, imgDisabled)
                        img.ImageTransparency = imgDisabled and 0.5 or 0
                        if titleLbl then titleLbl.TextTransparency = imgDisabled and 0.5 or 0 end
                        if subLbl then subLbl.TextTransparency = imgDisabled and 0.5 or 0 end
                        if metaLbl then metaLbl.TextTransparency = imgDisabled and 0.5 or 0 end
                end
                return finishElement("Image", o, cfg, row, ov and { ov } or { img }, nil, setEnabled)
        end

        return addImage
end
