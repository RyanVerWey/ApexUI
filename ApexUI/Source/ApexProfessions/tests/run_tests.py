from pathlib import Path
from lupa.lua51 import LuaRuntime
import time
import sys

base=Path(__file__).resolve().parents[1]
lua=LuaRuntime(unpack_returned_tuples=True)
ns=lua.table()
compile_lua=lua.eval('function(s,n) local f,e=loadstring(s,n); assert(f,e) end')
for f in base.rglob('*.lua'):compile_lua(f.read_text(encoding='utf-8-sig'),str(f))
mock=lua.execute((base/'upstream/tests/wowmock.lua').read_text())
fx=lua.execute((base/'upstream/tests/fixtures/yungzug.lua').read_text())
fx['firstaid']=lua.execute((base/'upstream/tests/fixtures/yungzug_firstaid.lua').read_text())
fx['fishing']=lua.execute((base/'upstream/tests/fixtures/yungzug_fishing.lua').read_text())
mock.install(fx,ns)
lua.globals().ns=ns; lua.globals().mock=mock; lua.globals().fx=fx
lua.execute('tinsert=table.insert; IsControlKeyDown=function() return false end')
for line in (base/'ApexProfessions.toc').read_text().splitlines():
    if line.endswith('.lua'):
        path=base/line.replace('\\','/')
        try:lua.execute(path.read_text(encoding='utf-8'), 'ApexProfessions',ns)
        except Exception as e:raise RuntimeError(str(path)) from e
mock.fire('ADDON_LOADED','ApexProfessions')
mock.fire('PLAYER_LOGIN')
lua.execute('''
AuctionDB=nil
Auctionator={API={v1={
 GetAuctionPriceByItemID=function(caller,id) assert(caller=='ApexProfessions'); return fx.ah[id] and fx.ah[id][2] or 100 end,
 GetAuctionAgeByItemID=function(caller,id) return 0 end
}}}
''')
start=time.perf_counter()
lua.execute((base/'tests/test_apex.lua').read_text())
print(f'PASS Apex integration and planner tests in {time.perf_counter()-start:.2f}s')
print(f'PASS syntax/load: {len(list(base.rglob("*.lua")))} Lua files including upstream sources')

if '--upstream' in sys.argv:
    upstream=LuaRuntime(unpack_returned_tuples=True)
    upstream.globals().arg=upstream.table_from({0:str(base/'tests/test_ladder.lua').replace('\\','/')})
    upstream.execute('os.exit=function(n) assert(n==0, "upstream tests failed") end')
    source=(base/'upstream/tests/test_ladder.lua').read_text()
    source=source.replace('root .. "CraftLadder/"','root .. ""').replace('tests/fixtures/','upstream/tests/fixtures/')
    upstream.execute(source)
