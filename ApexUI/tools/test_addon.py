"""Named layout and picker regressions on the standalone backend.
Legacy provider/Edit Mode placement assertions were superseded by
 test_profile_migration.py and test_toolbar_dock.py.
"""
from pathlib import Path
import runpy
ctx=runpy.run_path(str(Path(__file__).with_name('test_standalone.py')))
lua=ctx['lua'];ROOT=ctx['ROOT']
def loader(source): lua.execute(source,'ApexUI',lua.globals().A)
lua.execute("""
playerName='First Hunter';playerClass='HUNTER'
function UnitClass() return playerClass,playerClass end
function equal(a,b)
 if type(a)~=type(b) then return false end
 if type(a)~='table' then return a==b end
 for k,v in pairs(a) do if not equal(v,b[k]) then return false end end
 for k in pairs(b) do if a[k]==nil then return false end end
 return true
end
""")
loader((ROOT/'Layouts.lua').read_text())
lua.execute('''
function UnitName() return playerName end
function time() return 123456 end
ApexUICharacterDB.customLayout=false
A.InitLayoutLibrary()
local seed=ApexUIDB.sharedLayoutId
assert(A.CurrentLayoutName()=="Apex Default")
local count=#A.LayoutList();A.InitLayoutLibrary();assert(#A.LayoutList()==count)
assert(not A.SaveNamedLayout(" ") and not A.SaveNamedLayout("Bad|cffffff00"))
local originalShared=A.Copy(A.Active())
local id=A.SaveNamedLayout("  Raid Layout  ")
assert(id and ApexUIDB.layouts[id].name=="Raid Layout")
assert(not A.SaveNamedLayout("raid layout"),"Duplicate name overwrote a save")
assert(A.CurrentLayoutName()=="Apex Default","Saving silently changed the active scope/name")
A.Edit(function(u) u.player.frameWidth=333 end)
assert(ApexUIDB.layouts[id].snapshot.addons[A.UF].player.frameWidth~=333,"Saved copy aliases live data")
assert(A.UpdateNamedLayout(id))
assert(ApexUIDB.layouts[id].previousSnapshot.addons[A.UF].player.frameWidth~=333)
assert(A.RenameLayout(id,"Raid night"))
assert(not A.RenameLayout(id,"Apex Default"))
local saved=A.Copy(ApexUIDB.layouts[id].snapshot)
local sharedBefore=A.Copy(A.Active())
assert(A.LoadNamedLayout(id,"character"))
assert(ApexUICharacterDB.customLayout and A.CurrentLayoutName()=="Raid night")
A.Edit(function(u) u.player.frameWidth=310 end)
assert(equal(A.ProfileDB.profiles[ApexUIDB.sharedProfile],sharedBefore),"Character load/edits changed shared default")
assert(equal(ApexUIDB.layouts[id].snapshot,saved),"Live edits overwrote named save")
A.UseSharedDefault();assert(not ApexUICharacterDB.customLayout)
assert(A.CurrentLayoutName()=="Apex Default")
assert(A.LoadNamedLayout(id,"shared") and A.CurrentLayoutName()=="Raid night")
assert(A.Active().addons[A.UF].player.frameWidth==333)
A.UndoTemplate();assert(A.CurrentLayoutName()=="Apex Default","Undo kept the loaded layout's name")
assert(A.LoadNamedLayout(id,"shared"))
local retained=A.Copy(ApexUIDB.layouts)
A.ready=nil;ApexUICharacterDB=nil;playerName="Second Paladin";playerClass="PALADIN"
assert(A.Initialize());A.InitLayoutLibrary()
assert(not ApexUICharacterDB.customLayout and A.CurrentLayoutName()=="Raid night")
assert(A.Active().addons[A.UF].player.frameWidth==333)
assert(equal(ApexUIDB.layouts,retained),"Relog rebuilt the named library")
combat=true
assert(not A.SaveNamedLayout("Combat") and not A.RenameLayout(id,"Combat") and not A.UpdateNamedLayout(id) and not A.LoadNamedLayout(id,"character"))
assert(equal(ApexUIDB.layouts,retained));combat=false
A.Backend._unlockModeSessionActive=true
assert(not A.SaveNamedLayout("Moving"));A.Backend._unlockModeSessionActive=false
for i=1,9 do assert(A.SaveNamedLayout("Test "..i)) end
-- Exercise native panel construction and the real callbacks with simple widget doubles.
widgets={};UISpecialFrames={}
local methods={}
function methods:SetText(v) self.text=v end
function methods:GetText() return self.text or "" end
function methods:SetSize(w,h) self.width=w;self.height=h end
function methods:SetPoint(...) self.point={...} end
function methods:SetScript(event,fn) self.scripts[event]=fn end
function methods:SetShown(show) self.shown=show end
function methods:Show() self.shown=true end
function methods:Hide() self.shown=false end
function methods:IsShown() return self.shown end
function methods:SetEnabled(enable) self.enabled=enable end
function methods:CreateFontString() return CreateFrame("FontString",nil,self) end
function methods:GetFontString() self.font=self.font or self:CreateFontString();return self.font end
function CreateFrame(kind,name,parent)
 local f={kind=kind,name=name,parent=parent,scripts={},shown=true,enabled=true}
 setmetatable(f,{__index=function(_,key) return methods[key] or (key:match("^[A-Z]") and function() end) end})
 widgets[#widgets+1]=f;return f
end
''')
loader((ROOT/'Options.lua').read_text())
lua.execute('''
A.ToggleOptions();local p=A.panel
assert(p and #p.rows==5 and p.pageText:GetText()=="1 / 3")
assert(p.active:GetText():find("EDITING SHARED DEFAULT",1,true))
p.next.scripts.OnClick();assert(p.page==2)
p.rows[2].scripts.OnClick(p.rows[2]);assert(p.name:GetText()==ApexUIDB.layouts[p.rows[2].id].name)
p.name:SetText("New UI Save")
for _,w in ipairs(widgets) do if w.text=="Save current as new" then w.scripts.OnClick();break end end
assert(ApexUIDB.layouts[A.selectedLayoutId].name=="New UI Save")
assert(p.name:GetText()=="New UI Save")
combat=true;A.UpdateOptions()
for _,b in ipairs(p.editButtons) do assert(not b.enabled) end
for _,b in ipairs(p.selectionButtons) do assert(not b.enabled) end
combat=false;A.UpdateOptions();assert(p.selectionButtons[1].enabled)
''')
print('PASS: named saves/rename/update, validation, snapshot isolation, character/shared loads, undo labels, relog persistence, combat/mover guards, picker construction, paging, selection, save callback and disabled states.')
