-- Generated ApexUI module wrapper; original attribution follows.
local _, suite = ...
suite.Suite.Register("fishing", "ApexFishing/UI.lua", function(...)
local CreateFrame = function(...) return suite.Suite.CreateFrame("fishing", ...) end
local _, A = ...
local frame, content, scroll, heading, status, barF, barC, doneButton
local active, preview, lastID, fields = nil,nil,nil,{}
local fieldCount=0
local function db() return ApexFishingDB end
local function text(parent,size,r,g,b)
 local t=parent:CreateFontString(nil,'OVERLAY')
 t:SetFont('Fonts\\FRIZQT__.TTF',size,'')
 t:SetTextColor(r or .9,g or .94,b or .97)
 t:SetJustifyH('LEFT'); t:SetJustifyV('TOP')
 return t
end
local function button(label,x,y,w,handler)
 local b=CreateFrame('Button',nil,frame,'UIPanelButtonTemplate')
 b:SetSize(w,28)
 if y<=-490 then b:SetPoint('BOTTOMLEFT',x,610+y-28) else b:SetPoint('TOPLEFT',x,y) end
 b:SetText(label); b:SetScript('OnClick',handler)
 return b
end
local function paragraph(value,size,color,y)
 fieldCount=fieldCount+1
 local t=fields[fieldCount] or text(content,size)
 fields[fieldCount]=t
 t:SetFont('Fonts\\FRIZQT__.TTF',size,'')
 t:SetTextColor(unpack(color or {.88,.92,.96}))
 t:SetPoint('TOPLEFT',0,-y); t:SetWidth(content:GetWidth()); t:SetText(value); t:Show()
 return y+t:GetStringHeight()+14
end
local function gauge(y,r,g,b)
 local gbar=CreateFrame('StatusBar',nil,frame)
 gbar:SetSize(440,22); gbar:SetPoint('TOPLEFT',20,y)
 gbar:SetStatusBarTexture('Interface\\TargetingFrame\\UI-StatusBar')
 gbar:SetStatusBarColor(r,g,b); gbar:SetMinMaxValues(0,300)
 local bg=gbar:CreateTexture(nil,'BACKGROUND'); bg:SetAllPoints(); bg:SetColorTexture(.08,.1,.14)
 gbar.label=text(gbar,14,1,1,1); gbar.label:SetPoint('CENTER'); gbar.label:SetJustifyH('CENTER')
 return gbar
end
function A.Render()
 if not frame then return end
 for _,t in ipairs(fields) do t:Hide(); t:ClearAllPoints() end
 fieldCount=0
 A.inventory=false
 local s=A.ReadSkills()
 local faction=s.faction=='Horde' and 'Horde' or 'Alliance'
 local mode=db().mode or 'combined'
 local key=faction..':'..mode
 db().done[key]=db().done[key] or {}
 local done=db().done[key]
 db().origin=db().origin or A.DetectOrigin()
 local route=A.BuildRoute(faction,mode,db().origin)
 A.route=route; A.state=s; A.done=done
 local pending=A.Pending(route,s,done)
 if A.PrioritizePending then pending=A.PrioritizePending(route,pending,s) end
 local idx=preview or pending[1]
 active=idx and route[idx] or nil
 if active and not preview and A.GuidedStep then active=A.GuidedStep(active,s) end
 local id=active and active.id
 if id~=lastID then A.ClearWaypoint(); scroll:SetVerticalScroll(0); lastID=id end
 heading:SetText('Apex Fishing')
 status:SetText(faction..' / '..db().origin..' / '..(mode=='combined' and 'Fishing + Cooking' or 'Fishing only'))
 barF:SetValue(s.f); barF.label:SetText(('Fishing  %d / %d   |   Goal 300'):format(s.f,s.fcap))
 barC:SetValue(s.c); barC.label:SetText(('Cooking  %d / %d   |   Goal 300'):format(s.c,s.ccap))
 if A.arrowButton then A.arrowButton:SetText(db().arrow and 'Arrow: On' or 'Arrow: Off') end
 if A.IsGuideVisible and A.IsGuideVisible() or frame:IsShown() then A.UpdateNavigation(active,s) end
 A.activeStep=active
 if A.RefreshMini then A.RefreshMini() end
 if A.collapsed then status:SetText(active and active.title or 'Route complete'); return end
 doneButton:Disable()
 local y=8
 if s.faction~='Horde' and s.faction~='Alliance' then
  y=paragraph('Choose your faction in game before following this guide.',20,{1,.75,.35},y)
 elseif not active then
  y=paragraph('ROUTE COMPLETE',22,{.89,.74,.47},y)
  y=paragraph('Your selected professions have reached 300. Keep fishing for the food and materials your roster uses. Use Review to revisit the guide.',18,nil,y)
 else
  y=paragraph((preview and 'REVIEW' or 'CURRENT')..'  /  '..idx..' of '..#route,14,{.89,.74,.47},y)
  y=paragraph(active.title,23,{1,1,1},y)
  local blocked=A.Blocked(active,s)
  if blocked then y=paragraph(blocked,18,{1,.66,.3},y) end
  y=paragraph(active.body,18,nil,y)
  local p=A.points[active.point]
  if p then y=paragraph(p[4]..'  ('..p[2]..', '..p[3]..')',16,{.89,.74,.47},y) end
  if active.kind=='skill' then
   y=paragraph(('Progress: %d / %d base %s'):format(s[active.skill],active.target,active.skill=='f' and 'Fishing' or 'Cooking'),16,nil,y)
  elseif active.kind=='batch' then
   y=paragraph(('In bags: %d / %d | Then cook at your bank'):format(active.count,active.goal),16,{.89,.74,.47},y)
  elseif active.kind=='item' then
   y=paragraph('In bags: '..A.Count(active.item)..' / '..active.target,16,nil,y)
  elseif active.kind=='manual' then
   y=paragraph('Click Done after buying/learning these supplies. Already have them? Done also skips this stop.',15,{.65,.72,.8},y)
   if not blocked then doneButton:Enable() end
  else
   y=paragraph('Advances automatically when your trained skill cap increases.',15,{.65,.72,.8},y)
  end
  local nextIndex=preview and idx+1 or pending[2]
  local nextStep=nextIndex and route[nextIndex]
  if active.following or nextStep then
   y=paragraph('UP NEXT',14,{.89,.74,.47},y+12)
   y=paragraph(active.following or nextStep.title,20,{.9,.95,1},y)
  end
 end
 content:SetHeight(math.max(y,scroll:GetHeight()))
end
function A.SyncProgress(manual)
 if manual then preview=nil end
 A.Render()
end
local function resizeFont(delta)
 db().scale=math.max(.7,math.min(1.5,(db().scale or 1)+delta)); frame:SetScale(db().scale)
end
local function create()
 ApexFishingDB=ApexFishingDB or {}
 local d=db(); d.done=d.done or {}; d.history=d.history or {}; d.mode=d.mode or 'combined'
 if d.arrow==nil then d.arrow=true end
 frame=CreateFrame('Frame','ApexFishingFrame',UIParent,'BackdropTemplate')
 frame:SetSize(d.width or 480,d.height or 610); frame:SetScale(d.scale or 1)
 frame:SetResizable(true)
 if frame.SetResizeBounds then frame:SetResizeBounds(480,610,800,1000) end
 frame:SetBackdrop({bgFile='Interface\\Buttons\\WHITE8X8',edgeFile='Interface\\Buttons\\WHITE8X8',edgeSize=2})
 frame:SetBackdropColor(.025,.045,.075,.97); frame:SetBackdropBorderColor(.12,.5,.51,.9)
 frame:SetPoint('CENTER',UIParent,'CENTER',d.x or -360,d.y or 60)
 frame:SetMovable(true); frame:SetClampedToScreen(true); frame:EnableMouse(true)
 frame:RegisterForDrag('LeftButton')
 frame:SetScript('OnDragStart',function(self) if not d.locked then self:StartMoving() end end)
 frame:SetScript('OnDragStop',function(self)
  self:StopMovingOrSizing()
  local x,y=self:GetCenter(); local ux,uy=UIParent:GetCenter()
  d.x=x-ux*UIParent:GetEffectiveScale()/self:GetEffectiveScale()
  d.y=y-uy*UIParent:GetEffectiveScale()/self:GetEffectiveScale()
  self:ClearAllPoints(); self:SetPoint('CENTER',UIParent,'CENTER',d.x,d.y)
 end)
 heading=text(frame,24); heading:SetPoint('TOPLEFT',20,-18)
 status=text(frame,14,.65,.74,.82); status:SetPoint('TOPLEFT',20,-51); status:SetWidth(430)
 local close=button('x',438,-12,28,function() d.hidden=true; frame:Hide(); A.ClearWaypoint() end)
 if A.theme then close:SetText('');A.theme.Header(frame,heading,close,{inset=20,top=12,dividerY=43,titleWidth=350,icon='Trade_Fishing'}) end
 local collapse
 collapse=button('-',400,-12,28,function() A.SetCompact(true) end)
 barF=gauge(-78,.07,.5,.6); barC=gauge(-105,.65,.34,.12)
 button('Fishing + Cooking',20,-139,210,function() d.mode='combined'; preview=nil; A.Render() end)
 button('Fishing only',240,-139,220,function() d.mode='fishing'; preview=nil; A.Render() end)
 scroll=CreateFrame('ScrollFrame',nil,frame,'UIPanelScrollFrameTemplate')
 scroll:SetPoint('TOPLEFT',20,-181); scroll:SetSize(418,295)
 content=CreateFrame('Frame',nil,scroll); content:SetWidth(418); content:SetHeight(295); scroll:SetScrollChild(content)
 local arrowButton
 arrowButton=button(d.arrow and 'Arrow: On' or 'Arrow: Off',20,-490,130,function()
  d.arrow=not d.arrow; arrowButton:SetText(d.arrow and 'Arrow: On' or 'Arrow: Off'); A.UpdateNavigation(active,A.state)
 end)
 A.arrowButton=arrowButton
 doneButton=button('Done',160,-490,90,function()
  if active and active.kind=='manual' and not A.Blocked(active,A.state) then
   local key=A.state.faction..':'..d.mode
   d.history[#d.history+1]={key=key,id=active.id}
   A.done[active.id]=true; preview=nil; A.Render()
  end
 end)
 button('Undo',260,-490,80,function()
  local h=table.remove(d.history)
  if h and d.done[h.key] then d.done[h.key][h.id]=nil end
  preview=nil; A.Render()
 end)
 button('A-',350,-490,50,function() resizeFont(-.1) end)
 button('A+',410,-490,50,function() resizeFont(.1) end)
 button('<',20,-530,36,function() preview=math.max(1,(preview or 2)-1); A.Render() end)
 button('Review >',62,-530,98,function() preview=math.min(#A.route,(preview or 0)+1); A.Render() end)
 button('Current step',170,-530,130,function() preview=nil; A.Render() end)
 button('Fish in bags',310,-530,150,function()
  for _,t in ipairs(fields) do t:Hide(); t:ClearAllPoints() end; fieldCount=0
  local y=paragraph('YOUR CATCH',22,{.89,.74,.47},8)
  for _,fish in ipairs(A.fish) do y=paragraph(fish[2]..': '..A.Count(fish[1]),18,nil,y) end
  y=paragraph('Keep raw fish until the related Cooking milestone is complete. Click Current step to return.',16,nil,y)
  content:SetHeight(y); scroll:SetVerticalScroll(0); A.inventory=true
 end)
 A.modeButton=button('Start fishing',20,-570,140,A.ToggleFishing)
 button('Fishing spots',170,-570,140,function() if A.ShowSpots then A.ShowSpots() end end)
 button('Nearest water',320,-570,140,function() if A.ReplanSpots then A.ReplanSpots() end end)
 local grip=CreateFrame('Button',nil,frame)
 grip:SetSize(16,16); grip:SetPoint('BOTTOMRIGHT',-2,2)
 local mark=text(grip,16,.3,.9,.8); mark:SetAllPoints(); mark:SetText('+')
 grip:SetScript('OnMouseDown',function() if not d.locked then frame:StartSizing('BOTTOMRIGHT') end end)
 grip:SetScript('OnMouseUp',function() frame:StopMovingOrSizing(); d.width=frame:GetWidth(); d.height=frame:GetHeight() end)
 frame:SetScript('OnSizeChanged',function(self,w,h)
  if not scroll or A.collapsed then return end
  scroll:SetSize(w-62,h-315); content:SetWidth(w-62)
  A.Render()
 end)
 frame:SetScript('OnHide',function()
  if not A.switchingView then A.StopFishing(); A.ClearWaypoint() end
 end)
 A.frame=frame
 A.InitControls()
 A.Render()
 if d.hidden then frame:Hide() elseif d.compact then A.SetCompact(true) end
end
local events=CreateFrame('Frame')
events:RegisterEvent('ADDON_LOADED')
events:SetScript('OnEvent',function(_,event,name)
 if event=='ADDON_LOADED' then
  if name~='ApexFishing' then return end
  create()
  for _,e in ipairs({'SKILL_LINES_CHANGED','PLAYER_LEVEL_UP','BAG_UPDATE_DELAYED','QUEST_LOG_UPDATE','PLAYER_ENTERING_WORLD'}) do events:RegisterEvent(e) end
  print('|cffe3bd78Apex Fishing|r loaded. /apexfish opens your guide. Drag the title to move; A+ enlarges it.')
 elseif frame and A.IsGuideVisible() and not A.inventory then A.Render() end
end)
SLASH_APEXFISHING1='/apexfish'
SLASH_APEXFISHING2='/afish'
SlashCmdList.APEXFISHING=function(message)
 if not frame then return end
 local cmd=(message or ''):lower():match('^%s*(.-)%s*$')
 if cmd=='mini' then A.SetCompact(true); return end
 if cmd=='full' then A.SetCompact(false); return end
 if cmd=='spots' then A.ShowSpots(); return end
 if cmd=='mapstatus' then A.MapStatus(); return end
 if cmd=='nearby' then A.ReplanSpots(); return end
 if cmd=='fish' then A.ToggleFishing(); return end
 if cmd=='restore' then A.StopFishing(); return end
 if cmd=='detect' then db().origin=A.DetectOrigin(); preview=nil; if A.ReplanSpots then A.ReplanSpots() else A.Render() end; return end
 local key=cmd:match('^key (.+)$')
 if key then
  if A.fishingMode then print('Stop fishing mode before changing its key.'); return end
  db().fishingKey=key:upper(); print('Apex Fishing key: '..db().fishingKey); return
 end
 if cmd=='lock' then db().locked=not db().locked; print('Apex Fishing: frame '..(db().locked and 'locked' or 'unlocked')); return end
 if cmd=='home' then
  db().x=nil; db().y=nil; db().scale=1
  db().miniPosition=nil
  if A.mini then A.mini:ClearAllPoints(); A.mini:SetPoint('CENTER',UIParent,'CENTER',-360,60) end
  frame:SetScale(1); frame:ClearAllPoints(); frame:SetPoint('CENTER',UIParent,'CENTER',-360,60)
 elseif cmd=='help' then
  print('Apex Fishing: /apexfish toggles; mini / full change views; home restores position; lock toggles dragging. Start fishing opens the compact view. Done confirms shopping; Undo reverses it. Skills advance automatically.'); return
 elseif cmd=='' and A.IsGuideVisible() then
  db().hidden=true; frame:Hide(); if A.mini then A.mini:Hide() end; A.ClearWaypoint(); return
 end
 db().hidden=false; preview=nil; A.SetCompact(db().compact or false)
end

end)
