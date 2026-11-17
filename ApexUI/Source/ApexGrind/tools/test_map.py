"""Map projection and interaction tests with native and stitched canvas fixtures."""
from pathlib import Path
from lupa.lua51 import LuaRuntime
import struct

root=Path(__file__).resolve().parents[1]
lua=LuaRuntime(unpack_returned_tuples=True)
lua.execute('''
A={db={circles=true},current={level=29}}; frames={}
local methods={}
function methods:SetScript(name,fn) self.scripts[name]=fn end
function methods:CreateTexture() return CreateFrame() end
function methods:SetPoint(_,parent,_,x,y) self.x=x;self.y=y end
function methods:SetSize(w,h) self.w=w;self.h=h end
function methods:GetWidth() return self.w or 1000 end
function methods:GetHeight() return self.h or 700 end
function methods:GetFrameLevel() return self.frameLevel or 5 end
function methods:SetFrameLevel(n) self.frameLevel=n end
function methods:GetEffectiveScale() return self.scale or 1 end
function methods:SetParent(p) self.parent=p end
function methods:GetParent() return self.parent end
function methods:Show() self.shown=true end
function methods:Hide() self.shown=false end
function methods:IsShown() return self.shown end
for _,name in ipairs({'SetTexture','SetAllPoints','RegisterForClicks','ClearAllPoints','SetVertexColor','SetAlpha'}) do methods[name]=function() end end
function CreateFrame(_,_,parent)
 local f=setmetatable({scripts={},parent=parent,shown=true},{__index=methods})
 frames[#frames+1]=f;return f
end
UIParent=CreateFrame();canvas=CreateFrame();canvas.scale=.25
shownMap=1431;mapVisible=true
WorldMapFrame={GetMapID=function() return shownMap end,GetCanvas=function() return canvas end,
 IsShown=function() return mapVisible end,SetMapID=function(_,id) shownMap=id end}
C_Map={}
function CreateVector2D(x,y) return {GetXY=function() return x,y end} end
function ToggleWorldMap() mapVisible=not mapVisible end
A.guideChoices={
 {spot={id='first',mob='Test mob',map=1431,x=.3,y=.4,radius=.06,low=27,high=28}},
 {spot={id='second',mob='Other mob',map=1431,x=.6,y=.7,radius=.04,low=27,high=28}},
 {spot={id='remote',map=1440,x=.4,y=.5,radius=.05}}}
A.guideIndex=1
function A.GuideSelection() return A.guideChoices[A.guideIndex] end
function A.Material() return nil end
function A.Render() end
function A.Print() end
''')
lua.execute('assert(loadstring(...))("ApexGrind",A)',(root/'Map.lua').read_text())
lua.execute('''
A.RefreshGrindMap()
assert(#A.grindPins==2,'Do not draw wrong-zone markers without projection support')
local p=A.grindPins[1]
assert(p.spot.id=='first' and p.selected and p.shown)
assert(math.abs(p.x-300)<.01 and math.abs(p.y+280)<.01)
assert(p.w==80,'Center icon retains its screen size on zoomed canvas')
assert(math.abs(p.area.w-128)<.01 and math.abs(p.area.h-89.6)<.01,'Ring encodes geographic extent on both axes')
canvas.scale=2;A.RefreshGrindMap();assert(p.w==10 and math.abs(p.area.w-128)<.01,'Area size must not get clamped to UI-pixel size')
A.grindPins[2].scripts.OnClick(A.grindPins[2])
assert(A.guideIndex==2 and A.db.view=='spots' and A.db.hidden==false)
assert(A.grindPins[1].spot.id=='second' and A.grindPins[1].selected)
A.db.circles=false;A.RefreshGrindMap();assert(not p.shown)
A.db.circles=true;mapVisible=false;A.RefreshGrindMap();assert(not p.shown)
A.ShowGrindMap();assert(mapVisible and shownMap==1431 and p.shown)
-- Native continent projection: remote continents cannot share a fake location.
function C_Map.GetWorldPosFromMapPos(map,pos)
 local x,y=pos:GetXY();return map==1440 and 1 or 0,CreateVector2D(x*100,y*100)
end
function C_Map.GetMapPosFromWorldPos(continent,pos,map)
 if continent~=0 or map~=1415 then return end
 local x,y=pos:GetXY();return map,CreateVector2D(x/200,y/200)
end
shownMap=1415;A.RefreshGrindMap();assert(p.shown and math.abs(p.x-300)<.01 and math.abs(p.y+245)<.01)
assert(not A.grindPins[3])
-- OpenMap canvas positions may lie outside the underlying host-map [0,1] square.
OpenMapAPI={IsStitched=function() return true end,
 CanvasFromWorldPos=function(continent,x,y) if continent==0 then return 1+x/100,-y/100 end end,
 ArtTopLevel=function() return 60 end,
 WorldFromMap=function(map,x,y) return x,y end,
 ShowWorld=function(x,y) focused={x,y} end}
A.RefreshGrindMap()
assert(p.shown and math.abs(p.x-1600)<.01 and math.abs(p.y-490)<.01 and p.frameLevel>=66)
assert(math.abs(p.area.w-85.333333)<.01)
A.ShowGrindMap();assert(focused[1]==.6 and focused[2]==.7)
-- Filter with no matches removes stale markers, including after a level change.
A.guideChoices={};A.RefreshGrindMap();assert(not p.shown)
WorldMapFrame=nil;A.RefreshGrindMap()
''')
art=(root/'GrindArea.tga').read_bytes()
assert len(art)==18+128*128*4
assert struct.unpack('<HH',art[12:16])==(128,128)
assert art[18+4*(64*128+64)+3]>0,'Area needs a translucent fill'
assert art[18+3]==0,'Texture corners must be transparent'
print('PASS: native zone/continent, OpenMap, zoom, geographic radii, selection, filters, map toggle, missing APIs and area texture')
