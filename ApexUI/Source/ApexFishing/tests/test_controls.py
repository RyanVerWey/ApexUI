from pathlib import Path
from lupa.lua51 import LuaRuntime
root=Path(__file__).resolve().parents[1]
lua=LuaRuntime(unpack_returned_tuples=True)
lua.execute('''
A={}; frames={}; SlashCmdList={}; UIParent={}; ApexFishingDB={}
local methods={}
function methods:SetScript(k,f) self.scripts[k]=f end
function CreateFrame() local f={scripts={}}; setmetatable(f,{__index=function(_,k) return methods[k] or function() end end}); frames[#frames+1]=f; return f end
function InCombatLockdown() return fighting end
function UnitLevel() return 30 end
gear={[16]='sword',[17]='shield'}; swaps={}; bagFree=2; channel=nil; cv='0'
function GetInventoryItemLink(_,slot) return gear[slot] end
function EquipItemByName(link,slot) swaps[#swaps+1]=link; gear[slot]=link; if link:match('pole') then gear[17]=nil end end
function UnitChannelInfo() return channel end
function ClearOverrideBindings() binding=nil end
function SetOverrideBinding(_,_,key,action) binding={key,action} end
function SetOverrideBindingClick(_,_,key,button) binding={key,button} end
C_Spell={GetSpellName=function() return 'Fishing' end}
C_CVar={GetCVar=function() return cv end,SetCVar=function(_,v) cv=tostring(v) end}
C_Item={GetItemInfoInstant=function(link) return 1,'','',0,'',2,link:match('pole') and 20 or 7 end,
 GetItemInfo=function(link) return link,nil,1,link=='poleBest' and 40 or 10,1 end}
C_Container={GetContainerNumFreeSlots=function() return bagFree,0 end,
 GetContainerNumSlots=function(bag) return bag==0 and 2 or 0 end,
 GetContainerItemInfo=function(_,slot) return {hyperlink=slot==1 and 'poleWeak' or 'poleBest',isLocked=false} end}
C_Timer={After=function(_,fn) fn() end}
''')
lua.execute('assert(loadstring(...))("ApexFishing",A)',(root/'Controls.lua').read_text())
lua.execute('''
A.ToggleFishing()
assert(A.fishingMode and gear[16]=='poleBest' and not gear[17])
assert(ApexFishingDB.gear.main=='sword' and ApexFishingDB.gear.off=='shield')
assert(binding[1]=='SPACE' and binding[2]=='ApexFishingCastButton')
channel='Fishing'; frames[1].scripts.OnEvent(nil,'UNIT_SPELLCAST_CHANNEL_START','player')
assert(binding[1]=='SPACE' and binding[2]=='INTERACTTARGET')
A.StopFishing()
assert(gear[16]=='sword' and gear[17]=='shield' and not ApexFishingDB.gear)
assert(cv=='0' and binding==nil)
channel=nil; A.ToggleFishing(); fighting=true; A.StopFishing()
assert(ApexFishingDB.gear and gear[16]=='poleBest')
fighting=false; frames[1].scripts.OnEvent(nil,'PLAYER_REGEN_ENABLED')
assert(gear[16]=='sword' and gear[17]=='shield' and cv=='0')
ForeverFishing={}; A.ToggleFishing(); assert(not A.fishingMode); ForeverFishing=nil
bagFree=0; A.ToggleFishing(); assert(gear[16]=='sword' and not ApexFishingDB.gear); A.StopFishing()
bagFree=2; ApexFishingDB.gear={main='sword',off='shield'}; ApexFishingDB.oldInteract='0'; gear[16]='poleBest'; gear[17]=nil
A.InitControls(); assert(gear[16]=='sword' and gear[17]=='shield' and not ApexFishingDB.gear)
C_Item.EquipItemByName=EquipItemByName; EquipItemByName=nil
A.ToggleFishing(); assert(gear[16]=='poleBest','Modern client equipment API')
A.StopFishing(); assert(gear[16]=='sword' and gear[17]=='shield')
''')
print('PASS: highest-level pole, dual-wield restore, cast/reel switch, combat deferral, full bags, addon conflict, reload recovery')
