local _,A=...
local function text(parent,size)
 local t=parent:CreateFontString(nil,'OVERLAY')
 t:SetFont('Fonts\\FRIZQT__.TTF',size,''); t:SetJustifyH('LEFT'); t:SetJustifyV('TOP')
 t:SetTextColor(.9,.95,.97); return t
end
local function button(parent,label,x,y,width,fn)
 local b=CreateFrame('Button',nil,parent,'UIPanelButtonTemplate')
 b:SetSize(width,28); b:SetPoint('TOPLEFT',x,y); b:SetText(label); b:SetScript('OnClick',fn)
 return b
end
function A.IsGuideVisible()
 return (A.frame and A.frame:IsShown()) or (A.mini and A.mini:IsShown()) or false
end

-- The fishing channel reports line-out duration, not whether a fish has bitten.
-- Never turn a timer, interact target, or nearby player's emote into a bite alert.
function A.FishingLineState()
 local name,_,_,startMS,endMS,_,_,id=UnitChannelInfo('player')
 local localized=C_Spell and C_Spell.GetSpellName(7620) or 'Fishing'
 if name and (id==7620 or id==131474 or name==localized) then
  local now=GetTime()
  A.lastLineAt=now
  local duration=startMS and endMS and math.max(.001,(endMS-startMS)/1000)
  local remaining=endMS and math.max(0,endMS/1000-now)
  return 'LINE OUT',remaining and ('Watch / listen for splash  |  %.0fs left'):format(remaining) or 'Watch / listen for the splash',
   duration and math.min(1,remaining/duration) or 1,.24,.76,.93
 end
 if A.lineNotice and GetTime()<A.lineNotice.untilTime then
  return A.lineNotice.title,A.lineNotice.detail,0,1,.72,.27
 end
 return A.fishingMode and 'READY TO CAST' or 'FISHING STOPPED',
  A.fishingMode and ((ApexFishingDB.fishingKey or 'SPACE')..' to cast; same key at splash to reel') or 'Start fishing to equip your rod and bind your key',0,.35,.88,.7
end

function A.RefreshMini()
 if not A.mini then return end
 local title,detail,value,r,g,b=A.FishingLineState()
 A.mini.line:SetText(title); A.mini.line:SetTextColor(r,g,b)
 A.mini.detail:SetText(detail)
 A.mini.progress:SetValue(value); A.mini.progress:SetStatusBarColor(r,g,b)
 local s=A.state or {}
 A.mini.skills:SetText(('Fishing %d/%d  |  Cooking %d/%d'):format(s.f or 0,s.fcap or 0,s.c or 0,s.ccap or 0))
 A.mini.step:SetText(A.activeStep and A.activeStep.title or 'Open the guide to view your route')
 A.mini.mode:SetText(A.fishingMode and 'Stop fishing' or 'Start fishing')
 A.mini.arrow:SetText(ApexFishingDB.arrow and 'Arrow: On' or 'Arrow: Off')
end

function A.CreateMini()
 if A.mini then return end
 local f=CreateFrame('Frame','ApexFishingMiniFrame',UIParent,'BackdropTemplate')
 A.mini=f; f:SetSize(370,220); f:SetScale(ApexFishingDB.scale or 1)
 f:SetClampedToScreen(true); f:SetMovable(true); f:EnableMouse(true)
 f:SetBackdrop({bgFile='Interface\\Buttons\\WHITE8X8',edgeFile='Interface\\Buttons\\WHITE8X8',edgeSize=1})
 f:SetBackdropColor(.025,.045,.075,.95); f:SetBackdropBorderColor(.12,.5,.51,.9)
 local pos=ApexFishingDB.miniPosition
 f:SetPoint(pos and pos[1] or 'CENTER',UIParent,pos and pos[2] or 'CENTER',pos and pos[3] or -360,pos and pos[4] or 60)
 f:RegisterForDrag('LeftButton')
 f:SetScript('OnDragStart',function() if not ApexFishingDB.locked then f:StartMoving() end end)
 f:SetScript('OnDragStop',function()
  f:StopMovingOrSizing(); local p,_,rp,x,y=f:GetPoint(); ApexFishingDB.miniPosition={p,rp,x,y}
 end)
 local heading=text(f,17); heading:SetPoint('TOPLEFT',12,-10); heading:SetText('Apex Fishing')
 button(f,'Full',264,-5,55,function() A.SetCompact(false) end)
 local close=button(f,'x',326,-5,30,function() ApexFishingDB.hidden=true; f:Hide() end)
 if A.theme then close:SetText('');A.theme.Header(f,heading,close,{compact=true,dividerY=35,titleWidth=235,icon='Trade_Fishing'}) end
 f.line=text(f,23); f.line:SetPoint('TOPLEFT',12,-44); f.line:SetSize(346,28)
 f.detail=text(f,13); f.detail:SetPoint('TOPLEFT',12,-78); f.detail:SetSize(346,32)
 f.progress=CreateFrame('StatusBar',nil,f)
 f.progress:SetPoint('TOPLEFT',12,-111); f.progress:SetSize(346,6); f.progress:SetMinMaxValues(0,1)
 f.progress:SetStatusBarTexture('Interface\\Buttons\\WHITE8X8')
 local bg=f.progress:CreateTexture(nil,'BACKGROUND'); bg:SetAllPoints(); bg:SetColorTexture(.1,.16,.2)
 f.skills=text(f,14); f.skills:SetPoint('TOPLEFT',12,-125); f.skills:SetSize(346,20)
 f.step=text(f,14); f.step:SetPoint('TOPLEFT',12,-148); f.step:SetSize(346,32)
 f.mode=button(f,'Start fishing',12,-185,140,A.ToggleFishing)
 button(f,'Guide',160,-185,88,function() A.SetCompact(false) end)
 f.arrow=button(f,'Arrow',256,-185,102,function()
  ApexFishingDB.arrow=not ApexFishingDB.arrow
  A.UpdateNavigation(A.activeStep,A.state or A.ReadSkills())
  A.RefreshMini()
 end)
 f:SetScript('OnHide',function()
  if not A.switchingView then A.StopFishing(); A.ClearWaypoint() end
 end)
 local elapsed=0
 f:SetScript('OnUpdate',function(_,dt)
  elapsed=elapsed+dt; if elapsed<.1 then return end; elapsed=0
  A.RefreshMini()
 end)
 A.switchingView=true; f:Hide(); A.switchingView=nil
end

function A.SetCompact(on)
 if not A.frame then return end
 A.CreateMini()
 ApexFishingDB.compact=on and true or false; ApexFishingDB.hidden=false
 A.switchingView=true
 if on then
  A.frame:Hide(); A.mini:SetScale(ApexFishingDB.scale or 1); A.mini:Show()
 else A.mini:Hide(); A.frame:Show() end
 A.switchingView=nil
 A.Render(); A.RefreshMini()
end

local events=CreateFrame('Frame')
events:RegisterEvent('UI_ERROR_MESSAGE'); events:RegisterEvent('LOOT_OPENED')
events:RegisterEvent('UNIT_SPELLCAST_CHANNEL_START')
events:SetScript('OnEvent',function(_,event,arg,message)
 if event=='UNIT_SPELLCAST_CHANNEL_START' and arg=='player' then
  local title=A.FishingLineState()
  if title=='LINE OUT' then A.lineNotice=nil end
  return
 end
 if not A.lastLineAt or GetTime()-A.lastLineAt>3 then return end
 local title,detail
 if event=='UI_ERROR_MESSAGE' then
  if message==ERR_FISH_NOT_HOOKED then title,detail='TOO EARLY','No fish hooked. Cast again and wait for the splash.'
  elseif message==ERR_FISH_ESCAPED then title,detail='FISH GOT AWAY','Cast again when you are ready.' end
 elseif event=='LOOT_OPENED' then title,detail='LOOT OPEN','Collect your catch, then cast again.' end
 if title then A.lineNotice={title=title,detail=detail,untilTime=GetTime()+3}; A.RefreshMini() end
end)
