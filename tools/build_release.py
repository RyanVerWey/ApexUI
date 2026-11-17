"""Build the reviewed allowlist only; never read or install local game data."""
from pathlib import Path
import hashlib
import json
import shutil
import zipfile
from lupa.lua51 import LuaRuntime

root = Path(__file__).resolve().parents[1]
manifest = json.loads((root / 'release/package-manifest.json').read_text())
metadata = json.loads((root / 'release/release.json').read_text())
filename = metadata['releases'][0]['filename']
assert Path(filename).name == filename and filename.endswith('-forever.zip')
assert metadata['releases'][0]['metadata'] == [{'flavor': 'forever', 'interface': 16001}]
paths = {item['path'] for item in manifest}
assert len(paths) == len(manifest)
compile_lua = LuaRuntime().eval('function(s,n) local f,e=loadstring(s,n); assert(f,e) end')
lua_count = 0
for item in manifest:
    path = root / item['path']
    assert path.resolve().is_relative_to(root.resolve())
    data = path.read_bytes()
    assert hashlib.sha256(data).hexdigest() == item['sha256'], f'Unreviewed change: {item["path"]}'
    if path.suffix == '.lua':
        compile_lua(data.decode('utf-8-sig'), item['path'])
        lua_count += 1
    if path.suffix == '.toc':
        for line in data.decode('utf-8-sig').splitlines():
            line = line.strip()
            if line and not line.startswith('#'):
                target = (path.parent / line.replace('\\', '/')).relative_to(root).as_posix()
                assert target in paths, f'Missing TOC file: {target}'
assert not list((root / '.github/workflows').glob('*')), 'No Actions workflows are allowed for this project.'
out = root / '.dist'
out.mkdir(exist_ok=True)
archive = out / filename
with zipfile.ZipFile(archive, 'w', compression=zipfile.ZIP_DEFLATED, compresslevel=9) as bundle:
    for item in sorted(manifest, key=lambda entry: entry['path']):
        info = zipfile.ZipInfo(item['path'], date_time=(2026, 11, 17, 0, 0, 0))
        info.compress_type = zipfile.ZIP_DEFLATED
        info.external_attr = 0o644 << 16
        bundle.writestr(info, (root / item['path']).read_bytes(), compresslevel=9)
with zipfile.ZipFile(archive) as bundle:
    assert bundle.testzip() is None
    assert set(bundle.namelist()) == paths
shutil.copy2(root / 'release/release.json', out / 'release.json')
checksum = hashlib.sha256(archive.read_bytes()).hexdigest()
(out / 'SHA256SUMS.txt').write_text(f'{checksum}  {filename}\n', encoding='ascii')
print(f'PASS: {len(paths)} files, {lua_count} Lua chunks, TOC references and ZIP integrity.')
print(f'{archive}\nSHA256 {checksum}')
