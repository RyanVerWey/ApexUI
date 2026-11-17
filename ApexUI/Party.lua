local _,A=...
local B=A.Backend
local P={frames={},previewFrames={}};A.Party=P
local function public(v) return not issecretvalue or not issecretvalue(v) end
local roles={
 TANK={order=1,color={.12,.38,.78},icon="tank"},
 HEALER={order=2,color={.78,.57,.13},icon="healer"},
 DAMAGER={order=3,color={.65,.045,.055},icon="damage"},
 NONE={order=4,color={.34,.32,.28}},
}
function P.Role(unit)
 local role=UnitGroupRolesAssigned and UnitGroupRolesAssigned(unit)
 return public(role) and roles[role] and role or "NONE"
end
function P.StyleRole(f,role)
 local r=roles[role] or roles.NONE
 f.health:SetStatusBarColor(unpack(r.color));f:SetBackdropBorderColor(unpack(r.color))
 f.name:SetTextColor(.97,.93,.80)
 if r.icon then
  f.role:SetTexture("Interface\\AddOns\\ApexUI\\Media\\Roles\\"..r.icon..".tga");f.role:SetTexCoord(0,1,0,1)
  f.role:Show()
 else f.role:Hide() end
 f.selectedRole=role
end
function P.Order()
 local order={"party1","party2","party3","party4"}
 table.sort(order,function(a,b)
  local ae,be=UnitExists(a),UnitExists(b)
  if ae~=be then return ae end
  local ar,br=roles[P.Role(a)].order,roles[P.Role(b)].order
  if ar~=br then return ar<br end
  return a<b
 end)
 return order
end
local function settings()
 local profile=A.Active()
 profile.party=profile.party or {width=330,height=104,gap=10,position={point="TOPLEFT",relPoint="TOPLEFT",x=14,y=-130}}
 if not profile.party.rightRoleIcon then
  profile.party.width=(profile.party.width or 330)+80
  profile.party.rightRoleIcon=true
 end
 if profile.party.scale==nil then profile.party.scale=.75 end
 return profile.party
end
local function label(parent,size)
 local t=B.Text(parent,size);t:SetWordWrap(false);return t
end
local function bar(parent,y,height,color)
 local b=CreateFrame("StatusBar",nil,parent)
 b:SetPoint("TOPLEFT",91,y);b:SetPoint("TOPRIGHT",-8,y);b:SetHeight(height)
 b:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar");b:SetStatusBarColor(unpack(color))
 local bg=b:CreateTexture(nil,"BACKGROUND");bg:SetAllPoints();bg:SetColorTexture(.065,.051,.04,1)
 b.text=label(b,height>=28 and 17 or 14);b.text:SetPoint("CENTER")
 return b
end
local function create(index,preview,parent)
 local unit="party"..index
 local f=CreateFrame(preview and "Frame" or "Button",preview and ("ApexPartyPreview"..index) or ("ApexParty_"..unit),parent,
  preview and "BackdropTemplate" or "SecureUnitButtonTemplate,BackdropTemplate")
 f.unit=unit;B.FrameBorder(f);f:SetBackdropColor(.025,.027,.031,.94);f:SetBackdropBorderColor(.63,.46,.27,1)
 if preview then f:SetBackdropColor(.025,.027,.031,1) end
 if not preview then
  f:SetAttribute("unit",unit);f:SetAttribute("type1","target");f:SetAttribute("type2","togglemenu");f:RegisterForClicks("AnyUp")
  -- Standard unit buttons also accept mouseover macros and click-cast addons.
  ClickCastFrames=ClickCastFrames or {};ClickCastFrames[f]=true
  RegisterStateDriver(f,"visibility","[group:raid] hide; [@"..unit..",exists] show; hide")
 end
 f.role=f:CreateTexture(nil,"ARTWORK");f.role:SetSize(60,60);f.role:SetPoint("TOPLEFT",15,-11)
 f.name=label(f,17);f.name:SetPoint("TOPLEFT",93,-6);f.name:SetPoint("TOPRIGHT",-50,-6);f.name:SetJustifyH("LEFT")
 f.level=label(f,14);f.level:SetPoint("TOPRIGHT",-10,-7)
 f.health=bar(f,-29,29,{.65,.045,.055})
 f.power=bar(f,-61,18,{.05,.30,.85})
 f.dps=label(f,13);f.dps:SetPoint("BOTTOMLEFT",10,6);f.dps:SetTextColor(.93,.80,.53)
 f.hps=label(f,13);f.hps:SetPoint("BOTTOMRIGHT",-10,6);f.hps:SetTextColor(.52,.85,.64)
 for _,side in ipairs({"TOPLEFT","TOPRIGHT"}) do
  local cap=f:CreateTexture(nil,"OVERLAY");cap:SetColorTexture(.83,.65,.36,1);cap:SetSize(26,2);cap:SetPoint(side,f,side,side=="TOPLEFT" and 2 or -2,-2)
 end
 if not preview then
  f:SetScript("OnEnter",function(self)
   GameTooltip:SetOwner(self,"ANCHOR_RIGHT");GameTooltip:SetUnit(self.unit)
   GameTooltip:AddLine("DPS / HPS: current fight, retained between fights.",.93,.80,.53,true)
   GameTooltip:AddLine("Unavailable rates show -- when combat data cannot be matched safely.",.75,.75,.75,true);GameTooltip:Show()
  end)
  f:SetScript("OnLeave",function() GameTooltip:Hide() end)
 end
 return f
end
local function value(b,unit,health)
 local cur,max
 if health then cur,max=UnitHealth(unit),UnitHealthMax(unit) else cur,max=UnitPower(unit),UnitPowerMax(unit) end
 b:SetMinMaxValues(0,max);b:SetValue(cur)
 local percentFn=health and UnitHealthPercent or UnitPowerPercent
 if percentFn and CurveConstants then
  local percent
  if health then percent=percentFn(unit,false,CurveConstants.ScaleTo100)
  else percent=percentFn(unit,nil,false,CurveConstants.ScaleTo100) end
  b.text:SetFormattedText("%d / %d  (%.0f%%)",cur,max,percent)
 elseif public(cur) and public(max) then b.text:SetFormattedText("%d / %d  (%.0f%%)",cur,max,max>0 and cur/max*100 or 0)
 else b.text:SetFormattedText("%d / %d",cur,max) end
end
function P.Update(unit)
 local f=P.frames[unit];if not f or not UnitExists(unit) then return end
 local name,surname=UnitName(unit)
 if public(name) and public(surname) and name and surname and surname~="" then name=name.." "..surname end
 f.name:SetText(name);f.level:SetText(UnitLevel(unit))
 P.StyleRole(f,P.Role(unit))
 value(f.health,unit,true);value(f.power,unit,false)
 local _,token=UnitPowerType(unit);local powerColor=public(token) and PowerBarColor[token] or PowerBarColor.MANA
 if powerColor then f.power:SetStatusBarColor(powerColor.r,powerColor.g,powerColor.b) end
 if public(token) and token=="MANA" then f.power:SetStatusBarColor(.05,.30,.85) end
 if UnitIsConnected then
  local connected=UnitIsConnected(unit)
  if public(connected) and not connected then f.health.text:SetText("Offline");return end
 end
 if UnitIsDeadOrGhost then
  local dead=UnitIsDeadOrGhost(unit);if public(dead) and dead then f.health.text:SetText("Dead") end
 end
end
-- Identity fields can become secret. Never compare restricted GUIDs or reuse a
-- row index from a sorted meter. Numeric rates pass directly to native text APIs.
function P.ReadRates(metric)
 local dm=C_DamageMeter;local en=Enum and Enum.DamageMeterType;local st=Enum and Enum.DamageMeterSessionType
 if not dm or not dm.GetCombatSessionFromType or not en or not st then return nil end
 local ok,session=pcall(dm.GetCombatSessionFromType,st.Current,metric=="dps" and en.DamageDone or en.HealingDone)
 if not ok or not session or not session.combatSources then return nil end
 local rates={};local unknown=false
 for _,row in ipairs(session.combatSources) do
  if public(row.sourceGUID) then
   if row.sourceGUID then rates[row.sourceGUID]=row.amountPerSecond end
  else unknown=true end
 end
 return rates,unknown
end
function P.UpdateRates()
 for _,metric in ipairs({"dps","hps"}) do
  local rates,unknown=P.ReadRates(metric)
  for unit,f in pairs(P.frames) do
   if UnitExists(unit) then
    local guid=UnitGUID(unit)
    if rates and public(guid) and guid then
     local rate=rates[guid]
     if not public(rate) or type(rate)=="number" then f[metric]:SetFormattedText("%.0f "..metric:upper(),rate)
     elseif not unknown then f[metric]:SetText("0 "..metric:upper())
     else f[metric]:SetText("-- "..metric:upper()) end
    else f[metric]:SetText("-- "..metric:upper()) end
   end
  end
 end
end
function P.NativeFrames()
 if not P.hidden then P.hidden=CreateFrame("Frame");P.hidden:Hide() end
 for _,name in ipairs({"PartyFrame","CompactPartyFrame","PartyMemberFrame1","PartyMemberFrame2","PartyMemberFrame3","PartyMemberFrame4"}) do
  local f=_G[name];if f then f:SetParent(P.hidden) end
 end
 -- Blizzard shares this container between raid-style parties and real raids.
 -- Keep its raid rendering intact, hiding only its party presentation.
 if CompactRaidFrameContainer then
  if not P.raidGate then
   P.raidGate=CreateFrame("Frame","ApexNativeRaidGate",UIParent,"SecureHandlerStateTemplate")
   P.raidGate:SetAllPoints(UIParent)
   RegisterStateDriver(P.raidGate,"visibility","[group:raid] show; hide")
  end
  CompactRaidFrameContainer:SetParent(P.raidGate)
  if CompactRaidFrameManager then CompactRaidFrameManager:SetParent(P.raidGate) end
 end
end
function P.Apply()
 if InCombatLockdown() then P.pending=true;return end
 if not A.ready or not A.OwnActive() or B.conflict then return end
 P.pending=nil;local s=settings()
 if not P.host then P.host=CreateFrame("Frame","ApexPartyAnchor",UIParent);P.host:SetFrameStrata("LOW") end
 P.host:SetSize(s.width*s.scale,(s.height*4+s.gap*3)*s.scale);B.Position(P.host,s.position)
 for i=1,4 do
  local unit="party"..i;local f=P.frames[unit] or create(i,false,P.host);P.frames[unit]=f
  f:SetScale(s.scale);f:SetSize(s.width,s.height)
  P.Update(unit)
 end
 for index,unit in ipairs(P.Order()) do
  local f=P.frames[unit];f:ClearAllPoints();f:SetPoint("TOPLEFT",P.host,"TOPLEFT",0,-(index-1)*(s.height+s.gap))
 end
 P.NativeFrames();P.UpdateRates()
 if A.RegisterMover then A.RegisterMover("party",P.host,"Party frames",s,"position") end
end
function P.Preview(show)
 if InCombatLockdown() then print("ApexUI: preview party frames after combat.");return end
 P.Apply()
 if not P.preview then
  P.preview=CreateFrame("Frame","ApexPartyPreview",UIParent);P.preview:SetFrameStrata("DIALOG")
  P.preview.title=label(P.preview,14);P.preview.title:SetPoint("BOTTOMLEFT",P.preview,"TOPLEFT",0,7);P.preview.title:SetText("PARTY PREVIEW | /apexparty hide")
  for i=1,4 do P.previewFrames[i]=create(i,true,P.preview) end
 end
 if show==nil then show=not P.preview:IsShown() end
 if not show then P.preview:Hide();return end
 local s=settings();P.preview:SetSize(s.width*s.scale,(s.height*4+s.gap*3)*s.scale);B.Position(P.preview,s.position)
 local names={"Vanguard","Dawnweaver","Stormcaller","Shadowblade"}
 local previewRoles={"TANK","HEALER","DAMAGER","DAMAGER"}
 for i,f in ipairs(P.previewFrames) do
  f:SetScale(s.scale);f:SetSize(s.width,s.height);f:ClearAllPoints();f:SetPoint("TOPLEFT",P.preview,"TOPLEFT",0,-(i-1)*(s.height+s.gap))
  f.name:SetText(names[i]);f.level:SetText("60")
  P.StyleRole(f,previewRoles[i])
  f.health:SetMinMaxValues(0,10000);f.health:SetValue(10000-i*1200);f.health.text:SetFormattedText("%d / 10000  (%d%%)",10000-i*1200,100-i*12)
  f.power:SetMinMaxValues(0,7000);f.power:SetValue(7000-i*900);f.power.text:SetFormattedText("%d / 7000",7000-i*900)
  f.dps:SetFormattedText("%d DPS",i==2 and 80 or 280+i*185);f.hps:SetFormattedText("%d HPS",i==2 and 1240 or 0)
  if A.PvP then
   if i==1 then f.health:SetValue(1800);f.health.text:SetText("1800 / 10000  (18%)") end
   if i==2 then f.health:SetValue(0);f.health.text:SetText("Dead") end
   A.PvP.Preview(f,i)
  end
 end
 P.preview:Show()
end
B.RegisterRenderer("party",P.Apply)
SLASH_APEXPARTY1="/apexparty"
SlashCmdList.APEXPARTY=function(input)
 input=(input or ""):lower()
 if input=="preview" then P.Preview(true)
 elseif input=="hide" then P.Preview(false)
 elseif input=="larger" or input=="smaller" then
  if InCombatLockdown() then print("ApexUI: resize party frames after combat.");return end
  local s=settings();s.width=math.max(380,math.min(500,s.width+(input=="larger" and 20 or -20)));P.Apply()
  if P.preview and P.preview:IsShown() then P.Preview(true) end
 else print("ApexUI party: /apexparty preview | hide | larger | smaller. Move with /apexui unlock.") end
end
local events=CreateFrame("Frame");P.events=events
for _,event in ipairs({"PLAYER_ENTERING_WORLD","GROUP_ROSTER_UPDATE","PLAYER_ROLES_ASSIGNED","ROLE_CHANGED_INFORM","PLAYER_REGEN_ENABLED","PLAYER_REGEN_DISABLED","UNIT_HEALTH","UNIT_MAXHEALTH","UNIT_POWER_UPDATE","UNIT_MAXPOWER","UNIT_DISPLAYPOWER","UNIT_NAME_UPDATE","UNIT_LEVEL","UNIT_CONNECTION","UNIT_FLAGS","ADDON_LOADED"}) do events:RegisterEvent(event) end
events:SetScript("OnEvent",function(_,event,unit)
 if not A.ready then return end
 if event=="PLAYER_REGEN_DISABLED" then if P.preview then P.preview:Hide() end
 elseif P.frames[unit] then P.Update(unit)
 elseif event=="PLAYER_ENTERING_WORLD" or event=="GROUP_ROSTER_UPDATE" or event=="PLAYER_ROLES_ASSIGNED" or event=="ROLE_CHANGED_INFORM" or event=="PLAYER_REGEN_ENABLED" or event=="ADDON_LOADED" then P.Apply() end
end)
local elapsed=0
events:SetScript("OnUpdate",function(_,dt)
 elapsed=elapsed+dt;if elapsed<.5 then return end;elapsed=0
 if A.ready and IsInGroup() and not IsInRaid() then P.UpdateRates() end
end)
