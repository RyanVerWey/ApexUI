from pathlib import Path
from lupa.lua51 import LuaRuntime
root=Path(__file__).resolve().parents[1]
lua=LuaRuntime(unpack_returned_tuples=True)
lua.execute('''
A={}; ApexFishingDB={origin='teldrassil',done={},mode='combined'}; inventory={}; frames={}; now=10
function GetTime() return now end
function GetItemCount(id) return inventory[id] or 0 end
function UnitLevel() return 22 end
function UnitFactionGroup() return 'Alliance' end
function UnitRace() return 'Night Elf','NightElf' end
function UnitChannelInfo() if channel then return 'Fishing',nil,nil,0,30000,nil,nil,7620 end end
function CreateVector2D(x,y) return {GetXY=function() return x,y end} end
C_Spell={GetSpellName=function() return 'Fishing' end}
C_Map={GetBestMapForUnit=function() return 1433 end,GetPlayerMapPosition=function() return CreateVector2D(.3,.5) end,
 GetMapInfo=function(id) return {name='Zone '..id} end}
function CreateFrame()
 local f={scripts={}}
 function f:SetScript(e,fn) self.scripts[e]=fn end
 setmetatable(f,{__index=function() return function() end end}); frames[#frames+1]=f; return f
end
ApexNavigator={EstimateTravel=function(sm,x,y,dm)
 return dm==1433 and 10 or dm==1455 and 100 or dm==1457 and 800 or 300
end}
''')
for file in ('Data.lua','Guide.lua','Locations.lua','Spots.lua','Steps.lua'):
    lua.execute('local code=...; assert(loadstring(code))("ApexFishing",A)',(root/file).read_text())
lua.execute('''
local s={f=150,fcap=225,c=100,ccap=150,level=22,faction='Alliance'}
local route=A.BuildRoute('Alliance','combined','teldrassil')
local ids={}; local c125
for i,step in ipairs(route) do ids[step.id]=i; if step.id=='c125' then c125=step end end
assert(ids.c125<ids['cook-book-buy'],'Do not send the player back to the capital after buying the book')
assert(ids.c225<ids['nat-accept'],'Finish attainable Cooking before the level-35 quest gate')
local next=A.GuidedStep(c125,s)
assert(next.phase=='fish' and next.kind=='batch' and next.goal==20 and next.count==0)
assert(next.spot.id=='everstill','Current location outranks stored Night Elf starting region')
inventory[6308]=20
next=A.GuidedStep(c125,s)
assert(next.phase=='cook' and next.point==nil,'Cook locally, do not navigate back to a trainer')
s.c=115; inventory[6308]=0
next=A.GuidedStep(c125,s)
assert(next.phase=='fish' and next.goal==10,'Only request a top-up batch for remaining points')
inventory[6308]=10; assert(A.GuidedStep(c125,s).phase=='cook')
s.c=125; assert(A.Complete(c125,s,{}))
local low=A.AvailableSpots({f=1,level=1,faction='Alliance'},6291)
for _,spot in ipairs(low) do assert(spot.minSkill<=1 and spot.level<=1 and spot.faction~='Horde') end
assert(#A.AvailableSpots({f=150,level=22,faction='Alliance'},8365)==0,'Do not send a low-level character into higher-level water silently')

-- Preserve all trainer/vendor coordinates; the water catalogue is separate.
assert(A.points.darn[2]==47.6 and A.points.darn[3]==56.6)
assert(A.points.heming[2]==27.4 and A.points.heming[3]==77.2)
assert(A.points['water:everstill'].area)

-- A real fish loot records the bank, not an arbitrary cast or unrelated loot.
channel=true; frames[1].scripts.OnEvent(nil,'UNIT_SPELLCAST_CHANNEL_START','player')
assert(not ApexFishingDB.observedSpots)
function GetNumLootItems() return 1 end
function GetLootSlotLink() return 'item:6308:0:0' end
channel=false; now=25; frames[1].scripts.OnEvent(nil,'UNIT_SPELLCAST_CHANNEL_STOP','player')
A.activeStep={session='c125',item=6308}
frames[1].scripts.OnEvent(nil,'LOOT_OPENED')
local key=ApexFishingDB.spotChoice.c125
assert(key:match('^caught:'))
assert(ApexFishingDB.observedSpots[key].x==30 and ApexFishingDB.observedSpots[key].y==50)
local p=A.ChooseSpot(s,6308,'c125'); assert(p.observed)

-- Arrival at a water area clears the centre arrow rather than sending the
-- player into the water. Cooking also has no spurious destination.
ApexFishingDB.arrow=true
local cleared=0; A.ClearWaypoint=function() cleared=cleared+1 end
A.UpdateNavigation({id='near',point='water:everstill'},s); assert(cleared==1)
A.UpdateNavigation({phase='cook'},s); assert(cleared==2)

-- Catch goals remain quantities, never guessed guarantees of skill points.
local cf={id='c50',kind='skill',skill='c',target=50,body='Cook Smallfish'}
ApexFishingDB.batch=nil; local b=A.GuidedStep(cf,{f=40,c=49,level=10,faction='Alliance'})
assert(b.goal==1)

-- Play through both factions' complete guided loops with imperfect cooking
-- gains. Skill goals must never complete merely because one batch was caught.
for _,faction in ipairs({'Alliance','Horde'}) do
 for _,origin in ipairs(faction=='Alliance' and {'elwynn','teldrassil','dunmorogh','zephras'} or {'mulgore','durotar','tirisfal','zephras'}) do
  ApexFishingDB={origin=origin,done={},mode='combined'}; inventory={}
  local state={f=1,fcap=75,c=1,ccap=75,level=60,faction=faction}
  local complete={}; local turns=0
  while true do
   local r=A.BuildRoute(faction,'combined',origin)
   local pending=A.PrioritizePending(r,A.Pending(r,state,complete),state)
   if #pending==0 then break end
   turns=turns+1; assert(turns<350,'Guide stuck: '..origin)
   local base=r[pending[1]]; local task=A.GuidedStep(base,state)
   assert(not A.Blocked(base,state),base.id)
   if task.kind=='batch' then
    assert(task.spot,task.id..' missing eligible water')
    inventory[task.item]=task.goal
    state.f=math.min(state.fcap,state.f+math.ceil(task.goal/3))
   elseif task.phase=='cook' then
    state.c=math.min(state.ccap,base.target,state.c+math.max(1,math.floor(inventory[task.item]/2)))
    inventory[task.item]=0
   elseif base.kind=='cap' then state[base.skill..'cap']=base.target
   elseif base.kind=='manual' then complete[base.id]=true
   elseif base.kind=='skill' then state[base.skill]=base.target
   elseif base.kind=='item' then inventory[base.item]=base.target
   else error(base.id) end
  end
  assert(state.f==300 and state.c==300 and state.fcap==300 and state.ccap==300)
 end
end
''')
print('PASS: inventory batches/top-ups, local cooking, current-location ranking, level/fish filters, preserved NPCs, observed banks, area-arrival arrows, route order.')
