-- ApexUI feature host. Saved data stays in compatibility storage addons so
-- every character retains the existing tables without a destructive migration.
local ADDON, A = ...
local S={modules={},order={'navigation','fishing','grinding','professions','combat'}}
A.Suite=S
local definitions={
 navigation={'ApexNavigator','Navigation','Map pins, coordinates, boats, trams and optional flights.','APEXNAVIGATOR',''},
 fishing={'ApexFishing','Fishing','Fishing and cooking steps, compact guide and fishing controls.','APEXFISHING','show'},
 grinding={'ApexGrind','Grinding','XP per hour, rested forecast and profession loot grinding.','APEXGRIND','show'},
 professions={'ApexProfessions','Professions','Cheapest or fastest skill plans, farming and auction budgets.','APEXPROFESSIONS',''},
 combat={'ApexUI','Combat','Live DPS, damage since reset and dungeon party reports.','APEXCOMBAT','show'},
}
for _,key in ipairs(S.order) do
 local d=definitions[key]
 S.modules[key]={key=key,addon=d[1],title=d[2],description=d[3],command=d[4],argument=d[5],
  ns={suiteManaged=true,theme=A.Theme},chunks={},frames={},status='waiting',builtin=key=='combat'}
end
function S.Register(key,source,fn)
 local m=assert(S.modules[key],'Unknown ApexUI feature: '..tostring(key))
 m.chunks[#m.chunks+1]={source=source,fn=fn}
end
function S.CreateFrame(key,...)
 local f=CreateFrame(...)
 local frames=S.modules[key].frames
 frames[#frames+1]=f
 if A.Theme then A.Theme.Queue(f) end
 return f
end
function S.Settings()
 ApexUICharacterDB=ApexUICharacterDB or {}
 ApexUICharacterDB.features=ApexUICharacterDB.features or {}
 return ApexUICharacterDB.features
end
function S.Enabled(key) return S.Settings()[key]~=false end
function S.Pending()
 for _,key in ipairs(S.order) do
  local m=S.modules[key]
  if m.startedEnabled~=nil and S.Enabled(key)~=m.startedEnabled then return true end
 end
 return false
end
function S.SetEnabled(key,value)
 if not S.modules[key] then return end
 S.Settings()[key]=value and true or false
 if S.Refresh then S.Refresh() end
end
local function fail(m,reason)
 m.status='error';m.error=tostring(reason)
 for _,f in ipairs(m.frames) do
  if f.UnregisterAllEvents then f:UnregisterAllEvents() end
  if f.SetScript then f:SetScript('OnUpdate',nil) end
  if f.Hide then f:Hide() end
 end
 print('|cffe3bd78ApexUI:|r '..m.title..' could not load: '..m.error)
end
function S.Start()
 if S.started then return end
 S.started=true
 for _,key in ipairs(S.order) do
  local m=S.modules[key]
  m.startedEnabled=S.Enabled(key)
  if not m.startedEnabled then m.status='disabled'
  elseif not m.builtin and not (ApexUIStorage and ApexUIStorage[m.addon]) then
   fail(m,'Missing ApexUI data storage addon. Restore the complete suite package; your saved data has not been replaced.')
  else
   m.status='loading'
   for _,chunk in ipairs(m.chunks) do
    local ok,err=pcall(chunk.fn,m.addon,m.ns)
    if not ok then fail(m,chunk.source..': '..tostring(err));break end
   end
   if m.status=='loading' then
    -- The host's ADDON_LOADED arrives after all saved variables. Module init
    -- listeners receive their original identity exactly once, before PLAYER_LOGIN.
    for _,f in ipairs(m.frames) do
     local handler=f.GetScript and f:GetScript('OnEvent')
     if handler and f:IsEventRegistered('ADDON_LOADED') then
      local ok,err=pcall(handler,f,'ADDON_LOADED',m.addon)
      if not ok then fail(m,err);break end
     end
    end
    if m.status=='loading' then m.status='loaded' end
   end
  end
 end
end
function S.Open(key)
 local m=S.modules[key]
 if not m then return end
 if m.status~='loaded' then
  print('|cffe3bd78ApexUI:|r '..m.title..' is '..m.status..'. Enable it in Features and reload.');return
 end
 local fn=SlashCmdList[m.command]
 if not fn then print('|cffe3bd78ApexUI:|r '..m.title..' is still initializing.');return end
 if S.frame then S.frame:Hide() end
 if m.ns.frame and m.ns.frame:IsShown() then return end
 if key=='professions' and m.ns.Apex then m.ns.Apex.Open() else fn(m.argument) end
end
function S.Apply()
 if InCombatLockdown() then print('|cffe3bd78ApexUI:|r Finish combat before reloading features.');return end
 local fishing=S.modules.fishing
 if fishing.status=='loaded' and fishing.ns.StopFishing then fishing.ns.StopFishing() end
 ReloadUI()
end
local events=CreateFrame('Frame')
events:RegisterEvent('ADDON_LOADED')
events:SetScript('OnEvent',function(self,_,name)
 if name==ADDON then self:UnregisterEvent('ADDON_LOADED');S.Start() end
end)
