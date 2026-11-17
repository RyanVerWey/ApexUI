local _,A=...
local T={windows={}};A.Theme=T
T.font='Fonts\\FRIZQT__.TTF'
T.gold={.89,.74,.47};T.text={.93,.90,.83};T.muted={.73,.70,.64}
-- Explicit registration keeps module-specific close/drag behavior intact.
-- Full panels use the same title, divider and close-button treatment; compact
-- pickers retain their smaller header lane.
function T.Header(frame,title,close,options)
 local o=options or {};local compact=o.compact
 local inset=o.inset or (compact and 12 or 24)
 local top=o.top or (compact and 9 or 20)
 local iconSize=compact and 20 or 26;local offset=iconSize+9
 if not frame.apexHeaderIcon then frame.apexHeaderIcon=frame:CreateTexture(nil,'ARTWORK') end
 frame.apexHeaderIcon:SetTexture('Interface\\Icons\\'..(o.icon or 'INV_Shield_05'))
 frame.apexHeaderIcon:SetTexCoord(.06,.94,.06,.94);frame.apexHeaderIcon:SetSize(iconSize,iconSize)
 frame.apexHeaderIcon:ClearAllPoints();frame.apexHeaderIcon:SetPoint('TOPLEFT',frame,'TOPLEFT',inset,-top+2)
 title:ClearAllPoints();title:SetPoint('TOPLEFT',frame,'TOPLEFT',inset+offset,-top)
 title:SetFont(T.font,compact and 16 or 22,'OUTLINE');title:SetTextColor(unpack(T.gold))
 title:SetWidth((o.titleWidth or (frame:GetWidth()-inset-52))-offset);title:SetWordWrap(false);title:SetJustifyH('LEFT')
 if not frame.apexHeaderRule then
  local rule=frame:CreateTexture(nil,'ARTWORK');frame.apexHeaderRule=rule
  rule:SetColorTexture(.60,.44,.24,.85);rule:SetHeight(1)
 end
 local rule=frame.apexHeaderRule;rule:ClearAllPoints()
 rule:SetPoint('TOPLEFT',frame,'TOPLEFT',inset,-(o.dividerY or (compact and 29 or 57)))
 rule:SetPoint('TOPRIGHT',frame,'TOPRIGHT',-inset,-(o.dividerY or (compact and 29 or 57)))
 if close then
  close:ClearAllPoints();close:SetPoint('TOPRIGHT',frame,'TOPRIGHT',-8,-(compact and 4 or 12));close:SetSize(28,28)
  close:SetNormalTexture('');close:SetPushedTexture('');close:SetDisabledTexture('')
  close:SetHighlightTexture('Interface\\Buttons\\UI-Common-MouseHilight','ADD')
  if not close.apexLabel then close.apexLabel=close:CreateFontString(nil,'OVERLAY') end
  close.apexLabel:SetFont(T.font,18,'OUTLINE');close.apexLabel:SetAllPoints()
  close.apexLabel:SetText('X');close.apexLabel:SetTextColor(.95,.16,.12)
 end
 frame.apexHeaderTitle=title;frame.apexHeaderClose=close
end
local names={ApexUIFeatures='full',ApexUIOptions='full',ApexProfessionsGuideFrame='full',
 ApexProfessionsFrame='full',ApexNavigatorFrame='full',ApexFishingFrame='full',
 ApexFishingMiniFrame='compact',ApexGrindFrame='tracker',ApexCombatMeter='compact',ApexCombatReport='full'}
function T.Focus(frame)
 if T.focusing then return end
 T.focusing=true
 if names[frame:GetName()]=='full' then
  for other in pairs(T.windows) do
   if other~=frame and other:IsShown() and names[other:GetName()]=='full' then
    local fish=A.Suite and A.Suite.modules.fishing.ns
    if fish and other==fish.frame and fish.fishingMode and fish.SetCompact then fish.SetCompact(true)
    else other:Hide() end
   end
  end
 end
 frame:SetFrameLevel(names[frame:GetName()]=='full' and 200 or 80)
 T.focusing=false
end
function T.Fit(frame)
 if T.fitting then return end
 local w,h=frame:GetWidth(),frame:GetHeight()
 local sw,sh=UIParent:GetWidth(),UIParent:GetHeight()
 if not w or not h or w<=0 or h<=0 or not sw or not sh or sw<=32 or sh<=32 then return end
 local limit=math.min((sw-32)/w,(sh-32)/h)
 if frame:GetScale()>limit then
  T.fitting=true;frame:SetScale(limit);T.fitting=false
 end
end
function T.AvoidTrackers(frame)
 if names[frame:GetName()]~='full' or not frame:IsShown() then return end
 local rootScale=UIParent:GetEffectiveScale()
 if not rootScale or rootScale<=0 then return end
 local function rect(f)
  local x,y=f:GetLeft(),f:GetBottom()
  if type(x)~='number' or type(y)~='number' then return end
  local scale=f:GetEffectiveScale()/rootScale
  return x*scale,y*scale,f:GetWidth()*scale,f:GetHeight()*scale
 end
 local x,y,w,h=rect(frame);if not x then return end
 local obstacles={}
 for other in pairs(T.windows) do
  if other~=frame and names[other:GetName()]~='full' and other:IsShown() then
   local ox,oy,ow,oh=rect(other)
   if ox and y<oy+oh and y+h>oy then obstacles[#obstacles+1]={ox-12,ox+ow+12} end
  end
 end
 table.sort(obstacles,function(a,b) return a[1]<b[1] end)
 local left=16;local best,distance
 local function gap(right)
  if right-left>=w then
   local candidate=math.max(left,math.min(x,right-w));local d=math.abs(candidate-x)
   if not distance or d<distance then best,distance=candidate,d end
  end
 end
 for _,o in ipairs(obstacles) do gap(o[1]);left=math.max(left,o[2]) end
 gap(UIParent:GetWidth()-16)
 -- Move only the open planner, by the smallest distance. If a narrow display
 -- cannot fit both, retain readable text rather than shrinking the whole HUD.
 if best and distance>.5 then
  frame:ClearAllPoints();frame:SetPoint('CENTER',UIParent,'BOTTOMLEFT',best+w/2,y+h/2)
 end
end
function T.Attach(frame)
 if not frame or T.windows[frame] then return end
 local kind=names[frame:GetName()];if not kind then return end
 T.windows[frame]=true
 frame:SetFrameStrata(kind=='full' and 'DIALOG' or 'MEDIUM')
 if frame.SetBackdrop then
  frame:SetBackdrop({edgeFile='Interface\\DialogFrame\\UI-DialogBox-Border',edgeSize=20})
  frame:SetBackdropBorderColor(.58,.46,.29,1)
 end
 local bg=frame:CreateTexture(nil,'BACKGROUND',nil,-8)
 bg:SetPoint('TOPLEFT',5,-5);bg:SetPoint('BOTTOMRIGHT',-5,5);bg:SetColorTexture(.045,.036,.026,1)
 frame.apexSuiteSurface=bg
 -- A shared starting position aligns the full guides. Dragging still works.
 if kind=='full' then frame:ClearAllPoints();frame:SetPoint('CENTER',UIParent,'CENTER',0,32) end
 frame:HookScript('OnShow',function(self)
  T.Fit(self);T.Focus(self);C_Timer.After(0,function() T.AvoidTrackers(self) end)
 end)
 frame:HookScript('OnSizeChanged',function(self) T.Fit(self) end)
 if hooksecurefunc then hooksecurefunc(frame,'SetScale',function() T.Fit(frame) end) end
 T.Fit(frame)
 if frame:IsShown() then T.Focus(frame);C_Timer.After(0,function() T.AvoidTrackers(frame) end) end
end
function T.Queue(frame)
 if frame.GetName and names[frame:GetName()] then C_Timer.After(0,function() T.Attach(frame) end) end
end
