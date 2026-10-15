local ADDON_NAME = ...
local bar, cells, pending = nil, {}, false
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
    local p = MiniSkillsDB.position
    if type(p) == "table" and type(p.x) == "number" and type(p.y) == "number" then
        bar:SetPoint("CENTER", UIParent, "BOTTOMLEFT", p.x, p.y)
    elseif MiniStatsFrame then
        bar:SetPoint("TOPLEFT", MiniStatsFrame, "BOTTOMLEFT", 0, -3)
    else
        bar:SetPoint("TOPLEFT", Minimap or UIParent, "BOTTOMLEFT", 0, -54)
    end
end
local function StartDrag() GameTooltip:Hide(); bar:StartMoving() end
local function StopDrag()
    bar:StopMovingOrSizing()
    local x, y = bar:GetCenter()
    if x and y then
        local scale = bar:GetEffectiveScale() / UIParent:GetEffectiveScale()
        MiniSkillsDB.position = {x = x * scale, y = y * scale}
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
        GameTooltip:AddLine("Mit linker Maustaste ziehen zum Verschieben", 0.7, 0.7, 0.7)
        GameTooltip:Show()
    end)
    cell:SetScript("OnLeave", function() GameTooltip:Hide() end)
    cell.icon = cell:CreateTexture(nil, "ARTWORK")
    cell.icon:SetSize(14, 14)
    cell.icon:SetPoint("LEFT", 1, 0)
    cell.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    cell.text = cell:CreateFontString(nil, "OVERLAY")
    cell.text:SetPoint("LEFT", cell.icon, "RIGHT", 3, 0)
    cell.text:SetFont(STANDARD_TEXT_FONT, 11, "OUTLINE")
    cell.text:SetShadowColor(0, 0, 0, 1)
    cell.text:SetShadowOffset(1, -1)
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
        if self.flashTime >= 0.9 then
            self.flash:Hide()
            self:SetScript("OnUpdate", nil)
        else
            self.flash:SetShown(self.flashTime % 0.3 < 0.14)
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
        cell:ClearAllPoints()
        cell:SetPoint("LEFT", bar, "LEFT", width, 0)
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
    bar:SetWidth(math.max(1, width - 12))
    bar:SetShown(#professions > 0)
end
local events = CreateFrame("Frame")
for _, event in ipairs({"ADDON_LOADED", "PLAYER_ENTERING_WORLD", "SKILL_LINES_CHANGED", "CHAT_MSG_SKILL",
    "PLAYER_LEVEL_UP", "UI_SCALE_CHANGED", "DISPLAY_SIZE_CHANGED"}) do
    events:RegisterEvent(event)
end
events:SetScript("OnEvent", function(_, event, name)
    if event == "ADDON_LOADED" then
        if name ~= ADDON_NAME or bar then return end
        MiniSkillsDB = type(MiniSkillsDB) == "table" and MiniSkillsDB or {}
        bar = CreateFrame("Frame", "MiniSkillsFrame", UIParent)
        bar:SetSize(140, 20)
        bar:SetFrameStrata("MEDIUM")
        bar:SetMovable(true)
        bar:SetClampedToScreen(true)
        bar:EnableMouse(true)
        bar:RegisterForDrag("LeftButton")
        bar:SetScript("OnDragStart", StartDrag)
        bar:SetScript("OnDragStop", StopDrag)
        RestorePosition()
    end
    if bar then pending = true end
    if bar and event == "PLAYER_ENTERING_WORLD" and not MiniSkillsDB.position then RestorePosition() end
end)
-- Read after event bursts, once the client's skill values have settled.
events:SetScript("OnUpdate", function()
    if pending then pending = false; Update() end
end)
SLASH_MINISKILLS1 = "/miniskills"
SlashCmdList.MINISKILLS = function(message)
    if not bar then return end
    if (message or ""):lower():match("^%s*reset%s*$") then
        MiniSkillsDB.position = nil
        RestorePosition()
    else print("MiniSkills: /miniskills reset - Position zuruecksetzen. Mit linker Maustaste ziehen.") end
end
