local Theme = require(script.Theme)
local createCore = require(script.Core)
local createIcons = require(script.Icons)
local createNotifications = require(script.Notifications)
local createWindow = require(script.Window)
local attachConfig = require(script.Config)
local createNavigation = require(script.Navigation)
local createPopovers = require(script.Popovers)

local Components = {
    Toggle = require(script.Components.Toggle),
    Slider = require(script.Components.Slider),
    Dropdown = require(script.Components.Dropdown),
    Keybind = require(script.Components.Keybind),
    ColorPicker = require(script.Components.ColorPicker),
    Input = require(script.Components.Input),
    Button = require(script.Components.Button),
    Paragraph = require(script.Components.Paragraph),
    Image = require(script.Components.Image),
    List = require(script.Components.List),
    Row = require(script.Components.Row),
}

local Reborn = {
    Version = "0.9.8",
    NotificationsEnabled = true,
    _windows = {},
    _configs = {},
}

Reborn.Theme = Theme.Default
local Core = createCore(Theme)
local Icons = createIcons(Core)
local Notifications = createNotifications(Reborn, Core, Theme, Icons)
createWindow(Reborn, Core, Theme, Icons, Notifications, Components, attachConfig, createNavigation, createPopovers)

function Reborn:Unload()
    for i = #self._windows, 1, -1 do
        pcall(function() self._windows[i]:Destroy() end)
    end
    self._windows = {}
    if self._toastGui then
        pcall(function() self._toastGui:Destroy() end)
        self._toastGui = nil
        self._toastLayer = nil
    end
end

Reborn.Destroy = Reborn.Unload

return Reborn
