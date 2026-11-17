"""Run portable Lua 5.1 regression checks locally, without accessing WoW."""
from pathlib import Path
import subprocess
import sys

root = Path(__file__).resolve().parents[1]
tests = sorted((root / 'ApexUI/tools').glob('test_*.py'))
for module in ('ApexFishing', 'ApexNavigator', 'ApexProfessions'):
    tests += sorted((root / 'ApexUI/Source' / module / 'tests').glob('test_*.py'))
tests += sorted((root / 'ApexUI/Source/ApexGrind/tools').glob('test_*.py'))
tests += [root / 'ApexUI/Source/ApexProfessions/tests/run_tests.py']
failed = []
logs = root / 'test-results'
logs.mkdir(exist_ok=True)
for index, path in enumerate(tests, 1):
    result = subprocess.run([sys.executable, str(path)], cwd=root, capture_output=True, text=True, encoding='utf-8', errors='replace')
    (logs / f'{index:02d}-{path.stem}.txt').write_text(result.stdout + result.stderr, encoding='utf-8')
    print(f'{"PASS" if result.returncode == 0 else "FAIL"} {path.relative_to(root)}', flush=True)
    if result.returncode:
        failed.append(path)
        print(result.stderr[-2000:])
print(f'{len(tests)-len(failed)}/{len(tests)} test suites passed.')
sys.exit(bool(failed))
