local _, A = ...
-- RestedXP keeps quest progress separate from these presentation settings.
local guideFields={"framePositions","frameSizes","frameHeight","guideFontSize","windowScale",
 "arrowScale","arrowText","hideCompletedSteps","anchorOrientation","activeItemsScale","activeTargetScale"}
local function guideDB()
 local ace=LibStub and LibStub("AceDB-3.0",true)
 if ace and RXPSettings then
  for db in pairs(ace.db_registry or {}) do if db.sv==RXPSettings then return db end end
 end
end
local function appearance(profile)
 local result={}
 for _,key in ipairs(guideFields) do if profile[key]~=nil then result[key]=A.Copy(profile[key]) end end
 return result
end
function A.SaveGuideAppearance()
 if ApexUICharacterDB.customLayout then return end
 local db=guideDB();if not db then return end
 ApexUIDB.guideAppearance=appearance(db.profile)
 ApexUIDB.guideAppearanceVersion=(ApexUIDB.guideAppearanceVersion or 0)+1
 ApexUICharacterDB.guideAppearanceVersion=ApexUIDB.guideAppearanceVersion
end
function A.SyncGuideAppearance()
 if not A.OwnActive() or ApexUICharacterDB.customLayout then return end
 local db=guideDB();if not db then return end
 if not ApexUIDB.guideAppearance then
  -- Seed new installations from the active character, never a named developer profile.
  local source=db.profile
  if not source then return end
  ApexUIDB.guideAppearance=appearance(source);ApexUIDB.guideAppearanceVersion=1
 end
 if ApexUICharacterDB.guideAppearanceVersion==ApexUIDB.guideAppearanceVersion then return end
 ApexUICharacterDB.guideAppearanceBackup=ApexUICharacterDB.guideAppearanceBackup or appearance(db.profile)
 for _,key in ipairs(guideFields) do
  local value=ApexUIDB.guideAppearance[key]
  if value~=nil then db.profile[key]=A.Copy(value) end
 end
 -- Use RestedXP's existing profile-copy refresh to reposition and resize its frames.
 db.callbacks:Fire("OnProfileCopied",db)
 ApexUICharacterDB.guideAppearanceVersion=ApexUIDB.guideAppearanceVersion
end
