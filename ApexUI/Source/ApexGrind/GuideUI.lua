local _, A = ...
local pane
local function text(size,y,height)
 local t=pane:CreateFontString(nil,'OVERLAY')
 t:SetFont('Fonts\\FRIZQT__.TTF',size,'');t:SetTextColor(.93,.89,.80)
 t:SetPoint('TOPLEFT',0,-y);t:SetWidth(306);t:SetJustifyH('LEFT');t:SetJustifyV('TOP')
 if height then t:SetHeight(height) end
 return t
end
local function button(name,label,x,y,width,callback)
 local b=CreateFrame('Button',name,pane,'UIPanelButtonTemplate')
 b:SetSize(width,26);b:SetPoint('TOPLEFT',x,-y);b:SetText(label);b:SetScript('OnClick',callback)
 return b
end
function A.BuildGuide(parent)
 pane=CreateFrame('Frame',nil,parent);pane:SetSize(306,290);pane:SetPoint('TOPLEFT',16,-200)
 pane.previous=button('ApexGrindPreviousLevel','<',0,0,30,function() A.BrowseLevel(-1) end)
 pane.current=button('ApexGrindCurrentLevel','',38,0,230,A.CurrentLevel)
 pane.next=button('ApexGrindNextLevel','>',276,0,30,function() A.BrowseLevel(1) end)
 local picker=CreateFrame('DropdownButton','ApexGrindMaterialPicker',pane,'WowStyle1DropdownTemplate')
 picker:SetPoint('TOPLEFT',0,-34);picker:SetWidth(306);picker:SetDefaultText('Loot: any / XP first')
 picker:SetupMenu(function(_,root)
  root:SetScrollMode(340)
  root:CreateRadio('Loot: any / XP first',function() return not A.Material(A.db.material) end,function() A.SelectMaterial(0) end)
  for _,material in ipairs(A.materials) do
   local id=material.id
   root:CreateRadio(material.name..(material.method=='skin' and ' (Skinning)' or ''),
    function() return A.db.material==id end,function() A.SelectMaterial(id) end)
  end
 end)
 A.materialPicker=picker
 pane.mob=text(17,78,42)
 pane.zone=text(14,123)
 pane.target=text(14,146)
 pane.note=text(13,171,55)
 pane.evidence=text(11,232,28);pane.evidence:SetTextColor(.74,.70,.62)
 pane.route=button('ApexGrindRoute','Navigate',0,264,90,A.NavigateSpot)
 pane.other=button('ApexGrindOtherSpot','Next spot',98,264,110,A.NextSpot)
 pane.map=button('ApexGrindMap','Map',216,264,90,function() A.ShowGrindMap() end)
 pane:SetScript('OnEnter',function(self)
  local choice=A.GuideSelection();if not choice then return end
  GameTooltip:SetOwner(self,'ANCHOR_RIGHT')
  GameTooltip:AddLine('Why this spot?',.89,.74,.47)
  GameTooltip:AddLine(choice.reason,.93,.89,.80,true)
  GameTooltip:AddLine('Ranks level fit, local travel, recorded spawn clustering and pull risks.',.93,.89,.80,true)
  GameTooltip:AddLine('Reference recommendation, not a measured fastest camp. Compare 5-minute XP/h after arriving.',.93,.89,.80,true)
  GameTooltip:Show()
 end)
 pane:EnableMouse(true)
 pane:SetScript('OnLeave',function() GameTooltip:Hide() end)
 A.guidePane=pane
 return pane
end
function A.RenderGuide()
 if not pane then return end
 pane:SetShown(not A.db.compact and A.db.view=='spots')
 if A.db.compact or A.db.view~='spots' then return end
 local choice,level,count=A.GuideSelection()
 local material=A.Material(A.db.material)
 pane.current:SetText('Level '..level..(A.previewLevel and '  |  Back to mine' or '  |  Auto'))
 pane.previous:SetEnabled(level>1);pane.next:SetEnabled(level<60)
 pane.route:SetEnabled(choice~=nil);pane.other:SetEnabled(count>1)
 pane.map:SetEnabled(choice~=nil)
 if not choice then
  pane.mob:SetText(level>=60 and 'Level cap reached' or (material and 'No XP + loot match at this level' or 'No suitable camp in the reference data'))
  pane.zone:SetText(level>=60 and 'Normal leveling XP ends at 60.' or (material and material.name or 'Stay near your current quest hub.'))
  pane.target:SetText('');pane.note:SetText(material and 'This material has no verified candidate in your target level band. Clear the filter for XP, or preview a matching level.' or 'Use the level arrows to browse recommendations. Click the level button to follow your character again.')
  local nearest=A.NearestMaterialLevel(level)
  pane.evidence:SetText('No unsuitable farm is substituted for an XP spot.')
  pane.other:SetEnabled(nearest~=nil);pane.other:SetText(nearest and ('Preview Lv '..nearest) or 'Next spot');return
 end
 local s=choice.spot
 pane.mob:SetText(s.mob..' |cffc6bca7('..s.low..'-'..s.high..')|r')
 pane.zone:SetText(s.zone..string.format('  %.1f, %.1f',s.x*100,s.y*100))
 local target=choice.targetLow==choice.targetHigh and tostring(choice.targetLow) or (choice.targetLow..'-'..choice.targetHigh)
 pane.target:SetText('Kill level '..target..'  |  '..(s.map==A.LocalMap() and 'Your zone' or 'Travel required'))
 pane.note:SetText(s.note)
 if material then
  pane.evidence:SetText((material.method=='skin' and 'Requires Skinning + suitable skill/tool. ' or 'Loot from corpses. ')..'Classic loot reference.')
 else pane.evidence:SetText(s.map==2521 and 'Forever DB reference; phasing may vary.' or 'Classic baseline, checked against Forever DB.') end
 pane.other:SetText('Next spot '..(A.guideIndex or 1)..'/'..count)
end
