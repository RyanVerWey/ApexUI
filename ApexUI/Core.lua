local _, A = ...
_G.ApexUI=A
local function msg(s) print("|cffd7b46aApexUI|r: "..s) end
A.Print=msg
local function Ready()
 if not A.ProfileDB then A.Backend.InitializeProfiles() end
 local e=A.Backend
 return e and e.GetActiveProfileName and e.SwitchProfile and e._ModuleNS
  and e._ModuleNS[A.UF] and e._ModuleNS[A.UF].db and e._ModuleNS[A.UF].PAB_ApplyLiveConfig
  and A.ProfileDB and A.ProfileDB.profiles
end
function A.Safe(fn)
 if InCombatLockdown() then A.pending=fn;msg("Layout change queued until combat ends.");return false end
 fn();return true
end
function A.Active()
 return A.ProfileDB.profiles[A.Backend.GetActiveProfileName()]
end
function A.OwnActive()
 return A.ready and not A.Backend.conflict and ApexUICharacterDB.enabled~=false
  and A.Backend.GetActiveProfileName()==ApexUICharacterDB.profile
end
function A.Refresh()
 if not A.OwnActive() then return end
 local p=A.Active()
 if not p.apexXPReadout then
  local live=A.Backend._ModuleNS[A.AB]
  local profiles={p.addons[A.AB]}
  if live and live.db and live.db.profile then profiles[#profiles+1]=live.db.profile end
  for _,ab in ipairs(profiles) do
   local xp=ab.bars and ab.bars.XPBar
   if xp then
    xp.textSlotCenter="curMax,pct";xp.textSlotCenterRested=false
    xp.showRawValues=true;xp.showPercent=true
   end
  end
  p.apexXPReadout=true
 end
 A.Backend.Apply()
 if A.UpdateOptions then A.UpdateOptions() end
 if A.ScheduleDecorations then A.ScheduleDecorations() end
 if A.RefreshUtility then C_Timer.After(.2,A.RefreshUtility) end
end
local function register(name,p)
 A.ProfileDB.profiles[name]=p
 A.ProfileDB.profileOrder=A.ProfileDB.profileOrder or {}
 for _,s in ipairs(A.ProfileDB.profileOrder) do if s==name then return end end
 table.insert(A.ProfileDB.profileOrder,name)
end
function A.Activate()
 A.Safe(function()
  ApexUICharacterDB.enabled=true
  A.Backend.SwitchProfile(ApexUICharacterDB.profile)
  C_Timer.After(0,function() A.Refresh() end)
  C_Timer.After(1,function()
   if A.SyncGuideAppearance then A.Safe(A.SyncGuideAppearance) end
   if A.QueueUtilityRestore then A.QueueUtilityRestore() end
  end)
  msg("Loaded "..ApexUICharacterDB.profile..". /apexui opens settings.")
 end)
end
function A.Edit(fn)
 A.Safe(function()
  if not A.OwnActive() then msg("Enable this character's ApexUI profile first.");return end
  fn(A.Active().addons[A.UF]);A.Refresh()
 end)
end
function A.SaveTemplate()
 A.Safe(function()
  if not A.OwnActive() then msg("Enable this character's ApexUI profile first.");return end
  if A.Backend.AutoSaveActiveProfile then A.Backend.AutoSaveActiveProfile() end
  local snapshot=A.CaptureLayout and A.CaptureLayout() or A.Copy(A.Active())
  snapshot.fonts=A.Copy(A.Backend.GetFontsDB())
  -- Live mover relationships are banked by the suite on profile change/logout.
  if A.ProfileDB.unlockAnchors then snapshot.unlockLayout.anchors=A.Copy(A.ProfileDB.unlockAnchors) end
  if ApexUICharacterDB.customLayout then
   ApexUICharacterDB.customSnapshot=snapshot
   msg("Saved this character's custom layout snapshot. Shared default unchanged.")
  else
   ApexUIDB.sharedSnapshot=snapshot
   if A.SaveGuideAppearance then A.SaveGuideAppearance() end
   msg("Saved the shared default for all characters. Pet frames follow the active pet.")
  end
 end)
end
function A.UseTemplate(snapshot)
 A.Safe(function()
  if not A.OwnActive() then msg("Enable this character's ApexUI profile first.");return end
  local char=ApexUICharacterDB
  char.undo=A.Copy(A.Active());char.undo.fonts=A.Copy(A.Backend.GetFontsDB())
  if char.customLayout then char.undoLayoutId=char.savedLayoutId else char.undoLayoutId=ApexUIDB.sharedLayoutId end
  -- Switch away before replacing the table, so the suite banks the outgoing state safely.
  A.Backend.SwitchProfile(char.original)
  local saved=char.customLayout and char.customSnapshot or ApexUIDB.sharedSnapshot
  register(char.profile,A.Copy(type(snapshot)=="table" and snapshot.addons and snapshot or saved))
  A.Backend.SwitchProfile(char.profile);C_Timer.After(0,A.Refresh)
  msg("Layout snapshot applied. Undo restores the previous layout.")
 end)
end
function A.UndoTemplate()
 A.Safe(function()
  local char=ApexUICharacterDB
  if not char.undo then msg("No template change to undo.");return end
  if not A.OwnActive() then msg("Enable this character's ApexUI profile first.");return end
  A.Backend.SwitchProfile(char.original)
  register(char.profile,A.Copy(char.undo));char.undo=nil
  if char.customLayout then char.savedLayoutId=char.undoLayoutId else ApexUIDB.sharedLayoutId=char.undoLayoutId end
  char.undoLayoutId=nil
  A.Backend.SwitchProfile(char.profile);C_Timer.After(0,A.Refresh)
  msg("Previous character layout restored.")
 end)
end
function A.Restore()
 A.Safe(function()
  ApexUICharacterDB.enabled=false
  A.Backend.SwitchProfile(ApexUICharacterDB.original)
  msg("ApexUI paused. Reloading restores the native UI; your layouts remain saved.")
  if A.UpdateOptions then A.UpdateOptions() end
  if A.ScheduleDecorations then A.ScheduleDecorations() end
  ReloadUI()
 end)
end
function A.Unlock()
 A.Safe(function()
  if not A.OwnActive() then msg("Enable this character's ApexUI profile first.");return end
  if A.panel then A.panel:Hide() end
  A.Backend:OpenUnlockMode()
 end)
end
function A.CustomizeCharacter()
 A.Safe(function()
  local char=ApexUICharacterDB
  if not A.OwnActive() then msg("Enable ApexUI first.");return end
  if char.customLayout then msg("This character already has a custom layout.");return end
  if A.Backend.AutoSaveActiveProfile then A.Backend.AutoSaveActiveProfile() end
  local snapshot=A.CaptureLayout and A.CaptureLayout() or A.Copy(A.Active());snapshot.fonts=A.Copy(A.Backend.GetFontsDB())
  if A.ProfileDB.unlockAnchors then snapshot.unlockLayout.anchors=A.Copy(A.ProfileDB.unlockAnchors) end
  local name,realm=UnitFullName("player");local stem="ApexUI - Custom - "..name.." - "..(realm or GetRealmName())
  local key=stem;local i=1
  while A.ProfileDB.profiles[key] do i=i+1;key=stem.." "..i end
  register(key,snapshot);char.customSnapshot=A.Copy(snapshot);char.customLayout=true;char.profile=key;char.undo=nil
  char.savedLayoutId=nil
  A.Activate();msg("Custom layout starts from the shared default. Changes now affect only this character.")
 end)
end
function A.UseSharedDefault()
 A.Safe(function()
  local char=ApexUICharacterDB
  if char.customLayout then char.previousCustomProfile=char.profile end
  char.customLayout=false;char.profile=ApexUIDB.sharedProfile;char.undo=nil
  A.utilitiesRestoredThisLogin=nil
  A.Activate();msg("Using the shared default. Any previous custom profile is retained.")
 end)
end
function A.Initialize()
 if A.ready then return true end
 if not Ready() then return false end
 if InCombatLockdown() then A.pending=A.Initialize; return true end
 ApexUIDB=ApexUIDB or {version=1,templates={}}
 ApexUIDB.templates=ApexUIDB.templates or {}
 ApexUICharacterDB=ApexUICharacterDB or {}
 local char=ApexUICharacterDB
 local _,class=UnitClass("player");A.class=class
 local current=A.Backend.GetActiveProfileName()
 if not ApexUIDB.base then
  ApexUIDB.base=A.Copy(A.Active());ApexUIDB.base.fonts=A.Copy(A.Backend.GetFontsDB())
  ApexUIDB.original=current
 end
 char.original=char.original or ApexUIDB.original or current
 char.class=class
 if char.enabled==nil then char.enabled=true end
 if not A.ProfileDB.profiles[char.original] then
  char.original="ApexUI - Original backup"
  if not A.ProfileDB.profiles[char.original] then register(char.original,A.Copy(ApexUIDB.base)) end
 end
 -- One suite profile is authoritative. Never rebuild another class from the old baseline.
 -- The Hunter snapshot is the explicitly saved, finished two-row layout from v0.1.0.
 if not ApexUIDB.sharedProfile then
  local seed=ApexUIDB.templates.HUNTER or (char.profile and A.ProfileDB.profiles[char.profile])
   or A.BuildTemplate(ApexUIDB.base,"HUNTER")
  local name="ApexUI - Shared layout";local suffix=1
  while A.ProfileDB.profiles[name] do suffix=suffix+1;name="ApexUI - Shared layout "..suffix end
  ApexUIDB.sharedProfile=name
  ApexUIDB.sharedSnapshot=A.Copy(seed)
 end
 if not A.ProfileDB.profiles[ApexUIDB.sharedProfile] then
  register(ApexUIDB.sharedProfile,A.Copy(ApexUIDB.sharedSnapshot))
 end
 if not char.customLayout and char.profile~=ApexUIDB.sharedProfile then
  char.previousProfile=char.previousProfile or char.profile
  char.profile=ApexUIDB.sharedProfile
  char.undo=nil -- Old per-class undo must not replace the shared layout.
  char.sharedUtilitiesPlaced=nil
 end
 if char.customLayout and not A.ProfileDB.profiles[char.profile] then
  register(char.profile,A.Copy(char.customSnapshot or ApexUIDB.sharedSnapshot))
 end
 ApexUIDB.version=2
 A.utilitiesRestoredThisLogin=nil
 A.ready=true
 if char.enabled~=false then A.Activate() end
 if A.CreateLauncher then A.CreateLauncher() end
 return true
end
local attempts=0
local function retry()
 if A.Initialize() then return end
 attempts=attempts+1
 if attempts<20 then C_Timer.After(.5,retry)
 else msg("ApexUI frames are not ready. Reload to retry.") end
end
local events=CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN");events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:SetScript("OnEvent",function(_,event)
 if event=="PLAYER_LOGIN" then C_Timer.After(1,retry)
 elseif A.pending then local fn=A.pending;A.pending=nil;fn() end
end)
SLASH_APEXUI1="/apexui";SLASH_APEXUI2="/aui"
SlashCmdList.APEXUI=function(cmd)
 cmd=(cmd or ""):lower():match("^%s*(.-)%s*$")
 if not A.ready then if not A.Initialize() then msg("Waiting for ApexUI to finish loading.") end;return end
 if cmd=="unlock" then A.Unlock()
 elseif cmd=="enable" then A.Activate()
 elseif cmd=="restore" then A.Restore()
 elseif cmd=="save" then A.SaveTemplate()
 elseif cmd=="customize" then A.CustomizeCharacter()
 elseif cmd=="shared" then A.UseSharedDefault()
 elseif cmd=="repair" then A.Safe(function()
  A.Refresh();A.utilitiesRestoredThisLogin=nil
  if A.SyncGuideAppearance then A.SyncGuideAppearance() end
  if A.QueueUtilityRestore then A.QueueUtilityRestore() end
 end)
 elseif cmd=="template" then A.UseTemplate()
 elseif cmd=="defaults" then A.UseTemplate(ApexUIDB.sharedSnapshot)
 elseif cmd=="center" then A.UseTemplate(A.CenterCombatLayout(A.Active()))
 elseif cmd=="utility" then A.Safe(function() A.UseTemplate(A.UtilityLayout(A.Active()));C_Timer.After(1,A.PlaceNativeUtilities) end)
 elseif cmd=="thirdrow" then A.Safe(function() A.UseTemplate(A.ThirdRowLayout(A.Active())) end)
 elseif cmd=="tworows" then A.Safe(function() A.UseTemplate(A.TwoRowLayout(A.Active())) end)
 elseif cmd=="undo" then A.UndoTemplate()
 elseif cmd=="status" then
  msg("v"..A.VERSION.." | "..A.ClassInfo(A.class).label.." | "..A.Backend.GetActiveProfileName())
 elseif cmd=="layouts" or cmd=="options" then A.ToggleOptions()
 elseif A.Suite and A.Suite.modules[cmd] then A.Suite.Open(cmd)
 else A.ToggleFeatures() end
end
