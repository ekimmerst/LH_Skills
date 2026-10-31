local addonName = ...
local Addon = LH_Skills
local variables = {}

function Addon:RefreshSettings()
    if self.notifying or not Settings or not Settings.NotifyUpdate then return end
    self.notifying = true
    for _, variable in ipairs(variables) do Settings.NotifyUpdate(variable) end
    self.notifying = false
end

local function Proxy(category, key, kind, label, default, get, set)
    local variable = "LH_Skills_" .. key
    variables[#variables + 1] = variable
    return Settings.RegisterProxySetting(category, variable, kind, label, default, get, set)
end

local function Build(category, layout)
    Addon.category = category
    layout:AddInitializer(CreateSettingsListSectionHeaderInitializer("Positioning"))
    local locked = Proxy(category, "locked", "boolean", "Lock skill bar", true,
        function() return Addon:GetOption("locked") end,
        function(value) Addon:SetOption("locked", value) end)
    Settings.CreateCheckbox(category, locked,
        "Disable to drag the skill bar. A preview remains visible while unlocked, even with no learned skills. Saved per character.")

    layout:AddInitializer(CreateSettingsListSectionHeaderInitializer("Profession skills"))
    local enabled = Proxy(category, "enabled", "boolean", "Enable skill display", true,
        function() return Addon:GetOption("enabled") end,
        function(value) Addon:SetOption("enabled", value) end)
    local parent = Settings.CreateCheckbox(category, enabled,
        "Show learned profession and secondary skill ranks. Saved per character.")

    local alignment = Proxy(category, "alignment", "string", "Skill group alignment", "LEFT",
        function() return Addon:GetOption("alignment") end,
        function(value) Addon:SetOption("alignment", value) end)
    local function AlignmentOptions()
        local container = Settings.CreateControlTextContainer()
        container:Add("LEFT", "Left", "Place the whole skill group at the left edge of the bar.")
        container:Add("CENTER", "Center", "Center the whole skill group within the bar width.")
        container:Add("RIGHT", "Right", "Place the whole skill group at the right edge of the bar.")
        return container:GetData()
    end
    local alignmentControl = Settings.CreateDropdown(category, alignment, AlignmentOptions,
        "Align the whole set of skill icons and values within the configured bar width. Saved per character.")
    alignmentControl:SetParentInitializer(parent, function() return Addon:GetOption("enabled") end)

    local width = Proxy(category, "barWidth", "number", "Skill bar width", 320,
        function() return Addon:GetOption("barWidth") end,
        function(value) Addon:SetOption("barWidth", value) end)
    local options = Settings.CreateSliderOptions(160, 800, 10)
    options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right,
        function(value) return string.format("%.0f", value) end)
    local widthControl = Settings.CreateSlider(category, width, options,
        "Available width for aligning the whole skill group. The bar grows if its contents need more room. Saved per character.")
    widthControl:SetParentInitializer(parent, function() return Addon:GetOption("enabled") end)

    layout:AddInitializer(CreateSettingsButtonInitializer("Restore the position below LH Stats or the minimap",
        "Reset position", function() Addon:ResetPosition() end,
        "Keep activation, lock state, alignment and bar width.", true))
end

LH_Tweaks:RegisterModule(addonName, "LH Skills", Build)
