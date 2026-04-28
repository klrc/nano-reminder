#!/bin/bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CLAUDE_DIR="$HOME/.claude"
HOOKS_DIR="$CLAUDE_DIR/hooks"
SETTINGS="$CLAUDE_DIR/settings.json"
GLOBAL_CLAUDE="$CLAUDE_DIR/CLAUDE.md"
HOOK="$HOOKS_DIR/nano-reminder-stop.sh"
ASK_HOOK="$HOOKS_DIR/nano-reminder-ask-hook.sh"

mkdir -p "$HOOKS_DIR"

cat > "$HOOK" <<'HOOK'
#!/bin/zsh
set -euo pipefail

payload="$(cat)"

PAYLOAD="$payload" /usr/bin/python3 - <<'PY'
import json
import os
import pathlib
import re
import subprocess
import sys

APP_BIN = "/Applications/NanoReminder.app/Contents/MacOS/NanoReminder"
MAX_TEXT_CHARS = 180

def load_payload():
    try:
        return json.loads(os.environ.get("PAYLOAD", "{}"))
    except Exception:
        return {}

def load_transcript(path):
    if not path:
        return []
    transcript = pathlib.Path(os.path.expanduser(path))
    if not transcript.exists():
        return []
    rows = []
    for line in transcript.read_text(errors="ignore").splitlines():
        try:
            rows.append(json.loads(line))
        except Exception:
            pass
    return rows

def is_real_user_prompt(row):
    if row.get("type") != "user":
        return False
    message = row.get("message") or {}
    content = message.get("content")
    if isinstance(content, list):
        return not any(isinstance(item, dict) and item.get("type") == "tool_result" for item in content)
    return message.get("role") == "user" and isinstance(content, str)

def row_contains_nano_notification(row):
    message = row.get("message") or {}
    content = message.get("content")
    for item in content if isinstance(content, list) else []:
        if not isinstance(item, dict) or item.get("type") != "tool_use":
            continue
        if item.get("name") == "mcp__nano-reminder__notify_now":
            return True
        if item.get("name") == "Bash":
            command = str((item.get("input") or {}).get("command", ""))
            if "nano-reminder" in command and " show" in command:
                return True
    text = json.dumps(row, ensure_ascii=False)
    return "NanoReminder launch resident=false" in text or "ReminderWindowManager present" in text

def already_notified_this_turn(rows):
    start = 0
    for index, row in enumerate(rows):
        if is_real_user_prompt(row):
            start = index
    return any(row_contains_nano_notification(row) for row in rows[start:])

def mood_marker_from(text):
    match = re.search(r"(?:\[nano-mood:|<!--\s*nano-mood:)(calm|happy|grateful|confused|panic|shocked)(?:\]|(?:\s*-->))", text)
    return match.group(1) if match else ""

def text_from_last_message(value):
    if not isinstance(value, str):
        return "", ""
    marker_mood = mood_marker_from(value)
    text = re.sub(r"\[nano-mood:(?:calm|happy|grateful|confused|panic|shocked)\]", "", value)
    text = re.sub(r"<!--\s*nano-mood:(?:calm|happy|grateful|confused|panic|shocked)\s*-->", "", text)
    text = re.sub(r"```.*?```", "[代码片段]", text, flags=re.S)
    text = re.sub(r"\n{3,}", "\n\n", text)
    text = "\n".join(line.rstrip() for line in text.splitlines()).strip()
    if len(text) > MAX_TEXT_CHARS:
        text = text[:MAX_TEXT_CHARS].rstrip() + "..."
    return text, marker_mood

def mood_for(text):
    lowered = text.lower()
    if any(word in lowered for word in ["失败", "错误", "异常", "报错", "震惊", "惊讶", "吓", "😱", "failed", "error"]):
        return "shocked"
    if any(word in lowered for word in ["紧急", "马上", "立刻", "加班", "随时待命", "urgent"]):
        return "panic"
    if any(word in lowered for word in ["需要你", "请选择", "判断", "确认", "开玩笑", "玩笑", "解雇", "被抓", "?", "？"]):
        return "confused"
    if any(word in lowered for word in ["谢谢", "感谢", "辛苦"]):
        return "grateful"
    if any(word in lowered for word in ["完成", "通过", "成功", "好了", "哈哈", "😂", "😁", "😄", "done", "success"]):
        return "happy"
    return "calm"

data = load_payload()
if data.get("stop_hook_active") is True:
    sys.exit(0)
if already_notified_this_turn(load_transcript(data.get("transcript_path"))):
    sys.exit(0)

text, marker_mood = text_from_last_message(data.get("last_assistant_message", ""))
if not text:
    text = "Claude 本轮已结束。"
if pathlib.Path(APP_BIN).exists():
    subprocess.Popen([APP_BIN, "show", "--text", text, "--mood", marker_mood or mood_for(text)], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
PY
HOOK

chmod +x "$HOOK"
cp "$REPO_DIR/bin/nano-reminder-ask-hook.sh" "$ASK_HOOK"
chmod +x "$ASK_HOOK"

python3 - "$SETTINGS" "$HOOK" "$ASK_HOOK" <<'PY'
import json
import pathlib
import sys

settings_path = pathlib.Path(sys.argv[1])
hook = sys.argv[2]
ask_hook = sys.argv[3]
data = {}
if settings_path.exists():
    data = json.loads(settings_path.read_text())

hooks = data.setdefault("hooks", {})

def install(event, command, matcher=None):
    event_hooks = hooks.setdefault(event, [])
    event_hooks[:] = [
        item for item in event_hooks
        if not any(h.get("command") == command for h in item.get("hooks", []))
    ]
    entry = {"hooks": [{"type": "command", "command": command}]}
    if matcher:
        entry["matcher"] = matcher
    event_hooks.append(entry)

install("Stop", hook)
install("PreToolUse", ask_hook, "AskUserQuestion")
install("PermissionRequest", ask_hook)
install("Notification", ask_hook, "permission_prompt")
settings_path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n")
PY

touch "$GLOBAL_CLAUDE"
python3 - "$GLOBAL_CLAUDE" <<'PY'
import pathlib
import re
import sys

path = pathlib.Path(sys.argv[1])
text = path.read_text() if path.exists() else ""
block = """<!-- nano-reminder:start -->
Nano Reminder mirrors each final reply via the user Stop hook. End every final reply with one hidden mood marker: `<!-- nano-mood:happy -->`.

Pick expressive moods boldly; avoid `calm` unless the reply is a dry factual status. Use `happy` for greeting/success/playful banter, `grateful` for thanks/acknowledgement, `confused` for ambiguity/teasing/“are you kidding?”, `ask` for explicit user choice/permission, `panic` for urgent/overloaded, `shocked` for failure/surprise/being startled or roasted. Do not manually notify at every turn; only use `mcp__nano-reminder__notify_now` for explicit custom/immediate reminders.
<!-- nano-reminder:end -->"""
pattern = r"<!-- nano-reminder:start -->.*?<!-- nano-reminder:end -->"
if re.search(pattern, text, flags=re.S):
    text = re.sub(pattern, block, text, flags=re.S)
else:
    text = text.rstrip() + "\n\n" + block + "\n"
path.write_text(text)
PY

echo "Claude Stop hook installed: $HOOK"
echo "Claude ask hook installed: $ASK_HOOK"
