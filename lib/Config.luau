return function(Reborn, Core, Window, state, config)
    local HttpService = Core.HttpService

    local function sanitizeName(value)
        local name = tostring(value):gsub("[^%w%-_]", "-")
        return name ~= "" and name or "default"
    end

    local directory = "reborn/" .. sanitizeName(config.Title or "Reborn")

    local function pathFor(name)
        return directory .. "/" .. sanitizeName(name or "default") .. ".json"
    end

    local function canRead()
        return type(readfile) == "function" and type(isfile) == "function"
    end

    local function canWrite()
        return canRead() and type(writefile) == "function"
    end

    local function finite(value)
        return type(value) == "number" and value == value and math.abs(value) < math.huge
    end

    local function scalar(value)
        return type(value) == "string" or type(value) == "boolean" or finite(value)
    end

    local function snapshot(entry)
        local element = entry.el
        local kind = entry.kind

        if kind == "Toggle" then
            return element.Value == true
        elseif kind == "Slider" or kind == "ProgressBar" then
            if finite(element.Value) then return element.Value end
        elseif kind == "Dropdown" then
            if entry.cfg.Multi then
                local values = {}
                for _, value in ipairs(element.Value) do
                    if scalar(value) then table.insert(values, value) end
                end
                return values
            end
            if scalar(element.Value) then return element.Value end
        elseif kind == "Keybind" then
            return element.Name
        elseif kind == "ColorPicker" then
            return element.Hex
        elseif kind == "Input" then
            return element.Text
        elseif kind == "Image" then
            return element.Image.Image
        elseif kind == "List" then
            if element.Selected == nil then return false end
            return element.Selected
        end
        return nil
    end

    local function restore(entry, value)
        local element = entry.el
        local kind = entry.kind

        if kind == "Toggle" then
            if type(value) == "boolean" then element:Set(value, false) end
        elseif kind == "Slider" or kind == "ProgressBar" then
            local number = tonumber(value)
            if finite(number) then element:Set(number, false) end
        elseif kind == "Dropdown" then
            if entry.cfg.Multi then
                if type(value) ~= "table" then return end
                local values = {}
                for _, option in ipairs(value) do
                    if not scalar(option) then return end
                    table.insert(values, option)
                end
                element:Set(values, false)
            elseif scalar(value) then
                element:Set(value, false)
            end
        elseif kind == "Keybind" or kind == "Input" then
            if type(value) == "string" then element:Set(value) end
        elseif kind == "ColorPicker" then
            if type(value) == "string" then element:Set(value, false) end
        elseif kind == "Image" then
            if type(value) == "string" or finite(value) then element:SetImage(value) end
        elseif kind == "List" then
            if value == false then
                element:SetSelected(nil, false)
            elseif finite(value) then
                element:SetSelected(value, false)
            end
        end
    end

    local function flagOf(entry)
        local flag = entry.cfg.Flag
        if not entry.destroyed and type(flag) == "string" and flag ~= "" then
            return flag
        end
    end

    function Window:GetConfig()
        local values = {}
        for _, entry in ipairs(state.elements) do
            local flag = flagOf(entry)
            if flag then
                local value = snapshot(entry)
                if value ~= nil then values[flag] = value end
            end
        end
        return values
    end

    function Window:SetConfig(vals)
        if state.destroyed or type(vals) ~= "table" then return end
        for _, entry in ipairs(table.clone(state.elements)) do
            local flag = flagOf(entry)
            if flag and vals[flag] ~= nil then
                pcall(restore, entry, vals[flag])
            end
        end
    end

    function Window:SaveConfig(name)
        if state.destroyed then return false end
        local ok, json = pcall(function()
            return HttpService:JSONEncode(self:GetConfig())
        end)
        if not ok or type(json) ~= "string" then return false end

        local path = pathFor(name)
        if not canWrite() then
            Reborn._configs[path] = json
            return true
        end

        local written = pcall(function()
            if type(isfolder) == "function" and type(makefolder) == "function" then
                if not isfolder("reborn") then makefolder("reborn") end
                if not isfolder(directory) then makefolder(directory) end
            end
            writefile(path, json)
        end)
        if written then Reborn._configs[path] = nil end
        return written
    end

    function Window:LoadConfig(name)
        if state.destroyed then return nil end
        local path = pathFor(name)
        local json = Reborn._configs[path]

        if json == nil and canRead() then
            local ok, content = pcall(function()
                if isfile(path) then return readfile(path) end
            end)
            if not ok then return nil end
            json = content
        end
        if type(json) ~= "string" then return nil end

        local ok, values = pcall(function()
            return HttpService:JSONDecode(json)
        end)
        if not ok or type(values) ~= "table" then return nil end

        self:SetConfig(values)
        return values
    end

    function Window:DeleteConfig(name)
        local path = pathFor(name)
        local existed = Reborn._configs[path] ~= nil

        if type(isfile) == "function" then
            local checked, onDisk = pcall(isfile, path)
            if not checked then return false end
            if onDisk then
                if type(delfile) ~= "function" then return false end
                local deleted = pcall(delfile, path)
                if not deleted then return false end
                local verified, remains = pcall(isfile, path)
                if not verified or remains then return false end
                existed = true
            end
        end

        Reborn._configs[path] = nil
        return existed
    end

    function Window:ListConfigs()
        local names, seen = {}, {}
        local function add(name)
            if name and not seen[name] then
                seen[name] = true
                table.insert(names, name)
            end
        end

        if type(listfiles) == "function" then
            local ok, files = pcall(listfiles, directory)
            if ok and type(files) == "table" then
                for _, file in ipairs(files) do
                    add(tostring(file):match("([^%/\\]+)%.json$"))
                end
            end
        end

        local prefix = directory .. "/"
        for path in pairs(Reborn._configs) do
            if path:sub(1, #prefix) == prefix then
                add(path:sub(#prefix + 1):match("^([^/]+)%.json$"))
            end
        end

        table.sort(names)
        return names
    end
end
