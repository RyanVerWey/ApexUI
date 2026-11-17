from pathlib import Path
from lupa.lua51 import LuaRuntime
root=Path(__file__).resolve().parents[1]
lua=LuaRuntime(unpack_returned_tuples=True)
lua.execute('''
A={showSpots=true,state={},activeStep={session='batch'}}; ApexFishingDB={spotChoice={}}; frames={}
function CreateFrame()
 local f={shown=true,scripts={}}
 setmetatable(f,{__index=function(_,k)
  if k=='CreateTexture' then return function() return CreateFrame() end end
  if k=='SetScript' then return function(s,e,fn) s.scripts[e]=fn end end
  if k=='Show' then return function(s) s.shown=true end end
  if k=='Hide' then return function(s) s.shown=false end end
  if k=='SetPoint' then return function(s,anchor,parent,relative,x,y) s.x=x;s.y=y end end
  if k=='SetSize' then return function(s,w,h) s.w=w;s.h=h end end
  if k=='GetWidth' then return function() return 1000 end end
  if k=='GetHeight' then return function() return 700 end end
  if k=='GetFrameLevel' then return function() return 5 end end
  if k=='GetEffectiveScale' then return function() return .25 end end
  return function() end
 end})
 frames[#frames+1]=f; return f
end
local canvas=CreateFrame()
UIParent={GetEffectiveScale=function() return 1 end}
WorldMapFrame={GetMapID=function() return 1433 end,GetCanvas=function() return canvas end,IsShown=function() return true end}
C_Map={}
A.AvailableSpots=function() return {{id='water',map=1433,x=32,y=53,radius=5,label='Lake',fish={6308}}} end
A.ClearWaypoint=function() end; A.Render=function() end
''')
lua.execute('local code=...; assert(loadstring(code))("ApexFishing",A)',(root/'SpotMap.lua').read_text())
lua.execute('''
A.RefreshSpotMap()
local pin
for _,f in ipairs(frames) do if rawget(f,'spot') then pin=f end end
assert(pin and math.abs(pin.x-320)<.001 and math.abs(pin.y+371)<.001 and pin.shown,'Native map uses zone-relative coordinates')
assert(pin.w==104 and pin.h==104,'Icons retain a 26 UI-pixel hit target on a quarter-scale map canvas')
pin.scripts.OnClick(pin); assert(ApexFishingDB.spotChoice.batch=='water')
function CreateVector2D(x,y) return {GetXY=function() return x,y end} end
C_Map.GetWorldPosFromMapPos=function() return 0,CreateVector2D(10,20) end
OpenMapAPI={IsStitched=function() return true end,CanvasFromWorldPos=function() return .4,.6 end,ArtTopLevel=function() return 40 end}
A.RefreshSpotMap(); assert(pin.x==400 and pin.y==-420,'Stitched map uses the public canvas conversion')
OpenMapAPI.CanvasFromWorldPos=function() return 1.4,-.2 end
A.RefreshSpotMap(); assert(pin.shown and pin.x==1400 and pin.y==140,'Stitched pins outside host map bounds remain visible')
A.showSpots=false; A.RefreshSpotMap(); assert(not pin.shown)
''')
for file in root.glob('*.lua'):
    lua.execute('assert(loadstring(...))',file.read_text())
print('PASS: native/stitched map marker placement, spot selection, hidden overlay, all addon Lua syntax.')
