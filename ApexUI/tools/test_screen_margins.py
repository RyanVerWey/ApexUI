"""Shared edge migration preserves internal spacing and runs once per layout."""
from pathlib import Path
from lupa.lua51 import LuaRuntime
root=Path(__file__).resolve().parents[1]
lua=LuaRuntime()
lua.execute('A={};function CreateFrame() return {RegisterEvent=function() end,SetScript=function() end} end')
lua.execute((root/'Framework.lua').read_text(),'ApexUI',lua.globals().A)
lua.execute('''
local p={addons={ApexMinimap={minimap={position={point='CENTER',x=100,y=200}}},
 ApexBars={barPositions={MainBar={point='BOTTOM',y=3},Bar9={point='BOTTOM',y=3},Bar4={point='BOTTOM',y=62}}},
 ApexChat={chat={chatPosition={y=26},chatSize={w=556,h=209}}}}}
A.Backend.NormalizeScreenMargins(p)
local map=p.addons.ApexMinimap.minimap.position
local bars=p.addons.ApexBars.barPositions
local chat=p.addons.ApexChat.chat
assert(map.point=='TOPRIGHT' and map.x==-14 and map.y==-14)
assert(bars.MainBar.y==14 and bars.Bar9.y==14 and bars.Bar4.y-bars.MainBar.y==59)
assert(chat.chatPosition.x-40==14 and chat.chatPosition.y-12==14)
local height=chat.chatSize.h
A.Backend.NormalizeScreenMargins(p)
assert(bars.MainBar.y==14 and chat.chatSize.h==height)
-- A later deliberate user move must survive subsequent Apply calls.
map.x=-30;A.Backend.NormalizeScreenMargins(p);assert(map.x==-30)
''')
print('PASS: equal corner margins, preserved row spacing, idempotence, later user adjustments retained.')
