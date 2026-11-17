local _, A = ...
local driver=CreateFrame('Frame')
A.driver=driver
local ready, lastTime, previous, queued

function A.Snapshot()
 local ok,rested=pcall(GetXPExhaustion)
 if not ok or not A.Readable(rested) then rested=nil else rested=math.max(0,rested or 0) end
 return {level=UnitLevel('player'),xp=UnitXP('player') or 0,cap=UnitXPMax('player') or 0,rested=rested}
end
function A.IsPaused()
 return A.db.paused or (A.db.autoAFK and UnitIsAFK('player'))
end
function A.Tick()
 if not ready then return end
 local now=GetTime()
 A.Advance(A.db.session,now-lastTime,A.IsPaused())
 lastTime=now
end
function A.Sample()
 if not ready then return end
 A.Tick()
 local current=A.Snapshot()
 A.Record(A.db.session,previous,current,A.IsPaused())
 previous=current
 A.current=current
 A.bonuses=A.ScanBonuses()
 if A.Render then A.Render() end
end
function A.Reset()
 A.Sample()
 A.db.session=A.NewSession()
 previous=A.Snapshot();A.current=previous;lastTime=GetTime()
 if A.Render then A.Render() end
end
function A.TogglePause()
 A.Sample()
 A.db.paused=not A.db.paused
 if A.Render then A.Render() end
end
function A.Print(message) print('|cffe3bd78ApexGrind:|r '..message) end
function A.Initialize()
 ApexGrindDB=ApexGrindDB or {}
 A.db=ApexGrindDB
 local defaults={scale=1,compact=false,hidden=false,locked=false,autoAFK=true,paused=false,view='spots',material=0,circles=true}
 for k,v in pairs(defaults) do if A.db[k]==nil then A.db[k]=v end end
 A.db.scale=math.max(.8,math.min(1.8,tonumber(A.db.scale) or 1))
 if not A.db.session or A.db.version~=1 then A.db.session=A.NewSession() end
 A.db.version=1
 A.db.session.samples=A.db.session.samples or {}
 -- Preserve existing totals, but do not invent a rested breakdown for old XP.
 A.db.session.forecast=A.db.session.forecast or A.NewForecast()
 A.db.session.forecast.award=nil
 -- Reloads resume the session; offline XP/time are deliberately not included.
 previous=A.Snapshot();A.current=previous;lastTime=GetTime();ready=true
 A.bonusCache=nil;A.bonuses=A.ScanBonuses()
 if A.BuildUI then A.BuildUI() end
end
driver:RegisterEvent('PLAYER_LOGIN')
driver:RegisterEvent('PLAYER_LOGOUT')
driver:RegisterEvent('PLAYER_XP_UPDATE')
driver:RegisterEvent('PLAYER_LEVEL_UP')
driver:RegisterEvent('PLAYER_FLAGS_CHANGED')
driver:RegisterEvent('UPDATE_EXHAUSTION')
driver:RegisterEvent('UNIT_AURA')
driver:RegisterEvent('PLAYER_REGEN_ENABLED')
driver:RegisterEvent('CHAT_MSG_COMBAT_XP_GAIN')
driver:SetScript('OnEvent',function(_,event,unit)
 if event=='PLAYER_LOGIN' then A.Initialize();return end
 if not ready then return end
 if event=='PLAYER_LOGOUT' then A.Sample();return end
 if event=='CHAT_MSG_COMBAT_XP_GAIN' then
  local gained=A.KillXP(unit)
  if gained and gained>0 and not A.IsPaused() then
   A.db.session.forecast.kills=A.db.session.forecast.kills+gained
  end
  return
 end
 if event=='UNIT_AURA' then
  if unit=='player' then A.bonuses=A.ScanBonuses();if A.Render then A.Render() end end
  return
 end
 if (event=='PLAYER_XP_UPDATE' or event=='PLAYER_FLAGS_CHANGED') and unit and unit~='player' then return end
 -- XP and level events can arrive in either order. Read the settled values next frame.
 if not queued then
  queued=true
  C_Timer.After(0,function() queued=false;A.Sample() end)
 end
end)
local elapsed=0
driver:SetScript('OnUpdate',function(_,dt)
 elapsed=elapsed+dt
 if elapsed>=1 then elapsed=0;A.Sample() end
end)

SLASH_APEXGRIND1='/apexgrind'
SLASH_APEXGRIND2='/agrind'
SlashCmdList.APEXGRIND=function(input)
 if not ready then return end
 local command,arg=(input or ''):lower():match('^%s*(%S*)%s*(.-)%s*$')
 if command=='' then A.db.hidden=not A.db.hidden
 elseif command=='show' then A.db.hidden=false
 elseif command=='hide' then A.db.hidden=true
 elseif command=='pause' then A.TogglePause()
 elseif command=='reset' then A.Reset();A.Print('New session started.')
 elseif command=='compact' then A.db.compact=not A.db.compact
 elseif command=='spots' then A.db.view='spots';A.db.compact=false;A.db.hidden=false
 elseif command=='stats' then A.db.view='stats';A.db.compact=false;A.db.hidden=false
 elseif command=='level' then
  if arg=='' or arg=='auto' then A.previewLevel=nil
  elseif tonumber(arg) then A.previewLevel=math.max(1,math.min(60,math.floor(tonumber(arg))))
  else A.Print('Use /agrind level 29, or /agrind level auto.');return end
  A.guideKey=nil;A.db.view='spots';A.db.compact=false;A.db.hidden=false
 elseif command=='next' then A.NextSpot()
 elseif command=='navigate' then A.NavigateSpot()
 elseif command=='map' then A.ShowGrindMap()
 elseif command=='circles' then
  A.db.circles=not A.db.circles;A.RefreshGrindMap()
  A.Print('Map circles '..(A.db.circles and 'on.' or 'off.'))
 elseif command=='sources' then A.GuideSources()
 elseif command=='loot' then
  if arg=='' or arg=='all' then A.SelectMaterial(0)
  else
   local found
   for _,m in ipairs(A.materials) do if m.name:lower()==arg or tonumber(arg)==m.id then found=m.id;break end end
   if not found then A.Print('Use /agrind loot Wool Cloth, or /agrind loot all. Choose other materials in Grinding spots.');return end
   A.SelectMaterial(found)
  end
  A.db.view='spots';A.db.compact=false;A.db.hidden=false
 elseif command=='lock' then A.db.locked=not A.db.locked;A.Print(A.db.locked and 'Position locked.' or 'Drag the title to move.')
 elseif command=='afk' then A.Tick();A.db.autoAFK=not A.db.autoAFK;A.Print('AFK pause '..(A.db.autoAFK and 'on.' or 'off.'))
 elseif command=='scale' and tonumber(arg) then A.db.scale=math.max(.8,math.min(1.8,tonumber(arg)))
 elseif command=='position' then A.db.position=nil;A.db.hidden=false;A.Place()
 else A.Print('/agrind: spots, stats, map, circles, loot Wool Cloth, loot all, level 29, level auto, next, navigate, sources, show, hide, pause, reset, compact, lock, afk, scale 1.2, position');return end
 A.Render()
end
