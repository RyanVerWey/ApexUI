"""Reproducibly bundle the four Apex tools as isolated ApexUI feature modules."""
from pathlib import Path
import json
import shutil

ROOT=Path(__file__).resolve().parents[1]
MODULES=[('navigation','ApexNavigator'),('fishing','ApexFishing'),('grinding','ApexGrind'),('professions','ApexProfessions')]
BASE=['Framework.lua','Templates.lua','Defaults.lua','Migration.lua','UnitFrames.lua','Party.lua','ActionBars.lua','Auras.lua','Shell.lua','Movers.lua','Core.lua','Utility.lua','Shared.lua','Layouts.lua','Options.lua','BarOptions.lua','Theme.lua','Suite.lua']

def transform(name,rel,source):
    font='Fonts\\\\FRIZQT__.TTF'
    source=source.replace('Interface\\\\AddOns\\\\EllesmereUI\\\\media\\\\fonts\\\\Expressway.TTF',font)
    source=source.replace("STANDARD_TEXT_FONT or 'Fonts\\\\FRIZQT__.TTF'", "'"+font+"'")
    source=source.replace('STANDARD_TEXT_FONT or "Fonts\\\\FRIZQT__.TTF"', '"'+font+'"')
    source=source.replace('Fonts\\\\FRIZQT__.TTF',font)
    if rel in ('UI.lua','Mini.lua'):
        source=source.replace('|cff4de0cd','|cffe3bd78').replace('|cff50d8cd','|cffe3bd78')
        source=source.replace('{.3,.88,.8}','{.89,.74,.47}').replace('{.3,.9,.8}','{.89,.74,.47}')
    if name=='ApexProfessions' and rel=='UI/Widgets.lua':
        source=source.replace('0.620, 0.580, 0.530','0.730, 0.700, 0.640')
        source=source.replace('1.000, 0.820, 0.350','0.890, 0.740, 0.470')
        source=source.replace('0.930, 0.910, 0.880','0.930, 0.900, 0.830')
    source=source.replace('Interface\\\\AddOns\\\\'+name+'\\\\','Interface\\\\AddOns\\\\ApexUI\\\\Modules\\\\'+name+'\\\\')
    if name=='ApexProfessions' and rel=='UI/Widgets.lua':
        source=source.replace('"Interface\\\\AddOns\\\\" .. ADDON .. "\\\\Media\\\\"',
                              '"Interface\\\\AddOns\\\\ApexUI\\\\Modules\\\\ApexProfessions\\\\Media\\\\"')
    if name=='ApexFishing' and rel=='Minimap.lua':
        source=source.replace('local function createButton()', 'local function createButton()\n if A.suiteManaged then return end')
    if name=='ApexNavigator' and rel=='UI.lua':
        source=source.replace('function A.CreateMinimap()', 'function A.CreateMinimap()\n if A.suiteManaged then return end')
    if name=='ApexGrind' and rel=='UI.lua':
        source=source.replace('if Minimap then','if Minimap and not A.suiteManaged then')
    if name=='ApexProfessions' and rel=='UI/Minimap.lua':
        source=source.replace('local function build()', 'local function build()\n    if ns.suiteManaged then return end')
        source=source.replace('function Mini.Toggle()', 'function Mini.Toggle()\n    if ns.suiteManaged then ns.Chat("Open Features with /apexui."); return end')
    source=source.replace('Interface/AddOns/'+name+'/','Interface/AddOns/ApexUI/Modules/'+name+'/')
    return source

def build():
    entries=list(BASE)
    manifest={}
    for key,name in MODULES:
        src=ROOT.parent/name
        toc=(src/(name+'.toc')).read_text(encoding='utf-8-sig').splitlines()
        runtime=[x.strip().replace('\\','/') for x in toc if x.strip().endswith('.lua') and not x.startswith('#')]
        dest=ROOT/'Modules'/name
        manifest[name]=runtime
        # Include full sources, tests, licenses and media alongside runnable wrappers.
        for path in src.rglob('*'):
            if not path.is_file() or '__pycache__' in path.parts:continue
            rel=path.relative_to(src).as_posix()
            target=dest/rel;target.parent.mkdir(parents=True,exist_ok=True)
            if rel in runtime:
                original=path.read_text(encoding='utf-8-sig')
                text=transform(name,rel,original)
                header=(f'-- Generated ApexUI module wrapper; original attribution follows.\n'
                        f'local _, suite = ...\nsuite.Suite.Register("{key}", "{name}/{rel}", function(...)\n'
                        f'local CreateFrame = function(...) return suite.Suite.CreateFrame("{key}", ...) end\n')
                target.write_text(header+text+'\nend)\n',encoding='utf-8')
                raw=dest/'OriginalSource'/rel;raw.parent.mkdir(parents=True,exist_ok=True)
                raw.write_text(original,encoding='utf-8')
            else:shutil.copy2(path,target)
        entries.extend('Modules/'+name+'/'+x for x in runtime)
        bridge=ROOT/'Storage'/name;bridge.mkdir(parents=True,exist_ok=True)
        saved=[x for x in toc if x.startswith('## SavedVariables')]
        (bridge/(name+'.toc')).write_text('\n'.join([
            '## Interface: 16001','## AllowLoadGameType: camelot',
            '## Title: ApexUI Data: '+name.removeprefix('Apex'),
            '## Notes: Required saved-data storage for the ApexUI suite. No standalone feature code.',
            '## Author: ApexInterfectum','## Version: 0.3.0',*saved,'Bridge.lua','']),encoding='utf-8')
        (bridge/'Bridge.lua').write_text('local name=...\nApexUIStorage=ApexUIStorage or {}\nApexUIStorage[name]=true\n',encoding='utf-8')
    entries.extend(['Combat.lua','CombatUI.lua','Progress.lua','Features.lua','Toolbar.lua','Frames/Geometry.lua','Frames/Assets.lua','Frames/Core.lua','Frames/Auras.lua','Frames/Compatibility.lua','PvP.lua','Chat.lua','Skins.lua'])
    (ROOT/'ApexUI.toc').write_text('\n'.join([
        '## Interface: 16001','## AllowLoadGameType: camelot','## Title: ApexUI',
        '## Notes: Shared HUD, guides, live DPS and dungeon party reports.',
        '## Author: ApexInterfectum; profession foundation by Alex P','## Version: 0.3.0','## X-License: GPL-3.0',
        '## Dependencies: '+', '.join(n for _,n in MODULES),
        '## OptionalDeps: RXPGuides, Questie, Auctionator, AuctionDB, TomTom, OpenMap',
        '## SavedVariables: ApexUIDB','## SavedVariablesPerCharacter: ApexUICharacterDB',
        '## IconTexture: Interface\\Icons\\INV_Shield_05',
        *[x.replace('/','\\') for x in entries],'']),encoding='utf-8')
    shutil.copy2(ROOT.parent/'ApexProfessions'/'LICENSE',ROOT/'LICENSE')
    (ROOT/'suite-manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
    print(f'Bundled {sum(map(len,manifest.values()))} feature chunks in ApexUI; generated four saved-data bridges.')

if __name__=='__main__':build()
