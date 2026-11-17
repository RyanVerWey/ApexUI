local _, A = ...
local FONT="Fonts\\FRIZQT__.TTF"
local function pos(point,x,y) return {point=point,relPoint=point,x=x,y=y} end

function A.UtilityLayout(profile)
 local p=A.Copy(profile);local u=p.addons[A.UF];local ab=p.addons[A.AB]
 -- Absolute anchors make this preset safe to apply more than once.
 u.positions.player.y=-318;u.positions.pet.y=-330
 p=A.CenterCombatLayout(p);u=p.addons[A.UF];ab=p.addons[A.AB]
 u.positions.playerCastbar.y=-409;u.positions.petCastbar=pos("CENTER",u.positions.pet.x,-409)
 local b=ab.bars.XPBar
 b.width=u.player.frameWidth;b.height=16;b.textSize=12;b.xpArt=nil
 b.customBorder=true;b.borderTexture="solid";b.borderThickness="thin"
 b.borderColor={r=.55,g=.43,b=.28,a=1};b.alwaysHidden=false;b.barVisibility="always"
 ab.barPositions.XPBar=pos("CENTER",u.positions.player.x,-371)
 for _,key in ipairs({"MainBar","Bar9","Bar4","Bar5"}) do
  local old=ab.barPositions[key]
  ab.barPositions[key]=pos("BOTTOM",old.x,(key=="MainBar" or key=="Bar9") and 14 or 73)
  p.unlockLayout.anchors[key]=nil
 end
 -- Utility spells remain accessible in a slim column beside the main grid.
 ab.bars.Bar2.numRows=12;ab.bars.Bar2.numIcons=12;ab.bars.Bar2.alwaysShowButtons=false
 ab.barPositions.Bar2=pos("BOTTOM",650,14)
 ab.barPositions.PetBar=pos("CENTER",u.positions.pet.x,-394)
 for _,key in ipairs({"Bar2","PetBar","XPBar","pet","petCastbar"}) do p.unlockLayout.anchors[key]=nil end
 local db=p.addons.ApexDataBars
 if db then
  local left,right
  for _,bar in ipairs(db.bars) do if bar.name=="Left status" then left=bar elseif bar.name=="Right status" then right=bar end end
  if left and right then
   local blocks={};local byType={}
   for _,bar in ipairs({left,right}) do for _,block in ipairs(bar.blocks) do byType[block.type]=block end end
   for _,kind in ipairs({"durability","coords","fps","ms","gold","clock"}) do
    if byType[kind] then local c=A.Copy(byType[kind]);c.id=#blocks+1;blocks[#blocks+1]=c end
   end
   right.blocks=blocks;right.nextBlockId=#blocks;right.fontScale=115;right.thickness=25
   right.sizingMode="auto";right.fillBlockId=2;right.centerBlockId=nil
   for _,block in ipairs(blocks) do
    if block.type=="clock" then block.settings.fontSizeClock=18;block.settings.fontSizeInfo=11 end
   end
   right.savedPos=pos("BOTTOMRIGHT",-4,3);right.visibility="always"
   left.visibility="never"
   p.unlockLayout.anchors["EDB_"..left.id]=nil;p.unlockLayout.anchors["EDB_"..right.id]=nil
  end
 end
 p.apexUtility=true
 return p.apexThirdRow and A.ThirdRowLayout(p) or p
end

-- Each added bar keeps its own action page; copy appearance only.
function A.TwoRowLayout(profile)
 local p=A.Copy(profile);local ab=p.addons[A.AB];local u=p.addons[A.UF]
 local delta=14-ab.barPositions.MainBar.y
 for _,key in ipairs({"player","pet","playerCastbar","petCastbar"}) do
  if u.positions[key] then u.positions[key].y=u.positions[key].y+delta end
  p.unlockLayout.anchors[key]=nil
 end
 for _,key in ipairs({"buffsPos","debuffsPos"}) do
  local at=u.playerAuraBars[key];if at then at.y=at.y+delta end
 end
 for _,key in ipairs({"XPBar","PetBar"}) do
  if ab.barPositions[key] then ab.barPositions[key].y=ab.barPositions[key].y+delta end
  p.unlockLayout.anchors[key]=nil
 end
 p.unlockLayout.anchors.PAB_Buffs=nil;p.unlockLayout.anchors.PAB_Debuffs=nil
 for _,key in ipairs({"MainBar","Bar9","Bar4","Bar5"}) do
  ab.barPositions[key]=pos("BOTTOM",ab.barPositions[key].x,(key=="MainBar" or key=="Bar9") and 14 or 73)
  p.unlockLayout.anchors[key]=nil
 end
 for _,key in ipairs({"Bar3","Bar10"}) do
  local b=ab.bars[key];b.alwaysHidden=true;b.barVisibility="never"
 end
 p.apexThirdRow=nil
 return p
end

function A.ThirdRowLayout(profile)
 local p=A.Copy(profile);local ab=p.addons[A.AB];local u=p.addons[A.UF]
 local delta=73-ab.barPositions.MainBar.y
 for _,key in ipairs({"player","pet","playerCastbar","petCastbar"}) do
  if u.positions[key] then u.positions[key].y=u.positions[key].y+delta end
  p.unlockLayout.anchors[key]=nil
 end
 for _,key in ipairs({"buffsPos","debuffsPos"}) do
  local at=u.playerAuraBars[key];if at then at.y=at.y+delta end
 end
 for _,key in ipairs({"XPBar","PetBar"}) do
  if ab.barPositions[key] then ab.barPositions[key].y=ab.barPositions[key].y+delta end
  p.unlockLayout.anchors[key]=nil
 end
 p.unlockLayout.anchors.PAB_Buffs=nil;p.unlockLayout.anchors.PAB_Debuffs=nil
 for _,key in ipairs({"MainBar","Bar9","Bar4","Bar5"}) do
  ab.barPositions[key]=pos("BOTTOM",ab.barPositions[key].x,(key=="MainBar" or key=="Bar9") and 73 or 132)
  p.unlockLayout.anchors[key]=nil
 end
 for _,key in ipairs({"Bar3","Bar10"}) do
  local b=ab.bars[key] or {};ab.bars[key]=b
  for _,field in ipairs({"buttonWidth","buttonHeight","buttonPadding","cooldownFontSize","keybindFontSize","countFontSize","hideMacroText","showCooldownText","borderStyle","borderColor","iconZoom"}) do
   b[field]=A.Copy(ab.bars.MainBar[field])
  end
  b.buttonWidth=50;b.buttonHeight=50;b.buttonPadding=1;b.numRows=1;b.numIcons=12
  b.orientation="horizontal";b.overrideNumRows=nil;b.overrideNumIcons=nil;b.targetWidth=0;b.targetHeight=0;b.clickThrough=false
  b.enabled=true;b.alwaysHidden=false;b.barVisibility="always";b.alwaysShowButtons=true
  b.mouseoverEnabled=false;b.iconOrder="BOTTOMLEFT";b.endCaps=false;b.foreverBarBg=false
  ab.barPositions[key]=pos("BOTTOM",ab.barPositions[key=="Bar3" and "MainBar" or "Bar9"].x,14)
  p.unlockLayout.anchors[key]=nil
 end
 p.apexThirdRow=true
 return p
end

-- Save native menu/bag positions in the active Blizzard layout, not a competing mover.
A.UTILITY_VERSION=6
function A.PositionUtilityMap()
 local host=A.Shell and A.Shell.map;local bounds=A.utilityBounds
 if not host or not bounds or InCombatLockdown() then return end
 if bounds.mapDock then
  host:ClearAllPoints();host:SetPoint("TOPRIGHT",UIParent,"TOPRIGHT",-(A.EDGE_INSET or 14),-(A.EDGE_INSET or 14)-bounds.height-12)
 else
  local profile=A.Active();local mm=profile.addons.ApexMinimap
  if mm then A.Backend.Position(host,mm.minimap.position) end
 end
end
function A.PlaceNativeUtilities()
 if InCombatLockdown() or not A.OwnActive() then return end
 if A.Backend.EditModeOpen() or not (MicroMenuContainer and BagsBar) then return end
 BagsBar:SetParent(UIParent);MicroMenuContainer:SetParent(UIParent)
 -- A compact three-tier utility block shares the combat grid's baseline.
 local uiScale=UIParent:GetEffectiveScale()
 local gridRight,gridBottom,gridTop=0,nil,0
 for _,key in ipairs({"MainBar","Bar9","Bar4","Bar5"}) do
  local bar=_G["ApexBar_"..key]
  if bar and bar:IsShown() and bar:GetRight() then
   local r=bar:GetEffectiveScale()/uiScale
   gridRight=math.max(gridRight,bar:GetRight()*r)
   gridBottom=math.min(gridBottom or math.huge,bar:GetBottom()*r)
   gridTop=math.max(gridTop,bar:GetTop()*r)
  end
 end
 local edge,gap=A.EDGE_INSET or 14,12
 local mapDock=A.Active().apexUtilityDock=="top"
 local panelLeft=gridRight+gap
 local panelWidth=math.min(440,UIParent:GetWidth()-panelLeft-edge)
 if mapDock then panelWidth=A.Shell and A.Shell.map and A.Shell.map:GetWidth() or 374 end
 if panelWidth<220 then return end
 panelLeft=UIParent:GetWidth()-edge-panelWidth
 local base=edge
 local totalHeight=math.max(118,gridTop-base)
 if mapDock then totalHeight=118 end
 local statusHeight=24
 local menuHeight=math.min(46,(totalHeight-statusHeight-12)*.48)
 local bagHeight=math.min(48,totalHeight-statusHeight-menuHeight-12)
 local bagAspect=BagsBar:GetWidth()/math.max(1,BagsBar:GetHeight())
 local menuAspect=MicroMenuContainer:GetWidth()/math.max(1,MicroMenuContainer:GetHeight())
 bagHeight=math.min(bagHeight,(panelWidth-104)/bagAspect)
 menuHeight=math.min(menuHeight,(panelWidth-104)/menuAspect)
 local function scaleControls()
  BagsBar:SetScale(bagHeight/BagsBar:GetHeight()*uiScale/BagsBar:GetParent():GetEffectiveScale())
  MicroMenuContainer:SetScale(menuHeight/MicroMenuContainer:GetHeight()*uiScale/MicroMenuContainer:GetParent():GetEffectiveScale())
 end
 scaleControls()
 local controlsRight=panelLeft+panelWidth-8
 local panelHeight=statusHeight+12+menuHeight+bagHeight
 if mapDock then base=UIParent:GetHeight()-edge-panelHeight end
 local menuY=base+statusHeight+4
 local bagY=menuY+menuHeight+4
 if mapDock then bagY=base+statusHeight+4;menuY=bagY+bagHeight+4 end
 A.utilityBounds={left=panelLeft,bottom=base,width=panelWidth,height=panelHeight,mapDock=mapDock}
 local controlsLeft=controlsRight-math.max(bagAspect*bagHeight,menuAspect*menuHeight)
 A.utilityBounds.launcher={left=panelLeft+4,bottom=math.min(menuY,bagY),width=controlsLeft-8-panelLeft-4,height=menuHeight+bagHeight+4}
 for _,entry in ipairs({{MicroMenuContainer,menuY},{BagsBar,bagY}}) do
  local f=entry[1];local scale=f:GetEffectiveScale()/uiScale
  f:ClearAllPoints();f:SetPoint("BOTTOMRIGHT",UIParent,"BOTTOMLEFT",controlsRight/scale,entry[2]/scale)
 end
 if A.Shell and A.Shell.LayoutStatus then A.Shell.LayoutStatus(A.utilityBounds) end
 A.PositionUtilityMap()
 if A.Suite and A.Suite.LayoutToolbar then A.Suite.LayoutToolbar() end

 return true
end
SLASH_APEXDOCK1="/apexdock"
SlashCmdList.APEXDOCK=function(input)
 local mode=(input or ""):lower()
 if mode~="top" and mode~="bottom" then print("ApexUI: /apexdock top | bottom");return end
 if InCombatLockdown() then print("ApexUI: move the utility dock after combat.");return end
 A.Active().apexUtilityDock=mode;A.PlaceNativeUtilities();A.RefreshUtility()
end

-- Edit Mode and minimap geometry can arrive after PLAYER_LOGIN. Retry briefly,
-- and resume on readiness/combat-end events without repeatedly resetting a finished layout.
local restoring=false
function A.QueueUtilityRestore()
 if restoring or not A.OwnActive() or not A.Active().apexUtility
  or ApexUICharacterDB.customLayout or A.utilitiesRestoredThisLogin then return end
 if InCombatLockdown() then return end
 restoring=true
 local tries=0
 local function attempt()
  if not A.OwnActive() or ApexUICharacterDB.customLayout or InCombatLockdown() then restoring=false;return end
  tries=tries+1
  if A.PlaceNativeUtilities() then
   ApexUICharacterDB.utilityPlacementVersion=A.UTILITY_VERSION
   ApexUICharacterDB.sharedUtilitiesPlaced=true
   A.utilitiesRestoredThisLogin=true
   restoring=false
   A.Refresh()
  elseif tries<10 then C_Timer.After(1,attempt)
  else
   restoring=false
   A.Print("Menu/bag placement is waiting for Edit Mode. Close Edit Mode, then /apexui enable to retry.")
  end
 end
 attempt()
end

local petXP,menuBackdrop
local function updatePetXP()
 if not petXP then return end
 if not A.OwnActive() or not A.Active().apexUtility or A.class~="HUNTER" or not UnitExists("pet") then petXP:Hide();return end
 local cur,max=GetPetExperience();cur=tonumber(cur) or 0;max=tonumber(max) or 0
 petXP:SetMinMaxValues(0,math.max(1,max));petXP:SetValue(cur)
 petXP.text:SetText(max>0 and string.format("Pet XP  %d/%d  (%.1f%%)",cur,max,cur/max*100) or "Pet XP  •  Level cap")
 petXP:Show()
end
function A.RefreshUtility()
 if InCombatLockdown() then return end
 local active=A.OwnActive() and A.Active().apexUtility
 if active and Minimap and MicroMenuContainer then
  if not menuBackdrop then
   menuBackdrop=CreateFrame("Frame",nil,UIParent,"BackdropTemplate");menuBackdrop:EnableMouse(false)
   menuBackdrop:SetFrameStrata("BACKGROUND")
   menuBackdrop:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
   menuBackdrop:SetBackdropColor(.035,.030,.026,.82);menuBackdrop:SetBackdropBorderColor(.55,.43,.28,.7)
   -- A small original blue jewel ties this dock to the portrait frames.
   local gem=menuBackdrop:CreateTexture(nil,"OVERLAY")
   gem:SetTexture("Interface\\AddOns\\ApexUI\\Frames\\Media\\split.tga")
   gem:SetTexCoord(1010/4096,1166/4096,0,96/2048)
   gem:SetSize(32,20);gem:SetPoint("TOP",menuBackdrop,"TOP",0,10)
   for _,side in ipairs({"LEFT","RIGHT"}) do
    local cap=menuBackdrop:CreateTexture(nil,"OVERLAY");cap:SetColorTexture(.7,.52,.29,.9)
    cap:SetSize(28,2);cap:SetPoint("TOP"..side,menuBackdrop,"TOP"..side,side=="LEFT" and 1 or -1,-2)
   end
  end
  menuBackdrop:ClearAllPoints()
  local bounds=A.utilityBounds
  if bounds then
   menuBackdrop:SetPoint("BOTTOMLEFT",UIParent,"BOTTOMLEFT",bounds.left,bounds.bottom)
   menuBackdrop:SetSize(bounds.width,bounds.height)
  end
  menuBackdrop:Show()
 elseif menuBackdrop then menuBackdrop:Hide() end
 if A.Frames and ApexUIDB.portraitFrames and ApexUIDB.portraitFrames.enabled~=false then if petXP then petXP:Hide() end;return end
 local ns=A.Backend._ModuleNS[A.UF];local host=ns.frames and ns.frames.pet
 if A.OwnActive() and A.Active().apexUtility and host and A.class=="HUNTER" then
  if not petXP then
   petXP=CreateFrame("StatusBar","ApexUIPetXP",host,"BackdropTemplate")
   petXP:EnableMouse(false);petXP:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
   petXP:SetStatusBarColor(.32,.50,.64,1)
   local bg=petXP:CreateTexture(nil,"BACKGROUND");bg:SetAllPoints();bg:SetColorTexture(.06,.05,.04,1)
   petXP:SetBackdrop({edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1});petXP:SetBackdropBorderColor(.55,.43,.28,1)
   petXP.text=petXP:CreateFontString(nil,"OVERLAY");petXP.text:SetPoint("CENTER")
  end
  local scale=host.Health:GetHeight()/(ns.db.profile.pet.healthHeight or 36)
  petXP:SetParent(host);petXP:SetSize(host:GetWidth(),16*scale)
  petXP:ClearAllPoints();petXP:SetPoint("TOPLEFT",host,"BOTTOMLEFT",0,-4*scale)
  petXP.text:SetFont(FONT,12*scale,"OUTLINE")
 end
 updatePetXP()
end
local events=CreateFrame("Frame")
for _,event in ipairs({"UNIT_PET_EXPERIENCE","UNIT_PET","PET_BAR_UPDATE","PLAYER_ENTERING_WORLD","PLAYER_REGEN_ENABLED","EDIT_MODE_LAYOUTS_UPDATED"}) do events:RegisterEvent(event) end
events:SetScript("OnEvent",function(_,event)
 if event=="UNIT_PET_EXPERIENCE" then updatePetXP() else C_Timer.After(.2,A.RefreshUtility) end
 if event=="PLAYER_ENTERING_WORLD" or event=="PLAYER_REGEN_ENABLED" or event=="EDIT_MODE_LAYOUTS_UPDATED" then
  C_Timer.After(.5,A.QueueUtilityRestore)
 end
end)
