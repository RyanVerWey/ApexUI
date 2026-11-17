-- Generated ApexUI module wrapper; original attribution follows.
local _, suite = ...
suite.Suite.Register("fishing", "ApexFishing/Guide.lua", function(...)
local CreateFrame = function(...) return suite.Suite.CreateFrame("fishing", ...) end
local _, A = ...
function A.ReadSkills()
 local s={f=0,fcap=0,c=0,ccap=0,level=UnitLevel('player') or 1,faction=UnitFactionGroup('player')}
 if GetProfessions and GetProfessionInfo then
  local ids={GetProfessions()}
  for i=1,6 do
   if ids[i] then
    local _,_,rank,cap,_,_,id=GetProfessionInfo(ids[i])
    if id==356 then s.f=rank or 0; s.fcap=cap or 0 end
    if id==185 then s.c=rank or 0; s.ccap=cap or 0 end
   end
  end
 end
 -- Classic skill-line fallback; never include lure/equipment modifiers in base skill.
 if GetNumSkillLines and GetSkillLineInfo and (s.fcap==0 or s.ccap==0) then
  for i=1,GetNumSkillLines() do
   local name,header,_,rank,_,_,cap=GetSkillLineInfo(i)
   if not header and name==(_G.FISHING or 'Fishing') then s.f=rank or 0; s.fcap=cap or 0 end
   if not header and name==(_G.COOKING or 'Cooking') then s.c=rank or 0; s.ccap=cap or 0 end
  end
 end
 return s
end
function A.Count(id)
 if C_Item and C_Item.GetItemCount then return C_Item.GetItemCount(id,false,false) end
 return GetItemCount and GetItemCount(id) or 0
end
function A.Complete(step,s,done)
 if step.skipCap and s.fcap>=step.skipCap then return true end
 if step.skipSkill and s[step.skipSkill]>=step.skipAt then return true end
 if step.kind=='cap' then return s[step.skill..'cap']>=step.target end
 if step.kind=='skill' then return s[step.skill]>=step.target end
 if step.kind=='item' then return A.Count(step.item)>=step.target end
 if step.accept and C_QuestLog then
  if C_QuestLog.IsOnQuest and C_QuestLog.IsOnQuest(step.quest) then return true end
  if C_QuestLog.IsQuestFlaggedCompleted and C_QuestLog.IsQuestFlaggedCompleted(step.quest) then return true end
 end
 return done[step.id]==true
end
function A.Pending(route,s,done)
 local list={}
 for i,step in ipairs(route) do if not A.Complete(step,s,done) then list[#list+1]=i end end
 return list
end
function A.Blocked(step,s)
 if step.level and s.level<step.level then return 'Requires character level '..step.level..'. Continue character leveling, then return.' end
 if step.minSkill and s[step.skill]<step.minSkill then return 'Requires base skill '..step.minSkill..'.' end
 if step.kind=='skill' and s[step.skill]>=s[step.skill..'cap'] and s[step.skill..'cap']<step.target then
  return 'Your trained skill cap is blocking progress. Complete the training step first.'
 end
end
function A.ClearWaypoint()
 local N=_G.ApexNavigator
 if N and N.CancelGuide then
  local token=A.navDestination or (N.db and N.db.destination and N.db.destination.source=='ApexFishing' and N.db.destination)
  if token then N.CancelGuide(token) end
 end
 A.navDestination=nil
 if A.waypoint and TomTom and TomTom.RemoveWaypoint then TomTom:RemoveWaypoint(A.waypoint) end
 A.waypoint=nil
 A.navigationKey=nil
end
function A.UpdateNavigation(step,state)
 if step and step.phase=='cook' then A.ClearWaypoint(); return end
 if not ApexFishingDB.arrow or not step or A.Blocked(step,state) then A.ClearWaypoint(); return end
 local p=step.point and A.points[step.point]
 -- Once in the selected water area, use any reachable shoreline. Never keep
 -- commanding the player to swim to a lake-centre marker.
 if p and p.area and A.CurrentPosition then
  local here=A.CurrentPosition()
  if here and here.map==p[1] and ((here.x-p[2])^2+(here.y-p[3])^2)<((p.radius or 3)+1)^2 then
   A.ClearWaypoint(); return
  end
 end
 local key=step.id..':'..tostring(step.point)
 if key~=A.navigationKey then A.Navigate(step); A.navigationKey=key end
end
function A.Navigate(step)
 A.ClearWaypoint()
 local p=step and A.points[step.point]
 if not p then return end
 local map=A.ResolveMap and A.ResolveMap(p[1]) or p[1]
 if type(map)~='number' then print('Apex Fishing: '..p[4]..' ('..p[2]..', '..p[3]..'). Zone map is not available yet.'); return end
 local N=_G.ApexNavigator
 if N and N.FollowGuide then
  local token,connected=N.FollowGuide(map,p[2]/100,p[3]/100,'Apex Fishing: '..p[4]..(p.area and ' (water area)' or ''))
  A.navDestination=token
  if not connected then print('Apex Fishing: no connected travel route to '..p[4]..'. Use Fishing spots to choose another area.') end
  return
 end
 if TomTom and TomTom.AddWaypoint then
  A.waypoint=TomTom:AddWaypoint(map,p[2]/100,p[3]/100,{title='Apex Fishing: '..p[4]..(p.area and ' (area, choose a bank)' or ''),persistent=false,minimap=true,world=true})
 else
  print('|cff4de0cdApex Fishing:|r '..p[4]..' ('..p[2]..', '..p[3]..'). Install/enable TomTom for an arrow.')
  if WorldMapFrame and WorldMapFrame.SetMapID then WorldMapFrame:Show(); WorldMapFrame:SetMapID(map) end
 end
end

end)
