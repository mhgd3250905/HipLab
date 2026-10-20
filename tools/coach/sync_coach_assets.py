#!/usr/bin/env python3
"""从 ugk-3d-pose-sdk 同步 AI 定制的内置资产（目录快照只取 hiplab 范围 + profile）。

用法：python3 tools/coach/sync_coach_assets.py /path/to/ugk-3d-pose-sdk
升级 SDK（pubspec.yaml 里 ugk_coach 的 ref）时，用同一提交的 SDK 仓库重跑一次。
资产不改 profile：App 侧的范围交集（只用动作大全里有视频和动作包的动作）在运行时做，
见 lib/hip/coach/coach_service.dart 与 docs/ai-coach.md。
"""
import json
import subprocess
import sys
from pathlib import Path

sdk = Path(sys.argv[1] if len(sys.argv) > 1 else '../ugk-coach-sdk')
out = Path(__file__).resolve().parents[2] / 'assets' / 'coach'
out.mkdir(parents=True, exist_ok=True)

catalog = json.loads((sdk / 'test/fixtures/pose-hub-catalog.json').read_text(encoding='utf-8'))
profile = json.loads((sdk / 'profiles/hiplab.json').read_text(encoding='utf-8'))
apps = set(profile['select'].get('apps', []))
catalog['drills'] = [d for d in catalog['drills'] if apps & set(d.get('apps', []))]
if isinstance(catalog.get('apps'), dict):
    catalog['apps'] = {k: v for k, v in catalog['apps'].items() if k in apps or k == 'pose-hub'}
try:
    sha = subprocess.check_output(['git', '-C', str(sdk), 'rev-parse', 'HEAD'], text=True).strip()
except Exception:
    sha = 'unknown'
catalog.setdefault('source', {})
if isinstance(catalog['source'], dict):
    catalog['source']['hiplabSnapshot'] = {'sdkCommit': sha, 'filter': {'apps': sorted(apps)}}

(out / 'catalog.json').write_text(json.dumps(catalog, ensure_ascii=False, indent=1) + '\n', encoding='utf-8')
(out / 'hiplab.json').write_text(json.dumps(profile, ensure_ascii=False, indent=1) + '\n', encoding='utf-8')
print(f"catalog {catalog['version']} drills={len(catalog['drills'])} sdk={sha[:7]} -> {out}")
