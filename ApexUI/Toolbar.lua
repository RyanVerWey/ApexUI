local _,A=...
local S=A.Suite
local entries={
 {'features','ApexUI','Features and layout settings','INV_Shield_05'},
 {'fishing','Fishing','Fishing and cooking guide','Trade_Fishing'},
 {'navigation','Navigation','Routes, map pins and coordinates','INV_Misc_Map_01'},
 {'grinding','Grinding','XP tracking and grinding spots','Ability_Hunter_SniperShot'},
 {'professions','Professions','Crafting, gathering and cost plans','Trade_BlackSmithing'},
 {'combat','Combat','Live DPS and dungeon party reports','Ability_DualWield'},
 {'addons','Addons','Other addon shortcuts, kept off the minimap','INV_Misc_Gear_01'},
}
S.toolbarEntries=entries

local pending=false
local function active(key) return key=='features' or key=='addons' or (S.modules[key] and S.modules[key].status=='loaded') end
local function backdrop(f)
 f:SetBackdrop({bgFile='Interface\\Buttons\\WHITE8X8',edgeFile='Interface\\Buttons\\WHITE8X8',edgeSize=1})
 f:SetBackdropColor(.035,.030,.026,.97);f:SetBackdropBorderColor(.55,.43,.28,.9)
end
function S.ToolbarGeometry(width,count)
 local cols=math.max(1,math.floor((width-16)/142))
 local rows=math.max(1,math.ceil(count/cols))
 return cols,rows,40+rows*48
end
function S.RefreshToolbar()
 if not S.toolbar then return end
 for key,b in pairs(S.toolbar.buttons) do
  b.icon:SetDesaturated(not active(key));b.icon:SetAlpha(active(key) and 1 or .4)
 end
end
function S.CloseToolkit() if S.toolbar then S.toolbar:Hide() end end
function S.ToggleToolkit()
 if not S.toolbar then return end
 if S.toolbar:IsShown() then S.CloseToolkit() else S.LayoutToolbar();S.toolbar:Show() end
end
local function tooltip(self,title,description)
 GameTooltip:SetOwner(self,'ANCHOR_LEFT');GameTooltip:AddLine(title,.89,.74,.47)
 GameTooltip:AddLine(description,.9,.87,.8,true);GameTooltip:Show()
end
local function button(f,e)
 local b=CreateFrame('Button',nil,f);b.entry=e;b:SetSize(138,44)
 b.icon=b:CreateTexture(nil,'ARTWORK');b.icon:SetSize(30,30);b.icon:SetPoint('LEFT',b,'LEFT',5,0)
 b.icon:SetTexture('Interface\\Icons\\'..e[4]);b.icon:SetTexCoord(.06,.94,.06,.94)
 b.label=b:CreateFontString(nil,'OVERLAY');b.label:SetFont(A.Theme and A.Theme.font or STANDARD_TEXT_FONT,13,'OUTLINE')
 b.label:SetPoint('LEFT',b.icon,'RIGHT',7,0);b.label:SetWidth(90);b.label:SetJustifyH('LEFT');b.label:SetText(e[2])
 b:SetHighlightTexture('Interface\\QuestFrame\\UI-QuestTitleHighlight','ADD')
 b:RegisterForClicks('LeftButtonUp','RightButtonUp')
 b:SetScript('OnClick',function(self,mouse)
  S.CloseToolkit();GameTooltip:Hide()
  local key=self.entry[1]
  if key=='addons' then A.Shell.ToggleMapButtons()
  elseif mouse=='RightButton' or key=='features' or not active(key) then A.ToggleFeatures() else S.Open(key) end
 end)
 b:SetScript('OnEnter',function(self) tooltip(self,self.entry[2],self.entry[3]) end)
 b:SetScript('OnLeave',function() GameTooltip:Hide() end)
 return b
end
function S.LayoutToolbar()
 if InCombatLockdown() then pending=true;return end
 if not S.toolbar or not S.toolkitLauncher then return end
 local bounds=A.utilityBounds or {left=UIParent:GetWidth()-452,bottom=14,width=440,height=118}
 local launcher=S.toolkitLauncher
 local space=bounds.launcher or {left=bounds.left+4,bottom=bounds.bottom+28,width=96,height=bounds.height-32}
 launcher:ClearAllPoints();launcher:SetPoint('CENTER',UIParent,'BOTTOMLEFT',space.left+space.width/2,space.bottom+space.height/2)
 local f=S.toolbar
 local width=300;local cols,rows,height=S.ToolbarGeometry(width,#entries)
 f:SetSize(width,height);f:ClearAllPoints()
 if bounds.mapDock then f:SetPoint('TOPRIGHT',launcher,'TOPLEFT',-10,0)
 else f:SetPoint('BOTTOMRIGHT',launcher,'TOPRIGHT',180,10) end
 for i,e in ipairs(entries) do
  local b=f.buttons[e[1]] or button(f,e);f.buttons[e[1]]=b;b.entry=e
  b.icon:SetTexture('Interface\\Icons\\'..e[4]);b.label:SetText(e[2])
  local row=math.floor((i-1)/cols);local col=(i-1)%cols
  b:ClearAllPoints();b:SetPoint('TOPLEFT',f,'TOPLEFT',8+col*142,-34-row*48);b:Show()
 end
 -- The old minimap dock is gone, so restore a simple map-to-tracker gap.
 if Questie and Questie.db and Questie_BaseFrame and Minimap and Minimap:GetRight() then
  local host=A.Shell and A.Shell.map or Minimap
  local ratio=host:GetEffectiveScale()/UIParent:GetEffectiveScale()
  local right=host:GetRight()*ratio;local y=host:GetBottom()*ratio-18
  if ApexUICharacterDB and not ApexUICharacterDB.utilityQuestieBackup then
   ApexUICharacterDB.utilityQuestieBackup=A.Copy(Questie.db.profile.TrackerLocation)
  end
  Questie.db.profile.TrackerLocation={'TOPRIGHT','UIParent','BOTTOMLEFT',right,y}
  Questie_BaseFrame:ClearAllPoints();Questie_BaseFrame:SetPoint('TOPRIGHT',UIParent,'BOTTOMLEFT',right,y)
 end
 pending=false;S.RefreshToolbar()
end
function S.RegisterToolbarEntry(entry)
 assert(type(entry)=='table' and type(entry[1])=='string' and type(entry[4])=='string','Toolbar entry requires key, title, description and icon')
 for i,e in ipairs(entries) do if e[1]==entry[1] then entries[i]=entry;S.LayoutToolbar();return end end
 entries[#entries+1]=entry;S.LayoutToolbar()
end
function S.CreateToolkit()
 if InCombatLockdown() then pending=true;return end
 if not S.toolbar then
  local f=CreateFrame('Frame','ApexUIToolkitPicker',UIParent,'BackdropTemplate');S.toolbar=f
  f:SetFrameStrata('DIALOG');f:SetClampedToScreen(true);f:EnableMouse(true);f.buttons={};backdrop(f)
  f.title=f:CreateFontString(nil,'OVERLAY');f.title:SetFont(STANDARD_TEXT_FONT,14,'OUTLINE')
  f.title:SetPoint('TOPLEFT',12,-10);f.title:SetText('Apex Toolkit');f.title:SetTextColor(.89,.74,.47)
  local close=CreateFrame('Button',nil,f);close:SetSize(24,24);close:SetPoint('TOPRIGHT',-4,-4)
  local text=close:CreateFontString(nil,'OVERLAY');text:SetFont(STANDARD_TEXT_FONT,16,'OUTLINE');text:SetAllPoints();text:SetText('X');text:SetTextColor(.95,.16,.12)
  close:SetHighlightTexture('Interface\\Buttons\\UI-Common-MouseHilight','ADD')
  close:SetScript('OnClick',S.CloseToolkit)
  local line=f:CreateTexture(nil,'ARTWORK');line:SetColorTexture(.60,.44,.24,.85)
  line:SetHeight(1);line:SetPoint('TOPLEFT',12,-29);line:SetPoint('TOPRIGHT',-12,-29)
  if A.Theme then text:Hide();line:Hide();A.Theme.Header(f,f.title,close,{compact=true,titleWidth=238}) end
  for _,corner in ipairs({'TOPLEFT','TOPRIGHT','BOTTOMLEFT','BOTTOMRIGHT'}) do
   local cap=f:CreateTexture(nil,'OVERLAY');cap:SetColorTexture(.74,.55,.31,.95)
   cap:SetSize(22,2);cap:SetPoint(corner,f,corner,corner:find('LEFT') and 2 or -2,corner:find('TOP') and -2 or 2)
  end
  UISpecialFrames[#UISpecialFrames+1]='ApexUIToolkitPicker';f:Hide()
  local b=CreateFrame('Button','ApexUIToolkitLauncher',UIParent);S.toolkitLauncher=b
  b:SetSize(90,62);b:SetFrameStrata('MEDIUM')
  b.icon=b:CreateTexture(nil,'ARTWORK');b.icon:SetSize(44,44);b.icon:SetPoint('TOP',0,0)
  b.icon:SetTexture('Interface\\Icons\\INV_Shield_05')
  local mask=b:CreateMaskTexture();mask:SetAllPoints(b.icon)
  mask:SetTexture('Interface\\CharacterFrame\\TempPortraitAlphaMask','CLAMPTOBLACKADDITIVE','CLAMPTOBLACKADDITIVE');b.icon:AddMaskTexture(mask)
  local rim=b:CreateTexture(nil,'OVERLAY');rim:SetAllPoints(b.icon)
  rim:SetTexture('Interface\\AddOns\\ApexUI\\Media\\pixels_circle_border.tga');rim:SetVertexColor(.70,.54,.30)
  b.label=b:CreateFontString(nil,'OVERLAY');b.label:SetFont(STANDARD_TEXT_FONT,12,'OUTLINE')
  b.label:SetPoint('TOP',b.icon,'BOTTOM',0,-4);b.label:SetText('Apex Toolkit');b.label:SetTextColor(.89,.79,.61)
  b:SetScript('OnClick',S.ToggleToolkit)
  b:SetScript('OnEnter',function(self) tooltip(self,'Apex Toolkit','Open your Apex features. Select one to launch it and close this menu.') end)
  b:SetScript('OnLeave',function() GameTooltip:Hide() end)
 end
 S.LayoutToolbar()
end
local events=CreateFrame('Frame')
for _,event in ipairs({'PLAYER_ENTERING_WORLD','PLAYER_REGEN_ENABLED','EDIT_MODE_LAYOUTS_UPDATED','UI_SCALE_CHANGED','DISPLAY_SIZE_CHANGED','GLOBAL_MOUSE_DOWN'}) do events:RegisterEvent(event) end
events:SetScript('OnEvent',function(_,event)
 if event=='GLOBAL_MOUSE_DOWN' then
  if S.toolbar and S.toolbar:IsShown() and not S.toolbar:IsMouseOver() and not S.toolkitLauncher:IsMouseOver() then S.CloseToolkit() end
 elseif event=='PLAYER_REGEN_ENABLED' then if pending then S.CreateToolkit() end
 else S.CreateToolkit();C_Timer.After(2,S.CreateToolkit);C_Timer.After(5,S.CreateToolkit) end
end)
