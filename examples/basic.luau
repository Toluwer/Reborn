local Reborn = loadstring(game:HttpGet("https://raw.githubusercontent.com/Toluwer/Reborn/main/src/Reborn.luau"))()

local Window = Reborn:CreateWindow({
        Title = "Reborn",
        Size = Vector2.new(700, 530),
})

local Main = Window:Tab("Main", "home")
Main:SetColumns(2)

local Controls = Main:Section("Controls")
local Status

local function updateStatus(text)
        if Status then
                Status:Set(text)
        end
end

local Enabled = Controls:Toggle({
        Text = "Enabled",
        Value = true,
        Flag = "enabled",
        Callback = function(value)
                updateStatus(value and "Enabled" or "Disabled")
        end,
})

local Amount = Controls:Slider({
        Text = "Intensity",
        Min = 0,
        Max = 100,
        Value = 50,
        Suffix = "%",
        Flag = "intensity",
        Callback = function(value)
                updateStatus("Intensity: " .. value .. "%")
        end,
})

Controls:Dropdown({
        Text = "Mode",
        Options = { "Automatic", "Manual", "Adaptive" },
        Value = "Automatic",
        Flag = "mode",
        Callback = updateStatus,
})

Controls:Dropdown({
        Text = "Filters",
        Options = { "Recent", "Favorites", "Archived" },
        Value = { "Recent" },
        Multi = true,
        Flag = "filters",
        Callback = function(values)
                updateStatus(#values > 0 and table.concat(values, ", ") or "No filters")
        end,
})

Controls:ColorPicker({
        Text = "Accent",
        Flag = "color",
        Callback = function(hex)
                updateStatus(hex)
        end,
})

local Actions = Main:Section("Actions")

Status = Actions:Paragraph("Ready")

Actions:Button({
        Text = "Apply",
        Primary = true,
        Callback = function()
                Window:Notify({
                        Title = "Applied",
                        Description = "Your settings have been updated.",
                        Type = "success",
                })
        end,
})

local Buttons = Actions:Row()
Buttons:Button({
        Text = "Reset",
        Callback = function()
                Enabled:Set(true, true)
                Amount:Set(50, true)
                updateStatus("Controls reset")
        end,
})

Buttons:Button({
        Text = "Preview",
        Callback = function()
                Window:Notify("Preview", "Current intensity: " .. Amount.Value .. "%")
        end,
})

Actions:Input({
        Text = "Label",
        Placeholder = "Enter a label",
        Flag = "label",
        Callback = function(text)
                updateStatus(text ~= "" and text or "Ready")
        end,
})

Actions:Keybind({
        Text = "Quick action",
        Value = "K",
        Callback = function(_, _, processed)
                if not processed then
                        updateStatus("Quick action triggered")
                end
        end,
})

local Library = Window:Tab("Library", "layers")

local Collection = Library:Section("Collection")
local Entries = {
        { Text = "Workspace", Secondary = "Default collection", Icon = "folder", Trailing = "01" },
        { Text = "Favorites", Secondary = "Saved items", Icon = "star", Trailing = "02" },
        { Text = "Recent", Secondary = "Recently opened", Icon = "clock", Trailing = "03" },
        { Text = "Archive", Secondary = "Stored items", Icon = "package", Trailing = "04" },
}

local Selection
local Items = Collection:List({
        Height = 170,
        MaxHeight = 260,
        Flag = "collection",
        SelectionChanged = function(item)
                if Selection then
                        Selection:Set(item and item.Text or "Nothing selected")
                end
        end,
})

for _, item in ipairs(Entries) do
        Items:Add(item)
end

Selection = Collection:Paragraph("Nothing selected")

local ListActions = Collection:Row()
ListActions:Button({
        Text = "Add item",
        Callback = function()
                Items:Add({ Text = "New item", Secondary = "Custom entry", Icon = "folder" })
        end,
})

ListActions:Button({
        Text = "Remove",
        Callback = function()
                if Items.Selected then
                        Items:Remove(Items.Selected)
                        Selection:Set("Nothing selected")
                end
        end,
})

ListActions:Button({
        Text = "Restore",
        Callback = function()
                Items:SetItems(Entries)
                Selection:Set("Nothing selected")
        end,
})

local Media = Library:Section("Preview")
Media:Image({
        Image = "rbxthumb://type/GameIcon/id/" .. game.PlaceId .. "/w/150/h/150",
        Height = 112,
        ScaleType = "Fit",
        Title = "Current experience",
        Subtitle = tostring(game.PlaceId),
})

local Settings = Window:Tab("Settings", "settings")

local Interface = Settings:Section("Interface")
Interface:Toggle({
        Text = "Notifications",
        Value = true,
        Callback = function(value)
                Reborn.NotificationsEnabled = value
        end,
})

Interface:Keybind({
        Text = "Toggle window",
        Value = "Right Shift",
        Callback = function(_, _, processed)
                if not processed then
                        Window:Toggle()
                end
        end,
})

Window.ToggleKey = "Right Shift"

Interface:Button({
        Text = "Minimize",
        Callback = function()
                Window:Minimize()
        end,
})

local Configuration = Settings:Section("Configuration")
local Name = Configuration:Input({
        Text = "Profile",
        Value = "default",
        Placeholder = "Profile name",
})

local function profileName()
        return Name.Text ~= "" and Name.Text or "default"
end

local Profiles = Configuration:Row()
Profiles:Button({
        Text = "Save",
        Primary = true,
        Callback = function()
                local ok = Window:SaveConfig(profileName())
                Window:Notify({
                        Title = ok and "Profile saved" or "Save failed",
                        Type = ok and "success" or "error",
                })
        end,
})

Profiles:Button({
        Text = "Load",
        Callback = function()
                local config = Window:LoadConfig(profileName())
                Window:Notify({
                        Title = config and "Profile loaded" or "Profile not found",
                        Type = config and "success" or "error",
                })
        end,
})

Profiles:Button({
        Text = "Delete",
        Callback = function()
                local ok = Window:DeleteConfig(profileName())
                Window:Notify({
                        Title = ok and "Profile deleted" or "Profile not found",
                        Type = ok and "success" or "error",
                })
        end,
})
