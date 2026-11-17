local _, A = ...
A.VERSION = "0.3.0"
A.UF = "ApexUnits"
A.AB = "ApexBars"
A.classes = {
 WARRIOR={label="Warrior / tank",role="Tank",color={.78,.61,.43}},
 PRIEST={label="Priest / healer",role="Healer",color={.88,.86,.75}},
 HUNTER={label="Hunter / companion DPS",role="Pet DPS",pet=true,color={.67,.83,.45}},
 WARLOCK={label="Warlock / demon DPS",role="Pet DPS",pet=true,color={.65,.49,.90}},
 PALADIN={label="Paladin / DPS",role="DPS",color={.95,.55,.73}},
 MAGE={label="Mage / DPS",role="DPS",color={.35,.78,.94}},
 SHAMAN={label="Shaman / DPS",role="DPS",color={.25,.52,.94}},
 DRUID={label="Druid / DPS",role="DPS",color={1,.55,.20}},
 ROGUE={label="Rogue / DPS",role="DPS",color={.95,.84,.36}},
}
function A.Copy(v)
 if type(v)~="table" then return v end
 local r={}; for k,x in pairs(v) do r[k]=A.Copy(x) end; return r
end
function A.Merge(t, patch)
 for k,v in pairs(patch) do
  if type(v)=="table" then if type(t[k])~="table" then t[k]={} end; A.Merge(t[k],v)
  else t[k]=v end
 end
 return t
end
local function rgb(c) return {r=c[1],g=c[2],b=c[3]} end
local function position(x,y) return {point="CENTER",relPoint="CENTER",x=x,y=y} end
function A.ClassInfo(class) return A.classes[class] or {label=class or "Adventurer",role="DPS",color={.78,.68,.43}} end

function A.PlayerCenterOffset(s)
 local power=(s.powerPosition=="below" or s.powerPosition=="above") and (s.powerHeight or 0) or 0
 local header=(s.bottomTextBar and (s.btbPosition=="top" or s.btbPosition=="bottom")) and (s.bottomTextBarHeight or 0) or 0
 local canvas=((s.healthHeight or 36)+power+header+8)*128/94
 -- Portrait RIGHT sits 14px inside the bar's LEFT. The visible rim is .78 of its canvas.
 return (canvas*.89-14)/2
end

-- A scoped layout preset: preserve every action bar, pet placement and unrelated setting.
function A.CenterCombatLayout(profile)
 local p=A.Copy(profile);local u=p.addons[A.UF]
 local px=A.PlayerCenterOffset(u.player)
 local old=u.positions.player or {};local py=old.y or -268
 if old.point and old.point~="CENTER" then py=-268 end
 u.positions.player=position(px,py)
 u.positions.playerCastbar=position(px,py-59)
 local pab=u.playerAuraBars
 local top=py+((u.player.healthHeight or 36)+(u.player.powerHeight or 22)+(u.player.bottomTextBarHeight or 24))/2
 local left=px-u.player.frameWidth/2
 local buff=pab.defaultBuffs;local debuff=pab.defaultDebuffs
 buff.iconSize=28;buff.iconsPerRow=4;buff.maxRows=10;buff.maxTotal=40
 buff.growDirection="RIGHT";buff.iconWrapDirection="UP";buff.padding=4
 debuff.iconSize=30;debuff.iconsPerRow=4;debuff.maxRows=4;debuff.maxTotal=16
 debuff.growDirection="RIGHT";debuff.iconWrapDirection="UP";debuff.padding=4
 pab.buffsPos={point="BOTTOMLEFT",relPoint="CENTER",x=left,y=top+20,design=true}
 pab.debuffsPos={point="BOTTOMLEFT",relPoint="CENTER",x=left+148,y=top+20,design=true}
 u.target.frameWidth=420;u.target.healthHeight=30;u.target.powerHeight=14
 u.target.bottomTextBarHeight=22;u.target.btbLeftContent="none";u.target.btbCenterContent="name"
 u.target.btbCenterSize=17;u.target.btbCenterClassColor=true
 u.target.castbarWidth=420;u.target.castbarHeight=20
 u.target.buffOffsetX=0;u.target.buffOffsetY=-12
 u.positions.target={point="TOP",relPoint="TOP",x=0,y=-90}
 u.positions.targetCastbar={point="TOP",relPoint="TOP",x=0,y=-172}
 u.positions.focus={point="TOP",relPoint="TOP",x=0,y=-240}
 u.focus.powerPercentText="none";u.targettarget.powerPercentText="none"
 u.positions.focusCastbar={point="TOP",relPoint="TOP",x=0,y=-298}
 u.positions.targettarget={point="TOP",relPoint="TOP",x=230,y=-240}
 for _,key in ipairs({"player","playerCastbar","target","targetCastbar","focus","focusCastbar","targettarget","PAB_Buffs","PAB_Debuffs"}) do
  p.unlockLayout.anchors[key]=nil
 end
 return p
end

-- Only layout and presentation. Never touches spell slots, bindings or macros.
function A.BuildTemplate(base, class)
 local p=A.Copy(base); p.addons=p.addons or {}
 local u=p.addons[A.UF] or {}; p.addons[A.UF]=u
 local meta=A.ClassInfo(class); local accent=rgb(meta.color)
 local common={frameWidth=290,healthHeight=36,powerHeight=22,powerPosition="below",powerY=0,
  healthClassColored=false,healthColorMode="none",healthBarOpacity=100,
  customFillColor={r=.64,g=.12,b=.13},customBgColor={r=.085,g=.067,b=.055},
  powerClassColored=false,powerBarOpacity=100,powerPercentText="center",powerPercentSize=16,
  powerPercentPowerColor=true,powerPercentTextPowerColor=false,
  powerTextFormat="custom",powerTextCustomFormat="[pp]/[pp:max]  ([pp:pct]%)",
  leftTextContent="none",rightTextContent="none",centerTextContent="custom",
  centerTextCustomFormat="[hp]/[hp:max]  ([hp:pct]%)",centerTextSize=18,
  showPortrait=false,bottomTextBar=true,bottomTextBarHeight=24,btbPosition="top",
  btbLeftContent="name",btbLeftSize=16,btbLeftClassColor=true,
  btbRightContent="level",btbRightSize=14,btbCenterContent="none",
  btbBgColor={r=.075,g=.058,b=.045},btbBgOpacity=1,
  borderTexture="blizz",borderSize=3,borderColor=accent,borderPowerSeam=true,
  barVisibility="always",oocFadeEnabled=false,
  showBuffs=false,buffShowCooldownText=true,buffCooldownTextSize=14,
  debuffShowCooldownText=true,debuffCooldownTextSize=14,
  auraBorderTexture="blizz",auraBorderSize=2,
 }
 for _,unit in ipairs({"player","target","pet","focus","targettarget"}) do
  u[unit]=A.Merge(u[unit] or {},common)
  u[unit].customPowerFillColor=nil -- Preserve automatic rage, energy and focus colours.
 end
 -- Fixed-mana classes keep the requested blue. Shapeshifters retain automatic resources.
 if class~="WARRIOR" and class~="ROGUE" and class~="DRUID" then
  u.player.customPowerFillColor={r=.08,g=.32,b=.70}
  u.player.powerPercentPowerColor=false
 end
 u.healthBarTexture="matte"; u.castBarTexture="matte"
 u.castbarColor=accent
 u.player.showPlayerCastbar=true; u.player.lockCastbarToFrame=false
 u.player.playerCastbarWidth=290; u.player.playerCastbarHeight=20
 u.player.debuffAnchor="none"; u.player.showBuffs=false
 u.player.manaRegenSpark=true
 u.player.showClassPowerBar=true; u.player.classPowerStyle="modern"
 u.player.classPowerHeight=10; u.player.classPowerPosition="above"
 u.target.healthClassColored=true
 u.target.showBuffs=true; u.target.maxBuffs=8; u.target.buffSize=28
 u.target.buffAnchor="bottomleft"; u.target.buffOffsetY=-12;u.target.buffOffsetX=20
 u.target.debuffAnchor="topleft"; u.target.debuffOffsetY=16
 u.target.debuffSize=32; u.target.maxDebuffs=12; u.target.onlyPlayerDebuffs=true
 u.target.showCastbar=true; u.target.lockCastbarToFrame=false
 u.target.castbarWidth=290; u.target.castbarHeight=22
 u.pet.frameWidth=290
 u.pet.healthHeight=36
 u.pet.powerHeight=22; u.pet.centerTextSize=18
 u.pet.bottomTextBar=false -- Simple pet frames need ApexUI's own name strip.
 u.pet.centerTextContent="custom"; u.pet.leftTextContent="none"; u.pet.rightTextContent="none"
 u.pet.customFillColor={r=.28,g=.45,b=.16}; u.pet.lookSource="player"
 u.pet.showBuffs=true; u.pet.maxBuffs=6; u.pet.buffSize=28
 u.pet.buffAnchor="topleft"; u.pet.buffOffsetY=42
 u.pet.debuffAnchor="topright"; u.pet.maxDebuffs=4; u.pet.debuffSize=30; u.pet.debuffOffsetY=52
 u.pet.showCastbar=true; u.pet.lockCastbarToFrame=false; u.pet.castbarWidth=u.pet.frameWidth
 for _,unit in ipairs({"focus","targettarget"}) do
  u[unit].frameWidth=205; u[unit].healthHeight=28;u[unit].powerHeight=0
  u[unit].powerPosition="none"; u[unit].centerTextSize=15
  u[unit].btbLeftSize=14;u[unit].bottomTextBarHeight=20
 end
 u.targettarget.bottomTextBar=false
 u.targettarget.leftTextContent="name";u.targettarget.leftTextSize=14
 u.targettarget.centerTextContent="none";u.targettarget.rightTextContent="perhp"
 u.focus.showCastbar=true; u.focus.castbarWidth=205;u.focus.castbarHeight=18
 u.enabledFrames=u.enabledFrames or {}; u.enabledFrames.player=true;u.enabledFrames.target=true
 u.enabledFrames.pet=true -- The native secure unit watch hides the frame when no pet exists.
 u.enabledFrames.targettarget=false;u.enabledFrames.focus=true
 u.threatPctEnabled=(class=="WARRIOR");u.threatPctPosition="TOPRIGHT"
 u.threatPctYOffset=20;u.threatPctSize=14
 u.positions=u.positions or {}
 local px=meta.pet and -10 or -200; local tx=meta.pet and 350 or 200
 u.positions.player=position(px,-268)
 u.positions.target=position(tx,-268)
 u.positions.pet=position(-430,-280)
 u.positions.playerCastbar=position(px,-327)
 u.positions.targetCastbar=position(tx,-327)
 u.positions.petCastbar=position(-430,-327)
 u.positions.focus=position(480,-180)
 u.positions.focusCastbar=position(480,-218)
 u.positions.targettarget=position(480,-110)
 if class=="PRIEST" then u.target.healthHeight=42; u.target.onlyPlayerDebuffs=false end
 local pab=u.playerAuraBars or {};u.playerAuraBars=pab
 pab.enabled=true;pab.useBlizzardBuffs=false;pab.showText=true
 pab.durationTextSize=14;pab.stackTextSize=13;pab.durationPosition="BOTTOM"
 pab.defaultBuffs=A.Merge(pab.defaultBuffs or {},{enabled=true,showAllBuffs=true,iconSize=28,
  iconsPerRow=10,maxRows=4,maxTotal=40,padding=4,growDirection="RIGHT",iconWrapDirection="UP",durationTextSize=14,
  durationPosition="BOTTOM",borderTexture="blizz",borderSize=2,
  borderR=meta.color[1],borderG=meta.color[2],borderB=meta.color[3],borderA=1})
 pab.defaultDebuffs=A.Merge(pab.defaultDebuffs or {},{enabled=true,showAllDebuffs=true,iconSize=32,
  iconsPerRow=8,maxRows=2,maxTotal=16,padding=4,growDirection="RIGHT",iconWrapDirection="UP",durationTextSize=15,
  durationPosition="CENTER",borderTexture="blizz",borderSize=2,borderR=.9,borderG=.2,borderB=.15,borderA=1})
 -- Separate lanes grow up from the HUD. The target's own debuffs stay on the target frame.
 pab.buffsPos={point="BOTTOMLEFT",relPoint="CENTER",x=px-145,y=-132,design=true}
 pab.debuffsPos={point="BOTTOMLEFT",relPoint="CENTER",x=px-145,y=-206,design=true}
 p.unlockLayout=p.unlockLayout or {};p.unlockLayout.anchors=p.unlockLayout.anchors or {}
 p.unlockLayout.anchors.PAB_Buffs=nil;p.unlockLayout.anchors.PAB_Debuffs=nil
 for _,k in ipairs({"player","pet","target","targettarget","playerCastbar","petCastbar","targetCastbar"}) do
  p.unlockLayout.anchors[k]=nil
 end
 p.fonts=p.fonts or {};p.fonts.moduleFonts=p.fonts.moduleFonts or {}
 local found=false
 for _,v in ipairs(p.fonts.moduleFonts) do
  if v.folder==A.UF then v.font="Friz Quadrata";v.outline="none";found=true end
 end
 if not found then table.insert(p.fonts.moduleFonts,{folder=A.UF,font="Friz Quadrata",outline="none"}) end
 return A.CenterCombatLayout(p)
end
