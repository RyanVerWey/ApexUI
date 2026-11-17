local _, A = ...
local F={units={},headers={},VERSION=1}
A.Frames=F
F.MEDIA="Interface\\AddOns\\ApexUI\\Frames\\Media\\"
F.FONT="Fonts\\FRIZQT__.TTF"
-- Art coordinates are normalized against the original texture, before engine padding.
F.geometry={
 iron={ratio=3,face={.166,.452,.212},name={.30,.105,.55,.16},level={.875,.105,.065,.16},
  health={.300,.308,.668,.168},power={.300,.524,.668,.157},xp={.278,.753,.680,.076}},
 split={ratio=3,face={.505,.535,.165},name={.26,.135,.45,.13},level={.72,.135,.05,.13},
  health={.058,.409,.339,.270},power={.603,.409,.339,.270},xp={.118,.818,.770,.051}}
}
function F.ResolveLayout(class,hasPet,mode,center,barTop,scale,density)
 local paired=mode=="paired" or (mode~="solo" and (class=="HUNTER" or class=="WARLOCK" or hasPet))
 local compact=density~="roomy"
 local width=(paired and (compact and 400 or 420) or (compact and 480 or 560))*scale
 return {paired=paired,style=paired and "iron" or "split",width=width,height=width/3,
  x=center,y=barTop+(compact and 16 or 52),petX=center-width-22*scale}
end
function F.Text(parent,size)
 local t=parent:CreateFontString(nil,"OVERLAY");t:SetFont(F.FONT,size,"OUTLINE");t:SetTextColor(.97,.93,.80)
 t:SetWordWrap(false);return t
end
function F.Place(region,parent,rect)
 region:ClearAllPoints();region:SetPoint("TOPLEFT",parent,"TOPLEFT",rect[1]*parent:GetWidth(),-rect[2]*parent:GetHeight())
 region:SetSize(rect[3]*parent:GetWidth(),rect[4]*parent:GetHeight())
end
function F.Public(v) return not issecretvalue or not issecretvalue(v) end

function F.Settings()
 ApexUIDB.portraitFrames=ApexUIDB.portraitFrames or {enabled=true,mode="auto",scale=1}
 if A.Active and A.ProfileDB then
  local profile=A.Active()
  profile.portraitFrames=profile.portraitFrames or A.Copy(ApexUIDB.portraitFrames)
  return profile.portraitFrames
 end
 return ApexUIDB.portraitFrames
end
