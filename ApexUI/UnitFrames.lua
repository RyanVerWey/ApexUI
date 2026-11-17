local _,A=...
local B=A.Backend
local U={frames={},db={}}
B._ModuleNS.ApexUnits=U
local units={"player","pet","target","focus","targettarget"}
local function public(v) return not issecretvalue or not issecretvalue(v) end
local function bar(parent)
 local f=CreateFrame("StatusBar",nil,parent,"BackdropTemplate")
 f:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
 local bg=f:CreateTexture(nil,"BACKGROUND");bg:SetAllPoints();bg:SetColorTexture(.085,.067,.055,1)
 f.text=B.Text(f,16);f.text:SetPoint("CENTER");return f
end
local function update(unit)
 local f=U.frames[unit];if not f or not U.db.profile then return end
 local s=U.db.profile[unit]
 -- Secret combat values go directly to native display APIs, never Lua arithmetic.
 f.Health:SetMinMaxValues(0,UnitHealthMax(unit));f.Health:SetValue(UnitHealth(unit))
 if UnitHealthPercent and CurveConstants then
  f.Health.text:SetFormattedText("%d/%d  (%.0f%%)",UnitHealth(unit),UnitHealthMax(unit),UnitHealthPercent(unit,false,CurveConstants.ScaleTo100))
 else f.Health.text:SetFormattedText("%d/%d",UnitHealth(unit),UnitHealthMax(unit)) end
 f.Power:SetMinMaxValues(0,UnitPowerMax(unit));f.Power:SetValue(UnitPower(unit))
 if UnitPowerPercent and CurveConstants then
  f.Power.text:SetFormattedText("%d/%d  (%.0f%%)",UnitPower(unit),UnitPowerMax(unit),UnitPowerPercent(unit,nil,false,CurveConstants.ScaleTo100))
 else f.Power.text:SetFormattedText("%d/%d",UnitPower(unit),UnitPowerMax(unit)) end
 local _,token=UnitPowerType(unit)
 local color=(public(token) and PowerBarColor[token]) or PowerBarColor.MANA
 if color then f.Power:SetStatusBarColor(color.r,color.g,color.b) end
 if public(token) and token=="MANA" then f.Power:SetStatusBarColor(.05,.30,.85) end
 local name,surname=UnitName(unit)
 if public(name) and public(surname) and name and surname and surname~="" then name=name.." "..surname end
 f.name:SetText(name);f.level:SetText(UnitLevel(unit))
 if unit=="target" then
  local maximum=UnitPowerMax(unit)
  f.Power:SetShown(not public(maximum) or maximum>0)
 end
end
-- A slim encounter-style target, using original geometry and native textures.
local function styleTarget(f,s)
 local width=600
 f:SetSize(width,66);f:SetBackdrop(nil);f.rim:Hide()
 f.name:ClearAllPoints();f.name:SetPoint("TOP",f,"TOP",0,0)
 f.name:SetWidth(width-100);f.name:SetFont(A.FONT,21,"OUTLINE");f.name:SetJustifyH("CENTER")
 f.name:SetTextColor(.96,.89,.72);f.name:Show()
 f.level:ClearAllPoints();f.level:SetPoint("RIGHT",f.Health,"LEFT",-12,0)
 f.level:SetFont(A.FONT,15,"OUTLINE");f.level:SetTextColor(.89,.76,.51);f.level:Show()
 f.Health:ClearAllPoints();f.Health:SetPoint("TOPLEFT",f,"TOPLEFT",20,-30);f.Health:SetSize(width-40,26)
 f.Health:SetStatusBarColor(.64,.045,.045);f.Health.text:SetFont(A.FONT,16,"OUTLINE")
 f.Power:ClearAllPoints();f.Power:SetPoint("TOPLEFT",f.Health,"BOTTOMLEFT",0,-5)
 f.Power:SetSize(width-40,5);f.Power.text:Hide()
 if not f.encounterRim then
  local rim=CreateFrame("Frame",nil,f,"BackdropTemplate");f.encounterRim=rim
  rim:EnableMouse(false);rim:SetFrameLevel(f.Health:GetFrameLevel()+3)
  rim:SetPoint("TOPLEFT",f.Health,"TOPLEFT",-3,3);rim:SetPoint("BOTTOMRIGHT",f.Health,"BOTTOMRIGHT",3,-3)
  rim:SetBackdrop({edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
  rim:SetBackdropBorderColor(.78,.65,.42,1)
  -- Small swept endcaps keep the silhouette distinct without a large panel.
  for _,side in ipairs({-1,1}) do
   for _,dy in ipairs({-1,1}) do
    local trim=rim:CreateTexture(nil,"OVERLAY")
    trim:SetColorTexture(.84,.72,.48,1);trim:SetSize(18,2)
    trim:SetPoint("CENTER",rim,side==-1 and "LEFT" or "RIGHT",side*6,dy*8)
    trim:SetRotation(side*dy*math.pi/4)
   end
   local line=rim:CreateTexture(nil,"OVERLAY");line:SetColorTexture(.58,.45,.28,.8)
   line:SetSize(90,1);line:SetPoint(side==-1 and "TOPLEFT" or "TOPRIGHT",f,side==-1 and "TOPLEFT" or "TOPRIGHT",side==-1 and 30 or -30,-13)
  end
 end
 f.cast:SetParent(f);f.cast:ClearAllPoints();f.cast:SetPoint("TOP",f,"BOTTOM",0,-9)
 f.cast:SetSize(width-110,16);f.cast:SetStatusBarColor(.72,.53,.24)
 f.cast.text:SetFont(A.FONT,13,"OUTLINE")
end
local function castUpdate(unit)
 local f=U.frames[unit];local c=f and f.cast;if not c then return end
 local name,_,icon,startMS,endMS=UnitCastingInfo(unit)
 local duration=UnitCastingDuration and UnitCastingDuration(unit)
 local channel=false
 if not name then
  name,_,icon,startMS,endMS=UnitChannelInfo(unit)
  duration=UnitChannelDuration and UnitChannelDuration(unit);channel=true
 end
 if duration and c.SetTimerDuration then
  c:SetTimerDuration(duration,Enum.StatusBarInterpolation.Immediate,channel and Enum.StatusBarTimerDirection.RemainingTime or Enum.StatusBarTimerDirection.ElapsedTime)
  c.text:SetText(name);c:Show();return
 end
 if public(name) and name and public(startMS) and public(endMS) then
  c.startTime=startMS/1000;c.endTime=endMS/1000;c.channel=channel
  c:SetMinMaxValues(c.startTime,c.endTime);c.text:SetText(name);c:Show()
 else c.startTime=nil;c:Hide() end
end
local function create(unit)
 local f=CreateFrame("Button","ApexUnit_"..unit,UIParent,"SecureUnitButtonTemplate,BackdropTemplate")
 f:SetAttribute("unit",unit);f:SetAttribute("type1","target");f:SetAttribute("type2","togglemenu")
 f:RegisterForClicks("AnyUp");B.FrameBorder(f)
 f.Health=bar(f);f.Power=bar(f)
 f.rim=CreateFrame("Frame",nil,f,"BackdropTemplate");f.rim:SetAllPoints();f.rim:EnableMouse(false);f.rim:SetFrameLevel(f:GetFrameLevel()+4)
 f.rim:SetBackdrop({edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
 f.rim:SetBackdropBorderColor(.65,.47,.25,1)
 f.name=B.Text(f,16);f.name:SetPoint("TOPLEFT",7,-3);f.name:SetJustifyH("LEFT")
 f.level=B.Text(f,14);f.level:SetPoint("TOPRIGHT",-7,-3)
 f.cast=bar(UIParent);B.FrameBorder(f.cast);f.cast:Hide()
 f.cast:SetScript("OnUpdate",function(self)
  if self.startTime then
   local now=GetTime()
   if now>=self.endTime then self:Hide();self.startTime=nil
   else self:SetValue(self.channel and (self.endTime-now+self.startTime) or now) end
  end
 end)
 f:SetScript("OnEnter",function(self) GameTooltip:SetOwner(self,"ANCHOR_RIGHT");GameTooltip:SetUnit(unit);GameTooltip:Show() end)
 f:SetScript("OnLeave",function() GameTooltip:Hide() end)
 f:HookScript("OnShow",function() update(unit);castUpdate(unit) end)
 RegisterUnitWatch(f)
 U.frames[unit]=f;return f
end
function U.Apply()
 if not A.OwnActive() or B.conflict or InCombatLockdown() then return end
 U.db.profile=A.Active().addons.ApexUnits
 if not U.db.profile.targetOfTargetHidden then
  U.db.profile.enabledFrames.targettarget=false
  U.db.profile.targetOfTargetHidden=true
 end
 for _,unit in ipairs(units) do
  local s=U.db.profile[unit];local f=U.frames[unit] or create(unit)
  local hh=s.healthHeight or 36;local ph=s.powerPosition=="none" and 0 or (s.powerHeight or 22)
  local header=s.bottomTextBar and (s.bottomTextBarHeight or 24) or 0
  f:SetSize(s.frameWidth,hh+ph+header);B.Position(f,U.db.profile.positions[unit])
  f.Health:ClearAllPoints();f.Health:SetPoint("TOPLEFT",2,-header);f.Health:SetSize(s.frameWidth-4,hh)
  local color={r=.65,g=.045,b=.055}
  f.Health:SetStatusBarColor(color.r,color.g,color.b)
  f.Health.text:SetFont(A.FONT,s.centerTextSize or 18,"OUTLINE")
  f.Power:ClearAllPoints();f.Power:SetPoint("TOPLEFT",f.Health,"BOTTOMLEFT",0,0);f.Power:SetSize(s.frameWidth-4,math.max(1,ph-2));f.Power:SetShown(ph>0)
  f.Power.text:SetFont(A.FONT,s.powerPercentSize or 16,"OUTLINE")
  f.name:SetFont(A.FONT,s.btbLeftSize or 16,"OUTLINE");f.name:SetWidth(s.frameWidth-55)
  f.name:SetShown(header>0);f.level:SetShown(header>0)
  local accent=A.ClassInfo(A.class).color;f.name:SetTextColor(unpack(accent));f:SetBackdropBorderColor(.55,.43,.28,1)
  local cw=unit=="player" and s.playerCastbarWidth or s.castbarWidth
  local ch=unit=="player" and s.playerCastbarHeight or s.castbarHeight
  f.cast:SetSize(cw or s.frameWidth,ch or 20);f.cast:SetStatusBarColor(unpack(accent))
  B.Position(f.cast,U.db.profile.positions[unit.."Castbar"])
  if unit=="target" then styleTarget(f,s) end
  if U.db.profile.enabledFrames[unit]==false then UnregisterUnitWatch(f);f:Hide() else RegisterUnitWatch(f) end
  if A.RegisterMover then A.RegisterMover(unit,f,"Unit: "..unit,U.db.profile.positions,unit) end
  update(unit);castUpdate(unit)
 end
 -- Keep Blizzard party/raid frames available. Replace only the five owned units.
 for _,name in ipairs({"PlayerFrame","PetFrame","TargetFrame","FocusFrame","TargetFrameToT","CastingBarFrame","PlayerCastingBarFrame","PetCastingBarFrame"}) do
  local f=_G[name]
  if f then
   if not B.hiddenUnits then B.hiddenUnits=CreateFrame("Frame");B.hiddenUnits:Hide() end
   f:SetParent(B.hiddenUnits)
  end
 end
end
U.ReloadFrames=U.Apply;U.PAB_Restyle=function() end;U.PAB_ApplyLiveConfig=function() end
B.RegisterRenderer("units",U.Apply)
local events=CreateFrame("Frame")
for _,e in ipairs({"UNIT_HEALTH","UNIT_MAXHEALTH","UNIT_POWER_UPDATE","UNIT_MAXPOWER","UNIT_DISPLAYPOWER","UNIT_NAME_UPDATE","UNIT_LEVEL",
 "PLAYER_TARGET_CHANGED","PLAYER_FOCUS_CHANGED","UNIT_TARGET","UNIT_PET","PLAYER_ENTERING_WORLD","UNIT_SPELLCAST_START","UNIT_SPELLCAST_STOP",
 "UNIT_SPELLCAST_FAILED","UNIT_SPELLCAST_INTERRUPTED","UNIT_SPELLCAST_DELAYED","UNIT_SPELLCAST_CHANNEL_START","UNIT_SPELLCAST_CHANNEL_UPDATE","UNIT_SPELLCAST_CHANNEL_STOP"}) do events:RegisterEvent(e) end
events:SetScript("OnEvent",function(_,event,unit)
 if not A.ready or B.conflict then return end
 if event:find("SPELLCAST",1,true) then if U.frames[unit] then castUpdate(unit) end
 elseif U.frames[unit] and event~="UNIT_TARGET" then update(unit)
 else for _,u in ipairs(units) do update(u);castUpdate(u) end end
end)
