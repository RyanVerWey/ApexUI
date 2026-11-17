local _, A = ...

local function notify(message)
 A.layoutNotice=message
 A.Print(message)
 if A.UpdateOptions then A.UpdateOptions() end
end
local function editable()
 if not A.OwnActive() then notify("Enable ApexUI before saving or loading a layout.");return false end
 if InCombatLockdown() then notify("Finish combat before changing layouts.");return false end
 if A.Backend._unlockModeSessionActive then notify("Finish moving frames before saving a layout.");return false end
 return true
end
function A.CaptureLayout()
 if A.Backend.AutoSaveActiveProfile then A.Backend.AutoSaveActiveProfile() end
 local snapshot=A.Copy(A.Active())
 snapshot.fonts=A.Copy(A.Backend.GetFontsDB())
 snapshot.unlockLayout=snapshot.unlockLayout or {}
 for field,live in pairs({anchors="unlockAnchors",widthMatch="unlockWidthMatch",heightMatch="unlockHeightMatch",
  widthMatchExtra="unlockWidthMatchExtra",heightMatchExtra="unlockHeightMatchExtra",phantomBounds="phantomBounds"}) do
  if A.ProfileDB[live] then snapshot.unlockLayout[field]=A.Copy(A.ProfileDB[live]) end
 end
 return snapshot
end
function A.InitLayoutLibrary()
 ApexUIDB.layouts=ApexUIDB.layouts or {}
 ApexUIDB.nextLayoutId=ApexUIDB.nextLayoutId or 0
 if not ApexUIDB.layoutLibraryInitialized then
  local source=A.ProfileDB.profiles[ApexUIDB.sharedProfile] or ApexUIDB.sharedSnapshot
  if not source then return end
  ApexUIDB.nextLayoutId=ApexUIDB.nextLayoutId+1
  local id=ApexUIDB.nextLayoutId
  ApexUIDB.layouts[id]={name="Apex Default",snapshot=A.Copy(source),owner="Shared default",class="ALL"}
  ApexUIDB.sharedLayoutId=id
  ApexUIDB.layoutLibraryInitialized=true
 end
end
function A.LayoutList()
 A.InitLayoutLibrary()
 local list={}
 for id,entry in pairs(ApexUIDB.layouts) do list[#list+1]={id=id,entry=entry} end
 table.sort(list,function(a,b) return a.entry.name:lower()<b.entry.name:lower() end)
 return list
end
function A.CurrentLayoutName()
 local id
 if ApexUICharacterDB.customLayout then id=ApexUICharacterDB.savedLayoutId else id=ApexUIDB.sharedLayoutId end
 local entry=id and ApexUIDB.layouts and ApexUIDB.layouts[id]
 return entry and entry.name or (ApexUICharacterDB.customLayout and "Character copy" or "Apex Default")
end
local function validName(name,exceptId)
 name=(name or ""):match("^%s*(.-)%s*$")
 if name=="" then return nil,"Enter a name for this layout." end
 if #name>48 or name:find("[%c|]") then return nil,"Use up to 48 characters, without chat formatting." end
 for id,entry in pairs(ApexUIDB.layouts) do
  if id~=exceptId and entry.name:lower()==name:lower() then return nil,"That name already exists. Choose another or update the selected save." end
 end
 return name
end
function A.SaveNamedLayout(name)
 if not editable() then return end
 A.InitLayoutLibrary()
 local clean,err=validName(name)
 if not clean then notify(err);return end
 local snapshot=A.CaptureLayout()
 ApexUIDB.nextLayoutId=ApexUIDB.nextLayoutId+1
 local id=ApexUIDB.nextLayoutId
 ApexUIDB.layouts[id]={name=clean,snapshot=snapshot,owner=UnitName("player"),class=A.class,savedAt=time()}
 A.selectedLayoutId=id
 notify("Saved '"..clean.."'. Your active layout has not changed.")
 return id
end
function A.RenameLayout(id,name)
 if not editable() then return end
 A.InitLayoutLibrary()
 local entry=ApexUIDB.layouts[id];if not entry then return end
 local clean,err=validName(name,id)
 if not clean then notify(err);return end
 entry.name=clean
 notify("Renamed saved layout to '"..clean.."'.")
 return true
end
function A.UpdateNamedLayout(id)
 if not editable() then return end
 local entry=ApexUIDB.layouts and ApexUIDB.layouts[id];if not entry then return end
 entry.previousSnapshot=A.Copy(entry.snapshot)
 entry.snapshot=A.CaptureLayout();entry.owner=UnitName("player");entry.class=A.class;entry.savedAt=time()
 notify("Updated '"..entry.name.."' with the current layout.")
 return true
end
function A.LoadNamedLayout(id,scope)
 if not editable() then return end
 local entry=ApexUIDB.layouts and ApexUIDB.layouts[id]
 if not entry or (scope~="shared" and scope~="character") then return end
 if scope=="shared" then
  if ApexUICharacterDB.customLayout then A.UseSharedDefault() end
  A.UseTemplate(entry.snapshot)
  ApexUIDB.sharedSnapshot=A.Copy(entry.snapshot);ApexUIDB.sharedLayoutId=id
 else
  if not ApexUICharacterDB.customLayout then A.CustomizeCharacter() end
  A.UseTemplate(entry.snapshot)
  ApexUICharacterDB.customSnapshot=A.Copy(entry.snapshot);ApexUICharacterDB.savedLayoutId=id
 end
 notify("Loaded '"..entry.name.."' "..(scope=="shared" and "as the shared default." or "for this character only."))
 return true
end
