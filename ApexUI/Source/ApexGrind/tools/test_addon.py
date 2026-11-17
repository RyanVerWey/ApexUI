"""Execute actual addon code under Lua 5.1 with controlled game events and time."""
from pathlib import Path
from lupa.lua51 import LuaRuntime

root = Path(__file__).resolve().parents[1]
lua = LuaRuntime(unpack_returned_tuples=True)
lua.execute('A = {}')
loader = lua.eval('function(src) return assert(loadstring(src))("ApexGrind", A) end')
for source in root.glob('*.lua'):
    lua.execute('assert(loadstring(...))', source.read_text())
loader((root / 'Stats.lua').read_text())
loader((root / 'Bonuses.lua').read_text())
lua.execute('''
local s=A.NewSession()
A.Advance(s,60,false)
assert(A.Record(s,{level=29,xp=100,cap=1000},{level=29,xp=300,cap=1000},false)==200)
local rate,recent,eta,left=A.Metrics(s,{xp=300,cap=1000})
assert(rate==12000 and recent==12000 and eta==210 and left==700)
-- Level-up boundary, including an award larger than the remaining old-level XP.
A.Record(s,{level=29,xp=950,cap=1000},{level=30,xp=80,cap=1200},false)
assert(s.xp==330 and s.levels==1)
-- Paused gains and time are both excluded.
A.Advance(s,600,true)
A.Record(s,{level=30,xp=80,cap=1200},{level=30,xp=280,cap=1200},true)
assert(s.xp==330 and s.seconds==60)
A.Advance(s,301,false)
local _,r=A.Metrics(s,{xp=280,cap=1200});assert(r==0)
-- Zero time, max-level cap, negative corrections and boosts must not spike rates.
assert(A.Metrics(A.NewSession(),{xp=0,cap=0})==0)
A.Record(s,{level=30,xp=280,cap=1200},{level=30,xp=100,cap=1200},false)
assert(s.xp==330)
A.Record(s,{level=30,xp=100,cap=1200},{level=33,xp=0,cap=2000},false)
assert(s.xp==330 and s.note)
assert(A.Number(1234567)=='1,234,567' and A.Duration(3660)=='1h 1m')
assert(A.Duration(nil)=='--')
''')
print('PASS: accounting, level-up rollover, pause, rolling expiry, zero XP, boost rebasing')

lua.execute('''
now=100;level=29;xp=100;cap=1000;afk=false;timers={};frames={}
function GetTime() return now end
function UnitLevel() return level end
function UnitXP() return xp end
function UnitXPMax() return cap end
function UnitIsAFK() return afk end
function GetXPExhaustion() return 250 end
function UnitClass() return 'Warlock','WARLOCK' end
function UnitFactionGroup() return 'Alliance' end
C_Map={GetBestMapForUnit=function() return 1431 end,GetMapInfo=function() return nil end}
RAID_CLASS_COLORS={WARLOCK={r=.58,g=.51,b=.79}}
SlashCmdList={}
function print() end
C_Timer={After=function(delay,fn) timers[#timers+1]={delay=delay,fn=fn} end}
function flush()
 local pending=timers;timers={}
 for _,t in ipairs(pending) do t.fn() end
end
local methods={}
function methods:SetScript(key,fn) self.scripts[key]=fn end
function methods:GetScript(key) return self.scripts[key] end
function methods:RegisterEvent(event) self.events[event]=true end
function methods:SetText(text) self.text=text end
function methods:SetShown(shown) self.shown=shown end
function methods:SetEnabled(enabled) self.enabled=enabled end
function methods:SetFrameLevel(level) self.frameLevel=level end
function methods:GetFrameLevel() return self.frameLevel or 1 end
function methods:SetDefaultText(value) self.defaultText=value end
function methods:SetupMenu(callback) self.menuCallback=callback;self:GenerateMenu() end
function methods:GenerateMenu()
 local root={entries={},SetScrollMode=function() end}
 function root:CreateRadio(name,selected,callback) self.entries[#self.entries+1]={name=name,selected=selected,callback=callback} end
 self.menuCallback(self,root);self.menuEntries=root.entries
end
function methods:SetHeight(h) self.height=h end
function methods:SetWidth(w) self.width=w end
function methods:SetSize(w,h) self.width=w;self.height=h end
function methods:SetPoint(...) self.point={...} end
function methods:GetPoint() return unpack(self.point) end
function methods:CreateFontString() return CreateFrame() end
function methods:CreateTexture() return CreateFrame() end
function methods:Show() self.shown=true end
function methods:Hide() self.shown=false end
for _,key in ipairs({'SetFont','SetTextColor','SetJustifyH','SetScale','SetMinMaxValues',
 'SetValue','ClearAllPoints','SetClampedToScreen','SetFrameStrata','SetMovable','EnableMouse',
 'SetBackdrop','SetBackdropColor','SetBackdropBorderColor','RegisterForDrag','StartMoving',
 'StopMovingOrSizing','SetStatusBarTexture','SetStatusBarColor','SetAllPoints','SetColorTexture',
 'SetNormalTexture','SetHighlightTexture','RegisterForClicks','SetOwner','AddLine','SetJustifyV'}) do
 methods[key]=function() end
end
function CreateFrame(_,name)
 local f=setmetatable({scripts={},events={},shown=true},{__index=methods})
 frames[#frames+1]=f
 if name then _G[name]=f end
 return f
end
UIParent=CreateFrame();Minimap=CreateFrame();GameTooltip=CreateFrame()
''')
loader((root / 'Spots.lua').read_text())
loader((root / 'Materials.lua').read_text())
loader((root / 'Guide.lua').read_text())
loader((root / 'Core.lua').read_text())
loader((root / 'UI.lua').read_text())
loader((root / 'GuideUI.lua').read_text())
lua.execute('''
A.driver.scripts.OnEvent(nil,'PLAYER_LOGIN')
assert(A.frame and ApexGrindMinimapButton and A.frame.height==560)
assert(A.frame.progressText.text=='100 / 1,000 XP  (10.0%)')
local original=A.db
now=160;xp=300
A.driver.scripts.OnEvent(nil,'PLAYER_XP_UPDATE','player');flush()
assert(A.db.session.xp==200 and A.db.session.seconds==60)
-- Events arrive before game values settle; deferred reads coalesce to one award.
xp=950;A.Sample()
A.driver.scripts.OnEvent(nil,'PLAYER_LEVEL_UP',30)
A.driver.scripts.OnEvent(nil,'PLAYER_XP_UPDATE','player')
level=30;xp=80;cap=1200;flush()
assert(A.db.session.xp==980 and A.db.session.levels==1)
A.TogglePause();now=200;xp=180;A.Sample()
assert(A.db.session.xp==980 and A.db.session.seconds==60)
A.TogglePause();now=260;xp=280;A.Sample()
assert(A.db.session.xp==1080 and A.db.session.seconds==120)
afk=true;now=320;xp=380;A.Sample()
assert(A.db.session.xp==1080 and A.db.session.seconds==120)
afk=false;now=380;xp=480;A.Sample()
assert(A.db.session.xp==1180 and A.db.session.seconds==180)
SlashCmdList.APEXGRIND('hide');now=440;xp=580;A.Sample()
assert(A.frame.shown==false and A.db.session.xp==1280)
SlashCmdList.APEXGRIND('compact');SlashCmdList.APEXGRIND('show')
assert(A.frame.height==168 and A.frame.shown)
SlashCmdList.APEXGRIND('scale 99');assert(A.db.scale==1.8)
SlashCmdList.APEXGRIND('scale -2');assert(A.db.scale==.8)
-- A reload rebases to current XP, retaining totals but excluding offline time/XP.
savedXP=A.db.session.xp;savedSeconds=A.db.session.seconds
now=50000;xp=800;A.Initialize()
assert(A.db==original and A.db.session.xp==savedXP and A.db.session.seconds==savedSeconds)
now=50060;xp=850;A.Sample()
assert(A.db.session.xp==savedXP+50 and A.db.session.seconds==savedSeconds+60)
ApexGrindMinimapButton.scripts.OnClick(nil,'RightButton')
assert(A.frame.height==560)
A.frame.reset.scripts.OnClick(A.frame.reset)
assert(A.db.session.xp>0)
A.frame.reset.scripts.OnClick(A.frame.reset)
assert(A.db.session.xp==0 and A.db.session.seconds==0)
-- Separate character database gets a clean session and leaves original untouched.
local prior=A.db;ApexGrindDB=nil;A.Initialize()
assert(A.db~=prior and A.db.session.xp==0)
''')
print('PASS: event ordering, UI creation, compact/full, launcher, hidden tracking, reset confirmation')
print('PASS: session continuity, character isolation, AFK pause, offline exclusion, scale bounds')

lua.execute('''
-- Real compact button callback, not just the unrelated minimap toggle.
local f=A.frame
assert(f.scripts.OnDragStart==f.titleBar.scripts.OnDragStart)
assert(f.scripts.OnDragStop==f.titleBar.scripts.OnDragStop)
A.db.locked=true;f.scripts.OnDragStart();assert(not A.dragging)
A.db.locked=false;f.scripts.OnDragStart();assert(A.dragging)
local oldScale=f.SetScale
f.SetScale=function() error('A live drag must not relayout the frame') end
A.Render();f.SetScale=oldScale
f:SetPoint('TOPLEFT',UIParent,'TOPLEFT',650,-220)
f.scripts.OnDragStop();assert(not A.dragging and A.db.position.x==650)
A.db.compact=false;A.Render()
A.frame.compactButton.scripts.OnClick()
assert(A.db.compact and A.frame.height==168)
assert(A.frame.bonusText.shown and A.frame.restedText.shown,'Mini must retain buff reminders and rested status')
assert(A.frame.compactButton.frameLevel>A.frame.titleBar:GetFrameLevel())
assert(A.frame.titleBar.point[2]==-84,'Drag surface must reserve the + button hitbox')
A.frame.compactButton.scripts.OnClick()
assert(not A.db.compact and A.frame.height==560 and A.guidePane.shown)
SlashCmdList.APEXGRIND('stats');assert(A.frame.height==380 and not A.guidePane.shown)
SlashCmdList.APEXGRIND('spots');assert(A.frame.height==560 and A.guidePane.shown)
-- Exhaust every leveling level for both factions, including unknown location.
for _,faction in ipairs({'Alliance','Horde'}) do
 for l=1,59 do
  for _,map in ipairs({0,1429,1411,1431,1440,1452,2521}) do
   local choices=A.Recommend(l,faction,map)
   assert(#choices>0,'Missing level '..l..' '..faction)
   local c=choices[1];local s=c.spot
   assert(s.faction=='Both' or s.faction==faction)
   assert(c.targetLow>=math.max(1,l-2) and c.targetHigh<=math.max(1,l-1))
   assert(c.targetLow>=s.low and c.targetHigh<=s.high)
   assert(s.map~=2521 or map==2521,'Do not send mainland characters to gated starter island')
  end
 end
 assert(#A.Recommend(60,faction,1431)==0)
end
-- Stay in each starter region when matching targets exist.
for _,v in ipairs({{1429,'Alliance'},{1426,'Alliance'},{1438,'Alliance'},
 {1411,'Horde'},{1412,'Horde'},{1420,'Horde'},{2521,'Alliance'},{2521,'Horde'}}) do
 for l=1,11 do
  assert(A.Recommend(l,v[2],v[1])[1].spot.map==v[1],'Unnecessary starter travel at '..l..' map '..v[1])
 end
end
SlashCmdList.APEXGRIND('level 59')
local selection,preview,count=A.GuideSelection()
assert(preview==59 and selection and count>1)
local first=selection.spot.id;A.NextSpot();assert(A.GuideSelection().spot.id~=first)
SlashCmdList.APEXGRIND('level auto');assert(A.previewLevel==nil)
SlashCmdList.APEXGRIND('level 60');assert(not A.guidePane.route.enabled)
SlashCmdList.APEXGRIND('level 999');assert(A.previewLevel==60)
SlashCmdList.APEXGRIND('level -4');assert(A.previewLevel==1)
SlashCmdList.APEXGRIND('level 29')
local s=A.GuideSelection().spot
local navCalls=0
ApexNavigator={SetDestination=function(map,x,y)
 navCalls=navCalls+1;assert(map==s.map and x==s.x and y==s.y)
end}
A.Render();assert(navCalls==0,'Rendering must not replace existing arrows')
A.guidePane.route.scripts.OnClick();assert(navCalls==1)
ApexNavigator=nil
TomTom={AddWaypoint=function(_,map,x,y) assert(map==s.map);return 'our-pin' end,
 RemoveWaypoint=function(_,uid) assert(uid=='our-pin') end}
A.NavigateSpot();A.NavigateSpot();assert(A.grindWaypoint=='our-pin')
''')
print('PASS: compact hitbox/expand callback, guide tabs, level/faction coverage, starter locality, browsing and explicit navigation')

lua.execute('''
assert(#A.materials==10 and #A.materialPicker.menuEntries==11)
for _,material in ipairs(A.materials) do
 local found=0
 for _,faction in ipairs({'Alliance','Horde'}) do
  for l=1,59 do
   for _,choice in ipairs(A.Recommend(l,faction,0,material.id)) do
    assert(material.npcs[choice.spot.npc]>=1,'Unverified or incidental material source')
    assert(choice.targetLow>=math.max(1,l-2) and choice.targetHigh<=math.max(1,l-1))
    found=found+1
   end
  end
 end
 assert(found>0,'Material has no usable XP/loot candidates: '..material.name)
end
-- Click every picker entry: closures must capture the correct item IDs.
for i=2,11 do
 A.materialPicker.menuEntries[i].callback()
 assert(A.db.material==A.materials[i-1].id)
end
SlashCmdList.APEXGRIND('level 29');SlashCmdList.APEXGRIND('loot Wool Cloth')
local c=A.GuideSelection();assert(c and A.Material(2592).npcs[c.spot.npc])
SlashCmdList.APEXGRIND('loot Rugged Leather')
assert(not A.GuideSelection() and not A.guidePane.route.enabled)
local nextLevel=A.NearestMaterialLevel(29);assert(nextLevel and nextLevel>29)
A.guidePane.other.scripts.OnClick()
assert(A.previewLevel==nextLevel and A.GuideSelection())
assert(A.guidePane.evidence.text:find('Requires Skinning',1,true))
SlashCmdList.APEXGRIND('loot all');assert(A.db.material==0)
SlashCmdList.APEXGRIND('loot unsupported');assert(A.db.material==0)
A.CurrentLevel();assert(A.previewLevel==nil)
''')
print('PASS: all 10 material filters, per-NPC evidence, dropdown callbacks, no-match/nearest-preview and skinning labels')

lua.execute('''
rested=1000;function GetXPExhaustion() return rested end
COMBATLOG_XPGAIN_FIRSTPERSON='%s dies, you gain %d experience.'
COMBATLOG_XPGAIN_EXHAUSTION1='%s dies, you gain %d experience. (%s exp %s bonus)'
level=29;xp=0;cap=2000;A.Reset()
now=now+100;xp=200;rested=800
A.driver.scripts.OnEvent(nil,'CHAT_MSG_COMBAT_XP_GAIN','Wolf dies, you gain 200 experience. (100 exp Rested bonus)')
A.driver.scripts.OnEvent(nil,'PLAYER_XP_UPDATE','player')
A.driver.scripts.OnEvent(nil,'UPDATE_EXHAUSTION');flush()
assert(A.db.session.forecast.kills==200 and A.db.session.forecast.bonus==100)
local _,_,eta=A.Metrics(A.db.session,A.current);assert(eta==1400)
assert(A.frame.restedText.text:find('800',1,true))
A.TogglePause()
A.driver.scripts.OnEvent(nil,'CHAT_MSG_COMBAT_XP_GAIN','Wolf dies, you gain 200 experience.')
assert(A.db.session.forecast.kills==200)
A.TogglePause()
C_UnitAuras={GetAuraDataByIndex=function(_,i)
 if i==1 then return {spellId=1248406,expirationTime=now+900} end
 if i==2 then return {spellId=429959,expirationTime=now+7200,applications=3} end
end}
A.driver.scripts.OnEvent(nil,'UNIT_AURA','player')
assert(A.frame.bonusText.text:find('Food: 15m',1,true) and A.frame.bonusText.text:find('3/3',1,true))
assert(A.db.session.forecast.bonus==100,'Buff refresh must not count XP twice')
A.frame.bonusHints.scripts.OnEnter(A.frame.bonusHints)
-- Upgrade calibration starts fresh without discarding established session totals.
A.db.session.forecast=nil;local old=A.db.session.xp;A.Initialize()
assert(A.db.session.xp==old and A.db.session.forecast.xp==0)
''')
print('PASS: live event wiring, rested forecast, aura updates in both views, paused kills and existing-session migration')
lua.execute('''
local render=A.RenderGuide;local calls=0
A.RenderGuide=function() calls=calls+1 end
A.db.hidden=true;A.Render();assert(calls==0)
A.db.hidden=false;A.Render();assert(calls==1)
A.RenderGuide=render
''')
print('PASS: closed tracker avoids rebuilding guide UI while sampling remains enabled')

toc = (root / 'ApexGrind.toc').read_text()
assert '## Interface: 16001' in toc
for name in ('Stats.lua', 'Core.lua', 'UI.lua'):
    assert name in toc
for source in root.glob('*.lua'):
    text = source.read_text()
    for forbidden in ('SetCVar(', 'RunScript(', 'CastSpell', 'SetBinding', 'EllesmereUIDB='):
        assert forbidden not in text, (source, forbidden)
print('PASS: manifest and no display, combat, binding or external profile mutations')
