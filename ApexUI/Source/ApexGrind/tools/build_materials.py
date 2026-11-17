"""Cross-reference curated NPCs with online ClassicDB drop/skinning tables."""
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor
import json
import re
import urllib.request

root=Path(__file__).resolve().parents[1]
cache=root.parents[1]/'outputs/apexgrind-research'
cache.mkdir(exist_ok=True)
materials=[(2589,'Linen Cloth','drop'),(2592,'Wool Cloth','drop'),(4306,'Silk Cloth','drop'),
 (4338,'Mageweave Cloth','drop'),(14047,'Runecloth','drop'),(2318,'Light Leather','skin'),
 (2319,'Medium Leather','skin'),(4234,'Heavy Leather','skin'),(4304,'Thick Leather','skin'),
 (8170,'Rugged Leather','skin')]

def fetch(item):
    item_id,name,method=item
    path=cache/f'item-{item_id}.html'
    if not path.exists():
        request=urllib.request.Request(f'https://classicdb.ch/?item={item_id}',headers={'User-Agent':'ApexGrind research/0.2'})
        with urllib.request.urlopen(request,timeout=30) as response:
            path.write_bytes(response.read())
    html=path.read_text(encoding='utf-8')
    tables=re.findall(r"new Listview\(\{template:'npc',id:'([^']+)'.*?data:(\[.*?\])\}\);",html,re.S)
    wanted='skinned-from' if method=='skin' else 'dropped-by'
    found=[data for key,data in tables if key==wanted]
    if len(found)!=1:
        raise ValueError((item_id,wanted,[k for k,_ in tables]))
    rates={}
    for obj in re.findall(r'\{([^{}]+)\}',found[0]):
        npc=re.search(r'\bid:(\d+)',obj)
        percent=re.search(r'\bpercent:([0-9.eE+-]+)',obj)
        if npc and percent and float(percent.group(1))>0:
            rates[int(npc.group(1))]=round(float(percent.group(1)),3)
    assert rates,(name,'Empty drop table')
    return item_id,rates

if __name__=='__main__':
    with ThreadPoolExecutor(max_workers=3) as pool:
        tables=dict(pool.map(fetch,materials))
    catalog=json.loads((root/'tools/spot-evidence.json').read_text())
    used={s['npc'] for s in catalog}
    lines=['-- Online ClassicDB NPC loot/skinning facts, checked 2026-11-16.',
           '-- Historical rates are used only to reject incidental drops, not shown as Forever rates.',
           'local _, A = ...','A.materials = {']
    for item_id,name,method in materials:
        # Reject incidental corpse drops such as ~0.01% leather from humanoids.
        drops={npc:rate for npc,rate in tables[item_id].items() if npc in used and rate>=1}
        assert drops,(name,'No curated source')
        lines.append(' {id=%d,name=%s,method=%s,npcs={%s}},'%(
            item_id,json.dumps(name),json.dumps(method),','.join('[%d]=%s'%(npc,drops[npc]) for npc in sorted(drops))))
        print(name,len(drops),'curated NPC sources')
    lines.append('}')
    (root/'Materials.lua').write_text('\n'.join(lines)+'\n',encoding='utf-8')
    (root/'tools/material-evidence.json').write_text(json.dumps({str(k):{str(n):v for n,v in t.items() if n in used} for k,t in tables.items()},indent=2))
