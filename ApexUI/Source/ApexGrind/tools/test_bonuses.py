"""Rested forecast boundaries and real bonus/chat code under Lua 5.1."""
from pathlib import Path
from lupa.lua51 import LuaRuntime

root=Path(__file__).resolve().parents[1]
lua=LuaRuntime(unpack_returned_tuples=True)
lua.execute('A={}')
for name in ('Stats.lua','Bonuses.lua'):
    lua.execute('assert(loadstring(...))("ApexGrind",A)',(root/name).read_text())
lua.execute('''
local function near(a,b) assert(math.abs(a-b)<.0001,tostring(a)..' ~= '..tostring(b)) end
local function point(x,rest) return {xp=x,cap=2000,level=29,rested=rest} end
local s=A.NewSession()
A.Advance(s,100,false)
A.Record(s,point(0,1000),point(200,800),false);s.forecast.kills=200
-- 1 base XP/sec + 1 rested XP/sec; 400 sec boosted then 1000 sec normal.
local _,_,eta,_,f=A.Metrics(s,point(200,800))
near(eta,1400);near(f.depletes,400);near(f.noRest,1800)
-- Enough rested to cover the level, without double-counting observed bonus.
_,_,eta,_,f=A.Metrics(s,point(200,4000));near(eta,900);assert(f.coversLevel)
-- Exhausted now: earlier boosted kills must not inflate the forecast.
_,_,eta=A.Metrics(s,point(200,0));near(eta,1800)
-- Partial final kill consumes only remaining bonus.
local partial=A.NewSession();A.Advance(partial,100,false)
A.Record(partial,point(0,20),point(110,0),false);partial.forecast.kills=110
near(partial.forecast.bonus,10);_,_,eta=A.Metrics(partial,point(110,0));near(eta,1890)
-- Quest and kill mixture: quests are not doubled or charged to the pool.
local mixed=A.NewSession();A.Advance(mixed,100,false)
A.Record(mixed,point(0,1000),point(300,800),false);mixed.forecast.kills=200
_,_,eta,_,f=A.Metrics(mixed,point(300,800));near(eta,650);near(f.depletes,400)
local quest=A.NewSession();A.Advance(quest,100,false)
A.Record(quest,point(0,1000),point(300,1000),false)
_,_,eta,_,f=A.Metrics(quest,point(300,1000));near(eta,1700/3);assert(not f.depletes)
-- Acquiring rested after unboosted kills immediately changes the forecast.
local unbuffed=A.NewSession();A.Advance(unbuffed,100,false)
A.Record(unbuffed,point(0,0),point(100,0),false);unbuffed.forecast.kills=100
_,_,eta=A.Metrics(unbuffed,point(100,400));near(eta,1700)
-- Refills aren't negative consumption. Paused XP/time do not affect calibration.
A.Record(unbuffed,point(100,0),point(110,2000),false);assert(unbuffed.forecast.bonus==0)
local old=unbuffed.forecast.xp;A.Advance(unbuffed,500,true)
A.Record(unbuffed,point(110,2000),point(310,1800),true)
assert(unbuffed.forecast.xp==old and unbuffed.forecast.seconds==100)
assert(select(3,A.Metrics(A.NewSession(),point(0,1000)))==nil)
assert(select(3,A.Metrics(s,{xp=0,cap=0,rested=1000}))==nil)
-- Legacy session totals have no invented rested history.
local legacy={xp=500,seconds=100,samples={}}
_,_,eta,_,f=A.Metrics(legacy,point(500,1000));near(eta,300);assert(f.mode=='learning')
-- Level-up rollover retains real bonus consumption.
local rollover=A.NewSession();A.Advance(rollover,10,false)
A.Record(rollover,{xp=990,cap=1000,level=29,rested=500},{xp=90,cap=1200,level=30,rested=400},false)
assert(rollover.forecast.xp==100 and rollover.forecast.bonus==50)
-- XP and exhaustion settling on separate frames, in either order.
for _,xpFirst in ipairs({true,false}) do
 local split=A.NewSession();A.Advance(split,100,false)
 local mid=point(xpFirst and 200 or 0,xpFirst and 1000 or 800)
 A.Record(split,point(0,1000),mid,false);A.Advance(split,.1,false)
 A.Record(split,mid,point(200,800),false)
 assert(split.forecast.xp==200 and split.forecast.bonus==100)
end
-- Client-localized templates, grouped/raid messages, positional translation.
COMBATLOG_XPGAIN_FIRSTPERSON='%s dies, you gain %d experience.'
COMBATLOG_XPGAIN_EXHAUSTION1='%s dies, you gain %d experience. (%s exp %s bonus)'
COMBATLOG_XPGAIN_FIRSTPERSON_GROUP='%s dies, you gain %d experience. (+%d group bonus)'
COMBATLOG_XPGAIN_FIRSTPERSON_RAID='%s dies, you gain %d experience. (-%d raid penalty)'
COMBATLOG_XPGAIN_FIRSTPERSON_TEST='%2$d Erfahrung von %1$s.'
COMBATLOG_XPGAIN_FIRSTPERSON_UNNAMED='You gain %d experience.'
assert(A.KillXP('Wolf 42 dies, you gain 200 experience.')==200)
assert(A.KillXP('Wolf dies, you gain 1,200 experience. (600 exp Rested bonus)')==1200)
assert(A.KillXP('Wolf dies, you gain 210 experience. (+10 group bonus)')==210)
assert(A.KillXP('Wolf dies, you gain 190 experience. (-10 raid penalty)')==190)
assert(A.KillXP('120 Erfahrung von Wolf.')==120)
assert(A.KillXP('You gain 400 experience.')==nil)
assert(A.KillXP('You discovered a place: 300 experience.')==nil)
-- Visible food variants, bag stacks, expiry, unreadable auras and no APIs.
auras={}
C_UnitAuras={GetAuraDataByIndex=function(_,i) return auras[i] end}
local missing=A.ScanBonuses();assert(missing.known and not missing.food and not missing.bag)
assert(A.BonusText('food',missing,100):find('Eat XP food',1,true))
for id in pairs(A.xpFoodAuras) do
 auras={{spellId=id,expirationTime=1000,applications=0}}
 assert(A.ScanBonuses().food,'Missed food aura '..id)
end
auras={{spellId=429959,expirationTime=7300,applications=3},{spellId=1248406,expirationTime=1000}}
local active=A.ScanBonuses()
assert(active.food and active.bag.stacks==3)
assert(A.BonusText('bag',active,100):find('3/3: 2h 0m',1,true))
assert(A.BonusText('food',active,100):find('15m',1,true))
assert(A.BonusText('food',active,1001):find('Eat XP food',1,true))
assert(A.BonusText('food',active,900):find('cbb485',1,true))
-- Do not confuse legacy Well Rested talent with the sleeping-bag buff.
auras={{spellId=1225478}};assert(not A.ScanBonuses().bag)
issecretvalue=function(v) return v=='SECRET' end
auras={{spellId='SECRET'}};local unknown=A.ScanBonuses()
assert(not unknown.known and A.BonusText('bag',unknown,100):find('Check sleep bag',1,true))
C_UnitAuras=nil;assert(not A.ScanBonuses().known)
-- Forever blocks enumeration, but direct personal non-secret buffs work.
combat=false;function InCombatLockdown() return combat end
direct={[1248406]={expirationTime=1000,applications=0},[429959]={expirationTime=7300,applications=3}}
C_UnitAuras={GetAuraDataByIndex=function() error('Aura access restricted') end,
 GetPlayerAuraBySpellID=function(id) return direct[id] end}
local directState=A.ScanBonuses()
assert(directState.food and directState.bag and directState.known)
assert(A.BonusText('food',directState,100):find('Food: 15m',1,true))
-- nil during combat is not proof of removal; retain a bounded cached timer.
combat=true;direct={}
local cached=A.ScanBonuses()
assert(cached.food.cached and cached.bag.cached)
assert(A.BonusText('food',cached,100):find('~15m',1,true))
assert(A.BonusText('food',cached,1001):find('Eat XP food',1,true))
combat=false;local removed=A.ScanBonuses()
assert(removed.known and not removed.food and not removed.bag)
-- One unreadable status must not hide the other's definitive result.
C_UnitAuras.GetPlayerAuraBySpellID=function(id)
 if id==429959 then return {expirationTime=7300,applications=3} end
 error('Food query unavailable')
end
local separate=A.ScanBonuses()
assert(separate.bagKnown and not separate.foodKnown)
assert(A.BonusText('bag',separate,100):find('3/3',1,true))
assert(A.BonusText('food',separate,100):find('Check XP food',1,true))
''')
print('PASS: rested exhaustion, partial kills, quest mix, new rested, pause, migration, level-up, localized kill parsing, food variants, bag stacks, expiry and unavailable auras')
