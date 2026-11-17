"""Party ownership, visibility, live rates and protected-value regression checks."""
from pathlib import Path
from lupa.lua51 import LuaRuntime
ROOT=Path(__file__).resolve().parents[1]
lua=LuaRuntime(unpack_returned_tuples=True)
source=(ROOT/'tools/test_standalone.py').read_text()
lua.execute(source.split("lua.execute(r'''",1)[1].split("''')",1)[0])
for file in ['Framework.lua','Party.lua']:
    lua.execute((ROOT/file).read_text(),'ApexUI',lua.globals().A)
lua.execute('''
local profile={};A.Active=function() return profile end;A.OwnActive=function() return true end;A.ready=true
PartyFrame=CreateFrame('Frame',nil,UIParent)
CompactRaidFrameContainer=CreateFrame('Frame',nil,UIParent)
local P=A.Party;P.Apply()
local roleMap={party1='DAMAGER',party2='TANK',party3='NONE',party4='HEALER'}
UnitGroupRolesAssigned=function(unit) return roleMap[unit] end
P.Apply();local order=P.Order();assert(order[1]=='party2' and order[2]=='party4' and order[3]=='party1' and order[4]=='party3')
assert(P.frames.party2.health.color[3]==.78 and P.frames.party4.health.color[1]==.78)
assert(P.frames.party1.selectedRole=='DAMAGER' and not P.frames.party3.role:IsShown())
local tankPoint={P.frames.party2:GetPoint()};assert(tankPoint[5]==0)
combat=true;roleMap.party1='TANK';roleMap.party2='DAMAGER';P.Apply()
assert(({P.frames.party2:GetPoint()})[5]==0)
combat=false;P.Apply();assert(({P.frames.party1:GetPoint()})[5]==0)
roleMap.party3=secret;assert(P.Role('party3')=='NONE')
assert(P.frames.party1.health.value==secret)
assert(P.frames.party1.health.text.formatValues[2]==secret)
assert(P.frames.party1.power.text.formatValues[2]==secret)
assert(P.frames.party1:GetAttribute('unit')=='party1')
assert(P.frames.party1:GetAttribute('type1')=='target' and ClickCastFrames[P.frames.party1])
assert(drivers['ApexParty_party1:visibility']=='[group:raid] hide; [@party1,exists] show; hide')
assert(drivers['ApexNativeRaidGate:visibility']=='[group:raid] show; hide')
assert(PartyFrame:GetParent()==P.hidden and CompactRaidFrameContainer:GetParent()==P.raidGate)
Enum={DamageMeterType={DamageDone=0,HealingDone=2},DamageMeterSessionType={Current=1}}
local data={combatSources={{sourceGUID='GUID-party1',amountPerSecond=secret},{sourceGUID='GUID-party2',amountPerSecond=80}}}
C_DamageMeter={GetCombatSessionFromType=function() return data end}
P.UpdateRates();assert(P.frames.party1.dps.formatValues[2]==secret)
assert(P.frames.party2.dps.formatValues[2]==80 and P.frames.party3.dps.textValue=='0 DPS')
-- Reordered native meter rows must keep the correct player mapping.
data.combatSources={{sourceGUID='GUID-party2',amountPerSecond=100},{sourceGUID='GUID-party1',amountPerSecond=150}}
P.UpdateRates();assert(P.frames.party1.dps.formatValues[2]==150)
data.combatSources={{sourceGUID=secret,amountPerSecond=secret}}
P.UpdateRates();assert(P.frames.party1.dps.textValue=='-- DPS')
C_DamageMeter=nil;P.UpdateRates();assert(P.frames.party1.hps.textValue=='-- HPS')
P.Preview(true);assert(P.preview:IsShown() and P.previewFrames[1]:GetAttribute('unit')==nil)
combat=true;P.Apply();assert(P.pending);P.events.scripts.OnEvent(nil,'PLAYER_REGEN_DISABLED');assert(not P.preview:IsShown())
combat=false;P.Apply();assert(not P.pending)
local old=profile.party.width;SlashCmdList.APEXPARTY('larger');assert(profile.party.width==old+20)
''')
print('PASS: party secure targets, raid preservation, preview separation, combat deferral, secret-safe health and rates, GUID matching, unavailable-data state')
