local _,A=...
local B=A.Backend
function A.RegisterMover(id,frame,label,container,key,position)
 B.movers[id]={frame=frame,label=label,container=container,key=key,position=position}
end
local overlays={}
local function finish()
 if InCombatLockdown() then return end
 for _,overlay in pairs(overlays) do overlay:Hide() end
 B._unlockModeSessionActive=false
 if B.movePanel then B.movePanel:Hide() end
 B.AutoSaveActiveProfile();B.Apply()
end
function A.OpenMovers()
 if InCombatLockdown() or not A.OwnActive() then return end
 B._unlockModeSessionActive=true
 for id,mover in pairs(B.movers) do
  local o=overlays[id]
  if not o then
   o=CreateFrame("Frame",nil,UIParent,"BackdropTemplate");overlays[id]=o
   B.FrameBorder(o);o:SetBackdropColor(.18,.13,.06,.80);o:SetFrameStrata("DIALOG")
   o.text=B.Text(o,14);o.text:SetPoint("CENTER");o:EnableMouse(true);o:RegisterForDrag("LeftButton")
   o:SetMovable(true);o:SetClampedToScreen(true)
   o:SetScript("OnDragStart",function(self) if not InCombatLockdown() then self:StartMoving() end end)
   o:SetScript("OnDragStop",function(self)
    self:StopMovingOrSizing();if InCombatLockdown() then return end
    local m=self.mover;local x,y=self:GetCenter();local cx,cy=UIParent:GetCenter()
    local p={point="CENTER",relPoint="CENTER",x=x-cx,y=y-cy}
    if m.container then m.container[m.key]=p else for k,v in pairs(p) do m.position[k]=v end end
    B.Position(m.frame,p);B.AutoSaveActiveProfile()
   end)
  end
  o.mover=mover;o.text:SetText(mover.label)
  o:ClearAllPoints();o:SetPoint("CENTER",mover.frame,"CENTER")
  o:SetSize(math.max(80,mover.frame:GetWidth()),math.max(26,mover.frame:GetHeight()));o:SetShown(mover.frame:IsVisible())
 end
 if not B.movePanel then
  local p=CreateFrame("Frame","ApexMovePanel",UIParent,"BackdropTemplate");B.movePanel=p
  p:SetSize(440,90);p:SetPoint("TOP",0,-20);p:SetFrameStrata("FULLSCREEN_DIALOG");B.FrameBorder(p)
  local text=B.Text(p,16);text:SetPoint("TOP",0,-12);text:SetText("Drag the gold panels. Changes save to the active layout.")
  local done=CreateFrame("Button",nil,p,"UIPanelButtonTemplate");done:SetPoint("BOTTOM",0,10);done:SetSize(170,28);done:SetText("Done moving");done:SetScript("OnClick",finish)
 end
 B.movePanel:Show()
end
local e=CreateFrame("Frame");e:RegisterEvent("PLAYER_REGEN_DISABLED")
e:SetScript("OnEvent",function()
 for _,overlay in pairs(overlays) do overlay:StopMovingOrSizing();overlay:Hide() end
 if B.movePanel then B.movePanel:Hide() end
 B._unlockModeSessionActive=false
end)
