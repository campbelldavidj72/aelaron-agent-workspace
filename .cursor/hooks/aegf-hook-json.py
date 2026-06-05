#!/usr/bin/env python3
"""Parse Cursor hook stdin JSON (tolerates trailing extra data on the line)."""
from __future__ import annotations

import json
import os
import sys


def parse_hook_input(raw: str) -> dict:
    text = raw.strip()
    if not text:
        return {}
    try:
        parsed = json.loads(text)
        return parsed if isinstance(parsed, dict) else {}
    except json.JSONDecodeError:
        obj, _end = json.JSONDecoder().raw_decode(text)
        return obj if isinstance(obj, dict) else {}


def load_payload() -> dict:
    raw = os.environ.get("INPUT")
    if raw is None:
        raw = sys.stdin.read()
    return parse_hook_input(raw)


def field_value(payload: dict, key: str) -> str:
    if key == "session_id":
        return str(payload.get("session_id") or payload.get("conversation_id") or "unknown")
    if key == "composer_mode":
        return str(payload.get("composer_mode") or "agent")
    if key == "hook_event_name":
        return str(payload.get("hook_event_name") or "")
    val = payload.get(key, "")
    return "" if val is None else str(val)


def main() -> int:
    payload = load_payload()
    if len(sys.argv) == 1:
        print(json.dumps(payload, separators=(",", ":")))
        return 0
    for key in sys.argv[1:]:
        print(field_value(payload, key))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
