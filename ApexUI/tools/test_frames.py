"""Frame-only geometry, secret values, ownership and reload regression checks."""
from pathlib import Path
from lupa.lua51 import LuaRuntime
ROOT=Path(__file__).resolve().parents[1]
lua=LuaRuntime(unpack_returned_tuples=True)
# Reuse only the existing generic WoW test harness, not its suite test execution.
source=(ROOT/'tools/test_standalone.py').read_text()
bootstrap=source.split("lua.execute(r'''",1)[1].split("''')",1)[0]
lua.execute(bootstrap)
lua.execute('''
local originalCreateFrame=CreateFrame
function CreateFrame(kind,...)
 local f=originalCreateFrame(kind,...)
 if kind=='StatusBar' then
  f.GetStatusBarTexture=function(self) self.fill=self.fill or self:CreateTexture();return self.fill end
 end
 return f
end
A.ready=true;A.UF='ApexUnits';ApexUIDB={portraitFrames={enabled=true,mode='auto',scale=1}}
for _,f in pairs(frames) do f.Castbar=false end
''')
for name in ['Geometry.lua','Assets.lua','Core.lua','Auras.lua','Compatibility.lua']:
    lua.execute((ROOT/'Frames'/name).read_text(), 'ApexUI',lua.globals().A)
lua.execute('''
local F=A.Frames
-- Native interpolation receives restricted values unchanged. Numbers never
-- wait for animation; zero and range changes snap, and reduced motion works.
Enum={StatusBarInterpolation={Immediate=0,ExponentialEaseOut=1}}
local bar=CreateFrame('StatusBar')
bar.SetValue=function(self,v,mode) self.value=v;self.interpolation=mode end
F.SetBarValue(bar,100,100);assert(bar.interpolation==0)
F.SetBarValue(bar,70,100);assert(bar.scripts.OnUpdate)
bar.scripts.OnUpdate(bar,.14);assert(bar.value<100 and bar.value>70)
bar.scripts.OnUpdate(bar,.14);assert(bar.value==70 and not bar.scripts.OnUpdate)
F.SetBarValue(bar,0,100);assert(bar.interpolation==0)
F.SetBarValue(bar,20,200);assert(bar.interpolation==0)
ApexUIDB.portraitFrames.motion=false
F.SetBarValue(bar,30,200);assert(bar.interpolation==0)
ApexUIDB.portraitFrames.motion=true
F.SetBarValue(bar,secret,secret);assert(bar.value==secret and bar.interpolation==1)
assert(F.geometry.iron.level[1]+F.geometry.iron.level[3]<=.94)
assert(F.geometry.iron.name[1]+F.geometry.iron.name[3]<F.geometry.iron.level[1])
-- Horizontal center cannot drift with style, class or frame scale.
for _,class in ipairs({'PALADIN','WARRIOR','MAGE','HUNTER','WARLOCK'}) do
 for _,scale in ipairs({.7,1,1.4}) do
  for _,center in ipairs({640,960,1376}) do
   local l=F.ResolveLayout(class,false,'auto',center,140,scale)
   assert(l.x==center and l.y==156)
   assert(l.paired==(class=='HUNTER' or class=='WARLOCK'))
   assert(l.petX+l.width<l.x)
  end
 end
end
assert(F.ResolveLayout('MAGE',true,'auto',960,140,1).paired)
assert(not F.ResolveLayout('HUNTER',true,'solo',960,140,1).paired)
assert(F.ResolveLayout('PALADIN',false,'auto',960,140,1).width==480)
local roomy=F.ResolveLayout('PALADIN',false,'auto',960,140,1,'roomy')
assert(roomy.width==560 and roomy.y==192)
F.Apply()
assert(F.ready and F.layout.paired)
assert(F.units.player.health.value==secret and F.units.pet.power.value==secret)
assert(F.units.player.health.text.formatValues[2]==secret)
assert(F.units.player.xp.value==250 and F.units.pet.xp.value==25)
assert(F.units.player:GetAttribute('unit')=='player')
assert(F.units.pet:GetAttribute('type1')=='target')
assert(F.headers.playerHELPFUL:GetParent()==F.units.player)
assert(F.headers.petHELPFUL:GetParent()==F.units.pet)
-- Protected geometry waits for combat; data updates continue.
local x=F.layout.x;combat=true;ApexUIDB.portraitFrames.mode='solo';F.Apply()
assert(F.pending and F.layout.paired);F.Update('player')
combat=false;F.Apply();assert(not F.layout.paired and not F.units.pet.watched)
assert(F.units.player:GetPoint()=='BOTTOM')
assert(F.units.player.health.splitText and not F.units.player.health.wingMask)
-- Large exact amounts remain inside the wing; percentages have their own line.
local oldHealth,oldMax=UnitHealth,UnitHealthMax
UnitHealth=function() return 12345 end;UnitHealthMax=function() return 99999 end
F.units.player.health.text.GetStringWidth=function() return 600 end
F.units.player.health.text.SetFont=function(self,face,size) self.fittedSize=size end
F.Update('player')
assert(F.units.player.health.text.formatValues[2]==12345)
assert(F.units.player.health.percent.formatValues[2]>12)
assert(F.units.player.health.text.fittedSize<20)
assert(math.abs(F.units.player.health:GetWidth()-F.geometry.split.health[3]*F.layout.width*2)<.01)
assert(math.abs(F.units.player.power:GetWidth()-F.geometry.split.power[3]*F.layout.width*2)<.01)
assert(math.abs(F.units.player.xp:GetWidth()-F.geometry.split.xp[3]*F.layout.width)<.01)
assert(F.layout.width==480 and not F.units.player.art:IsShown())
UnitHealth,UnitHealthMax=oldHealth,oldMax

-- Absent pets are governed by unit watch, not a fake persistent pet placeholder.
ApexUIDB.portraitFrames.mode='auto';F.Apply();assert(F.units.pet.watched)
-- Native suppression removes hidden click targets but leaves other frames alone.
assert(not PlayerFrame:GetParent():IsShown())
assert(TargetFrame:GetParent()==UIParent)
assert(MainActionBar:GetParent()==UIParent)
SlashCmdList.APEXPORTRAITFRAMES('off');assert(reloaded and not ApexUIDB.portraitFrames.enabled)
''')
for p in (ROOT/'Frames').glob('*.lua'):
    lua.execute('assert(loadstring(...))',p.read_text())
assert 'SetCVar' not in ''.join(p.read_text() for p in (ROOT/'Frames').glob('*.lua'))
assert '"SecureAuraHeaderTemplate"' not in (ROOT/'Frames/Auras.lua').read_text()
assert 'hooksecurefunc' not in (ROOT/'Frames/Compatibility.lua').read_text()
print('PASS: exact-center geometry, class modes, secret-safe values, XP, secure targets, combat deferral, isolated ownership, XML and Lua syntax')
