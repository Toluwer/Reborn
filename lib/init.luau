local Theme = require(script.Theme)
local createCore = require(script.Core)
local createAnimation = require(script.Animation)
local createFade = require(script.Fade)
local createIcons = require(script.Icons)
local createNotifications = require(script.Notifications)
local createWindow = require(script.Window)
local attachConfig = require(script.Config)
local createNavigation = require(script.Navigation)
local createPopovers = require(script.Popovers)
local createLifecycle = require(script.Lifecycle)
local createInput = require(script.InputRouter)
local createComponentContext = require(script.ComponentContext)
local bindKeybinds = require(script.Keybinds)
local createWidget = require(script.Widget)
local createTooltip = require(script.Tooltip)
local createPillLayout = require(script.PillLayout)

local Components = {
    Toggle = require(script.Components.Toggle),
    Slider = require(script.Components.Slider),
    ProgressBar = require(script.Components.ProgressBar),
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
    _widgets = {},
    _configs = {},
}

Reborn.Theme = Theme.Default
local Core = createCore(Theme, createAnimation, createFade)
local Icons = createIcons(Core)
local Notifications = createNotifications(Reborn, Core, Theme, Icons)
createWindow(Reborn, Core, Theme, Icons, Notifications, Components, attachConfig, createNavigation, createPopovers, createLifecycle, createInput, createComponentContext, bindKeybinds, createTooltip, createPillLayout)
createWidget(Reborn, Core, Theme, Icons, Notifications, Components, attachConfig, createPopovers, createLifecycle, createInput, createComponentContext, bindKeybinds, createTooltip)

function Reborn:Unload()
    for _, widget in ipairs(table.clone(self._widgets)) do
        pcall(function() widget:Destroy() end)
    end
    table.clear(self._widgets)
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
