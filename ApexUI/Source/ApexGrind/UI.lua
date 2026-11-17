local _, A = ...
local frame, rows, pauseButton, compactButton, footer, statsTab, spotsTab
local font='Fonts\\FRIZQT__.TTF'
local function label(parent,size)
 local t=parent:CreateFontString(nil,'OVERLAY')
 t:SetFont(font,size,'');t:SetTextColor(.93,.89,.80)
 t:SetJustifyH('LEFT')
 return t
end
local function button(parent,text,width,x,callback)
 local b=CreateFrame('Button',nil,parent,'UIPanelButtonTemplate')
 b:SetSize(width,26);b:SetPoint('BOTTOMLEFT',x,12);b:SetText(text)
 b:SetScript('OnClick',callback)
 return b
end
function A.Place()
 if not frame then return end
 frame:ClearAllPoints()
 local p=A.db.position
 if p then frame:SetPoint(p.point,UIParent,p.relativePoint,p.x,p.y)
 else frame:SetPoint('TOPLEFT',UIParent,'TOPLEFT',32,-220) end
end
function A.Render()
 if not frame then return end
 if A.dragging then return end -- Do not resize/re-anchor controls during a drag.
 frame:SetScale(A.db.scale)
 frame:SetShown(not A.db.hidden)
 if A.db.hidden then return end -- Sampling continues; closed panels need no layout work.
 local s=A.db.session
 local rate,recent,eta,remaining,forecast=A.Metrics(s,A.current)
 local cap=A.current.cap
 local paused=A.IsPaused()
 local showStats=not A.db.compact and A.db.view=='stats'
 frame:SetWidth(338)
 frame:SetHeight(A.db.compact and 168 or (showStats and 380 or 560))
 frame.progress:SetWidth(306)
 frame.title:SetText('Apex Grind'..(paused and '  |cffe8b15aPAUSED|r' or ''))
 frame.pace:SetText(A.Number(rate)..' |cffc6bca7XP / hour|r')
 frame.progress:SetMinMaxValues(0,math.max(1,cap))
 frame.progress:SetValue(A.current.xp)
 local percent=cap>0 and A.current.xp*100/cap or 0
 frame.progressText:SetText(cap>0 and (A.Number(A.current.xp)..' / '..A.Number(cap)..' XP  ('..string.format('%.1f%%',percent)..')') or 'No leveling XP available')
 frame.levelText:SetText('Level '..A.current.level..'  |  Next: '..A.Duration(eta))
 local buffs=A.bonuses or {known=false}
 frame.bonusText:SetText(A.BonusText('food',buffs,GetTime())..'   |   '..A.BonusText('bag',buffs,GetTime()))
 local rest=A.current.rested
 local restText=rest==nil and 'Rested: checking...' or ('Rested: '..A.Number(rest))
 if rest and rest>0 then
  restText=restText..(forecast.depletes and ('  |  ~'..A.Duration(forecast.depletes)..' left') or '  |  learning pace')
 end
 frame.restedText:SetText(restText)
 local values={A.Number(recent)..' XP/h',A.Number(s.xp),A.Duration(s.seconds),A.Number(remaining),rest and A.Number(rest) or '--'}
 for i,row in ipairs(rows) do row.key:SetShown(showStats);row.value:SetShown(showStats);row.value:SetText(values[i]) end
 statsTab:SetShown(not A.db.compact);spotsTab:SetShown(not A.db.compact)
 statsTab:SetEnabled(A.db.view~='stats');spotsTab:SetEnabled(A.db.view~='spots')
 pauseButton:SetText(A.db.paused and 'Resume' or 'Pause')
 pauseButton:SetShown(not A.db.compact)
 compactButton:SetText(A.db.compact and '+' or 'Mini')
 compactButton:ClearAllPoints()
 if A.db.compact then compactButton:SetPoint('TOPRIGHT',frame,'TOPRIGHT',-40,-6);compactButton:SetWidth(28)
 else compactButton:SetPoint('BOTTOMLEFT',frame,'BOTTOMLEFT',118,12);compactButton:SetWidth(72) end
 frame.reset:SetShown(not A.db.compact)
 footer:SetShown(not A.db.compact)
 footer:SetText(s.note and 'Baseline refreshed. See tooltip.' or (paused and 'Tracking paused' or (s.xp==0 and 'Earn XP to measure your pace' or 'Session pace includes travel time')))
 if A.RenderGuide then A.RenderGuide() end
end
function A.BuildUI()
 if frame then return end
 frame=CreateFrame('Frame','ApexGrindFrame',UIParent,'BackdropTemplate')
 A.frame=frame;frame:SetSize(338,282);frame:SetClampedToScreen(true)
 frame:SetFrameStrata('MEDIUM');frame:SetMovable(true);frame:EnableMouse(true)
 frame:SetBackdrop({bgFile='Interface\\DialogFrame\\UI-DialogBox-Background',edgeFile='Interface\\Tooltips\\UI-Tooltip-Border',tile=true,tileSize=32,edgeSize=16,insets={left=4,right=4,top=4,bottom=4}})
 frame:SetBackdropColor(.10,.085,.065,.96);frame:SetBackdropBorderColor(.60,.46,.27,1)
 local titleBar=CreateFrame('Frame',nil,frame)
 -- Reserve the entire top-right control area. The old drag surface covered +.
 titleBar:SetPoint('TOPLEFT',5,-3);titleBar:SetPoint('TOPRIGHT',-84,-3);titleBar:SetHeight(29)
 frame.titleBar=titleBar
 titleBar:EnableMouse(true);titleBar:RegisterForDrag('LeftButton')
 local function startDrag() if not A.db.locked then A.dragging=true;frame:StartMoving() end end
 local function stopDrag()
  frame:StopMovingOrSizing()
  local point,_,relativePoint,x,y=frame:GetPoint()
  A.db.position={point=point,relativePoint=relativePoint,x=x,y=y}
  A.dragging=false
 end
 titleBar:SetScript('OnDragStart',startDrag)
 titleBar:SetScript('OnDragStop',stopDrag)
 -- The shared header also occupies the root frame; allow dragging its free space.
 frame:RegisterForDrag('LeftButton')
 frame:SetScript('OnDragStart',startDrag)
 frame:SetScript('OnDragStop',stopDrag)
 titleBar:SetScript('OnEnter',function(self)
  GameTooltip:SetOwner(self,'ANCHOR_BOTTOM')
  GameTooltip:AddLine('ApexGrind',.89,.74,.47)
  GameTooltip:AddLine('Drag this title to move. /agrind lock to lock.',.93,.89,.80)
  GameTooltip:AddLine('Session: all XP / unpaused online time.',.93,.89,.80)
  GameTooltip:AddLine('Recent: last 5 minutes of unpaused time.',.93,.89,.80)
  GameTooltip:AddLine('AFK pause: '..(A.db.autoAFK and 'on' or 'off')..'. Offline time is excluded.',.93,.89,.80)
  GameTooltip:AddLine('Paused XP is excluded. Hidden panels still track.',.93,.89,.80)
  GameTooltip:AddLine('Next level estimates rested use, then normal pace. Hover the buff line for details.',.93,.89,.80,true)
  if A.db.session.note then GameTooltip:AddLine(A.db.session.note,1,.7,.3) end
  GameTooltip:Show()
 end)
 titleBar:SetScript('OnLeave',function() GameTooltip:Hide() end)
 -- Let the root own the header hitbox too, avoiding a child drag surface
 -- underneath the shared title art. Buttons keep their own input handlers.
 titleBar:EnableMouse(false)
 frame:SetScript('OnEnter',titleBar:GetScript('OnEnter'))
 frame:SetScript('OnLeave',titleBar:GetScript('OnLeave'))
 titleBar:Hide()
 frame.title=label(frame,16);frame.title:SetPoint('TOPLEFT',14,-9)
 local close=CreateFrame('Button',nil,frame,not A.theme and 'UIPanelCloseButton' or nil)
 close:SetSize(28,28);close:SetPoint('TOPRIGHT',-4,-3)
 close:SetScript('OnClick',function() A.db.hidden=true;A.Render() end)
 if A.theme then A.theme.Header(frame,frame.title,close,{compact=true,dividerY=32,titleWidth=235,icon='Ability_Hunter_SniperShot'}) end
 frame.pace=label(frame,21);frame.pace:SetPoint('TOPLEFT',16,-39)
 frame.progress=CreateFrame('StatusBar',nil,frame)
 frame.progress:SetPoint('TOPLEFT',16,-111);frame.progress:SetSize(306,5)
 frame.progress:SetStatusBarTexture('Interface\\TargetingFrame\\UI-StatusBar')
 local _,class=UnitClass('player');local c=RAID_CLASS_COLORS[class] or {r=.8,g=.65,b=.35}
 frame.progress:SetStatusBarColor(c.r,c.g,c.b)
 local bg=frame.progress:CreateTexture(nil,'BACKGROUND');bg:SetAllPoints();bg:SetColorTexture(.18,.16,.13,1)
 frame.progressText=label(frame,13);frame.progressText:SetPoint('TOPLEFT',16,-70)
 frame.levelText=label(frame,12);frame.levelText:SetPoint('TOPLEFT',16,-90)
 frame.bonusText=label(frame,12);frame.bonusText:SetPoint('TOPLEFT',16,-124);frame.bonusText:SetWidth(306)
 frame.restedText=label(frame,12);frame.restedText:SetPoint('TOPLEFT',16,-143);frame.restedText:SetWidth(306);frame.restedText:SetTextColor(.58,.74,.87)
 local hints=CreateFrame('Frame',nil,frame);hints:SetPoint('TOPLEFT',16,-121);hints:SetSize(306,39);hints:EnableMouse(true)
 frame.bonusHints=hints
 hints:SetScript('OnEnter',function(self)
  GameTooltip:SetOwner(self,'ANCHOR_BOTTOM')
  GameTooltip:AddLine('Keep your XP buffs ready',.89,.74,.47)
  GameTooltip:AddLine('Eat cooked XP food and finish eating to gain Well Fed. Use a Cozy Sleeping Bag to build its buff to 3 stacks.',.93,.89,.80,true)
  GameTooltip:AddLine('Muted gold: missing, low stacks or expiring. Green: active. ~ uses the last confirmed timer during restricted reads. Check means status is unavailable.',.93,.89,.80,true)
  GameTooltip:AddLine('The bag buff is separate from your blue rested-XP pool.',.93,.89,.80,true)
  local _,_,eta,_,f=A.Metrics(A.db.session,A.current)
  if f.mode=='learning' then GameTooltip:AddLine('Learning the XP mix. Earn XP after this update to calibrate the forecast.',.93,.89,.80,true)
  else
   GameTooltip:AddLine('Next level: '..A.Duration(eta)..' | Without rested: '..A.Duration(f.noRest),.93,.89,.80,true)
   if f.depletes then GameTooltip:AddLine(f.coversLevel and 'Rested is expected to last through this level.' or ('Rested runs out in about '..A.Duration(f.depletes)..'; remaining XP uses normal pace.'),.58,.74,.87,true) end
  end
  GameTooltip:AddLine('Estimate assumes your measured kill/quest mix continues. Food and bag gains are already in measured XP. Buff expiry or a route change can alter pace.',.93,.89,.80,true)
  GameTooltip:Show()
 end)
 hints:SetScript('OnLeave',function() GameTooltip:Hide() end)
 rows={}
 for i,name in ipairs({'Recent 5 min','Session XP','Time tracked','XP to level','Rested XP left'}) do
  local key=label(frame,14);key:SetPoint('TOPLEFT',16,-205-(i-1)*23);key:SetText(name);key:SetTextColor(.74,.70,.62)
  local value=label(frame,14);value:SetPoint('TOPRIGHT',-16,-205-(i-1)*23);value:SetJustifyH('RIGHT')
  rows[i]={key=key,value=value}
 end
 footer=label(frame,11);footer:SetPoint('BOTTOMLEFT',16,44)
 pauseButton=button(frame,'Pause',90,16,A.TogglePause)
 compactButton=button(frame,'Mini',72,118,function() A.db.compact=not A.db.compact;A.Render() end)
 -- Separate hit area and explicit stacking protect the control from drag capture.
 compactButton:SetFrameLevel(frame:GetFrameLevel()+10)
 compactButton:EnableMouse(true);compactButton:RegisterForClicks('LeftButtonUp')
 frame.compactButton=compactButton
 statsTab=button(frame,'Session stats',149,16,function() A.db.view='stats';A.Render() end)
 statsTab:ClearAllPoints();statsTab:SetPoint('TOPLEFT',16,-166)
 spotsTab=button(frame,'Grinding spots',149,173,function() A.db.view='spots';A.Render() end)
 spotsTab:ClearAllPoints();spotsTab:SetPoint('TOPLEFT',173,-166)
 if A.BuildGuide then A.BuildGuide(frame) end
 local armed=false
 frame.reset=button(frame,'Reset',104,202,function(self)
  if armed then armed=false;A.Reset();self:SetText('Reset')
  else armed=true;self:SetText('Confirm reset');C_Timer.After(4,function() armed=false;self:SetText('Reset') end) end
 end)
 A.Place();A.Render()
 if Minimap then
  local b=CreateFrame('Button','ApexGrindMinimapButton',Minimap)
  b:SetSize(30,30);b:SetPoint('BOTTOMLEFT',Minimap,'BOTTOMLEFT',0,0)
  b:SetNormalTexture('Interface\\Icons\\INV_Misc_Book_11')
  b:SetHighlightTexture('Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight','ADD')
  b:RegisterForClicks('LeftButtonUp','RightButtonUp')
  b:SetScript('OnClick',function(_,which)
   if which=='RightButton' then A.db.compact=not A.db.compact;A.db.hidden=false
   else A.db.hidden=not A.db.hidden end
   A.Render()
  end)
  b:SetScript('OnEnter',function(self)
   GameTooltip:SetOwner(self,'ANCHOR_LEFT');GameTooltip:AddLine('ApexGrind',.89,.74,.47)
   GameTooltip:AddLine('Left-click: show / hide',.93,.89,.80)
   GameTooltip:AddLine('Right-click: compact / full',.93,.89,.80);GameTooltip:Show()
  end)
  b:SetScript('OnLeave',function() GameTooltip:Hide() end)
 end
end
