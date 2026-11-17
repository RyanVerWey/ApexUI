local addon,A=...
_G.ApexNavigator=A
local function say(s) print('|cff50d8cdApex Navigator:|r '..s) end
A.Say=say

function A.PlayerPoint()
 local map=C_Map.GetBestMapForUnit('player')
 local p=map and C_Map.GetPlayerMapPosition(map,'player')
 if not p then return end
 local x,y=p:GetXY()
 return A.ToWorld(map,x,y,'Your location')
end

function A.ClearArrow()
 if A.arrow and TomTom and TomTom.RemoveWaypoint then TomTom:RemoveWaypoint(A.arrow) end
 A.arrow=nil
end
function A.CurrentLeg() return A.route and A.route[A.step or 1] end
function A.IsRide(leg) return leg and leg.kind~='walk' and leg.kind~='road' end
function A.Arrow()
 A.ClearArrow()
 local leg=A.CurrentLeg()
 if not leg or not TomTom then return end
 local target=A.graph.nodes[(A.IsRide(leg) and not A.riding) and leg.from or leg.to]
 if target and TomTom.AddWaypoint then
  local title=A.IsRide(leg) and ((A.riding and 'Arrive: ' or 'Board (/anav next): ')..target.label) or target.label
  local ok,uid=pcall(TomTom.AddWaypoint,TomTom,target.map,target.x,target.y,
   {title='Apex: '..title,persistent=false,minimap=true,world=true,crazy=true,arrivaldistance=0})
  if ok then A.arrow=uid end
 end
end

function A.Route()
 A.ClearArrow(); A.route=nil; A.graph=nil; A.riding=false; A.step=1; A.eta=nil
 local dest=A.db.destination
 if not dest then A.status='Choose a destination on your map.'; A.Refresh(); return end
 local start=A.PlayerPoint()
 local finish=A.ToWorld(dest.map,dest.x,dest.y,dest.label)
 if not start or not finish then
  A.status='Position unavailable. Leave the instance or transport, then click Replan.'
  A.Refresh(); return
 end
 A.graph=A.BuildGraph(start,finish,A.db)
 A.route,A.eta=A.Shortest(A.graph.nodes,A.graph.edges,'start','finish',A.db)
 A.status=A.route and 'Fastest estimated route in the mapped network.' or
  'No connected route in this map network. This area may need more route data.'
 A.Refresh(); A.Arrow()
end

function A.SetDestination(map,x,y)
 if not map or not x or not y or x<0 or y<0 or x>1 or y>1 then say('Choose a point inside a zone map.'); return end
 -- Resolve continent clicks to a zone, including OpenMap's stitched canvas.
 local p=A.ToWorld(map,x,y)
 local supported=false
 for _,id in ipairs(A.zoneMaps) do if id==map then supported=true; break end end
 if p and not supported then
  local zone=A.FromWorld(p.continent,p.wx,p.wy)
  if zone then map,x,y=zone.map,zone.x,zone.y end
 end
 local info=C_Map.GetMapInfo(map)
 A.db.destination={map=map,x=x,y=y,label=(info and info.name or 'Destination')..(' %.1f, %.1f'):format(x*100,y*100)}
 A.CreateUI(); A.frame:Show(); A.Route()
 -- Keep a real destination pin while TomTom points at the next travel leg.
 if C_Map.SetUserWaypoint and UiMapPoint and UiMapPoint.CreateFromCoordinates then
  pcall(C_Map.SetUserWaypoint,UiMapPoint.CreateFromCoordinates(map,x,y))
 end
 say('Route set to '..A.db.destination.label..'.')
end

-- Guide handoff uses the same transport planner, without opening another panel.
-- The destination table is an ownership token: cancelling a guide cannot erase
-- a route the user has since replaced with their own map pin.
function A.FollowGuide(map,x,y,label)
 if not A.db then return end
 local token={map=map,x=x,y=y,label=label,source='ApexFishing'}
 A.db.destination=token; A.CreateUI(); A.Route()
 return token,A.route~=nil
end
function A.CancelGuide(token)
 if token and A.db and A.db.destination==token and token.source=='ApexFishing' then
  A.db.destination=nil; A.Route()
 end
end

function A.Next()
 local leg=A.CurrentLeg(); if not leg then return end
 if A.IsRide(leg) and not A.riding then
  A.riding=true; A.Arrow(); A.Refresh(); return
 end
 if A.IsRide(leg) then
  local d=A.Distance(A.PlayerPoint(),A.graph.nodes[leg.to])
  if not d or d>100 then say('Not at the arrival waypoint yet. Stay aboard, then exit at the named stop.'); return end
 end
 A.step=A.step+1; A.riding=false
 if not A.CurrentLeg() then A.status='Destination reached. Choose another pin whenever you are ready.' end
 A.Refresh(); A.Arrow()
end

function A.MapClick()
 local map,x,y
 if OpenMapAPI and OpenMapAPI.IsStitched() then
  local u,v=OpenMapAPI.CursorPosition()
  if u then
   map=OpenMapAPI.MapAt(u,v)
   if map then x,y=OpenMapAPI.MapFromWorld(map,u,v) end
  end
 elseif WorldMapFrame and WorldMapFrame.ScrollContainer then
  map=WorldMapFrame:GetMapID()
  x,y=WorldMapFrame:GetNormalizedCursorPosition()
 end
 if not map or not x or not y then say('Zoom into a zone and try again.'); return end
 A.armed=false; A.SetDestination(map,x,y)
end

function A.ArmPin()
 A.armed=true
 if ToggleWorldMap and (not WorldMapFrame or not WorldMapFrame:IsShown()) then ToggleWorldMap() end
 A.HookMap()
 say('Click the map to set your destination. Click Pin again to cancel.')
 A.Refresh()
end

function A.HookMap()
 local scroll=WorldMapFrame and WorldMapFrame.ScrollContainer
 if not scroll or A.mapHook then return end
 A.mapHook=true
 scroll:HookScript('OnMouseDown',function(_,button)
  if button=='LeftButton' and A.armed then A.MapClick() end
 end)
end

function A.ReadFlights()
 A.estimateCache={}
 if not NumTaxiNodes or not TaxiNodeGetType then return end
 local list,current={},nil
 -- Match the native taxi list to native node IDs, using localized names if available.
 local names={}
 for id,n in pairs(A.flightNodes) do names[n[1]]=id end
 if C_TaxiMap and C_TaxiMap.GetTaxiNodesForMap then
  for _,map in ipairs({1414,1415,2521,2548}) do
   local ok,nodes=pcall(C_TaxiMap.GetTaxiNodesForMap,map)
   if ok and nodes then for _,n in ipairs(nodes) do if n.name and n.nodeID then names[n.name]=n.nodeID end end end
  end
 end
 for i=1,NumTaxiNodes() do
  local kind,name=TaxiNodeGetType(i),TaxiNodeName(i)
  local id=names[name]
  if A.flightNodes[id] then
   list[#list+1]={id=id,kind=kind}
   if kind=='CURRENT' then current=id end
  end
 end
 if not current then return end
 local count=0
 for _,n in ipairs(list) do
  if n.kind=='REACHABLE' then
   local key=current..':'..n.id
   A.db.flightOffers[key]={from=current,to=n.id}; count=count+1
  end
 end
 if count>0 then say(count..' available flight destinations recorded here.') end
end

local events=CreateFrame('Frame')
events:RegisterEvent('ADDON_LOADED'); events:RegisterEvent('PLAYER_LOGIN'); events:RegisterEvent('TAXIMAP_OPENED')
events:SetScript('OnEvent',function(_,event,name)
 if event=='ADDON_LOADED' and name==addon then
  ApexNavigatorDB=ApexNavigatorDB or {}; A.db=ApexNavigatorDB
  if A.db.flights==nil then A.db.flights=false end
  A.db.faction=UnitFactionGroup('player'); A.db.flightOffers=A.db.flightOffers or {}
  A.db.speed=math.max(4,math.min(20,tonumber(A.db.speed) or 7))
 elseif event=='PLAYER_LOGIN' then
  A.CreateUI(); A.CreateMinimap(); A.HookMap()
  if OpenMapAPI and OpenMapAPI.RegisterMenuToggle then
   OpenMapAPI.RegisterMenuToggle('ApexNavigator',{id='panel',label='Apex Navigator',
    get=function() return A.frame:IsShown() end,set=function(v) A.frame:SetShown(v) end})
  end
  if A.db.destination then A.Route() end
 elseif event=='ADDON_LOADED' and name=='Blizzard_WorldMap' then A.HookMap()
 elseif event=='TAXIMAP_OPENED' then A.ReadFlights() end
end)
local elapsed=0
events:SetScript('OnUpdate',function(_,dt)
 elapsed=elapsed+dt; if elapsed<1 then return end; elapsed=0
 if not A.db then return end
 A.HookMap()
 local leg=A.CurrentLeg()
 if not leg then return end
 local target=A.graph.nodes[leg.to]
 local d=A.Distance(A.PlayerPoint(),target)
 if d and d<35 and (not A.IsRide(leg) or A.riding) and not (UnitOnTaxi and UnitOnTaxi('player')) then A.Next() end
end)

SLASH_APEXNAVIGATOR1='/apexnav'
SLASH_APEXNAVIGATOR2='/anav'
SlashCmdList.APEXNAVIGATOR=function(msg)
 msg=msg or ''; A.CreateUI()
 msg=msg:match('^%s*(.-)%s*$')
 if msg=='pin' then A.ArmPin()
 elseif msg=='waypoint' then
  local p=C_Map.GetUserWaypoint and C_Map.GetUserWaypoint()
  if p and p.position then local x,y=p.position:GetXY(); A.SetDestination(p.uiMapID,x,y)
  else say('Place a map pin first, or use /apexnav pin.') end
 elseif msg=='clear' or msg=='stop' then A.db.destination=nil; A.Route()
 elseif msg=='arrow' then A.frame:Hide(); A.Arrow()
 elseif msg=='flights' then A.db.flights=not A.db.flights; A.Route()
 elseif msg=='replan' then A.Route()
 elseif msg=='next' then A.Next()
 elseif msg=='home' then A.frame:ClearAllPoints(); A.frame:SetPoint('CENTER',UIParent,'CENTER',240,100); A.db.position=nil; A.frame:Show()
 elseif msg:match('^speed ') then
  local speed=tonumber(msg:match('^speed (.+)'))
  if speed and speed>=4 and speed<=20 then A.db.speed=speed; A.Route() else say('Use /apexnav speed 7 (walking) or 11.2 (60% mount). Range: 4-20 yards/sec.') end
 elseif msg=='help' then say('/apexnav opens the panel. Enter X Y for your current zone, or ZONE NAME X Y / MAPID X Y. Also: arrow, stop, pin, waypoint, flights, replan, next, home, speed N.')
 elseif msg:find('%d') then A.CoordinateCommand(msg)
 else A.frame:SetShown(not A.frame:IsShown()) end
end
