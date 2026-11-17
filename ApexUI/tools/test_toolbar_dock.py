from pathlib import Path
from lupa.lua51 import LuaRuntime
ROOT=Path(__file__).resolve().parents[1]
lua=LuaRuntime(unpack_returned_tuples=True)
source=(ROOT/'tools/test_standalone.py').read_text()
lua.execute(source.split("lua.execute(r'''",1)[1].split("''')",1)[0])
lua.execute('''
A.Suite={modules={fishing={status='loaded'}}};A.Copy=function(v) return v end
ApexUICharacterDB={};Questie={db={profile={TrackerLocation={'old'}}}}
Questie_BaseFrame=CreateFrame('Frame');Minimap=CreateFrame('Frame');Minimap:SetSize(370,370)
''')
lua.execute((ROOT/'Toolbar.lua').read_text(),'ApexUI',lua.globals().A)
lua.execute('''
local S=A.Suite
for _,width in ipairs({180,300,370,500}) do for count=1,40 do
 local cols,rows,height=S.ToolbarGeometry(width,count)
 assert(cols*142+16<=width and rows*cols>=count and height>=88)
end end
S.CreateToolkit();assert(not S.toolbar:IsShown());S.ToggleToolkit();assert(S.toolbar:IsShown())
assert(S.toolbar:GetWidth()==300 and S.toolbar:GetHeight()==232)
local _,_,_,_,initialY=Questie_BaseFrame:GetPoint()
for i=1,12 do S.RegisterToolbarEntry({'test'..i,'Test','Description','Trade_Fishing'}) end
assert(S.toolbar:GetHeight()==520)
local _,_,_,_,expandedY=Questie_BaseFrame:GetPoint();assert(expandedY==initialY)
assert(#S.toolbarEntries==19)
S.RegisterToolbarEntry({'test1','Changed','Description','Trade_Fishing'});assert(#S.toolbarEntries==19)
local oldHeight=S.toolbar:GetHeight();combat=true
S.RegisterToolbarEntry({'new','New','Description','Trade_Fishing'});assert(S.toolbar:GetHeight()==oldHeight)
combat=false;S.LayoutToolbar()
assert(ApexUICharacterDB.utilityQuestieBackup[1]=='old')
local opened
S.Open=function(key) opened=key end;A.ToggleFeatures=function() opened='features' end
S.toolbar.buttons.fishing.scripts.OnClick(S.toolbar.buttons.fishing,'LeftButton');assert(opened=='fishing' and not S.toolbar:IsShown())
S.toolbar.buttons.fishing.scripts.OnClick(S.toolbar.buttons.fishing,'RightButton');assert(opened=='features')
S.toolbar.buttons.navigation.scripts.OnClick(S.toolbar.buttons.navigation,'LeftButton');assert(opened=='features')
''')
for p in [ROOT/'Utility.lua']:
 lua.execute('assert(loadstring(...))',p.read_text())
assert 'EllesmereUI' not in (ROOT/'Toolbar.lua').read_text()
lua.execute('''
UIParent:SetSize(2400,1080)
ApexBar_MainBar=CreateFrame('Frame');ApexBar_MainBar:SetSize(1750,50)
MicroMenuContainer=CreateFrame('Frame',nil,UIParent);MicroMenuContainer:SetSize(400,40);MicroMenuContainer.system=1
BagsBar=CreateFrame('Frame',nil,UIParent);BagsBar:SetSize(300,50);BagsBar.system=2
local live={bars={{name='Right status'}}}
local profile={apexUtilityDock='bottom',addons={EllesmereUIDataBars={bars={{name='Right status'}}}}}
A.Active=function() return profile end;A.OwnActive=function() return true end;A.Print=function() end
local blob={activeLayout=1,layouts={{systems={{system=1},{system=2}}}}}
A.Backend={EditModeOpen=function() return false end,EditModeLayoutsForSave=function() return blob,0 end,
 _ModuleNS={EllesmereUIDataBars={GetProfile=function() return live end}}}
EllesmereUI=A.Backend;EditModeManagerFrame={accountSettings={}}
C_EditMode={SaveLayouts=function(v) saved=v end,SetActiveLayout=function() end}
''')
lua.execute((ROOT/'Utility.lua').read_text(),'ApexUI',lua.globals().A)
lua.execute('''
assert(A.PlaceNativeUtilities())
local mp={MicroMenuContainer:GetPoint()};local bp={BagsBar:GetPoint()}
assert(mp[1]=='BOTTOMRIGHT' and bp[1]=='BOTTOMRIGHT')
local ms=MicroMenuContainer:GetEffectiveScale();local bs=BagsBar:GetEffectiveScale()
assert(math.abs(mp[4]*ms-bp[4]*bs)<.001)
local menuHeight=MicroMenuContainer:GetHeight()*ms
assert(bp[5]*bs>=mp[5]*ms+menuHeight+3.99)
local bounds=A.utilityBounds
assert(bounds.width==440)
assert(UIParent:GetWidth()-bounds.left-bounds.width==14)
assert(bounds.bottom==14)
local profile=A.Active();profile.apexUtilityDock='top'
A.Shell={map=CreateFrame('Frame',nil,UIParent)};A.Shell.map:SetSize(374,374)
assert(A.PlaceNativeUtilities())
local top=A.utilityBounds;assert(top.mapDock and top.width==374)
assert(math.abs(top.bottom+top.height-(UIParent:GetHeight()-14))<.001)
local upper={MicroMenuContainer:GetPoint()};local lower={BagsBar:GetPoint()}
assert(upper[5]*MicroMenuContainer:GetEffectiveScale()>lower[5]*BagsBar:GetEffectiveScale())
assert(({A.Shell.map:GetPoint()})[5]==-14-top.height-12)
combat=true;assert(A.PlaceNativeUtilities()==nil);combat=false
''')
print('PASS: right-aligned utility stack, toolkit toggle and auto-close, feature growth, tracker clearance, combat deferral, Lua syntax')
