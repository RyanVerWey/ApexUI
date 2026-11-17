local _,A=...
-- Original ApexUI profile and renderer coordination. No external framework code.
local B={_ModuleNS={},renderers={},movers={}};A.Backend=B
A.FONT="Fonts\\FRIZQT__.TTF"
A.EDGE_INSET=14
function B.NormalizeScreenMargins(p)
 if p.apexEdgeMargins==1 then return end
 local edge=A.EDGE_INSET
 local map=p.addons.ApexMinimap and p.addons.ApexMinimap.minimap
 if map then map.position={point="TOPRIGHT",relPoint="TOPRIGHT",x=-edge,y=-edge} end
 local bars=p.addons.ApexBars and p.addons.ApexBars.barPositions
 if bars and bars.MainBar and bars.MainBar.point=="BOTTOM" then
  local delta=edge-(bars.MainBar.y or 0)
  for _,key in ipairs({"MainBar","Bar9","Bar4","Bar5","Bar2"}) do
   local pos=bars[key]
   if pos and pos.point=="BOTTOM" then pos.y=(pos.y or 0)+delta end
  end
 end
 p.addons.ApexChat=p.addons.ApexChat or {}
 local chat=p.addons.ApexChat.chat or {};p.addons.ApexChat.chat=chat
 local oldY=chat.chatPosition and chat.chatPosition.y or edge+12
 chat.chatSize=chat.chatSize or {w=556,h=209}
 chat.chatSize.h=math.max(160,chat.chatSize.h+oldY-edge-12)
 -- Account for the chat surround's control gutter and bottom padding.
 chat.chatPosition={point="BOTTOMLEFT",relPoint="BOTTOMLEFT",x=edge+40,y=edge+12}
 chat.apexSurroundVersion=1
 p.apexEdgeMargins=1
end
local function copy(value)
 if type(value)~="table" then return value end
 local out={};for k,v in pairs(value) do out[k]=copy(v) end;return out
end
function B.RegisterRenderer(key,apply)
 B.renderers[key]=apply
end
function B.GetActiveProfileName() return A.ProfileDB and A.ProfileDB.activeProfile end
function B.GetFontsDB()
 local p=A.ProfileDB.profiles[B.GetActiveProfileName()]
 p.fonts=p.fonts or {};return p.fonts
end
function B.AutoSaveActiveProfile()
 if not A.ProfileDB then return end
 local p=A.ProfileDB.profiles[B.GetActiveProfileName()]
 if not p then return end
 for key,ns in pairs(B._ModuleNS) do
  if ns.db and ns.db.profile then p.addons[key]=ns.db.profile end
 end
 if ApexUIDB.sharedProfile==B.GetActiveProfileName() then ApexUIDB.sharedSnapshot=copy(p) end
 if ApexUICharacterDB and ApexUICharacterDB.customLayout then ApexUICharacterDB.customSnapshot=copy(p) end
end
function B.SwitchProfile(name)
 if InCombatLockdown() then A.pending=function() B.SwitchProfile(name) end;return end
 local p=A.ProfileDB.profiles[name];if not p then return end
 B.AutoSaveActiveProfile();A.ProfileDB.activeProfile=name
 for key,ns in pairs(B._ModuleNS) do ns.db.profile=p.addons[key] end
 B.Apply()
end
function B.Apply()
 if InCombatLockdown() then A.pending=B.Apply;return end
 if B.conflict or not A.ready then return end
 -- Retain the imported layout's coordinate scale; never alter display mode or resolution.
 local migration=ApexUIDB.frameworkMigrationBackup
 local scale=ApexUIDB.layoutScale or (migration and migration.provider and migration.provider.ppUIScale)
 if type(scale)=="number" and scale>=.4 and scale<=1.5 then
  ApexUIDB.layoutScale=scale
  if math.abs(UIParent:GetScale()-scale)>.0001 then UIParent:SetScale(scale) end
 end
 B.NormalizeScreenMargins(A.Active())
 for _,key in ipairs({"units","bars","shell","party"}) do
  if B.renderers[key] then B.renderers[key]() end
 end
 if A.PlaceNativeUtilities then A.PlaceNativeUtilities() end
 if A.Frames then A.Frames.Apply() end
 if A.StyleNativeWindows then A.StyleNativeWindows() end
 if A.ScheduleDecorations then A.ScheduleDecorations() end
end
function B.InvalidateFontCache() end
function B._applySavedPositions() B.Apply() end
function B.EditModeOpen()
 return B._unlockModeSessionActive or (EditModeManagerFrame and EditModeManagerFrame:IsShown())
end
function B.EditModeLayoutsForSave()
 if not C_EditMode or not C_EditMode.GetLayouts then return end
 local data=C_EditMode.GetLayouts()
 if not data or not data.layouts then return end
 local manager=EditModePresetLayoutManager
 local presetLayouts=manager and manager.GetCopyOfPresetLayouts and manager:GetCopyOfPresetLayouts()
 if type(presetLayouts)~="table" or #presetLayouts==0 then return end
 local result=copy(data);result.layouts={}
 for _,p in ipairs(presetLayouts) do result.layouts[#result.layouts+1]=copy(p) end
 for _,p in ipairs(data.layouts) do result.layouts[#result.layouts+1]=copy(p) end
 return result,#presetLayouts
end
function B.OpenUnlockMode()
 if A.OpenMovers then A.OpenMovers() end
end
function B.Position(frame,p)
 if not p then return end
 frame:ClearAllPoints();frame:SetPoint(p.point or "CENTER",UIParent,p.relPoint or p.point or "CENTER",p.x or 0,p.y or 0)
 frame:SetClampedToScreen(true)
end
function B.FrameBorder(frame)
 frame:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",edgeSize=8})
 frame:SetBackdropColor(.055,.045,.035,.96);frame:SetBackdropBorderColor(.55,.43,.28,1)
end
function B.Text(frame,size)
 local text=frame:CreateFontString(nil,"OVERLAY");text:SetFont(A.FONT,size or 15,"OUTLINE")
 text:SetTextColor(.93,.90,.83);return text
end
local events=CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGOUT")
events:SetScript("OnEvent",function() B.AutoSaveActiveProfile() end)
