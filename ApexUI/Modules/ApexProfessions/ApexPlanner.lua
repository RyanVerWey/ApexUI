-- Generated ApexUI module wrapper; original attribution follows.
local _, suite = ...
suite.Suite.Register("professions", "ApexProfessions/ApexPlanner.lua", function(...)
local CreateFrame = function(...) return suite.Suite.CreateFrame("professions", ...) end
-- ApexProfessions additions, 2026-11-17. GPL-3.0; see UPSTREAM.md.
local ADDON, ns = ...
local P = {}
ns.Apex = P
_G.ApexProfessions = ns
local ceil, min, max = math.ceil, math.min, math.max
local function copy(t) local r={} for k,v in pairs(t or {}) do r[k]=v end return r end

function P.Settings(data)
    local saved=ns.Player.Prof(data)
    saved.apex=saved.apex or {mode='cheap',source='buy',target=150,today=true}
    return saved.apex
end

-- Realm/faction separation belongs to Auctionator's API. Never read another
-- realm's saved table, confuse age-in-days with an epoch, or invent a zero quote.
function P.Auction(item)
    local api=Auctionator and Auctionator.API and Auctionator.API.v1
    if not (api and api.GetAuctionPriceByItemID) then return end
    local ok,price=pcall(api.GetAuctionPriceByItemID,ADDON,item)
    if not ok or type(price)~='number' or price<=0 then return end
    local age
    if api.GetAuctionAgeByItemID then
        local good,n=pcall(api.GetAuctionAgeByItemID,ADDON,item)
        if good and type(n)=='number' then age=n end
    end
    return price, {source='auctionator',unit=price,ageDays=age}
end

function P.PriceText(e)
    if not e then return 'No usable price. Scan this item in Auctionator.' end
    if e.source=='farm' then return 'Farm yourself; no gold purchase. Time is not free.' end
    if e.source=='vendor' then return (e.real and 'Merchant observed' or 'Vendor baseline')..': '..ns.Money(e.unit)..' each' end
    return 'Auctionator: '..ns.Money(e.unit)..' each, '..(e.ageDays==0 and 'seen today'
        or e.ageDays and (e.ageDays..' day(s) old') or 'age unknown')
end

-- All candidates are real zones or source NPCs. Zone-level data opens the map;
-- it never turns the middle of the zone into a pretend exact node waypoint.
function P.Farms(item,state,skills,currentMap)
    local out={}
    local function add(f)
        f.available=(f.need or 0)<=(skills[f.profession] or 0)
            and (not f.profession or (skills[f.profession] or 0)>0)
            and (f.level or 1)<=state.level+2
        f.localZone=f.map and f.map==currentMap
        out[#out+1]=f
    end
    for _,d in ipairs({ns.HERBALISM,ns.MINING,ns.SKINNING}) do
        for _,z in pairs(d.zones) do
            if z.faction=='C' or z.faction==state.faction then
                local best,bestRate
                for id,places in pairs(z.nodes or {}) do
                    local node=d.nodes[id]
                    local rate=node and node.loot and node.loot[item]
                    if rate and rate>0 and (not bestRate or rate*places>bestRate) then best,bestRate=node,rate*places end
                end
                if best then add({profession=d.key,need=best.skill,level=best.level or (z.levels and z.levels[1]) or 1,
                    map=z.map,name=best.name,zone=z.name,method=d.gather.verb,score=bestRate/(z.size or 1),
                    note='Zone survey; spawn availability varies. Classic loot estimates, Forever locations.'}) end
            end
        end
    end
    for _,z in pairs(ns.FISHING.zones) do
        local share=z.fish and z.fish[item]
        if share and share>0.04 and (z.faction=='C' or z.faction==state.faction) then
            add({profession='fishing',need=max(1,(z.base or 0)+95),level=z.levels and z.levels[1] or 1,
                map=z.map,name='Open-water fishing',zone=z.name,method='Fish',score=share*100,
                note='Skill target avoids escapes without a lure; historical catch mix. ApexFishing has detailed fishing guidance.'})
        end
    end
    for _,r in ipairs(ns.ApexDrops[item] or {}) do
        if r.faction=='C' or r.faction==state.faction then
            add({name=r.name,zone=r.zone,map=r.map,x=r.x,y=r.y,level=r.high,method='Hunt',
                score=r.spots,nameID=r.npc,note='QuestieDB drop source; drop rate is not measured. Named drops can be rare.'})
        end
    end
    -- Disenchanting is useful guidance, but not quoted as free: the equipment
    -- has to come from somewhere and may be more valuable sold intact.
    for _,b in pairs(ns.DISENCHANT.buckets) do
        for _,g in ipairs(b.gives) do
            if g.item==item and g.chance>=0.5 then
                add({profession='enchanting',need=b.skill,level=1,method='Disenchant',name=(b.quality==3 and 'Rare ' or 'Uncommon ')..b.class,
                    zone='Item level '..b.levels[1]..'-'..b.levels[2],score=g.chance,notFree=true,
                    note='Item level, not required character level. Random result; equipment cost is not included. Never destroy upgrades.'})
            end
        end
    end
    table.sort(out,function(a,b)
        if a.available~=b.available then return a.available end
        if a.localZone~=b.localZone then return a.localZone end
        if (a.score or 0)~=(b.score or 0) then return (a.score or 0)>(b.score or 0) end
        return (a.zone..a.name)<(b.zone..b.name)
    end)
    return out
end

function P.Quotes(settings,state,skills,real,currentMap)
    local entries,farms={},{}
    local function sources(item)
        if not farms[item] then farms[item]=P.Farms(item,state,skills,currentMap) end
        return farms[item]
    end
    local function lookup(item,ahOnly)
        local key=ahOnly and -item or item
        if entries[key]~=nil then return entries[key] or nil end
        local price,entry=P.Auction(item)
        if settings.today and entry and entry.ageDays~=0 then price,entry=nil,nil end
        if settings.source=='self' then price,entry=nil,nil end
        if not ahOnly then
            local vp,ve=ns.Prices.Vendor(item,state.faction,real)
            if vp and (not price or vp<=price) then price,entry=vp,ve; entry.unit=vp end
            if settings.source~='buy' and not vp then
                for _,f in ipairs(sources(item)) do
                    if f.available and not f.notFree then price,entry=0,{source='farm',unit=0,farm=f}; break end
                end
            end
        end
        entries[key]=entry or false
        return entry
    end
    local function quote(item,n,already,ahOnly)
        local e=lookup(item,ahOnly)
        if not e then return nil end
        return e.unit*n,e
    end
    return quote,lookup,sources
end

function P.Shopping(plan,lookup)
    local rows,components={},{}
    local function walk(buy)
        for item,b in pairs(buy or {}) do
            if b.make then
                components[#components+1]={item=item,spell=b.make.spell,crafts=ceil(b.make.crafts),count=ceil(b.make.made)}
                walk(b.make.parts)
                -- A merged step can both buy and make the same intermediate.
                local direct=max(0,b.buy-(b.make.used or b.make.made))
                if direct>0 then
                    local e=lookup(item)
                    walk({[item]={need=direct,have=0,buy=direct,cost=e and e.unit*direct}})
                end
            else
                local r=rows[item] or {item=item,need=0,have=0,buy=0,cost=0}
                rows[item]=r
                r.need=r.need+b.need; r.have=r.have+b.have; r.buy=r.buy+b.buy
                if b.buy>0 then
                    r.entry=lookup(item)
                    if b.cost==nil then r.unknown=true else r.cost=r.cost+b.cost end
                end
            end
        end
    end
    local fees=0
    for _,s in ipairs(plan.steps) do
        walk(s.buy)
        if s.kind=='rank' then fees=fees+(s.cost or 0) end
        if s.learn then fees=fees+(s.learn.cost or 0) end
    end
    local list={}
    local unknown,farmed,stale=0,0,0
    for _,r in pairs(rows) do
        r.buy=ceil(r.buy-1e-9); r.need=ceil(r.need-1e-9)
        if r.unknown then unknown=unknown+1 end
        if r.entry and r.entry.source=='farm' then farmed=farmed+1 end
        if r.entry and r.entry.source=='auctionator' and r.entry.ageDays~=0 then stale=stale+1 end
        list[#list+1]=r
    end
    table.sort(list,function(a,b) return ns.Describe.ItemName(a.item)<ns.Describe.ItemName(b.item) end)
    return list,components,{unknown=unknown,farmed=farmed,stale=stale,fees=fees}
end

-- Plan from the actual character snapshot. A target past a level gate is a
-- future plan with an explicit "reach level" step, never a claim it is usable now.
function P.Build(data,settings,override)
    local state=override or ns.Player.State(data)
    state=copy(state)
    state.target=max(state.skill,min(300,tonumber(settings.target) or 150))
    local skills={}
    for _,d in ipairs(ns.Professions) do skills[d.key]=ns.Player.Skill(d) end
    local currentMap=C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit('player')
    local quote,lookup,sources=P.Quotes(settings,state,skills,ns.Prices.Real(),currentMap)
    local castTimes,recipeMats={},{}
    for id,r in pairs(data.recipes) do recipeMats[id]=r.mats end
    if settings.mode=='fast' then
        for id in pairs(data.recipes) do
            local info=C_Spell and C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(id)
            if info and type(info.castTime)=='number' and info.castTime>0 then castTimes[id]=info.castTime/1000 end
        end
    end
    local opts={mode=settings.mode=='fast' and data.kind=='mining' and 'fast' or 'skill',wholeCrafts=true,fastest=settings.mode=='fast',castTimes=castTimes,
        apexCheapest=settings.mode~='fast',recipeMats=recipeMats,
        realPrices=ns.Prices.Real(),standing=ns.Player.Standing,favor=false,
        smelt=data.smelt and {skill=skills.mining or 0,recipes=ns.MINING.recipes} or nil,
        rate=data.kind=='fishing' and ns.Fishing.Rate() or nil,
        seenPools=data.kind=='fishing' and ns.Fishing.SeenPools(data) or nil}
    ns.Ladder.overtime=0 -- do not turn an unverified Legacy-perk formula into a promise
    local model=copy(data); model.resale=false
    local build=data.kind=='fishing' and ns.Fishing.Build or data.kind=='mining' and ns.Mining.Build or ns.Ladder.Build
    local result=build(model,state,quote,opts)
    result.data,result.state,result.lookup,result.sources=data,state,lookup,sources
    result.shopping,result.components,result.audit=P.Shopping(result,lookup)
    result.mode,result.source=settings.mode,settings.source
    result.levelGate=nil
    for _,s in ipairs(result.steps) do
        if s.needLevel then result.levelGate=max(result.levelGate or 0,s.needLevel) end
    end
    return result
end

function P.Go(place)
    if not place or not place.map then ns.Chat('No verified map position for this source.'); return end
    if place.x and place.y then
        if ApexNavigator and ApexNavigator.SetGuideDestination then
            ApexNavigator.SetGuideDestination(place.map,place.x/100,place.y/100,place.name)
        elseif TomTom and TomTom.AddWaypoint then
            TomTom:AddWaypoint(place.map,place.x/100,place.y/100,{title='ApexProfessions: '..place.name,persistent=false,world=true,minimap=true,crazy=true})
        else ns.PinAt(place.map,place.x,place.y,place.name,place.zone) end
    elseif WorldMapFrame then
        if ApexProfessionsGuideFrame then ApexProfessionsGuideFrame:Hide() end
        if ToggleWorldMap and not WorldMapFrame:IsShown() then ToggleWorldMap() end
        if WorldMapFrame.SetMapID then WorldMapFrame:SetMapID(place.map) end
        ns.Chat('Showing '..(place.zone or place.name)..'. This is a farming zone, not a pinpoint spawn.')
    end
end

end)
