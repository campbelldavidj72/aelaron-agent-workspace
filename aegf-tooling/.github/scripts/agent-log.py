#!/usr/bin/env python3
"""Append-only agent activity log for Aelaron v4 workspace (agent-log.jsonl)."""
from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import sys
import time
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

LOG_VERSION = 1
THINKING_MAX = 12000

DOMAIN_SUBAGENTS = {"explore"}
WORKER_SUBAGENTS = {
    "engineer",
    "quality-engineer",
    "enterprise-architect",
    "product-manager",
    "program-manager",
    "ux-designer",
    "risk-manager-line1",
    "infosec-specialist",
    "platform-manager",
    "ci-investigator",
    "member-ops-specialist",
    "product-marketing",
    "capital-raising-advisor",
    "generalPurpose",
    "shell",
}


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def parse_hook_json(raw: str) -> dict[str, Any]:
    text = raw.strip()
    if not text:
        return {}
    try:
        parsed = json.loads(text)
        return parsed if isinstance(parsed, dict) else {}
    except json.JSONDecodeError:
        obj, _end = json.JSONDecoder().raw_decode(text)
        return obj if isinstance(obj, dict) else {}


def resolve_workspace_root() -> Path:
    for key in ("AEGF_WORKSPACE_ROOT", "CURSOR_PROJECT_DIR"):
        val = os.environ.get(key)
        if val:
            p = Path(val).resolve()
            if _looks_like_agent_workspace(p):
                return p
    cwd = Path.cwd().resolve()
    for p in [cwd, *cwd.parents]:
        if _looks_like_agent_workspace(p):
            return p
    return cwd


def enrich_hook_context(payload: dict[str, Any]) -> None:
    sid = payload.get("conversation_id") or payload.get("session_id")
    if sid:
        os.environ["AEGF_SESSION_ID"] = str(sid)
    for root in payload.get("workspace_roots") or []:
        p = Path(root).resolve()
        if _looks_like_agent_workspace(p):
            os.environ["AEGF_WORKSPACE_ROOT"] = str(p)
            break
    else:
        cwd = payload.get("cwd")
        if cwd:
            p = Path(cwd).resolve()
            if _looks_like_agent_workspace(p):
                os.environ["AEGF_WORKSPACE_ROOT"] = str(p)
    if os.environ.get("AGENT_LOG_TRACE"):
        trace = resolve_workspace_root() / ".cursor/governance/hook-trace.jsonl"
        trace.parent.mkdir(parents=True, exist_ok=True)
        with trace.open("a", encoding="utf-8") as fh:
            fh.write(
                json.dumps(
                    {
                        "ts": utc_now(),
                        "hook_event": payload.get("hook_event_name"),
                        "keys": sorted(payload.keys()),
                    },
                    separators=(",", ":"),
                )
                + "\n"
            )


def _as_dict(value: Any) -> dict[str, Any]:
    if isinstance(value, dict):
        return value
    if isinstance(value, str):
        try:
            parsed = json.loads(value)
            return parsed if isinstance(parsed, dict) else {}
        except json.JSONDecodeError:
            return {}
    return {}


def extract_read_path(payload: dict[str, Any]) -> str | None:
    for source in (_as_dict(payload.get("tool_input")), payload):
        for key in ("file_path", "path", "filePath", "target_file", "targetFile"):
            val = source.get(key)
            if val:
                return str(val)
    return None


def _looks_like_agent_workspace(path: Path) -> bool:
    if (path / "repos.yaml").is_file():
        return True
    if not (path / "AGENTS.md").is_file():
        return False
    return (path / "aelaron-framework-governance").is_dir() or (path / "governance" / "aegf").is_dir()


def aegf_instruction_context_script(ws: Path) -> Path | None:
    for rel in ("governance/aegf", "aelaron-framework-governance"):
        script = ws / rel / ".github" / "scripts" / "governance-instruction-context.py"
        if script.is_file():
            return script
    return None


def log_path(ws: Path | None = None) -> Path:
    return (ws or resolve_workspace_root()) / "agent-log.jsonl"


def load_session_state() -> dict[str, Any]:
    state_path = os.environ.get("AEGF_SESSION_STATE")
    if state_path and Path(state_path).is_file():
        return json.loads(Path(state_path).read_text(encoding="utf-8"))
    return {}


def session_id() -> str:
    return (
        os.environ.get("AEGF_SESSION_ID")
        or load_session_state().get("session_id")
        or "unknown"
    )


def infer_agent_kind(subagent_type: str | None) -> str:
    if not subagent_type:
        return "parent"
    if subagent_type in DOMAIN_SUBAGENTS:
        return "domain"
    if subagent_type in WORKER_SUBAGENTS:
        return "worker"
    return "parent"


def extract_role_fields(text: str) -> dict[str, str | None]:
    out: dict[str, str | None] = {
        "domain_agent_role": None,
        "worker_agent_role": None,
        "target_repository": None,
        "issue": None,
    }
    if not text:
        return out
    for key in ("domain_agent_role", "worker_agent_role", "target_repository"):
        m = re.search(rf"{key}[:\s]+[`'\"]?([a-z0-9_.-]+)", text, re.I)
        if m:
            out[key] = m.group(1).lower()
    m = re.search(r"(?:issue|closes)\s+#(\d+)", text, re.I)
    if m:
        out["issue"] = m.group(1)
    return out


def append_entry(entry: dict[str, Any], ws: Path | None = None) -> Path:
    root = ws or resolve_workspace_root()
    path = log_path(root)
    path.parent.mkdir(parents=True, exist_ok=True)
    record = {"v": LOG_VERSION, "ts": utc_now(), "session_id": session_id(), **entry}
    with path.open("a", encoding="utf-8") as fh:
        fh.write(json.dumps(record, ensure_ascii=False, separators=(",", ":")) + "\n")
    return path


def git_ref_for_path(file_path: Path) -> str | None:
    if not file_path.is_file():
        return None
    try:
        proc = subprocess.run(
            ["git", "-C", str(file_path.parent), "rev-parse", "--short", "HEAD"],
            capture_output=True,
            text=True,
            timeout=5,
        )
        if proc.returncode == 0:
            return proc.stdout.strip()
    except (OSError, subprocess.TimeoutExpired):
        pass
    return None


def read_aegf_version(ws: Path) -> str | None:
    version_file = ws / "aelaron-framework-governance" / "VERSION"
    if version_file.is_file():
        return version_file.read_text(encoding="utf-8").strip()
    return None


def submodule_pin(ws: Path, rel: str) -> str | None:
    gitmodules = ws / ".gitmodules"
    if not gitmodules.is_file():
        return None
    try:
        proc = subprocess.run(
            ["git", "-C", str(ws), "submodule", "status", "--", rel],
            capture_output=True,
            text=True,
            timeout=10,
        )
        if proc.returncode == 0 and proc.stdout.strip():
            return proc.stdout.strip().split()[0].lstrip("+-U")
    except (OSError, subprocess.TimeoutExpired):
        pass
    return None


def _load_yaml_file(path: Path) -> dict[str, Any]:
    if not path.is_file():
        return {}
    text = path.read_text(encoding="utf-8")
    try:
        import yaml  # type: ignore

        return yaml.safe_load(text) or {}
    except Exception:
        return {}


def resolve_program_framework_pins(ws: Path | None = None) -> dict[str, str]:
    root = ws or resolve_workspace_root()
    pins: dict[str, str] = {}
    aegf = read_aegf_version(root)
    if aegf:
        pins["aegf"] = aegf if aegf.startswith("v") else f"v{aegf}"
    baseline = root / "aelaron-enterprise-application" / "governance" / "baseline.yaml"
    data = _load_yaml_file(baseline)
    for key, block in (data.get("frameworks") or {}).items():
        if isinstance(block, dict) and block.get("version"):
            pins[str(key)] = str(block["version"])
    return pins


def domain_active_path(ws: Path | None = None) -> Path:
    return (ws or resolve_workspace_root()) / ".cursor/governance/domain-active.json"


def load_domain_active(ws: Path | None = None) -> dict[str, Any]:
    path = domain_active_path(ws)
    if path.is_file():
        return json.loads(path.read_text(encoding="utf-8"))
    return {}


def save_domain_active(state: dict[str, Any], ws: Path | None = None) -> None:
    path = domain_active_path(ws)
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(state, indent=2), encoding="utf-8")


def clear_domain_active(ws: Path | None = None) -> None:
    path = domain_active_path(ws)
    if path.is_file():
        path.unlink()


def _rel_path(ws: Path, path: str) -> str:
    p = Path(path)
    if not p.is_absolute():
        p = (ws / path).resolve()
    try:
        return str(p.relative_to(ws))
    except ValueError:
        return str(path)


def _parse_read_spec(spec: str) -> dict[str, str]:
    parts = spec.split(":")
    path = parts[0].strip()
    tier = parts[1].strip() if len(parts) > 1 else ""
    pin = parts[2].strip() if len(parts) > 2 else ""
    return {"path": path, "context_tier": tier, "pin_ref": pin}


def _merge_reads(
    tracked: list[dict[str, Any]], explicit: list[dict[str, str]]
) -> list[dict[str, Any]]:
    by_path: dict[str, dict[str, Any]] = {}
    for item in tracked:
        by_path[item.get("path", "")] = item
    for item in explicit:
        path = item["path"]
        existing = by_path.get(path, {})
        by_path[path] = {
            "path": path,
            "context_tier": item.get("context_tier") or existing.get("context_tier"),
            "pin_ref": item.get("pin_ref") or existing.get("pin_ref"),
        }
    return list(by_path.values())


def freshness_snapshot(ws: Path, trigger: str) -> dict[str, Any]:
    snap: dict[str, Any] = {"trigger": trigger, "checks": []}
    aegf_ver = read_aegf_version(ws)
    if aegf_ver:
        snap["checks"].append(
            {"target": "aelaron-framework-governance", "observed": f"v{aegf_ver}", "kind": "VERSION"}
        )
    baseline = ws / "aelaron-enterprise-application" / "governance" / "baseline.yaml"
    if baseline.is_file():
        snap["checks"].append(
            {
                "target": "governance/baseline.yaml",
                "observed": git_ref_for_path(baseline),
                "kind": "git_sha",
            }
        )
    for rel in ("governance/aegf",):
        for repo in (
            ws / "aelaron-enterprise-application",
            ws / "aelaron-framework-architecture",
        ):
            sub = repo / rel
            if (repo / ".git").exists() or (repo / ".git").is_file():
                pin = submodule_pin(repo, rel) if (repo / ".gitmodules").is_file() else None
                if pin or sub.is_dir():
                    snap["checks"].append(
                        {
                            "target": str(repo.relative_to(ws)) + "/" + rel,
                            "observed": pin,
                            "kind": "submodule",
                        }
                    )
    return snap


def hook_session_start(payload: dict[str, Any]) -> None:
    enrich_hook_context(payload)
    ws = resolve_workspace_root()
    validation = {}
    aegf = aegf_instruction_context_script(ws)
    if aegf:
        try:
            proc = subprocess.run(
                ["python3", str(aegf), "validate-json"],
                capture_output=True,
                text=True,
                timeout=15,
                env={**os.environ, "AEGF_WORKSPACE_ROOT": str(ws)},
            )
            if proc.returncode == 0:
                validation = json.loads(proc.stdout or "{}")
        except (OSError, subprocess.TimeoutExpired, json.JSONDecodeError):
            pass
    append_entry(
        {
            "event": "session_start",
            "agent_kind": "parent",
            "composer_mode": payload.get("composer_mode"),
            "instruction_layer_ok": validation.get("ok"),
            "summary": "Agent session started",
            "meta": {"missing_files": validation.get("gaps", [])},
        },
        ws,
    )


def hook_session_end(payload: dict[str, Any]) -> None:
    enrich_hook_context(payload)
    state = load_session_state()
    append_entry(
        {
            "event": "session_end",
            "agent_kind": "parent",
            "reason": payload.get("reason"),
            "duration_ms": payload.get("duration_ms"),
            "instruction_layer_ok": state.get("instruction_layer_ok"),
            "report_logged": state.get("report_logged"),
            "summary": "Agent session ended",
        }
    )


def _infer_context_tier(path: str) -> str:
    name = Path(path).name
    if name == "AGENTS.md" or "baseline.yaml" in name or name == "MANIFEST.md":
        return "L0"
    if "agent-verification-profiles" in path:
        return "L1"
    return "L2"


def hook_context_read(payload: dict[str, Any]) -> None:
    enrich_hook_context(payload)
    path = extract_read_path(payload)
    if not path:
        return
    ws = resolve_workspace_root()
    abs_path = Path(path)
    if not abs_path.is_absolute():
        abs_path = (ws / path).resolve()
    rel = _rel_path(ws, str(path))
    tier = _infer_context_tier(rel)
    pin = git_ref_for_path(abs_path) if abs_path.is_file() else None
    active = load_domain_active(ws)
    agent_kind = os.environ.get("AEGF_AGENT_KIND", "parent")
    if active and active.get("session_id") == session_id():
        agent_kind = "domain"
        reads = active.get("reads") or []
        reads.append({"path": rel, "context_tier": tier, "pin_ref": pin})
        active["reads"] = reads
        save_domain_active(active, ws)
    append_entry(
        {
            "event": "context_read",
            "agent_kind": agent_kind,
            "path": rel,
            "context_tier": tier,
            "pin_ref": pin,
            "domain_agent_role": active.get("domain_agent_role") if agent_kind == "domain" else None,
            "summary": f"Read into context: {rel}",
        },
        ws,
    )


def hook_subagent_start(payload: dict[str, Any]) -> None:
    enrich_hook_context(payload)
    subagent_type = payload.get("subagent_type") or payload.get("subagentType") or "unknown"
    prompt = payload.get("prompt") or payload.get("task") or payload.get("description") or ""
    roles = extract_role_fields(prompt)
    kind = infer_agent_kind(subagent_type)
    if roles.get("worker_agent_role"):
        kind = "worker"
    elif kind == "domain" and roles.get("domain_agent_role"):
        kind = "domain"
    ws = resolve_workspace_root()
    entry: dict[str, Any] = {
        "event": "subagent_engaged",
        "agent_kind": kind,
        "subagent_type": subagent_type,
        "domain_agent_role": roles.get("domain_agent_role"),
        "worker_agent_role": roles.get("worker_agent_role") or (
            subagent_type if kind == "worker" else None
        ),
        "issue": roles.get("issue"),
        "summary": f"{kind} agent engaged: {subagent_type}",
        "meta": {"prompt_chars": len(prompt)},
    }
    append_entry(entry, ws)
    if kind == "domain":
        save_domain_active(
            {
                "session_id": session_id(),
                "domain_agent_role": roles.get("domain_agent_role"),
                "target_repository": roles.get("target_repository"),
                "issue": roles.get("issue"),
                "reads": [],
                "started_at": utc_now(),
            },
            ws,
        )
        append_entry(
            {
                "event": "governed_work_start",
                "agent_kind": "domain",
                "domain_agent_role": roles.get("domain_agent_role"),
                "issue": roles.get("issue"),
                "governed": True,
                "summary": "Governed work — domain agent curating context",
                "framework_pins": resolve_program_framework_pins(ws),
            },
            ws,
        )


def hook_pretooluse_task(payload: dict[str, Any]) -> None:
    hook_subagent_start(
        {
            "subagent_type": (payload.get("tool_input") or {}).get("subagent_type")
            or (payload.get("tool_input") or {}).get("subagentType"),
            "prompt": (payload.get("tool_input") or {}).get("prompt")
            or (payload.get("tool_input") or {}).get("task")
            or (payload.get("tool_input") or {}).get("description"),
        }
    )


def hook_agent_thought(payload: dict[str, Any]) -> None:
    enrich_hook_context(payload)
    thought = (
        payload.get("text")
        or payload.get("thought")
        or payload.get("content")
        or payload.get("thinking")
        or ""
    )
    if not thought or not str(thought).strip():
        return
    text = str(thought).strip()
    if len(text) > THINKING_MAX:
        text = text[:THINKING_MAX] + "…[truncated]"
    subagent_type = payload.get("subagent_type") or payload.get("subagentType")
    kind = infer_agent_kind(subagent_type)
    ws = resolve_workspace_root()
    active = load_domain_active(ws)
    entry: dict[str, Any] = {
        "event": "agent_thinking",
        "agent_kind": kind,
        "subagent_type": subagent_type,
        "thinking": text,
        "summary": f"{kind} agent thinking ({len(text)} chars)",
        "governed": bool(active) and active.get("session_id") == session_id(),
    }
    if kind == "domain" and active:
        entry["domain_agent_role"] = active.get("domain_agent_role")
    append_entry(entry, ws)


def hook_post_tool_use(payload: dict[str, Any]) -> None:
    enrich_hook_context(payload)
    tool = (payload.get("tool_name") or payload.get("toolName") or "").strip()
    if not tool:
        return
    if tool in ("Read", "read"):
        hook_context_read(payload)
        return
    if tool == "Task":
        hook_pretooluse_task(payload)
        return
    ti = _as_dict(payload.get("tool_input"))
    summary = tool or "tool"
    if tool == "Shell":
        summary = f"{tool} — {_truncate(str(ti.get('command', '')), 100)}"
    elif tool in ("Grep", "Glob", "SemanticSearch"):
        summary = f"{tool} — {_truncate(str(ti.get('pattern') or ti.get('query') or ti), 100)}"
    elif tool == "Write":
        summary = f"{tool} — {ti.get('path', '')}"
    append_entry(
        {
            "event": "tool_use",
            "agent_kind": "parent",
            "path": ti.get("path"),
            "summary": summary,
            "meta": {"tool": tool, "duration_ms": payload.get("duration")},
        }
    )


def hook_after_file_edit(payload: dict[str, Any]) -> None:
    enrich_hook_context(payload)
    path = payload.get("file_path") or payload.get("path")
    if not path:
        return
    ws = resolve_workspace_root()
    try:
        rel = str(Path(path).resolve().relative_to(ws))
    except ValueError:
        rel = str(path)
    append_entry(
        {
            "event": "file_edit",
            "agent_kind": "parent",
            "path": rel,
            "summary": f"Edited: {rel}",
            "meta": {"edits": len(payload.get("edits") or [])},
        },
        ws,
    )


def hook_shell_freshness(payload: dict[str, Any]) -> None:
    enrich_hook_context(payload)
    command = payload.get("command") or ""
    if not command:
        return
    ws = resolve_workspace_root()
    snap = freshness_snapshot(ws, command.strip()[:500])
    append_entry(
        {
            "event": "freshness_check",
            "agent_kind": "parent",
            "summary": "Freshness probe after sync/submodule/validation command",
            "freshness": snap,
            "meta": {"command": command.strip()[:500]},
        },
        ws,
    )


HOOKS = {
    "session-start": hook_session_start,
    "session-end": hook_session_end,
    "context-read": hook_context_read,
    "subagent-start": hook_subagent_start,
    "pretooluse-task": hook_pretooluse_task,
    "agent-thought": hook_agent_thought,
    "post-tool-use": hook_post_tool_use,
    "after-file-edit": hook_after_file_edit,
    "shell-freshness": hook_shell_freshness,
}


def cmd_think(args: argparse.Namespace) -> int:
    text = args.message or args.thinking
    if not text:
        print("think requires --message", file=sys.stderr)
        return 1
    if len(text) > THINKING_MAX:
        text = text[:THINKING_MAX] + "…[truncated]"
    entry: dict[str, Any] = {
        "event": "agent_thinking",
        "agent_kind": args.agent_kind,
        "thinking": text,
        "summary": f"{args.agent_kind} agent thinking ({len(text)} chars)",
        "governed": args.governed,
    }
    if args.domain_agent_role:
        entry["domain_agent_role"] = args.domain_agent_role
    if args.worker_agent_role:
        entry["worker_agent_role"] = args.worker_agent_role
    if args.issue:
        entry["issue"] = args.issue
    append_entry(entry)
    print(log_path())
    return 0


def cmd_validate_context(args: argparse.Namespace) -> int:
    ws = resolve_workspace_root()
    active = load_domain_active(ws)
    explicit_reads = [_parse_read_spec(spec) for spec in (args.read or [])]
    tracked = active.get("reads") or [] if active.get("session_id") == session_id() else []
    reads = _merge_reads(tracked, explicit_reads)
    pins = resolve_program_framework_pins(ws)
    for spec in args.framework_pin or []:
        if ":" in spec:
            key, val = spec.split(":", 1)
            pins[key.strip()] = val.strip()
    status = args.status or "ok"
    if not reads and status == "ok":
        status = "incomplete"
    validation: dict[str, Any] = {
        "status": status,
        "reads": reads,
        "framework_pins": pins,
        "required_tiers": [t.strip() for t in (args.required_tiers or "L0,L1").split(",") if t.strip()],
    }
    tiers_present = {r.get("context_tier") for r in reads}
    missing_tiers = [t for t in validation["required_tiers"] if t not in tiers_present]
    if missing_tiers and status == "ok":
        validation["missing_tiers"] = missing_tiers
        status = "incomplete"
        validation["status"] = status
    append_entry(
        {
            "event": "context_validation",
            "agent_kind": "domain",
            "domain_agent_role": args.domain_agent_role or active.get("domain_agent_role"),
            "target_repository": args.target_repository or active.get("target_repository"),
            "issue": args.issue or active.get("issue"),
            "governed": True,
            "validation": validation,
            "framework_pins": pins,
            "summary": (
                f"Domain context validated ({status}): "
                f"{len(reads)} files, pins {', '.join(f'{k}={v}' for k, v in list(pins.items())[:4])}"
            ),
        },
        ws,
    )
    if args.clear_active:
        clear_domain_active(ws)
    print(log_path())
    return 0


def cmd_append(args: argparse.Namespace) -> int:
    entry: dict[str, Any] = {
        "event": args.event,
        "agent_kind": args.agent_kind,
        "summary": args.summary or args.event,
    }
    if args.path:
        entry["path"] = args.path
    if args.paths:
        entry["paths"] = [p.strip() for p in args.paths.split(",") if p.strip()]
    if args.context_tier:
        entry["context_tier"] = args.context_tier
    if args.domain_agent_role:
        entry["domain_agent_role"] = args.domain_agent_role
    if args.worker_agent_role:
        entry["worker_agent_role"] = args.worker_agent_role
    if args.issue:
        entry["issue"] = args.issue
    if args.thinking:
        text = args.thinking
        if len(text) > THINKING_MAX:
            text = text[:THINKING_MAX] + "…[truncated]"
        entry["thinking"] = text
    if args.pin_ref:
        entry["pin_ref"] = args.pin_ref
    if args.freshness_json:
        entry["freshness"] = json.loads(args.freshness_json)
    append_entry(entry)
    print(log_path())
    return 0


def _short_time(ts: str) -> str:
    if len(ts) >= 19:
        return ts[11:19]
    return ts


def _short_session(session_id: str | None) -> str:
    if not session_id or session_id == "unknown":
        return "—"
    if len(session_id) > 8:
        return session_id[:8]
    return session_id


def _truncate(text: str, limit: int = 120) -> str:
    text = " ".join(text.split())
    if len(text) <= limit:
        return text
    return text[: limit - 1] + "…"


def _colorize(text: str, code: str, use_color: bool) -> str:
    if not use_color or not sys.stdout.isatty():
        return text
    return f"\033[{code}m{text}\033[0m"


EVENT_COLORS = {
    "session_start": "36",
    "session_end": "36",
    "context_read": "32",
    "subagent_engaged": "33",
    "agent_thinking": "35",
    "freshness_check": "34",
    "freshness_validated": "34",
    "context_pack": "32",
    "context_validation": "32",
    "governed_work_start": "36",
    "tool_use": "90",
    "file_edit": "93",
    "log_error": "31",
}


def format_entry_line(record: dict[str, Any], use_color: bool = True) -> str:
    event = record.get("event", "?")
    kind = record.get("agent_kind", "?")
    time_part = _short_time(record.get("ts", ""))
    session = _short_session(record.get("session_id"))
    event_label = _colorize(event, EVENT_COLORS.get(event, "0"), use_color)

    parts = [f"{time_part}", f"[{event_label}]", f"{kind}", f"sid={session}"]

    if event == "context_read":
        tier = record.get("context_tier")
        path = record.get("path", "?")
        pin = record.get("pin_ref")
        detail = f"{tier} {path}" if tier else path
        if pin:
            detail += f" @{pin}"
        parts.append(f"— {detail}")

    elif event == "subagent_engaged":
        sub = record.get("subagent_type", "?")
        roles = []
        if record.get("domain_agent_role"):
            roles.append(f"domain={record['domain_agent_role']}")
        if record.get("worker_agent_role"):
            roles.append(f"worker={record['worker_agent_role']}")
        role_txt = f" ({', '.join(roles)})" if roles else ""
        issue = record.get("issue")
        issue_txt = f" issue=#{issue}" if issue else ""
        parts.append(f"— {sub}{role_txt}{issue_txt}")

    elif event == "agent_thinking":
        sub = record.get("subagent_type")
        if sub:
            parts.append(f"— {sub}")
        thought = record.get("thinking") or record.get("summary") or ""
        parts.append(f"| {_truncate(thought, 160)}")

    elif event in ("freshness_check", "freshness_validated"):
        path = record.get("path")
        pin = record.get("pin_ref")
        if path and pin:
            parts.append(f"— {path} @{pin}")
        elif record.get("freshness"):
            checks = record["freshness"].get("checks", [])
            items = [f"{c.get('target')}: {c.get('observed')}" for c in checks[:3]]
            parts.append(f"— {', '.join(items)}")
            if len(checks) > 3:
                parts.append(f"(+{len(checks) - 3} more)")
        else:
            parts.append(f"— {record.get('summary', '')}")

    elif event == "context_pack":
        paths = record.get("paths") or []
        issue = record.get("issue")
        dom = record.get("domain_agent_role")
        parts.append(f"— domain={dom} issue=#{issue}" if issue else f"— domain={dom}")
        if paths:
            parts.append(f"| {', '.join(paths[:4])}")
            if len(paths) > 4:
                parts.append(f"(+{len(paths) - 4})")

    elif event == "context_validation":
        dom = record.get("domain_agent_role", "?")
        val = record.get("validation") or {}
        status = val.get("status", "?")
        reads = val.get("reads") or []
        pins = record.get("framework_pins") or {}
        pin_txt = ", ".join(f"{k}={v}" for k, v in list(pins.items())[:3])
        parts.append(f"— domain={dom} status={status} reads={len(reads)}")
        if pin_txt:
            parts.append(f"| pins: {pin_txt}")
        if reads:
            sample = ", ".join(
                f"{r.get('context_tier', '?')}:{r.get('path', '?')}" for r in reads[:3]
            )
            parts.append(f"| {sample}")
            if len(reads) > 3:
                parts.append(f"(+{len(reads) - 3})")

    elif event == "governed_work_start":
        dom = record.get("domain_agent_role")
        issue = record.get("issue")
        pins = record.get("framework_pins") or {}
        pin_txt = ", ".join(f"{k}={v}" for k, v in list(pins.items())[:3])
        parts.append(f"— domain={dom}" + (f" issue=#{issue}" if issue else ""))
        if pin_txt:
            parts.append(f"| {pin_txt}")

    elif event == "session_start":
        ok = record.get("instruction_layer_ok")
        mode = record.get("composer_mode")
        extra = []
        if mode:
            extra.append(mode)
        if ok is not None:
            extra.append("layer_ok" if ok else "layer_gap")
        if extra:
            parts.append(f"— {' '.join(extra)}")

    elif event == "session_end":
        reason = record.get("reason")
        dur = record.get("duration_ms")
        extra = []
        if reason:
            extra.append(reason)
        if dur is not None:
            extra.append(f"{dur}ms")
        if extra:
            parts.append(f"— {' '.join(extra)}")

    else:
        summary = record.get("summary")
        if summary:
            parts.append(f"— {summary}")

    return " ".join(parts)


def _print_lines(lines: list[str], use_color: bool) -> None:
    for line in lines:
        line = line.strip()
        if not line:
            continue
        try:
            print(format_entry_line(json.loads(line), use_color))
        except json.JSONDecodeError:
            print(line)


def _iter_log_lines(path: Path, from_start: bool) -> Any:
    with path.open(encoding="utf-8") as fh:
        if not from_start:
            fh.seek(0, os.SEEK_END)
        while True:
            line = fh.readline()
            if line:
                yield line
            else:
                time.sleep(0.2)
                if not path.exists():
                    time.sleep(0.8)


def cmd_follow(args: argparse.Namespace) -> int:
    path = Path(args.file) if args.file else log_path()
    use_color = not args.no_color

    if not path.is_file():
        print(f"Waiting for {path} …", file=sys.stderr)
        while not path.is_file():
            time.sleep(0.5)

    if args.from_start:
        _print_lines(path.read_text(encoding="utf-8").splitlines(), use_color)
        if args.no_follow:
            return 0
    elif args.lines > 0 and path.is_file():
        all_lines = path.read_text(encoding="utf-8").splitlines()
        if all_lines:
            print(
                _colorize(f"── last {min(args.lines, len(all_lines))} entries ──", "90", use_color),
                file=sys.stderr,
            )
            _print_lines(all_lines[-args.lines :], use_color)
        if args.no_follow:
            return 0

    print(
        _colorize(f"── following {path} (Ctrl+C to stop) ──", "90", use_color),
        file=sys.stderr,
    )
    try:
        for line in _iter_log_lines(path, from_start=False):
            line = line.strip()
            if not line:
                continue
            try:
                print(format_entry_line(json.loads(line), use_color))
            except json.JSONDecodeError:
                print(line)
    except KeyboardInterrupt:
        print("\n── stopped ──", file=sys.stderr)
    return 0


def cmd_hook(args: argparse.Namespace) -> int:
    handler = HOOKS.get(args.hook_type)
    if not handler:
        print(f"Unknown hook type: {args.hook_type}", file=sys.stderr)
        return 1
    raw = sys.stdin.read()
    payload = parse_hook_json(raw)
    enrich_hook_context(payload)
    try:
        handler(payload)
    except Exception as exc:  # noqa: BLE001 — hooks must not break sessions
        append_entry(
            {
                "event": "log_error",
                "agent_kind": "system",
                "summary": f"agent-log hook failed: {args.hook_type}",
                "meta": {"error": str(exc)},
            }
        )
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description="Aelaron agent activity log")
    sub = parser.add_subparsers(dest="command", required=True)

    hook_p = sub.add_parser("hook", help="Process Cursor hook stdin JSON")
    hook_p.add_argument("hook_type", choices=sorted(HOOKS.keys()))
    hook_p.set_defaults(func=cmd_hook)

    app_p = sub.add_parser("append", help="Append a manual log entry")
    app_p.add_argument("--event", required=True)
    app_p.add_argument("--agent-kind", default="parent", dest="agent_kind")
    app_p.add_argument("--summary", default="")
    app_p.add_argument("--path", default="")
    app_p.add_argument("--paths", default="")
    app_p.add_argument("--context-tier", default="", dest="context_tier")
    app_p.add_argument("--domain-agent-role", default="", dest="domain_agent_role")
    app_p.add_argument("--worker-agent-role", default="", dest="worker_agent_role")
    app_p.add_argument("--issue", default="")
    app_p.add_argument("--thinking", default="")
    app_p.add_argument("--pin-ref", default="", dest="pin_ref")
    app_p.add_argument("--freshness-json", default="", dest="freshness_json")
    app_p.set_defaults(func=cmd_append)

    follow_p = sub.add_parser("follow", help="Tail agent-log.jsonl with readable summaries")
    follow_p.add_argument(
        "--from-start",
        action="store_true",
        help="Print existing entries before following new ones",
    )
    follow_p.add_argument(
        "--no-follow",
        action="store_true",
        help="With --from-start, print and exit (no tail)",
    )
    follow_p.add_argument("--file", default="", help="Log file path (default: workspace agent-log.jsonl)")
    follow_p.add_argument(
        "--lines",
        "-n",
        type=int,
        default=20,
        help="Show last N entries before following (default: 20; use 0 for none)",
    )
    follow_p.add_argument("--no-color", action="store_true", help="Disable ANSI colours")
    follow_p.set_defaults(func=cmd_follow)

    think_p = sub.add_parser("think", help="Log agent thinking (domain/worker)")
    think_p.add_argument("--message", default="", help="Thinking text")
    think_p.add_argument("--thinking", default="", help="Alias for --message")
    think_p.add_argument("--agent-kind", default="domain", dest="agent_kind")
    think_p.add_argument("--domain-agent-role", default="", dest="domain_agent_role")
    think_p.add_argument("--worker-agent-role", default="", dest="worker_agent_role")
    think_p.add_argument("--issue", default="")
    think_p.add_argument("--governed", action="store_true", default=True)
    think_p.add_argument("--no-governed", action="store_false", dest="governed")
    think_p.set_defaults(func=cmd_think)

    val_p = sub.add_parser(
        "validate-context",
        help="Domain agent attests files read and framework release pins",
    )
    val_p.add_argument("--domain-agent-role", required=True, dest="domain_agent_role")
    val_p.add_argument("--target-repository", default="", dest="target_repository")
    val_p.add_argument("--issue", default="")
    val_p.add_argument(
        "--read",
        action="append",
        default=[],
        help="path:tier:pin_ref (repeatable); merges with hook-tracked reads",
    )
    val_p.add_argument(
        "--framework-pin",
        action="append",
        default=[],
        help="key:version override (e.g. aegf:v1.0.9)",
    )
    val_p.add_argument("--status", choices=["ok", "incomplete", "stale"], default="ok")
    val_p.add_argument("--required-tiers", default="L0,L1", dest="required_tiers")
    val_p.add_argument(
        "--clear-active",
        action="store_true",
        help="Clear domain-active session after validation",
    )
    val_p.set_defaults(func=cmd_validate_context)

    args = parser.parse_args()
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())
