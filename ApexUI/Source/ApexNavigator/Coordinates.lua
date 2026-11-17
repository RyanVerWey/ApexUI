local _,A=...
local function trim(s) return (s or ''):match('^%s*(.-)%s*$') end
function A.CoordinateZones()
 local zones={}
 for _,id in ipairs(A.zoneMaps) do
  local info=C_Map.GetMapInfo(id)
  if info and info.name then zones[#zones+1]={id=id,name=info.name} end
 end
 table.sort(zones,function(a,b) return a.name<b.name end)
 return zones
end
function A.ResolveCoordinateZone(value)
 value=trim(value)
 local id=value=='' and C_Map.GetBestMapForUnit('player') or tonumber(value)
 local matches={}
 for _,zone in ipairs(A.CoordinateZones()) do
  if zone.id==id or zone.name:lower()==value:lower() then return zone.id end
  if value~='' and zone.name:lower():find(value:lower(),1,true) then matches[#matches+1]=zone.id end
 end
 if #matches==1 then return matches[1] end
 return nil,#matches>1 and 'Several zones match. Enter the full zone name.' or 'Select a supported outdoor zone or city.'
end
function A.ParseCoordinates(value)
 local x,y=trim(value):match('^([%d%.]+)%s*,%s*([%d%.]+)$')
 if not x then x,y=trim(value):match('^(%S+)%s+(%S+)$') end
 local function number(s)
  if not s or not (s:match('^%d+%.?%d*$') or s:match('^%.%d+$')) then return end
  local n=tonumber(s)
  if n and n>=0 and n<=100 then return n/100 end
 end
 x,y=number(x),number(y)
 if not x or not y then return nil,nil,'Enter X, Y from 0 to 100, for example 42.5, 67.8.' end
 return x,y
end
function A.CoordinateMessage(message,success)
 if A.coordinateFeedback then
  A.coordinateFeedback:SetTextColor(success and .3 or 1,success and .88 or .72,success and .8 or .35)
  A.coordinateFeedback:SetText(message)
 end
 if not success then A.Say(message) end
end
function A.NavigateCoordinates(zone,value)
 local map,err=A.ResolveCoordinateZone(tostring(zone or ''))
 if not map then A.CoordinateMessage(err);return false end
 local x,y,problem=A.ParseCoordinates(value)
 if not x then A.CoordinateMessage(problem);return false end
 A.armed=false
 A.SetDestination(map,x,y)
 A.coordinateMap=map
 if A.zonePicker then A.zonePicker:GenerateMenu() end
 A.CoordinateMessage('Destination set. Follow the arrow to the next route step.',true)
 return true
end
function A.CoordinateCommand(value)
 local normalized=trim(value):gsub(',',' ')
 local zone,x,y=normalized:match('^(.-)(%S+)%s+(%S+)$')
 if not x then A.CoordinateMessage('Use /anav 42.5 67.8 or /anav Redridge Mountains 42.5 67.8.');return false end
 return A.NavigateCoordinates(trim(zone),x..' '..y)
end
