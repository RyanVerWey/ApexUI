-- Generated ApexUI module wrapper; original attribution follows.
local _, suite = ...
suite.Suite.Register("fishing", "ApexFishing/Spots.lua", function(...)
local CreateFrame = function(...) return suite.Suite.CreateFrame("fishing", ...) end
local _,A=...
-- These are WATER AREAS, not precise standing locations. The ring marks a search
-- area; a shoreline chosen by the player replaces it after an observed fish catch.
A.spots={}
local function area(id,map,x,y,radius,label,minSkill,level,faction,fish)
 local spot={id=id,map=map,x=x,y=y,radius=radius,label=label,minSkill=minSkill,level=level,faction=faction,fish=fish}
 A.spots[id]=spot
 A.points['water:'..id]={map,x,y,label,area=true,radius=radius}
end
area('crystal',1429,49.5,65,3,'Crystal Lake shoreline',1,1,'Alliance',{6291,6289})
area('alameth',1438,56,67,3,'Lake Al\'Ameth shoreline',1,1,'Alliance',{6291,6289})
area('iceflow',1426,33.5,43,3,'Iceflow Lake shoreline',1,1,'Alliance',{6291,6289})
area('stonebull',1412,45.5,58.5,3,'Stonebull Lake shoreline',1,1,'Horde',{6291,6289})
area('brightwater',1420,67,50,3,'Brightwater Lake shoreline',1,1,'Horde',{6291,6289})
area('senjin',1411,56,75,2,'Sen\'jin coast',1,1,'Horde',{6303})
area('sw',1453,55,69.6,2,'Stormwind canal beside the Fishing trainer',1,1,'Alliance',{6291,6289,6308})
area('iron',1455,48.4,6.4,2,'Forlorn Cavern pond',1,1,'Alliance',{6291,6289,6308})
area('darn',1457,47.6,56.6,2,'Darnassus water beside Astaia',1,1,'Alliance',{6291,6289,6308})
area('tb',1456,56,46.8,2,'Thunder Bluff pond',1,1,'Horde',{6291,6289,6308})
area('org',1454,69.8,29.6,2,'Valley of Honor pond',1,1,'Horde',{6291,6289,6308})
area('uc',1458,80.8,31.2,2,'Undercity canals',1,1,'Horde',{6291,6289,6308})
area('everstill',1433,32,53,5,'Lake Everstill, Lakeshire shore',55,15,nil,{6289,6308})
area('loch',1432,47,45,6,'The Loch, western shore',1,10,'Alliance',{6289,6308})
-- Published Forever fishing-bank observations: FishFry 1.4.5 changelog.
area('darkshore-south',1439,40.6,74,1.5,'Southern Darkshore inland water',1,16,nil,{6291,6289,6308})
area('cliffspring',1439,51,28,2,'Cliffspring River banks (stay outside the cave)',1,12,nil,{6291,6289,6308})
area('mystral',1440,48.91,68.23,1.5,'Mystral Lake shoreline',55,20,nil,{6289,6308})
area('sunrock',1442,48,61,2,'Sun Rock Retreat pond',55,20,'Horde',{6289,6308})
area('dustwallow',1445,60,53,4,'Inland ponds west of Theramore (not the bay)',130,35,nil,{6308,8365})
area('verdantis',1444,62,52,3,'Verdantis River banks',205,40,nil,{8365,13758,13759,13760,13889})

function A.CurrentPosition()
 if not C_Map or not C_Map.GetBestMapForUnit then return end
 local map=C_Map.GetBestMapForUnit('player')
 local p=map and C_Map.GetPlayerMapPosition(map,'player')
 if p then local x,y=p:GetXY(); return {map=map,x=x*100,y=y*100} end
end
local function hasFish(spot,item)
 if not item then return true end
 for _,id in ipairs(spot.fish or {}) do if id==item then return true end end
 return false
end
function A.AvailableSpots(state,item)
 local list={}
 for id,spot in pairs(A.spots) do
  if (not spot.faction or spot.faction==state.faction) and (state.f or 0)>=spot.minSkill
   and (state.level or 1)>=spot.level and hasFish(spot,item) then list[#list+1]=spot end
 end
 for id,spot in pairs(ApexFishingDB and ApexFishingDB.observedSpots or {}) do
  if hasFish(spot,item) and spot.faction==state.faction then
   A.points['water:'..id]={spot.map,spot.x,spot.y,spot.label,observed=true}
   list[#list+1]=spot
  end
 end
 table.sort(list,function(a,b) return a.id<b.id end)
 return list
end
function A.SpotCost(spot,position)
 if not position then return math.huge end
 -- Prefer actual transport-network estimates to cross-continent straight lines.
 local N=_G.ApexNavigator
 if N and N.EstimateTravel then
  local seconds=N.EstimateTravel(position.map,position.x/100,position.y/100,spot.map,spot.x/100,spot.y/100)
  if seconds then return seconds end
 end
 if spot.map==position.map then return math.sqrt((spot.x-position.x)^2+(spot.y-position.y)^2)*8 end
 if C_Map and C_Map.GetWorldPosFromMapPos and CreateVector2D then
  local ok1,c1,p1=pcall(C_Map.GetWorldPosFromMapPos,position.map,CreateVector2D(position.x/100,position.y/100))
  local ok2,c2,p2=pcall(C_Map.GetWorldPosFromMapPos,spot.map,CreateVector2D(spot.x/100,spot.y/100))
  if ok1 and ok2 and p1 and p2 and c1==c2 then
   local x1,y1=p1:GetXY(); local x2,y2=p2:GetXY()
   -- Geographic fallback only. Cross-continent distance is never compared.
   return math.sqrt((x1-x2)^2+(y1-y2)^2)*1.35/7+60
  end
 end
 return math.huge
end
function A.ChooseSpot(state,item,session)
 local list=A.AvailableSpots(state,item)
 local position=A.CurrentPosition()
 local d=ApexFishingDB; d.spotChoice=d.spotChoice or {}
 local saved=d.spotChoice[session]
 for _,spot in ipairs(list) do if spot.id==saved then return spot end end
 local best,bestCost
 for _,spot in ipairs(list) do
  local cost=A.SpotCost(spot,position)
  if cost<math.huge and (not bestCost or cost<bestCost) then best,bestCost=spot,cost end
 end
 -- If no route estimate is available, prefer the user's detected home region,
 -- explicitly calling it a fallback rather than inventing a travel time.
 if not best then
  local home={elwynn='crystal',teldrassil='alameth',dunmorogh='iceflow',mulgore='stonebull',durotar='senjin',tirisfal='brightwater'}
  for _,spot in ipairs(list) do if spot.id==home[A.DetectOrigin()] then best=spot; break end end
  best=best or list[1]
 end
 if best then d.spotChoice[session]=best.id end
 return best
end
function A.ReplanSpots()
 ApexFishingDB.spotChoice={}; ApexFishingDB.batch=nil
 A.ClearWaypoint(); A.Render()
end

-- Only actual fish loot immediately after this player's fishing channel can
-- record a precise bank. Never infer a working fishing location from a cast alone.
local lastCast,castPosition
local events=CreateFrame('Frame')
events:RegisterEvent('UNIT_SPELLCAST_CHANNEL_START'); events:RegisterEvent('UNIT_SPELLCAST_CHANNEL_STOP')
events:RegisterEvent('LOOT_OPENED')
events:SetScript('OnEvent',function(_,event,unit)
 if not ApexFishingDB then return end
 if event=='UNIT_SPELLCAST_CHANNEL_START' and unit=='player' then
  local name,_,_,_,_,_,_,id=UnitChannelInfo('player')
  if id==7620 or id==131474 or name==(C_Spell and C_Spell.GetSpellName(7620) or 'Fishing') then
   lastCast=GetTime(); castPosition=A.CurrentPosition()
  else lastCast=nil; castPosition=nil end
 elseif event=='UNIT_SPELLCAST_CHANNEL_STOP' and unit=='player' and castPosition then lastCast=GetTime()
 elseif event=='LOOT_OPENED' and lastCast and GetTime()-lastCast<3 and castPosition and GetNumLootItems then
  local fish={}; local allowed={[6303]=true}
  for _,f in ipairs(A.fish) do allowed[f[1]]=true end
  for i=1,GetNumLootItems() do
   local link=GetLootSlotLink(i); local id=link and tonumber(link:match('item:(%d+)'))
   if id and allowed[id] then fish[#fish+1]=id end
  end
  if #fish>0 then
   local p=castPosition; local key=('caught:%d:%d:%d'):format(p.map,math.floor(p.x*2),math.floor(p.y*2))
   local d=ApexFishingDB; d.observedSpots=d.observedSpots or {}
   local old=d.observedSpots[key]
   if old then
    for _,id in ipairs(fish) do if not hasFish(old,id) then old.fish[#old.fish+1]=id end end
   else
    local info=C_Map.GetMapInfo(p.map)
    d.observedSpots[key]={id=key,map=p.map,x=p.x,y=p.y,radius=.5,label='Your successful bank: '..(info and info.name or 'water'),
     faction=UnitFactionGroup('player'),fish=fish,observed=true}
   end
   -- Replace an approximate area target with the player's proven nearby bank.
   if A.activeStep and A.activeStep.session and hasFish(d.observedSpots[key],A.activeStep.item) then
    d.spotChoice=d.spotChoice or {}; d.spotChoice[A.activeStep.session]=key
   end
  end
  lastCast=nil; castPosition=nil
 end
end)

end)
