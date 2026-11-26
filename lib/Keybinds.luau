return function(Core, state, inputRouter, popovers, onEscape)
    local keyDisplayName = Core.keyDisplayName

    local function matchesKeybind(keybind, input)
        return (keybind.KeyCode ~= nil and keybind.KeyCode ~= Enum.KeyCode.None and input.KeyCode == keybind.KeyCode)
            or (keybind.UserInputType ~= nil and input.UserInputType == keybind.UserInputType)
    end

    inputRouter.OnBegan(function(input, gameProcessed)
        if state.destroyed then return end
        if state.listening and input.UserInputType == Enum.UserInputType.Keyboard then
            if input.KeyCode == Enum.KeyCode.Escape then
                state.listening._cancel()
            elseif input.KeyCode == Enum.KeyCode.Backspace then
                state.listening._commit("None", nil, nil)
            else
                state.listening._commit(keyDisplayName(input.KeyCode.Name), input.KeyCode, nil)
            end
            return
        end
        if not gameProcessed then
            for _, kb in ipairs(table.clone(state.keybinds)) do
                if state.destroyed then return end
                if matchesKeybind(kb, input) and kb.Callback then
                    if kb.Mode == "Toggle" then
                        kb.Active = not kb.Active
                        kb.Callback(kb.Active, kb.Name, input, gameProcessed)
                    elseif kb.Mode == "Hold" then
                        if not kb.Active then
                            kb.Active = true
                            kb.Callback(true, kb.Name, input, gameProcessed)
                        end
                    else
                        kb.Callback(kb.Name, input, gameProcessed)
                    end
                end
            end
        end
        if state.destroyed then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            local m = Vector2.new(input.Position.X, input.Position.Y)
            popovers.CloseOutside(m)
            if state.listening and not gameProcessed then
                local chip = state.listening._chip
                if chip == nil or not popovers.Contains(chip, m) then
                    state.listening._cancel()
                end
            end
        end
        if input.KeyCode == Enum.KeyCode.Escape then
            if onEscape then onEscape() else popovers.CloseAll() end
        end
    end)
    inputRouter.OnEnded(function(input, gameProcessed)
        for _, kb in ipairs(table.clone(state.keybinds)) do
            if state.destroyed then return end
            if kb.Mode == "Hold" and kb.Active and kb.Callback and matchesKeybind(kb, input) then
                kb.Active = false
                kb.Callback(false, kb.Name, input, gameProcessed)
            end
        end
    end)
end
