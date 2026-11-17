local _,A=...
local B=A.Backend
local R={frames={},buttons={}};A.ActionBars=R
-- Stable action slots, independent of visual layout. Bar9 must never page MainBar.
R.definitions={
 {"MainBar",1,"ACTIONBUTTON"},{"Bar9",2},{"Bar4",3,"MULTIACTIONBAR3BUTTON"},
 {"Bar5",4,"MULTIACTIONBAR4BUTTON"},{"Bar3",5,"MULTIACTIONBAR2BUTTON"},
 {"Bar2",6,"MULTIACTIONBAR1BUTTON"},{"Bar6",13,"MULTIACTIONBAR5BUTTON"},
 {"Bar7",14,"MULTIACTIONBAR6BUTTON"},{"Bar8",15,"MULTIACTIONBAR7BUTTON"},{"Bar10",10},
}
local function renderButton(button)
 local slot=button:GetAttribute("action");if not slot then return end
 button.icon:SetTexture(GetActionTexture(slot))
 button:SetAlpha(button.hideEmpty and not GetActionTexture(slot) and 0 or 1)
 if IsUsableAction then
  local usable,mana=IsUsableAction(slot)
  if (not issecretvalue or (not issecretvalue(usable) and not issecretvalue(mana))) then
   if usable then button.icon:SetVertexColor(1,1,1)
   elseif mana then button.icon:SetVertexColor(.35,.45,1) else button.icon:SetVertexColor(.45,.45,.45) end
  end
 end
 local count=GetActionCount(slot)
 if not issecretvalue or not issecretvalue(count) then button.count:SetText(count and count>1 and count or "") else button.count:SetText(count) end
 button:SetChecked(IsCurrentAction(slot) or IsAutoRepeatAction(slot))
 if C_ActionBar and C_ActionBar.GetActionCooldownDuration and button.cooldown.SetCooldownFromDurationObject then
  local duration=C_ActionBar.GetActionCooldownDuration(slot)
  if duration then button.cooldown:SetCooldownFromDurationObject(duration) else button.cooldown:Clear() end
 elseif GetActionCooldown then
  local start,duration,enable=GetActionCooldown(slot)
  button.cooldown:SetCooldown(start,duration)
 end
end
local function button(header,key,index,slot)
 local f=CreateFrame("CheckButton","ApexAction_"..key.."_"..index,header,"SecureActionButtonTemplate,BackdropTemplate")
 f:SetAttribute("type","action");f:SetAttribute("action",slot);f:SetAttribute("checkselfcast",true);f:SetAttribute("checkfocuscast",true)
 f:RegisterForClicks("AnyUp","AnyDown");f:RegisterForDrag("LeftButton")
 f:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
 f:SetBackdropColor(.035,.03,.026,.85);f:SetBackdropBorderColor(.55,.43,.28,.8)
 f.icon=f:CreateTexture(nil,"ARTWORK");f.icon:SetPoint("TOPLEFT",2,-2);f.icon:SetPoint("BOTTOMRIGHT",-2,2);f.icon:SetTexCoord(.07,.93,.07,.93)
 f.cooldown=CreateFrame("Cooldown",nil,f,"CooldownFrameTemplate");f.cooldown:SetAllPoints(f.icon)
 f.cooldown:SetHideCountdownNumbers(false)
 f.count=B.Text(f,14);f.count:SetPoint("BOTTOMRIGHT",-3,3)
 f.key=B.Text(f,14);f.key:SetPoint("TOPRIGHT",-3,-3)
 f:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square","ADD")
 f:SetCheckedTexture("Interface\\Buttons\\CheckButtonHilight","ADD")
 f:SetPushedTexture("Interface\\Buttons\\UI-Quickslot-Depress")
 f:SetScript("OnAttributeChanged",function(self,name) if name=="action" and self.icon then renderButton(self) end end)
 f:SetScript("OnEnter",function(self) GameTooltip:SetOwner(self,"ANCHOR_TOP");GameTooltip:SetAction(self:GetAttribute("action"));GameTooltip:Show() end)
 f:SetScript("OnLeave",function() GameTooltip:Hide() end)
 f:SetScript("OnDragStart",function(self)
  if not InCombatLockdown() and (IsShiftKeyDown() or GetCVar("lockActionBars")~="1") then PickupAction(self:GetAttribute("action")) end
 end)
 f:SetScript("OnReceiveDrag",function(self) if not InCombatLockdown() then PlaceAction(self:GetAttribute("action")) end end)
 R.buttons[#R.buttons+1]=f;return f
end
local function create(def)
 local key,page=def[1],def[2]
 local f=CreateFrame("Frame","ApexBar_"..key,UIParent,"SecureHandlerStateTemplate")
 f.buttons={}
 for i=1,12 do f.buttons[i]=button(f,key,i,(page-1)*12+i);f:SetFrameRef("button"..i,f.buttons[i]) end
 if key=="MainBar" then
  f:SetAttribute("_onstate-page",[[
   local page=tonumber(newstate) or 1
   for i=1,12 do self:GetFrameRef("button"..i):SetAttribute("action",(page-1)*12+i) end
  ]])
  RegisterStateDriver(f,"page","[bonusbar:5]11;[bonusbar:4]10;[bonusbar:3]9;[bonusbar:2]8;[bonusbar:1]7;1")
 end
 RegisterStateDriver(f,"visibility","[petbattle]hide;show")
 R.frames[key]=f;return f
end
local function arrange(f,s)
 local n=math.min(s.numIcons or 12,#f.buttons);local rows=math.max(1,math.min(s.numRows or 1,n))
 local cols=math.ceil(n/rows);local w,h,g=s.buttonWidth or 50,s.buttonHeight or 50,s.buttonPadding or 1
 f:SetSize(cols*w+(cols-1)*g,rows*h+(rows-1)*g)
 local right=(s.iconOrder or ""):find("RIGHT",1,true);local top=(s.iconOrder or ""):find("TOP",1,true)
 for i,b in ipairs(f.buttons) do
  local col=(i-1)%cols;local row=math.floor((i-1)/cols)
  b:ClearAllPoints();b:SetSize(w,h)
  b:SetPoint(top and "TOPLEFT" or "BOTTOMLEFT",f,top and "TOPLEFT" or "BOTTOMLEFT",(right and cols-1-col or col)*(w+g),(top and -1 or 1)*row*(h+g))
  b:SetShown(i<=n)
  b.hideEmpty=s.alwaysShowButtons==false
  if b.hideEmpty and b.icon and not GetActionTexture(b:GetAttribute("action")) then b:SetAlpha(0) else b:SetAlpha(1) end
  if b.key then b.key:SetFont(A.FONT,s.keybindFontSize or 14,"OUTLINE") end
  if b.count then b.count:SetFont(A.FONT,s.countFontSize or 14,"OUTLINE") end
  if b.cooldown then
   b.cooldown:SetHideCountdownNumbers(s.showCooldownText==false)
   if b.cooldown.Text then b.cooldown.Text:SetFont(A.FONT,s.cooldownFontSize or 20,"OUTLINE") end
  end
 end
end
function R.Bindings()
 if InCombatLockdown() or not A.OwnActive() or B.conflict then return end
 R.bindingOwner=R.bindingOwner or CreateFrame("Frame")
 ClearOverrideBindings(R.bindingOwner)
 for _,def in ipairs(R.definitions) do
  local f=R.frames[def[1]]
  if f then for i,b in ipairs(f.buttons) do
   local keys=def[3] and {GetBindingKey(def[3]..i)} or {}
   -- Explicit Apex clicks remain ordinary saved WoW bindings.
   local direct={GetBindingKey("CLICK "..b:GetName()..":LeftButton")}
   for _,key in ipairs(direct) do keys[#keys+1]=key end
   for _,key in ipairs(keys) do SetOverrideBindingClick(R.bindingOwner,false,key,b:GetName(),"LeftButton") end
   b.key:SetText(keys[1] and GetBindingText(keys[1],"KEY_") or "")
  end end
 end
end
local function nativeStrip(key,prefix,count,s,position,visibility)
 local f=R.frames[key]
 if not f then f=CreateFrame("Frame","ApexBar_"..key,UIParent,"SecureHandlerStateTemplate");f.buttons={};R.frames[key]=f end
 if #f.buttons==0 then for i=1,count do local b=_G[prefix..i];if b then b:SetParent(f);f.buttons[#f.buttons+1]=b end end end
 if #f.buttons==0 then return end
 arrange(f,s);B.Position(f,position)
 RegisterStateDriver(f,"visibility",(s.alwaysHidden or s.barVisibility=="never" or s.enabled==false) and "hide" or visibility)
end
function R.Apply()
 if InCombatLockdown() or not A.OwnActive() or B.conflict then return end
 local profile=A.Active().addons.ApexBars
 for _,def in ipairs(R.definitions) do
  local key=def[1];local s=profile.bars[key];local f=R.frames[key] or create(def)
  arrange(f,s);B.Position(f,profile.barPositions[key])
  local hidden=s.alwaysHidden or s.barVisibility=="never" or s.enabled==false
  RegisterStateDriver(f,"visibility",hidden and "hide" or "[petbattle]hide;show")
  if A.RegisterMover then A.RegisterMover(key,f,key,profile.barPositions,key) end
  for _,b in ipairs(f.buttons) do renderButton(b) end
 end
 nativeStrip("PetBar","PetActionButton",10,profile.bars.PetBar,profile.barPositions.PetBar,"[pet,nopossessbar]show;hide")
 nativeStrip("StanceBar","StanceButton",10,profile.bars.StanceBar,profile.barPositions.StanceBar,(GetNumShapeshiftForms and GetNumShapeshiftForms()>0) and "show" or "hide")
 if BagsBar then BagsBar:SetParent(UIParent) end
 if MicroMenuContainer then MicroMenuContainer:SetParent(UIParent) end
 -- Native secure controls still handle extra actions, vehicles and possession.
 if not R.hidden then R.hidden=CreateFrame("Frame");R.hidden:Hide() end
 for _,name in ipairs({"MainActionBar","MultiBarBottomLeft","MultiBarBottomRight","MultiBarRight","MultiBarLeft","MultiBar5","MultiBar6","MultiBar7","StatusTrackingBarManager","MainMenuExpBar","ReputationWatchBar"}) do
  local f=_G[name];if f then f:SetParent(R.hidden) end
 end
 R.Bindings()
end
B.RegisterRenderer("bars",R.Apply)
local events=CreateFrame("Frame")
for _,event in ipairs({"ACTIONBAR_SLOT_CHANGED","ACTIONBAR_UPDATE_COOLDOWN","ACTIONBAR_UPDATE_STATE","ACTIONBAR_UPDATE_USABLE","UPDATE_BINDINGS","PLAYER_REGEN_ENABLED","PLAYER_ENTERING_WORLD"}) do events:RegisterEvent(event) end
events:SetScript("OnEvent",function(_,event)
 if B.conflict or not A.ready then return end
 if event=="UPDATE_BINDINGS" or event=="PLAYER_REGEN_ENABLED" then R.Bindings() end
 for _,b in ipairs(R.buttons) do renderButton(b) end
end)
