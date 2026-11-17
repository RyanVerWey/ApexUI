local _,A=...
local pins={}
function A.MapStatus()
 local shown=0
 for _,pin in pairs(pins) do
  if pin:IsShown() then
   shown=shown+1
   print(('Apex map: %s at %.3f, %.3f; scale %.3f'):format(pin.spot.id,pin.mapX,pin.mapY,pin:GetEffectiveScale()))
  end
 end
 print('Apex map visible pins: '..shown)
end
local function project(map,x,y)
 local shown=WorldMapFrame:GetMapID()
 if map==shown and not (OpenMapAPI and OpenMapAPI.IsStitched()) then return x/100,y/100 end
 if not (C_Map.GetWorldPosFromMapPos and CreateVector2D) then return end
 local ok,c,p=pcall(C_Map.GetWorldPosFromMapPos,map,CreateVector2D(x/100,y/100))
 if not ok or not p then return end
 local wx,wy=p:GetXY()
 if OpenMapAPI and OpenMapAPI.IsStitched() then return OpenMapAPI.CanvasFromWorldPos(c,wx,wy) end
 if C_Map.GetMapPosFromWorldPos then
  local good,id,pos=pcall(C_Map.GetMapPosFromWorldPos,c,p,shown)
  if good and id==shown and pos then return pos:GetXY() end
 end
end
function A.RefreshSpotMap()
 for _,pin in pairs(pins) do pin:Hide() end
 if not (A.showSpots and A.state and WorldMapFrame and WorldMapFrame:IsShown()) then return end
 local canvas=WorldMapFrame:GetCanvas()
 if not canvas then return end
 local list=A.AvailableSpots(A.state,A.activeStep and A.activeStep.item)
 local width,height=canvas:GetWidth(),canvas:GetHeight()
 local scale=canvas:GetEffectiveScale()/UIParent:GetEffectiveScale()
 for i,spot in ipairs(list) do
  local x,y=project(spot.map,spot.x,spot.y)
  -- OpenMap's visible stitched world extends beyond its underlying host map.
  -- The scroll container clips these pins; host-map bounds must not hide them.
  local stitched=OpenMapAPI and OpenMapAPI.IsStitched()
  if x and y and (stitched or (x>=0 and x<=1 and y>=0 and y<=1)) then
   local pin=pins[i]
   if not pin then
    pin=CreateFrame('Button',nil,canvas); pins[i]=pin; pin:SetSize(26,26)
    pin.icon=pin:CreateTexture(nil,'OVERLAY'); pin.icon:SetAllPoints(); pin.icon:SetTexture('Interface\\Icons\\INV_Misc_Fish_02')
    pin.ring=pin:CreateTexture(nil,'ARTWORK'); pin.ring:SetPoint('CENTER'); pin.ring:SetTexture('Interface\\AddOns\\ApexFishing\\Ring.tga')
    pin:SetScript('OnClick',function(self)
     local step=A.activeStep
     if step and step.session then
      ApexFishingDB.spotChoice[step.session]=self.spot.id; A.ClearWaypoint(); A.Render(); A.RefreshSpotMap()
     end
    end)
    pin:SetScript('OnEnter',function(self)
     local s=self.spot
     GameTooltip:SetOwner(self,'ANCHOR_RIGHT'); GameTooltip:AddLine(s.label,.3,.9,.8)
     GameTooltip:AddLine(s.observed and 'Confirmed by your own catch at this bank.' or 'Fishing AREA: use an accessible bank inside the ring.',1,1,1,true)
     GameTooltip:AddLine(('Fishing %d+ | Recommended character %d+'):format(s.minSkill or 1,s.level or 1),.8,.85,.9)
     GameTooltip:AddLine('Click to use this water for the current fishing step.',1,.85,.3,true); GameTooltip:Show()
    end)
    pin:SetScript('OnLeave',function() GameTooltip:Hide() end)
   end
   pin.spot=spot; pin.mapX=x; pin.mapY=y; pin:ClearAllPoints(); pin:SetPoint('CENTER',canvas,'TOPLEFT',x*width,-y*height)
   -- Canvas zoom must not shrink the clickable icon to a few pixels.
   pin:SetSize(26/scale,26/scale)
   local art=OpenMapAPI and OpenMapAPI.ArtTopLevel and OpenMapAPI.ArtTopLevel()
   pin:SetFrameLevel(math.max(canvas:GetFrameLevel()+15,(art or 0)+5))
   local x2,y2=project(spot.map,math.min(100,spot.x+(spot.radius or 1)),spot.y)
   local diameter=x2 and math.max(36/scale,math.min(180/scale,math.abs(x2-x)*width*2)) or 50/scale
   pin.ring:SetSize(diameter,diameter)
   local selected=A.activeStep and A.activeStep.spot and A.activeStep.spot.id==spot.id
   pin.ring:SetVertexColor(selected and .2 or 1,selected and 1 or .8,selected and .8 or .3,.85)
   pin.icon:SetAlpha(selected and 1 or .65); pin:Show()
  end
 end
end
function A.ShowSpots()
 A.showSpots=true
 if not A.state then A.Render() end
 if ToggleWorldMap and (not WorldMapFrame or not WorldMapFrame:IsShown()) then ToggleWorldMap() end
 local spot=A.activeStep and A.activeStep.spot
 if spot and WorldMapFrame then
  if OpenMapAPI and OpenMapAPI.IsStitched() and OpenMapAPI.WorldFromMap and OpenMapAPI.ShowWorld then
   local u,v=OpenMapAPI.WorldFromMap(spot.map,spot.x/100,spot.y/100)
   if u then OpenMapAPI.ShowWorld(u,v) end
  else WorldMapFrame:SetMapID(spot.map) end
 end
 A.RefreshSpotMap()
end
local timer=CreateFrame('Frame'); local elapsed=0
timer:SetScript('OnUpdate',function(_,dt)
 elapsed=elapsed+dt; if elapsed<1 then return end; elapsed=0
 if A.IsGuideVisible and A.IsGuideVisible() and A.activeStep and A.state then A.UpdateNavigation(A.activeStep,A.state) end
 A.RefreshSpotMap()
end)
