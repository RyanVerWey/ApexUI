local _,A=...
local B=A.Backend
local panels,tabs={},{}
local hooked=false

local function selected(frame)
 local dock=GENERAL_CHAT_DOCK or GeneralDockManager
 return not frame.isDocked or (dock and dock.selected==frame)
end

local function paintTab(tab,active)
 local skin=tabs[tab]
 if not skin then return end
 skin:SetBackdropColor(active and .13 or .055,active and .105 or .047,.035,.97)
 skin:SetBackdropBorderColor(active and .85 or .43,active and .65 or .34,active and .36 or .23,1)
 skin.line:SetShown(active)
 local text=skin.label
 if text then text:SetTextColor(active and 1 or .83,active and .87 or .78,active and .63 or .68) end
end

local function styleTab(frame)
 local tab=_G[frame:GetName().."Tab"]
 if not tab then return end
 if not tabs[tab] then
  tab:SetFrameStrata("LOW");tab:SetFrameLevel(10)
  for _,part in ipairs({"Left","Middle","Right","ActiveLeft","ActiveMiddle","ActiveRight","HighlightLeft","HighlightMiddle","HighlightRight"}) do
   local tex=tab[part] or _G[tab:GetName()..part]
   if tex and tex.SetTexture then tex:SetTexture(nil) end
  end
  -- A child backdrop can composite over its button's FontString on Classic.
  -- Use a sibling surface with explicit visibility instead.
  local skin=CreateFrame("Frame",nil,UIParent,"BackdropTemplate")
  tabs[tab]=skin;skin:EnableMouse(false)
  skin:SetFrameStrata("MEDIUM");skin:SetFrameLevel(1)
  skin:SetShown(tab:IsShown())
  tab:HookScript("OnShow",function() skin:Show() end)
  tab:HookScript("OnHide",function() skin:Hide() end)
  skin:SetPoint("TOPLEFT",tab,"TOPLEFT",2,-1)
  skin:SetPoint("BOTTOMRIGHT",tab,"BOTTOMRIGHT",-2,1)
  B.FrameBorder(skin)
  skin.label=skin:CreateFontString(nil,"OVERLAY")
  skin.label:SetFont(A.FONT,14,"OUTLINE");skin.label:SetPoint("CENTER",0,0)
  skin.label:SetText(tab:GetText() or "")
  hooksecurefunc(tab,"SetText",function(_,name) skin.label:SetText(name or "") end)
  local line=skin:CreateTexture(nil,"OVERLAY")
  line:SetColorTexture(.12,.67,.88,1);line:SetHeight(2)
  line:SetPoint("BOTTOMLEFT",7,3);line:SetPoint("BOTTOMRIGHT",-7,3);skin.line=line
  local text=tab:GetFontString()
  if text then
   text:SetFont(A.FONT,14,"OUTLINE");text:SetAlpha(0)
  end
  -- Some Classic builds cache tab fade targets before addons load. Keep only
  -- the tab chrome opaque; native message fading is left alone.
  if tab.SetIgnoreParentAlpha then tab:SetIgnoreParentAlpha(true) end
  hooksecurefunc(tab,"SetAlpha",function(self,alpha)
   if A.OwnActive() and alpha and alpha<1 then self:SetAlpha(1) end
  end)
  tab:HookScript("OnEnter",function() skin:SetBackdropBorderColor(.95,.77,.43,1) end)
  tab:HookScript("OnLeave",function() paintTab(tab,selected(frame)) end)
 end
 paintTab(tab,selected(frame))
 tab:SetAlpha(1)
end

local function groupCall(frame,method,legacy,...)
 if frame[method] then frame[method](frame,...)
 elseif _G[legacy] then _G[legacy](frame,...) end
end

function A.EnsureGuildChat()
 if not ApexUICharacterDB or ApexUICharacterDB.chatTabsVersion==1 or not FCF_OpenNewWindow then return end
 local guild
 for i=1,(NUM_CHAT_WINDOWS or 10) do
  local name=GetChatWindowInfo and GetChatWindowInfo(i)
  if name and name:lower()=="guild" then guild=_G["ChatFrame"..i];break end
 end
 -- Respect existing Guild filters. Only a new tab gets our initial subscriptions.
 if not guild then
  guild=FCF_OpenNewWindow("Guild",true)
  if not guild then return end -- Never repurpose a user's window when all slots are used.
  groupCall(guild,"RemoveAllMessageGroups","ChatFrame_RemoveAllMessageGroups")
  groupCall(guild,"RemoveAllChannels","ChatFrame_RemoveAllChannels")
  groupCall(guild,"AddMessageGroup","ChatFrame_AddMessageGroup","GUILD")
  groupCall(guild,"AddMessageGroup","ChatFrame_AddMessageGroup","GUILD_ACHIEVEMENT")
  if guild.editBox then
   guild.editBox:SetAttribute("chatType","GUILD")
   guild.editBox:SetAttribute("stickyType","GUILD")
  end
  local dock=GENERAL_CHAT_DOCK or GeneralDockManager
  if dock and FCFDock_SelectWindow and ChatFrame1 then FCFDock_SelectWindow(dock,ChatFrame1) end
 end
 ApexUICharacterDB.chatTabsVersion=1
end

function A.StyleChat()
 if not A.OwnActive() or InCombatLockdown() then return end
 A.EnsureGuildChat()
 local addons=A.Active().addons
 addons.ApexChat=addons.ApexChat or {}
 addons.ApexChat.chat=addons.ApexChat.chat or {}
 local cfg=addons.ApexChat.chat
 if cfg.apexSurroundVersion~=1 then
  local bar=A.ActionBars and A.ActionBars.frames.MainBar
  local bottom=bar and bar:GetBottom() or 12
  if bar and bar.GetEffectiveScale then bottom=bottom*bar:GetEffectiveScale()/UIParent:GetEffectiveScale() end
  local oldY=cfg.chatPosition and cfg.chatPosition.y or 38
  local height=cfg.chatSize and cfg.chatSize.h or 209
  cfg.chatPosition={point="BOTTOMLEFT",relPoint="BOTTOMLEFT",x=54,y=bottom+12}
  cfg.chatSize={w=cfg.chatSize and cfg.chatSize.w or 556,h=math.max(160,height+oldY-bottom-12)}
  cfg.apexSurroundVersion=1
 end
 -- Native fading reads these values. Keep tab labels visible even when not hovered.
 CHAT_FRAME_TAB_SELECTED_MOUSEOVER_ALPHA=1;CHAT_FRAME_TAB_SELECTED_NOMOUSE_ALPHA=1
 CHAT_FRAME_TAB_NORMAL_MOUSEOVER_ALPHA=1;CHAT_FRAME_TAB_NORMAL_NOMOUSE_ALPHA=1
 for i=1,(NUM_CHAT_WINDOWS or 10) do
  local frame=_G["ChatFrame"..i]
  if frame then
   frame:SetFont(A.FONT,cfg.chatFontSize or 16,"OUTLINE")
   frame:SetShadowOffset(1,-1)
   if frame.SetSpacing then frame:SetSpacing(3) end
   if i==1 and cfg.chatPosition then
    -- Native chat reserves extra screen-edge space for its old edit box.
    -- Our surround already reserves that space; avoid a second hidden inset.
    frame:SetClampRectInsets(0,0,0,0)
    B.Position(frame,cfg.chatPosition)
    if cfg.chatSize then frame:SetSize(cfg.chatSize.w,cfg.chatSize.h) end
   end
   if not panels[frame] then
    for _,part in ipairs({"Background","TopLeftTexture","BottomLeftTexture","TopRightTexture","BottomRightTexture","LeftTexture","RightTexture","BottomTexture","TopTexture"}) do
     local tex=_G[frame:GetName()..part] or frame[part]
     if tex and tex.SetTexture then tex:SetTexture(nil) end
    end
    local panel=CreateFrame("Frame",nil,frame,"BackdropTemplate")
    panels[frame]=panel;panel:EnableMouse(false)
    -- Dock tabs have their own parent hierarchy. Keep the surround below that
    -- hierarchy as well as below the scrolling text, otherwise it dims the tabs.
    panel:SetFrameStrata("BACKGROUND");panel:SetFrameLevel(0)
    -- The scrolling message rectangle stays native; the surround supplies real gutters.
    -- Reserve the left gutter for native voice/chat-menu controls as well.
    panel:SetPoint("TOPLEFT",frame,"TOPLEFT",-40,34)
    panel:SetPoint("BOTTOMRIGHT",frame,"BOTTOMRIGHT",18,-12)
    B.FrameBorder(panel);panel:SetBackdropColor(.025,.027,.031,.88)
    panel:SetBackdropBorderColor(.63,.46,.27,1)
    local rule=panel:CreateTexture(nil,"ARTWORK")
    rule:SetColorTexture(.55,.40,.23,.8);rule:SetHeight(1)
    rule:SetPoint("TOPLEFT",panel,"TOPLEFT",10,-29)
    rule:SetPoint("TOPRIGHT",panel,"TOPRIGHT",-10,-29)
    local gem=panel:CreateTexture(nil,"OVERLAY")
    gem:SetColorTexture(.73,.53,.29,1);gem:SetRotation(math.pi/4)
    gem:SetSize(11,11);gem:SetPoint("TOPLEFT",panel,"TOPLEFT",15,-13)
    local jewel=panel:CreateTexture(nil,"OVERLAY",nil,1)
    jewel:SetColorTexture(.08,.64,.86,1);jewel:SetRotation(math.pi/4)
    jewel:SetSize(7,7);jewel:SetPoint("CENTER",gem,"CENTER")
    for _,side in ipairs({"LEFT","RIGHT"}) do
     local cap=panel:CreateTexture(nil,"OVERLAY");cap:SetColorTexture(.7,.52,.29,.9)
     cap:SetSize(28,2);cap:SetPoint("TOP"..side,panel,"TOP"..side,side=="LEFT" and 1 or -1,-2)
    end
   end
   styleTab(frame)
   if FCFTab_UpdateAlpha then FCFTab_UpdateAlpha(frame) end
  end
 end
 if not hooked then
  hooked=true
  if FCFTab_UpdateColors then hooksecurefunc("FCFTab_UpdateColors",paintTab) end
  if FCF_OpenNewWindow then hooksecurefunc("FCF_OpenNewWindow",function() C_Timer.After(0,A.StyleChat) end) end
 end
end
