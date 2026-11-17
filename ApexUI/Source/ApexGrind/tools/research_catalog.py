"""Read locally installed reference facts; never changes Questie or the game."""
from pathlib import Path
import base64
import re
import sys

root = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(root.parents[1] / 'outputs/apexgrind-build-deps'))
import cbor2

db = Path(r'C:\Program Files (x86)\World of Warcraft\_forever_\Interface\AddOns\QuestieDB')
metadata = dict(re.findall(r'^## (X-Npc-[^:]+): (.+)$', (db/'QuestieDB_Forever.toc').read_text(encoding='utf-8-sig'), re.M))
rows = {}
for key, encoded in metadata.items():
    if key.endswith('-S'):
        row = cbor2.loads(base64.b64decode(encoded))
        if isinstance(row, list): row = dict(enumerate(row, 1))
        row = {k: v.decode() if isinstance(v, bytes) else v for k,v in row.items()}
        rows[int(key.split('-')[2])] = row

def spawns(npc):
    key = f'X-Npc-{npc}-7'
    data = metadata.get(key)
    if not data:
        return {}
    if data.startswith('~'):
        data = ''.join(metadata[f'{key}-{i}'] for i in range(1, int(data.strip('~'))+1))
    result=cbor2.loads(base64.b64decode(data))
    return dict(enumerate(result,1)) if isinstance(result,list) else result

if __name__ == '__main__':
    pattern = re.compile('|'.join(sys.argv[1:]), re.I)
    for npc, row in sorted(rows.items(), key=lambda pair: (pair[1].get(4, 99), pair[0])):
        if pattern.search(row.get(1,'')) and row.get(4,99)<=60 and row.get(6,0)==0:
            points=spawns(npc)
            print(npc, row.get(1), row.get(4), row.get(5), 'friendly',row.get(13),
                  'zones', {z:len(p) for z,p in points.items()})
