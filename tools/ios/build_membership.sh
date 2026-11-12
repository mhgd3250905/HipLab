#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../.."
flutter_bin="${FLUTTER_BIN:-flutter}"
config="${HIP_RC_IOS_CONFIG_FILE:?Set HIP_RC_IOS_CONFIG_FILE to a local JSON file}"
python3 - "$config" <<'PY'
import json
import re
import sys
with open(sys.argv[1], encoding='utf-8') as source:
    config = json.load(source)
if set(config) != {'HIP_RC_IOS_KEY'} or not re.fullmatch(r'appl_[A-Za-z0-9]+', config['HIP_RC_IOS_KEY']):
    raise SystemExit('Expected a JSON file containing only the public HIP_RC_IOS_KEY.')
PY
defines=(
  "--dart-define-from-file=$config"
  "--dart-define=HIP_AI_GATEWAY_URL=https://ugk-ai-gateway.294851575.workers.dev/v1"
  "--dart-define=POSEHUB_CATALOG_CHANNEL=stable"
  "--dart-define=UGK_COACH_APP_KEY="
  "--dart-define=UGK_COACH_TOKEN="
)
case "${1:-}" in
  simulator) "$flutter_bin" build ios --simulator --debug --no-pub "${defines[@]}" ;;
  archive) "$flutter_bin" build ipa --release --no-codesign --no-pub "${defines[@]}" ;;
  *) printf 'Usage: %s simulator|archive\n' "$0" >&2; exit 2 ;;
esac
