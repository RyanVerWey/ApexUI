"""PvP state transitions, pooled raid units and combat creation deferral."""
from pathlib import Path
from lupa.lua51 import LuaRuntime
ROOT=Path(__file__).resolve().parents[1]
lua=LuaRuntime(unpack_returned_tuples=True)
source=(ROOT/'tools/test_standalone.py').read_text()
lua.execute(source.split("lua.execute(r'''",1)[1].split("''')",1)[0])
lua.execute('''
A.ready=true;A.OwnActive=function() return true end;A.Backend={}
flags={player=true,party1=false,raid1=true,raid2=false};free={}
UnitIsPVP=function(unit) return flags[unit] end
UnitIsPVPFreeForAll=function(unit) return free[unit] end
A.Frames={units={player=CreateFrame('Button',nil,UIParent)}}
A.Frames.units.player.unit='player';A.Frames.units.player.face=A.Frames.units.player:CreateTexture()
A.Party={frames={party1=CreateFrame('Button',nil,UIParent)}};A.Party.frames.party1.unit='party1'
CompactRaidFrame1=CreateFrame('Button',nil,UIParent);CompactRaidFrame1.unit='raid1'
CompactUnitFrame_SetUnit=function() end
hooksecurefunc=function(name,fn) nativeHook=fn end
''')
lua.execute((ROOT/'PvP.lua').read_text(),'ApexUI',lua.globals().A)
lua.execute('''
local V=A.PvP;V.Refresh()
local player=A.Frames.units.player;local party=A.Party.frames.party1
assert(V.frames[player].textValue=='PvP' and V.frames[player]:IsShown())
assert(not V.frames[party]:IsShown())
flags.party1=true;V.events.scripts.OnEvent(nil,'UNIT_FACTION','party1')
assert(V.frames[party].textValue=='PvP' and V.frames[party]:IsShown())
flags.player=false;V.Refresh();assert(not V.frames[player]:IsShown())
free.player=true;V.Refresh();assert(V.frames[player].textValue=='FFA')
free.player=false;flags.player=secret;V.Refresh();assert(V.frames[player].textValue=='PvP ?')
flags.player=true;free.player=secret;V.Refresh();assert(V.frames[player].textValue=='PvP')
-- Reusing a raid frame must clear the previous member's flag immediately.
assert(V.frames[CompactRaidFrame1]:IsShown())
CompactRaidFrame1.unit='raid2';nativeHook(CompactRaidFrame1);assert(not V.frames[CompactRaidFrame1]:IsShown())
CompactRaidFrame1.unit='nameplate1';nativeHook(CompactRaidFrame1);assert(not V.frames[CompactRaidFrame1]:IsShown())
-- Existing decorations still update in combat, new frames wait until regen.
combat=true;flags.party1=false;V.Refresh();assert(not V.frames[party]:IsShown())
CompactRaidFrame2=CreateFrame('Button',nil,UIParent);CompactRaidFrame2.unit='raid1'
nativeHook(CompactRaidFrame2);assert(not V.frames[CompactRaidFrame2])
combat=false;V.events.scripts.OnEvent(nil,'PLAYER_REGEN_ENABLED')
assert(V.frames[CompactRaidFrame2]:IsShown())
-- The critical threshold is strict; death always suppresses the pulse.
local hp=20;UnitHealth=function() return hp end;UnitHealthMax=function() return 100 end
assert(V.CriticalAlpha('party1')==0);hp=19;assert(V.CriticalAlpha('party1')==1)
hp=0;assert(V.CriticalAlpha('party1')==0)
local d=V.details[party]
d.dead.SetAlpha=function(self,a) self.alpha=a end;d.alive.SetAlpha=function(self,a) self.alpha=a end
UnitIsDeadOrGhost=function() return true end;V.Update(party)
assert(d.dead.alpha==1 and d.alive.alpha==0)
UnitIsDeadOrGhost=function() return false end;V.Update(party)
assert(d.dead.alpha==0 and d.alive.alpha==1)
-- Restricted health must be evaluated by a native step curve, not Lua math.
C_CurveUtil={CreateCurve=function() return {SetType=function() end,AddPoint=function(self,x,y) self[x]=y end} end}
Enum={LuaCurveType={Step=1}}
UnitHealthPercent=function(unit,predicted,curve) assert(curve[.2]==0 and curve[0]==1);return secret end
assert(V.CriticalAlpha('party1')==secret)
UnitExists=function() return false end;V.Refresh();assert(not V.frames[CompactRaidFrame2]:IsShown())
''')
print('PASS: PvP/FFA/clear/unknown states, party events, raid reuse, combat deferral, absent units')
