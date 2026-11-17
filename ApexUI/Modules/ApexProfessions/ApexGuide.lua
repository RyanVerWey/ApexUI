-- Generated ApexUI module wrapper; original attribution follows.
local _, suite = ...
suite.Suite.Register("professions", "ApexProfessions/ApexGuide.lua", function(...)
local CreateFrame = function(...) return suite.Suite.CreateFrame("professions", ...) end
-- Apex guide front end. No display CVars, protected actions, automatic purchases or crafting.
local ADDON,ns=...
local P,UI=ns.Apex,ns.UI
local C=UI.C
local frame,plan,profession,selected,tab,dirty
selected,tab,dirty=1,'steps',true
local advancedOpen=ns.Window.Open
local function text(parent,size,color)
    local f=parent:CreateFontString(nil,'OVERLAY')
    f:SetFont('Fonts\\FRIZQT__.TTF',size or 17,'')
    f:SetTextColor(unpack(color or C.text)); f:SetJustifyH('LEFT'); f:SetWordWrap(true)
    return f
end
local function button(parent,label,w,h,fn)
    local b=UI.Button(parent,label,w,h,fn)
    b.label:SetFont('Fonts\\FRIZQT__.TTF',16,'')
    return b
end
local function panel(parent,w)
    local f=CreateFrame('ScrollFrame',nil,parent,'UIPanelScrollFrameTemplate')
    local child=CreateFrame('Frame',nil,f); child:SetSize(w-30,1); f:SetScrollChild(child)
    f.child=child; f.rows={}; f.used=0; f.y=8; f.cw=w-30
    return f
end
local function clear(f)
    for _,r in ipairs(f.rows) do r:Hide() end
    f.used=0; f.y=8; f.child:SetHeight(1)
end
local function line(f,value,color,fn,size,selectedRow)
    f.used=f.used+1
    local r=f.rows[f.used]
    if not r then
        r=CreateFrame('Button',nil,f.child); r.label=text(r,17); r.label:SetPoint('TOPLEFT',6,-4)
        r.bg=r:CreateTexture(nil,'BACKGROUND'); r.bg:SetAllPoints(); r.bg:SetColorTexture(.17,.14,.09,.6); r.bg:Hide()
        r:SetScript('OnEnter',function(self) if self.action then self.bg:Show() end end)
        r:SetScript('OnLeave',function(self) self.bg:SetShown(self.selected) end)
        r:SetScript('OnClick',function(self) if self.action then self.action() end end)
        f.rows[f.used]=r
    end
    r.action=fn; r.selected=selectedRow and true or false; r.bg:SetShown(r.selected); r:EnableMouse(fn~=nil)
    r.label:SetFont('Fonts\\FRIZQT__.TTF',size or 17,'')
    r.label:SetTextColor(unpack(color or C.text)); r.label:SetWidth(f.cw-14); r.label:SetText(value)
    local h=math.max(25,r.label:GetStringHeight()+12)
    r:SetSize(f.cw,h); r:ClearAllPoints(); r:SetPoint('TOPLEFT',0,-f.y); r:Show()
    f.y=f.y+h; f.child:SetHeight(f.y+12)
end
local function npc(f,id)
    local n=ns.Lookup('npcs',id)
    local name,where=ns.Describe.NPC(id)
    if n and n.faction and not n.faction:find(plan.state.faction,1,true) then return end
    line(f,'> '..name..(where and ('  |  '..where) or ''),C.gold,n and n.map and function() ns.Waypoint(id) end or nil)
end
local function stepName(s)
    if s.kind=='rank' then return 'Train '..s.rank.name..' ('..s.rank.cap..')' end
    if s.kind=='craft' then return ns.Describe.RecipeName(s.recipe,profession.recipes[s.recipe]) end
    local z=profession.zones and profession.zones[s.zone]
    return z and z.name or s.kind
end
local function sourceLines(f,item)
    local farms=plan.sources(item)
    local shown=0
    for _,p in ipairs(farms) do
        shown=shown+1
        if shown>2 then break end
        local access=p.available and '' or (' | needs '..(p.profession and (p.profession..' '..(p.need or 1)..', ') or '')..'level '..(p.level or 1)..'+')
        line(f,'> '..p.method..': '..p.name..' - '..p.zone..access,p.available and C.gold or C.muted,p.map and function() P.Go(p) end or nil)
        line(f,p.note,C.muted,nil,15)
    end
    if shown==0 then line(f,'No verified self-farm location in this dataset. Buy it, use another character, or check its source before committing.',C.muted,nil,15) end
end
local function materials(f,buy,depth)
    depth=depth or 0
    local ids={}; for item in pairs(buy or {}) do ids[#ids+1]=item end; table.sort(ids)
    for _,item in ipairs(ids) do
        local b=buy[item]
        line(f,ns.Describe.ItemName(item)..'  '..math.ceil(b.need)..' needed | '..math.floor(b.have)..' owned',C.text)
        if b.make then
            local rec=ns.FindRecipe(b.make.spell)
            line(f,'Craft '..math.ceil(b.make.crafts)..' x '..(rec and rec.name or ns.Describe.ItemName(item))..' yourself.',C.good)
            if depth<4 then materials(f,b.make.parts,depth+1) end
        elseif b.buy>0 then
            local e=plan.lookup(item)
            line(f,math.ceil(b.buy)..' to obtain. '..P.PriceText(e)..(b.cost and (' | subtotal '..ns.Money(b.cost)) or ''),e and C.muted or C.warn,nil,15)
            if e and e.source=='vendor' then line(f,'Buy from a merchant who stocks this item. Visiting that merchant updates your discounted unit price.',C.muted,nil,15)
            else sourceLines(f,item) end
        end
    end
end
local function renderDetail()
    local f=frame.detail; clear(f)
    if tab=='help' then
        line(f,'How your plan is calculated',C.gold,nil,21)
        line(f,'Cheapest compares expected gold outlay among accessible recipes. Owned materials are consumed once across the route. Outputs needed later are kept. No hoped-for auction sales are subtracted.')
        line(f,'Fastest prefers lower modeled crafting time per skill point and easier recipe acquisition. Money is secondary. It is a practical estimate, not a globally optimal travel itinerary.')
        line(f,'Buy materials compares vendors with Auctionator. Farm + buy gaps uses accessible farm sources and buys the rest. Self-farm only excludes auction purchases; missing sources remain unresolved.')
        line(f,'Today only accepts Auctionator item prices with an age of zero days. Turn it off to allow older quotes, which stay labeled. Search at the auction house, then Refresh.')
        line(f,'Yellow/green skill-ups are random. Counts are rounded expected crafts; stop at the stated skill and refresh after each batch. A future rank can require a higher character level.')
        line(f,'Open each profession window once so known recipes are recorded. Visit trainers and merchants to replace baseline assumptions with observations. Recipe and rank learn levels inherited from Classic are marked where known.')
        line(f,'Farming zones come from source and spawn data, not live node availability. Area recommendations open the map without putting a false pin at its center.')
        line(f,'Data: Forever client 1.60.1.70938, Craft Ladder 1.11.0, QuestieDB 1.0.14, CMaNGOS and GatherMate2_Data. Full attribution and research: SOURCES.md / CREDITS.txt.',C.muted,nil,15)
        return
    end
    if tab=='shopping' then
        local r=plan.shopping[selected]
        if not r then line(f,'No reagents to purchase for this plan.',C.good); return end
        line(f,ns.Describe.ItemName(r.item),C.gold,nil,22)
        line(f,r.need..' total | '..math.floor(r.have)..' owned | '..r.buy..' still needed')
        if r.buy>0 then
            line(f,P.PriceText(r.entry),r.unknown and C.warn or C.text)
            line(f,'Estimated item total: '..(r.unknown and 'unknown' or ns.Money(r.cost)),C.gold)
        end
        if r.entry and r.entry.source=='vendor' then
            line(f,'Visit a merchant who stocks this item. Baseline prices are before your reputation discount; observed unlimited-stock prices take precedence.')
        else sourceLines(f,r.item) end
        return
    end
    local s=plan.steps[selected]
    if not s then line(f,plan.stuck and ('Plan stopped: '..plan.stuck..'. Open your profession and trainer windows, scan materials, then Refresh.') or 'Target reached. Choose a higher skill target to continue.',C.gold); return end
    line(f,stepName(s),C.gold,nil,22)
    if s.kind=='rank' then
        local r=s.rank
        line(f,'New cap: '..r.cap..'. Learn at profession skill '..r.learnAt..'.')
        if s.needLevel then line(f,'First reach character level '..s.needLevel..'. Later steps are a future plan.',C.warn) end
        line(f,'Training / book cost: '..ns.Money(s.cost)..' (baseline estimate)')
        if r.note then line(f,r.note) end
        if s.vendor then npc(f,s.vendor) end
        for _,id in ipairs(r.trainers or {}) do npc(f,id) end
        if r.how=='trainer' and not r.trainers then line(f,'Ask a city guard for your '..profession.name..' trainer.') end
        if s.quest then local name,q=ns.Describe.Quest(s.quest); line(f,'Quest: '..name,C.gold); if q and q.npc then npc(f,q.npc) end end
        if r.item then line(f,'Book: '..ns.Describe.ItemName(r.item)) end
        materials(f,s.buy)
    elseif s.kind=='craft' then
        local rec=profession.recipes[s.recipe]
        line(f,'Skill '..s.from..' to '..s.to..' | about '..math.ceil(s.crafts)..' crafts',C.text)
        line(f,'Learn: '..ns.Describe.Learn(s.learn,profession),C.gold)
        local warning=ns.Describe.Unconfirmed(rec,s.learn)
        if warning then line(f,warning,C.warn,nil,15) end
        if s.learn and s.learn.npc then npc(f,s.learn.npc) end
        for _,id in ipairs(rec.trainers or {}) do npc(f,id) end
        if s.learn and s.learn.kind=='trainer' and not rec.trainers then line(f,'Visit a '..profession.name..' trainer. Learn this recipe before making the batch.',C.muted,nil,15) end
        for item,k in pairs(s.keep or {}) do line(f,'KEEP '..math.ceil(k.n)..' '..ns.Describe.ItemName(item)..' for later steps.',C.good) end
        line(f,'Materials for this step',C.gold,nil,19)
        materials(f,s.buy)
        if #s.options>1 then
            line(f,'Other available recipes',C.gold,nil,19)
            for i=2,math.min(4,#s.options) do
                local o=s.options[i]
                line(f,ns.Describe.RecipeName(o.recipe,profession.recipes[o.recipe])..' | '..(o.cost and ns.Money(o.cost) or 'price unknown')..' for skill '..o.from..'-'..o.to,C.muted,nil,15)
            end
        end
    else
        local z=profession.zones[s.zone]
        line(f,'Work here from skill '..s.from..' to '..s.to..'.')
        if s.dangerous then line(f,'Danger: this route includes enemies above your current level. Level your character first or use a safer alternative.',C.warn) end
        if z then
            line(f,'> Open '..z.name..' on the map',C.gold,function() P.Go({map=z.map,name=z.name,zone=z.name}) end)
            if z.levels then line(f,'Zone enemy levels: '..z.levels[1]..'-'..z.levels[2],C.muted) end
            if z.nodes then
                local names={}
                for id in pairs(z.nodes) do
                    local n=profession.nodes[id]
                    if n and n.skill<=s.from and ns.Ladder.Chance(n.colors,s.from)>0 then names[#names+1]=n.name end
                end
                table.sort(names); line(f,'Look for: '..table.concat(names,', '))
            end
            if z.top then line(f,'Typical catch: '..ns.Describe.ItemName(z.top)) end
        end
        line(f,'Route ratings use node density and skill-up estimates. Competition, respawns and travel can change the winner. Check the detailed planner for alternatives.',C.muted,nil,15)
        materials(f,s.buy)
    end
    local nextStep=plan.steps[selected+1]
    if nextStep then line(f,'NEXT: '..stepName(nextStep),C.gold,nil,18) end
end

function P.Render(rebuild)
    if not frame or not frame:IsShown() then dirty=true; return end
    profession=profession or ns.CurrentProfession()
    if rebuild or dirty or not plan then
        local prior=plan and (tab=='shopping' and plan.shopping[selected] or plan.steps[selected])
        local ok,result=pcall(P.Build,profession,P.Settings(profession))
        if not ok then
            plan=nil;clear(frame.list);clear(frame.detail)
            frame.summary:SetText('Could not build this route. Choose another target or click Refresh.')
            line(frame.detail,'The previous plan is hidden because it could not be refreshed.',C.warn)
            ns.Chat(tostring(result)); return
        end
        plan=result; selected=1; dirty=false
        if prior then
            for i,s in ipairs(tab=='shopping' and plan.shopping or plan.steps) do
                if (tab=='shopping' and s.item==prior.item) or
                   (tab=='steps' and s.kind==prior.kind and s.recipe==prior.recipe and s.zone==prior.zone
                    and s.from==prior.from and s.to==prior.to) then selected=i;break end
            end
        end
    end
    local set=P.Settings(profession)
    frame.prof:SetPicked(profession.key)
    frame.mode:SetPicked(set.mode); frame.source:SetPicked(set.source); frame.goal:SetText(tostring(set.target))
    frame.today:SetChecked(set.today)
    for key,b in pairs(frame.tabs or {}) do
        b:SetPanelColors(key==tab and C.hover or C.panel2,key==tab and C.gold or C.edge)
        b.label:SetTextColor(unpack(key==tab and C.gold or C.text))
    end
    frame.status:SetText('Level '..plan.state.level..' | '..profession.name..' '..plan.state.skill..' / '..plan.state.maxSkill..' | target '..set.target)
    local audit=plan.audit
    frame.summary:SetText((set.mode=='fast' and 'FASTEST ESTIMATE  ' or 'LOWEST GOLD ESTIMATE  ')..ns.Money(plan.cost)..
        (audit.unknown>0 and (' + '..audit.unknown..' unpriced material(s)') or '')..
        (audit.farmed>0 and (' | '..audit.farmed..' farmed material(s)') or '')..
        '\n'..math.ceil(plan.crafts or 0)..' expected crafts / gathers. Training included; resale excluded.'..
        (audit.stale>0 and (' '..audit.stale..' older or undated quotes.') or '')..
        (plan.levelGate and (' Future rank needs level '..plan.levelGate..'.') or ''))
    clear(frame.list)
    if tab=='steps' then
        for i,s in ipairs(plan.steps) do
            line(frame.list,(i==selected and '|cffffd275> ' or '')..i..'. '..stepName(s)..'|r\n'..s.from..' - '..s.to,
                i==selected and C.gold or C.text,function() selected=i; P.Render(false); frame.detail:SetVerticalScroll(0) end,16,i==selected)
        end
        if #plan.steps==0 then line(frame.list,'Target reached, or no usable recipe. Read the details.',C.muted) end
    elseif tab=='shopping' then
        for i,r in ipairs(plan.shopping) do
            line(frame.list,(i==selected and '> ' or '')..ns.Describe.ItemName(r.item)..'\n'..r.buy..' to obtain',
                i==selected and C.gold or C.text,function() selected=i; P.Render(false); frame.detail:SetVerticalScroll(0) end,16,i==selected)
        end
        line(frame.list,'Component crafts: '..#plan.components..'. Expand the relevant route step for their ingredients.',C.muted,nil,15)
    else
        line(frame.list,'ApexProfessions',C.gold,nil,21)
        line(frame.list,'1. Choose a profession and target.\n\n2. Choose Cheapest or Fastest.\n\n3. Pick buying or farming.\n\n4. Follow the steps and refresh after a batch.\n\nCtrl + mouse wheel scales this window. Drag its title to move it.')
    end
    renderDetail()
end

local function searchAH()
    if not plan then return end
    if not ((AuctionFrame and AuctionFrame:IsShown()) or (AuctionHouseFrame and AuctionHouseFrame:IsShown())) then
        ns.Chat('Visit an auctioneer first, then click Search AH.'); return
    end
    local api=Auctionator and Auctionator.API and Auctionator.API.v1
    if not (api and api.MultiSearchExact) then ns.Chat('Auctionator is not available.'); return end
    local terms={}
    for _,r in ipairs(plan.shopping) do
        if r.buy>0 and (not r.entry or r.entry.source=='auctionator') then terms[#terms+1]=ns.Describe.ItemName(r.item) end
    end
    if #terms==0 then ns.Chat('No auction materials in this plan.'); return end
    local ok,err=pcall(api.MultiSearchExact,ADDON,terms)
    if not ok then ns.Chat('Auctionator search failed: '..tostring(err)) end
end

local function create()
    if frame then return end
    profession=ns.CurrentProfession()
    frame=CreateFrame('Frame','ApexProfessionsGuideFrame',UIParent,'BackdropTemplate')
    frame:SetSize(990,780); frame:SetPoint('CENTER'); frame:SetClampedToScreen(true); frame:SetFrameStrata('DIALOG')
    frame:SetBackdrop({bgFile='Interface\\DialogFrame\\UI-DialogBox-Background',edgeFile='Interface\\Tooltips\\UI-Tooltip-Border',tile=true,tileSize=32,edgeSize=16,insets={left=4,right=4,top=4,bottom=4}})
    frame:SetBackdropColor(.055,.047,.035,.98); frame:SetBackdropBorderColor(.54,.40,.19,1)
    -- An independent opaque surface survives UI skin addons that replace Blizzard
    -- backdrop textures. Bright outdoor scenery must never compete with the guide.
    frame.apexBackdrop=frame:CreateTexture(nil,'BACKGROUND',nil,-8)
    frame.apexBackdrop:SetPoint('TOPLEFT',5,-5); frame.apexBackdrop:SetPoint('BOTTOMRIGHT',-5,5)
    frame.apexBackdrop:SetColorTexture(.035,.029,.022,1)
    frame:SetMovable(true); frame:EnableMouse(true); frame:RegisterForDrag('LeftButton')
    frame:SetScript('OnDragStart',function(self) self:StartMoving() end)
    frame:SetScript('OnDragStop',function(self)
        self:StopMovingOrSizing(); local point,_,rel,x,y=self:GetPoint()
        ns.Player.Me().apexWindow={point,rel,x,y,scale=self:GetScale()}
    end)
    local pos=ns.Player.Me().apexWindow
    frame:SetScale(pos and pos.scale or 1.05)
    if pos then frame:ClearAllPoints(); frame:SetPoint(pos[1],UIParent,pos[2],pos[3],pos[4]) end
    frame:EnableMouseWheel(true)
    frame:SetScript('OnMouseWheel',function(self,delta)
        if IsControlKeyDown() then
            self:SetScale(math.max(.75,math.min(1.5,self:GetScale()+delta*.05)))
            local p=ns.Player.Me().apexWindow or {'CENTER','CENTER',0,0}; p.scale=self:GetScale(); ns.Player.Me().apexWindow=p
        end
    end)
    local title=text(frame,25,C.gold); title:SetPoint('TOPLEFT',22,-18); title:SetText('APEX PROFESSIONS')
    frame.status=text(frame,16,C.muted); frame.status:SetPoint('TOPLEFT',22,-51)
    local close=button(frame,'Close',70,29,function() frame:Hide() end);close:SetPoint('TOPRIGHT',-20,-19)
    if ns.theme then close.label:Hide();title:SetText('Apex Professions');ns.theme.Header(frame,title,close,{inset=22,top=12,dividerY=43,titleWidth=420,icon='Trade_BlackSmithing'}) end
    button(frame,'Detailed planner',160,29,function() frame:Hide(); ns.SetProfession(profession); advancedOpen() end):SetPoint('TOPRIGHT',-100,-10)
    button(frame,'Detect skills',130,29,function() P.SyncProgress(true) end):SetPoint('TOPRIGHT',-272,-10)
    local profs={}
    for _,d in ipairs(ns.Professions) do
        if not d.class then profs[#profs+1]={d.key,d.name} end
    end
    frame.prof=UI.Dropdown(frame,200,32,profs,function(key) profession=ns.ProfessionByKey[key]; ns.SetProfession(profession); P.Render(true) end)
    frame.prof:SetPoint('TOPLEFT',22,-82); frame.prof.label:SetFont(UI.FONT,17,'')
    frame.mode=UI.Dropdown(frame,165,32,{{'cheap','Cheapest'},{'fast','Fastest'}},function(v) P.Settings(profession).mode=v; P.Render(true) end)
    frame.mode:SetPoint('TOPLEFT',234,-82); frame.mode.label:SetFont(UI.FONT,17,'')
    frame.source=UI.Dropdown(frame,223,32,{{'buy','Buy materials'},{'mixed','Farm + buy gaps'},{'self','Self-farm only'}},function(v) P.Settings(profession).source=v; P.Render(true) end)
    frame.source:SetPoint('TOPLEFT',411,-82); frame.source.label:SetFont(UI.FONT,17,'')
    for _,drop in ipairs({frame.prof,frame.mode,frame.source}) do
        drop.list:SetFrameStrata('TOOLTIP')
        for _,option in ipairs(drop.options) do option.label:SetFont(UI.FONT,16,'') end
    end
    local goalLabel=text(frame,16); goalLabel:SetPoint('TOPLEFT',650,-90); goalLabel:SetText('Target')
    frame.goal=CreateFrame('EditBox',nil,frame,'InputBoxTemplate'); frame.goal:SetSize(65,30); frame.goal:SetPoint('TOPLEFT',713,-83)
    frame.goal:SetAutoFocus(false); frame.goal:SetNumeric(true); frame.goal:SetMaxLetters(3); frame.goal:SetFont(UI.FONT,18,'')
    local function setGoal() local v=tonumber(frame.goal:GetText()); if v and v>=1 and v<=300 then P.Settings(profession).target=v; P.Render(true) else ns.Chat('Choose a skill target from 1 to 300.') end; frame.goal:ClearFocus() end
    frame.goal:SetScript('OnEnterPressed',setGoal); frame.goal:SetScript('OnEscapePressed',function(self) self:ClearFocus() end)
    button(frame,'Set target',142,32,setGoal):SetPoint('TOPLEFT',794,-82)
    frame.today=CreateFrame('CheckButton',nil,frame,'UICheckButtonTemplate'); frame.today:SetPoint('TOPLEFT',18,-125)
    local today=text(frame,16); today:SetPoint('LEFT',frame.today,'RIGHT',2,0); today:SetText('Today’s AH prices only')
    frame.today:SetScript('OnClick',function(self) P.Settings(profession).today=self:GetChecked() and true or false; P.Render(true) end)
    button(frame,'Refresh',100,29,function() P.Render(true) end):SetPoint('TOPRIGHT',-22,-128)
    button(frame,'Search AH',130,29,searchAH):SetPoint('TOPRIGHT',-134,-128)
    local summaryBG=frame:CreateTexture(nil,'BACKGROUND',nil,-6)
    summaryBG:SetPoint('TOPLEFT',16,-164);summaryBG:SetSize(958,80);summaryBG:SetColorTexture(.095,.078,.053,1)
    frame.summary=text(frame,16,C.gold); frame.summary:SetPoint('TOPLEFT',26,-174); frame.summary:SetWidth(938); frame.summary:SetHeight(64)
    frame.tabs={}
    for i,t in ipairs({{'steps','Guide'},{'shopping','Materials'},{'help','How it works'}}) do
        local b=button(frame,t[2],140,32,function() tab=t[1]; selected=1; P.Render(false); frame.list:SetVerticalScroll(0); frame.detail:SetVerticalScroll(0) end)
        b:SetPoint('TOPLEFT',22+(i-1)*152,-256);frame.tabs[t[1]]=b
    end
    local listLabel=text(frame,14,C.muted);listLabel:SetPoint('TOPLEFT',26,-304);listLabel:SetText('ROUTE / MATERIALS')
    local detailLabel=text(frame,14,C.muted);detailLabel:SetPoint('TOPLEFT',362,-304);detailLabel:SetText('SELECTED STEP')
    for _,r in ipairs({{18,320},{350,622}}) do
        local bg=frame:CreateTexture(nil,'BACKGROUND',nil,-6);bg:SetPoint('TOPLEFT',r[1],-326)
        bg:SetSize(r[2],400);bg:SetColorTexture(.073,.061,.044,1)
    end
    frame.list=panel(frame,310); frame.list:SetPoint('TOPLEFT',22,-330); frame.list:SetSize(280,386)
    frame.detail=panel(frame,610); frame.detail:SetPoint('TOPLEFT',356,-330); frame.detail:SetSize(580,386)
    local foot=text(frame,14,C.muted); foot:SetPoint('BOTTOMLEFT',22,20); foot:SetWidth(944);foot:SetText('Expected quantities; stop at the target skill. Open your profession window to sync known recipes.')
    tinsert(UISpecialFrames,'ApexProfessionsGuideFrame')
    frame:SetScript('OnShow',function() P.Render(true) end)
    frame:Hide()
end

function P.SyncProgress(manual)
    if manual then ns.Player.viewing=nil;plan=nil;selected=1 end
    for _,d in ipairs(ns.Professions) do
        if not d.class then
            local rank=ns.Player.Skill(d,true)
            local set=P.Settings(d)
            if rank and rank>=set.target and rank<300 then
                set.target=math.min(300,(math.floor(rank/75)+1)*75)
            end
        end
    end
    dirty=true;P.Render(true)
    if manual then ns.Chat('Detected current character level and profession skills. Plans start at your actual rank.') end
end
function P.Open()
    if ns.Player.viewing then ns.Player.viewing=nil; dirty=true end
    create(); frame:Show(); P.Render(dirty)
end
function P.Toggle() create(); if frame:IsShown() then frame:Hide() else P.Open() end end
-- Existing minimap and compartment launch the guided interface.
ns.Window.Toggle=P.Toggle
ApexProfessions_OnCompartmentClick=P.Toggle
SLASH_APEXPROFESSIONS1='/aprof'
SLASH_APEXPROFESSIONS2='/apexprof'
SlashCmdList.APEXPROFESSIONS=function(msg)
    msg=(msg or ''):lower():gsub('^%s+',''):gsub('%s+$','')
    if msg=='details' then advancedOpen()
    elseif msg=='minimap' then ns.Minimap.Toggle()
    else
        for _,d in ipairs(ns.Professions) do if msg==d.key then profession=d; ns.SetProfession(d); dirty=true end end
        P.Toggle()
    end
end
local events=CreateFrame('Frame')
local pending=false
events:SetScript('OnEvent',function(_,event)
    dirty=true
    if frame and frame:IsShown() and not pending then
        pending=true
        C_Timer.After(.5,function() pending=false; if frame and frame:IsShown() then P.Render(true) end end)
    end
end)
for _,event in ipairs({'SKILL_LINES_CHANGED','PLAYER_LEVEL_UP','TRADE_SKILL_LIST_UPDATE','NEW_RECIPE_LEARNED','BAG_UPDATE_DELAYED','MERCHANT_SHOW','MERCHANT_UPDATE','AUCTION_HOUSE_CLOSED'}) do pcall(events.RegisterEvent,events,event) end

end)
