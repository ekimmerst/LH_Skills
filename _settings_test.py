from pathlib import Path

addon = Path(__file__).resolve().parent
root = addon.parent
exec((addon / '.test.py').read_text(encoding='utf-8'))
lua.execute('''
registry={};controls={};buttons={};notices={};Settings={}
function Settings.RegisterVerticalLayoutSubcategory(parent,title)
 local category={parent=parent,title=title}
 function category:GetID() return self.title end
 local layout={rows={}}
 function layout:AddInitializer(row) self.rows[#self.rows+1]=row end
 category.layout=layout
 return category,layout
end
function Settings.RegisterAddOnCategory(category) registered=category end
function Settings.RegisterProxySetting(category,variable,kind,label,default,get,set)
 local setting={variable=variable,kind=kind,label=label,default=default,get=get,set=set}
 registry[variable]=setting;return setting
end
local function Control(category,setting)
 local row={setting=setting}
 function row:SetParentInitializer(parent,predicate) self.parent=parent;self.predicate=predicate end
 category.layout:AddInitializer(row);controls[setting.variable]=row;return row
end
function Settings.CreateCheckbox(category,setting) return Control(category,setting) end
function Settings.CreateDropdown(category,setting,getOptions)
 local row=Control(category,setting);row.getOptions=getOptions;return row
end
function Settings.CreateSliderOptions(minimum,maximum,step)
 local result={minimum=minimum,maximum=maximum,step=step}
 function result:SetLabelFormatter() end
 return result
end
function Settings.CreateSlider(category,setting,options)
 local row=Control(category,setting);row.options=options;return row
end
function Settings.CreateControlTextContainer()
 local result={data={}}
 function result:Add(value,label) self.data[#self.data+1]={value=value,label=label} end
 function result:GetData() return self.data end
 return result
end
function Settings.NotifyUpdate(variable) notices[variable]=(notices[variable] or 0)+1 end
function Settings.OpenToCategory(id) opened=id end
function CreateSettingsListSectionHeaderInitializer(title) return {header=title} end
function CreateSettingsButtonInitializer(label,button,callback)
 buttons[button]=callback;return {label=label,button=button}
end
MinimalSliderWithSteppersMixin={Label={Right=1}}
LH_Tweaks={category={},modules={}}
''')
source = (root / 'LH_Tweaks/LH_Tweaks.lua').read_text(encoding='utf-8')
registration = source.split('function Hub:RegisterModule(id, title, build)')[1].split('\nfunction Hub:RestoreDefaults')[0]
lua.execute('local Hub=LH_Tweaks\nfunction Hub:RegisterModule(id, title, build)' + registration)
source = (root / 'LH_Tweaks/Settings.lua').read_text(encoding='utf-8')
registration = source.split('function Hub:RegisterModulePage(id)')[1].split('\nlocal function RegisterSettings')[0]
lua.execute('local Hub=LH_Tweaks\nfunction Hub:RegisterModulePage(id)' + registration)
lua.execute((addon / 'Settings.lua').read_text(encoding='utf-8'), 'LH_Skills')
lua.execute('''
assert(registered.parent==LH_Tweaks.category and registered.title=='LH Skills')
assert(registered.layout.rows[1].header=='Positioning')
assert(registered.layout.rows[2]==controls.LH_Skills_locked and controls.LH_Skills_locked.parent==nil)
assert(registry.LH_Skills_enabled.default==true)
assert(registry.LH_Skills_locked.default==true and registry.LH_Skills_locked.get())
assert(registry.LH_Skills_alignment.default=='LEFT')
assert(registry.LH_Skills_barWidth.default==320)
local choices=controls.LH_Skills_alignment.getOptions()
assert(#choices==3 and choices[1].value=='LEFT' and choices[2].value=='CENTER' and choices[3].value=='RIGHT')
assert(controls.LH_Skills_barWidth.options.minimum==160 and controls.LH_Skills_barWidth.options.maximum==800)
registry.LH_Skills_locked.set(false)
assert(not LH_SkillsDB.locked and LH_SkillsFrame.shown)
registry.LH_Skills_alignment.set('CENTER')
assert(LH_SkillsDB.alignment=='CENTER')
registry.LH_Skills_barWidth.set(430)
assert(LH_SkillsDB.barWidth==430 and LH_SkillsFrame.width==430)
registry.LH_Skills_enabled.set(false)
assert(not LH_SkillsFrame.shown)
registry.LH_Skills_enabled.set(true)
assert(LH_SkillsFrame.shown)
SlashCmdList.LH_SKILLS('');assert(opened=='LH Skills')
LH_SkillsDB.position={x=9,y=13}
buttons['Reset position']()
assert(LH_SkillsDB.position==nil)
assert(not LH_SkillsDB.locked and LH_SkillsDB.alignment=='CENTER')
''')
for extension in ('png', 'tga'):
    assert (addon / f'Media/Icon.{extension}').read_bytes() == (root / f'LH_Tweaks/Icon.{extension}').read_bytes()
print('PASS: native settings, three-way group alignment, width, unlock preview, activation, reset position and shared icons')
