"""Check chat subscription safety, repeat loads and full-window behavior."""
from pathlib import Path
from lupa.lua51 import LuaRuntime

root=Path(__file__).resolve().parents[1]
lua=LuaRuntime(unpack_returned_tuples=True)
lua.execute('''
A={Backend={}};ApexUICharacterDB={};NUM_CHAT_WINDOWS=10;SlashCmdList={}
ChatFrame1={groups={SAY=true,CHANNEL=true,GUILD=true}};GENERAL_CHAT_DOCK={selected=ChatFrame1}
names={[1]='General',[2]='Combat Log'};created=0
function GetChatWindowInfo(i) return names[i] end
function FCF_OpenNewWindow(name,noDefault)
 if full then return nil end
 created=created+1;names[3]=name
 local f={groups={WHISPER=true},channels={'General'},editBox={SetAttribute=function(self,k,v) self[k]=v end}}
 function f:RemoveAllMessageGroups() self.groups={} end
 function f:RemoveAllChannels() self.channels={} end
 function f:AddMessageGroup(group) self.groups[group]=true end
 ChatFrame3=f;GENERAL_CHAT_DOCK.selected=f;return f
end
function FCFDock_SelectWindow(dock,frame) dock.selected=frame end
''')
lua.execute('assert(loadstring(...))("ApexUI",A)',(root/'Chat.lua').read_text())
lua.execute('''
A.EnsureGuildChat()
assert(created==1 and names[3]=='Guild')
assert(ChatFrame3.groups.GUILD and ChatFrame3.groups.GUILD_ACHIEVEMENT and not ChatFrame3.groups.WHISPER)
assert(#ChatFrame3.channels==0 and ChatFrame1.groups.SAY and ChatFrame1.groups.CHANNEL)
assert(GENERAL_CHAT_DOCK.selected==ChatFrame1)
assert(ChatFrame3.editBox.chatType=='GUILD')
ChatFrame3.groups.OFFICER=true
A.EnsureGuildChat();assert(created==1 and ChatFrame3.groups.OFFICER)
ApexUICharacterDB={};A.EnsureGuildChat();assert(created==1 and ChatFrame3.groups.OFFICER)
ApexUICharacterDB={};names[3]=nil;full=true
A.EnsureGuildChat();assert(created==1 and not ApexUICharacterDB.chatTabsVersion)
full=false;A.EnsureGuildChat();assert(created==2)
''')
print('PASS: Guild-only initial filters, unchanged General, idempotent setup, existing filters preserved, no overwrite when full.')
