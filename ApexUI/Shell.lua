local _,A=...
local B=A.Backend
local S={};A.Shell=S
function S.CollectMapButtons()
 if not S.map or InCombatLockdown() then return end
 if not S.addonPanel then
  local panel=CreateFrame("Frame","ApexMinimapAddons",UIParent,"BackdropTemplate");S.addonPanel=panel
  B.FrameBorder(panel);panel:SetFrameStrata("DIALOG");panel:SetSize(170,90)
  panel:SetPoint("BOTTOMRIGHT",UIParent,"BOTTOMRIGHT",-14,150);panel:Hide()
  local title=B.Text(panel,14);title:SetPoint("TOPLEFT",10,-8);title:SetText("Addon shortcuts")
  local close=CreateFrame("Button",nil,panel);close:SetSize(24,24);close:SetPoint("TOPRIGHT",-3,-3)
  close.text=B.Text(close,16);close.text:SetPoint("CENTER");close.text:SetText("X");close.text:SetTextColor(.95,.16,.12)
  close:SetScript("OnClick",function() panel:Hide() end)
  if A.Theme then
   title:SetText("Addons");close.text:Hide()
   A.Theme.Header(panel,title,close,{compact=true,inset=10,top=8,dividerY=30,titleWidth=130,icon="INV_Misc_Gear_01"})
  end
  UISpecialFrames[#UISpecialFrames+1]="ApexMinimapAddons"
 end
 local lib=LibStub and LibStub("LibDBIcon-1.0",true)
 local buttons={}
 if lib and lib.GetButtonList and lib.GetMinimapButton then
  for _,name in ipairs(lib:GetButtonList()) do
   local button=lib:GetMinimapButton(name)
   if button and button:IsShown() then buttons[#buttons+1]=button end
  end
 end
 S.mapButtons=S.mapButtons or {}
 for _,button in ipairs(buttons) do S.mapButtons[button]=true end
 -- These installed addons use their own launcher rather than LibDBIcon.
 for _,name in ipairs({"HunterPetJournalMinimapButton","OpenMapMinimapButton","GearQuestMinimapButton"}) do
  local button=_G[name];if button and button:IsShown() then S.mapButtons[button]=true end
 end
 local ordered={};for button in pairs(S.mapButtons) do ordered[#ordered+1]=button end
 table.sort(ordered,function(a,b) return (a:GetName() or "")<(b:GetName() or "") end)
 for i,button in ipairs(ordered) do
  if button.SetFixedFrameStrata then button:SetFixedFrameStrata(false) end
  if button.SetFixedFrameLevel then button:SetFixedFrameLevel(false) end
  if button.fadeOut then button.fadeOut:Stop() end
  button.showOnMouseover=false
  button:RegisterForDrag() -- Collected shortcuts stay in the picker grid.
  button:SetParent(S.addonPanel);button:SetScale(1);button:SetAlpha(1);button:SetFrameStrata("DIALOG");button:SetFrameLevel(S.addonPanel:GetFrameLevel()+2);button:ClearAllPoints()
  button:SetPoint("TOPLEFT",S.addonPanel,"TOPLEFT",7+((i-1)%4)*38,-34-math.floor((i-1)/4)*38)
 end
 S.addonPanel:SetHeight(math.max(1,math.ceil(#ordered/4))*38+42)
end
function S.ToggleMapButtons()
 S.CollectMapButtons()
 if S.addonPanel then S.addonPanel:SetShown(not S.addonPanel:IsShown()) end
end
local function status()
 if not S.status then return end
 local cur,max=0,0
 for slot=1,19 do local a,b=GetInventoryItemDurability(slot);if a and b then cur=cur+a;max=max+b end end
 local coords="--, --"
 local map=C_Map.GetBestMapForUnit("player");local p=map and C_Map.GetPlayerMapPosition(map,"player")
 if p then local x,y=p:GetXY();coords=string.format("%.0f, %.0f",x*100,y*100) end
 local money=GetMoney()
 local t=S.status.fields
 t.armor:SetFormattedText("%d%%",max>0 and cur/max*100 or 100)
 t.coords:SetText(coords)
 t.money:SetFormattedText("|cffffd05b%dg|r |cffd7d7df%ds|r |cffcb8a54%dc|r",math.floor(money/10000),math.floor(money/100)%100,money%100)
 t.clock:SetText(date("%I:%M %p"):gsub("^0",""))
end
function S.LayoutStatus(bounds)
 if not S.status then
  local f=CreateFrame("Frame","ApexStatusPanel",UIParent,"BackdropTemplate");S.status=f
  B.FrameBorder(f);f.fields={}
  for _,key in ipairs({"armor","coords","money","clock"}) do f.fields[key]=B.Text(f,13) end
  f.anvil=f:CreateTexture(nil,"ARTWORK");f.anvil:SetSize(18,18)
  f.anvil:SetTexture("Interface\\Icons\\Trade_BlackSmithing");f.anvil:SetTexCoord(.08,.92,.08,.92)
  f.coordinateIcon=CreateFrame("Frame",nil,f);f.coordinateIcon:SetSize(16,16);f.coordinateIcon:EnableMouse(false)
  -- A small gold crosshair is legible at HUD scale without an external font.
  for _,r in ipairs({{0,0,12,2},{0,0,2,12},{-5,0,2,6},{5,0,2,6},{0,-5,6,2},{0,5,6,2}}) do
   local line=f.coordinateIcon:CreateTexture(nil,"ARTWORK");line:SetColorTexture(.93,.76,.39,1)
   line:SetSize(r[3],r[4]);line:SetPoint("CENTER",r[1],r[2])
  end
  f.elapsed=0;f:SetScript("OnUpdate",function(self,elapsed)
   self.elapsed=self.elapsed+elapsed;if self.elapsed>=1 then self.elapsed=0;status() end
  end)
  f:EnableMouse(true)
  f:SetScript("OnEnter",function(self)
   GameTooltip:SetOwner(self,"ANCHOR_TOP");GameTooltip:AddLine(GetZoneText(),.9,.74,.47)
   GameTooltip:AddLine("Anvil: armor durability  |  Crosshair: coordinates  |  Currency  |  Local time",.9,.9,.9,true);GameTooltip:Show()
  end)
  f:SetScript("OnLeave",function() GameTooltip:Hide() end)
 end
 local f=S.status;f:ClearAllPoints();f:SetPoint("BOTTOMLEFT",UIParent,"BOTTOMLEFT",bounds.left+4,bounds.bottom)
 f:SetSize(bounds.width-8,24)
 local widths={.20,.24,.33,.23};local offset=6
 for i,key in ipairs({"armor","coords","money","clock"}) do
  local icon=key=="armor" and f.anvil or key=="coords" and f.coordinateIcon
  local inset=icon and 23 or 0
  if icon then icon:ClearAllPoints();icon:SetPoint("LEFT",f,"LEFT",offset,0) end
  local text=f.fields[key];text:ClearAllPoints();text:SetPoint("LEFT",f,"LEFT",offset+inset,0)
  text:SetWidth((f:GetWidth()-12)*widths[i]-inset);text:SetJustifyH(i==4 and "RIGHT" or "LEFT")
  text:SetFont(A.FONT,key=="clock" and 15 or 12,"OUTLINE");offset=offset+(f:GetWidth()-12)*widths[i]
 end
 f:Show();status()
end
function S.Apply()
 if InCombatLockdown() or not A.OwnActive() or B.conflict then return end
 local profile=A.Active();local mm=profile.addons.ApexMinimap.minimap
 if Minimap then
  if not S.map then
   S.map=CreateFrame("Frame","ApexMinimapFrame",UIParent,"BackdropTemplate");B.FrameBorder(S.map)
   Minimap:SetParent(S.map)
   S.map:EnableMouseWheel(true);S.map:SetScript("OnMouseWheel",function(_,delta) Minimap:SetZoom(math.max(0,math.min(Minimap:GetZoomLevels()-1,Minimap:GetZoom()+delta))) end)
   S.map:SetScript("OnMouseUp",function(_,button) if button=="MiddleButton" then ToggleWorldMap() end end)
   for _,name in ipairs({"MinimapBorder","MinimapBorderTop","MinimapBackdrop","MinimapNorthTag"}) do if _G[name] then _G[name]:Hide() end end
   S.map.location=B.Text(S.map,14);S.map.location:SetPoint("TOP",0,-4)
  end
  S.map:SetSize(mm.mapSize or 374,mm.mapSize or 374);B.Position(S.map,mm.position)
  if A.PositionUtilityMap then A.PositionUtilityMap() end
  Minimap:SetScale(1);Minimap:ClearAllPoints();Minimap:SetPoint("CENTER",S.map,"CENTER",0,0);Minimap:SetSize((mm.mapSize or 374)-8,(mm.mapSize or 374)-8)
  Minimap:SetMaskTexture("Interface\\Buttons\\WHITE8X8")
  S.map.location:SetText(mm.locationMode=="none" and "" or GetMinimapZoneText())
  if MinimapCluster then
   for _,key in ipairs({"ZoneTextButton","Tracking","InstanceDifficulty"}) do if MinimapCluster[key] then MinimapCluster[key]:Hide() end end
  end
  for _,name in ipairs({"GameTimeFrame","TimeManagerClockButton","MinimapZoneTextButton","MiniMapTracking","MinimapZoomIn","MinimapZoomOut"}) do if _G[name] then _G[name]:Hide() end end
  if A.RegisterMover then A.RegisterMover("minimap",S.map,"Minimap",mm,"position") end
  C_Timer.After(1,S.CollectMapButtons)
  C_Timer.After(5,S.CollectMapButtons)
 end
 if B.ApplyAuras then B.ApplyAuras() end
end
B.RegisterRenderer("shell",S.Apply)
local events=CreateFrame("Frame")
for _,e in ipairs({"PLAYER_XP_UPDATE","UPDATE_EXHAUSTION","PLAYER_LEVEL_UP","ZONE_CHANGED","ZONE_CHANGED_NEW_AREA","PLAYER_MONEY","PLAYER_ENTERING_WORLD"}) do events:RegisterEvent(e) end
events:SetScript("OnEvent",function() if A.ready and not B.conflict then status() end end)
