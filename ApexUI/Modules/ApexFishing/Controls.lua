-- Generated ApexUI module wrapper; original attribution follows.
local _, suite = ...
suite.Suite.Register("fishing", "ApexFishing/Controls.lua", function(...)
local CreateFrame = function(...) return suite.Suite.CreateFrame("fishing", ...) end
local _,A=...
local owner=CreateFrame('Frame')
local cast=CreateFrame('Button','ApexFishingCastButton',UIParent,'SecureActionButtonTemplate')
cast:RegisterForClicks('AnyUp','AnyDown')
cast:SetAttribute('type','spell'); cast:SetAttribute('spell',7620)
local function say(s) print('|cff4de0cdApex Fishing:|r '..s) end
local function combat() return InCombatLockdown and InCombatLockdown() end
local function equip(link,slot)
 local fn=C_Item and C_Item.EquipItemByName or EquipItemByName
 if fn then return fn(link,slot) end
 error('This client has no supported equipment API.')
end
local function freeSlots()
 local n=0
 for bag=0,4 do local count,kind=C_Container.GetContainerNumFreeSlots(bag); if kind==0 then n=n+count end end
 return n
end
local function equipBest()
 local best,missing
 local function inspect(link)
  if not link then return end
  local _,_,_,_,_,class,sub=C_Item.GetItemInfoInstant(link)
  if class~=2 or sub~=20 then return end
  local name,_,_,level,minimum=C_Item.GetItemInfo(link)
  if not name then C_Item.RequestLoadItemDataByID(tonumber(link:match('item:(%d+)'))); missing=true; return end
  if (minimum or 0)>UnitLevel('player') then return end
  if not best or (level or 0)>best.level then best={link=link,level=level or 0,name=name} end
 end
 inspect(GetInventoryItemLink('player',16))
 for bag=0,4 do
  for slot=1,C_Container.GetContainerNumSlots(bag) do
   local item=C_Container.GetContainerItemInfo(bag,slot)
   if item and not item.isLocked then inspect(item.hyperlink) end
  end
 end
 if missing then say('Some pole data is still loading. Toggle fishing mode again in a moment to select the highest-level rod.'); return end
 if not best then say('No usable fishing pole found in your bags.'); return end
 local main=GetInventoryItemLink('player',16)
 if main==best.link then return end
 if freeSlots()<1 then say('Free a normal bag slot before swapping your fishing pole.'); return end
 ApexFishingDB.gear=ApexFishingDB.gear or {main=main or false,off=GetInventoryItemLink('player',17) or false}
 equip(best.link,16)
 say('Equipping '..best.name..'. Your previous weapons are saved.')
end
function A.RestoreGear()
 local g=ApexFishingDB and ApexFishingDB.gear
 if not g then return end
 if combat() then A.restorePending=true; say('Weapon restoration queued until combat ends.'); return end
 if g.main then equip(g.main,16)
 elseif GetInventoryItemLink('player',16) then
  if freeSlots()<1 then say('Free a bag slot, then use /apexfish restore.'); return end
  if CursorHasItem and CursorHasItem() then say('Clear your cursor, then use /apexfish restore.'); return end
  local placed=false
  for bag=0,4 do
   local count,kind=C_Container.GetContainerNumFreeSlots(bag)
   if count>0 and kind==0 then
    for slot=1,C_Container.GetContainerNumSlots(bag) do
     if not C_Container.GetContainerItemInfo(bag,slot) then
      PickupInventoryItem(16); C_Container.PickupContainerItem(bag,slot); placed=true; break
     end
    end
   end
   if placed then break end
  end
 end
 if g.off then equip(g.off,17) end
 A.restorePending=true
 C_Timer.After(.7,function()
  local main=GetInventoryItemLink('player',16) or false
  local off=GetInventoryItemLink('player',17) or false
  if main==g.main and off==g.off then ApexFishingDB.gear=nil; A.restorePending=nil
  else say('Weapons are still saved. Check bag space and use /apexfish restore.'); end
 end)
end
local function bind()
 if combat() then return end
 ClearOverrideBindings(owner)
 if not A.fishingMode then return end
 local name,_,_,_,_,_,_,id=UnitChannelInfo('player')
 local fishingName=C_Spell and C_Spell.GetSpellName(7620) or 'Fishing'
 local key=ApexFishingDB.fishingKey or 'SPACE'
 if name and (id==7620 or id==131474 or name==fishingName) then
  SetOverrideBinding(owner,true,key,'INTERACTTARGET')
 else SetOverrideBindingClick(owner,true,key,'ApexFishingCastButton','LeftButton') end
end
function A.StopFishing()
 A.fishingMode=false
 if A.RefreshMini then A.RefreshMini() end
 if combat() then A.stopPending=true; A.restorePending=true; return end
 ClearOverrideBindings(owner); A.stopPending=nil
 local d=ApexFishingDB
 if d and d.oldInteract~=nil then C_CVar.SetCVar('SoftTargetInteract',d.oldInteract); d.oldInteract=nil end
 A.RestoreGear()
 if A.modeButton then A.modeButton:SetText('Start fishing') end
end
function A.ToggleFishing()
 if A.fishingMode then A.StopFishing(); return end
 if combat() then say('Finish combat before entering fishing mode.'); return end
 if _G.ForeverFishing then say('Forever Fishing is loaded. Disable it in AddOns and reload before using Apex\'s fishing controls. Your guide works with either addon.'); return end
 A.fishingMode=true
 local d=ApexFishingDB
 d.oldInteract=d.oldInteract or C_CVar.GetCVar('SoftTargetInteract')
 C_CVar.SetCVar('SoftTargetInteract',3)
 equipBest(); bind()
 if A.modeButton then A.modeButton:SetText('Stop fishing') end
 if A.SetCompact then A.SetCompact(true) end
 say((d.fishingKey or 'SPACE')..': press to cast; press again at the splash to reel. After looting, press again for the next cast. Face the bobber within interact range.')
end
function A.InitControls()
 -- Recover a saved loadout and temporary CVars after a reload or disconnect.
 if ApexFishingDB.oldInteract~=nil then C_CVar.SetCVar('SoftTargetInteract',ApexFishingDB.oldInteract); ApexFishingDB.oldInteract=nil end
 if ApexFishingDB.gear then C_Timer.After(1,A.RestoreGear) end
end
for _,event in ipairs({'UNIT_SPELLCAST_CHANNEL_START','UNIT_SPELLCAST_CHANNEL_STOP','UNIT_SPELLCAST_CHANNEL_UPDATE','PLAYER_REGEN_DISABLED','PLAYER_REGEN_ENABLED'}) do owner:RegisterEvent(event) end
owner:SetScript('OnEvent',function(_,event,unit)
 if event=='PLAYER_REGEN_DISABLED' then return end
 if event=='PLAYER_REGEN_ENABLED' then
  if A.stopPending then A.StopFishing()
  elseif A.restorePending then A.RestoreGear() end
  bind()
 elseif unit=='player' and A.fishingMode then bind() end
end)

end)
