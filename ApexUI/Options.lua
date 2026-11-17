local _, A = ...
local FONT="Fonts\\FRIZQT__.TTF"
local function label(parent,text,x,y,size,width)
 local f=parent:CreateFontString(nil,"OVERLAY")
 f:SetFont(FONT,size or 16,"");f:SetPoint("TOPLEFT",x,y)
 f:SetTextColor(.91,.86,.75);f:SetJustifyH("LEFT")
 if width then f:SetWidth(width);f:SetWordWrap(true) end
 f:SetText(text);return f
end
local function button(parent,text,x,y,w,fn)
 local b=CreateFrame("Button",nil,parent,"UIPanelButtonTemplate")
 b:SetSize(w,32);b:SetPoint("TOPLEFT",x,y);b:SetText(text)
 b:GetFontString():SetFont(FONT,15,"")
 b:SetScript("OnClick",fn);return b
end
local function clamp(n,lo,hi) return math.max(lo,math.min(hi,n)) end
local function adjust(field,delta)
 A.Edit(function(u)
  local f=A.Frames and A.Frames.Settings()
  if f and (field=="width" or field=="pet") then f.scale=clamp((f.scale or 1)+delta/200,.7,1.4) end
  if field=="text" then
   if f then f.textOffset=clamp((f.textOffset or 0)+delta,-4,6) end
   for _,key in ipairs({"player","target","pet"}) do
    local s=u[key];s.centerTextSize=clamp((s.centerTextSize or 18)+delta,14,24)
    s.powerPercentSize=clamp((s.powerPercentSize or 16)+delta,14,22)
    s.btbLeftSize=clamp((s.btbLeftSize or 16)+delta,14,22)
   end
  elseif field=="width" then
   for _,key in ipairs({"player","target"}) do
    local s=u[key];s.frameWidth=clamp(s.frameWidth+delta,250,key=="target" and 600 or 340)
    if key=="player" then s.playerCastbarWidth=s.frameWidth else s.castbarWidth=s.frameWidth end
   end
  elseif field=="pet" then
   local s=u.pet;s.frameWidth=clamp(s.frameWidth+delta,210,320);s.castbarWidth=s.frameWidth
  elseif field=="auras" then
   if f then f.auraSize=clamp((f.auraSize or 32)+delta,24,40) end
   local p=u.playerAuraBars
   for _,key in ipairs({"defaultBuffs","defaultDebuffs"}) do
    p[key].iconSize=clamp(p[key].iconSize+delta,24,36)
   end
  end
 end)
end
local function selected()
 return ApexUIDB.layouts and ApexUIDB.layouts[A.selectedLayoutId]
end
function A.UpdateOptions()
 if not A.panel then return end
 A.InitLayoutLibrary()
 local p=A.panel;local on=A.OwnActive();local idle=on and not InCombatLockdown()
 local info=A.ClassInfo(A.class)
 p.character:SetText(UnitName("player").."  |  "..info.label)
 p.character:SetTextColor(unpack(info.color))
 p.active:SetText((ApexUICharacterDB.customLayout and "EDITING THIS CHARACTER: " or "EDITING SHARED DEFAULT: ")..A.CurrentLayoutName())
 p.status:SetText(not on and "ApexUI is paused. Enable it to edit your saved layouts." or
  (ApexUICharacterDB.customLayout and "Live changes affect only this character. Other characters keep the shared default." or
   "Live changes auto-save for every character using the shared default. Pet frames appear when needed."))
 p.activate:SetText(on and "Reapply active layout" or "Enable ApexUI")
 local list=A.LayoutList()
 if not selected() and list[1] then A.selectedLayoutId=list[1].id end
 p.page=math.max(1,math.min(p.page or 1,math.max(1,math.ceil(#list/5))))
 for i,row in ipairs(p.rows) do
  local item=list[(p.page-1)*5+i]
  row.id=item and item.id
  row:SetShown(item~=nil)
  if item then
   row.title:SetText(item.entry.name)
   row.detail:SetText(item.entry.owner.."  |  "..(item.entry.class=="ALL" and "All classes" or A.ClassInfo(item.entry.class).label))
   local chosen=item.id==A.selectedLayoutId
   row:SetBackdropColor(chosen and .24 or .09,chosen and .18 or .075,chosen and .10 or .055,1)
   row:SetBackdropBorderColor(chosen and .85 or .30,chosen and .68 or .25,chosen and .36 or .18,1)
  end
 end
 p.pageText:SetText(p.page.." / "..math.max(1,math.ceil(#list/5)))
 p.prev:SetEnabled(p.page>1);p.next:SetEnabled(p.page*5<#list)
 local entry=selected()
 p.selection:SetText(entry and ("Selected save: "..entry.name.."\nLoading replaces the chosen scope. Live edits do not overwrite this save.") or "Save your current layout to start a library.")
 if p.lastSelection~=A.selectedLayoutId then
  p.name:SetText(entry and entry.name or "");p.lastSelection=A.selectedLayoutId
 end
 p.notice:SetText(InCombatLockdown() and "Layout editing is unavailable during combat." or (A.layoutNotice or "Named saves include suite frames, bars and minimap. Questie and RestedXP keep their own settings."))
 for _,b in ipairs(p.editButtons) do b:SetEnabled(idle) end
 for _,b in ipairs(p.selectionButtons) do b:SetEnabled(idle and entry~=nil) end
 p.activate:SetEnabled(not InCombatLockdown())
 p.undo:SetEnabled(idle and ApexUICharacterDB.undo~=nil)
 p.shared:SetEnabled(idle and ApexUICharacterDB.customLayout==true)
 p.custom:SetEnabled(idle and not ApexUICharacterDB.customLayout)
 local own=A.ProfileDB.profiles[ApexUICharacterDB.profile]
 local u=own and own.addons and own.addons[A.UF]
 if u then
  local f=A.Frames and A.Frames.Settings() or {}
  p.values.text:SetText("Frame text "..string.format("%+d",f.textOffset or 0))
  p.values.width:SetText(string.format("%d%% / %d",(f.scale or 1)*100,u.target.frameWidth or 420))
  p.values.pet:SetText(string.format("%d%%",(f.scale or 1)*100))
  p.values.auras:SetText((f.auraSize or 32).." px")
 end
end
function A.ToggleOptions()
 if A.panel then A.panel:SetShown(not A.panel:IsShown());A.UpdateOptions();return end
 local p=CreateFrame("Frame","ApexUIOptions",UIParent,"BackdropTemplate")
 A.panel=p;p:SetSize(820,670);p:SetPoint("CENTER");p:SetFrameStrata("DIALOG")
 p:SetClampedToScreen(true);p:SetMovable(true);p:EnableMouse(true);p:RegisterForDrag("LeftButton")
 p:SetScript("OnDragStart",function(self) self:StartMoving() end)
 p:SetScript("OnDragStop",function(self) self:StopMovingOrSizing() end)
 p:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border",edgeSize=24,insets={left=7,right=7,top=7,bottom=7}})
 p:SetBackdropColor(.055,.045,.035,.98);p:SetBackdropBorderColor(.79,.65,.40,1)
 table.insert(UISpecialFrames,"ApexUIOptions")
 local close=CreateFrame("Button",nil,p,"UIPanelCloseButton");close:SetPoint("TOPRIGHT",-6,-6)
 local title=label(p,"ApexUI",24,-20,22)
 if A.Theme then A.Theme.Header(p,title,close,{titleWidth=155}) end
 p.character=label(p,"",210,-31,18,550)
 p.active=label(p,"",26,-74,18,760)
 p.status=label(p,"",26,-103,16,760)
 p.editButtons={};p.selectionButtons={};p.values={}
 local library=CreateFrame("Frame",nil,p);library:SetPoint("TOPLEFT",26,-208);library:SetSize(768,365)
 local controls=CreateFrame("Frame",nil,p);controls:SetPoint("TOPLEFT",26,-208);controls:SetSize(768,365);controls:Hide()
 local layoutsTab,controlsTab
 local function tab(which)
  library:SetShown(which=="layouts");controls:SetShown(which=="controls")
  layoutsTab:SetEnabled(which~="layouts");controlsTab:SetEnabled(which~="controls")
 end
 layoutsTab=button(p,"Saved layouts",26,-155,185,function() tab("layouts") end)
 controlsTab=button(p,"Frames and placement",220,-155,215,function() tab("controls") end)
 p.activate=button(p,"Enable ApexUI",548,-155,246,A.Activate)
 label(library,"LAYOUT LIBRARY",0,0,16)
 p.rows={}
 for i=1,5 do
  local row=CreateFrame("Button",nil,library,"BackdropTemplate")
  row:SetPoint("TOPLEFT",0,-29-(i-1)*49);row:SetSize(326,45)
  row:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
  row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight","ADD")
  row.title=label(row,"",10,-5,16,304);row.title:SetWordWrap(false)
  row.detail=label(row,"",10,-25,12,304);row.detail:SetWordWrap(false)
  row:SetScript("OnClick",function(self) A.selectedLayoutId=self.id;A.layoutNotice=nil;A.UpdateOptions() end)
  p.rows[i]=row
 end
 p.prev=button(library,"Previous",0,-283,105,function() p.page=p.page-1;A.UpdateOptions() end)
 p.pageText=label(library,"",139,-292,16)
 p.next=button(library,"Next",221,-283,105,function() p.page=p.page+1;A.UpdateOptions() end)
 label(library,"LAYOUT NAME",355,0,16)
 p.name=CreateFrame("EditBox",nil,library,"InputBoxTemplate")
 p.name:SetPoint("TOPLEFT",361,-31);p.name:SetSize(396,32);p.name:SetAutoFocus(false);p.name:SetMaxLetters(48)
 p.name:SetFont(FONT,17,"");p.name:SetScript("OnEscapePressed",function(self) self:ClearFocus() end)
 p.name:SetScript("OnEnterPressed",function(self) self:ClearFocus() end)
 local function chosenPage()
  for i,item in ipairs(A.LayoutList()) do if item.id==A.selectedLayoutId then p.page=math.ceil(i/5);break end end
  A.UpdateOptions()
 end
 table.insert(p.editButtons,button(library,"Save current as new",355,-76,198,function()
  if A.SaveNamedLayout(p.name:GetText()) then p.name:ClearFocus();chosenPage() end
 end))
 table.insert(p.selectionButtons,button(library,"Rename selected",563,-76,198,function()
  if A.RenameLayout(A.selectedLayoutId,p.name:GetText()) then p.name:ClearFocus();chosenPage() end
 end))
 table.insert(p.selectionButtons,button(library,"Update selected from current",355,-118,406,function() A.UpdateNamedLayout(A.selectedLayoutId) end))
 p.selection=label(library,"",355,-165,15,406)
 table.insert(p.selectionButtons,button(library,"Load for this character",355,-232,406,function() A.LoadNamedLayout(A.selectedLayoutId,"character") end))
 table.insert(p.selectionButtons,button(library,"Use as shared default",355,-274,406,function() A.LoadNamedLayout(A.selectedLayoutId,"shared") end))
 p.shared=button(p,"Return to shared default",26,-550,246,A.UseSharedDefault)
 p.custom=button(p,"Make a character copy",284,-550,246,A.CustomizeCharacter)
 p.undo=button(p,"Undo last layout load",542,-550,246,A.UndoTemplate)
 p.notice=label(p,"",26,-602,15,760)
 label(controls,"FRAME READABILITY",0,0,16)
 local rows={{key="text",name="Combat text",delta=1},{key="width",name="Player / target width",delta=10},
  {key="pet",name="Pet frame width",delta=10},{key="auras",name="Aura icon size",delta=2}}
 for i,r in ipairs(rows) do
  local y=-36-(i-1)*43
  label(controls,r.name,0,y-7,17)
  p.values[r.key]=label(controls,"",238,y-7,16)
  table.insert(p.editButtons,button(controls,"-",365,y,44,function() adjust(r.key,-r.delta) end))
  table.insert(p.editButtons,button(controls,"+",419,y,44,function() adjust(r.key,r.delta) end))
 end
 label(controls,"Move individual elements with the familiar in-game editor.\nChanges affect the scope shown at the top of this window.",0,-222,16,760)
 table.insert(p.editButtons,button(controls,"Move frames and bars",0,-285,246,A.Unlock))
 table.insert(p.editButtons,button(controls,"Action bar settings",264,-285,246,function() if A.OpenBarOptions then A.OpenBarOptions() end end))
 table.insert(p.editButtons,button(controls,"Return to original UI",528,-285,230,A.Restore))
 p:SetScript("OnShow",A.UpdateOptions)
 p:SetScript("OnHide",function() p.name:ClearFocus() end)
 p:RegisterEvent("PLAYER_REGEN_DISABLED");p:RegisterEvent("PLAYER_REGEN_ENABLED")
 p:SetScript("OnEvent",function(self) if self:IsShown() then A.UpdateOptions() end end)
 tab("layouts");A.UpdateOptions();if A.Theme then A.Theme.Attach(p) end
end
function A.CreateLauncher()
 -- Apex Toolkit is the single launcher; keep the map free of duplicate buttons.
 if A.launcher then A.launcher:Hide() end
end
