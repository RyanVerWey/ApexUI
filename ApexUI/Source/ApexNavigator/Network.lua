local _, A = ...
-- Explicit land connections keep continent proximity from becoming an ocean shortcut.
-- Coordinates are road/zone transition waypoints, not terrain navigation meshes.
A.zoneMaps={1453,1455,1457,1454,1456,1458,2521,2548,
 1426,1429,1432,1433,1436,1431,1434,1437,1416,1424,1421,1420,
 1417,1425,1422,1423,1418,1427,1428,1430,1435,
 1438,1439,1440,1442,1443,1444,1445,1411,1412,1413,1441,
 1446,1447,1448,1449,1450,1451,1452}
A.roads={
 {1453,73,91,1429,32,49,'Stormwind gates'},
 {1455,15,84,1426,53,36,'Ironforge gates'},
 {1454,52,85,1411,45,12,'Orgrimmar gates'},
 {1456,51,31,1412,38,28,'Thunder Bluff elevator'},
 {1458,66,18,1420,62,66,'Undercity entrance and elevator'},
 {1426,84,51,1432,19,63,'South Gate tunnel'},
 {1432,25,10,1437,53,73,'Dun Algaz tunnels'},
 {1429,20,79,1436,60,19,'Westfall bridge'},
 {1429,93,72,1433,9,71,'Redridge road'},
 {1436,67,72,1431,6,60,'Duskwood bridge'},
 {1433,9,72,1431,93,12,'Three Corners road'},
 {1431,44,88,1434,38,4,'Stranglethorn road'},
 {1433,46,10,1428,78,64,'Burning Steppes pass'},
 {1428,31,30,1427,34,83,'Blackrock Mountain passage'},
 {1432,47,79,1418,48,7,'Badlands pass'},
 {1418,3,60,1427,80,83,'Searing Gorge road'},
 {1431,93,41,1430,41,28,'Deadwind Pass road'},
 {1430,59,41,1435,9,60,'Swamp of Sorrows road'},
 {1435,33,73,1419,52,7,'Blasted Lands road'},
 {1437,51,10,1417,45,88,'Thandol Span'},
 {1417,20,30,1424,86,31,'Thoradin wall road'},
 {1424,14,48,1421,67,79,'Silverpine road'},
 {1421,64,8,1420,54,76,'Tirisfal road'},
 {1424,55,4,1416,49,77,'Alterac road'},
 {1424,85,20,1425,8,55,'Hinterlands mountain path'},
 {1416,77,45,1422,43,85,'Chillwind road'},
 {1420,83,70,1422,28,58,'Western Plaguelands road'},
 {1422,69,50,1423,8,70,'Eastern Plaguelands bridge'},
 {1439,43,94,1440,30,16,'Ashenvale road'},
 {1440,68,85,1413,48,5,'Mor\'shan rampart'},
 {1440,42,72,1442,78,43,'Talondeep tunnel'},
 {1440,55,31,1448,54,87,'Felwood road'},
 {1440,95,48,1447,10,74,'Azshara bridge'},
 {1448,65,8,1452,28,34,'Timbermaw tunnel (reputation danger)'},
 {1448,65,8,1450,36,73,'Timbermaw tunnel (reputation danger)'},
 {1411,36,30,1413,62,20,'Durotar bridge'},
 {1412,68,60,1413,45,72,'Mulgore pass'},
 {1413,46,17,1442,81,98,'Stonetalon road'},
 {1442,30,78,1443,54,8,'Desolace pass'},
 {1443,44,94,1444,45,3,'Feralas road'},
 {1413,49,79,1445,30,46,'Dustwallow road'},
 {1413,44,92,1441,31,25,'Great Lift (Horde guards)'},
 {1441,10,9,1444,89,41,'Feralas pass'},
 {1441,78,94,1446,51,25,'Tanaris road'},
 {1446,27,57,1449,71,76,'Un\'Goro ramp'},
 {1449,29,22,1451,82,18,'Silithus ramp'},
}
table.insert(A.zoneMaps,1419)

function A.ToWorld(map,x,y,label)
 if not (C_Map and C_Map.GetWorldPosFromMapPos and CreateVector2D) then return end
 local ok,c,p=pcall(C_Map.GetWorldPosFromMapPos,map,CreateVector2D(x,y))
 if not ok or not p or c==nil then return end
 local wx,wy=p:GetXY()
 return {map=map,x=x,y=y,continent=c,wx=wx,wy=wy,label=label or 'Destination'}
end

function A.FromWorld(c,wx,wy,label,preferredMap)
 if not (C_Map and C_Map.GetMapPosFromWorldPos) then return end
 local function project(map)
  local ok,id,p=pcall(C_Map.GetMapPosFromWorldPos,c,CreateVector2D(wx,wy),map)
  if ok and p and id==map then
   local x,y=p:GetXY()
   if x>=0 and x<=1 and y>=0 and y<=1 then
    local roundTrip=A.ToWorld(map,x,y)
    if roundTrip and roundTrip.continent==c and (roundTrip.wx-wx)^2+(roundTrip.wy-wy)^2<25 then
     return {map=map,x=x,y=y,continent=c,wx=wx,wy=wy,label=label}
    end
   end
  end
 end
 if preferredMap then return project(preferredMap) end
 -- Rectangles overlap: the first city rectangle that contains the coordinates
 -- is NOT necessarily the player's zone. Resolve from the continent hierarchy.
 local root=({[0]=1415,[1]=1414,[2991]=2521})[c]
 local p=root and project(root)
 if not p then return end
 if C_Map.GetMapInfoAtPosition then
  for _=1,6 do
   local ok,info=pcall(C_Map.GetMapInfoAtPosition,p.map,p.x,p.y)
   if not ok or not info or not info.mapID or info.mapID==p.map then break end
   local nextPoint=project(info.mapID); if not nextPoint then break end
   p=nextPoint
  end
 end
 for _,id in ipairs(A.zoneMaps) do if id==p.map then return p end end
 -- Unknown is better than a plausible-looking waypoint on an unrelated map.
end

function A.TransportMap(t,c,wx,wy)
 local name=t[2]
 if name:find('Booty Bay',1,true) then return c==0 and 1434 or 1413 end
 if name:find('Grom\'gol - Orgrimmar',1,true) then return c==0 and 1434 or 1411 end
 if name=='Menethil Ships' then return c==0 and 1437 or 1445 end
 if name:find('Rut\'theran',1,true) then return wx>8000 and 1438 or 1439 end
 if name=='Orgrimmar Zepplins' then return c==1 and 1411 or wx<0 and 1434 or 1420 end
 if name:find('Feathermoon',1,true) then return 1444 end
 if name=='Menethil - Southshore - Auberdine' then return c==1 and 1439 or wx< -2000 and 1437 or 1424 end
 if name:find('Powderfuse',1,true) then return c==0 and 2548 or 1446 end
 if name:find('Alterac Mountains',1,true) then return c==2991 and 2521 or 1416 end
 if name:find('Mulgore',1,true) then return c==2991 and 2521 or 1412 end
 if name=='Stormwind - Auberdine' then return c==0 and 1453 or 1439 end
end

function A.FlightMap(node)
 local city=node[1]:match('^([^,]+)')
 local cities={Stormwind=1453,Ironforge=1455,Orgrimmar=1454,['Thunder Bluff']=1456,Undercity=1458}
 return cities[city]
end

function A.LandRegion(p)
 -- Islands and elevated capitals must use their dedicated links.
 if p.map==1438 then return p.y>.86 and 'ruttheran' or 'teldrassil' end
 if p.map==1444 and p.x<.36 then return 'feathermoon' end
 return p.map
end

function A.BuildGraph(start,finish,db)
 local g={nodes={},edges={}}
 local function add(id,p) if p then p.id=id; g.nodes[id]=p end end
 local function localEdge(a,b,text,seconds,kind,faction)
  local pa,pb=g.nodes[a],g.nodes[b]; if not pa or not pb then return end
  local d=A.Distance(pa,pb)
  seconds=seconds or (d and math.max(5,d*1.35/(db.speed or 7)))
  if seconds then A.Edge(g,a,b,kind or 'walk',seconds,text,faction) end
 end
 local function pair(a,b,text,seconds,kind,faction)
  localEdge(a,b,text,seconds,kind,faction); localEdge(b,a,text,seconds,kind,faction)
 end
 add('start',start); add('finish',finish)
 for i,r in ipairs(A.roads) do
  local a,b='road'..i..'a','road'..i..'b'
  add(a,A.ToWorld(r[1],r[2]/100,r[3]/100,r[7]))
  add(b,A.ToWorld(r[4],r[5]/100,r[6]/100,r[7]))
  pair(a,b,'Follow '..r[7],nil,'road')
 end
 -- Explicit entry/exit links for the tram and Darnassus portal.
 add('tramSW',A.ToWorld(1453,.637,.081,'Deeprun Tram entrance, Dwarven District'))
 add('tramIF',A.ToWorld(1455,.764,.512,'Deeprun Tram entrance, Tinker Town'))
 pair('tramSW','tramIF','Enter Deeprun Tram; ride to the other city, then exit',150,'tram','Alliance')
 add('darnPortal',A.ToWorld(1457,.30,.415,'Darnassus pink portal'))
 add('rutPortal',A.ToWorld(1438,.55,.888,'Rut\'theran portal'))
 pair('darnPortal','rutPortal','Use the pink portal between Darnassus and Rut\'theran',25,'portal','Alliance')
 add('darnGate',A.ToWorld(1457,.90,.57,'Darnassus main gate'))
 add('teldGate',A.ToWorld(1438,.386,.548,'Darnassus road'))
 pair('darnGate','teldGate','Follow the Darnassus road',30,'road')
 for i,t in ipairs(A.transports) do
  local faction=t[1]=='zeppelin' and 'Horde' or 'Alliance'
  if t[2]:find('Booty Bay',1,true) or t[2]:find('Powderfuse',1,true) then faction=nil end
  if t[2]:find('Mulgore',1,true) then faction='Horde' end
  if not faction or faction==db.faction then
   local a,b='transport'..i..'a','transport'..i..'b'
   add(a,A.FromWorld(t[3],t[4],t[5],t[2]..' departure',A.TransportMap(t,t[3],t[4],t[5])))
   add(b,A.FromWorld(t[6],t[7],t[8],t[2]..' arrival',A.TransportMap(t,t[6],t[7],t[8])))
   local arrival=g.nodes[b]
   local zone=arrival and C_Map.GetMapInfo(arrival.map)
   local destination=zone and zone.name or 'the marked arrival'
   A.Edge(g,a,b,t[1],300,'Board '..t[2]..'; ride to '..destination,faction)
  end
 end
 -- Only flight offers actually seen at a flight master are eligible.
 for key,f in pairs(db.flightOffers or {}) do
  if f.from and f.to and A.flightNodes[f.from] and A.flightNodes[f.to] then
   local a,b=A.flightNodes[f.from],A.flightNodes[f.to]
   local aid,bid='flight'..f.from,'flight'..f.to
   add(aid,A.FromWorld(a[2],a[3],a[4],a[1]..' flight master',A.FlightMap(a)))
   add(bid,A.FromWorld(b[2],b[3],b[4],b[1]..' flight master',A.FlightMap(b)))
   local seconds=f.seconds or A.FlightEstimate(f.from,f.to,db.faction)
   if seconds then A.Edge(g,aid,bid,'flight',seconds+20,'Ask the flight master for '..b[1],db.faction,true) end
  end
 end
 -- Short local links are estimates. No edges connect unrelated zones or islands.
 for a,pa in pairs(g.nodes) do
  for b,pb in pairs(g.nodes) do
   if a~=b and A.LandRegion(pa)==A.LandRegion(pb) then
    localEdge(a,b,'Travel to '..(pb.label or 'waypoint')..'; follow local roads')
   end
  end
 end
 return g
end

function A.FlightEstimate(from,to,faction)
 local nodes,edges={},{}
 local mask=faction=='Alliance' and 1 or faction=='Horde' and 2
 for id,n in pairs(A.flightNodes) do
  if not mask or n[5]==mask or n[5]==3 then nodes[id]=true end
 end
 for _,p in ipairs(A.flightPaths) do
  edges[p[1]]=edges[p[1]] or {}
  table.insert(edges[p[1]],{from=p[1],to=p[2],kind='data',seconds=p[3]/30})
 end
 local _,seconds=A.Shortest(nodes,edges,from,to,{})
 return seconds
end

-- Read-only travel-time service for Apex Fishing. It never changes the user's
-- destination, current route, arrow, or saved flight preferences.
function A.EstimateTravel(startMap,sx,sy,endMap,ex,ey)
 if not A.db then return end
 local key=table.concat({startMap,math.floor(sx*200),math.floor(sy*200),endMap,ex,ey,tostring(A.db.flights),A.db.speed or 7},':')
 A.estimateCache=A.estimateCache or {}
 if A.estimateCache[key]~=nil then return A.estimateCache[key] or nil end
 local start,finish=A.ToWorld(startMap,sx,sy,'Start'),A.ToWorld(endMap,ex,ey,'Destination')
 if not start or not finish then return end
 local graph=A.BuildGraph(start,finish,A.db)
 local _,seconds=A.Shortest(graph.nodes,graph.edges,'start','finish',A.db)
 A.estimateCache[key]=seconds or false
 return seconds
end
