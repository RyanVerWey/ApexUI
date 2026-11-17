from pathlib import Path
from lupa.lua51 import LuaRuntime
root=Path(__file__).resolve().parents[1]
lua=LuaRuntime(unpack_returned_tuples=True)
lua.execute('''
A={}; frames={}; SlashCmdList={}; UIParent={}; now=10; stops=0; clears=0
function GetTime() return now end
function UnitChannelInfo() if channel then return 'Fishing',nil,nil,10000,30000,nil,nil,7620 end end
C_Spell={GetSpellName=function() return 'Fishing' end}
ERR_FISH_NOT_HOOKED='not hooked'; ERR_FISH_ESCAPED='escaped'
function CreateFrame(kind,name,parent)
 local f={scripts={},shown=true,w=480,h=610,children={}}
 if parent and parent.children then table.insert(parent.children,f) end
 setmetatable(f,{__index=function(self,k)
  if k=='CreateFontString' or k=='CreateTexture' then return function() return CreateFrame() end end
  if k=='SetScript' then return function(s,e,fn) s.scripts[e]=fn end end
  if k=='Show' then return function(s) s.shown=true end end
  if k=='Hide' then return function(s) local was=s.shown; s.shown=false; if was and s.scripts.OnHide then s.scripts.OnHide(s) end end end
  if k=='IsShown' then return function(s) return s.shown end end
  if k=='SetSize' then return function(s,w,h) s.w=w; s.h=h end end
  if k=='SetWidth' then return function(s,w) s.w=w end end
  if k=='SetHeight' then return function(s,h) s.h=h end end
  if k=='GetWidth' then return function(s) return s.w end end
  if k=='GetHeight' then return function(s) return s.h end end
  if k=='GetChildren' then return function(s) return unpack(s.children) end end
  if k=='SetText' then return function(s,t) s.text=t end end
  if k=='GetStringHeight' then return function() return 25 end end
  return function() end
 end})
 frames[#frames+1]=f; return f
end
A.ReadSkills=function() return {f=150,fcap=225,c=140,ccap=225,faction='Alliance',level=30} end
A.DetectOrigin=function() return 'elwynn' end
A.BuildRoute=function() return {{id='fish',title='Fish to 175',body='Fish here',kind='skill',skill='f',target=175}} end
A.Pending=function() return {1} end
A.Blocked=function() end
A.ClearWaypoint=function() clears=clears+1 end
A.UpdateNavigation=function() end
A.InitControls=function() end
A.StopFishing=function() stops=stops+1; A.fishingMode=false end
A.ToggleFishing=function() A.fishingMode=not A.fishingMode end
A.points={}
''')
for file in ('UI.lua','Mini.lua'):
    lua.execute('local code=...; assert(loadstring(code))("ApexFishing",A)',(root/file).read_text())
lua.execute('''
frames[1].scripts.OnEvent(nil,'ADDON_LOADED','ApexFishing')
assert(A.frame:IsShown())
A.fishingMode=true
A.SetCompact(true)
assert(A.mini:IsShown() and not A.frame:IsShown() and A.IsGuideVisible())
assert(A.fishingMode and stops==0,'Minimizing must not restore weapons or clear fishing bindings')
assert(A.mini.w==370 and A.mini.h==220 and ApexFishingDB.compact)
assert(A.mini.skills.text=='Fishing 150/225  |  Cooking 140/225')
assert(A.mini.step.text=='Fish to 175')
A.SetCompact(false)
assert(A.frame:IsShown() and not A.mini:IsShown() and stops==0 and A.fishingMode)
SlashCmdList.APEXFISHING('mini'); assert(A.mini:IsShown() and A.fishingMode)
channel=true; A.RefreshMini()
assert(A.mini.line.text=='LINE OUT')
local label,detail,value=A.FishingLineState(); assert(value==1 and detail:find('20s'))
now=25; label,detail,value=A.FishingLineState(); assert(label=='LINE OUT' and value==.25)
-- Passage of time alone never claims a fish has bitten.
now=29; A.RefreshMini(); assert(A.mini.line.text=='LINE OUT')
channel=false
frames[2].scripts.OnEvent(nil,'UI_ERROR_MESSAGE',0,ERR_FISH_NOT_HOOKED)
assert(A.mini.line.text=='TOO EARLY')
frames[2].scripts.OnEvent(nil,'UI_ERROR_MESSAGE',0,ERR_FISH_ESCAPED)
assert(A.mini.line.text=='FISH GOT AWAY')
frames[2].scripts.OnEvent(nil,'LOOT_OPENED')
assert(A.mini.line.text=='LOOT OPEN')
now=34; A.RefreshMini(); assert(A.mini.line.text=='READY TO CAST')
local old=A.lineNotice
frames[2].scripts.OnEvent(nil,'LOOT_OPENED'); assert(A.lineNotice==old,'Unrelated later loot ignored')
SlashCmdList.APEXFISHING('')
assert(not A.IsGuideVisible() and stops==1 and not A.fishingMode and ApexFishingDB.hidden)
SlashCmdList.APEXFISHING('show'); assert(A.mini:IsShown() and not A.frame:IsShown())
SlashCmdList.APEXFISHING('full'); assert(A.frame:IsShown() and not A.mini:IsShown())
''')
print('PASS: full/compact visibility, no fishing interruption on view switch, size/skills/step, genuine line duration, error/loot feedback, no timer-based bite alert, close/reopen.')
