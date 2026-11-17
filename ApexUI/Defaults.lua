local _,A=...
local B=A.Backend
local function pos(point,x,y) return {point=point,relPoint=point,x=x,y=y} end
function B.FillDefaults(source)
 local ab={bars={},barPositions={}}
 for _,key in ipairs({"MainBar","Bar2","Bar3","Bar4","Bar5","Bar6","Bar7","Bar8","Bar9","Bar10","PetBar","StanceBar"}) do
  ab.bars[key]={buttonWidth=50,buttonHeight=50,buttonPadding=1,numRows=1,numIcons=12,
   showCooldownText=true,cooldownFontSize=20,keybindFontSize=14,countFontSize=14,hideMacroText=true,
   iconOrder="BOTTOMLEFT",alwaysShowButtons=true,barVisibility="always"}
  ab.barPositions[key]=pos("BOTTOM",0,14)
 end
 for _,key in ipairs({"Bar3","Bar6","Bar7","Bar8","Bar10"}) do
  ab.bars[key].alwaysHidden=true;ab.bars[key].barVisibility="never"
 end
 ab.barPositions.MainBar=pos("BOTTOM",-310,14);ab.barPositions.Bar9=pos("BOTTOM",312,14)
 ab.barPositions.Bar4=pos("BOTTOM",-310,73);ab.barPositions.Bar5=pos("BOTTOM",312,73)
 ab.bars.Bar2.buttonWidth=40;ab.bars.Bar2.buttonHeight=40;ab.bars.Bar2.numRows=12;ab.bars.Bar2.buttonPadding=4
 ab.barPositions.Bar2=pos("BOTTOM",650,14)
 ab.bars.PetBar.buttonWidth=26;ab.bars.PetBar.buttonHeight=26;ab.bars.PetBar.numIcons=10
 ab.barPositions.PetBar=pos("CENTER",-430,-394)
 ab.bars.StanceBar.buttonWidth=28;ab.bars.StanceBar.buttonHeight=28;ab.bars.StanceBar.numIcons=10
 ab.barPositions.StanceBar=pos("BOTTOM",-310,136)
 ab.bars.XPBar={width=290,height=16,textSize=12};ab.barPositions.XPBar=pos("CENTER",47.536,-371)
 local p={addons={ApexUnits={},ApexBars=ab,ApexMinimap={minimap={mapSize=374,position=pos("TOPRIGHT",-14,-14)}},
  ApexDataBars={bars={{id=1,name="Right status",visibility="always",thickness=25,length=605,
   savedPos=pos("BOTTOMRIGHT",-4,3),blocks={{type="durability"},{type="coords"},{type="fps"},{type="ms"},{type="gold"},{type="clock"}}}}}},
  unlockLayout={anchors={}},apexUtility=true}
 p=A.BuildTemplate(p,"HUNTER")
 p.addons.ApexUnits.positions.player.y=-318;p.addons.ApexUnits.positions.pet.y=-330
 p.addons.ApexUnits.positions.playerCastbar.y=-409;p.addons.ApexUnits.positions.petCastbar.y=-409
 A.Merge(p,source or {})
 for key,s in pairs(p.addons.ApexBars.bars) do
  if key~="XPBar" then
   local fallback=key=="PetBar" and 26 or key=="StanceBar" and 28 or 50
   if not s.buttonWidth or s.buttonWidth<=0 then s.buttonWidth=fallback end
   if not s.buttonHeight or s.buttonHeight<=0 then s.buttonHeight=s.buttonWidth end
   local maximum=(key=="PetBar" or key=="StanceBar") and 10 or 12
   s.numIcons=math.max(1,math.min(maximum,s.numIcons or maximum))
   s.numRows=math.max(1,math.min(s.numIcons,s.numRows or 1))
  end
 end
 return p
end
