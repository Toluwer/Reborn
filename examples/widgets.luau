local Reborn = loadstring(game:HttpGet("https://raw.githubusercontent.com/Toluwer/Reborn/main/src/Reborn.luau"))()

local Controls = Reborn:CreateWidget({
    Title = "Controls",
    Id = "controls",
    Width = 260,
    Position = Vector2.new(24, 80),
})

local Status = Controls:Paragraph("Ready")
local Enabled = Controls:Toggle({
    Text = "Enabled",
    Flag = "enabled",
    Value = true,
    Callback = function(value)
        Status:Set(value and "Enabled" or "Disabled")
    end,
})

local Intensity = Controls:Slider({
    Text = "Intensity",
    Flag = "intensity",
    Min = 0,
    Max = 100,
    Value = 65,
    Suffix = "%",
})

local Actions = Controls:Row()
Actions:Button("Reset", function()
    Enabled:Set(true, true)
    Intensity:Set(65)
end)
Actions:Button("Collapse", function()
    Controls:Minimize()
end)

local Settings = Reborn:CreateWidget({
    Title = "Settings",
    Id = "settings",
    Width = 260,
    Position = Vector2.new(300, 80),
})

Settings:Dropdown({
    Text = "Mode",
    Options = { "Default", "Compact", "Custom" },
    Flag = "mode",
})
Settings:ColorPicker({
    Text = "Accent",
    Value = "#2C67C5",
    Flag = "accent",
})
Settings:Input({
    Text = "Profile",
    Value = "default",
    Flag = "profile",
})
Settings:Keybind({
    Text = "Toggle controls",
    Value = "K",
    Callback = function()
        Controls:ToggleCollapsed()
    end,
})
Settings:Button("Save settings", function()
    Settings:SaveConfig("default")
end)
Settings:Button("Load settings", function()
    Settings:LoadConfig("default")
end)

local Clock = Reborn:CreateWidget({
    Title = "Clock",
    Width = 190,
    Position = Vector2.new(24, 360),
    Resizable = false,
})
local Time = Clock:Paragraph(os.date("%H:%M:%S"))
local elapsed = 0
local connection = game:GetService("RunService").Heartbeat:Connect(function(dt)
    elapsed = elapsed + dt
    if elapsed >= 1 then
        elapsed = 0
        Time:Set(os.date("%H:%M:%S"))
    end
end)
Clock:AddCleanup(function()
    connection:Disconnect()
end)
