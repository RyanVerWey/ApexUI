from pathlib import Path
from lupa.lua51 import LuaRuntime

ROOT=Path(__file__).resolve().parents[1]
lua=LuaRuntime(unpack_returned_tuples=True)
compile_lua=lua.eval('function(s,n) local f,e=loadstring(s,n); assert(f,e) end')
toc=(ROOT/'ApexUI.toc').read_text().splitlines()
runtime=[ROOT/x.replace('\\','/') for x in toc if x.endswith('.lua')]
for path in runtime:
    compile_lua(path.read_text(encoding='utf-8-sig'),str(path))
lua.execute('''
frames={}; SlashCmdList={}; ApexUICharacterDB={features={fishing=false}}
ApexUIStorage={ApexNavigator=true,ApexFishing=true,ApexGrind=true,ApexProfessions=true}
function CreateFrame()
 local f={events={},scripts={}}
 function f:RegisterEvent(e) self.events[e]=true end
 function f:UnregisterEvent(e) self.events[e]=nil end
 function f:UnregisterAllEvents() self.events={} end
 function f:IsEventRegistered(e) return self.events[e] end
 function f:SetScript(e,v) self.scripts[e]=v end
 function f:GetScript(e) return self.scripts[e] end
 function f:Hide() self.hidden=true end
 frames[#frames+1]=f;return f
end
function InCombatLockdown() return combat end
function ReloadUI() reloads=(reloads or 0)+1 end
A={}; hits={}; oldData={marker=71}; ApexGrindDB=oldData
''')
lua.execute((ROOT/'Suite.lua').read_text(),'ApexUI',lua.globals().A)
lua.execute('''
local S=A.Suite
for _,key in ipairs(S.order) do
 S.Register(key,'test',function(name,ns)
  assert(ns.suiteManaged);ns.owner=name
  hits[key]=(hits[key] or 0)+1
  local f=S.CreateFrame(key);f:RegisterEvent('ADDON_LOADED');f:RegisterEvent('PLAYER_LOGIN')
  f:SetScript('OnEvent',function(self,event,id)
   if event=='ADDON_LOADED' then assert(id==name);ns.init=(ns.init or 0)+1 end
   if event=='PLAYER_LOGIN' then ns.login=(ns.login or 0)+1 end
  end)
 end)
end
assert(next(hits)==nil)
frames[1].scripts.OnEvent(frames[1],'ADDON_LOADED','Unrelated');assert(next(hits)==nil)
frames[1].scripts.OnEvent(frames[1],'ADDON_LOADED','ApexUI');S.Start()
assert(hits.navigation==1 and hits.fishing==nil and hits.grinding==1 and hits.professions==1)
assert(S.modules.fishing.status=='disabled' and #S.modules.fishing.frames==0)
assert(S.modules.navigation.ns.init==1 and S.modules.professions.ns.init==1)
assert(S.modules.navigation.ns~=S.modules.professions.ns)
for _,f in ipairs(frames) do if f.events.PLAYER_LOGIN then f.scripts.OnEvent(f,'PLAYER_LOGIN') end end
assert(S.modules.grinding.ns.login==1)
assert(ApexGrindDB==oldData and ApexGrindDB.marker==71)
assert(not S.Pending());S.SetEnabled('fishing',true);assert(S.Pending())
assert(hits.fishing==nil);S.SetEnabled('fishing',false);assert(not S.Pending())
combat=true;S.Apply();assert(reloads==nil);combat=false;S.Apply();assert(reloads==1)
SlashCmdList.APEXGRIND=function(arg) assert(arg=='show');opened=true end
S.Open('grinding');assert(opened)
''')
# Exercise the bundled profession engine, not just synthetic host chunks.
v=LuaRuntime(unpack_returned_tuples=True)
base=ROOT/'Source/ApexProfessions'
mock=v.execute((base/'upstream/tests/wowmock.lua').read_text())
fx=v.execute((base/'upstream/tests/fixtures/yungzug.lua').read_text())
ns=v.table(); mock.install(fx,ns)
v.globals().host=v.table();v.globals().mock=mock
v.execute('''
tinsert=table.insert
ApexUICharacterDB={features={navigation=false,fishing=false,grinding=false}}
ApexUIStorage={ApexProfessions=true}
local original=CreateFrame
CreateFrame=function(...)
 local f=original(...)
 f.IsEventRegistered=function(self,e) return self.events[e] end
 return f
end
''')
v.execute((ROOT/'Suite.lua').read_text(),'ApexUI',v.globals().host)
for path in runtime:
    if 'Modules' in path.parts:
        v.execute(path.read_text(encoding='utf-8-sig'),'ApexUI',v.globals().host)
mock.fire('ADDON_LOADED','ApexUI');mock.fire('PLAYER_LOGIN')
v.execute('''
local m=host.Suite.modules.professions
assert(m.status=='loaded',m.error)
assert(m.ns.db and m.ns.Apex and m.ns.UI)
assert(SlashCmdList.APEXPROFESSIONS)
assert(not ApexProfessionsMinimapButton)
host.Suite.Open('professions')
assert(ApexProfessionsGuideFrame:IsShown())
''')
v.execute('''
local original=CreateFrame
CreateFrame=function(...)
 local f=original(...)
 f.GetFontString=function(self) self.font=rawget(self,'font') or self:CreateFontString();return self.font end
 f.CreateMaskTexture=function(self) return self:CreateTexture() end
 f.SetChecked=function(self,value) self.checked=value end
 f.GetChecked=function(self) return self.checked end
 return f
end
''')
v.execute((ROOT/'Features.lua').read_text(),'ApexUI',v.globals().host)
v.execute('InCombatLockdown=function() return false end')
v.execute((ROOT/'Toolbar.lua').read_text(),'ApexUI',v.globals().host)
mock.fire('PLAYER_ENTERING_WORLD')
v.execute('''
local S=host.Suite
assert(S.toolbar and S.toolbar.buttons.professions and S.toolbar.buttons.features)
host.ToggleFeatures();assert(S.frame:IsShown())
assert(S.frame.rows.professions.check:GetChecked())
assert(not S.frame.rows.fishing.check:GetChecked())
local b=S.frame.rows.fishing.check;b:SetChecked(true);b:GetScript('OnClick')(b)
assert(S.Enabled('fishing') and S.Pending() and not S.frame.reload.disabled)
b:SetChecked(false);b:GetScript('OnClick')(b);assert(not S.Pending())
S.toolbar.buttons.professions:GetScript('OnClick')(S.toolbar.buttons.professions,'LeftButton')
assert(ApexProfessionsGuideFrame:IsShown() and not S.frame:IsShown())
S.toolbar.buttons.fishing:GetScript('OnClick')(S.toolbar.buttons.fishing,'LeftButton')
assert(S.frame:IsShown())
''')
# A failed module must not prevent another feature from starting or overwrite data.
lua.execute('''
A={};frames={};ApexUICharacterDB={features={fishing=false}}
ApexUIStorage={ApexNavigator=true,ApexGrind=true}
''')
lua.execute((ROOT/'Suite.lua').read_text(),'ApexUI',lua.globals().A)
lua.execute('''
local S=A.Suite
S.Register('navigation','broken',function() local f=S.CreateFrame('navigation');f:RegisterEvent('BAD');error('intentional') end)
S.Register('grinding','healthy',function() healthy=true end)
S.Register('professions','missing storage',function() error('must not execute') end)
S.Start()
assert(S.modules.navigation.status=='error' and next(S.modules.navigation.frames[1].events)==nil)
assert(S.modules.grinding.status=='loaded' and healthy)
assert(S.modules.professions.status=='error' and #S.modules.professions.frames==0)
assert(ApexGrindDB==oldData)
''')
for name in ('ApexNavigator','ApexFishing','ApexGrind','ApexProfessions'):
    lines=(ROOT.parent/name/(name+'.toc')).read_text().splitlines()
    assert [s for s in lines if s.endswith('.lua')]==['Bridge.lua']
    assert any(s.startswith('## SavedVariables') for s in lines)
# Focus management uses real show/hide hooks, including active fishing controls.
v.execute('''
local original=CreateFrame
CreateFrame=function(...)
 local f=original(...);f.GetName=function(self) return self.name end;return f
end
''')
v.execute((ROOT/'Theme.lua').read_text(),'ApexUI',v.globals().host)
v.execute('''
local T=host.Theme
local p=CreateFrame('Frame','ApexProfessionsGuideFrame');p:Hide();T.Attach(p)
local h=CreateFrame('Frame','ApexUIFeatures');h:Hide();T.Attach(h)
local mini=CreateFrame('Frame','ApexFishingMiniFrame');T.Attach(mini)
p:Show();assert(p:IsShown() and mini:IsShown())
h:Show();assert(h:IsShown() and not p:IsShown() and mini:IsShown())
local f=CreateFrame('Frame','ApexFishingFrame');f:Hide();T.Attach(f)
host.Suite.modules.fishing.ns={frame=f,fishingMode=true,SetCompact=function(on) assert(on);f:Hide();mini:Show();compacted=true end}
f:Show();assert(not h:IsShown());h:Show();assert(compacted and mini:IsShown())
UIParent:SetSize(1000,700);h:SetSize(830,650);h:SetScale(2);T.Fit(h)
assert(h:GetScale()<=668/650 and h:GetScale()>0.9)
local capped=h:GetScale();T.Fit(h);assert(h:GetScale()==capped)
UIParent:SetSize(1500,900)
T.windows={}
local full=CreateFrame('Frame','ApexUIFeatures');full:SetSize(800,600)
full.GetLeft=function() return 400 end;full.GetBottom=function() return 150 end
local tracker=CreateFrame('Frame','ApexGrindFrame');tracker:SetSize(250,650)
tracker.GetLeft=function() return 1100 end;tracker.GetBottom=function() return 150 end
T.windows[full]=true;T.windows[tracker]=true
T.AvoidTrackers(full);assert(full.point[4]==688,'shift just far enough to clear tracker')
-- Shared header styling must preserve each feature's cleanup callback and
-- remain idempotent when the same window is refreshed or reopened.
local title=full:CreateFontString();title:SetText('Apex Toolkit')
local close=CreateFrame('Button',nil,full)
for _,method in ipairs({'SetNormalTexture','SetPushedTexture','SetDisabledTexture'}) do
 close[method]=function(_,texture) assert(texture~=nil,'texture setters require an explicit empty texture') end
end
full.apexHeaderRule=false;full.apexHeaderIcon=false;close.apexLabel=false -- mock unknown fields default to methods
close:SetScript('OnClick',function() full:Hide();closedCleanly=true end)
T.Header(full,title,close);local rule=full.apexHeaderRule;local glyph=close.apexLabel
T.Header(full,title,close)
assert(full.apexHeaderRule==rule and close.apexLabel==glyph)
close:GetScript('OnClick')();assert(closedCleanly and not full:IsShown())
''')
# Closed guides still synchronize; ordinary events preserve intentional previews,
# whereas Detect returns to the player's actual level. Bursts are coalesced.
v.execute('''
syncCalls={};timers={};C_Timer.After=function(_,fn) timers[#timers+1]=fn end
UnitLevel=function() return 27 end
for _,key in ipairs({'fishing','grinding','professions'}) do
 local m=host.Suite.modules[key];m.status='loaded'
 m.ns={previewLevel=12,guideIndex=4,done={boughtRecipe=true}}
 local function record(manual) syncCalls[key]=(syncCalls[key] or 0)+1;m.ns.manual=manual end
 if key=='grinding' then m.ns.Sample=record
 elseif key=='professions' then m.ns.Apex={SyncProgress=record}
 else m.ns.SyncProgress=record end
end
''')
v.execute((ROOT/'Progress.lua').read_text(),'ApexUI',v.globals().host)
v.execute('''
local e=mock.frames[#mock.frames]
for _,event in ipairs({'PLAYER_LEVEL_UP','SKILL_LINES_CHANGED','NEW_RECIPE_LEARNED'}) do
 assert(e.events[event]);e.scripts.OnEvent(e,event)
end
assert(#timers==1);timers[1]()
local S=host.Suite
assert(S.lastSyncLevel==27 and syncCalls.fishing==1 and syncCalls.professions==1 and syncCalls.grinding==1)
assert(S.modules.grinding.ns.previewLevel==12)
S.SyncProgress(true)
assert(S.modules.grinding.ns.previewLevel==nil and S.modules.grinding.ns.guideIndex==1)
assert(S.modules.fishing.ns.manual and S.modules.professions.ns.manual)
assert(S.modules.fishing.ns.done.boughtRecipe)
''')
print(f'PASS: {len(runtime)} Lua chunks; deferred isolated init, disabled features, data identity, reload/combat guards, launcher, real bundled profession initialization and storage-only manifests.')
