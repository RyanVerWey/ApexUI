"""Migration, independent paging and renderer checks with no external UI loaded."""
from pathlib import Path
from lupa.lua51 import LuaRuntime
import re

ROOT=Path(__file__).resolve().parents[1]
lua=LuaRuntime(unpack_returned_tuples=True)
lua.execute(r'''
frames={};drivers={};bindings={};pending={};A={};SlashCmdList={};UISpecialFrames={}
local methods={}
local function object(kind,name,parent)
 local f={kind=kind,nameKey=name,parent=parent,width=100,height=30,scale=1,scripts={},attrs={},children={},shown=true}
 if parent and parent.children then table.insert(parent.children,f) end
 setmetatable(f,{__index=function(t,k)
  if methods[k] then return methods[k] end
  if k:match('^[A-Z]') and k~='Text' then return function() end end
  return nil
 end})
 if name then _G[name]=f;frames[name]=f end
 return f
end
function CreateFrame(kind,name,parent,template) assert(not template or not template:find('SecureAuraHeader'));local f=object(kind,name,parent);f.template=template;return f end
function methods:SetAttribute(k,v) self.attrs[k]=v;if self.scripts.OnAttributeChanged then self.scripts.OnAttributeChanged(self,k,v) end end
function methods:GetAttribute(k) return self.attrs[k] end
function methods:SetFrameRef(k,v) self.attrs[k]=v end
function methods:GetFrameRef(k) return self.attrs[k] end
function methods:SetSize(w,h) self.width=w;self.height=h end
function methods:SetWidth(w) self.width=w end
function methods:SetHeight(h) self.height=h end
function methods:GetStatusBarTexture() self.fill=self.fill or self:CreateTexture();return self.fill end
function methods:IsVisible() return self.shown end
function methods:GetWidth() return self.width end
function methods:GetHeight() return self.height end
function methods:SetScale(s) self.scale=s end
function methods:GetScale() return self.scale end
function methods:GetEffectiveScale() return self.scale end
function methods:GetLeft() return 0 end
function methods:GetRight() return self.width end
function methods:GetTop() return self.height end
function methods:GetBottom() return 0 end
function methods:GetCenter() return self.width/2,self.height/2 end
function methods:GetFrameLevel() return 10 end
function methods:GetName() return self.nameKey end
function methods:GetParent() return self.parent end
function methods:SetParent(p) self.parent=p end
function methods:SetPoint(...) self.point={...} end
function methods:GetPoint() return unpack(self.point or {'CENTER',UIParent,'CENTER',0,0}) end
function methods:ClearAllPoints() self.point=nil end
function methods:CreateFontString() return object('FontString',nil,self) end
function methods:CreateTexture() return object('Texture',nil,self) end
function methods:CreateMaskTexture() return object('Mask',nil,self) end
function methods:GetChildren() return unpack(self.children) end
function methods:SetScript(k,v) self.scripts[k]=v end
function methods:GetScript(k) return self.scripts[k] end
function methods:HookScript(k,v) self.hooks=self.hooks or {};self.hooks[k]=v end
function methods:SetText(v) self.textValue=v end
function methods:SetFormattedText(...) self.formatValues={...} end
function methods:SetMinMaxValues(a,b) self.range={a,b} end
function methods:SetValue(v) self.value=v end
function methods:SetStatusBarColor(...) self.color={...} end
function methods:SetShown(v) self.shown=v end
function methods:Show() self.shown=true end
function methods:Hide() self.shown=false end
function methods:IsShown() return self.shown end
function RegisterStateDriver(f,k,v) drivers[f.nameKey..':'..k]=v end
function RegisterUnitWatch(f) f.watched=true end
function UnregisterUnitWatch(f) f.watched=false end
function SetOverrideBindingClick(owner,priority,key,name,button) bindings[key]={name,button} end
function ClearOverrideBindings() bindings={} end
function GetBindingKey(cmd) if cmd=='ACTIONBUTTON1' then return '1','NUMPAD1' end end
function GetBindingText(k) return k end
function GetActionTexture(slot) return slot end
function GetActionCount() return 1 end
function IsCurrentAction() return false end
function IsAutoRepeatAction() return false end
function GetActionCooldown() return 0,0,1 end
function GetCVar() return '1' end
function IsShiftKeyDown() return false end
function InCombatLockdown() return combat==true end
function UnitName(unit) return 'Test '..unit end
function UnitFullName() return 'Test','Realm' end
function GetRealmName() return 'Realm' end
function UnitClass() return 'Hunter','HUNTER' end
function UnitLevel() return 22 end
function UnitExists() return true end
function UnitGUID(unit) return 'GUID-'..unit end
function IsInGroup() return true end
function IsInRaid() return false end
function UnitPowerType() return 0,'MANA' end
PowerBarColor={MANA={r=.08,g=.32,b=.70}}
local function forbidden() error('Secret value reached Lua arithmetic') end
secret=setmetatable({},{__add=forbidden,__sub=forbidden,__div=forbidden,__mul=forbidden,__lt=forbidden,__le=forbidden,__concat=forbidden})
function UnitHealth() return secret end
function UnitHealthMax() return secret end
function UnitPower() return secret end
function UnitPowerMax() return secret end
function UnitHealthPercent() return secret end
function UnitPowerPercent() return secret end
function issecretvalue(v) return v==secret end
CurveConstants={ScaleTo100={}}
function UnitCastingInfo() return nil end
function UnitChannelInfo() return nil end
function GetTime() return 10 end
function time() return 100 end
function GetPetExperience() return 25,100 end
function UnitXP() return 250 end
function UnitXPMax() return 1000 end
function GetXPExhaustion() return 500 end
function GetInventoryItemDurability() return 50,100 end
function GetNetStats() return 0,0,30,40 end
function GetFramerate() return 60 end
function GetCoinTextureString() return '10g' end
function GetMoney() return 100000 end
function GetZoneText() return 'Test Zone' end
function GetMinimapZoneText() return 'Test Town' end
function date() return '12:00 PM' end
function ReloadUI() reloaded=true end
function SetPortraitTexture() end
function hooksecurefunc() end
function print() end
C_Timer={After=function(_,fn) pending[#pending+1]=fn end}
C_AddOns={IsAddOnLoaded=function() return oldProviderLoaded==true end}
C_Map={GetBestMapForUnit=function() return 1 end,GetPlayerMapPosition=function() return {GetXY=function() return .5,.5 end} end}
C_UnitAuras={GetAuraDataByIndex=function() return nil end}
UIParent=CreateFrame('Frame','UIParent');UIParent:SetSize(2752,1152)
Minimap=CreateFrame('Frame','Minimap',UIParent)
MicroMenuContainer=CreateFrame('Frame','MicroMenuContainer',UIParent)
BagsBar=CreateFrame('Frame','BagsBar',UIParent)
GameTooltip=CreateFrame('Frame','GameTooltip',UIParent)
for _,name in ipairs({'PlayerFrame','PetFrame','TargetFrame','FocusFrame','TargetFrameToT','MainActionBar','MultiBarBottomLeft','MultiBarBottomRight','MultiBarRight','MultiBarLeft','MultiBar5','MultiBar6','MultiBar7','BuffFrame','DebuffFrame'}) do CreateFrame('Frame',name,UIParent) end
for i=1,10 do CreateFrame('Button','PetActionButton'..i,UIParent);CreateFrame('Button','StanceButton'..i,UIParent) end
''')
def load(name): lua.execute((ROOT/name).read_text(encoding='utf-8-sig'),'ApexUI',lua.globals().A)
for name in ['Framework.lua','Templates.lua','Defaults.lua','Migration.lua']:
    load(name)
lua.execute('''
local B=A.Backend
local source=B.FillDefaults({})
source.addons.EllesmereUIUnitFrames=source.addons.ApexUnits;source.addons.ApexUnits=nil
source.addons.EllesmereUIActionBars=source.addons.ApexBars;source.addons.ApexBars=nil
source.addons.EllesmereUIUnitFrames.player.frameWidth=317
source.addons.EllesmereUIActionBars.barPositions.MainBar.x=-301
EllesmereUIDB={profiles={Original=source},activeProfile='Original',profileOrder={'Original'}}
ApexUIDB={sharedProfile='Shared',sharedSnapshot=source,layouts={[1]={name='Saved',snapshot=source}},templates={HUNTER=source}}
ApexUICharacterDB={profile='Shared'}
oldProviderLoaded=true;B.InitializeProfiles()
assert(B.conflict and A.ProfileDB.profiles.Original.addons.ApexUnits.player.frameWidth==317)
assert(source.addons.EllesmereUIUnitFrames and not source.addons.ApexUnits,'Migration mutated source')
assert(ApexUIDB.layouts[1].snapshot.addons.ApexUnits.player.frameWidth==317)
assert(ApexUIDB.frameworkMigrationBackup.provider.profiles.Original.addons.EllesmereUIUnitFrames)
assert(ApexUIDB.sharedSnapshot.addons.ApexBars.barPositions.MainBar.x==-301)
-- A later login works without the provider or any of its saved globals.
EllesmereUIDB=nil;oldProviderLoaded=false;B.InitializeProfiles();assert(not B.conflict)
''')
for name in ['UnitFrames.lua','Party.lua','ActionBars.lua','Auras.lua','Shell.lua','Movers.lua','Core.lua','Utility.lua','Shared.lua','Layouts.lua','Frames/Geometry.lua','Frames/Assets.lua','Frames/Core.lua','Frames/Auras.lua','Frames/Compatibility.lua','Chat.lua','Skins.lua']:
    load(name)
# Rebind the registered native renderer's database (as first initialization does).
lua.execute('''
A.ProfileDB=nil
assert(A.Initialize());assert(A.OwnActive())
A.Refresh()
local u=A.Backend._ModuleNS.ApexUnits.frames.player
assert(u.Health.value==secret and u.Power.value==secret)
assert(u.Health.formatValues==nil)
assert(u.Health.text.formatValues[2]==secret)
assert(A.ActionBars.frames.MainBar.buttons[1]:GetAttribute('action')==1)
assert(A.ActionBars.frames.Bar9.buttons[1]:GetAttribute('action')==13)
assert(A.ActionBars.frames.Bar4.buttons[1]:GetAttribute('action')==25)
assert(A.ActionBars.frames.Bar5.buttons[1]:GetAttribute('action')==37)
assert(A.ActionBars.frames.Bar2.buttons[1]:GetAttribute('action')==61)
assert(bindings['1'][1]=='ApexAction_MainBar_1' and bindings.NUMPAD1)
local f=A.ActionBars.frames.MainBar
self=f;newstate='7';assert(loadstring(f:GetAttribute('_onstate-page')))()
assert(f.buttons[1]:GetAttribute('action')==73)
assert(A.ActionBars.frames.Bar9.buttons[1]:GetAttribute('action')==13)
self=nil;newstate=nil
local id=A.SaveNamedLayout('Standalone test');assert(id)
local shared=A.Active()
A.CustomizeCharacter();assert(ApexUICharacterDB.customLayout)
A.Active().addons.ApexUnits.player.frameWidth=331
assert(shared.addons.ApexUnits.player.frameWidth~=331)
A.UseSharedDefault();assert(not ApexUICharacterDB.customLayout)
local before=A.CurrentLayoutName();combat=true
assert(not A.SaveNamedLayout('Cannot save in combat'));assert(A.CurrentLayoutName()==before)
combat=false
-- Clean account with no old provider also builds complete independent defaults.
ApexUIDB={};ApexUICharacterDB={};A.ProfileDB=nil;A.ready=nil
assert(A.Initialize());A.Refresh()
assert(A.Active().addons.ApexUnits.player and A.Active().addons.ApexBars.bars.MainBar)
assert(A.Frames.units.player.xp.value==250)
''')
for p in ROOT.rglob('*.lua'):
    if 'OriginalSource' not in p.parts:
        lua.execute('assert(loadstring(...))',p.read_text(encoding='utf-8-sig'))
toc=(ROOT/'ApexUI.toc').read_text()
assert 'Ellesmere' not in toc
for p in ROOT.glob('*.lua'):
    if p.name!='Migration.lua': assert 'Ellesmere' not in p.read_text(),p
runtime=[ROOT/x.strip().replace('\\','/') for x in toc.splitlines() if x.strip().endswith(('.lua','.xml')) and not x.startswith('#')]
for p in runtime:
    assert p.is_file(),p
    if p.name!='Migration.lua':
        assert not re.search(r'Interface.*AddOns.*Ellesmere',p.read_text(encoding="utf-8")),p
print('PASS: standalone clean boot, provider migration/relogin, immutable recovery copy, secret-safe unit display, independent action pages, stance paging, preserved primary bindings, named saves, character isolation, combat guards, Lua and no external UI assets/dependencies.')
