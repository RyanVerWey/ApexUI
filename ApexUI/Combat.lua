-- Native combat records only. No combat-log parsing, protected actions or CVar changes.
local _,A=...
A.Suite.Register('combat','Combat.lua',function(_,M)
local E=Enum and Enum.DamageMeterType
local ST=Enum and Enum.DamageMeterSessionType
local metrics={'damage','healing','taken'}
local types=E and {damage=E.DamageDone,healing=E.HealingDone,taken=E.DamageTaken}
local function plain(v) return not (issecretvalue and issecretvalue(v)) end
local function number(v) return plain(v) and type(v)=='number' and v>=0 and v<math.huge end
local function str(v) return plain(v) and type(v)=='string' and v~='' end
M.Plain=plain;M.Number=number
local function call(fn,...)
 if type(fn)~='function' then return nil end
 local ok,v=pcall(fn,...);if ok then return v end
end
local function now() return GetServerTime and GetServerTime() or time() end
local function blank() return {damage=0,healing=0,taken=0,seconds=0} end
local function say(s) print('|cffe3bd78Apex Combat:|r '..s) end
function M.Available()
 return C_DamageMeter and types and ST and C_DamageMeter.GetCombatSessionFromID
  and call(C_DamageMeter.IsDamageMeterAvailable)==true
end
function M.Restricted()
 if InCombatLockdown() then return true end
 if C_RestrictedActions and Enum.AddOnRestrictionType then
  return call(C_RestrictedActions.IsAddOnRestrictionActive,Enum.AddOnRestrictionType.Combat)==true
 end
 return false
end
function M.Current()
 if not M.Available() then return nil end
 local s=call(C_DamageMeter.GetCombatSessionFromType,ST.Current,types.damage)
 if s and s.combatSources then
  for _,r in ipairs(s.combatSources) do
   if plain(r.isLocalPlayer) and r.isLocalPlayer then return r end
  end
 end
end
function M.Read(id,duration)
 if not M.Available() then return nil end
 local out={rows={},seconds=number(duration) and duration or 0}
 for _,key in ipairs(metrics) do
  local s=call(C_DamageMeter.GetCombatSessionFromID,id,types[key])
  if not s or not s.combatSources then return nil end
  if number(s.durationSeconds) then out.seconds=math.max(out.seconds,s.durationSeconds) end
  for _,src in ipairs(s.combatSources) do
   if not plain(src.sourceGUID) or not plain(src.totalAmount) then return nil end
   local guid=src.sourceGUID
   if plain(src.isLocalPlayer) and src.isLocalPlayer then guid=UnitGUID('player') end
   if str(guid) and number(src.totalAmount) then
    local r=out.rows[guid] or blank();out.rows[guid]=r
    r[key]=src.totalAmount
    if str(src.name) then r.name=src.name end
    if str(src.classFilename) then r.class=src.classFilename end
   end
  end
 end
 return out
end
function M.Roster()
 local run=M.db and M.db.run;if not run or run.closed then return end
 local units={'player','party1','party2','party3','party4'}
 for _,unit in ipairs(units) do
  local guid=UnitGUID(unit)
  if str(guid) then
   local name,realm=UnitFullName(unit);local _,class=UnitClass(unit)
   if str(name) then
    if str(realm) then name=name..'-'..realm end
    run.roster[guid]={name=name,class=plain(class) and class or nil}
    if not run.rows[guid] then run.rows[guid]=blank() end
    run.rows[guid].name=name;run.rows[guid].class=class
   end
  end
 end
end
function M.Accept(id,snapshot,seed)
 local old=M.db.seen[id]
 if old and snapshot.seconds<old.seconds then old=nil end -- Native ID reused after a reset.
 local run=M.db.run
 local assigned=M.db.pending[id]
 snapshot.run=old and old.run or (not seed and (assigned~=nil and assigned or
  (M.inDungeon and run and not run.closed and run.key)) or nil)
 if assigned==false then snapshot.run=nil end
 if not seed then
  local mine=UnitGUID('player');local deltaSeconds=snapshot.seconds-(old and old.seconds or 0)
  local function add(dest,src,prior)
   for _,k in ipairs(metrics) do dest[k]=math.max(0,(dest[k] or 0)+(src[k] or 0)-(prior and prior[k] or 0)) end
  end
  local own=snapshot.rows[mine]
  if own then
   add(M.db.total,own,old and old.rows[mine])
   M.db.total.seconds=math.max(0,M.db.total.seconds+(old and old.rows[mine] and deltaSeconds or snapshot.seconds))
  end
  if run and snapshot.run==run.key then
   run.seconds=math.max(0,run.seconds+deltaSeconds)
   for guid,src in pairs(snapshot.rows) do
    if run.roster[guid] then
     local row=run.rows[guid] or blank();run.rows[guid]=row
     add(row,src,old and old.rows[guid]);row.name=run.roster[guid].name;row.class=run.roster[guid].class
    end
   end
  end
 end
 M.db.seen[id]=snapshot;M.db.pending[id]=nil
end
function M.Flush()
 if not M.db or not M.Available() or M.Restricted() then return false end
 local list=call(C_DamageMeter.GetAvailableCombatSessions);if not list then return false end
 local retained={};local complete=true
 for _,s in ipairs(list) do
  if number(s.sessionID) then
   retained[s.sessionID]=true
   local snapshot=M.Read(s.sessionID,s.durationSeconds)
   if snapshot then M.Accept(s.sessionID,snapshot,M.seed) else complete=false end
  end
 end
 if complete and (not M.warmUntil or GetTime()>=M.warmUntil) then
  for id in pairs(M.db.seen) do if not retained[id] then M.db.seen[id]=nil end end
  if not M.seedUntil or GetTime()>=M.seedUntil then M.seed=false;M.seedUntil=nil;M.dirty=false end
 end
 return complete
end
function M.Reset()
 if M.Restricted() then say('Finish combat before resetting totals.');return false end
 if not M.Flush() then say('Waiting for readable combat records. Try again after combat.');return false end
 M.db.total=blank();M.db.resetAt=now()
 if M.Render then M.Render() end
 return true
end
function M.Zone()
 if not M.db then return end
 local _,kind=IsInInstance();local name,_,_,_,_,_,_,id=GetInstanceInfo()
 local inside=kind=='party' and number(id)
 if inside then
  local run=M.db.run
  if not run or run.instance~=id or (run.leftAt and now()-run.leftAt>900) then
   M.Flush()
   if run then M.db.previous=run end
   M.db.serial=(M.db.serial or 0)+1
   M.db.run={key=tostring(now())..':'..M.db.serial,instance=id,name=name or 'Dungeon',
    start=now(),seconds=0,rows={},roster={},status='In progress'}
  elseif run.closed and run.leftAt then
   -- A completed run re-entered is a new run, never a continuation of its totals.
   M.db.previous=run;M.db.run=nil;M.Zone();return
  end
  M.inDungeon=true;M.db.run.leftAt=nil
  if not M.db.run.closed then M.db.run.status='In progress' end
  M.Roster()
 else
  local run=M.db.run
  if M.inDungeon and run then
   M.Flush();run.leftAt=now()
   if not run.closed then run.status='Left dungeon (incomplete)' end
   M.reportPending=true;M.reportAt=GetTime()+3
  end
  M.inDungeon=false
 end
end
function M.Finish(reason)
 local run=M.db and M.db.run
 if not run or run.closed or not M.inDungeon then return end
 M.finishPending=reason or 'Finished manually';M.reportAt=GetTime()+3;M.dirty=true
end
-- Final encounters verified against installed DBM-Party-Vanilla (2026-10-19).
-- Unknown/custom dungeons use native completion events or the explicit Finish button.
-- Multi-wing instances are labelled as wing completions, not entire-dungeon clears.
local finals={
 [36]={mods={EdwinVanCleef=true},encounters={[2972]=true}},
 [33]={mods={ArchmageArugal=true}},[34]={mods={BazilThredd=true}},
 [43]={mods={['481']=true},encounters={[592]=true}},
 [48]={mods={Akumai=true},encounters={[2767]=true}},
 [47]={mods={CharlgaRazorflank=true}},[129]={mods={AmnennartheColdbringer=true}},
 [90]={mods={['422']=true},encounters={[2772]=true,[382]=true}},
 [70]={mods={['473']=true},encounters={[554]=true}},
 [230]={mods={['387']=true},encounters={[245]=true}},
 [289]={mods={DarkmasterGandling=true},encounters={[2801]=true,[463]=true}},
 [189]={wing=true,mods={ArcanistDoan=true,Herod=true,Mograine_and_Whitemane=true,BloodmageThalnos=true},encounters={[447]=true,[448]=true,[450]=true,[2779]=true,[445]=true}},
 [429]={wing=true,mods={['405']=true,['410']=true,['417']=true},encounters={[346]=true,[361]=true,[368]=true}},
 [229]={wing=true,mods={['396']=true,GeneralDrakkisath=true},encounters={[275]=true}},
 [329]={wing=true,mods={['456']=true},encounters={[484]=true}},
}
function M.Boss(encounter,modID)
 local run=M.db and M.db.run;local f=run and finals[run.instance]
 if not f or not M.inDungeon then return end
 if (number(encounter) and f.encounters and f.encounters[encounter]) or
  (plain(modID) and modID~=nil and f.mods[tostring(modID)]) then
  M.Finish(f.wing and 'Wing complete' or 'Final boss defeated')
 end
end
function M.HookDBM()
 if M.dbmHooked or not DBM or not DBM.RegisterCallback then return end
 DBM:RegisterCallback('DBM_Kill',function(_,mod) if mod then M.Boss(nil,mod.id) end end)
 M.dbmHooked=true
end
function M.Tick()
 if not M.db then return end
 if M.dirty or M.finishPending or M.reportPending then
  local flushed=M.Flush()
  if flushed and not M.Restricted() and GetTime()>=(M.reportAt or 0) then
   if M.finishPending then
    local run=M.db.run
    if run then run.status=M.finishPending;run.closed=true;run.ended=now() end
    M.finishPending=nil;M.reportPending=true
   end
   if M.reportPending then M.reportPending=nil;if M.ShowReport then M.ShowReport() end end
  end
 end
 if M.Render then M.Render() end
end
function M.Initialize()
 ApexUICharacterDB=ApexUICharacterDB or {}
 ApexUICharacterDB.combat=ApexUICharacterDB.combat or {total=blank(),seen={},resetAt=now()}
 M.db=ApexUICharacterDB.combat;M.seed=not M.db.initialized;M.db.initialized=true
 M.db.total=M.db.total or blank();M.db.seen=M.db.seen or {};M.db.pending=M.db.pending or {}
 M.warmUntil=GetTime()+3
 -- Native history can arrive several frames after PLAYER_LOGIN. Seed it during
 -- a brief warm-up rather than counting restored records as fresh damage.
 if not M.db.schema then
  M.db.total=blank();M.db.seen={};M.db.pending={};M.db.schema=1;M.seed=true
 end
 if M.seed then M.seedUntil=GetTime()+3 end
 M.dirty=true;M.Flush();M.Zone();M.HookDBM()
 if M.CreateUI then M.CreateUI() end
end
local events=A.Suite.CreateFrame('combat','Frame');M.events=events
for _,e in ipairs({'PLAYER_LOGIN','PLAYER_ENTERING_WORLD','PLAYER_REGEN_DISABLED','PLAYER_REGEN_ENABLED',
 'GROUP_ROSTER_UPDATE','ZONE_CHANGED_NEW_AREA','DAMAGE_METER_COMBAT_SESSION_UPDATED',
 'DAMAGE_METER_CURRENT_SESSION_UPDATED','DAMAGE_METER_RESET','ADDON_RESTRICTION_STATE_CHANGED',
 'LFG_COMPLETION_REWARD','CHALLENGE_MODE_COMPLETED','ENCOUNTER_END','BOSS_KILL','ADDON_LOADED'}) do pcall(events.RegisterEvent,events,e) end
events:SetScript('OnEvent',function(_,event,...)
 if event=='PLAYER_LOGIN' then M.Initialize();return end
 if not M.db then return end
 if event=='ADDON_LOADED' then M.HookDBM()
 elseif event=='PLAYER_ENTERING_WORLD' then
  local initial=...
  if initial then M.db.seen={};M.db.pending={};M.seed=true;M.seedUntil=GetTime()+3 end
  M.Flush();M.Zone()
 elseif event=='ZONE_CHANGED_NEW_AREA' then M.Zone()
 elseif event=='GROUP_ROSTER_UPDATE' then M.Roster()
 elseif event=='DAMAGE_METER_RESET' then M.db.seen={};M.db.pending={};M.seed=false;M.seedUntil=nil;M.dirty=true
 elseif event=='DAMAGE_METER_COMBAT_SESSION_UPDATED' then
  local _,id=...;local run=M.db.run
  if number(id) and not M.db.seen[id] then
   M.db.pending[id]=M.inDungeon and run and not run.closed and run.key or false
  end
  M.dirty=true
 elseif event=='PLAYER_REGEN_DISABLED' then M.fighting=true;M.seed=false;M.seedUntil=nil;M.Roster()
 elseif event=='PLAYER_REGEN_ENABLED' then M.fighting=false;M.dirty=true;M.reportAt=GetTime()+2
 elseif event=='LFG_COMPLETION_REWARD' or event=='CHALLENGE_MODE_COMPLETED' then M.Finish('Dungeon complete')
 elseif event=='ENCOUNTER_END' then local id,_,_,_,success=...;if plain(success) and success==1 then M.Boss(id) end
 elseif event=='BOSS_KILL' then M.Boss(...)
 else M.dirty=true end
end)
local elapsed=0
events:SetScript('OnUpdate',function(_,dt)
 elapsed=elapsed+dt;if elapsed<.25 then return end;elapsed=0
 -- Paint live values four times/sec; read full session history only after combat.
 M.Tick()
end)
end)
