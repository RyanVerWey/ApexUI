from pathlib import Path
from lupa.lua51 import LuaRuntime

lua=LuaRuntime(unpack_returned_tuples=True)
lua.execute('''
A={}; frames={}; Minimap={}; clicks={}; visible=true
A.frame={IsShown=function() return visible end}
A.ToggleFishing=function() clicks[#clicks+1]='fish' end
SlashCmdList={APEXFISHING=function(cmd) clicks[#clicks+1]=cmd end}
GameTooltip=setmetatable({},{__index=function() return function() end end})
function CreateFrame(kind,name,parent)
 local f={scripts={},kind=kind,name=name,parent=parent}
 function f:SetScript(key,value) self.scripts[key]=value end
 setmetatable(f,{__index=function() return function() end end})
 frames[#frames+1]=f
 return f
end
''')
root=Path(__file__).resolve().parents[1]
lua.execute('assert(loadstring(...))("ApexFishing",A)',(root/'Minimap.lua').read_text())
lua.execute('''
frames[1].scripts.OnEvent()
local b=A.minimapButton
assert(b.kind=='Button' and b.name=='ApexFishingMinimapButton' and b.parent==Minimap)
assert(not b.name:match('%d+$'))
b.scripts.OnClick(b,'LeftButton'); assert(clicks[1]=='')
b.scripts.OnClick(b,'RightButton'); assert(clicks[2]=='fish')
visible=false; b.scripts.OnClick(b,'RightButton'); assert(clicks[3]=='show' and clicks[4]=='fish')
b.scripts.OnEnter(b); b.scripts.OnLeave()
frames[1].scripts.OnEvent(); assert(#frames==2)
''')
print('PASS: minimap collector-compatible name/parent, both click actions, tooltip, duplicate prevention')
