from pathlib import Path
from lupa.lua51 import LuaRuntime

root = Path(__file__).resolve().parents[1]
lua = LuaRuntime(unpack_returned_tuples=True)
lua.execute('''
A={}; SlashCmdList={}; UIParent={}; Minimap={}; STANDARD_TEXT_FONT='font'; frames={}
function CreateFrame(_,name)
 local f={scripts={},shown=true,name=name}
 frames[#frames+1]=f
 setmetatable(f,{__index=function(self,k)
  if k=='CreateFontString' then return function() return CreateFrame() end end
  if k=='SetScript' or k=='HookScript' then return function(s,e,fn) s.scripts[e]=fn end end
  if k=='Show' then return function(s) s.shown=true; if s.scripts.OnShow then s.scripts.OnShow(s) end end end
  if k=='Hide' then return function(s) s.shown=false; if s.scripts.OnHide then s.scripts.OnHide(s) end end end
  if k=='SetShown' then return function(s,v) if v then s:Show() else s:Hide() end end end
  if k=='IsShown' then return function(s) return s.shown end end
  if k=='SetText' then return function(s,v) s.text=v end end
  if k=='GetText' then return function(s) return s.text or '' end end
  if k=='SetupMenu' then return function(s,fn) s.menuBuilder=fn end end
  if k=='GetStringHeight' then return function() return 200 end end
  return function() end
 end})
 if name then _G[name]=f end
 return f
end
function UnitFactionGroup() return 'Alliance' end
function UnitOnTaxi() return false end
function CreateVector2D(x,y) return {GetXY=function() return x,y end} end
function print() end
C_Map={GetBestMapForUnit=function() return 1453 end,
 GetPlayerMapPosition=function() return CreateVector2D(.5,.5) end,
 GetMapInfo=function(id) return {name='Map '..id} end}
''')
for filename in ('TravelData.lua','Network.lua','Planner.lua','Core.lua','Coordinates.lua','UI.lua'):
    lua.execute('local code=...; assert(loadstring(code))("ApexNavigator", A)',
                (root/filename).read_text(encoding='utf-8'))

lua.execute('''
-- Directed routes and optional flights must affect the result, not just labels.
local g={nodes={a={},b={},c={},d={}},edges={}}
A.Edge(g,'a','b','boat',100,'boat')
A.Edge(g,'b','c','boat',100,'boat')
A.Edge(g,'c','a','boat',100,'boat')
A.Edge(g,'a','c','flight',10,'flight','Alliance',true)
A.Edge(g,'a','d','flight',1,'unconfirmed','Alliance',false)
local route,cost=A.Shortest(g.nodes,g.edges,'a','c',{faction='Alliance',flights=false})
assert(#route==2 and cost==200)
route,cost=A.Shortest(g.nodes,g.edges,'a','c',{faction='Alliance',flights=true})
assert(#route==1 and cost==10)
assert(not A.Shortest(g.nodes,g.edges,'a','d',{faction='Alliance',flights=true}))
route,cost=A.Shortest(g.nodes,g.edges,'a','c',{faction='Horde',flights=true})
assert(cost==200)
route,cost=A.Shortest(g.nodes,g.edges,'c','b',{flights=false})
assert(#route==2 and cost==200) -- one-way loop cannot reverse
assert(A.Distance({continent=0,wx=0,wy=0},{continent=1,wx=0,wy=0})==nil)
assert(A.FlightEstimate(2,6)>0)
assert(not A.FlightEstimate(2,999999))

-- Model maps separately so land links can only be created explicitly.
local originalTo,originalFrom=A.ToWorld,A.FromWorld
A.ToWorld=function(map,x,y,label)
 return {map=map,x=x,y=y,continent=map,wx=x*1000,wy=y*1000,label=label}
end
A.FromWorld=function(c,x,y,label)
 return {map=9000+c,continent=c,wx=x,wy=y,x=.5,y=.5,label=label}
end
local db={faction='Alliance',flights=false,speed=7,flightOffers={}}
local start=A.ToWorld(1453,.5,.5,'start'); local finish=A.ToWorld(1455,.5,.5,'finish')
local network=A.BuildGraph(start,finish,db)
route,cost=A.Shortest(network.nodes,network.edges,'start','finish',db)
assert(route)
local tram=false; for _,e in ipairs(route) do tram=tram or e.kind=='tram' end
assert(tram,'Stormwind to Ironforge should use the tram')
local unknown=A.ToWorld(99999,.5,.5,'unmapped')
network=A.BuildGraph(start,unknown,db)
assert(not A.Shortest(network.nodes,network.edges,'start','finish',db))
db.faction='Horde'
network=A.BuildGraph(start,finish,db)
assert(not A.Shortest(network.nodes,network.edges,'start','finish',db),'Horde cannot use Alliance tram')
assert(A.LandRegion({map=1438,y=.9})~=A.LandRegion({map=1438,y=.5}))
assert(A.LandRegion({map=1444,x=.3})~=A.LandRegion({map=1444,x=.5}))

-- All stock transport edges retain direction; loop has exactly three directed legs.
local loop={}
for _,t in ipairs(A.transports) do
 assert(t[3]~=nil and t[6]~=nil)
 if t[2]=='Menethil - Southshore - Auberdine' then loop[#loop+1]=t end
end
assert(#loop==3)

-- Smoke-load the UI, validate controls and play through a transport stage.
A.db={faction='Alliance',flights=false,speed=7,flightOffers={}}
A.CreateUI(); A.CreateMinimap(); assert(A.frame and A.minimap)
assert(not A.frame:IsShown())
A.graph={nodes={dock={map=1,x=.1,y=.1,continent=1,wx=0,wy=0,label='dock'},
 arrival={map=2,x=.2,y=.2,continent=2,wx=50,wy=50,label='arrival'}}}
A.route={{from='dock',to='arrival',kind='boat',seconds=300,text='Test boat'}}
A.step=1; A.frame:Show()
local at={continent=1,wx=0,wy=0}
A.PlayerPoint=function() return at end
A.Next(); assert(A.riding and A.step==1)
A.Next(); assert(A.step==1,'Cannot mark arrival on the wrong continent')
at={continent=2,wx=50,wy=50}
A.Next(); assert(A.step==2 and not A.riding)

-- Closing the panel keeps the arrow and hidden walking progression operational.
local removed={}; local added={}
TomTom={RemoveWaypoint=function(_,uid) removed[#removed+1]=uid end,
 AddWaypoint=function(_,map,x,y,opts) added[#added+1]=opts.title; return 'new-arrow' end}
A.step=1; A.riding=false; A.arrow='own-waypoint'; A.frame:Hide()
assert(A.arrow=='own-waypoint' and #removed==0)
A.Arrow(); assert(A.arrow=='new-arrow' and #added==1 and removed[1]=='own-waypoint')
A.route={{from='dock',to='arrival',kind='walk',seconds=10,text='Walk'}}
A.step=1; at={continent=2,wx=50,wy=50}
frames[1].scripts.OnUpdate(nil,1)
assert(A.step==2 and not A.arrow and not A.frame:IsShown())
A.db.destination={map=2,x=.2,y=.2}; A.step=1; A.arrow='stop-arrow'
SlashCmdList.APEXNAVIGATOR('stop'); assert(not A.arrow and not A.db.destination and not A.route)

-- Taxi discovery must never trust the continent API's bogus all-discovered flags.
function NumTaxiNodes() return 3 end
local kinds={'CURRENT','REACHABLE','DISTANT'}
function TaxiNodeGetType(i) return kinds[i] end
function TaxiNodeName(i) return ({'Stormwind, Elwynn','Ironforge, Dun Morogh','Lakeshire, Redridge'})[i] end
C_Map.GetTaxiNodesForMap=nil
A.ReadFlights()
assert(A.db.flightOffers['2:6'])
assert(not A.db.flightOffers['2:5'])
assert(not A.db.flightOffers['6:2'],'Do not invent reverse flight availability')
A.ToWorld,A.FromWorld=originalTo,originalFrom

-- OpenMap cursor coordinates use its public map conversion and do not assume
-- that the canvas's host zone is the zone underneath the mouse.
local picked
local setDestination=A.SetDestination
A.SetDestination=function(m,x,y) picked={m,x,y} end
OpenMapAPI={IsStitched=function() return true end,
 CursorPosition=function() return .2,.3 end,
 MapAt=function(u,v) assert(u==.2 and v==.3); return 1455 end,
 MapFromWorld=function(m,u,v) assert(m==1455); return .4,.6 end}
A.armed=true; A.MapClick()
assert(picked[1]==1455 and picked[2]==.4 and picked[3]==.6 and not A.armed)
OpenMapAPI=nil
WorldMapFrame={GetMapID=function() return 1439 end,
 GetNormalizedCursorPosition=function() return .3,.7 end,ScrollContainer={}}
A.MapClick(); assert(picked[1]==1439 and picked[2]==.3 and picked[3]==.7)
A.SetDestination=setDestination

-- Overlapping map rectangles must not silently pick the first city. Native
-- continent lookup selects Redridge, while explicit transport maps stay exact.
C_Map.GetMapPosFromWorldPos=function(c,p,map) return map,CreateVector2D(.25,.5) end
C_Map.GetWorldPosFromMapPos=function(map,p) return 0,CreateVector2D(10,20) end
C_Map.GetMapInfoAtPosition=function(map) return {mapID=1433} end
local resolved=A.FromWorld(0,10,20,'test')
assert(resolved.map==1433,'Do not assign an overlapping city rectangle')
resolved=A.FromWorld(0,10,20,'dock',1437); assert(resolved.map==1437)
assert(not A.FromWorld(0,1000,2000,'bad transform',1437),'Reject a failed coordinate round-trip')
for _,t in ipairs(A.transports) do
 assert(A.TransportMap(t,t[3],t[4],t[5]) and A.TransportMap(t,t[6],t[7],t[8]))
end
local realRoute=A.Route; local replans=0
A.Route=function() replans=replans+1; A.route={} end
local token=A.FollowGuide(1433,.3,.5,'Fishing area')
assert(A.db.destination==token and token.source=='ApexFishing')
local manual={map=1453,x=.5,y=.5}; A.db.destination=manual
A.CancelGuide(token); assert(A.db.destination==manual and replans==1)
token=A.FollowGuide(1433,.3,.5,'Fishing area'); A.CancelGuide(token)
assert(not A.db.destination and replans==3)
A.Route=realRoute
''')
print('PASS: Lua 5.1 load, directed routing, flight toggle/discovery, faction filters, tram, islands, disconnected maps, UI controls, transport arrival, waypoint ownership, native/OpenMap map clicks.')

lua.execute('''
local function near(a,b) return math.abs(a-b)<1e-9 end
local x,y=A.ParseCoordinates('42.5,67.8');assert(near(x,.425) and near(y,.678))
x,y=A.ParseCoordinates('  42.5 , 67.8  ');assert(near(x,.425) and near(y,.678))
x,y=A.ParseCoordinates('0 100');assert(x==0 and y==1)
x,y=A.ParseCoordinates('.5 50.');assert(x==.005 and y==.5)
for _,value in ipairs({'','50','50 50 50','-1 50','101 50','nan 50','50, nope','1..2 3','50,,60','inf 2'}) do
 assert(not A.ParseCoordinates(value),'Invalid coordinates accepted: '..value)
end
local mapInfo=C_Map.GetMapInfo
C_Map.GetMapInfo=function(id)
 return {name=({[1453]='Stormwind City',[1433]='Redridge Mountains',[1438]='Teldrassil',[1439]='Darkshore'})[id] or 'Map '..id}
end
assert(A.ResolveCoordinateZone('')==1453)
assert(A.ResolveCoordinateZone('1433')==1433)
assert(A.ResolveCoordinateZone(' redridge mountains ')==1433)
assert(A.ResolveCoordinateZone('Redridge')==1433)
assert(not A.ResolveCoordinateZone('Map')) -- ambiguous
assert(not A.ResolveCoordinateZone('999999'))
local setDestination=A.SetDestination
local picked
A.SetDestination=function(map,px,py) picked={map,px,py} end
A.armed=true
assert(A.CoordinateCommand('42.5, 67.8'))
assert(picked[1]==1453 and near(picked[2],.425) and near(picked[3],.678) and not A.armed)
assert(A.CoordinateCommand('Redridge Mountains 42.5 67.8') and picked[1]==1433)
SlashCmdList.APEXNAVIGATOR('1453 50 60');assert(picked[1]==1453 and picked[2]==.5 and picked[3]==.6)
SlashCmdList.APEXNAVIGATOR('  Darkshore 25, 75  ');assert(picked[1]==1439 and picked[2]==.25)
local last=picked
assert(not A.NavigateCoordinates(1433,'101 20') and picked==last,'Invalid input replaced route')
assert(not A.NavigateCoordinates('Unknown zone','50 50') and picked==last)
-- Exercise the live dropdown's zone callback and the Go/Enter callbacks.
local choices={}
A.zonePicker.menuBuilder(nil,{SetScrollMode=function(_,height) assert(height==280) end,
 CreateRadio=function(_,name,isSelected,select) choices[name]={isSelected,select} end})
choices['Redridge Mountains'][2]();assert(A.coordinateMap==1433 and choices['Redridge Mountains'][1]())
A.coordinateInput:SetText('33.3, 66.6')
A.coordinateGo.scripts.OnClick();assert(picked[1]==1433 and near(picked[2],.333) and near(picked[3],.666))
A.coordinateInput:SetText('40 70');A.coordinateInput.scripts.OnEnterPressed()
assert(picked[2]==.4 and picked[3]==.7)
A.SetDestination=setDestination;C_Map.GetMapInfo=mapInfo
''')
print('PASS: coordinate decimals/bounds/validation, current/named/ID zones, ambiguity, slash commands, dropdown and Go/Enter callbacks, invalid input preserves route.')
