return function(state, popovers)
    local entries = state.elements
    local searchRows = state.searchRows
    local byRow = {}
    local searchByRow = {}
    local connections = {}
    local query = ""
    local hideTip, tipHover

    local function remove(array, value)
        local index = table.find(array, value)
        if index then table.remove(array, index) end
    end

    local function disconnect(row)
        local scope = connections[row]
        if not scope then return end
        connections[row] = nil
        for _, connection in ipairs(scope) do
            connection:Disconnect()
        end
    end

    local function connect(row, signal, callback)
        local scope = connections[row]
        if not scope then
            scope = {}
            connections[row] = scope
        end
        local connection = signal:Connect(callback)
        table.insert(scope, connection)
        return connection
    end

    local function isVisible(row)
        local entry = byRow[row]
        return not entry or (not entry.hidden and not entry.destroyed)
    end

    local function refreshSearch()
        if state.destroyed then return end
        local matches = {}
        local groups = {}

        for _, record in ipairs(searchRows) do
            local frame = record.frame
            if frame.Parent then
                local visible = isVisible(frame)
                local match = visible and (query == "" or record.text:find(query, 1, true) ~= nil)
                if record.group then
                    local group = record.group
                    frame.Visible = visible
                    if groups[group] == nil then groups[group] = false end
                    if match then groups[group] = true end
                    if match and isVisible(group) then matches[record.section] = true end
                else
                    frame.Visible = match
                    if match and record.section then matches[record.section] = true end
                end
            end
        end

        for group, matched in pairs(groups) do
            if group.Parent then
                group.Visible = isVisible(group) and (query == "" or matched)
            end
        end
        for _, section in ipairs(state.sections) do
            if section.Frame.Parent then
                section.Frame.Visible = query == "" or matches[section] == true
            end
        end
    end

    local function registerSearch(frame, text, section)
        local record = searchByRow[frame]
        if not record then
            local group = section and section._isRow and section.Frame or nil
            record = {
                frame = frame,
                group = group,
                section = group and section._parent or section,
            }
            searchByRow[frame] = record
            table.insert(searchRows, record)
        end
        record.text = tostring(text or ""):lower()
        if query ~= "" then refreshSearch() end
    end

    local function unregisterSearch(frame)
        local record = searchByRow[frame]
        if not record then return end
        searchByRow[frame] = nil
        remove(searchRows, record)
        if record.group and record.group.Parent then
            local hasChildren = false
            for _, remaining in ipairs(searchRows) do
                if remaining.group == record.group then
                    hasChildren = true
                    break
                end
            end
            if not hasChildren then
                record.group.Visible = query == "" and isVisible(record.group)
            end
        end
    end

    local function search(text)
        query = tostring(text or ""):lower()
        if query ~= "" then popovers.CloseAll() end
        refreshSearch()
    end

    local function closeElementPopup(entry)
        if entry.pop then
            popovers.Close(entry.pop)
            entry.pop.Visible = false
        end
    end

    local function destroy(entry, external)
        if entry.destroyed then return end
        entry.destroyed = true
        entry.disabled = true

        local row = entry.row
        disconnect(row)

        if entry.kind == "Keybind" then
            if state.listening == entry.el then
                if not external and entry.el._cancel then entry.el._cancel() end
                state.listening = nil
            end
            entry.el.Callback = nil
            entry.el.Active = false
            remove(state.keybinds, entry.el)
        end

        if not external and entry.setEnabled then
            pcall(entry.setEnabled, false)
        end

        if entry.pop then
            popovers.Unregister(entry.pop)
            entry.pop:Destroy()
        end

        unregisterSearch(row)
        byRow[row] = nil
        remove(entries, entry)

        if not external then row:Destroy() end
        if not state.destroyed then refreshSearch() end
    end

    local function finish(kind, el, cfg, row, hosts, pop, setEnabled)
        el._kind = kind
        el.Flag = cfg.Flag
        el._row = row

        local entry = {
            kind = kind,
            el = el,
            cfg = cfg,
            row = row,
            pop = pop,
            setEnabled = setEnabled,
            disabled = false,
            hidden = false,
            destroyed = false,
        }
        byRow[row] = entry
        table.insert(entries, entry)

        local callback = cfg.Callback
        if callback then
            cfg.Callback = function(...)
                if entry.disabled or entry.destroyed or state.destroyed then return end
                return callback(...)
            end
            if kind == "Keybind" then el.Callback = cfg.Callback end
        end

        function el:SetEnabled(value)
            local disabled = not value
            if entry.destroyed or state.destroyed or entry.disabled == disabled then return end
            entry.disabled = disabled
            if setEnabled then setEnabled(not disabled) end
        end

        function el:SetVisible(value)
            if entry.destroyed or state.destroyed then return end
            entry.hidden = not value
            if not value then
                closeElementPopup(entry)
                if kind == "Row" then
                    for _, child in ipairs(entries) do
                        if child.row.Parent == row then closeElementPopup(child) end
                    end
                end
            end
            row.Visible = not entry.hidden
            refreshSearch()
            if not value and hideTip then hideTip() end
        end

        function el:SetTooltip(text)
            if entry.destroyed or state.destroyed then return end
            cfg.Tooltip = text
            if hideTip and (not text or tostring(text) == "") then hideTip() end
        end

        function el:Destroy()
            if entry.destroyed then return end
            if hideTip and not state.destroyed then hideTip() end
            destroy(entry, false)
        end

        connect(row, row.Destroying, function()
            destroy(entry, true)
        end)

        if tipHover and hosts and #hosts > 0 then
            tipHover(row, cfg, hosts)
        end
        if query ~= "" then refreshSearch() end
        return el
    end

    local function destroyAll()
        while #entries > 0 do
            destroy(entries[#entries], true)
        end
        for row in pairs(connections) do
            disconnect(row)
        end
        table.clear(byRow)
        table.clear(searchByRow)
        table.clear(searchRows)
    end

    local function setTooltips(hide, hover)
        hideTip = hide
        tipHover = hover
    end

    return {
        Connect = connect,
        RegisterSearch = registerSearch,
        Search = search,
        Finish = finish,
        DestroyAll = destroyAll,
        SetTooltips = setTooltips,
    }
end
