return function(UserInputService, connect)
    local capture = nil
    local beganHandlers = {}
    local endedHandlers = {}
    local mouseButton = Enum.UserInputType.MouseButton1
    local mouseMovement = Enum.UserInputType.MouseMovement
    local touch = Enum.UserInputType.Touch

    local function isPointer(input)
        return input.UserInputType == mouseButton or input.UserInputType == touch
    end

    local function cancel(owner)
        if not capture or (owner and capture.owner ~= owner) then return end
        local previous = capture
        capture = nil
        if previous.finished then previous.finished() end
    end

    local function begin(owner, input, moved, finished)
        if not isPointer(input) or capture then return false end
        capture = {
            owner = owner,
            input = input,
            mouse = input.UserInputType == mouseButton,
            moved = moved,
            finished = finished,
        }
        return true
    end

    local function onBegan(callback)
        table.insert(beganHandlers, callback)
    end

    local function onEnded(callback)
        table.insert(endedHandlers, callback)
    end

    connect(UserInputService.InputBegan, function(input, processed)
        for _, callback in ipairs(beganHandlers) do
            callback(input, processed)
        end
    end)

    connect(UserInputService.InputChanged, function(input)
        local current = capture
        if not current then return end
        if current.mouse then
            if input.UserInputType ~= mouseMovement then return end
        elseif input ~= current.input then
            return
        end
        current.moved(input)
    end)

    connect(UserInputService.InputEnded, function(input, processed)
        local current = capture
        if current and (input == current.input or (current.mouse and input.UserInputType == mouseButton)) then
            cancel()
        end
        for _, callback in ipairs(endedHandlers) do
            callback(input, processed)
        end
    end)

    connect(UserInputService.WindowFocusReleased, function()
        cancel()
    end)

    local function destroy()
        cancel()
        table.clear(beganHandlers)
        table.clear(endedHandlers)
    end

    return {
        Begin = begin,
        Cancel = cancel,
        IsPointer = isPointer,
        OnBegan = onBegan,
        OnEnded = onEnded,
        Destroy = destroy,
    }
end
