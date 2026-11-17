from pathlib import Path
from lupa.lua51 import LuaRuntime

root = Path(__file__).resolve().parents[1]
lua = LuaRuntime(unpack_returned_tuples=True)
lua.execute('''
unpack=unpack or table.unpack
load=loadstring or load
A={}; SlashCmdList={}; inventory={}; level=12; faction='Alliance'
function UnitLevel() return level end
function UnitFactionGroup() return faction end
function GetItemCount(id) return inventory[id] or 0 end
function GetProfessions() return nil,nil,nil,4,5,nil end
function GetProfessionInfo(i)
 if i==4 then return 'Fishing',0,150,225,0,0,356 end
 if i==5 then return 'Cooking',0,100,150,0,0,185 end
end
''')
for name in ('Data.lua', 'Guide.lua', 'Locations.lua'):
    lua.execute('assert(load(...))("ApexFishing", A)', (root/name).read_text())
lua.execute('''
local s=A.ReadSkills()
assert(s.f==150 and s.fcap==225 and s.c==100 and s.ccap==150)
for _,f in ipairs({'Alliance','Horde'}) do
 for _,mode in ipairs({'combined','fishing'}) do
  local route=A.BuildRoute(f,mode); local ids={}
  for _,step in ipairs(route) do
   assert(not ids[step.id]); ids[step.id]=true
   assert(A.points[step.point],step.id)
   assert(step.body and step.title)
   if mode=='fishing' then assert(step.skill~='c') end
  end
  local fresh={f=0,fcap=0,c=0,ccap=0,level=1}
  local pending=A.Pending(route,fresh,{})
  assert(route[pending[1]].id=='learn-f')
  local maxed={f=300,fcap=300,c=300,ccap=300,level=60}
  assert(#A.Pending(route,maxed,{})==0)
  -- Simulate the full route, completing only the objective actually requested.
  local sim={f=0,fcap=0,c=0,ccap=0,level=60}; local done={}
  local iterations=0
  while true do
   local p=A.Pending(route,sim,done); if #p==0 then break end
   local step=route[p[1]]; iterations=iterations+1; assert(iterations<80)
   if step.kind=='cap' then sim[step.skill..'cap']=step.target
   elseif step.kind=='skill' then
    assert(sim[step.skill..'cap']>=step.target,step.id); sim[step.skill]=step.target
   elseif step.kind=='item' then inventory[step.item]=step.target
   else done[step.id]=true end
  end
  assert(sim.f==300); if mode=='combined' then assert(sim.c==300) end
  inventory={}
 end
end
local ar=A.BuildRoute('Alliance','combined'); local hr=A.BuildRoute('Horde','combined')
for _,origin in ipairs({'teldrassil','dunmorogh','elwynn','mulgore','durotar','tirisfal','zephras','riverglades'}) do
 for _,f in ipairs({'Alliance','Horde'}) do
  local route=A.BuildRoute(f,'combined',origin)
  local seen={}
  for _,s in ipairs(route) do assert(A.points[s.point]); assert(not seen[s.id]); seen[s.id]=true end
  assert(#A.Pending(route,{f=300,fcap=300,c=300,ccap=300,level=60},{})==0)
 end
end
C_Map={GetBestMapForUnit=function() return 999 end,GetMapInfo=function(id)
 if id==999 then return {name='Starting cave',parentMapID=1438} end
 return {name='Teldrassil',parentMapID=1414} end}
assert(A.DetectOrigin()=='teldrassil')
C_Map.GetMapInfo=function() return {name='Zephras Isle',parentMapID=947} end
assert(A.DetectOrigin()=='zephras' and A.ResolveMap('Zephras Isle')==999)
C_Map=nil
assert(ar[1].point=='elwynn' and hr[1].point=='mulgore')
for _,step in ipairs(ar) do
 if step.id=='nat-accept' then
  assert(A.Blocked(step,{level=12})); assert(not A.Blocked(step,{level=35}))
 end
 if step.kind=='item' then
  assert(not A.Complete(step,{fcap=225},{}))
  inventory[step.item]=1; assert(A.Complete(step,{fcap=225},{}))
  inventory[step.item]=nil; assert(A.Complete(step,{fcap=300},{}))
 end
 if step.id=='expert-f' then
  assert(not A.Complete(step,{fcap=150},{['expert-f']=true}))
 end
end
local added,removed=0,0
TomTom={AddWaypoint=function(_,map,x,y,opts)
 assert(map and x>0 and x<1 and y>0 and y<1); added=added+1; return added
end,RemoveWaypoint=function(_,id) assert(id>=1 and id<=added); removed=removed+1 end}
A.Navigate(ar[1]); A.Navigate(hr[1]); A.ClearWaypoint()
assert(added==2 and removed==2)
''')
# UI smoke: exercise event load, rendering, navigation, undo, hide, reopen.
lua.execute('''
frames={}; local methods={}
function methods:SetScript(k,v) self.scripts[k]=v end
function methods:RegisterEvent(event) assert(event~='TRADE_SKILL_UPDATE','Removed client event') end
function methods:SetText(v) self.value=v end
function methods:GetStringHeight() return math.ceil(#(self.value or '')/42)*22 end
function methods:GetHeight() return self.h or 295 end
function methods:GetWidth() return self.w or 418 end
function methods:SetSize(w,h) self.w=w; self.h=h end
function methods:SetHeight(h) self.h=h; if self.scripts.OnSizeChanged then self.scripts.OnSizeChanged(self,self.w,h) end end
function methods:GetChildren() local children={}; for _,f in ipairs(frames) do if f.parent==self then children[#children+1]=f end end; return unpack(children) end
function methods:GetCenter() return 800,500 end
function methods:GetEffectiveScale() return 1 end
function methods:Show() self.visible=true end
function methods:Hide() self.visible=false end
function methods:IsShown() return self.visible end
local function widget()
 local w={scripts={},visible=true}
 setmetatable(w,{__index=function(_,k) return methods[k] or function() end end})
 return w
end
function methods:CreateFontString() return widget() end
function methods:CreateTexture() return widget() end
function CreateFrame(_,name,parent,template)
 local w=widget(); w.parent=parent; frames[#frames+1]=w; if name then _G[name]=w end; return w
end
UIParent=widget()
A.InitControls=function() end; A.StopFishing=function() end; A.ToggleFishing=function() end
function UnitChannelInfo() end
function GetTime() return 0 end
''')
lua.execute('assert(load(...))("ApexFishing", A)', (root/'UI.lua').read_text())
lua.execute('assert(load(...))("ApexFishing", A)', (root/'Mini.lua').read_text())
lua.execute('''
frames[1].scripts.OnEvent(frames[1],'ADDON_LOADED','ApexFishing')
assert(A.frame and A.route and ApexFishingDB)
for i=1,30 do A.Render() end
for _,label in ipairs({'Directions','Done','Undo','A+','A-','Review >','<','Current step','Fish in bags','Current step','Fishing only','Fishing + Cooking','-','Full'}) do
 for _,b in ipairs(frames) do if b.value==label then b.scripts.OnClick(b); break end end
end
SlashCmdList.APEXFISHING(''); assert(not A.frame:IsShown())
SlashCmdList.APEXFISHING(''); assert(A.frame:IsShown())
SlashCmdList.APEXFISHING('home'); SlashCmdList.APEXFISHING('lock')
faction='Horde'; A.Render(); assert(A.route[1].point=='mulgore')
''')
print('PASS: Lua syntax, 4 full routes, skill API gaps, level/cap gates, quest items, waypoint ownership, UI lifecycle')
