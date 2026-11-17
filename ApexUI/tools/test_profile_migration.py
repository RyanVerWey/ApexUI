"""Exercise saved layouts with a synthetic legacy profile, without any local account data."""
from pathlib import Path
import runpy
ctx=runpy.run_path(str(Path(__file__).with_name('test_standalone.py')))
lua=ctx['lua'];root=ctx['ROOT']
lua.execute("""
local source=A.Backend.FillDefaults({})
source.addons.EllesmereUIActionBars=source.addons.ApexBars;source.addons.ApexBars=nil
source.addons.EllesmereUIUnitFrames=source.addons.ApexUnits;source.addons.ApexUnits=nil
source.addons.EllesmereUIMinimap=source.addons.ApexMinimap;source.addons.ApexMinimap=nil
source.addons.EllesmereUIActionBars.barPositions.MainBar.x=-301
source.addons.EllesmereUIMinimap.minimap.mapSize=260
EllesmereUIDB={profiles={Original=source},activeProfile='Original',profileOrder={'Original'}}
ApexUIDB={sharedProfile='Original',sharedSnapshot=A.Copy(source)}
local expected=EllesmereUIDB.profiles[EllesmereUIDB.activeProfile]
ApexUIDB.framework=nil;A.ProfileDB=nil;A.ready=nil;oldProviderLoaded=false
ApexUICharacterDB={enabled=true}
assert(A.Initialize());A.Refresh()
local p=A.Active()
for _,key in ipairs({'MainBar','Bar9','Bar4','Bar5'}) do
 local old=expected.addons.EllesmereUIActionBars.barPositions[key]
 local new=p.addons.ApexBars.barPositions[key]
 assert(math.abs(old.x-new.x)<.01 and math.abs(old.y-new.y)<.01,key..' shifted')
end
assert(p.addons.ApexMinimap.minimap.mapSize==expected.addons.EllesmereUIMinimap.minimap.mapSize)
assert(ApexUIDB.frameworkMigrationBackup.provider)
local id=A.SaveNamedLayout('Migration regression');assert(id)
local before=A.Copy(A.Active())
A.CustomizeCharacter();A.Active().addons.ApexUnits.player.frameWidth=399
A.UseSharedDefault();assert(A.Active().addons.ApexUnits.player.frameWidth==before.addons.ApexUnits.player.frameWidth)
-- Switching is scoped to the old UI provider, never unrelated addons.
local disabled={};local installed={'EllesmereUI','Questie','RXPGuides','EllesmereUIActionBars','Auctionator'}
C_AddOns.GetNumAddOns=function() return #installed end
C_AddOns.GetAddOnInfo=function(i) return installed[i] end
C_AddOns.DisableAddOn=function(n) disabled[n]=true end
combat=true;reloaded=false;A.Backend.EnableStandalone();assert(not reloaded and not next(disabled))
combat=false;A.Backend.EnableStandalone()
assert(reloaded and disabled.EllesmereUI and disabled.EllesmereUIActionBars)
assert(not disabled.Questie and not disabled.RXPGuides and not disabled.Auctionator)
""")
print('PASS: synthetic saved profile migration preserves bar coordinates, minimap size, shared isolation and scoped provider switch.')
