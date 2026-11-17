local _,A=...
local F=A.Frames
function F.SetBarValue(bar,value,maximum)
 local interpolation=Enum and Enum.StatusBarInterpolation
 local db=ApexUIDB and F.Settings()
 local snap=not bar.apexInitialized or (db and db.motion==false)
 -- Range changes (level-up, gear, power type) and zero snap immediately.
 -- Restricted values go straight to native rendering, never Lua arithmetic.
 if F.Public(value) and value==0 then snap=true end
 if F.Public(maximum) then
  if bar.apexMaximum~=maximum then snap=true end
  bar.apexMaximum=maximum
 else bar.apexMaximum=nil end
 bar:SetMinMaxValues(0,maximum)
 -- Public values use a short explicit tween, including clients where the
 -- interpolation enum exists but StatusBar:SetValue ignores its second arg.
 if F.Public(value) and F.Public(maximum) then
  if snap then
   bar:SetScript("OnUpdate",nil);bar.apexDisplayed=value;bar:SetValue(value,interpolation and interpolation.Immediate)
  elseif bar.apexTarget~=value then
   local from=bar.apexDisplayed or value
   bar.apexTarget=value;bar.apexElapsed=0
   bar:SetScript("OnUpdate",function(self,elapsed)
    self.apexElapsed=self.apexElapsed+elapsed
    local t=math.min(1,self.apexElapsed/.28)
    local shown=from+(value-from)*(1-(1-t)^3)
    self.apexDisplayed=shown;self:SetValue(shown,interpolation and interpolation.Immediate)
    if t>=1 then self:SetScript("OnUpdate",nil) end
   end)
  end
  bar.apexTarget=value
 else
  bar:SetScript("OnUpdate",nil);bar.apexDisplayed=nil;bar.apexTarget=nil
  if interpolation then bar:SetValue(value,snap and interpolation.Immediate or interpolation.ExponentialEaseOut)
  else bar:SetValue(value) end
 end
 bar.apexInitialized=true
end
local function createBar(f)
 local b=CreateFrame("StatusBar",nil,f)
 b:SetFrameLevel(f:GetFrameLevel()+2);b:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
 local bg=b:CreateTexture(nil,"BACKGROUND");b.bg=bg;bg:SetAllPoints();bg:SetColorTexture(.035,.03,.025,1)
 b.text=F.Text(b,18);b.text:SetPoint("CENTER")
 b.percent=F.Text(b,13);b.percent:SetPoint("CENTER",b,"CENTER",0,-13);b.percent:Hide();return b
end
local function refreshPortrait(f)
 SetPortraitTexture(f.face,f.unit,true);f.face:SetTexCoord(.05,.95,.05,.95)
end
function F.UpdateXP(f)
 local cur,max
 if f.unit=="player" then cur,max=UnitXP("player"),UnitXPMax("player")
 elseif select(2,UnitClass("player"))=="HUNTER" and GetPetExperience then cur,max=GetPetExperience() end
 cur,max=cur or 0,max or 0
 if not F.Public(cur) or not F.Public(max) then return end
 F.SetBarValue(f.xp,cur,math.max(1,max))
 if max>0 then f.xp.text:SetFormattedText("%d / %d  (%.1f%%)",cur,max,cur/max*100)
 elseif f.unit=="player" then f.xp.text:SetText("Level cap")
 else f.xp.text:SetText("Companion") end
end
local function barText(bar,value,maximum,percent)
 if bar.splitText then
  bar.text:SetFormattedText("%d / %d",value,maximum)
  bar.percent:SetFormattedText("%.0f%%",percent)
 else bar.text:SetFormattedText("%d/%d  (%.0f%%)",value,maximum,percent) end
 -- Never measure restricted text. Public large values shrink within a fixed
 -- text area instead of escaping the artwork at four/five/six digits.
 if F.Public(value) and F.Public(maximum) then
  local size=bar.baseFont or 18;bar.text:SetFont(F.FONT,size,"OUTLINE")
  local measured=bar.text:GetStringWidth()
  if type(measured)=="number" and measured>bar:GetWidth()-12 then
   bar.text:SetFont(F.FONT,math.max(10,size*(bar:GetWidth()-12)/measured),"OUTLINE")
  end
 end
end
function F.Update(unit)
 local f=F.units[unit];if not f then return end
 local hp,hmax=UnitHealth(unit),UnitHealthMax(unit)
 F.SetBarValue(f.health,hp,hmax)
 if F.Public(hp) and F.Public(hmax) then
  barText(f.health,hp,hmax,hmax>0 and hp/hmax*100 or 0)
 elseif UnitHealthPercent and CurveConstants then
  barText(f.health,hp,hmax,UnitHealthPercent(unit,false,CurveConstants.ScaleTo100))
 end
 local power,pmax=UnitPower(unit),UnitPowerMax(unit)
 F.SetBarValue(f.power,power,pmax)
 if F.Public(power) and F.Public(pmax) then
  barText(f.power,power,pmax,pmax>0 and power/pmax*100 or 0)
 elseif UnitPowerPercent and CurveConstants then
  barText(f.power,power,pmax,UnitPowerPercent(unit,nil,false,CurveConstants.ScaleTo100))
 end
 local _,token=UnitPowerType(unit)
 local c=F.Public(token) and PowerBarColor[token] or PowerBarColor.MANA
 if c then f.power:SetStatusBarColor(c.r,c.g,c.b) end
 if F.Public(token) and token=="MANA" then f.power:SetStatusBarColor(.05,.30,.85) end
 local name,surname=UnitName(unit)
 if F.Public(name) and F.Public(surname) and name and surname and surname~="" then name=name.." "..surname end
 f.name:SetText(name);f.level:SetText(UnitLevel(unit))
 F.UpdateXP(f)
end
local function create(unit)
 local f=CreateFrame("Button","ApexPortraitFrame_"..unit,UIParent,"SecureUnitButtonTemplate")
 f.unit=unit;f:SetFrameStrata("LOW");f:SetFrameLevel(12)
 f:SetAttribute("unit",unit);f:SetAttribute("type1","target");f:SetAttribute("type2","togglemenu")
 f:RegisterForClicks("AnyUp")
 f.face=f:CreateTexture(nil,"BACKGROUND");f.mask=f:CreateMaskTexture()
 f.mask:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask","CLAMPTOBLACKADDITIVE","CLAMPTOBLACKADDITIVE")
 f.face:AddMaskTexture(f.mask)
 f.art=f:CreateTexture(nil,"ARTWORK");f.art:SetAllPoints()
 f.health=createBar(f);f.health:SetStatusBarColor(.65,.045,.055)
 f.power=createBar(f);f.xp=createBar(f);f.xp:SetStatusBarColor(.02,.64,.87)
 f.labelHost=CreateFrame("Frame",nil,f);f.labelHost:SetAllPoints();f.labelHost:SetFrameLevel(f:GetFrameLevel()+5)
 f.name=F.Text(f.labelHost,18);f.name:SetJustifyH("LEFT")
 f.level=F.Text(f.labelHost,16);f.level:SetJustifyH("RIGHT")
 f:SetScript("OnEnter",function(self) GameTooltip:SetOwner(self,"ANCHOR_RIGHT");GameTooltip:SetUnit(unit);GameTooltip:Show() end)
 f:SetScript("OnLeave",function() GameTooltip:Hide() end)
 f:HookScript("OnShow",function() F.Update(unit);refreshPortrait(f) end)
 F.units[unit]=f;return f
end
local function extendPlayerBars(f,kind,width,height)
 if f.unit~="player" then return end
 local g=F.geometry[kind];local extra=g.health[3]*width
 local health={unpack(g.health)};local power={unpack(g.power)}
 health[3]=health[3]*2;power[3]=power[3]*2
 if kind=="split" then health[1]=health[1]-g.health[3] end
 F.Place(f.health,f,health);F.Place(f.power,f,power)
 -- Render the existing art in slices. Only the bar strip grows; the name,
 -- portrait, XP strip and unit anchor keep their original geometry.
 f.art:Hide();f.barArt=f.barArt or {}
 local asset=F.assets[kind];local slices={}
 local top,bottom=kind=="split" and .32 or .29,kind=="split" and .78 or .71
 slices[#slices+1]={0,1,0,top,0,1}
 slices[#slices+1]={0,1,bottom,1,0,1}
 local e=extra/width
 if kind=="split" then
  slices[#slices+1]={0,.10,top,bottom,-e,.10}
  slices[#slices+1]={.10,.35,top,bottom,.10-e,.25+e}
  slices[#slices+1]={.35,.65,top,bottom,.35,.30}
  slices[#slices+1]={.65,.90,top,bottom,.65,.25+e}
  slices[#slices+1]={.90,1,top,bottom,.90+e,.10}
 else
  slices[#slices+1]={0,.29,top,bottom,0,.29}
  slices[#slices+1]={.29,.96,top,bottom,.29,.67+e}
  slices[#slices+1]={.96,1,top,bottom,.96+e,.04}
 end
 for i,r in ipairs(slices) do
  local t=f.barArt[i] or f:CreateTexture(nil,"ARTWORK");f.barArt[i]=t
  t:SetTexture(F.MEDIA..kind..".tga");t:SetTexCoord(r[1]*asset.u,r[2]*asset.u,r[3]*asset.v,r[4]*asset.v)
  t:ClearAllPoints();t:SetPoint("TOPLEFT",f,"TOPLEFT",r[5]*width,-r[3]*height)
  t:SetSize(r[6]*width,(r[4]-r[3])*height);t:Show()
 end
 for i=#slices+1,#f.barArt do f.barArt[i]:Hide() end
end
local function style(f,kind,width,height,x,y)
 local g=F.geometry[kind]
 f:SetSize(width,height);f:ClearAllPoints();f:SetPoint("BOTTOM",UIParent,"BOTTOMLEFT",x,y)
 local asset=F.assets[kind]
 f.art:SetTexture(F.MEDIA..kind..".tga");f.art:SetTexCoord(0,asset.u,0,asset.v)
 F.Place(f.health,f,g.health);F.Place(f.power,f,g.power);F.Place(f.xp,f,g.xp)
 F.Place(f.name,f,g.name);F.Place(f.level,f,g.level)
 extendPlayerBars(f,kind,width,height)
 local d=g.face[3]*width
 f.face:ClearAllPoints();f.face:SetSize(d,d);f.face:SetPoint("CENTER",f,"TOPLEFT",g.face[1]*width,-g.face[2]*height)
 f.mask:ClearAllPoints();f.mask:SetAllPoints(f.face)
 for _,bar in ipairs({f.health,f.power}) do
  if bar.wingMask then
   local texture=bar:GetStatusBarTexture()
   texture:RemoveMaskTexture(bar.wingMask);bar.bg:RemoveMaskTexture(bar.wingMask)
  end
  bar.splitText=kind=="split";bar.baseFont=(kind=="iron" and 16 or 20)+(F.Settings().textOffset or 0)
  bar.text:ClearAllPoints();bar.text:SetPoint("CENTER",bar,"CENTER",0,bar.splitText and 7 or 0)
  bar.text:SetFont(F.FONT,bar.baseFont,"OUTLINE");bar.percent:SetShown(bar.splitText)
  if bar.splitText then
   -- Native status textures preserve alpha correctly on this client; applying a
   -- separate custom mask to a StatusBar texture made the entire fill disappear.
   bar:SetStatusBarTexture(F.MEDIA.."wing-fill.tga")
   bar.bg:SetTexture(F.MEDIA.."wing-mask.tga");bar.bg:SetVertexColor(.035,.03,.025,1)
   if bar==f.power then
    bar:GetStatusBarTexture():SetTexCoord(1,0,0,1);bar.bg:SetTexCoord(1,0,0,1)
   end
  else
   bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
   bar.bg:SetColorTexture(.035,.03,.025,1)
  end
 end
 f.health:SetStatusBarColor(.65,.045,.055)
 f.xp.text:SetFont(F.FONT,12,"OUTLINE")
 f.name:SetFont(F.FONT,kind=="iron" and 16 or 18,"OUTLINE")
 refreshPortrait(f);F.Update(f.unit)
end
function F.Apply()
 if InCombatLockdown() then F.pending=true;return end
 if not A.ready or (A.OwnActive and not A.OwnActive()) or (A.Backend and A.Backend.conflict) then return end
 ApexUIDB.portraitFrames=ApexUIDB.portraitFrames or {enabled=true,mode="auto",scale=1}
 local db=F.Settings()
 if not db or db.enabled==false then return end
 local _,class=UnitClass("player")
 local center,top=F.BarBounds()
 local layout=F.ResolveLayout(class,UnitExists("pet"),db.mode or "auto",center,top,db.scale or 1,db.density)
 F.layout=layout
 local p=F.units.player or create("player")
 local pet=F.units.pet or create("pet")
 style(p,layout.style,layout.width,layout.height,layout.x,layout.y)
 local petWidth=(db.density=="roomy" and 420 or 400)*(db.scale or 1)
 style(pet,"iron",petWidth,petWidth/3,layout.petX,layout.y)
 RegisterUnitWatch(p)
 if layout.paired then RegisterUnitWatch(pet) else UnregisterUnitWatch(pet);pet:Hide() end
 if F.ApplyAuras then F.ApplyAuras() end
 if F.SuppressLegacy then F.SuppressLegacy() end
 if F.ApplyBarTrim then F.ApplyBarTrim() end
 F.ready=true
end
local events=CreateFrame("Frame")
for _,e in ipairs({"PLAYER_ENTERING_WORLD","PLAYER_REGEN_ENABLED","UNIT_HEALTH","UNIT_MAXHEALTH","UNIT_POWER_UPDATE","UNIT_POWER_FREQUENT","UNIT_MAXPOWER","UNIT_DISPLAYPOWER","UNIT_NAME_UPDATE","UNIT_LEVEL","UNIT_PORTRAIT_UPDATE","UNIT_MODEL_CHANGED","UNIT_PET","PLAYER_XP_UPDATE","UPDATE_EXHAUSTION","UNIT_PET_EXPERIENCE","PLAYER_LEVEL_UP","EDIT_MODE_LAYOUTS_UPDATED"}) do events:RegisterEvent(e) end
events:SetScript("OnEvent",function(_,event,unit)
 if not ApexUIDB then return end
 ApexUIDB.portraitFrames=ApexUIDB.portraitFrames or {enabled=true,mode="auto",scale=1}
 if event=="PLAYER_ENTERING_WORLD" then C_Timer.After(2,F.Apply);C_Timer.After(5,F.Apply)
 elseif event=="PLAYER_REGEN_ENABLED" then if F.pending then F.pending=nil;F.Apply() end
 elseif event=="UNIT_PET" or event=="EDIT_MODE_LAYOUTS_UPDATED" then C_Timer.After(.1,F.Apply)
 elseif event=="UNIT_PORTRAIT_UPDATE" or event=="UNIT_MODEL_CHANGED" then if F.units[unit] then refreshPortrait(F.units[unit]) end
 elseif F.units[unit] then F.Update(unit)
 else F.Update("player");F.Update("pet") end
end)
SLASH_APEXPORTRAITFRAMES1="/apexframes"
SlashCmdList.APEXPORTRAITFRAMES=function(input)
 local mode=input:lower():match("^%s*(%S+)") or ""
 if mode=="solo" or mode=="paired" or mode=="auto" then
  F.Settings().mode=mode;F.Apply();print("ApexUI frames: "..mode)
 elseif mode=="compact" or mode=="roomy" then
  F.Settings().density=mode;F.Apply();print("ApexUI frame spacing: "..mode)
 elseif mode=="larger" or mode=="smaller" then
  local db=F.Settings();db.scale=math.max(.7,math.min(1.4,(db.scale or 1)+(mode=="larger" and .05 or -.05)));F.Apply()
 elseif mode=="off" or mode=="on" then
  if InCombatLockdown() then print("ApexUI: finish combat before changing frame ownership.");return end
  F.Settings().enabled=mode=="on";ReloadUI()
 elseif mode=="motionoff" or mode=="motionon" then
  F.Settings().motion=mode=="motionon";F.Update("player");F.Update("pet")
  print("ApexUI frame motion: "..(mode=="motionon" and "on" or "off"))
 elseif mode=="trimoff" or mode=="trimon" then
  F.Settings().barTrim=mode=="trimon";F.Apply()
  print("ApexUI action bar trim: "..(mode=="trimon" and "on" or "off"))
 elseif mode=="status" then
  local l=F.layout
  print("ApexUI frames: "..(F.ready and "loaded" or "waiting")..", "..(l and l.style or "unknown")..", "..(l and string.format("center %.1f, baseline %.1f",l.x,l.y) or ""))
 else print("ApexUI frames: /apexframes auto | solo | paired | compact | roomy | larger | smaller | motionon | motionoff | trimon | trimoff | status | off | on") end
end
