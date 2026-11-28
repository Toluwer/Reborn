return function(tween, killTween, completed)
    local function capture(instance)
        local fields = {}
        local function add(name)
            local value = instance[name]
            fields[name] = { base = value, last = value }
        end
        if instance:IsA("GuiObject") then add("BackgroundTransparency") end
        if instance:IsA("TextLabel") or instance:IsA("TextButton") or instance:IsA("TextBox") then
            add("TextTransparency")
            add("TextStrokeTransparency")
        end
        if instance:IsA("ImageLabel") or instance:IsA("ImageButton") then add("ImageTransparency") end
        if instance:IsA("ScrollingFrame") then add("ScrollBarImageTransparency") end
        if instance:IsA("UIStroke") then add("Transparency") end
        return next(fields) and fields or nil
    end

    local function apply(instance, fields, alpha)
        for name, field in pairs(fields) do
            local current = instance[name]
            if current ~= field.last then field.base = current end
            local value = field.base + (1 - field.base) * alpha
            if current ~= value then instance[name] = value end
            field.last = instance[name]
        end
    end

    local function restore(instance, fields)
        for name, field in pairs(fields) do
            if instance[name] == field.last then instance[name] = field.base end
        end
    end

    return function(root)
        local driver
        local records = {}
        local connections = {}
        local generation = 0
        local destroyed = false

        local function render(alpha)
            for instance, fields in pairs(records) do
                if instance == root or instance:IsDescendantOf(root) then
                    apply(instance, fields, alpha)
                else
                    records[instance] = nil
                end
            end
        end

        local function reset(restoreProperties)
            generation = generation + 1
            if not driver then return end
            killTween(driver, "Value")
            for _, connection in ipairs(connections) do connection:Disconnect() end
            table.clear(connections)
            if restoreProperties ~= false then
                for instance, fields in pairs(records) do
                    if instance == root or instance:IsDescendantOf(root) then restore(instance, fields) end
                end
            end
            table.clear(records)
            driver:Destroy()
            driver = nil
        end

        local function start()
            if driver then return end
            driver = Instance.new("NumberValue")
            records[root] = capture(root)
            for _, instance in ipairs(root:GetDescendants()) do records[instance] = capture(instance) end
            table.insert(connections, driver:GetPropertyChangedSignal("Value"):Connect(function()
                if driver and not destroyed then render(driver.Value) end
            end))
            table.insert(connections, root.DescendantAdded:Connect(function(instance)
                if not driver or destroyed or not instance:IsDescendantOf(root) or records[instance] then return end
                local fields = capture(instance)
                if fields then
                    records[instance] = fields
                    apply(instance, fields, driver.Value)
                end
            end))
            table.insert(connections, root.DescendantRemoving:Connect(function(instance)
                local fields = records[instance]
                records[instance] = nil
                if fields and not destroyed then restore(instance, fields) end
            end))
        end

        local function set(alpha)
            if destroyed then return end
            start()
            generation = generation + 1
            killTween(driver, "Value")
            driver.Value = math.clamp(alpha, 0, 1)
            render(driver.Value)
        end

        local function play(alpha, duration, style, direction, callback)
            if destroyed then return end
            start()
            generation = generation + 1
            local current = generation
            local animation = tween(driver, duration, { Value = alpha }, style, direction)
            completed(animation, function()
                if destroyed or generation ~= current then return end
                render(alpha)
                if callback then callback() end
                if not destroyed and generation == current then reset() end
            end)
        end

        root.Destroying:Connect(function()
            destroyed = true
            reset(false)
        end)
        return { Set = set, Play = play, Reset = reset }
    end
end
