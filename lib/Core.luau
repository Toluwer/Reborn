return function(Theme)
        local F = Theme.Fonts

        local TweenService = game:GetService("TweenService")
        local UserInputService = game:GetService("UserInputService")
        local TextService = game:GetService("TextService")
        local Players = game:GetService("Players")
        local HttpService = game:GetService("HttpService")

        local function rnd(x) return math.floor(x + 0.5) end
        local function clamp(v, a, b)
                if v < a then return a elseif v > b then return b end
                return v
        end

        local function toWidth(w, def)
                if type(w) == "number" then
                        if w > 0 and w < 1 then return UDim.new(w, 0) end
                        if w >= 1 then return UDim.new(0, rnd(w)) end
                end
                return def
        end

        local function New(className, props)
                local inst = Instance.new(className)
                local parent = nil
                if props then
                        for k, v in pairs(props) do
                                if k == "Parent" then parent = v else inst[k] = v end
                        end
                end
                if parent then inst.Parent = parent end
                return inst
        end

        local function corner(inst, r)
                return New("UICorner", { CornerRadius = UDim.new(0, r), Parent = inst })
        end

        local function padding(inst, t, r, b, l)
                local p = New("UIPadding", { Parent = inst })
                if t then p.PaddingTop = UDim.new(0, t) end
                if r then p.PaddingRight = UDim.new(0, r) end
                if b then p.PaddingBottom = UDim.new(0, b) end
                if l then p.PaddingLeft = UDim.new(0, l) end
                return p
        end

        local function list(parent, gap, sortOrder)
                return New("UIListLayout", {
                        Padding = UDim.new(0, gap or 0),
                        SortOrder = sortOrder or Enum.SortOrder.LayoutOrder,
                        Parent = parent,
                })
        end

        local liveTweens = setmetatable({}, { __mode = "kv" })

        local function tween(inst, time, props, style, dir)
                local reg = liveTweens[inst]
                if reg == nil then
                        reg = {}
                        liveTweens[inst] = reg
                end
                for k in pairs(props) do
                        local prev = reg[k]
                        if prev then
                                prev:Cancel()
                                reg[k] = nil
                        end
                end
                local t = TweenService:Create(inst, TweenInfo.new(
                        time,
                        style or Enum.EasingStyle.Quad,
                        dir or Enum.EasingDirection.Out
                ), props)
                for k in pairs(props) do reg[k] = t end
                t:Play()
                return t
        end

        local function killTween(inst, prop)
                local reg = liveTweens[inst]
                if reg == nil then return end
                local t = reg[prop]
                if t then
                        t:Cancel()
                        reg[prop] = nil
                end
        end

        local function measureText(text, size, font)
                if font == F.Mono then
                        local ok, w = pcall(function()
                                return TextService:GetTextSize(text, size, Enum.Font.Code, Vector2.new(4096, size * 2)).X
                        end)
                        if ok and w then return w end
                else
                        local params = Instance.new("GetTextBoundsParams")
                        params.Text = text
                        params.Size = size
                        params.Font = font
                        params.Width = 4096
                        local ok, bounds = pcall(function()
                                return TextService:GetTextBoundsAsync(params)
                        end)
                        params:Destroy()
                        if ok and bounds then return bounds.X end
                        local fallback = font.Weight == Enum.FontWeight.Bold and Enum.Font.GothamBold
                                or font.Weight == Enum.FontWeight.SemiBold and Enum.Font.GothamSemibold
                                or font.Weight == Enum.FontWeight.Medium and Enum.Font.GothamMedium
                                or Enum.Font.Gotham
                        local measured, w = pcall(function()
                                return TextService:GetTextSize(text, size, fallback, Vector2.new(4096, size * 2)).X
                        end)
                        if measured and w then return w end
                end
                return rnd(#text * size * 0.58)
        end

        local function colorToHex(c)
                local function to(v) return string.format("%02X", clamp(math.floor(v * 255 + 0.5), 0, 255)) end
                return "#" .. to(c.R) .. to(c.G) .. to(c.B)
        end

        local function hexToColor(hex)
                local h = tostring(hex):gsub("#", "")
                local r = tonumber(h:sub(1, 2), 16) or 0
                local g = tonumber(h:sub(3, 4), 16) or 0
                local b = tonumber(h:sub(5, 6), 16) or 0
                return Color3.fromRGB(r, g, b)
        end

        local function keyDisplayName(name)
                return (name:gsub("(%l)(%u)", "%1 %2"))
        end

        local function fmtNum(n)
                if math.abs(n - math.floor(n + 0.5)) < 1e-6 then
                        return string.format("%d", math.floor(n + 0.5))
                end
                local s = string.format("%.2f", n)
                s = s:gsub("0+$", "")
                s = s:gsub("%.$", "")
                return s
        end

        local MOUSE_NAMES = {
                [Enum.UserInputType.MouseButton1] = "Left Mouse",
                [Enum.UserInputType.MouseButton2] = "Right Mouse",
                [Enum.UserInputType.MouseButton3] = "Middle Mouse",
        }

        local function resolveParent(config)
                if config and config.Parent then return config.Parent, false end
                local ok, hidden = pcall(function()
                        if gethui then return gethui() end
                        return nil
                end)
                if ok and type(hidden) == "Instance" then return hidden, true end
                local okCore = pcall(function()
                        local probe = Instance.new("Folder")
                        probe.Parent = game:GetService("CoreGui")
                        probe:Destroy()
                end)
                if okCore then return game:GetService("CoreGui"), false end
                local player = Players.LocalPlayer
                if player then
                        local pg = player:FindFirstChild("PlayerGui")
                        if pg then return pg, false end
                        local okWait, waited = pcall(function()
                                return player:WaitForChild("PlayerGui", 5)
                        end)
                        if okWait and waited then return waited, false end
                end
                error("Reborn: no usable GUI parent (no gethui, no CoreGui access, no LocalPlayer) — pass config.Parent")
        end

        local MARK = "__r"

        local function randomName()
                local t = {}
                for i = 1, 12 do
                        t[i] = string.char(97 + math.random(0, 25))
                end
                return table.concat(t)
        end

        local orderBase = math.random(100000, 800000)
        local orderSeq = 0
        local function nextOrder()
                orderSeq = orderSeq + 1
                return math.min(orderBase + orderSeq, 900000)
        end

        local function protectGui(g)
                pcall(function()
                        if syn and syn.protect_gui then syn.protect_gui(g) end
                end)
                pcall(function()
                        if protect_gui then protect_gui(g) end
                end)
        end

        local function clearOld(parent, mark)
                for _, child in ipairs(parent:GetChildren()) do
                        if child:GetAttribute(mark or MARK) then child:Destroy() end
                end
        end

        local function normCfg(a, b)
                if type(a) == "string" then a = { Text = a } end
                if type(b) == "function" and a and a.Callback == nil then a.Callback = b end
                return a or {}
        end

        return {
                TweenService = TweenService,
                UserInputService = UserInputService,
                TextService = TextService,
                Players = Players,
                HttpService = HttpService,
                rnd = rnd,
                clamp = clamp,
                toWidth = toWidth,
                New = New,
                corner = corner,
                padding = padding,
                list = list,
                tween = tween,
                killTween = killTween,
                measureText = measureText,
                colorToHex = colorToHex,
                hexToColor = hexToColor,
                keyDisplayName = keyDisplayName,
                fmtNum = fmtNum,
                MOUSE_NAMES = MOUSE_NAMES,
                resolveParent = resolveParent,
                MARK = MARK,
                randomName = randomName,
                nextOrder = nextOrder,
                protectGui = protectGui,
                clearOld = clearOld,
                normCfg = normCfg,
        }
end
