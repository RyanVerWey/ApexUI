-- Generated ApexUI module wrapper; original attribution follows.
local _, suite = ...
suite.Suite.Register("grinding", "ApexGrind/Stats.lua", function(...)
local CreateFrame = function(...) return suite.Suite.CreateFrame("grinding", ...) end
local _, A = ...

-- Pure accounting. Session time is loaded, unpaused time, not wall-clock time.
function A.NewSession()
 return {xp=0,seconds=0,levels=0,samples={},recentSince=0,forecast=A.NewForecast()}
end
function A.NewForecast() return {seconds=0,xp=0,kills=0,bonus=0} end
function A.Advance(s, seconds, paused)
 if not paused then
  s.seconds=s.seconds+math.max(0,seconds)
  if s.forecast then s.forecast.seconds=s.forecast.seconds+math.max(0,seconds) end
 end
 local cutoff=s.seconds-300
 while s.samples[1] and s.samples[1].t<=cutoff do table.remove(s.samples,1) end
end
function A.Record(s, previous, current, paused)
 local gained=0
 if current.level==previous.level then
  gained=math.max(0,current.xp-previous.xp)
 elseif current.level==previous.level+1 then
  gained=math.max(0,previous.cap-previous.xp)+current.xp
 elseif current.level>previous.level+1 then
  -- A server-side boost can skip levels without exposing intermediate caps.
  -- Rebase instead of inventing XP and contaminating the rate.
  s.note="Multiple-level jump: XP baseline refreshed."
 end
 if not paused then
  s.levels=s.levels+math.max(0,current.level-previous.level)
  s.xp=s.xp+gained
  if s.forecast then
   local f=s.forecast
   f.xp=f.xp+gained
   -- Exhaustion is the total eligible doubled XP, not just its bonus half.
   local spent=previous.rested and current.rested and math.max(0,previous.rested-current.rested) or 0
   -- The XP and exhaustion events can settle on adjacent frames. Reconcile
   -- a short award window in either order instead of losing its bonus.
   if gained>0 or spent>0 then
    local w=f.award
    if not w or s.seconds-w.time>2 or current.level>previous.level+1 then
     w={xp=0,spent=0,bonus=0,time=s.seconds};f.award=w
    end
    w.xp=w.xp+gained;w.spent=w.spent+spent
    local known=math.min(w.xp,w.spent)/2
    f.bonus=f.bonus+math.max(0,known-w.bonus);w.bonus=known
   end
  end
  if gained>0 then
   local last=s.samples[#s.samples]
   if last and last.t==s.seconds then last.xp=last.xp+gained
   else s.samples[#s.samples+1]={t=s.seconds,xp=gained} end
  end
 elseif s.forecast then s.forecast.award=nil end
 return gained
end
function A.LevelForecast(s,current)
 local f=s.forecast
 local left=math.max(0,current.cap-current.xp)
 local info={rested=math.max(0,current.rested or 0),mode='learning'}
 if current.cap<=0 or not f or f.seconds<1 or f.xp<=0 then return nil,info end
 local bonus=math.min(f.xp/2,f.bonus)
 local base=(f.xp-bonus)/f.seconds
 -- Chat identifies kills independently of quest/exploration awards. Rested
 -- consumption is also evidence of eligible XP when chat is unavailable.
 local killBase=math.max(bonus,math.min(f.xp,f.kills)-bonus)/f.seconds
 local budget=info.rested/2
 info.baseRate=base*3600;info.noRest=left/base;info.mode='measured'
 if killBase<=0 or budget<=0 then return info.noRest,info end
 info.depletes=budget/killBase
 local boosted=base+killBase
 local before=info.depletes*boosted
 local eta=left<=before and left/boosted or info.depletes+(left-before)/base
 info.coversLevel=left<=before;info.saved=math.max(0,info.noRest-eta)
 return eta,info
end
function A.Metrics(s, current)
 local rate=s.seconds>=1 and s.xp*3600/s.seconds or 0
 local recentXP=0
 for _,v in ipairs(s.samples) do recentXP=recentXP+v.xp end
 local recentTime=math.min(300,math.max(0,s.seconds-(s.recentSince or 0)))
 local recent=recentTime>=1 and recentXP*3600/recentTime or 0
 local remaining=math.max(0,current.cap-current.xp)
 local eta,forecast=A.LevelForecast(s,current)
 if not eta and rate>0 and current.cap>0 then eta=remaining*3600/rate end
 return rate,recent,eta,remaining,forecast
end
function A.Number(n)
 local value=tostring(math.floor((n or 0)+.5))
 local result=value:reverse():gsub('(%d%d%d)','%1,'):reverse():gsub('^,','')
 return result
end
function A.Duration(seconds)
 if not seconds then return "--" end
 local minutes=math.floor(math.max(0,seconds)/60)
 if minutes<1 then return "<1m" end
 if minutes<60 then return minutes.."m" end
 return math.floor(minutes/60).."h "..(minutes%60).."m"
end

end)
