local _,A=...
local B=A.Backend
-- Only this compatibility boundary reads the old provider's configuration.
local names={EllesmereUIUnitFrames="ApexUnits",EllesmereUIActionBars="ApexBars",
 EllesmereUIMinimap="ApexMinimap",EllesmereUIDataBars="ApexDataBars",EllesmereUIChat="ApexChat"}
function B.NormalizeProfile(source)
 local p=A.Copy(source or {});p.addons=p.addons or {}
 for old,new in pairs(names) do
  if p.addons[old] then p.addons[new]=A.Copy(p.addons[old]);p.addons[old]=nil end
 end
 -- Keep unsupported settings only in the migration backup, never execute them.
 for key in pairs(p.addons) do
  if key~="ApexUnits" and key~="ApexBars" and key~="ApexMinimap" and key~="ApexDataBars" and key~="ApexChat" then p.addons[key]=nil end
 end
 return B.FillDefaults(p)
end
-- Explicit one-time switch, invoked through the addon command, never during combat.
-- Configuration remains saved for rollback; no macros, actions or bindings are rewritten.
function B.EnableStandalone()
 if InCombatLockdown() then A.Print("Finish combat before switching UI renderers.");return end
 if not C_AddOns or not C_AddOns.DisableAddOn then return end
 local disabled={}
 for i=1,C_AddOns.GetNumAddOns() do
  local name=C_AddOns.GetAddOnInfo(i)
  if type(name)=="string" and name:match("^EllesmereUI") then
   disabled[#disabled+1]=name;C_AddOns.DisableAddOn(name)
  end
 end
 ApexUIDB.disabledProviders=disabled
 ReloadUI()
end
SLASH_APEXSTANDALONE1="/apexstandalone"
SlashCmdList.APEXSTANDALONE=function() B.EnableStandalone() end
function B.InitializeProfiles()
 ApexUIDB=ApexUIDB or {};ApexUICharacterDB=ApexUICharacterDB or {}
 local db=ApexUIDB
 if not db.framework then
  local old=EllesmereUIDB
  db.framework={profiles={},profileOrder={},schema=1}
  db.frameworkMigrationBackup={sharedSnapshot=A.Copy(db.sharedSnapshot),base=A.Copy(db.base),
   layouts=A.Copy(db.layouts),templates=A.Copy(db.templates)}
  if old and old.profiles then
   db.frameworkMigrationBackup.provider=A.Copy(old)
   for key,p in pairs(old.profiles) do db.framework.profiles[key]=B.NormalizeProfile(p) end
   db.framework.profileOrder=A.Copy(old.profileOrder or {})
   db.framework.activeProfile=old.activeProfile
  end
  db.base=B.NormalizeProfile(db.base)
  if db.sharedSnapshot then db.sharedSnapshot=B.NormalizeProfile(db.sharedSnapshot) end
  for _,entry in pairs(db.layouts or {}) do entry.snapshot=B.NormalizeProfile(entry.snapshot) end
  for key,p in pairs(db.templates or {}) do db.templates[key]=B.NormalizeProfile(p) end
 end
 A.ProfileDB=db.framework
 for key,p in pairs(A.ProfileDB.profiles) do A.ProfileDB.profiles[key]=B.NormalizeProfile(p) end
 local current=A.ProfileDB.activeProfile or "Apex Original"
 A.ProfileDB.activeProfile=current
 if not A.ProfileDB.profiles[current] then A.ProfileDB.profiles[current]=B.NormalizeProfile(db.sharedSnapshot or db.base) end
 if db.sharedProfile and not A.ProfileDB.profiles[db.sharedProfile] then
  A.ProfileDB.profiles[db.sharedProfile]=B.NormalizeProfile(db.sharedSnapshot)
 end
 local char=ApexUICharacterDB
 if char.customSnapshot then char.customSnapshot=B.NormalizeProfile(char.customSnapshot) end
 if char.undo then char.undo=B.NormalizeProfile(char.undo) end
 for _,key in ipairs({"ApexUnits","ApexBars","ApexMinimap","ApexDataBars"}) do
  B._ModuleNS[key]=B._ModuleNS[key] or {db={}}
  B._ModuleNS[key].db.profile=A.ProfileDB.profiles[current].addons[key]
 end
 -- Both renderers must never compete. Migration can run with the old UI loaded;
 -- its addons are disabled explicitly before the first standalone live test.
 B.conflict=C_AddOns and C_AddOns.IsAddOnLoaded and C_AddOns.IsAddOnLoaded("EllesmereUI")
 if B.conflict then
  print("|cffe3bd78ApexUI:|r Layouts imported. Disable EllesmereUI and its UI modules, then reload to use standalone ApexUI.")
  -- The player already chose standalone for this account. Apply the same
  -- choice on alts whose per-character addon overrides still enable the provider.
  if db.disabledProviders then C_Timer.After(3,function() if not InCombatLockdown() then B.EnableStandalone() end end) end
 end
end
