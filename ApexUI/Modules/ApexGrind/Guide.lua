-- Generated ApexUI module wrapper; original attribution follows.
local _, suite = ...
suite.Suite.Register("grinding", "ApexGrind/Guide.lua", function(...)
local CreateFrame = function(...) return suite.Suite.CreateFrame("grinding", ...) end
local _, A = ...

local continents={}
for _,s in ipairs(A.spots) do continents[s.map]=s.continent end
-- City/subzone aliases affect proximity only; they never become destination pins.
local cityZones={[1453]=1429,[1455]=1426,[1457]=1438,[1454]=1411,[1456]=1412,[1458]=1420}
function A.Material(id)
 for _,m in ipairs(A.materials) do if m.id==id then return m end end
end
function A.SelectMaterial(id)
 A.db.material=A.Material(id) and id or 0
 A.guideKey=nil
 if A.materialPicker then A.materialPicker:GenerateMenu() end
 A.Render()
end
function A.LocalMap()
 local id=C_Map and C_Map.GetBestMapForUnit('player')
 for _=1,5 do
  if not id then return end
  if cityZones[id] then return cityZones[id] end
  if continents[id] then return id end
  local info=C_Map.GetMapInfo(id)
  if not info or not info.parentMapID or info.parentMapID==id then return end
  id=info.parentMapID
 end
end
function A.Recommend(level,faction,map,materialID)
 local matches={}
 local material=A.Material(materialID)
 if level<1 or level>=60 then return matches end
 for _,s in ipairs(A.spots) do
  local desiredLow=math.max(1,level-2)
  local desiredHigh=math.max(1,level-1)
  local targetLow=math.max(desiredLow,s.low)
  local targetHigh=math.min(desiredHigh,s.high)
  -- Every recommended camp has at least one level in the requested band.
  -- Never trade away level suitability for proximity or a density score.
  local factionOK=s.faction=='Both' or s.faction==faction
  local islandOK=s.map~=2521 or map==2521
  local dropRate=material and material.npcs[s.npc]
  if factionOK and islandOK and (not material or dropRate) and targetLow<=targetHigh and s.high<=math.max(2,level) then
   local fullBand=s.low>=desiredLow and s.high<=desiredHigh
   local score=(fullBand and 30 or 0)+math.min(s.nearby,12)-s.risk*2
   -- Relative historical yield only. Do not present this as a Forever drop rate.
   if dropRate then score=score+math.min(16,dropRate/5) end
   if s.map==map then score=score+45
   elseif continents[map] and continents[map]==s.continent then score=score+8 end
   matches[#matches+1]={spot=s,score=score,targetLow=targetLow,targetHigh=targetHigh,
    reason=(s.map==map and 'In your zone. ' or 'Travel required. ')..
      (fullBand and 'Whole mob range fits your target.' or 'Pick only the indicated mob levels.')}
  end
 end
 table.sort(matches,function(a,b) if a.score~=b.score then return a.score>b.score end return a.spot.id<b.spot.id end)
 return matches
end
function A.GuideSelection()
 local level=A.previewLevel or A.current.level
 local faction=UnitFactionGroup('player')
 local map=A.LocalMap()
 local key=tostring(level)..':'..tostring(faction)..':'..tostring(map)..':'..tostring(A.db.material)
 if A.guideKey~=key then
  A.guideKey=key;A.guideChoices=A.Recommend(level,faction,map,A.db.material);A.guideIndex=1
 end
 return A.guideChoices[A.guideIndex or 1],level,#A.guideChoices
end
function A.NearestMaterialLevel(level)
 if not A.Material(A.db.material) then return end
 local faction,map=UnitFactionGroup('player'),A.LocalMap()
 for distance=1,59 do
  for _,candidate in ipairs({level-distance,level+distance}) do
   if candidate>=1 and candidate<60 and #A.Recommend(candidate,faction,map,A.db.material)>0 then return candidate end
  end
 end
end
function A.BrowseLevel(delta)
 A.previewLevel=math.max(1,math.min(60,(A.previewLevel or A.current.level)+delta));A.Render()
end
function A.CurrentLevel()
 A.previewLevel=nil;A.guideKey=nil;A.Render()
end
function A.NextSpot()
 local _,level=A.GuideSelection()
 if #A.guideChoices==0 then
  A.previewLevel=A.NearestMaterialLevel(level) or A.previewLevel
 end
 if #A.guideChoices>0 then A.guideIndex=(A.guideIndex or 1)%#A.guideChoices+1 end
 A.Render()
end
function A.NavigateSpot()
 local choice=A.GuideSelection()
 if not choice then return end
 local s=choice.spot
 -- Explicit click only: never replace RestedXP's arrow automatically.
 if ApexNavigator and ApexNavigator.SetDestination then
  ApexNavigator.SetDestination(s.map,s.x,s.y)
 elseif TomTom and TomTom.AddWaypoint then
  if A.grindWaypoint and TomTom.RemoveWaypoint then TomTom:RemoveWaypoint(A.grindWaypoint) end
  A.grindWaypoint=TomTom:AddWaypoint(s.map,s.x,s.y,{title='ApexGrind: '..s.mob,persistent=false,minimap=true,world=true,crazy=true})
 elseif C_Map and C_Map.SetUserWaypoint and UiMapPoint then
  C_Map.SetUserWaypoint(UiMapPoint.CreateFromCoordinates(s.map,s.x,s.y))
 else
  A.Print(s.zone..' '..string.format('%.1f, %.1f',s.x*100,s.y*100)..': '..s.mob)
 end
end
function A.SourceURL(s)
 return 'https://www.wowhead.com/'..(s.map==2521 and 'forever' or 'classic')..'/npc='..s.npc
end
function A.GuideSources()
 local choice=A.GuideSelection()
 A.Print('Research and ranking: Interface/AddOns/ApexUI/Modules/ApexGrind/SOURCES.md')
 if choice then A.Print(choice.spot.source..'; '..A.SourceURL(choice.spot)) end
 local material=A.Material(A.db.material)
 if material then A.Print('Classic loot reference: https://classicdb.ch/?item='..material.id) end
end

end)
