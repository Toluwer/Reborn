local Reborn = loadstring(game:HttpGet("https://raw.githubusercontent.com/Toluwer/Reborn/main/src/Reborn.luau"))()

local Window = Reborn:CreateWindow({
        Title = "Reborn",
        Size = Vector2.new(700, 530),
})

local Main = Window:Tab("Main")

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
        Callback = function(value)
                print("[Reborn] example feature:", value)
        end,
})
Core:Slider({
        Text = "Walk speed",
        Min = 16,
        Max = 100,
        Value = 16,
        Callback = function(value)
                print("[Reborn] walk speed:", value)
        end,
})

local Combat = Window:Tab("Combat")

local Aim = Combat:Section("Aim assist", "Beta")
Aim:Toggle({
        Text = "Enabled",
        Value = true,
        Callback = function(v) print("[Reborn] aim assist:", v) end,
})
Aim:Slider({
        Text = "Field of view",
        Min = 5,
        Max = 120,
        Value = 90,
        Callback = function(v) print("[Reborn] fov:", v) end,
})
Aim:Dropdown({
        Text = "Target part",
        Value = "Head",
        Options = { "Head", "Torso", "Nearest limb" },
        Callback = function(v) print("[Reborn] target part:", v) end,
})
Aim:Keybind({
        Text = "Aim key",
        Value = "Right Mouse",
        Callback = function(name, input, gameProcessed)
                if not gameProcessed then
                        print("[Reborn] aim key fired:", name)
                end
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

local Visuals = Window:Tab("Visuals")
Visuals:SetColumns(2)

local ESP = Visuals:Section("ESP")
ESP:Toggle("Enable ESP")
ESP:Toggle("Boxes")
ESP:Toggle("Name tags")
ESP:ColorPicker({
        Text = "ESP color",
        Value = "#0070F3",
        Callback = function(hex, color)
                print("[Reborn] esp color:", hex)
        end,
})

local Environment = Visuals:Section("Environment")
Environment:Dropdown({
        Text = "Time of day",
        Value = "Night",
        Options = { "Dawn", "Day", "Dusk", "Night" },
        Callback = function(v) print("[Reborn] time of day:", v) end,
})
Environment:Slider({
        Text = "Ambient brightness",
        Min = 0,
        Max = 100,
        Value = 35,
        Callback = function(v) print("[Reborn] brightness:", v) end,
})

local Settings = Window:Tab("Settings")

local Interface = Settings:Section("Interface")
Interface:Toggle({
        Text = "Notifications",
        Value = true,
        Callback = function(v)
                Reborn.NotificationsEnabled = v
        end,
})
Interface:Keybind({
        Text = "Open / close UI",
        Value = "Right Shift",
        Callback = function(name, input, gameProcessed)
                if not gameProcessed then
                        Window:Toggle()
                end
        end,
})

local Config = Settings:Section("Configuration")
local nameInput = Config:Input({
        Text = "Config name",
        Placeholder = "my-config",
        Callback = function(text, enterPressed)
                print("[Reborn] config name committed:", text, enterPressed)
        end,
})
Config:Button({
        Text = "Save config",
        Primary = true,
        Callback = function()
                Reborn:Notify({
                        Title = "Config saved",
                        Description = '"' .. (nameInput.Text ~= "" and nameInput.Text or "my-config") .. '" was written to the workspace.',
                        Type = "success",
                })
        end,
})
Config:Button({
        Text = "Load config",
        Callback = function()
                Reborn:Notify("Config loaded", "3 modules restored from the workspace.")
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
