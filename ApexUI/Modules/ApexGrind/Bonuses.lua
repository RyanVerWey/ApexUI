-- Generated ApexUI module wrapper; original attribution follows.
local _, suite = ...
suite.Suite.Register("grinding", "ApexGrind/Bonuses.lua", function(...)
local CreateFrame = function(...) return suite.Suite.CreateFrame("grinding", ...) end
local _, A = ...
local function readable(v) return not (issecretvalue and issecretvalue(v)) end
A.Readable=readable
A.xpFoodAuras={}
-- Visible Forever Well Fed variants; the shared XP aura can be hidden.
for _,id in ipairs({1243969,1248406,1248420,1248421,1248422,1248688,1249519,
 1249520,1249521,1249523,1249907,1249926,1249927,1294007,1319310}) do A.xpFoodAuras[id]=true end

-- Match the client's localized kill messages, never unnamed quest awards.
-- Argument 2 is total awarded XP; positional translations are supported.
local patterns
local function compile(format)
 local out,args,pos,nextArg={}, {},1,1
 while pos<=#format do
  local first,last,token=format:find('%%(%d+%$[sd])',pos)
  local a,b,t=format:find('%%([sd])',pos)
  if a and (not first or a<first) then first,last,token=a,b,t end
  if not first then out[#out+1]=format:sub(pos):gsub('([%^%$%(%)%%%.%[%]%*%+%-%?])','%%%1');break end
  out[#out+1]=format:sub(pos,first-1):gsub('([%^%$%(%)%%%.%[%]%*%+%-%?])','%%%1')
  args[#args+1]=tonumber(token:match('^(%d+)%$')) or nextArg;nextArg=nextArg+1
  out[#out+1]=token:sub(-1)=='d' and '([%d%,%.%s]+)' or '(.-)'
  pos=last+1
 end
 return {pattern='^'..table.concat(out)..'$',args=args}
end
function A.KillXP(message)
 if not readable(message) or type(message)~='string' then return end
 if not patterns then
  patterns={}
  for key,value in pairs(_G) do
   if type(key)=='string' and type(value)=='string' and
    (key:match('^COMBATLOG_XPGAIN_FIRSTPERSON') or key:match('^COMBATLOG_XPGAIN_EXHAUSTION')) and not key:find('UNNAMED',1,true) then
    patterns[#patterns+1]=compile(value)
   end
  end
 end
 for _,p in ipairs(patterns) do
  local matches={message:match(p.pattern)}
  if #matches>0 then
   for i,arg in ipairs(p.args) do
    if arg==2 then return tonumber(((matches[i] or ''):gsub('[^%d]',''))) end
   end
  end
 end
end

local function auraAt(index)
 if C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then return C_UnitAuras.GetAuraDataByIndex('player',index,'HELPFUL') end
 if UnitAura then
  local name,_,stacks,_,duration,expiration,_,_,_,id=UnitAura('player',index,'HELPFUL')
  if name then return {name=name,spellId=id,applications=stacks,duration=duration,expirationTime=expiration} end
 end
end
function A.ScanBonuses()
 local result={known=true,foodKnown=false,bagKnown=false}
 local combat=InCombatLockdown and InCombatLockdown()
 local function unpackAura(aura)
  if not readable(aura) then return end
  if not aura then return false end
  local expires=readable(aura.expirationTime) and aura.expirationTime or nil
  local stacks=readable(aura.applications) and aura.applications or nil
  return {expires=type(expires)=='number' and expires or 0,stacks=type(stacks)=='number' and stacks or nil}
 end
 -- Forever can reject enumeration while still allowing these non-secret
 -- personal buff lookups. An unrelated combat aura must not hide both hints.
 local lookup=C_UnitAuras and C_UnitAuras.GetPlayerAuraBySpellID
 if lookup then
  for _,kind in ipairs({'food','bag'}) do
   local ids=kind=='food' and A.xpFoodAuras or {[429959]=true}
   local complete=true
   for id in pairs(ids) do
    local ok,buff=pcall(function() return unpackAura(lookup(id)) end)
    if not ok or buff==nil then complete=false
    elseif buff then
     result[kind]=buff;result[kind..'Known']=true
     break
    end
   end
   if not result[kind] then result[kind..'Known']=complete and not combat end
  end
 end
 if not result.foodKnown or not result.bagKnown then
  local complete=(C_UnitAuras and C_UnitAuras.GetAuraDataByIndex) or UnitAura
  if complete then
   for index=1,255 do
    local ok,aura=pcall(auraAt,index)
    if not ok or not readable(aura) then complete=false;break end
    if not aura then break end
    if not readable(aura.spellId) then complete=false
    else
     local kind=aura.spellId==429959 and 'bag' or (A.xpFoodAuras[aura.spellId] and 'food')
     if kind and not result[kind..'Known'] then
      local good,buff=pcall(unpackAura,aura)
      if good and buff then result[kind]=buff;result[kind..'Known']=true end
     end
    end
   end
  end
  if complete and not combat then result.foodKnown=true;result.bagKnown=true end
 end
 A.bonusCache=A.bonusCache or {}
 for _,kind in ipairs({'food','bag'}) do
  if result[kind..'Known'] then A.bonusCache[kind]=result[kind]
  else
   result.known=false
   local cached=A.bonusCache[kind]
   if cached and cached.expires>0 then
    result[kind]={expires=cached.expires,stacks=cached.stacks,cached=true}
   end
  end
 end
 return result
end
function A.BonusText(kind,state,now)
 local buff=state[kind]
 local name=kind=='food' and 'Food' or 'Bag'
 if not buff then
  if not state[kind..'Known'] and not state.known then return '|cffbcb3a3'..(kind=='food' and 'Check XP food' or 'Check sleep bag')..'|r' end
  return '|cffcbb485'..(kind=='food' and 'Eat XP food' or 'Use sleep bag')..'|r'
 end
 local left=buff.expires>0 and math.max(0,buff.expires-now) or nil
 if left and left<=0 then return '|cffcbb485'..(kind=='food' and 'Eat XP food' or 'Use sleep bag')..'|r' end
 local suffix=kind=='bag' and buff.stacks and (' '..math.min(3,math.max(1,buff.stacks))..'/3') or ''
 return ((left and left<=120 or kind=='bag' and buff.stacks and buff.stacks<3) and '|cffcbb485' or '|cff9ec4a0')..name..suffix..': '..(buff.cached and '~' or '')..(left and A.Duration(left) or 'on')..'|r'
end

end)
