local _,A=...
local cookItems={c50=6291,c100=6289,c125=6308,c175=6308,c225=8365,c250=13758,c275=13759,c300=13889}
local names={[6291]='Raw Brilliant Smallfish',[6303]='Raw Slitherskin Mackerel',[6289]='Raw Longjaw Mud Snapper',
 [6308]='Raw Bristle Whisker Catfish',[8365]='Raw Mithril Head Trout',[13758]='Raw Redgill',
 [13759]='Raw Nightfin Snapper',[13760]='Raw Sunscale Salmon',[13889]='Raw Whitescale Salmon'}
local base=A.BuildRoute
function A.BuildRoute(faction,mode,origin)
 local route=base(faction,mode,origin)
 if mode~='combined' then return route end
 local byId={}; for _,s in ipairs(route) do byId[s.id]=s end
 local ids={'learn-f','learn-c','small-recipe','zephras-fallback','c50','f50','journey-f','journey-c','cat-recipe',
  'c100','c125','f125','expert-f','trout-recipes','cook-book-buy','expert-c','c175','c225','f225',
  'nat-accept','quest-ahi','quest-striker','quest-sailfin','quest-mahi','artisan-f','artisan-c','late-recipes',
  'salmon-recipe','c250','c275','c300','f300'}
 local out={}; for _,id in ipairs(ids) do if byId[id] then out[#out+1]=byId[id] end end
 return out
end
local function copy(s) local o={}; for k,v in pairs(s) do o[k]=v end; return o end
function A.PrioritizePending(route,pending,state)
 for _,index in ipairs(pending) do
  local s=route[index]
  if s.kind=='cap' and s.target<=225 and (state[s.skill..'cap'] or 0)>0
   and state[s.skill]>=state[s.skill..'cap'] and state.level>=(s.level or 1) then
   local out={index}; for _,other in ipairs(pending) do if other~=index then out[#out+1]=other end end
   return out
  end
 end
 return pending
end
function A.GuidedStep(step,state)
 if not step then return end
 local s=copy(step)
 local item=cookItems[s.id]
 if s.id=='c50' and ApexFishingDB.origin=='durotar' then item=6303 end
 if s.id=='c275' then
  local hour=GetGameTime and GetGameTime() or 0
  if A.Count(13760)>A.Count(13759) or (A.Count(13759)==0 and hour>=6 and hour<18) then item=13760 end
 end
 if item then
  local count=A.Count(item)
  local batchSize=math.max(1,math.min(20,s.target-state.c))
  local d=ApexFishingDB
  if not d.batch or d.batch.id~=s.id or d.batch.item~=item then
   d.batch={id=s.id,item=item,phase=count>=batchSize and 'cook' or 'fish',goal=batchSize}
  end
  local batch=d.batch
  if batch.phase=='fish' and count>=batch.goal then batch.phase='cook' end
  if batch.phase=='cook' and count==0 then batch.phase='fish'; batch.goal=batchSize end
  s.session=s.id; s.item=item; s.goal=batch.goal; s.count=count
  if batch.phase=='cook' then
   s.phase='cook'; s.point=nil; s.id=s.id..':cook'
   s.title=('Cook %s: skill %d / %d'):format(names[item],state.c,s.target)
   s.body=('Use a campfire at your fishing bank, or the nearest cooking fire. You have %d fish. Cook until Cooking %d or this batch runs out.\n\nIf skill-ups leave you short, the next step automatically requests another batch.\n\n%s'):format(count,s.target,step.body)
   s.following='If short: catch another batch here. Otherwise: continue to the next guide stop.'
   return s
  end
  s.phase='fish'; s.kind='batch'; s.id=s.id..':fish'
  s.title=('Catch %s: %d / %d in bags'):format(names[item],count,batch.goal)
  s.body=('Keep fishing until you hold %d %s. You need %d more. Other catches do not count toward this batch.\n\nThen cook this batch at a campfire by the water, toward Cooking %d. Batch sizes are targets, not guaranteed skill-ups.'):format(batch.goal,names[item],math.max(0,batch.goal-count),step.target)
  s.following=('Cook this batch toward Cooking %d.'):format(step.target)
 elseif s.kind=='skill' and s.skill=='f' then
  s.phase='fish'; s.session=s.id; s.title=('Fish to skill %d: currently %d'):format(s.target,state.f)
  s.body='Stay in suitable nearby water. Each successful catch can advance Fishing. Higher-level water is not needed for faster skill-ups. Keep fish you can cook.'
 elseif s.kind=='cap' or s.kind=='manual' or s.kind=='item' then return s
 else return s end
 local spot=A.ChooseSpot(state,item,s.session)
 if spot then
  s.point='water:'..spot.id; s.spot=spot
  s.body=s.body..'\n\n'..(spot.observed and 'This bank has produced the required fish for your character.' or
   'The ring highlights a fishing AREA. Choose an accessible bank inside it; do not try to stand at the centre marker.')
 else
  s.point=nil; s.body=s.body..'\n\nNo catalogued water meets your current level and skill for this fish. Raise your character/Fishing level or revisit a bank where you have caught it.'
 end
 return s
end
