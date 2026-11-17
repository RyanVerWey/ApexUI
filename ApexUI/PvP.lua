local _,A=...
local V={frames={},details={}};A.PvP=V
local function public(v) return not issecretvalue or not issecretvalue(v) end
local function eligible(unit)
 return public(unit) and type(unit)=="string" and (unit=="player" or unit:match("^party%d+$") or unit:match("^raid%d+$"))
end
function V.Status(unit)
 if not eligible(unit) or not UnitExists(unit) then return nil end
 if not UnitIsPVP then return "PvP ?" end
 local pvp=UnitIsPVP(unit)
 local ffa=UnitIsPVPFreeForAll and UnitIsPVPFreeForAll(unit)
 if public(ffa) and ffa then return "FFA" end
 if public(pvp) and pvp then return "PvP" end
 if not public(pvp) or not public(ffa) then return "PvP ?" end
 return nil
end
function V.Update(frame)
 local badge=V.frames[frame];if not badge then return end
 local d=V.details[frame]
 local status
 if d and d.preview then status=d.preview.pvp and "PvP" or nil else status=V.Status(frame.unit) end
 badge:SetText(status or "");badge:SetShown(status~=nil)
 if d then V.UpdateDetails(frame,d) end
end
local function booleanAlpha(value,yes,no)
 if public(value) then return value and yes or no end
 if C_CurveUtil and C_CurveUtil.EvaluateColorValueFromBoolean then
  return C_CurveUtil.EvaluateColorValueFromBoolean(value,yes,no)
 end
 return no
end
function V.CriticalAlpha(unit)
 if C_CurveUtil and C_CurveUtil.CreateCurve and UnitHealthPercent and Enum and Enum.LuaCurveType then
  if not V.criticalCurve then
   V.criticalCurve=C_CurveUtil.CreateCurve();V.criticalCurve:SetType(Enum.LuaCurveType.Step)
   V.criticalCurve:AddPoint(0,1);V.criticalCurve:AddPoint(.20,0);V.criticalCurve:AddPoint(1,0)
  end
  return UnitHealthPercent(unit,false,V.criticalCurve)
 end
 local hp,max=UnitHealth(unit),UnitHealthMax(unit)
 if public(hp) and public(max) and max>0 and hp>0 and hp/max<.20 then return 1 end
 return 0
end
function V.UpdateDetails(frame,d)
 local unit=frame.unit
 if not d.preview and (not eligible(unit) or not UnitExists(unit)) then d.overlay:Hide();d.class:Hide();return end
 d.overlay:Show()
 local _,class=UnitClass(unit)
 if d.preview then class=d.preview.class end
 if public(class) and class then
  d.class:SetTexture("Interface\\Icons\\ClassIcon_"..class);d.class:Show()
 else d.class:Hide() end
 local dead=UnitIsDeadOrGhost and UnitIsDeadOrGhost(unit)
 if d.preview then dead=d.preview.dead end
 d.dead:SetAlpha(booleanAlpha(dead,1,0));d.alive:SetAlpha(booleanAlpha(dead,0,1))
 d.critical:SetAlpha(d.preview and (d.preview.critical and 1 or 0) or V.CriticalAlpha(unit))
 if public(dead) then d.class:SetDesaturated(dead and true or false) end
end
function V.Preview(frame,index)
 V.Attach(frame,"party")
 local d=V.details[frame];if not d then return end
 d.preview={class=({"WARRIOR","PRIEST","MAGE","ROGUE"})[index],pvp=index==1 or index==3,critical=index==1,dead=index==2}
 V.Update(frame)
end
local function details(frame,kind,badge)
 local d={};V.details[frame]=d
 local parent=frame.labelHost or frame
 d.class=parent:CreateTexture(nil,"OVERLAY",nil,7);d.class:SetSize(kind=="raid" and 12 or 18,kind=="raid" and 12 or 18)
 d.class:SetTexCoord(.08,.92,.08,.92)
 if kind=="party" then
  d.class:SetPoint("TOPLEFT",frame,"TOPLEFT",93,-5)
  if frame.name then
   frame.name:ClearAllPoints();frame.name:SetPoint("TOPLEFT",117,-6);frame.name:SetPoint("TOPRIGHT",-104,-6)
   badge:ClearAllPoints();badge:SetPoint("LEFT",frame.name,"RIGHT",5,0)
  end
 else
  d.class:SetPoint("TOPLEFT",frame,"TOPLEFT",3,-3)
  if frame.name then
   frame.name:ClearAllPoints();frame.name:SetPoint("TOPLEFT",18,-3);frame.name:SetPoint("TOPRIGHT",-34,-3)
  end
  badge:ClearAllPoints();badge:SetPoint("TOPRIGHT",frame,"TOPRIGHT",-2,-3)
 end
 badge:SetFont("Fonts\\FRIZQT__.TTF",kind=="raid" and 10 or 14,"OUTLINE");badge:SetTextColor(1,.68,.16)
 d.overlay=CreateFrame("Frame",nil,frame);d.overlay:SetAllPoints();d.overlay:SetFrameLevel(frame:GetFrameLevel()+8);d.overlay:EnableMouse(false)
 d.alive=CreateFrame("Frame",nil,d.overlay);d.alive:SetAllPoints();d.alive:EnableMouse(false)
 d.critical=CreateFrame("Frame",nil,d.alive);d.critical:SetAllPoints();d.critical:EnableMouse(false)
 local flash=d.critical:CreateTexture(nil,"OVERLAY");flash:SetAllPoints();flash:SetColorTexture(1,.035,.02,1)
 local time=0
 d.critical:SetScript("OnUpdate",function(_,dt)
  time=(time+dt)%1.2;flash:SetAlpha(.10+.22*(.5-.5*math.cos(time/1.2*math.pi*2)))
 end)
 d.dead=CreateFrame("Frame",nil,d.overlay);d.dead:SetAllPoints();d.dead:EnableMouse(false)
 local grey=d.dead:CreateTexture(nil,"OVERLAY");grey:SetAllPoints();grey:SetColorTexture(.22,.23,.25,.78)
 local text=d.dead:CreateFontString(nil,"OVERLAY");text:SetFont("Fonts\\FRIZQT__.TTF",kind=="raid" and 10 or 16,"OUTLINE")
 text:SetTextColor(.88,.88,.88);text:SetPoint("CENTER");text:SetText(kind=="raid" and "DEAD" or "")
end
function V.Attach(frame,kind)
 if not frame then return end
 if V.frames[frame] then V.Update(frame);return end
 if InCombatLockdown() then V.pending=true;return end
 local parent=frame.labelHost or frame
 local t=parent:CreateFontString(nil,"OVERLAY",nil,7)
 t:SetFont("Fonts\\FRIZQT__.TTF",kind=="raid" and 10 or 12,"OUTLINE")
 t:SetTextColor(1,.56,.20);t:SetShadowColor(0,0,0,1);t:SetShadowOffset(1,-1);t:SetWordWrap(false)
 if kind=="player" and frame.face then t:SetPoint("BOTTOM",frame.face,"BOTTOM",0,3)
 elseif kind=="party" then t:SetPoint("BOTTOM",frame,"BOTTOM",0,6)
 else t:SetPoint("RIGHT",frame,"RIGHT",-3,0) end
 V.frames[frame]=t
 if kind~="player" then details(frame,kind,t) end
 V.Update(frame)
end
function V.Native(frame)
 if not frame then return end
 if eligible(frame.unit) then V.Attach(frame,"raid")
 elseif V.frames[frame] then
  V.frames[frame]:Hide()
  local d=V.details[frame];if d then d.overlay:Hide();d.class:Hide() end
 end
end
function V.Refresh()
 if not A.ready or not A.OwnActive() or A.Backend.conflict then return end
 if A.Frames and A.Frames.units then V.Attach(A.Frames.units.player,"player") end
 if A.Party then for _,f in pairs(A.Party.frames) do V.Attach(f,"party") end end
 if not V.hooked and CompactUnitFrame_SetUnit then
  hooksecurefunc("CompactUnitFrame_SetUnit",V.Native);V.hooked=true
 end
 -- Both native layouts are pooled: inspect current unit tokens, not slot numbers.
 for i=1,40 do V.Native(_G["CompactRaidFrame"..i]) end
 for group=1,8 do for member=1,5 do V.Native(_G["CompactRaidGroup"..group.."Member"..member]) end end
 for frame in pairs(V.frames) do V.Update(frame) end
end
local events=CreateFrame("Frame");V.events=events
for _,event in ipairs({"PLAYER_ENTERING_WORLD","GROUP_ROSTER_UPDATE","PLAYER_REGEN_ENABLED","UNIT_FACTION","UNIT_FLAGS","PLAYER_FLAGS_CHANGED","UNIT_HEALTH","UNIT_MAXHEALTH","UNIT_CONNECTION","ADDON_LOADED"}) do events:RegisterEvent(event) end
events:SetScript("OnEvent",function(_,event,unit)
 if event=="UNIT_HEALTH" or event=="UNIT_MAXHEALTH" or event=="UNIT_FLAGS" then
  for frame in pairs(V.frames) do if frame.unit==unit then V.Update(frame) end end
 else V.Refresh() end
end)
local elapsed=0
events:SetScript("OnUpdate",function(_,dt)
 elapsed=elapsed+dt;if elapsed<1 then return end;elapsed=0
 V.Refresh()
end)
