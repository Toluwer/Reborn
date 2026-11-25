return function(ctx)
        local New = ctx.New
        local padding = ctx.padding
        local theme = ctx.theme
        local F = ctx.F
        local registerSearch = ctx.registerSearch
        local finishElement = ctx.finishElement

        local function addParagraph(section, cfg)
                cfg = cfg or {}
                local lbl = New("TextLabel", {
                        Size = UDim2.new(1, 0, 0, 0),
                        AutomaticSize = Enum.AutomaticSize.Y,
                        BackgroundTransparency = 1,
                        FontFace = F.Regular,
                        TextSize = 13,
                        TextColor3 = theme.TextMuted,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        TextYAlignment = Enum.TextYAlignment.Top,
                        TextWrapped = true,
                        Text = tostring(cfg.Text or ""),
                        Parent = section.Rows,
                })
                padding(lbl, 2, 2, 2, 12)
                registerSearch(lbl, cfg.Text, section)
                local p = { Label = lbl }
                function p:Set(text)
                        lbl.Text = tostring(text)
                end
                local function setEnabled(v)
                        lbl.TextTransparency = v and 0 or 0.5
                end
                return finishElement("Paragraph", p, cfg, lbl, { lbl }, nil, setEnabled)
        end

        return addParagraph
end
