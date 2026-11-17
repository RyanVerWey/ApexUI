local _,A=...
local B=A.Backend
local styled={}
local function border(frame)
 if not frame or styled[frame] then return end
 local panel=CreateFrame("Frame",nil,frame,"BackdropTemplate");styled[frame]=panel
 panel:SetAllPoints();panel:EnableMouse(false);panel:SetFrameLevel(math.max(0,frame:GetFrameLevel()-1))
 B.FrameBorder(panel);panel:SetBackdropColor(.035,.030,.026,.94)
 local line=panel:CreateTexture(nil,"OVERLAY");line:SetColorTexture(.72,.53,.29,.85)
 line:SetHeight(2);line:SetPoint("TOPLEFT",5,-2);line:SetPoint("TOPRIGHT",-5,-2)
 -- Keep native buttons, tooltips, scrolling, secure controls and third-party skins.
end
function A.StyleNativeWindows()
 if not A.OwnActive() or InCombatLockdown() then return end
 for _,name in ipairs({"CharacterFrame","SpellBookFrame","QuestLogFrame","GossipFrame","QuestFrame","MerchantFrame","FriendsFrame","GameMenuFrame","LootFrame","TaxiFrame","MailFrame","BankFrame","ClassTrainerFrame","TradeSkillFrame"}) do border(_G[name]) end
 if A.StyleChat then A.StyleChat() end
end
local e=CreateFrame("Frame")
for _,event in ipairs({"PLAYER_ENTERING_WORLD","ADDON_LOADED","PLAYER_REGEN_ENABLED"}) do e:RegisterEvent(event) end
e:SetScript("OnEvent",function() C_Timer.After(.5,A.StyleNativeWindows) end)
