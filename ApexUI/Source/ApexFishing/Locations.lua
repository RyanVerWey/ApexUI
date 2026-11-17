local _,A=...
local function point(key,map,x,y,label) A.points[key]={map,x,y,label} end
point('darn',1457,47.6,56.6,'Astaia, Darnassus fishing water')
point('alameth',1438,55,66,'Lake Al\'Ameth, Teldrassil')
point('nyoma',1438,57.2,61.3,'Nyoma, Dolanaar recipes')
point('zarrin',1438,57.1,61.3,'Zarrin, Dolanaar Cooking')
point('iron',1455,48.4,6.4,'Grimnur Stonebrand, Ironforge')
point('iceflow',1426,35.6,40.4,'Paxton Ganter, Iceflow Lake')
point('gretta',1426,31.5,44.7,'Gretta Ganter, Smallfish recipe')
point('tansy',1455,48.2,6.5,'Tansy Puddlefizz, fish recipes')
point('daryl',1455,60.1,36.4,'Daryl Riknussun, Ironforge Cooking')
point('org',1454,69.8,29.6,'Lumak, Valley of Honor pond')
point('zamja',1454,57.4,53.8,'Zamja, Orgrimmar Cooking')
point('zansoa',1411,57,76,'Zansoa, Sen\'jin fishing supplies')
point('durotar',1411,55.7,74.4,'Lau\'Tiki, Sen\'jin fishing trainer')
point('uc',1458,80.8,31.2,'Armand Cromwell, Undercity')
point('brightwater',1420,67.2,51,'Clyde Kellen, Brightwater Lake')
point('martine',1420,66,60,'Martine Tramblay, Smallfish recipe')
point('lizbeth',1458,81,30.8,'Lizbeth Cromwell, Snapper recipe')
point('ronald',1458,62,43,'Ronald Burch, Catfish recipe')
point('eunice',1458,62.2,44.6,'Eunice Burch, Cooking trainer')
point('zephras','Zephras Isle',63.2,75.8,'Baelann Swiftcurrent, Valanaar fishing')
point('nyalah','Zephras Isle',60.6,72.7,'Nyalah Brightfire, Cooking trainer')
point('krix','Riverglades',79.2,54.8,'Krix, Powderfuse Port fishing trainer')

local zones={
 [1438]='teldrassil',[1457]='teldrassil',[1439]='teldrassil',
 [1426]='dunmorogh',[1455]='dunmorogh',[1432]='dunmorogh',
 [1429]='elwynn',[1453]='elwynn',[1436]='elwynn',[1433]='elwynn',
 [1412]='mulgore',[1456]='mulgore',[1411]='durotar',[1454]='durotar',
 [1420]='tirisfal',[1458]='tirisfal',[1421]='tirisfal',
}
function A.DetectOrigin()
 local map=C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit('player')
 for _=1,6 do
  if not map or map==0 then break end
  local info=C_Map.GetMapInfo(map)
  if info and info.name=='Zephras Isle' then A.specialMaps=A.specialMaps or {}; A.specialMaps['Zephras Isle']=map; return 'zephras' end
  if info and info.name=='Riverglades' then A.specialMaps=A.specialMaps or {}; A.specialMaps.Riverglades=map; return 'riverglades' end
  if zones[map] then return zones[map] end
  map=info and info.parentMapID
 end
 local race
 if UnitRace then local _,token=UnitRace('player'); race=token end
 local races={NightElf='teldrassil',Dwarf='dunmorogh',Gnome='dunmorogh',Human='elwynn',Orc='durotar',Troll='durotar',Tauren='mulgore',Scourge='tirisfal'}
 return races[race] or (UnitFactionGroup('player')=='Horde' and 'mulgore' or 'elwynn')
end
function A.ResolveMap(map)
 if type(map)=='number' then return map end
 if A.specialMaps and A.specialMaps[map] then return A.specialMaps[map] end
 -- Resolve names through the client hierarchy; do not guess new-zone map IDs.
 if C_Map and C_Map.GetMapChildrenInfo then
  for _,root in ipairs({947,1414,1415}) do
   local children=C_Map.GetMapChildrenInfo(root,nil,true) or {}
   for _,info in ipairs(children) do
    if info.name==map then A.specialMaps=A.specialMaps or {}; A.specialMaps[map]=info.mapID; return info.mapID end
   end
  end
 end
end
local build=A.BuildRoute
function A.BuildRoute(faction,mode,origin)
 local route=build(faction,mode)
 local profiles={
  teldrassil={faction='Alliance',start='alameth',trainer='darn',city='darn',cook='zarrin',recipe='nyoma',shopping='Nyoma in Dolanaar sells Brilliant Smallfish and Longjaw Mud Snapper. Get a pole and lures from Narret Shadowgrove nearby. Catfish recipe: Laird in Auberdine.'},
  dunmorogh={faction='Alliance',start='iceflow',trainer='iceflow',city='iron',cook='daryl',recipe='gretta',shopping='Gretta Ganter sells Brilliant Smallfish. Tansy Puddlefizz in Ironforge sells Longjaw Mud Snapper and Bristle Whisker Catfish. Buy a pole and lures.'},
  durotar={faction='Horde',start='durotar',trainer='durotar',city='org',cook='zamja',recipe='zansoa',shopping='Buy Slitherskin Mackerel from Zansoa at Sen\'jin. Fish the coast for Raw Slitherskin Mackerel and cook it to 50. For Snapper and Catfish recipes, visit Naal Mistrunner in Thunder Bluff.'},
  tirisfal={faction='Horde',start='brightwater',trainer='brightwater',city='uc',cook='eunice',recipe='martine',shopping='Martine Tramblay sells Brilliant Smallfish. Lizbeth Cromwell in Undercity sells Longjaw Mud Snapper; Ronald Burch sells Bristle Whisker Catfish.'},
  zephras={start='zephras',trainer='zephras',city='zephras',cook='nyalah',recipe='nyalah',shopping='Check Nyalah Brightfire for starter fish recipes. Recent hotfix reports conflict about Smallfish and Snapper stock. If absent, use the next verified mainland supplier step. Do not discard your raw fish.'},
 }
 local p=profiles[origin]
 if not p or (p.faction and p.faction~=faction) then
  if origin=='riverglades' then
   for _,s in ipairs(route) do
    if s.id=='learn-f' then s.point='krix'; s.body=s.body..' Krix is your local trainer. Low-skill fish tables here are not verified; the guide uses established starter water after training.' end
   end
  end
  return route
 end
 point('laird',1439,36,44,'Laird, Auberdine fish recipes')
 local defaultCity=faction=='Alliance' and 'sw' or 'tb'
 local start=faction=='Alliance' and 'elwynn' or 'mulgore'
 for _,s in ipairs(route) do
  if s.point==defaultCity then s.point=p.city end
  if s.point==start then s.point=p.start end
  if s.id=='learn-f' or s.id=='journey-f' then s.point=p.trainer end
  if s.id=='learn-c' or s.id=='journey-c' then s.point=p.cook end
  if s.id=='small-recipe' then s.point=p.recipe; s.body=p.shopping end
  if origin=='durotar' and s.id=='c50' then s.title='Cook Mackerel to 50'; s.body='Cook Raw Slitherskin Mackerel from the Sen\'jin coast using the recipe from Zansoa. Catch more until Cooking reaches 50.' end
  if origin=='durotar' and s.id=='f50' then s.body='Fish the coast near Sen\'jin with a lure. Save Raw Slitherskin Mackerel for Cooking 1-50.' end
  if s.id=='cat-recipe' then
   if origin=='teldrassil' then s.point='laird'; s.body='Buy Bristle Whisker Catfish from Laird in Auberdine. Nyoma in Dolanaar supplies Smallfish and Snapper if you still need them.'
   elseif origin=='dunmorogh' then s.point='tansy'; s.body='Buy Longjaw Mud Snapper and Bristle Whisker Catfish from Tansy Puddlefizz in Ironforge.'
   elseif origin=='tirisfal' then s.point='ronald'; s.body='Buy Bristle Whisker Catfish from Ronald Burch. Lizbeth Cromwell near the Fishing trainer supplies Longjaw Mud Snapper.' end
  end
 end
 if origin=='zephras' and mode=='combined' then
  table.insert(route,4,{id='zephras-fallback',title='Resolve starter recipe stock',kind='manual',skipSkill='c',skipAt=100,point=faction=='Alliance' and 'tharynn' or 'sewa',body='If Nyalah had both starter recipes, click Done. Otherwise collect Smallfish from this verified supplier; Alliance: Tharynn also sells Snapper. Horde: get Snapper from Naal nearby. Return to suitable inland starter water to cook your saved fish.'})
 end
 return route
end
