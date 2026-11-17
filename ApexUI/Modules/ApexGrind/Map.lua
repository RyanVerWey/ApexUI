-- Generated ApexUI module wrapper; original attribution follows.
local _, suite = ...
suite.Suite.Register("grinding", "ApexGrind/Map.lua", function(...)
local CreateFrame = function(...) return suite.Suite.CreateFrame("grinding", ...) end
local _, A = ...
local pins={}
A.grindPins=pins
local function stitched()
 return OpenMapAPI and OpenMapAPI.IsStitched and OpenMapAPI.IsStitched()
end
function A.ProjectGrindPoint(map,x,y)
 if not WorldMapFrame then return end
 local shown=WorldMapFrame:GetMapID()
 if not stitched() and shown==map then return x,y end
 if not (C_Map and C_Map.GetWorldPosFromMapPos and CreateVector2D) then return end
 local ok,continent,world=pcall(C_Map.GetWorldPosFromMapPos,map,CreateVector2D(x,y))
 if not ok or not world then return end
 if stitched() and OpenMapAPI.CanvasFromWorldPos then
  local wx,wy=world:GetXY()
  return OpenMapAPI.CanvasFromWorldPos(continent,wx,wy)
 elseif C_Map.GetMapPosFromWorldPos then
  local good,id,point=pcall(C_Map.GetMapPosFromWorldPos,continent,world,shown)
  if good and id==shown and point then return point:GetXY() end
 end
end
function A.GrindAreaGeometry(s,width,height)
 local x,y=A.ProjectGrindPoint(s.map,s.x,s.y)
 if not x or not y then return end
 local radius=s.radius or .07
 -- Project both axes rather than drawing a screen-sized circle that changes
 -- geographic coverage with zoom. OpenMap may rotate its underlying canvas.
 local dx=s.x+radius<=1 and radius or -radius
 local dy=s.y+radius<=1 and radius or -radius
 local xx,xy=A.ProjectGrindPoint(s.map,s.x+dx,s.y)
 local yx,yy=A.ProjectGrindPoint(s.map,s.x,s.y+dy)
 if not xx or not xy or not yx or not yy then return end
 local rx=math.sqrt(((xx-x)*width)^2+((yx-x)*width)^2)
 local ry=math.sqrt(((xy-y)*height)^2+((yy-y)*height)^2)
 if rx<=0 or ry<=0 then return end
 if not stitched() and (x+rx/width<0 or x-rx/width>1 or y+ry/height<0 or y-ry/height>1) then return end
 return x,y,rx,ry
end
local function makePin(canvas)
 local pin=CreateFrame('Button',nil,canvas)
 pin.area=pin:CreateTexture(nil,'ARTWORK');pin.area:SetPoint('CENTER')
 pin.area:SetTexture('Interface\\AddOns\\ApexUI\\Modules\\ApexGrind\\GrindArea.tga')
 pin.icon=pin:CreateTexture(nil,'OVERLAY');pin.icon:SetAllPoints()
 pin.icon:SetTexture('Interface\\Icons\\INV_Misc_Book_11')
 pin:RegisterForClicks('LeftButtonUp')
 pin:SetScript('OnClick',function(self)
  A.GuideSelection()
  for i,choice in ipairs(A.guideChoices or {}) do
   if choice.spot.id==self.spot.id then A.guideIndex=i;break end
  end
  A.db.hidden=false;A.db.compact=false;A.db.view='spots';A.Render();A.RefreshGrindMap()
 end)
 pin:SetScript('OnEnter',function(self)
  local s=self.spot
  GameTooltip:SetOwner(self,'ANCHOR_RIGHT')
  GameTooltip:AddLine('ApexGrind: '..s.mob,1,.79,.35)
  GameTooltip:AddLine(s.zone..' | Mobs '..s.low..'-'..s.high,.93,.89,.80)
  local material=A.Material(A.db.material)
  if material then GameTooltip:AddLine(material.name..(material.method=='skin' and ' (Skinning)' or ' (corpse loot)'),.93,.89,.80) end
  GameTooltip:AddLine('Shaded circle: approximate recorded spawn cluster, not a safe-path boundary.',.93,.89,.80,true)
  GameTooltip:AddLine(self.selected and 'Gold: selected recommendation.' or 'Blue: matching alternative. Click the book to select.',.93,.89,.80,true)
  GameTooltip:AddLine('Sources: /agrind sources | Hide: /agrind circles',.8,.8,.8,true)
  GameTooltip:Show()
 end)
 pin:SetScript('OnLeave',function() GameTooltip:Hide() end)
 return pin
end
function A.RefreshGrindMap()
 for _,pin in ipairs(pins) do pin:Hide() end
 if not (A.db and A.current and A.db.circles and WorldMapFrame and WorldMapFrame:IsShown()) then return end
 local canvas=WorldMapFrame:GetCanvas()
 if not canvas then return end
 local width,height=canvas:GetWidth(),canvas:GetHeight()
 if width<=0 or height<=0 then return end
 local scale=canvas:GetEffectiveScale()/UIParent:GetEffectiveScale()
 if scale<=0 then return end
 local chosen=A.GuideSelection()
 if not chosen then return end
 local ordered={chosen}
 for _,choice in ipairs(A.guideChoices) do if choice.spot.id~=chosen.spot.id then ordered[#ordered+1]=choice end end
 local used=0
 for _,choice in ipairs(ordered) do
  local s=choice.spot
  local x,y,rx,ry=A.GrindAreaGeometry(s,width,height)
  if x then
   used=used+1
   local pin=pins[used]
   if not pin then pin=makePin(canvas);pins[used]=pin end
   if pin:GetParent()~=canvas then pin:SetParent(canvas) end
   pin.spot=s;pin.selected=s.id==chosen.spot.id
   pin:ClearAllPoints();pin:SetPoint('CENTER',canvas,'TOPLEFT',x*width,-y*height)
   pin:SetSize(20/scale,20/scale)
   -- The artwork's visible edge sits at radius 60 in a 128px texture.
   pin.area:SetSize(rx*128/60,ry*128/60)
   local art=OpenMapAPI and OpenMapAPI.ArtTopLevel and OpenMapAPI.ArtTopLevel() or 0
   pin:SetFrameLevel(math.max(canvas:GetFrameLevel()+16,art+6)+(pin.selected and 2 or 0))
   if pin.selected then pin.area:SetVertexColor(1,.72,.23,.95);pin.icon:SetAlpha(1)
   else pin.area:SetVertexColor(.35,.70,1,.50);pin.icon:SetAlpha(.65) end
   pin:Show()
   -- Limit clutter and keep work bounded on stitched continent views.
   if used>=12 then break end
  end
 end
end
function A.ShowGrindMap()
 local choice=A.GuideSelection()
 if not choice then A.Print('No matching camp to show. Choose another level or loot filter.');return end
 A.db.circles=true
 if ToggleWorldMap and (not WorldMapFrame or not WorldMapFrame:IsShown()) then ToggleWorldMap() end
 if not WorldMapFrame then return end
 local s=choice.spot
 if stitched() and OpenMapAPI.WorldFromMap and OpenMapAPI.ShowWorld then
  local u,v=OpenMapAPI.WorldFromMap(s.map,s.x,s.y)
  if u then OpenMapAPI.ShowWorld(u,v) end
 else WorldMapFrame:SetMapID(s.map) end
 A.RefreshGrindMap()
end
local update=CreateFrame('Frame')
local elapsed=0
update:SetScript('OnUpdate',function(_,dt)
 elapsed=elapsed+dt
 if elapsed>=.2 then elapsed=0;A.RefreshGrindMap() end
end)

end)
