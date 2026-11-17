"""Exercise real combat module and UI with native-session fixtures (Lua 5.1)."""
from pathlib import Path
from lupa.lua51 import LuaRuntime
root=Path(__file__).resolve().parents[1]
lua=LuaRuntime(unpack_returned_tuples=True)
base=root/'Source/ApexProfessions/upstream/tests'
mock=lua.execute((base/'wowmock.lua').read_text())
fixture=lua.execute((base/'fixtures/yungzug.lua').read_text())
mock.install(fixture,lua.table())
lua.globals().mock=mock
lua.execute('''
host={Suite={modules={combat={ns={},chunks={}}}}}; M=host.Suite.modules.combat.ns
function host.Suite.Register(_,_,fn) table.insert(host.Suite.modules.combat.chunks,fn) end
function host.Suite.CreateFrame(_,...) return CreateFrame(...) end
local old=CreateFrame
CreateFrame=function(...)
 local f=old(...)
 f.GetFontString=function(self) self.font=rawget(self,'font') or self:CreateFontString();return self.font end
 f.SetFormattedText=function(self,format,value)
  self.text=issecretvalue(value) and '<native secret rendered>' or string.format(format,value)
 end
 local font=f.CreateFontString
 f.CreateFontString=function(self,...) local t=font(self,...);t.SetFormattedText=f.SetFormattedText;return t end
 return f
end
Enum={DamageMeterType={DamageDone=0,HealingDone=1,DamageTaken=2},DamageMeterSessionType={Current=0,Overall=1},AddOnRestrictionType={Combat=0}}
secret=setmetatable({secret=true},{__tostring=function() error('secret tostring') end,__add=function() error('secret arithmetic') end})
function issecretvalue(v) return type(v)=='table' and rawget(v,'secret')==true end
clock=1000;function GetTime() return clock end;function GetServerTime() return clock end
combat=false;restriction=false;function InCombatLockdown() return combat end
C_RestrictedActions={IsAddOnRestrictionActive=function() return restriction end}
instance=nil;function IsInInstance() return instance~=nil,instance and 'party' or 'none' end
function GetInstanceInfo() return 'Deadmines','party',1,'Normal',5,0,false,instance end
members={player='me',party1='healer'}
function UnitGUID(unit) return members[unit] end
function UnitFullName(unit) return members[unit],nil end
function UnitClass(unit) return 'Hunter',unit=='party1' and 'PRIEST' or 'HUNTER' end
RAID_CLASS_COLORS={HUNTER={r=.6,g=.8,b=.4}};UISpecialFrames={};ApexUICharacterDB={}
sessions={};current={};api=true;calls=0
C_DamageMeter={
 IsDamageMeterAvailable=function() return api end,
 GetAvailableCombatSessions=function()
  local list={};for id,s in pairs(sessions) do list[#list+1]={sessionID=id,durationSeconds=s.seconds} end
  return list
 end,
 GetCombatSessionFromID=function(id,kind)
  calls=calls+1;local s=sessions[id];return {durationSeconds=s.seconds,combatSources=s[kind] or {}}
 end,
 GetCombatSessionFromType=function() return {combatSources=current} end,
 ResetAllCombatSessions=function() error('Must not reset native meters') end,
}
function row(guid,amount) return {sourceGUID=guid,name=guid,classFilename='HUNTER',totalAmount=amount,amountPerSecond=amount/10,isLocalPlayer=guid=='me'} end
function pull(id,seconds,damage,heal,taken)
 sessions[id]={seconds=seconds,[0]={row('me',damage),row('healer',100)},[1]={row('healer',heal)},[2]={row('me',taken)}}
end
DBM={RegisterCallback=function(self,event,fn) self.callback=fn end}
''')
for f in ('Combat.lua','CombatUI.lua'):
    lua.execute((root/f).read_text(),'ApexUI',lua.globals().host)
lua.execute('''
for _,chunk in ipairs(host.Suite.modules.combat.chunks) do chunk('ApexUI',M) end
-- First install seeds historical pulls, instead of importing them into new totals.
pull(1,10,500,50,30);mock.fire('PLAYER_LOGIN')
assert(M.db.total.damage==0 and M.frame:IsShown())
assert(DBM.callback)
-- Cache restored after login is still historical, not a new fight.
pull(9,30,1600,80,100);clock=clock+1;M.Tick();assert(M.db.total.damage==0)
clock=clock+3;M.Tick();assert(not M.seed and M.db.total.damage==0)
pull(2,20,1000,300,120);M.dirty=true;M.Tick()
assert(M.db.total.damage==1000 and M.db.total.seconds==20)
M.dirty=true;M.Tick();assert(M.db.total.damage==1000,'duplicate poll')
sessions[2][0][1].totalAmount=1100;M.dirty=true;M.Tick();assert(M.db.total.damage==1100)
-- Secret values render live but are never persisted/calculated. Delayed restrictions retry.
combat=true;current={{isLocalPlayer=true,totalAmount=secret,amountPerSecond=secret}}
local n=calls;M.dirty=true;M.Tick();assert(calls==n)
assert(M.frame.dps:GetText()=='<native secret rendered>')
assert(M.db.total.damage==1100 and not M.Reset())
combat=false;restriction=true;M.Tick();assert(M.dirty)
restriction=false;sessions[2][0][1].totalAmount=secret;M.Tick();assert(M.dirty and M.db.total.damage==1100)
sessions[2][0][1].totalAmount=1100;M.Tick();assert(not M.dirty)
current={}
-- Dungeon aggregates all members by combat duration, without out-of-dungeon history.
instance=36;M.Zone();local run=M.db.run
pull(3,10,800,600,200);M.dirty=true;M.Tick()
assert(run.rows.me.damage==800 and run.rows.healer.healing==600 and run.rows.me.taken==200)
assert(run.seconds==10 and run.rows.me.damage/run.seconds==80)
clock=clock+200;members.party1=nil;members.party2='newDPS';M.Roster()
pull(4,30,1200,0,300);sessions[4][0][2]=row('newDPS',900);M.dirty=true;M.Tick()
assert(run.seconds==40 and run.rows.me.damage==2000 and run.rows.me.damage/run.seconds==50)
assert(run.rows.healer.healing==600 and run.rows.newDPS.damage==900)
-- Personal reset never touches active dungeon totals or native history.
assert(M.Reset());assert(M.db.total.damage==0 and run.rows.me.damage==2000)
M.dirty=true;M.Tick();assert(M.db.total.damage==0)
-- Native reset reuses IDs without erasing Apex totals or doubling older records.
sessions={};mock.fire('DAMAGE_METER_RESET');pull(1,5,100,20,50);M.Tick()
assert(M.db.total.damage==100 and run.rows.me.damage==2100 and run.seconds==45)
-- Leave/corpse-run reentry remains incomplete and resumes same run.
instance=nil;M.Zone();clock=clock+4;M.Tick()
assert(run.status=='Left dungeon (incomplete)' and not run.closed and M.report:IsShown())
instance=36;M.Zone();assert(M.db.run==run)
-- Ordinary boss does not complete the dungeon; final boss notification waits for data.
mock.fire('ENCOUNTER_END',123,'Not final',1,5,1);assert(not M.finishPending)
combat=true;DBM.callback('DBM_Kill',{id='EdwinVanCleef'});assert(M.finishPending)
clock=clock+4;M.Tick();assert(not run.closed)
combat=false;restriction=true;M.Tick();assert(not run.closed)
restriction=false;M.Tick();assert(run.closed and run.status=='Final boss defeated')
assert(M.report.title:GetText()=='Deadmines' and M.report.rows[1].values[1]:GetText()=='47')
-- Continued polling/extra post-clear pulls don't mutate the finished run.
pull(2,10,400,0,20);M.dirty=true;M.Tick();assert(run.rows.me.damage==2100 and M.db.total.damage==500)
-- Reload keeps ledger and therefore does not import the same native pulls twice.
M.Initialize();M.dirty=true;M.Tick();assert(M.db.total.damage==500)
local retained=sessions;sessions={};M.dirty=true;M.Tick()
sessions=retained;clock=clock+4;M.Tick();assert(M.db.total.damage==500,'reload cache gap must not erase dedup ledger')
-- New entry after exiting a cleared run starts a new report and keeps previous.
instance=nil;M.Zone();instance=36;M.Zone()
assert(M.db.run~=run and M.db.previous==run and M.db.run.seconds==0)
-- The final session can become readable only after crossing the exit portal.
local nextRun=M.db.run
combat=true;pull(3,8,240,80,30)
mock.fire('DAMAGE_METER_COMBAT_SESSION_UPDATED',0,3)
instance=nil;M.Zone();combat=false;clock=clock+4;M.Tick()
assert(nextRun.rows.me.damage==240 and nextRun.seconds==8)
assert(nextRun.status=='Left dungeon (incomplete)' and not nextRun.closed)
-- Missing API is explicit; no fake zeros presented as measured data.
api=false;M.Render();assert(M.frame.caption:GetText()=='COMBAT DATA UNAVAILABLE')
api=true
SlashCmdList.APEXCOMBAT('');assert(not M.frame:IsShown())
SlashCmdList.APEXCOMBAT('show');assert(M.frame:IsShown())
M.frame.reset:GetScript('OnClick')();assert(M.frame.reset:GetText()=='Confirm reset')
M.frame.reset:GetScript('OnClick')();assert(M.db.total.damage==0)
M.previousView=true;M.ShowReport();assert(M.report.title:GetText()=='Deadmines')
''')
print('PASS: live native-secret rendering, history baseline, deduplication, corrections, persisted totals, resets, dungeon party/leavers, combat-time averages, completion deferral, exit/reentry, report and launcher callbacks.')
