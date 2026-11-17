local _,A=...
local S=A.Suite
function S.SyncProgress(manual)
 local results={}
 local function sync(key,fn)
  local m=S.modules[key]
  if m.status=='loaded' then
   local ok,err=pcall(fn,m.ns)
   if not ok then results[#results+1]=m.title..': '..tostring(err) end
  end
 end
 sync('fishing',function(ns) if ns.SyncProgress then ns.SyncProgress(manual) else ns.Render() end end)
 sync('grinding',function(ns)
  if manual then ns.previewLevel=nil;ns.guideKey=nil;ns.guideIndex=1 end
  ns.Sample()
 end)
 sync('professions',function(ns) if ns.Apex.SyncProgress then ns.Apex.SyncProgress(manual) else ns.Apex.Render(true) end end)
 S.lastSyncLevel=UnitLevel('player')
 if manual then
  print('|cffe3bd78ApexUI:|r Detected level '..S.lastSyncLevel..'. Fishing, Cooking and profession plans now use your current skill ranks. Grinding uses your level.')
  for _,err in ipairs(results) do print('|cffff8855ApexUI sync:|r '..err) end
 end
 if S.Refresh then S.Refresh() end
end
local events=CreateFrame('Frame');local queued=false
for _,e in ipairs({'PLAYER_ENTERING_WORLD','PLAYER_LEVEL_UP','SKILL_LINES_CHANGED','NEW_RECIPE_LEARNED'}) do events:RegisterEvent(e) end
events:SetScript('OnEvent',function()
 if queued then return end;queued=true
 C_Timer.After(1,function() queued=false;S.SyncProgress(false) end)
end)
