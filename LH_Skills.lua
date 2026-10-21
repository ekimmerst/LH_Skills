local ADDON_NAME = ...
local Addon = {}
LH_Skills = Addon
local bar, cells, pending = nil, {}, false
local preview
local function Options()
    LH_SkillsDB = type(LH_SkillsDB) == "table" and LH_SkillsDB or {}
    if type(LH_SkillsDB.enabled) ~= "boolean" then LH_SkillsDB.enabled = true end
    if type(LH_SkillsDB.locked) ~= "boolean" then LH_SkillsDB.locked = true end
    if LH_SkillsDB.alignment ~= "LEFT" and LH_SkillsDB.alignment ~= "CENTER"
        and LH_SkillsDB.alignment ~= "RIGHT" then LH_SkillsDB.alignment = "LEFT" end
    if type(LH_SkillsDB.barWidth) ~= "number" then LH_SkillsDB.barWidth = 320 end
    LH_SkillsDB.barWidth = math.max(160, math.min(800, LH_SkillsDB.barWidth))
    return LH_SkillsDB
end
function Addon:GetOption(key) return Options()[key] end
local function CanTrain(s)
    local level = UnitLevel("player") or 0
    local free = s.id == 182 or s.id == 186 or s.id == 393 or s.id == 129 or s.id == 356
    if s.max == 75 then return s.rank >= 50 and level >= (free and 0 or 10) end
    if s.max == 150 then return s.rank >= 125 and level >= ((s.id == 182 or s.id == 186 or s.id == 393) and 0 or 20) end
    if s.max == 225 then return s.rank >= 200 and level >= ((s.id == 182 or s.id == 186 or s.id == 197) and 0 or 35) end
    return false
end
local function RestorePosition()
    bar:ClearAllPoints()
    local p = LH_SkillsDB.position
    if type(p) == "table" and type(p.x) == "number" and type(p.y) == "number" then
        bar:SetPoint("CENTER", UIParent, "BOTTOMLEFT", p.x, p.y)
    elseif LH_StatsFrame then
        bar:SetPoint("TOPLEFT", LH_StatsFrame, "BOTTOMLEFT", 0, -3)
    else
        bar:SetPoint("TOPLEFT", Minimap or UIParent, "BOTTOMLEFT", 0, -54)
    end
end
local function StartDrag()
    if Options().locked then return end
    GameTooltip:Hide()
    bar:StartMoving()
end
local function StopDrag()
    if Options().locked then return end
    bar:StopMovingOrSizing()
    local x, y = bar:GetCenter()
    if x and y then
        local scale = bar:GetEffectiveScale() / UIParent:GetEffectiveScale()
        LH_SkillsDB.position = {x = x * scale, y = y * scale}
    end
    RestorePosition()
end
local function CreateCell()
    local cell = CreateFrame("Frame", nil, bar)
    cell:SetHeight(20)
    cell:EnableMouse(true)
    cell:RegisterForDrag("LeftButton")
    cell:SetScript("OnDragStart", StartDrag)
    cell:SetScript("OnDragStop", StopDrag)
    cell:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOMLEFT")
        GameTooltip:AddLine(self.skill.name, 1, 0.82, 0)
        if not Options().locked then GameTooltip:AddLine("Left-drag to move", 0.7, 0.7, 0.7) end
        GameTooltip:Show()
    end)
    cell:SetScript("OnLeave", function() GameTooltip:Hide() end)
    cell.icon = cell:CreateTexture(nil, "ARTWORK")
    cell.icon:SetSize(14, 14)
    cell.icon:SetPoint("LEFT", 1, 0)
    cell.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    cell.text = cell:CreateFontString(nil, "OVERLAY")
    cell.text:SetPoint("LEFT", cell.icon, "RIGHT", 3, 0)
    local style = ObjectiveTrackerLineFont or GameFontHighlightSmall
    if style then
        cell.text:SetFontObject(style)
        local font, _, flags = style:GetFont()
        cell.text:SetFont(font, 10, flags or "")
    else
        cell.text:SetFont(STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF", 10, "")
        cell.text:SetShadowColor(0, 0, 0, 1)
        cell.text:SetShadowOffset(1, -1)
    end
    cell.flash = cell:CreateTexture(nil, "BACKGROUND")
    cell.flash:SetAllPoints()
    cell.flash:SetColorTexture(1, 1, 1, 0.35)
    cell.flash:Hide()
    return cell
end
local function Flash(cell)
    cell.flashTime = 0
    cell.flash:Show()
    cell:SetScript("OnUpdate", function(self, elapsed)
        self.flashTime = self.flashTime + elapsed
        if self.flashTime >= 1.8 then
            self.flash:Hide()
            self:SetScript("OnUpdate", nil)
        else
            self.flash:SetShown(self.flashTime % 0.6 < 0.28)
        end
    end)
end
-- Resolve localized names because Forever may return custom profession IDs.
local spells = {{2259,171},{2018,164},{7411,333},{4036,202},{2366,182},{2108,165},
    {2575,186},{8613,393},{3908,197},{2550,185},{3273,129},{7620,356}}
local function SkillLine(name, id)
    for _, entry in ipairs(spells) do
        local localized
        if C_Spell and C_Spell.GetSpellName then localized = C_Spell.GetSpellName(entry[1])
        elseif GetSpellInfo then localized = GetSpellInfo(entry[1]) end
        if name == localized then return entry[2] end
    end
    return id
end
local function Update()
    if not Options().enabled then bar:Hide(); return end
    local professions = {}
    -- Preserve nil gaps between unlearned profession slots and secondary skills.
    local function Add(...)
        for i = 1, select("#", ...) do
            local index = select(i, ...)
            if index then
                local name, icon, rank, maximum, _, _, id = GetProfessionInfo(index)
                if name and rank and maximum and maximum > 0 then
                    professions[#professions + 1] = {name=name, icon=icon, rank=rank, max=maximum, id=SkillLine(name,id)}
                end
            end
        end
    end
    Add(GetProfessions())
    local previous, width = {}, 0
    for _, cell in ipairs(cells) do
        if cell.skill then previous[cell.skill.name] = cell.skill end
    end
    for i, skill in ipairs(professions) do
        local cell = cells[i]
        if not cell then cell = CreateCell(); cells[i] = cell end
        local old = previous[skill.name]
        if not cell.skill or cell.skill.name ~= skill.name then
            cell:SetScript("OnUpdate", nil)
            cell.flash:Hide()
        end
        cell.skill = skill
        cell.icon:SetTexture(skill.icon)
        cell.text:SetText(string.format("%d/%d", skill.rank, skill.max))
        if skill.rank >= skill.max then cell.text:SetTextColor(1, 0.5, 0)
        elseif CanTrain(skill) then cell.text:SetTextColor(1, 1, 0)
        else cell.text:SetTextColor(1, 1, 1) end
        cell:SetWidth(18 + cell.text:GetStringWidth())
        width = width + cell:GetWidth() + 12
        cell:Show()
        if old and (old.rank ~= skill.rank or old.max ~= skill.max) then Flash(cell) end
    end
    for i = #professions + 1, #cells do
        cells[i]:Hide()
        cells[i]:SetScript("OnUpdate", nil)
        cells[i].flash:Hide()
        cells[i].skill = nil
    end
    local contentWidth = math.max(0, width - 12)
    local barWidth = math.max(Options().barWidth, contentWidth)
    bar:SetWidth(barWidth)
    local offset = Options().alignment == "CENTER" and (barWidth - contentWidth) / 2
        or Options().alignment == "RIGHT" and (barWidth - contentWidth) or 0
    for i = 1, #professions do
        local cell = cells[i]
        cell:ClearAllPoints()
        cell:SetPoint("LEFT", bar, "LEFT", offset, 0)
        offset = offset + cell:GetWidth() + 12
    end
    preview:SetShown(#professions == 0 and not Options().locked)
    bar:SetShown(#professions > 0 or not Options().locked)
end
function Addon:SetOption(key, value)
    local db = Options()
    if key == "enabled" or key == "locked" then
        if bar and not db.locked and ((key == "locked" and value) or (key == "enabled" and not value)) then
            StopDrag()
        end
        db[key] = not not value
    elseif key == "alignment" and (value == "LEFT" or value == "CENTER" or value == "RIGHT") then
        db.alignment = value
    elseif key == "barWidth" and type(value) == "number" then
        db.barWidth = math.max(160, math.min(800, value))
    else return end
    if bar then Update() end
    if self.RefreshSettings then self:RefreshSettings() end
end
function Addon:ResetPosition()
    Options().position = nil
    if bar then RestorePosition() end
end
local events = CreateFrame("Frame")
for _, event in ipairs({"ADDON_LOADED", "PLAYER_ENTERING_WORLD", "SKILL_LINES_CHANGED", "CHAT_MSG_SKILL",
    "PLAYER_LEVEL_UP", "UI_SCALE_CHANGED", "DISPLAY_SIZE_CHANGED"}) do
    events:RegisterEvent(event)
end
events:SetScript("OnEvent", function(_, event, name)
    if event == "ADDON_LOADED" then
        if name ~= ADDON_NAME or bar then return end
        Options()
        bar = CreateFrame("Frame", "LH_SkillsFrame", UIParent)
        bar:SetSize(140, 20)
        bar:SetFrameStrata("MEDIUM")
        bar:SetMovable(true)
        bar:SetClampedToScreen(true)
        bar:EnableMouse(true)
        bar:RegisterForDrag("LeftButton")
        bar:SetScript("OnDragStart", StartDrag)
        bar:SetScript("OnDragStop", StopDrag)
        preview = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        preview:SetPoint("CENTER", bar, "CENTER")
        preview:SetText("LH Skills - drag to move")
        preview:Hide()
        RestorePosition()
    end
    if bar then pending = true end
    if bar and event == "PLAYER_ENTERING_WORLD" and not LH_SkillsDB.position then RestorePosition() end
end)
-- Read after event bursts, once the client's skill values have settled.
events:SetScript("OnUpdate", function()
    if pending then pending = false; Update() end
end)
SLASH_LH_SKILLS1 = "/lh_skills"
SlashCmdList.LH_SKILLS = function(message)
    if not bar then return end
    local command = (message or ""):lower():match("^%s*(.-)%s*$")
    if command == "" and Addon.category and Settings and Settings.OpenToCategory then
        Settings.OpenToCategory(Addon.category:GetID())
    elseif command == "reset" then Addon:ResetPosition()
    elseif command == "unlock" then Addon:SetOption("locked", false)
    elseif command == "lock" then Addon:SetOption("locked", true)
    elseif command == "on" then Addon:SetOption("enabled", true)
    elseif command == "off" then Addon:SetOption("enabled", false)
    else print("LH_Skills: /lh_skills on | off | unlock | lock | reset") end
end
