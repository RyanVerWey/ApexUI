"""Build a compact, attributed snapshot of the installed MIT OpenMap travel data."""
from pathlib import Path
import json
from lupa.lua51 import LuaRuntime

root = Path(__file__).resolve().parents[1]
source = Path(r'C:\Program Files (x86)\World of Warcraft\_forever_\Interface\AddOns\OpenMap')
lua = LuaRuntime(unpack_returned_tuples=True)
ns = lua.table()
for file in ('Places.lua', 'FlightData.lua'):
    lua.execute('local code,ns=...; assert(loadstring(code))("OpenMap", ns)',
                (source / 'Data/Forever' / file).read_text(encoding='utf-8'), ns)
def encode(v):
    if isinstance(v, str): return json.dumps(v, ensure_ascii=True)
    return str(v)
lines = ['-- Travel facts adapted from OpenMap, MIT, Copyright (c) 2026 OpenMap contributors.',
         '-- Client data build 1.60.1.70245. See LICENSE-OpenMap.txt.',
         '-- Rebuild with tools/import_travel_data.py. Runtime has no OpenMap dependency.',
         'local _, A = ...', 'A.transports = {']
for _, row in ns.MapPlaces.transports.items():
    lines.append(' {' + ','.join(encode(row[i]) for i in range(1,9)) + '},')
lines += ['}', 'A.flightNodes = {']
for key, row in sorted(ns.MapFlights.nodes.items()):
    lines.append(' [%d]={%s},' % (key, ','.join(encode(row[i]) for i in range(1,6))))
lines += ['}', 'A.flightPaths = {']
for _, row in ns.MapFlights.paths.items():
    lines.append(' {' + ','.join(encode(row[i]) for i in range(1,5)) + '},')
lines += ['}', '']
(root / 'TravelData.lua').write_text('\n'.join(lines), encoding='utf-8')
(root / 'LICENSE-OpenMap.txt').write_text((source/'LICENSE.txt').read_text(), encoding='utf-8')
print('Imported %d transport legs, %d flight nodes, %d flight paths.' %
      (len(ns.MapPlaces.transports), len(list(ns.MapFlights.nodes.items())), len(ns.MapFlights.paths)))
