#!/bin/bash
set -euo pipefail

CLAUDE_DIR="$HOME/.claude"
HOOK="$CLAUDE_DIR/hooks/nano-reminder-stop.sh"
SETTINGS="$CLAUDE_DIR/settings.json"
GLOBAL_CLAUDE="$CLAUDE_DIR/CLAUDE.md"

rm -f "$HOOK"

if [[ -f "$SETTINGS" ]]; then
  python3 - "$SETTINGS" "$HOOK" <<'PY'
import json
import pathlib
import sys

settings_path = pathlib.Path(sys.argv[1])
hook = sys.argv[2]
data = json.loads(settings_path.read_text())
hooks = data.get("hooks", {})
stop_hooks = hooks.get("Stop", [])
hooks["Stop"] = [
    item for item in stop_hooks
    if not any(h.get("command") == hook for h in item.get("hooks", []))
]
if not hooks["Stop"]:
    hooks.pop("Stop", None)
if not hooks:
    data.pop("hooks", None)
settings_path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n")
PY
fi

if [[ -f "$GLOBAL_CLAUDE" ]]; then
  python3 - "$GLOBAL_CLAUDE" <<'PY'
import pathlib
import re
import sys

path = pathlib.Path(sys.argv[1])
text = path.read_text()
text = re.sub(r"\n?<!-- nano-reminder:start -->.*?<!-- nano-reminder:end -->\n?", "\n", text, flags=re.S)
path.write_text(text.rstrip() + "\n")
PY
fi

echo "Claude Stop hook uninstalled."
