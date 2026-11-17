local _,A=...
local F=A.Frames
local function update(button)
 local h=button:GetParent();local index=button.index
 if not index or not C_UnitAuras then return end
 local unit,filter=h.unit,h.filter
 local aura=C_UnitAuras.GetAuraDataByIndex(unit,index,filter)
 if not aura then button:Hide();button.cooldown:Clear();return end
 button:Show()
 button.icon:SetTexture(aura.icon)
 if C_UnitAuras.GetAuraApplicationDisplayCount then button.count:SetText(C_UnitAuras.GetAuraApplicationDisplayCount(unit,aura.auraInstanceID,2,99))
 else button.count:SetText(aura.applications) end
 local duration=C_UnitAuras.GetAuraDuration and C_UnitAuras.GetAuraDuration(unit,aura.auraInstanceID)
 if duration and button.cooldown.SetCooldownFromDurationObject then button.cooldown:SetCooldownFromDurationObject(duration)
 elseif F.Public(aura.duration) and F.Public(aura.expirationTime) and aura.duration and aura.duration>0 then
  button.cooldown:SetCooldown(aura.expirationTime-aura.duration,aura.duration)
 else button.cooldown:Clear() end
 if filter=="HARMFUL" then button:SetBackdropBorderColor(.85,.12,.12,1) else button:SetBackdropBorderColor(.65,.48,.24,1) end
end
function ApexPortraitAura_OnLoad(b)
 b:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
 b:SetBackdropColor(.03,.03,.03,1)
 b.icon=b:CreateTexture(nil,"ARTWORK");b.icon:SetPoint("TOPLEFT",2,-2);b.icon:SetPoint("BOTTOMRIGHT",-2,2);b.icon:SetTexCoord(.07,.93,.07,.93)
 b.cooldown=CreateFrame("Cooldown",nil,b,"CooldownFrameTemplate");b.cooldown:SetAllPoints(b.icon);b.cooldown:SetHideCountdownNumbers(false)
 b.count=F.Text(b,11);b.count:SetPoint("BOTTOMRIGHT",0,0)
 b:RegisterForClicks("RightButtonUp")
 b:SetScript("OnEnter",function(self)
  local h=self:GetParent();GameTooltip:SetOwner(self,"ANCHOR_TOP");GameTooltip:SetUnitAura(h.unit,self.index,h.filter);GameTooltip:Show()
 end)
 b:SetScript("OnLeave",function() GameTooltip:Hide() end)
 b:SetScript("OnClick",function(self)
  local h=self:GetParent()
  if h.unit=="player" and h.filter=="HELPFUL" and not InCombatLockdown() and CancelUnitBuff then CancelUnitBuff("player",self.index,"HELPFUL") end
 end)
end
function F.ApplyAuras()
 for _,unit in ipairs({"player","pet"}) do
  local f=F.units[unit]
  for _,filter in ipairs({"HELPFUL","HARMFUL"}) do
   local key=unit..filter;local h=F.headers[key]
   if not h then
    -- This client has no SecureAuraHeaderTemplate. Preallocate ordinary display
    -- buttons; aura changes may then update safely without protected attributes.
    h=CreateFrame("Frame","ApexPortraitAuras_"..key,f);F.headers[key]=h
    h.unit=unit;h.filter=filter;h.buttons={};h:SetSize(288,32)
    for i=1,(filter=="HELPFUL" and 16 or 8) do
     local b=CreateFrame("Button",nil,h,"BackdropTemplate");b.index=i;b:SetSize(32,32)
     b:SetPoint("BOTTOMLEFT",h,"BOTTOMLEFT",((i-1)%8)*36,math.floor((i-1)/8)*40)
     ApexPortraitAura_OnLoad(b);h.buttons[i]=b
    end
   end
   local size=F.Settings().auraSize or 32
   h:SetSize(8*(size+4),size)
   for i,b in ipairs(h.buttons) do
    b:SetSize(size,size);b:ClearAllPoints()
    b:SetPoint("BOTTOMLEFT",h,"BOTTOMLEFT",((i-1)%8)*(size+4),math.floor((i-1)/8)*(size+8))
   end
   h:ClearAllPoints()
   h:SetPoint("BOTTOMLEFT",f,"TOPLEFT",f:GetWidth()*.28,filter=="HELPFUL" and 8 or (size+8)*2+12)
   h:Show()
   for _,child in ipairs(h.buttons) do update(child) end
  end
 end
end
local events=CreateFrame("Frame");events:RegisterEvent("UNIT_AURA")
events:SetScript("OnEvent",function(_,_,unit)
 for _,filter in ipairs({"HELPFUL","HARMFUL"}) do local h=F.headers[unit..filter]
  if h then for _,child in ipairs(h.buttons) do update(child) end end
 end
end)
