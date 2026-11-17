-- Generated ApexUI module wrapper; original attribution follows.
local _, suite = ...
suite.Suite.Register("navigation", "ApexNavigator/UI.lua", function(...)
local CreateFrame = function(...) return suite.Suite.CreateFrame("navigation", ...) end
local _,A=...
local function text(parent,size,color)
 local t=parent:CreateFontString(nil,'OVERLAY')
 t:SetFont('Fonts\\FRIZQT__.TTF',size,'')
 t:SetJustifyH('LEFT'); t:SetJustifyV('TOP'); t:SetTextColor(unpack(color or { .9,.94,.96 }))
 return t
end
local function button(parent,label,w,x,y,callback)
 local b=CreateFrame('Button',nil,parent,'UIPanelButtonTemplate')
 b:SetSize(w,30); b:SetPoint('TOPLEFT',x,y); b:SetText(label)
 b:SetScript('OnClick',callback); return b
end
local function clock(seconds)
 return math.max(1,math.ceil((seconds or 0)/60))..' min'
end

function A.CreateUI()
 if A.frame or not A.db then return end
 local f=CreateFrame('Frame','ApexNavigatorFrame',UIParent,'BackdropTemplate')
 A.frame=f; f:SetSize(460,645); f:SetClampedToScreen(true)
 f:SetBackdrop({bgFile='Interface\\Buttons\\WHITE8X8',edgeFile='Interface\\Buttons\\WHITE8X8',edgeSize=1})
 f:SetBackdropColor(.035,.055,.075,.96); f:SetBackdropBorderColor(.16,.48,.48,.9)
 f:SetFrameStrata('MEDIUM'); f:EnableMouse(true); f:SetMovable(true)
 f:SetScale(A.db.scale or 1)
 local pos=A.db.position
 if pos then f:SetPoint(pos[1],UIParent,pos[2],pos[3],pos[4]) else f:SetPoint('CENTER',UIParent,'CENTER',240,100) end
 local drag=CreateFrame('Frame',nil,f); drag:SetPoint('TOPLEFT'); drag:SetPoint('TOPRIGHT'); drag:SetHeight(42)
 drag:EnableMouse(true); drag:RegisterForDrag('LeftButton')
 drag:SetScript('OnDragStart',function() f:StartMoving() end)
 drag:SetScript('OnDragStop',function()
  f:StopMovingOrSizing(); local p,_,rp,x,y=f:GetPoint(); A.db.position={p,rp,x,y}
 end)
 local title=text(drag,22,{.89,.74,.47}); title:SetPoint('TOPLEFT',16,-10); title:SetText('APEX NAVIGATOR')
 local close=CreateFrame('Button',nil,f,'UIPanelCloseButton'); close:SetPoint('TOPRIGHT',-2,-2)
 close:SetScript('OnClick',function() f:Hide() end)
 if A.theme then title:SetText('Apex Navigation');A.theme.Header(f,title,close,{inset=16,top=12,dividerY=42,icon='INV_Misc_Map_01'}) end
 A.subtitle=text(f,16); A.subtitle:SetPoint('TOPLEFT',16,-49); A.subtitle:SetSize(428,44)
 A.pinButton=button(f,'Pin destination',140,16,-99,function()
  if A.armed then A.armed=false; A.Refresh() else A.ArmPin() end
 end)
 A.flightButton=button(f,'Flights: OFF',140,160,-99,function() A.db.flights=not A.db.flights; A.Route() end)
 button(f,'Replan',140,304,-99,function() A.Route() end)
 local zoneLabel=text(f,14); zoneLabel:SetPoint('TOPLEFT',16,-142); zoneLabel:SetText('Destination zone')
 A.coordinateMap=A.ResolveCoordinateZone('')
 A.zonePicker=CreateFrame('DropdownButton',nil,f,'WowStyle1DropdownTemplate')
 A.zonePicker:SetPoint('TOPLEFT',16,-164); A.zonePicker:SetWidth(282)
 A.zonePicker:SetDefaultText('Select a zone')
 A.zonePicker:SetupMenu(function(_,root)
  root:SetScrollMode(280)
  for _,zone in ipairs(A.CoordinateZones()) do
   local id=zone.id
   root:CreateRadio(zone.name,function() return A.coordinateMap==id end,function()
    A.coordinateMap=id
    A.CoordinateMessage('Enter coordinates for '..zone.name..'.',true)
   end)
  end
 end)
 button(f,'Current zone',140,304,-160,function()
  local map,err=A.ResolveCoordinateZone('')
  if map then A.coordinateMap=map; A.zonePicker:GenerateMenu(); A.CoordinateMessage('Using your current zone.',true)
  else A.CoordinateMessage(err) end
 end)
 local coordLabel=text(f,14); coordLabel:SetPoint('TOPLEFT',16,-200); coordLabel:SetText('Coordinates (X, Y)')
 A.coordinateInput=CreateFrame('EditBox',nil,f,'InputBoxTemplate')
 A.coordinateInput:SetPoint('TOPLEFT',22,-220); A.coordinateInput:SetSize(270,30)
 A.coordinateInput:SetAutoFocus(false); A.coordinateInput:SetMaxLetters(32)
 A.coordinateInput:SetFont('Fonts\\FRIZQT__.TTF',16,'')
 local function go()
  if not A.coordinateMap then A.CoordinateMessage('Select a destination zone first.');return end
  if A.NavigateCoordinates(A.coordinateMap,A.coordinateInput:GetText()) then A.coordinateInput:ClearFocus() end
 end
 A.coordinateInput:SetScript('OnEnterPressed',go)
 A.coordinateInput:SetScript('OnEscapePressed',function(self) self:ClearFocus() end)
 A.coordinateGo=button(f,'Go to coordinates',140,304,-220,go)
 A.coordinateFeedback=text(f,12,{.65,.74,.79}); A.coordinateFeedback:SetPoint('TOPLEFT',16,-256); A.coordinateFeedback:SetSize(428,30)
 A.coordinateFeedback:SetText('Use 0-100 coordinates, for example 42.5, 67.8.')
 A.info=text(f,14,{.65,.74,.79}); A.info:SetPoint('TOPLEFT',16,-293); A.info:SetSize(428,48)
 local scroll=CreateFrame('ScrollFrame',nil,f,'UIPanelScrollFrameTemplate')
 scroll:SetPoint('TOPLEFT',16,-348); scroll:SetPoint('BOTTOMRIGHT',-34,94)
 local child=CreateFrame('Frame',nil,scroll); child:SetSize(402,1); scroll:SetScrollChild(child)
 A.itinerary=text(child,16); A.itinerary:SetPoint('TOPLEFT'); A.itinerary:SetWidth(400)
 A.itinerary:SetSpacing(5); A.scrollChild=child
 A.nextButton=button(f,'Next step',140,16,-562,function() A.Next() end)
 button(f,'Stop',90,160,-562,function() A.db.destination=nil; A.Route() end)
 button(f,'A-',60,256,-562,function() A.db.scale=math.max(.8,(A.db.scale or 1)-.1); f:SetScale(A.db.scale) end)
 button(f,'A+',60,322,-562,function() A.db.scale=math.min(1.5,(A.db.scale or 1)+.1); f:SetScale(A.db.scale) end)
 local foot=text(f,12,{.6,.69,.74}); foot:SetPoint('BOTTOMLEFT',16,13); foot:SetSize(428,32)
 foot:SetText('Boats, tram and zeppelins included. Local arrows are bearings; follow roads and watch terrain / hostile areas.')
 f:SetScript('OnHide',function() A.armed=false; A.coordinateInput:ClearFocus() end)
 f:SetScript('OnShow',function() A.Refresh(); A.Arrow() end)
 f:Hide(); A.Refresh()
end

function A.Refresh()
 if not A.frame then return end
 A.subtitle:SetText(A.db.destination and A.db.destination.label or 'Where would you like to go?')
 A.pinButton:SetText(A.armed and 'Cancel pin' or 'Pin destination')
 A.flightButton:SetText(A.db.flights and 'Flights: ON' or 'Flights: OFF')
 local count=0; for _ in pairs(A.db.flightOffers or {}) do count=count+1 end
 local info=A.eta and ('Estimated total: '..clock(A.eta)..' | Walking '..A.db.speed..' yd/s\n') or ''
 A.info:SetText(info..(A.db.flights and (count..' recorded flight offers. Visit flight masters to learn more.') or 'Flights excluded. Estimates include assumed transport waits.'))
 local lines={}; local leg=A.CurrentLeg()
 if A.route and leg then
  for i=A.step,#A.route do
   local e=A.route[i]
   local prefix=(i==A.step and '|cffe3bd78NOW' or '|cffb7c7d1'..(i-A.step+1))
   lines[#lines+1]=prefix..'  '..string.upper(e.kind)..' | '..clock(e.seconds)..'|r\n'..e.text
   if i==A.step and A.IsRide(e) then
    lines[#lines+1]=A.riding and '|cffffd27fStay aboard until arrival, then exit. The route advances nearby.|r' or '|cffffd27fArrow points to boarding. Click Boarded once riding.|r'
   end
  end
 else lines[1]=A.status or 'Click Pin destination, then click anywhere on a zone map.\n\nAlready placed a standard map pin? Type /apexnav waypoint to route to it.\n\nTomTom provides the next-leg arrow.\n\nThis first version plans through mapped zone passages and transport stops; it cannot detect obstacles.' end
 if not TomTom then lines[#lines+1]='|cffffd27fEnable TomTom for the direction arrow.|r' end
 A.itinerary:SetText(table.concat(lines,'\n\n')); A.scrollChild:SetHeight(math.max(1,A.itinerary:GetStringHeight()+10))
 A.nextButton:SetText(A.IsRide(leg) and (A.riding and 'Arrived' or 'Boarded / entered') or 'Next step')
 A.nextButton:SetEnabled(leg~=nil)
end

function A.CreateMinimap()
 if A.suiteManaged then return end
 if A.minimap or not Minimap then return end
 local b=CreateFrame('Button','ApexNavigatorMinimapButton',Minimap)
 A.minimap=b; b:SetSize(32,32); b:SetPoint('BOTTOMRIGHT',Minimap,'BOTTOMRIGHT',2,-2)
 b:SetNormalTexture('Interface\\Icons\\INV_Misc_Map_01')
 b:SetHighlightTexture('Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight','ADD')
 b:RegisterForClicks('LeftButtonUp','RightButtonUp')
 b:SetScript('OnClick',function(_,key)
  if key=='RightButton' then A.ArmPin() else A.frame:SetShown(not A.frame:IsShown()) end
 end)
 b:SetScript('OnEnter',function(self)
  GameTooltip:SetOwner(self,'ANCHOR_LEFT'); GameTooltip:AddLine('Apex Navigator',.3,.9,.8)
  GameTooltip:AddLine('Left-click: open / close route',1,1,1)
  GameTooltip:AddLine('Right-click: choose a map destination',1,1,1); GameTooltip:Show()
 end)
 b:SetScript('OnLeave',function() GameTooltip:Hide() end)
end

end)
