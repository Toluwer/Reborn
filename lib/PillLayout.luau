local WIDTH = "RebornPillWidth"
local ORDER = "RebornPillOrder"
local GAP = 8

return function(parent, gui, viewportSize, pillHeight, onPosition)
    local watched = {}
    local destroyed = false
    local queued = false
    local position

    local function entries()
        local result = {}
        for _, child in ipairs(parent:GetChildren()) do
            local width = child:GetAttribute(WIDTH)
            local order = child:GetAttribute(ORDER)
            if child:IsA("ScreenGui") and type(width) == "number" and width > 0 and type(order) == "number" then
                table.insert(result, { gui = child, width = width, order = order })
            end
        end
        table.sort(result, function(a, b)
            if a.order == b.order then return a.gui.Name < b.gui.Name end
            return a.order < b.order
        end)
        return result
    end

    local function refresh()
        if destroyed or gui.Parent ~= parent or (gui:GetAttribute(WIDTH) or 0) <= 0 then return end
        local active = entries()
        local limit = math.max(1, viewportSize().X - GAP * 2)
        local first, y = 1, 14
        while first <= #active do
            local last, total = first, active[first].width
            while last < #active do
                local extra = active[last + 1].width + GAP
                if total + extra > limit then break end
                total = total + extra
                last = last + 1
            end
            local x = -total / 2
            for index = first, last do
                local item = active[index]
                if item.gui == gui then
                    local nextPosition = UDim2.new(0.5, x + item.width / 2, 0, y)
                    if nextPosition ~= position then
                        position = nextPosition
                        onPosition(position)
                    end
                    return
                end
                x = x + item.width + GAP
            end
            first = last + 1
            y = y + pillHeight + GAP
        end
    end

    local function schedule()
        if destroyed or queued then return end
        queued = true
        task.defer(function()
            queued = false
            refresh()
        end)
    end

    local function watch(child)
        if watched[child] or not child:IsA("ScreenGui") or child:GetAttribute(ORDER) == nil then return end
        watched[child] = child:GetAttributeChangedSignal(WIDTH):Connect(schedule)
    end

    for _, child in ipairs(parent:GetChildren()) do watch(child) end
    local added = parent.ChildAdded:Connect(function(child)
        watch(child)
        schedule()
    end)
    local removed = parent.ChildRemoved:Connect(function(child)
        if watched[child] then
            watched[child]:Disconnect()
            watched[child] = nil
        end
        schedule()
    end)

    local function setWidth(width)
        if destroyed then return end
        local previous = gui:GetAttribute(WIDTH) or 0
        if previous <= 0 and width > 0 then
            local order = 0
            for _, item in ipairs(entries()) do order = math.max(order, item.order) end
            gui:SetAttribute(ORDER, order + 1)
            position = nil
        end
        if previous ~= width then gui:SetAttribute(WIDTH, width) end
        if width > 0 then refresh() else position = nil end
    end

    local function destroy()
        if destroyed then return end
        destroyed = true
        added:Disconnect()
        removed:Disconnect()
        for _, connection in pairs(watched) do connection:Disconnect() end
        table.clear(watched)
        if gui.Parent then gui:SetAttribute(WIDTH, 0) end
    end

    return { SetWidth = setWidth, Refresh = refresh, Destroy = destroy }
end
