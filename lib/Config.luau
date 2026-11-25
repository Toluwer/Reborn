return function(Reborn, Core, Window, state, config)
    local HttpService = Core.HttpService

    local function sanitizeName(s)
        return (tostring(s):gsub("[^%w%-_]", "-"))
    end
    local function cfgDir()
        return "reborn/" .. sanitizeName(config.Title or "Reborn")
    end
    local function cfgPath(name)
        return cfgDir() .. "/" .. sanitizeName(name or "default") .. ".json"
    end
    local function fsAvailable()
        return type(writefile) == "function" and type(readfile) == "function" and type(isfile) == "function"
    end

    function Window:GetConfig()
        local out = {}
        for _, e in ipairs(state.elements) do
            local el, k, flag = e.el, e.kind, e.cfg.Flag
            if flag and not e.hidden then
                if k == "Toggle" then
                    out[flag] = el.Value and true or false
                elseif k == "Slider" then
                    out[flag] = el.Value
                elseif k == "Dropdown" then
                    if type(el.Value) == "table" then
                        local c = {}
                        for i, v in ipairs(el.Value) do c[i] = v end
                        out[flag] = c
                    else
                        out[flag] = el.Value
                    end
                elseif k == "Keybind" then
                    out[flag] = el.Name
                elseif k == "ColorPicker" then
                    out[flag] = el.Hex
                elseif k == "Input" then
                    out[flag] = el.Text
                elseif k == "Image" then
                    out[flag] = el.Image.Image
                elseif k == "List" then
                    out[flag] = el.Selected
                end
            end
        end
        return out
    end

    function Window:SetConfig(vals)
        if type(vals) ~= "table" then return end
        for _, e in ipairs(state.elements) do
            local flag = e.cfg.Flag
            if flag and vals[flag] ~= nil then
                if e.kind == "Keybind" or e.kind == "Input" then
                    e.el:Set(vals[flag])
                else
                    e.el:Set(vals[flag], false)
                end
            end
        end
    end

    function Window:SaveConfig(name)
        name = tostring(name or "default")
        local okJson, json = pcall(function() return HttpService:JSONEncode(self:GetConfig()) end)
        if not okJson or type(json) ~= "string" then return false end
        if fsAvailable() then
            if type(isfolder) == "function" and type(makefolder) == "function" then
                pcall(function()
                    if not isfolder("reborn") then makefolder("reborn") end
                    if not isfolder(cfgDir()) then makefolder(cfgDir()) end
                end)
            end
            local ok = pcall(function() writefile(cfgPath(name), json) end)
            if not ok then return false end
        else
            Reborn._configs[cfgPath(name)] = json
        end
        return true
    end

    function Window:LoadConfig(name)
        name = tostring(name or "default")
        local json = nil
        if fsAvailable() then
            local ok, content = pcall(function()
                if isfile(cfgPath(name)) then return readfile(cfgPath(name)) end
                return nil
            end)
            if ok then json = content end
        end
        if json == nil then json = Reborn._configs[cfgPath(name)] end
        if type(json) ~= "string" then return nil end
        local ok, tbl = pcall(function() return HttpService:JSONDecode(json) end)
        if not ok or type(tbl) ~= "table" then return nil end
        self:SetConfig(tbl)
        return tbl
    end

    function Window:DeleteConfig(name)
        name = tostring(name or "default")
        Reborn._configs[cfgPath(name)] = nil
        if fsAvailable() and type(delfile) == "function" then
            pcall(function()
                if isfile(cfgPath(name)) then delfile(cfgPath(name)) end
            end)
        end
        return true
    end

    function Window:ListConfigs()
        local out, seen = {}, {}
        if type(listfiles) == "function" then
            local ok, files = pcall(function() return listfiles(cfgDir()) end)
            if ok and type(files) == "table" then
                for _, f in ipairs(files) do
                    local base = tostring(f):match("([^%/\\]+)%.json$")
                    if base and not seen[base] then
                        seen[base] = true
                        table.insert(out, base)
                    end
                end
            end
        end
        for path in pairs(Reborn._configs) do
            local base = path:match("^" .. cfgDir():gsub("%W", "%%%0") .. "/(.+)%.json$")
            if base and not seen[base] then
                seen[base] = true
                table.insert(out, base)
            end
        end
        table.sort(out)
        return out
    end
end
