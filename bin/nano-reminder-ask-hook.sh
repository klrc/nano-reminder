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


def load_payload():
    try:
        return json.loads(os.environ.get("PAYLOAD", "{}"))
    except Exception:
        return {}


def summarize_tool(data):
    tool_name = data.get("tool_name") or "Claude"
    tool_input = data.get("tool_input") or {}
    if tool_name == "Bash":
        command = str(tool_input.get("command", "")).strip()
        description = str(tool_input.get("description", "")).strip()
        body = description or command
        return f"允许执行 Bash？\n\n`{body[:220]}`"
    if tool_name in {"Edit", "Write", "MultiEdit"}:
        path = tool_input.get("file_path") or tool_input.get("path") or ""
        return f"允许修改文件？\n\n`{path}`"
    return f"允许 Claude 使用 {tool_name}？"


def run_nano(text, choices):
    if not pathlib.Path(APP_BIN).exists():
        return ""
    proc = subprocess.run(
        [APP_BIN, "show", "--text", text, "--mood", "ask", "--choices", ",".join(choices)],
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
    )
    match = re.search(r"NanoReminder choice:\s*(.+)", proc.stdout)
    return match.group(1).strip() if match else ""


def ask_permission(data):
    choice = run_nano(summarize_tool(data), ["允许", "拒绝"])
    behavior = "allow" if choice == "允许" else "deny"
    decision = {"behavior": behavior}
    if behavior == "deny":
        decision["message"] = "用户通过 Nano Reminder 拒绝了这次操作。"
    return {
        "hookSpecificOutput": {
            "hookEventName": "PermissionRequest",
            "decision": decision,
        }
    }


def question_text(question):
    if isinstance(question, str):
        return question
    if isinstance(question, dict):
        for key in ("question", "text", "prompt", "title", "label"):
            value = question.get(key)
            if isinstance(value, str) and value.strip():
                return value.strip()
    return "Claude 需要你确认。"


def question_choices(question):
    if isinstance(question, dict):
        for key in ("choices", "options"):
            values = question.get(key)
            if isinstance(values, list):
                labels = []
                for value in values:
                    if isinstance(value, str):
                        labels.append(value)
                    elif isinstance(value, dict):
                        label = value.get("label") or value.get("value") or value.get("text")
                        if label:
                            labels.append(str(label))
                labels = [label.strip() for label in labels if label.strip()]
                if labels:
                    return labels[:5]
    return ["是", "否"]


def ask_user_question(data):
    tool_input = data.get("tool_input") or {}
    questions = tool_input.get("questions")
    if not isinstance(questions, list) or not questions:
        questions = [tool_input.get("question") or tool_input.get("prompt") or "Claude 需要你确认。"]

    answers = {}
    for question in questions:
        text = question_text(question)
        choice = run_nano(text, question_choices(question))
        if not choice:
            choice = "取消"
        answers[text] = choice

    updated = dict(tool_input)
    updated["questions"] = questions
    updated["answers"] = answers
    return {
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "allow",
            "updatedInput": updated,
        }
    }


def notify_permission_prompt(data):
    message = data.get("message") or "Claude 正在等待确认。"
    run_nano(str(message), ["知道了"])
    return None


data = load_payload()
event = data.get("hook_event_name")
tool_name = data.get("tool_name")
notification_type = data.get("notification_type") or data.get("type")

if event == "PermissionRequest":
    print(json.dumps(ask_permission(data), ensure_ascii=False))
elif event == "PreToolUse" and tool_name == "AskUserQuestion":
    print(json.dumps(ask_user_question(data), ensure_ascii=False))
elif event == "Notification" and notification_type == "permission_prompt":
    notify_permission_prompt(data)
PY
