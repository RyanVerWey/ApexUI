-- Generated ApexUI module wrapper; original attribution follows.
local _, suite = ...
suite.Suite.Register("fishing", "ApexFishing/Data.lua", function(...)
local CreateFrame = function(...) return suite.Suite.CreateFrame("fishing", ...) end
local _, A = ...
A.maxSkill = 300
A.version = '1.1.0'
-- Original route instructions. Coordinates are zone percentages, not world positions.
A.points = {
 sw={1453,55,69.6,'Stormwind canals / Arnold Leland'},
 tb={1456,56,46.8,'Thunder Bluff pond / Kah Mistrunner'},
 elwynn={1429,47.6,62.2,'Crystal Lake / Lee Brown'},
 mulgore={1412,44.6,60.6,'Stonebull Lake / Uthan Stillwater'},
 catherine={1453,55.6,69.6,'Catherine Leland, fishing supplies'},
 tharynn={1429,42,67.2,'Tharynn Bouden, Goldshire'},
 naal={1456,51,52.5,'Naal Mistrunner, recipes'},
 sewa={1456,55.8,47,'Sewa Mistrunner, fishing supplies'},
 stephen={1453,78,53,'Stephen Ryback, Cooking trainer'},
 aska={1456,51,53,'Aska Mistrunner, Cooking trainer'},
 heming={1434,27.4,77.2,'Old Man Heming, Booty Bay'},
 kelsey={1434,28.2,74.3,'Kelsey Yance, Booty Bay'},
 shandrina={1440,49.6,67,'Shandrina, Mystral Lake'},
 wulan={1443,26.2,69.6,'Wulan, upstairs in Shadowprey Village'},
 mystral={1440,49.6,67,'Mystral Lake, Ashenvale'},
 stonetalon={1442,48,61,'Sun Rock Retreat, Stonetalon Mountains'},
 marsh={1445,56,44,'Dustwallow inland water, west of Theramore'},
 nat={1445,58.6,60.1,'Nat Pagle, Tidefury Cove'},
 ahi={1444,62,51,'Feralas Ahi, Verdantis River'},
 striker={1443,25,77,'Sar\'theris Striker, Sar\'theris Strand'},
 sailfin={1434,33,32,'Savage Coast Blue Sailfin, Savage Coast'},
 mahi={1435,90,72,'Misty Reed Mahi Mahi, eastern coast'},
 dirge={1446,52.6,28,'Dirge Quikcleave, Gadgetzan inn'},
 gikkix={1446,66.6,22,'Gikkix, Steamwheedle Port'},
 vivianna={1444,31.3,43.5,'Vivianna, Feathermoon Stronghold'},
 sheendra={1444,74.5,42.7,'Sheendra Tallgrass, Camp Mojache'},
 feralas={1444,62,51,'Feralas inland water / Verdantis River'},
}
A.fish = {{6291,'Brilliant Smallfish'},{6289,'Longjaw Mud Snapper'},
 {6308,'Bristle Whisker Catfish'},{8365,'Mithril Head Trout'},
 {13758,'Redgill'},{13759,'Nightfin Snapper'},{13760,'Sunscale Salmon'},{13889,'Whitescale Salmon'}}

function A.BuildRoute(faction, mode)
 local alliance = faction == 'Alliance'
 local city = alliance and 'sw' or 'tb'
 local start = alliance and 'elwynn' or 'mulgore'
 local cook = alliance and 'stephen' or 'aska'
 local book = alliance and 'shandrina' or 'wulan'
 local middle = alliance and 'mystral' or 'stonetalon'
 local route = {}
 local function add(id,title,body,point,kind,skill,target,extra)
  local s={id=id,title=title,body=body,point=point,kind=kind,skill=skill,target=target}
  if extra then for k,v in pairs(extra) do s[k]=v end end
  route[#route+1]=s
 end
 local function cap(id,skill,target,title,body,point,level,minimum)
  add(id,title,body,point,'cap',skill,target,{level=level,minSkill=minimum})
 end
 local function gain(id,skill,target,title,body,point)
  add(id,title,body,point,'skill',skill,target)
 end
 local function task(id,title,body,point,skipSkill,skipAt,extra)
  extra=extra or {}; extra.skipSkill=skipSkill; extra.skipAt=skipAt
  add(id,title,body,point,'manual',nil,nil,extra)
 end
 cap('learn-f','f',75,'Learn Fishing','Train Apprentice Fishing. Buy a pole and a stack of Shiny Baubles from a fishing supplier. Equip the pole and apply a lure before casting.',start,5,0)
 if mode=='combined' then
  cap('learn-c','c',75,'Learn Cooking','Train Apprentice Cooking. Keep raw fish for your Cooking batches. Carry cooking-fire supplies and leave bag space.',cook,1,0)
  task('small-recipe','Buy your starter recipes',alliance and 'Buy Brilliant Smallfish and Longjaw Mud Snapper recipes from Tharynn Bouden in Goldshire. Learn Smallfish now; Snapper needs Cooking 50.' or 'Buy Brilliant Smallfish from Sewa Mistrunner by the fishing pond. Naal Mistrunner near the Cooking trainer sells Longjaw Mud Snapper and Bristle Whisker Catfish.',alliance and 'tharynn' or 'sewa','c',100)
 end
 gain('f50','f',50,'Fish to 50','Use the nearby starter lake and a lure. Keep Smallfish and Snapper. Higher-level water does not award more skill per successful catch.',start)
 if mode=='combined' then gain('c50','c',50,'Cook Smallfish to 50','Learn Brilliant Smallfish and cook near a fire. Fish more at the starter lake if your stock runs out; catch totals vary.',start) end
 cap('journey-f','f',150,'Unlock Fishing 150','Learn Journeyman Fishing from a Fishing trainer before reaching the 75 cap.',city,10,50)
 if mode=='combined' then
  cap('journey-c','c',150,'Unlock Cooking 150','Learn Journeyman Cooking before the 75 cap.',cook,10,50)
  task('cat-recipe','Stock up on city recipes',alliance and 'Catherine Leland sells Bristle Whisker Catfish and fishing supplies. Get Longjaw Mud Snapper from Tharynn if missing. Learn Snapper at 50; Catfish at 100.' or 'Naal Mistrunner sells Longjaw Mud Snapper and Bristle Whisker Catfish. Learn Snapper at 50; Catfish at 100. Buy lures from Sewa by the pond.',alliance and 'catherine' or 'naal','c',175)
 end
 gain('f125','f',125,'Fish to 125 in your capital','Use the capital pond or canals. Keep a lure active while catches escape. Safe successful catches are the priority.',city)
 if mode=='combined' then gain('c100','c',100,'Cook Snapper to 100','Use Longjaw Mud Snapper. If short of fish, return to the capital water and keep catching. Do not sell the Catfish.',city) end
 cap('expert-f','f',225,'Read the Expert Fishing book','Buy Expert Fishing - The Bass and You from Old Man Heming on Booty Bay\'s lower level, then use it. Buying alone does not raise the cap.', 'heming',20,125)
 if mode=='combined' then
  task('trout-recipes','Buy the next two recipes','Kelsey Yance sells Mithril Head Trout (Cooking 175) and Filet of Redgill (225). Buy both during your Booty Bay stop. Keep them until you can learn them.','kelsey','c',250)
  task('cook-book-buy','Buy the Expert Cookbook',alliance and 'Buy Expert Cookbook from Shandrina beside Mystral Lake. Pick up Nightcrawlers for the next fishing stretch.' or 'Buy Expert Cookbook from Wulan upstairs in Shadowprey Village. Stock up on Nightcrawlers before leaving town.',book,'c',150)
  gain('c125','c',125,'Cook Catfish to 125','Use Bristle Whisker Catfish. Catch more in your capital if needed. Keep the remaining Catfish for the next stage.',city)
  cap('expert-c','c',225,'Read the Expert Cookbook','Use Expert Cookbook to unlock Cooking 225. Without the new cap, cooking at 150 wastes potential skill-ups.',book,20,125)
  gain('f205','f',205,'Catch Catfish to Fishing 205','Fish this inland lake with a Nightcrawler. Keep Snapper and Catfish. These fish feed the next Cooking milestone.',middle)
  gain('c175','c',175,'Cook Catfish to 175','Cook Bristle Whisker Catfish near a fire. If the recipe turns green, extra fish may be needed. Keep fishing here until Cooking reaches 175.',middle)
 end
 gain('f225','f',225,'Fish to 225',mode=='combined' and 'Move to inland Dustwallow water for Mithril Head Trout. Use a Nightcrawler and keep all Trout. Avoid the sea for this step.' or 'Continue in safe capital water. Fishing skill gains slow as your skill increases; moving to dangerous water will not fix that.',mode=='combined' and 'marsh' or city)
 task('nat-accept','Accept Nat Pagle, Angler Extreme','Speak to Nat Pagle at Tidefury Cove. Accept the quest BEFORE visiting the four fishing spots. Bring strong lures. Do not attempt this route below character level 35.','nat','f',226,{level=35,quest=6607,accept=true,skipCap=300})
 for _,q in ipairs({{'ahi',16967,'Feralas Ahi'},{'striker',16968,"Sar'theris Striker"},{'sailfin',16969,'Savage Coast Blue Sailfin'},{'mahi',16970,'Misty Reed Mahi Mahi'}}) do
  add('quest-'..q[1],'Catch '..q[3],'Have Nat\'s quest active. Fish at the marked coast or river until the quest fish is in your bags. Use your best lure, especially in Feralas. These are level 30-40+ zones; approach along safe routes.',q[1],'item',nil,1,{item=q[2],level=35,skipCap=300})
 end
 cap('artisan-f','f',300,'Return to Nat Pagle','Turn in all four quest fish to unlock Artisan Fishing. The guide advances when your trained cap reaches 300.','nat',35,225)
 if mode=='combined' then
  gain('f255','f',255,'Collect Trout to Fishing 255','Return to inland Dustwallow water. Keep catching Mithril Head Trout and cook your saved Catfish first if Cooking is still below 175.','marsh')
  gain('c225','c',225,'Cook Trout to 225','Learn Mithril Head Trout and cook it near a fire. Save spare raw Trout when you hit the 225 cap. Return to inland Dustwallow if you need more.','marsh')
  cap('artisan-c','c',300,'Complete Clamlette Surprise','Dirge Quikcleave in Gadgetzan needs 12 Giant Eggs, 10 Zesty Clam Meat and 20 Alterac Swiss. Eggs: Tanaris rocs. Meat: Big-mouth Clams from coastal turtles. Swiss: cheese/food vendors. Accept and turn in his quest to unlock Cooking 300.','dirge',35,225)
  task('late-recipes','Buy your late-game recipes','Gikkix sells Nightfin Soup and Poached Sunscale Salmon (Cooking 250). Nightfin Soup needs Refreshing Spring Water. Sunscale needs an Iron Oven in Forever.','gikkix','c',275)
  task('salmon-recipe','Buy Baked Salmon',alliance and 'Buy Recipe: Baked Salmon from Vivianna at Feathermoon Stronghold. Learn it at Cooking 275; buy Soothing Spices. It requires an Iron Oven.' or 'Buy Recipe: Baked Salmon from Sheendra Tallgrass at Camp Mojache. Learn it at Cooking 275; buy Soothing Spices. It requires an Iron Oven.',alliance and 'vivianna' or 'sheendra','c',300)
  gain('c250','c',250,'Cook Redgill to 250','Fish Feralas inland water for Redgill. Learn Filet of Redgill and cook to 250. Save Nightfin, Sunscale and Whitescale Salmon. Avoid Jademir Lake; use a lure.','feralas')
  gain('c275','c',275,'Cook Nightfin or Sunscale to 275','Fish Feralas inland water: Nightfin is favored at night, Sunscale by day. Nightfin Soup needs water; Poached Sunscale Salmon needs an Iron Oven. Choose the recipe for your catches and access. Catch more until 275.','feralas')
  gain('c300','c',300,'Finish Cooking with Baked Salmon','Catch Raw Whitescale Salmon in Feralas inland water. Cook with Soothing Spices at another player\'s Iron Oven. Placing your own oven requires Cooking 300, so arrange access first. Keep fishing until you have enough Salmon.','feralas')
 end
 gain('f300','f',300,'Finish Fishing to 300',mode=='combined' and 'Fish Feralas inland water with a lure. Keep useful cooking fish. The final points take multiple catches each; no fixed catch count is guaranteed.' or 'Finish in safe capital water. Refresh your lure if fish escape. Higher water difficulty is useful for valuable catches, not faster skill gains.',mode=='combined' and 'feralas' or city)
 return route
end

end)
