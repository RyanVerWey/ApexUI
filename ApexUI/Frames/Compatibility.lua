local _,A=...
local F=A.Frames
-- Coordinate owned bars and portrait frames without touching independent addons.
local function backend() return A.Backend end
local trim={}
function F.ApplyBarTrim()
 if InCombatLockdown() then F.pending=true;return end
 local enabled=F.Settings().barTrim~=false
 for _,key in ipairs({"MainBar","Bar9","Bar4","Bar5","Bar3","Bar10","PetBar","StanceBar"}) do
  local bar=_G["ApexBar_"..key]
  if bar then
   local plate=trim[bar]
   if not plate then
    -- Decorative child only. Follows bar size, scale and visibility without
    -- touching action assignments, secure buttons, cooldowns or drag behavior.
    plate=CreateFrame("Frame",nil,bar,"BackdropTemplate");trim[bar]=plate
    plate:EnableMouse(false);plate:SetFrameLevel(math.max(0,bar:GetFrameLevel()-1))
    plate:SetPoint("TOPLEFT",bar,"TOPLEFT",3,-1)
    plate:SetPoint("BOTTOMRIGHT",bar,"BOTTOMRIGHT",-3,1)
    plate:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1,insets={left=1,right=1,top=1,bottom=1}})
    plate:SetBackdropColor(.035,.030,.026,.92)
    plate:SetBackdropBorderColor(.55,.39,.19,.85)
    local top=plate:CreateTexture(nil,"BORDER")
    top:SetColorTexture(.76,.57,.30,.65);top:SetHeight(1)
    top:SetPoint("BOTTOMLEFT",bar,"TOPLEFT",0,2);top:SetPoint("BOTTOMRIGHT",bar,"TOPRIGHT",0,2)
    local bottom=plate:CreateTexture(nil,"BORDER")
    bottom:SetColorTexture(.47,.33,.16,.85);bottom:SetHeight(1)
    bottom:SetPoint("TOPLEFT",bar,"BOTTOMLEFT",0,-2);bottom:SetPoint("TOPRIGHT",bar,"BOTTOMRIGHT",0,-2)
   end
   plate:SetShown(enabled)
  end
 end
end
function F.BarBounds()
 local left,right,top
 for _,key in ipairs({"MainBar","Bar9","Bar4","Bar5","Bar3","Bar10"}) do
  local f=_G["ApexBar_"..key]
  if f and f:IsShown() and f:GetLeft() then
   local s=f:GetEffectiveScale()/UIParent:GetEffectiveScale()
   local l,r,t=f:GetLeft()*s,f:GetRight()*s,f:GetTop()*s
   left=left and math.min(left,l) or l;right=right and math.max(right,r) or r;top=top and math.max(top,t) or t
  end
 end
 return left and (left+right)/2 or UIParent:GetWidth()/2,top or 125
end
local suppressed={}
local hidden=CreateFrame("Frame");hidden:Hide()
local function suppress(f)
 if not f or suppressed[f] then return end
 suppressed[f]=true
 -- Reparenting also removes invisible child click targets. Castbars retain their
 -- independent anchors and continue working while the former unit artwork is hidden.
 f:SetParent(hidden)
end
function F.SuppressLegacy()
 if InCombatLockdown() then F.pending=true;return end
 local b=backend();local ns=b and b._ModuleNS and b._ModuleNS[A.UF]
 if ns and ns.frames then
  for _,unit in ipairs({"player","pet"}) do suppress(ns.frames[unit]) end
 end
 for _,name in ipairs({"ApexUIPetXP","ApexAuras_PlayerBuffs","ApexAuras_PlayerDebuffs","ApexAuras_petBuffs","ApexAuras_petDebuffs","ApexPlayerXP"}) do suppress(_G[name]) end
 -- Native frames are fallback competitors on a clean install.
 suppress(PlayerFrame);suppress(PetFrame);suppress(BuffFrame);suppress(DebuffFrame)
end
-- Do not hook these callbacks: this client rejects a hooked callback passed
-- directly to C_Timer.After by the existing suite. Native layout/pet events
-- and the bounded login retries refresh this feature without rewriting them.
