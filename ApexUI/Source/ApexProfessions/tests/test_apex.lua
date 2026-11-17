local P=ns.Apex
local function assertEq(a,b) assert(a==b,tostring(a)..' ~= '..tostring(b)) end
local state={skill=1,maxSkill=75,target=15,level=20,faction='A',known={},owned={}}
local s={source='buy',mode='cheap',target=25,today=true}

-- Prices: age is per item, missing is nil, vendor unit cost can beat an auction.
local oldPrice=Auctionator.API.v1.GetAuctionPriceByItemID
local oldAge=Auctionator.API.v1.GetAuctionAgeByItemID
Auctionator.API.v1.GetAuctionPriceByItemID=function(_,id) if id==999999 then return nil end return 100 end
Auctionator.API.v1.GetAuctionAgeByItemID=function(_,id) return id==765 and 2 or 0 end
local quote,lookup=P.Quotes(s,state,{herbalism=75},{},1429)
assertEq(quote(765,2),nil)
assertEq(quote(2447,2),200)
assertEq(quote(999999,2),nil)
assert(quote(3371,2)<200,'vendor vial price should beat auction')
s.today=false
quote,lookup=P.Quotes(s,state,{herbalism=75},{},1429)
assertEq(quote(765,2),200); assertEq(lookup(765).ageDays,2)
s.today=true; s.source='self'
quote,lookup=P.Quotes(s,state,{herbalism=75},{},1429)
assertEq(quote(2447,20),0); assertEq(lookup(2447).source,'farm')
assertEq(quote(999999,2),nil)
quote=P.Quotes(s,state,{herbalism=0},{},1429)
assertEq(quote(2447,20),nil,'unlearned gathering must not be free')
Auctionator.API.v1.GetAuctionPriceByItemID=oldPrice
Auctionator.API.v1.GetAuctionAgeByItemID=oldAge

-- Engine: gold route and time route make different, deliberate choices.
local data={ranks={{name='Apprentice',cap=75,learnAt=0,how='trainer'}},vendorPrices={},recipes={
 [1]={name='Cheap yellow',learn=1,colors={1,1,40,80},mats={[101]=1},get={{kind='start'}}},
 [2]={name='Expensive orange',learn=1,colors={1,40,60,80},mats={[102]=1},get={{kind='start'}}}
}}
local function costs(id,n) return (id==101 and 1 or 10000)*n end
state.target=20
local cheap=ns.Ladder.Build(data,state,costs,{wholeCrafts=true})
local fast=ns.Ladder.Build(data,state,costs,{wholeCrafts=true,fastest=true})
assertEq(cheap.steps[1].recipe,1); assertEq(fast.steps[1].recipe,2)
assert(fast.crafts<=cheap.crafts)

-- Inventory is not reusable when a later step consumes the same raw material.
data.recipes[1].colors={1,1,5,5}; data.recipes[2].learn=5; data.recipes[2].colors={5,20,30,40}
data.recipes[2].mats={[101]=2}; state.owned={[101]=3}; state.target=10
local r=ns.Ladder.Build(data,state,costs,{wholeCrafts=true})
local have=0
for _,step in ipairs(r.steps) do for _,b in pairs(step.buy or {}) do have=have+b.have end end
assertEq(have,3)

-- Two different intermediate crafts cannot each spend the same owned reagent.
local nested={ranks=data.ranks,vendorPrices={},recipes={
 [11]={name='Part A',learn=1,colors={1,1,1,1},makes=201,mats={[101]=1},get={{kind='start'}}},
 [12]={name='Part B',learn=1,colors={1,1,1,1},makes=202,mats={[101]=1},get={{kind='start'}}},
 [13]={name='Final',learn=1,colors={1,20,30,40},mats={[201]=1,[202]=1},get={{kind='start'}}}
}}
local nr=ns.Ladder.Build(nested,{skill=1,maxSkill=75,target=2,level=20,faction='A',known={},owned={[101]=1}},
 function(id,n) return (id==101 and 10 or 100)*n end,{wholeCrafts=true})
assertEq(nr.cost,10)
local used=0
for _,b in pairs(nr.steps[1].buy) do for _,raw in pairs(b.make.parts) do used=used+raw.have end end
assertEq(used,1)

-- Merged buy/make batches retain both their purchases and their raw-material list.
local mergedBuy={[201]={need=7,have=0,buy=7,cost=40,
 make={spell=11,crafts=1,made=2,used=2,parts={[101]={need=1,have=0,buy=1,cost=10}}}}}
local shop=P.Shopping({steps={{buy=mergedBuy}}},
 function(id) return {source='auctionator',unit=id==201 and 6 or 10,ageDays=0} end)
local found={} for _,row in ipairs(shop) do found[row.item]=row.buy end
assertEq(found[201],5); assertEq(found[101],1)

-- Every main/secondary profession loads and plans for both factions.
for _,d in ipairs(ns.Professions) do
 if not d.class then
  for _,faction in ipairs({'A','H'}) do
   for _,mode in ipairs({'cheap','fast'}) do
    local st={skill=1,maxSkill=75,level=60,faction=faction,known={},owned={},class='MAGE'}
    local p=P.Build(d,{source='buy',mode=mode,target=300,today=true},st)
    assert(p and p.steps and p.audit and p.shopping,d.name)
    assert(#p.steps>0,d.name..' empty')
    assert(not p.stuck,d.name..' stuck: '..tostring(p.stuck))
    for _,row in ipairs(p.shopping) do assert(row.buy>=0 and row.have>=0) end
   end
  end
 end
end

-- Skill gates stay visible, target cannot exceed 300, unknown budgets stay partial.
local p=P.Build(ns.ALCHEMY,{source='buy',mode='cheap',target=999,today=true},
 {skill=1,maxSkill=75,level=10,faction='A',known={},owned={}})
assertEq(p.state.target,300); assert(p.levelGate and p.levelGate>10)
Auctionator.API.v1.GetAuctionPriceByItemID=function() return nil end
p=P.Build(ns.ALCHEMY,{source='buy',mode='cheap',target=25,today=true},state)
assert(p.audit.unknown>0,'missing auction materials must stay explicitly unpriced')
Auctionator.API.v1.GetAuctionPriceByItemID=oldPrice

-- Open the full UI against the host mock and click the tabs/controls.
P.Open()
assert(ApexProfessionsGuideFrame:IsShown())
local f=ApexProfessionsGuideFrame
assert(f.summary:GetText():find('ESTIMATE'))
f.mode.options[2].scripts.OnClick(f.mode.options[2])
assert(f.summary:GetText():find('FASTEST'))
f.source.options[2].scripts.OnClick(f.source.options[2])
f.goal:SetText('75'); f.goal.scripts.OnEnterPressed(f.goal)
f.today:SetChecked(false); f.today.scripts.OnClick(f.today)
for _,child in ipairs(f.children) do
 if rawget(child,'label') and child.label:GetText()=='Materials' then child.scripts.OnClick(child) end
end
P.Toggle(); assert(not f:IsShown()); P.Toggle(); assert(f:IsShown())
mock.fire('SKILL_LINES_CHANGED')
-- Refreshing bags/prices must preserve the material being read.
f.source.options[1].scripts.OnClick(f.source.options[1])
f.goal:SetText('150');f.goal.scripts.OnEnterPressed(f.goal)
assert(f.list.used>=2)
f.list.rows[2]:GetScript('OnClick')(f.list.rows[2])
local selectedText=f.list.rows[2].label:GetText()
P.Render(true)
assert(f.list.rows[2].selected and f.list.rows[2].label:GetText()==selectedText)
-- A failed rebuild must not leave an outdated plan actionable on screen.
local build=P.Build;P.Build=function() error('intentional planner failure') end
P.Render(true);assert(f.list.used==0 and f.summary:GetText():find('Could not build'))
assert(f.detail.used==1)
P.Build=build;P.Render(true);assert(f.list.used>0)
P.SyncProgress(true);assert(f.list.rows[1].selected)
assert(_G.CraftLadderDB==nil,'must not overwrite another addon\'s settings')
