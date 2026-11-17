"""Extract reagent drop locations from installed GPL QuestieDB; no live game access."""
from pathlib import Path
import sys, re, base64, json, ast
from lupa.lua51 import LuaRuntime

root=Path(__file__).resolve().parents[3]
sys.path.insert(0,str(root/'outputs/apexgrind-build-deps'))
import cbor2
addon=Path(__file__).resolve().parents[1]
questie=Path('C:/Program Files (x86)/World of Warcraft/_forever_/Interface/AddOns/QuestieDB')
meta=dict(re.findall(r'^## (X-(?:Item|Npc)-[^:]+): (.+)$',(questie/'QuestieDB_Forever.toc').read_text(encoding='utf-8-sig'),re.M))
def read(key):
    v=meta.get(key)
    if not v:return None
    if v.startswith('~'):v=''.join(meta[f'{key}-{i}'] for i in range(1,int(v.strip('~'))+1))
    v=cbor2.loads(base64.b64decode(v))
    return v
def scalar(n):
    d=read(f'X-Npc-{n}-S') or {}
    return dict(enumerate(d,1)) if isinstance(d,list) else d
tree=ast.parse((root/'work/ApexGrind/tools/build_spots.py').read_text())
zones=next(ast.literal_eval(n.value) for n in tree.body if isinstance(n,ast.Assign) and any(isinstance(t,ast.Name) and t.id=='zones' for t in n.targets))
lua=LuaRuntime(unpack_returned_tuples=True)
ns=lua.table()
for f in (addon/'Data').glob('*.lua'):
    if f.stem.startswith('Names'):continue
    lua.execute(f.read_text(), 'ApexProfessions', ns)
items=set()
for _,d in ns.items():
    if not hasattr(d,'items'):continue
    for _,rec in (d['recipes'] or lua.table()).items():
        for item in (rec['mats'] or lua.table()).keys(): items.add(item)

out={}
for item in sorted(items):
    drops=read(f'X-Item-{item}-2') or []
    if isinstance(drops,dict):drops=list(drops.values())
    rows=[]
    for npc in drops:
        if not isinstance(npc,int):continue
        s=scalar(npc)
        name=s.get(1,'')
        if isinstance(name,bytes):name=name.decode()
        low,high=s.get(4,99),s.get(5,99)
        if not name or low<1 or high>60 or s.get(6,0)!=0:continue
        if s.get(13) not in (None,0):continue
        sp=read(f'X-Npc-{npc}-7') or {}
        if not isinstance(sp,dict):continue
        for area,points in sp.items():
            if area not in zones or not points or len(points)<4:continue
            pts=[p for p in points if isinstance(p,(list,tuple)) and len(p)>1 and 0<p[0]<100 and 0<p[1]<100]
            if not pts:continue
            x,y=min(pts,key=lambda p:sum((p[0]-q[0])**2+(p[1]-q[1])**2 for q in pts))[:2]
            zone=zones[area]
            rows.append(dict(npc=npc,name=name,low=low,high=high,map=zone[0],zone=zone[1],faction={'Alliance':'A','Horde':'H','Both':'C'}[zone[3]],x=round(x,2),y=round(y,2),spots=len(pts)))
    # Broad coverage with deterministic limits; keep different zones and level bands.
    rows.sort(key=lambda r:(-r['spots'],r['npc'],r['map']))
    buckets={}
    for r in rows:
        key=(r['map'],r['low']//10)
        if buckets.get(key,0)>=2:continue
        buckets[key]=buckets.get(key,0)+1
        out.setdefault(item,[]).append(r)
    if item in out:out[item]=out[item][:45]

def luaval(v):
    if isinstance(v,str):return json.dumps(v,ensure_ascii=False)
    if isinstance(v,dict):return '{'+','.join((k if isinstance(k,str) else f'[{k}]')+'='+luaval(x) for k,x in v.items())+'}'
    if isinstance(v,list):return '{'+','.join(luaval(x) for x in v)+'}'
    return str(v)
(addon/'ApexFarmData.lua').write_text('-- Reagent drop candidates from QuestieDB Forever 1.0.14, checked 2026-11-17.\n-- Sources are observed database relationships, not verified Forever drop rates. GPL-3.0.\nlocal _, ns = ...\nns.ApexDrops = '+luaval(out)+'\n',encoding='utf-8')
print(f'{len(items)} reagents checked; {len(out)} have mapped outdoor drop sources; {sum(map(len,out.values()))} source candidates')
