local _, A = ...

-- A normal named Minimap child lets button collectors (including EllesmereUI)
-- discover and reparent this launcher without dependencies or private APIs.
local function createButton()
 if A.minimapButton or not Minimap then return end
 local b=CreateFrame('Button','ApexFishingMinimapButton',Minimap)
 b:SetSize(32,32)
 b:SetPoint('TOPRIGHT',Minimap,'TOPRIGHT',2,2)
 b:SetFrameStrata('MEDIUM')
 b:RegisterForClicks('LeftButtonUp','RightButtonUp')
 b:SetNormalTexture('Interface\\Icons\\INV_Misc_Fish_02')
 b:SetHighlightTexture('Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight','ADD')
 b:SetScript('OnClick',function(_,button)
  if button=='RightButton' then
   if A.frame and not (A.IsGuideVisible and A.IsGuideVisible() or A.frame:IsShown()) then SlashCmdList.APEXFISHING('show') end
   A.ToggleFishing()
  else
   SlashCmdList.APEXFISHING('')
  end
 end)
 b:SetScript('OnEnter',function(self)
  GameTooltip:SetOwner(self,'ANCHOR_LEFT')
  GameTooltip:AddLine('Apex Fishing',.3,.9,.8)
  GameTooltip:AddLine('Left-click: open / close guide',1,1,1)
  GameTooltip:AddLine('Right-click: start / stop fishing mode',1,1,1)
  GameTooltip:Show()
 end)
 b:SetScript('OnLeave',function() GameTooltip:Hide() end)
 b:Show()
 A.minimapButton=b
end

local events=CreateFrame('Frame')
events:RegisterEvent('PLAYER_LOGIN')
events:RegisterEvent('PLAYER_ENTERING_WORLD')
events:SetScript('OnEvent',createButton)
