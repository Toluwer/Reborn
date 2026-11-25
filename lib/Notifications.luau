return function(Reborn, Core, Theme, Icons)
        local DEFAULT_THEME = Theme.Default
        local F = Theme.Fonts
        local GEO = Theme.Geometry
        local icon = Icons.Create
        local New = Core.New
        local corner = Core.corner
        local padding = Core.padding
        local tween = Core.tween
        local measureText = Core.measureText
        local resolveParent = Core.resolveParent
        local MARK = Core.MARK
        local randomName = Core.randomName
        local protectGui = Core.protectGui
        local clearOld = Core.clearOld

        local TOAST_TYPES = {
                info    = { color = DEFAULT_THEME.Accent,  name = "info" },
                success = { color = DEFAULT_THEME.Success, name = "circle-check" },
                error   = { color = DEFAULT_THEME.Error,   name = "circle-x" },
        }

        local function buildToastLayer(gui, theme)
                local layer = New("Frame", {
                        AnchorPoint = Vector2.new(1, 0),
                        Position = UDim2.new(1, -18, 0, 18),
                        Size = UDim2.new(0, GEO.ToastW, 1, -36),
                        BackgroundTransparency = 1,
                        ClipsDescendants = false,
                        ZIndex = 50,
                        Parent = gui,
                })
                local state = { items = {} }

                local function toastHeight(cfg)
                        local desc = tostring(cfg.Description or "")
                        if desc == "" then return 38 end
                        local lines = 1
                        local w = measureText(desc, 12, F.Regular)
                        lines = math.max(1, math.ceil(w / math.max(GEO.ToastW - 39, 40)))
                        return 22 + math.max(16, 18 + (lines * 15 + 4))
                end

                local function relayout(animate)
                        local y = 0
                        for _, item in ipairs(state.items) do
                                local h = item.toast.AbsoluteSize.Y
                                if h < 12 then h = item.estH or 46 end
                                if animate then
                                        tween(item.toast, 0.18, { Position = UDim2.new(0, 0, 0, y) })
                                else
                                        item.toast.Position = UDim2.new(0, 0, 0, y)
                                end
                                y = y + h + 8
                        end
                end

                local function dismiss(item)
                        if item.closed then return end
                        item.closed = true
                        for i, it in ipairs(state.items) do
                                if it == item then table.remove(state.items, i) break end
                        end
                        tween(item.toast, 0.22, { Position = UDim2.new(0, GEO.ToastW + 18, 0, item.toast.Position.Y.Offset) })
                        task.delay(0.24, function()
                                if item.toast then item.toast:Destroy() end
                        end)
                        relayout(true)
                end

                local function notify(cfg)
                        cfg = cfg or {}
                        local kind = TOAST_TYPES[cfg.Type] or TOAST_TYPES.info
                        local toast = New("Frame", {
                                Position = UDim2.new(0, GEO.ToastW + 18, 0, 0),
                                Size = UDim2.new(0, GEO.ToastW, 0, 0),
                                AutomaticSize = Enum.AutomaticSize.Y,
                                BackgroundColor3 = theme.Overlay,
                                BackgroundTransparency = 0.06,
                                BorderSizePixel = 0,
                                Parent = layer,
                        })
                        corner(toast, 8)
                        padding(toast, 11, 12, 11, 12)

                        local ic = icon(toast, kind.name, 16, kind.color)
                        ic.Position = UDim2.new(0, 0, 0, 0)

                        local title = New("TextLabel", {
                                Position = UDim2.new(0, 27, 0, 0),
                                Size = UDim2.new(1, -27, 0, 16),
                                BackgroundTransparency = 1,
                                FontFace = F.Semibold,
                                TextSize = 13,
                                TextColor3 = theme.Text,
                                TextXAlignment = Enum.TextXAlignment.Left,
                                Text = tostring(cfg.Title or "Notification"),
                                TextTruncate = Enum.TextTruncate.AtEnd,
                                Parent = toast,
                        })
                        local desc = New("TextLabel", {
                                Position = UDim2.new(0, 27, 0, 18),
                                Size = UDim2.new(1, -27, 0, 0),
                                AutomaticSize = Enum.AutomaticSize.Y,
                                BackgroundTransparency = 1,
                                FontFace = F.Regular,
                                TextSize = 12,
                                TextColor3 = theme.TextMuted,
                                TextXAlignment = Enum.TextXAlignment.Left,
                                TextYAlignment = Enum.TextYAlignment.Top,
                                TextWrapped = true,
                                Text = tostring(cfg.Description or ""),
                                Parent = toast,
                        })
                        desc.Visible = desc.Text ~= ""

                        local hit = New("TextButton", {
                                Position = UDim2.new(0, -12, 0, -11),
                                Size = UDim2.new(1, 24, 1, 22),
                                BackgroundTransparency = 1,
                                Text = "",
                                AutoButtonColor = false,
                                ZIndex = 10,
                                Parent = toast,
                        })
                        local item = { toast = toast, closed = false, estH = toastHeight(cfg) }
                        hit.Activated:Connect(function() dismiss(item) end)
                        table.insert(state.items, item)
                        while #state.items > 5 do
                                dismiss(state.items[1])
                        end
                        relayout(false)
                        local targetY = toast.Position.Y.Offset
                        toast.Position = UDim2.new(0, GEO.ToastW + 18, 0, targetY)
                        tween(toast, 0.24, { Position = UDim2.new(0, 0, 0, targetY) }, Enum.EasingStyle.Quint)
                        task.defer(function()
                                if not item.closed then relayout(true) end
                        end)
                        local dur = tonumber(cfg.Duration) or 3.6
                        if dur > 0 and dur < 3600 then
                                task.delay(dur, function() dismiss(item) end)
                        end
                        return item
                end

                return { Layer = layer, Notify = notify }
        end

        local function normNotify(a, b)
                if type(a) == "string" then
                        local t = { Title = a }
                        if type(b) == "string" then t.Description = b end
                        return t
                end
                return a or {}
        end

        function Reborn:Notify(a, b)
                local cfg = normNotify(a, b)
                if not self.NotificationsEnabled then return end
                if #self._windows > 0 then
                        local w = self._windows[#self._windows]
                        w:Notify(cfg)
                        return
                end
                if not self._toastGui or not self._toastGui.Parent then
                        local tparent, viaHidden = resolveParent(nil)
                        clearOld(tparent)
                        self._toastGui = New("ScreenGui", {
                                Name = randomName(),
                                ResetOnSpawn = false,
                                IgnoreGuiInset = true,
                                ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
                                DisplayOrder = math.random(900001, 999999),
                        })
                        self._toastGui:SetAttribute(MARK, true)
                        if not viaHidden then protectGui(self._toastGui) end
                        self._toastGui.Parent = tparent
                        self._toastLayer = buildToastLayer(self._toastGui, DEFAULT_THEME)
                end
                self._toastLayer.Notify(cfg)
        end

        return { Build = buildToastLayer, Normalize = normNotify }
end
