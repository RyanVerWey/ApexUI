local _,A=...
local S=A.Suite
local FONT='Fonts\\FRIZQT__.TTF'
local function label(parent,value,x,y,size,width)
 local f=parent:CreateFontString(nil,'OVERLAY');f:SetFont(FONT,size or 17,'')
 f:SetPoint('TOPLEFT',x,y);f:SetTextColor(.91,.86,.75);f:SetJustifyH('LEFT')
 if width then f:SetWidth(width);f:SetWordWrap(true) end
 f:SetText(value);return f
end
local function button(parent,value,x,y,width,fn)
 local b=CreateFrame('Button',nil,parent,'UIPanelButtonTemplate')
 b:SetPoint('TOPLEFT',x,y);b:SetSize(width,32);b:SetText(value)
 b:GetFontString():SetFont(FONT,16,'');b:SetScript('OnClick',fn);return b
end
local function external(command,title)
 for key,fn in pairs(SlashCmdList) do
  for i=1,20 do
   local alias=_G['SLASH_'..key..i]
   if not alias then break end
   if alias:lower()==command then S.frame:Hide();fn('');return end
  end
 end
 print('|cffe3bd78ApexUI:|r '..title..' is not available. Enable its addon and reload.')
end
function S.Refresh()
 local f=S.frame;if not f then return end
 f.scope:SetText((UnitName('player') or 'This character')..' | Feature choices are saved per character')
 for _,key in ipairs(S.order) do
  local m=S.modules[key];local row=f.rows[key]
  row.check:SetChecked(S.Enabled(key))
  local pending=S.Enabled(key)~=m.startedEnabled
  row.state:SetText(pending and (S.Enabled(key) and 'Enable after reload' or 'Disable after reload')
   or m.status=='loaded' and 'On' or m.status=='disabled' and 'Off' or m.status=='error' and 'Load error' or 'Loading')
  row.state:SetTextColor(unpack(m.status=='error' and {.95,.45,.33} or pending and {.89,.74,.47} or {.64,.75,.64}))
  row.open:SetEnabled(m.status=='loaded')
 end
 f.reload:SetEnabled(S.Pending() and not InCombatLockdown())
 f.notice:SetText(InCombatLockdown() and 'Finish combat before applying feature changes.'
  or S.Pending() and 'Changes are saved. Reload to apply them; your progress and settings are retained.'
  or 'One launcher for every Apex feature. Existing slash commands still work.')
end
function A.ToggleFeatures()
 if S.frame then S.frame:SetShown(not S.frame:IsShown());S.Refresh();return end
 local f=CreateFrame('Frame','ApexUIFeatures',UIParent,'BackdropTemplate');S.frame=f
 local extra=(#S.order-4)*75
 f:SetSize(830,650+extra);f:SetPoint('CENTER');f:SetFrameStrata('FULLSCREEN_DIALOG');f:SetFrameLevel(1000);f:SetClampedToScreen(true)
 f:SetBackdrop({edgeFile='Interface\\DialogFrame\\UI-DialogBox-Border',edgeSize=24})
 f:SetBackdropBorderColor(.70,.55,.32,1)
 local bg=f:CreateTexture(nil,'BACKGROUND',nil,-8);bg:SetPoint('TOPLEFT',7,-7);bg:SetPoint('BOTTOMRIGHT',-7,7);bg:SetColorTexture(.045,.036,.026,1)
 f:SetMovable(true);f:EnableMouse(true);f:RegisterForDrag('LeftButton')
 f:SetScript('OnDragStart',function(self) self:StartMoving() end)
 f:SetScript('OnDragStop',function(self) self:StopMovingOrSizing() end)
 table.insert(UISpecialFrames,'ApexUIFeatures')
 local close=CreateFrame('Button',nil,f,'UIPanelCloseButton');close:SetPoint('TOPRIGHT',-7,-7)
 local title=label(f,'Apex Toolkit',24,-20,22)
 if A.Theme then A.Theme.Header(f,title,close,{titleWidth=460}) end
 button(f,'Detect level & skills',535,-27,265,function() S.SyncProgress(true) end)
 f.scope=label(f,'',28,-67,16,770)
 label(f,'Your layout',28,-108,20)
 label(f,'Shared default, character variations, frames and saved layouts.',28,-137,16,535)
 button(f,'Layout settings',606,-116,194,function() f:Hide();A.ToggleOptions() end)
 label(f,'FEATURE',28,-192,14);label(f,'STATUS',563,-192,14)
 f.rows={}
 for i,key in ipairs(S.order) do
  local m=S.modules[key];local y=-219-(i-1)*75
  local check=CreateFrame('CheckButton',nil,f,'UICheckButtonTemplate');check:SetPoint('TOPLEFT',25,y);check:SetSize(30,30)
  check:SetScript('OnClick',function(self) S.SetEnabled(key,self:GetChecked()) end)
  label(f,m.title,68,y-1,20)
  label(f,m.description,68,y-29,15,470)
  local state=label(f,'',565,y-7,14,130)
  local open=button(f,'Open',708,y-3,92,function() S.Open(key) end)
  f.rows[key]={check=check,state=state,open=open}
 end
 label(f,'INTEGRATIONS',28,-530-extra,14)
 button(f,'RestedXP',28,-552-extra,158,function() external('/rxp','RestedXP') end)
 button(f,'Questie',198,-552-extra,140,function() external('/questie','Questie') end)
 button(f,'Auctionator',350,-552-extra,160,function() external('/auctionator','Auctionator') end)
 f.reload=button(f,'Apply and reload',606,-552-extra,194,S.Apply)
 f.notice=label(f,'',28,-606-extra,15,770)
 f:RegisterEvent('PLAYER_REGEN_DISABLED');f:RegisterEvent('PLAYER_REGEN_ENABLED')
 f:SetScript('OnEvent',S.Refresh);f:SetScript('OnShow',S.Refresh)
 if A.Theme then A.Theme.Attach(f) end
 S.Refresh()
end
