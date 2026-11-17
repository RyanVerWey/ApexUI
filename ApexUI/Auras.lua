local _,A=...
local B=A.Backend
local headers={}
local function update(h)
 if not C_UnitAuras then return end
 for i,b in ipairs(h.buttons) do
  local aura=i<=h.limit and C_UnitAuras.GetAuraDataByIndex(h.unit,i,h.filter)
  b:SetShown(not not aura)
  if aura then
   b.icon:SetTexture(aura.icon);b.count:SetText(aura.applications)
   local duration=C_UnitAuras.GetAuraDuration and C_UnitAuras.GetAuraDuration(h.unit,aura.auraInstanceID)
   if duration and b.cooldown.SetCooldownFromDurationObject then b.cooldown:SetCooldownFromDurationObject(duration)
   elseif A.Frames.Public(aura.duration) and A.Frames.Public(aura.expirationTime) and aura.duration and aura.duration>0 then
    b.cooldown:SetCooldown(aura.expirationTime-aura.duration,aura.duration)
   else b.cooldown:Clear() end
  end
 end
end
function B.ApplyAuras()
 if InCombatLockdown() or not A.OwnActive() then return end
 local u=A.Active().addons.ApexUnits
 for _,unit in ipairs({"target","focus"}) do
  local f=B._ModuleNS.ApexUnits.frames[unit];local s=u[unit]
  if f then for _,filter in ipairs({"HELPFUL","HARMFUL"}) do
   local key=unit..filter;local h=headers[key]
   if not h then
    h=CreateFrame("Frame",nil,f);headers[key]=h;h.unit=unit;h.filter=filter;h.buttons={}
    for i=1,16 do
     local b=CreateFrame("Button",nil,h,"BackdropTemplate");b.index=i;h.buttons[i]=b
     ApexPortraitAura_OnLoad(b)
    end
   end
   local harmful=filter=="HARMFUL"
   h.filter=harmful and s.onlyPlayerDebuffs and "HARMFUL|PLAYER" or filter
   h.limit=math.min(16,(harmful and s.maxDebuffs or s.maxBuffs) or 6)
   local size=(harmful and s.debuffSize or s.buffSize) or 28
   h:SetSize(f:GetWidth(),size);h:ClearAllPoints()
   if unit=="target" then
    -- Keep both rows under the encounter frame and its reserved castbar lane.
    local buffSize=s.buffSize or 28
    h:SetPoint("TOPLEFT",f,"BOTTOMLEFT",20,-(harmful and (36+buffSize+8) or 36))
   else h:SetPoint("BOTTOMLEFT",f,"TOPLEFT",0,harmful and 54 or 12) end
   for i,b in ipairs(h.buttons) do
    b:SetSize(size,size);b:ClearAllPoints();b:SetPoint("BOTTOMLEFT",h,"BOTTOMLEFT",(i-1)*(size+4),0)
    b:SetBackdropBorderColor(harmful and .85 or .65,harmful and .12 or .48,harmful and .12 or .24,1)
   end
   update(h)
  end end
 end
end
local e=CreateFrame("Frame")
for _,event in ipairs({"UNIT_AURA","PLAYER_TARGET_CHANGED","PLAYER_FOCUS_CHANGED"}) do e:RegisterEvent(event) end
e:SetScript("OnEvent",function(_,event,unit)
 for _,h in pairs(headers) do if event~="UNIT_AURA" or h.unit==unit then update(h) end end
end)
