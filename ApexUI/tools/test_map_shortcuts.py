from pathlib import Path
from lupa.lua51 import LuaRuntime
ROOT=Path(__file__).resolve().parents[1]
lua=LuaRuntime(unpack_returned_tuples=True)
source=(ROOT/'tools/test_standalone.py').read_text()
lua.execute(source.split("lua.execute(r'''",1)[1].split("''')",1)[0])
for file in ['Framework.lua','Shell.lua']:
    lua.execute((ROOT/file).read_text(),'ApexUI',lua.globals().A)
lua.execute('''
local S=A.Shell;S.map=CreateFrame('Frame')
HunterPetJournalMinimapButton=CreateFrame('Button','HunterPetJournalMinimapButton',Minimap)
GearQuestMinimapButton=CreateFrame('Button','GearQuestMinimapButton',Minimap)
local quest=CreateFrame('Button','LibDBIcon10_Questie',Minimap)
LibStub=function() return {GetButtonList=function() return {'Questie'} end,GetMinimapButton=function() return quest end} end
S.CollectMapButtons();assert(not S.addonPanel:IsShown() and not ApexMinimapAddonsToggle)
assert(quest:GetParent()==S.addonPanel and GearQuestMinimapButton:GetParent()==S.addonPanel)
S.ToggleMapButtons();assert(S.addonPanel:IsShown())
S.ToggleMapButtons();assert(not S.addonPanel:IsShown())
combat=true;S.CollectMapButtons();assert(not S.addonPanel:IsShown())
''')
print('PASS: library and custom shortcuts off map, recoverable through picker, no floating toggle')
