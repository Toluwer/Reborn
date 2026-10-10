local Reborn = loadstring(game:HttpGet("https://raw.githubusercontent.com/Toluwer/Reborn/main/src/Reborn.luau"))()

local Window = Reborn:CreateWindow({
        Title = "Reborn",
        Size = Vector2.new(700, 530),
})

local Main = Window:Tab("Main", "home")

local Overview = Main:Section("Overview")
Overview:Paragraph(
        "Reborn is a dark, minimalist UI library for Roblox. Drag the window by its header, "
                .. "switch tabs in the sidebar, and interact with every component below — the spacing, "
                .. "states and measurements are the reference implementation."
)
Overview:Button({
        Text = "Show notification",
        Primary = true,
        Callback = function()
                Reborn:Notify({
                        Title = "Welcome to Reborn",
                        Description = "Notifications slide in from the top-right corner.",
                        Type = "info",
                })
        end,
})

local Core = Main:Section("Core components")
local enableFeature = Core:Toggle({
        Text = "Enable example feature",
        Value = false,
        Flag = "feature_enabled",
        Tooltip = "Toggles the reference demo loop that drives the API checks.",
        Callback = function(value)
                print("[Reborn] example feature:", value)
        end,
})
Core:Slider({
        Text = "Walk speed",
        Min = 16,
        Max = 100,
        Value = 16,
        Flag = "walk_speed",
        Callback = function(value)
                print("[Reborn] walk speed:", value)
        end,
})

local Combat = Window:Tab("Combat", "crosshair")

local Media = Main:Section("Media")
Media:Image({
        Image = "rbxthumb://type/GameIcon/id/" .. game.PlaceId .. "/w/150/h/150",
        Height = 120,
        CornerRadius = 8,
        Tooltip = "rbxthumb resolves for any place id — this is the current game's icon.",
        Callback = function()
                Reborn:Notify({
                        Title = "Image clicked",
                        Description = "An Image with a Callback acts as an image button.",
                        Type = "info",
                })
        end,
})
Media:Image("rbxthumb://type/AvatarHeadShot/id/" .. game.Players.LocalPlayer.UserId .. "/w/150/h/150", function()
        print("[Reborn] avatar image clicked")
end)

local Aim = Combat:Section("Aim assist")
Aim:Toggle({
        Text = "Enabled",
        Value = true,
        Flag = "aim_enabled",
        Callback = function(v) print("[Reborn] aim assist:", v) end,
})
Aim:Slider({
        Text = "Field of view",
        Min = 5,
        Max = 120,
        Value = 90,
        Flag = "aim_fov",
        Callback = function(v) print("[Reborn] fov:", v) end,
})
Aim:Dropdown({
        Text = "Target part",
        Value = "Head",
        Options = { "Head", "Torso", "Nearest limb" },
        Flag = "aim_part",
        Callback = function(v) print("[Reborn] target part:", v) end,
})
Aim:Keybind({
        Text = "Aim key",
        Value = "Right Mouse",
        Mode = "Hold",
        Flag = "aim_key",
        Callback = function(active, name, input, gameProcessed)
                if not gameProcessed then
                        print("[Reborn] aim key", active and "held" or "released")
                end
        end,
})
Aim:Dropdown({
        Text = "Target filters",
        Multi = true,
        Value = { "Players" },
        Options = { "Players", "NPCs", "Team check" },
        Flag = "aim_filters",
        Tooltip = "Multi-select dropdown: pick any combination of filters.",
        Callback = function(values)
                print("[Reborn] filters:", table.concat(values, ", "))
        end,
})

local Triggerbot = Combat:Section("Triggerbot")
Triggerbot:Toggle({
        Text = "Auto fire",
        Value = false,
        Callback = function(v) print("[Reborn] auto fire:", v) end,
})
Triggerbot:Slider({
        Text = "Fire delay",
        Min = 0,
        Max = 500,
        Value = 120,
        Suffix = "ms",
        Callback = function(v) print("[Reborn] fire delay:", v) end,
})
Triggerbot:Keybind({
        Text = "Toggle triggerbot",
        Value = "B",
        Mode = "Toggle",
        Flag = "triggerbot_key",
        Tooltip = "Toggle-mode keybind: fires (true) on first press, (false) on the next.",
        Callback = function(active)
                print("[Reborn] triggerbot armed:", active)
        end,
})

local Visuals = Window:Tab("Visuals", "eye")
Visuals:SetColumns(2)

local ESP = Visuals:Section("ESP")
ESP:Toggle("Enable ESP")
ESP:Toggle("Boxes")
ESP:Toggle("Name tags")
ESP:ColorPicker({
        Text = "ESP color",
        Value = "#0070F3",
        Flag = "esp_color",
        Callback = function(hex, color)
                print("[Reborn] esp color:", hex)
        end,
})

local Environment = Visuals:Section("Environment")
Environment:Dropdown({
        Text = "Time of day",
        Value = "Night",
        Options = { "Dawn", "Day", "Dusk", "Night" },
        Flag = "env_time",
        Callback = function(v) print("[Reborn] time of day:", v) end,
})
Environment:Slider({
        Text = "Ambient brightness",
        Min = 0,
        Max = 100,
        Value = 35,
        Callback = function(v) print("[Reborn] brightness:", v) end,
})

local Settings = Window:Tab("Settings", "settings")

local Interface = Settings:Section("Interface")
Interface:Toggle({
        Text = "Notifications",
        Value = true,
        Flag = "ui_notifications",
        Callback = function(v)
                Reborn.NotificationsEnabled = v
        end,
})
Interface:Keybind({
        Text = "Open / close UI",
        Value = "Right Shift",
        Flag = "ui_toggle",
        Callback = function()
                Window:Toggle()
        end,
})
Window.ToggleKey = "Right Shift"

local Config = Settings:Section("Configuration")
local nameInput = Config:Input({
        Text = "Config name",
        Placeholder = "my-config",
        Flag = "config_name",
        Callback = function(text, enterPressed)
                print("[Reborn] config name committed:", text, enterPressed)
        end,
})
Config:Button({
        Text = "Save config",
        Primary = true,
        Callback = function()
                local name = nameInput.Text ~= "" and nameInput.Text or "my-config"
                local ok = Window:SaveConfig(name)
                Reborn:Notify({
                        Title = ok and "Config saved" or "Save failed",
                        Description = ok and ('"' .. name .. '" written — ' .. tostring(#Window:ListConfigs()) .. ' config(s) known.') or "Could not encode the config.",
                        Type = ok and "success" or "error",
                })
        end,
})
Config:Button({
        Text = "Load config",
        Callback = function()
                local name = nameInput.Text ~= "" and nameInput.Text or "my-config"
                local cfg = Window:LoadConfig(name)
                Reborn:Notify({
                        Title = cfg and "Config loaded" or "No such config",
                        Description = cfg and ('"' .. name .. '" restored — ' .. tostring(#Window:GetConfig()) .. ' flagged values applied.') or ('Nothing saved under "' .. name .. '" yet.'),
                        Type = cfg and "success" or "error",
                })
        end,
})

task.delay(2, function()
        enableFeature:Set(true, true)
        Reborn:Notify({
                Title = "Reborn loaded",
                Description = "Programmatic API works: enableFeature:Set(true) fired its callback.",
                Type = "success",
        })
end)
