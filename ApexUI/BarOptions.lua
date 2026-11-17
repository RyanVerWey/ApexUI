local _,A=...
local B=A.Backend
local keys={"MainBar","Bar9","Bar4","Bar5","Bar2","Bar3","Bar10","Bar6","Bar7","Bar8","PetBar","StanceBar"}
local labels={MainBar="1  Primary",Bar9="2  Right",Bar4="3  Upper left",Bar5="4  Upper right",Bar2="Utility",Bar3="Extra left",Bar10="Extra right",PetBar="Pet",StanceBar="Stance / aura"}
local panel
local function refresh()
 if not panel then return end
 local bars=A.Active().addons.ApexBars.bars
 for key,row in pairs(panel.rows) do
  local s=bars[key];row.values:SetFormattedText("%d buttons     %d rows     %d px",s.numIcons or 12,s.numRows or 1,s.buttonWidth or 50)
  row.visible:SetText((s.alwaysHidden or s.barVisibility=="never") and "Hidden" or "Shown")
 end
end
function A.ConfigureBar(key,field,delta)
 if InCombatLockdown() or not A.OwnActive() then return end
 local s=A.Active().addons.ApexBars.bars[key];if not s then return end
 if field=="visible" then
  local hidden=s.alwaysHidden or s.barVisibility=="never"
  s.alwaysHidden=not hidden;s.barVisibility=hidden and "always" or "never";s.enabled=hidden
 elseif field=="size" then s.buttonWidth=math.max(20,math.min(80,(s.buttonWidth or 50)+delta));s.buttonHeight=s.buttonWidth
 elseif field=="rows" then s.numRows=math.max(1,math.min(s.numIcons or 12,(s.numRows or 1)+delta))
 elseif field=="count" then
  local max=(key=="PetBar" or key=="StanceBar") and 10 or 12
  s.numIcons=math.max(1,math.min(max,(s.numIcons or max)+delta));s.numRows=math.min(s.numRows or 1,s.numIcons)
 end
 A.Refresh();B.AutoSaveActiveProfile();refresh()
end
function A.OpenBarOptions()
 if not A.OwnActive() or InCombatLockdown() then return end
 if not panel then
  panel=CreateFrame("Frame","ApexBarOptions",UIParent,"BackdropTemplate");panel:SetSize(780,590);panel:SetPoint("CENTER");panel:SetFrameStrata("DIALOG")
  B.FrameBorder(panel);panel.rows={};UISpecialFrames[#UISpecialFrames+1]="ApexBarOptions"
  local title=B.Text(panel,22);title:SetPoint("TOPLEFT",20,-16);title:SetText("Apex action bars")
  local note=B.Text(panel,14);note:SetPoint("TOPLEFT",20,-42);note:SetText("Independent action pages. Changes save to the active layout.")
  for i,text in ipairs({"Buttons","Rows","Size"}) do local h=B.Text(panel,11);h:SetPoint("TOPLEFT",445+(i-1)*68,-64);h:SetText(text) end
  local function button(text,x,y,width,fn)
   local f=CreateFrame("Button",nil,panel,"UIPanelButtonTemplate");f:SetSize(width,28);f:SetPoint("TOPLEFT",x,y);f:SetText(text);f:SetScript("OnClick",fn);return f
  end
  button("X",732,-12,30,function() panel:Hide() end)
  for i,key in ipairs(keys) do
   local y=-78-(i-1)*38;local row={};panel.rows[key]=row
   local name=B.Text(panel,14);name:SetPoint("TOPLEFT",20,y-6);name:SetText(labels[key] or key)
   row.values=B.Text(panel,13);row.values:SetPoint("TOPLEFT",166,y-6)
   for j,field in ipairs({"count","rows","size"}) do
    local x=445+(j-1)*68
    button("-",x,y,29,function() A.ConfigureBar(key,field,field=="size" and -2 or -1) end)
    button("+",x+30,y,29,function() A.ConfigureBar(key,field,field=="size" and 2 or 1) end)
   end
   row.visible=button("Shown",650,y,105,function() A.ConfigureBar(key,"visible") end)
  end
  button("Move bars",20,-548,140,function() panel:Hide();A.Unlock() end)
  button("Done",615,-548,140,function() panel:Hide() end)
  panel:RegisterEvent("PLAYER_REGEN_DISABLED");panel:SetScript("OnEvent",function() panel:Hide() end)
 end
 refresh();panel:Show()
end
SLASH_APEXBARS1="/apexbars"
SlashCmdList.APEXBARS=A.OpenBarOptions
