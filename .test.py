import sys,tempfile, pathlib
sys.path.insert(0,str(pathlib.Path(tempfile.gettempdir())/'minibars-lua-runtime'))
from lupa import LuaRuntime
lua=LuaRuntime()
lua.execute('''
frames={}
function RegisterEventCheck(self,event)
 assert(event ~= "LEARNED_SPELL_IN_TAB", "unsupported client event")
end
local methods={}
methods.RegisterEvent=RegisterEventCheck
function methods:SetScript(k,v) self.scripts[k]=v end
function methods:SetWidth(v) self.width=v end
function methods:GetWidth() return self.width or 100 end
function methods:GetStringWidth() return #(self.text or '')*6 end
function methods:SetText(v) self.text=v end
function methods:SetTextColor(...) self.color={...} end
function methods:Show() self.shown=true end
function methods:Hide() self.shown=false end
function methods:SetShown(v) self.shown=v end
function methods:GetCenter() return 100,200 end
function methods:GetEffectiveScale() return 1 end
local function object()
 local o={scripts={},shown=true}
 return setmetatable(o,{__index=function(t,k) if k=="skill" or k=="position" then return nil end; return methods[k] or function() end end})
end
function methods:CreateTexture() return object() end
function methods:CreateFontString() return object() end
function CreateFrame(_,name) local o=object(); frames[#frames+1]=o; if name then _G[name]=o end; return o end
UIParent=object(); Minimap=object(); GameTooltip=object(); SlashCmdList={}; STANDARD_TEXT_FONT='font'
rank=20; cap=75; level=60; learned=true
function UnitLevel() return level end
function GetProfessions() return nil,nil,nil,learned and 4 or nil end
function GetProfessionInfo() return 'Fishing',123,rank,cap,nil,nil,356 end
C_Spell={GetSpellName=function(id) if id==7620 then return 'Fishing' end end}
''')
lua.execute(pathlib.Path(__file__).with_name('LH_Skills.lua').read_text(encoding='utf-8'), 'LH_Skills')
lua.execute('''
local events=frames[1]
events.scripts.OnEvent(events,'ADDON_LOADED','LH_Skills')
events.scripts.OnUpdate()
local cell=frames[3]
assert(cell.text.text=='20/75')
assert(cell.text.color[2]==1 and cell.text.color[3]==1)
assert(cell.scripts.OnUpdate==nil)
rank=50; events.scripts.OnEvent(events,'SKILL_LINES_CHANGED'); events.scripts.OnUpdate()
assert(cell.text.color[3]==0 and cell.text.color[2]==1)
local flashes=1
local was=cell.flash.shown
for i=1,200 do
 if cell.scripts.OnUpdate then cell.scripts.OnUpdate(cell,0.01) end
 if cell.flash.shown and not was then flashes=flashes+1 end
 was=cell.flash.shown
end
assert(flashes==3 and not cell.flash.shown and cell.scripts.OnUpdate==nil)
rank=75; events.scripts.OnEvent(events,'SKILL_LINES_CHANGED'); events.scripts.OnUpdate()
assert(cell.text.color[2]==0.5)
cap=150; events.scripts.OnEvent(events,'SKILL_LINES_CHANGED'); events.scripts.OnUpdate()
assert(cell.text.color[3]==1)
cell.scripts.OnDragStop(); assert(LH_SkillsDB.position.x==100)
SlashCmdList.LH_SKILLS('reset'); assert(LH_SkillsDB.position==nil)
learned=false; events.scripts.OnEvent(events,'SKILL_LINES_CHANGED'); events.scripts.OnUpdate()
assert(not LH_SkillsFrame.shown and cell.skill==nil)
''')
print('PASS: loading, secondary slot gaps, white/yellow/orange, three flashes, cap upgrade, drag saving/reset, unlearning')
