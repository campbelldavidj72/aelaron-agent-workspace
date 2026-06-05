#!/usr/bin/env python3
"""Shared AEGF instruction-layer logic for Cursor, Claude, and validation scripts."""
from __future__ import annotations

import json
import sys
from datetime import datetime, timezone
from pathlib import Path

try:
    import yaml
except ImportError:
    yaml = None  # type: ignore


def repo_root() -> Path:
    env = __import__("os").environ.get("AEGF_REPO_ROOT")
    if env:
        return Path(env)
    # This file lives at aegf-tooling/.github/scripts/ (L0) or legacy governance repo.
    return Path(__file__).resolve().parents[2]


def aegf_tooling_root(ws: Path | None = None) -> Path:
    """Resolve L0 aegf-tooling directory for the program workspace."""
    ws = ws or workspace_root()
    candidate = ws / "aegf-tooling"
    if (candidate / "templates" / "governance-firing-catalog.yaml").is_file():
        return candidate
    legacy = ws / "aelaron-framework-governance"
    if (legacy / "templates" / "governance-firing-catalog.yaml").is_file():
        return legacy
    sibling = ws / ".." / "aelaron-framework-governance"
    if (sibling / "templates" / "governance-firing-catalog.yaml").is_file():
        return sibling.resolve()
    return candidate


def workspace_root() -> Path:
    env = __import__("os").environ.get("AEGF_WORKSPACE_ROOT")
    if env:
        return Path(env)
    return Path(__import__("os").environ.get("CURSOR_PROJECT_DIR", Path.cwd()))


def catalog_path(root: Path | None = None) -> Path:
    r = root or repo_root()
    return r / "templates/governance-firing-catalog.yaml"


def role_catalog_path(root: Path | None = None) -> Path:
    r = root or repo_root()
    return r / "templates/agent-role-catalog.yaml"


def skills_catalog_path(root: Path | None = None) -> Path:
    r = root or repo_root()
    return r / "templates/agent-skills-catalog.yaml"


def load_yaml(path: Path) -> dict:
    if not yaml:
        return {}
    if not path.is_file():
        return {}
    return yaml.safe_load(path.read_text(encoding="utf-8")) or {}


def applicable_checkpoint_count(catalog: dict, run_type: str = "standard") -> int:
    group_names = catalog.get("run_types", {}).get(run_type, {}).get("groups", [])
    count = 0
    for gname in group_names:
        for el in catalog.get("groups", {}).get(gname, {}).get("elements", []):
            el_rts = el.get("run_types")
            if el_rts and run_type not in el_rts:
                continue
            count += 1
    return count


def instruction_layer_paths(ws: Path) -> dict[str, Path]:
    aegf = aegf_tooling_root(ws)
    return {
        "AGENTS.md": ws / "AGENTS.md",
        "CLAUDE.md": ws / "CLAUDE.md",
        "copilot-instructions": ws / ".github" / "copilot-instructions.md",
        "cursor-hooks": ws / ".cursor" / "hooks.json",
        "cursor-governance-rule": ws / ".cursor" / "rules" / "aegf-governance.mdc",
        "claude-settings": ws / ".claude" / "settings.json",
        "aegf-tooling": aegf,
        "firing-catalog": aegf / "templates" / "governance-firing-catalog.yaml",
        "run-report-script": aegf / ".github" / "scripts" / "governance-run-report.sh",
        "role-catalog": aegf / "templates" / "agent-role-catalog.yaml",
        "skills-catalog": aegf / "templates" / "agent-skills-catalog.yaml",
    }


def validate_instruction_layer(ws: Path | None = None) -> tuple[bool, list[str], dict[str, bool]]:
    ws = ws or workspace_root()
    paths = instruction_layer_paths(ws)
    required = [
        "AGENTS.md",
        "cursor-hooks",
        "cursor-governance-rule",
        "aegf-tooling",
        "firing-catalog",
        "run-report-script",
    ]
    recommended = ["CLAUDE.md", "copilot-instructions", "claude-settings", "role-catalog"]
    present = {k: (paths[k].is_file() or paths[k].is_dir()) for k in paths}
    missing = [k for k in required if not present[k]]
    ok = len(missing) == 0
    gaps = missing + [k for k in recommended if not present[k]]
    return ok, gaps, present


def governance_context_markdown(ws: Path | None = None, agent_kind: str = "primary") -> str:
    ws = ws or workspace_root()
    aegf = aegf_tooling_root(ws)
    catalog = load_yaml(catalog_path(aegf))
    count = applicable_checkpoint_count(catalog) if catalog else 14
    ok, gaps, _ = validate_instruction_layer(ws)

    lines = [
        "## AEGF session governance (auto-injected)",
        "",
        f"Agent surface: **{agent_kind}**",
        "",
        "You are operating under the Aelaron Enterprise Governance Framework.",
        "Read workspace `AGENTS.md` before implementing.",
        "",
        "### Non-negotiables",
        "- Linked GitHub issue with `status/ready` before coding (except E0 analysis)",
        "- PRs target `development` only; humans merge `main`",
        "- Run declared verification profile; attach evidence in PR",
        "- Stay within issue envelope and allowed paths",
        "- Subagents inherit the same constraints — do not bypass intake or envelope rules",
        "",
        "### Metrication (advisory)",
        f"Standard run catalog: **{count}** checkpoints.",
        "For PRs and release work, run `governance-run-report.sh` with `--fire` and paste output in the PR.",
        "Local agent sessions: no stop-hook enforcement — do not block on end-of-run reports.",
        "",
        "Catalog: `aegf-tooling/templates/governance-firing-catalog.yaml`",
        "Roles: `aegf-tooling/templates/agent-role-catalog.yaml`",
        "Skills: `aegf-tooling/templates/agent-skills-catalog.yaml`",
        "Specs (L1): `aelaron-platform-specifications/` @ tag in app baseline.yaml",
        "Project skills: `.cursor/skills/aegf-*` in agent workspace",
        "Activity log: append-only `agent-log.jsonl` at workspace root (hooks + `agent-log.py`)",
    ]
    if not ok:
        lines.extend(["", "### Instruction layer gaps (restore before implementation)"])
        for g in gaps:
            lines.append(f"- Missing or incomplete: `{g}`")
    return "\n".join(lines)


def report_followup_message() -> str:
    # Stop/subagentStop follow-ups disabled permanently (caused infinite loops).
    return ""


def _merge_skill_lists(*lists: list | None) -> list[str]:
    out: list[str] = []
    seen: set[str] = set()
    for lst in lists:
        for item in lst or []:
            if item and item not in seen:
                seen.add(item)
                out.append(item)
    return out


def resolve_skills_for_subagent(subagent_type: str) -> dict[str, list[str]]:
    catalog = load_yaml(skills_catalog_path())
    global_ps = catalog.get("global_project_skills", [])
    sub_cfg = catalog.get("subagent_skills", {}).get(subagent_type, {})

    allowed_ps: list[str] = []
    allowed_plug: list[str] = []
    forbidden_plug: list[str] = []

    merge_key = sub_cfg.get("merge")
    if merge_key == "domain_agent_policy":
        dp = catalog.get("domain_agent_policy", {})
        allowed_ps = _merge_skill_lists(global_ps, dp.get("allowed_project_skills"))
        allowed_plug = list(dp.get("allowed_plugin_skills") or [])
        forbidden_plug = list(dp.get("forbidden_plugin_skills") or [])
    elif merge_key and merge_key.startswith("worker_agents."):
        role = merge_key.split(".", 1)[1]
        wp = catalog.get("worker_agents", {}).get(role, {})
        allowed_ps = _merge_skill_lists(global_ps, wp.get("allowed_project_skills"))
        allowed_plug = list(wp.get("allowed_plugin_skills") or [])
    elif sub_cfg:
        allowed_ps = _merge_skill_lists(global_ps, sub_cfg.get("allowed_project_skills"))
        allowed_plug = list(sub_cfg.get("allowed_plugin_skills") or [])
        forbidden_plug = list(sub_cfg.get("forbidden_plugin_skills") or [])
    else:
        allowed_ps = list(global_ps)

    return {
        "allowed_project": allowed_ps,
        "allowed_plugin": allowed_plug,
        "forbidden_plugin": forbidden_plug,
    }


def skills_policy_suffix(subagent_type: str) -> str:
    skills = resolve_skills_for_subagent(subagent_type)
    if not any(skills.values()):
        return ""
    lines = ["\n### Skills policy (`agent-skills-catalog.yaml`)\n"]
    if skills["allowed_project"]:
        names = ", ".join(f"`{n}`" for n in skills["allowed_project"])
        lines.append(f"- Project skills (`.cursor/skills/`): {names}\n")
    if skills["allowed_plugin"]:
        names = ", ".join(f"`{n}`" for n in skills["allowed_plugin"])
        lines.append(f"- Plugin skills (when applicable): {names}\n")
    if skills["forbidden_plugin"]:
        names = ", ".join(f"`{n}`" for n in skills["forbidden_plugin"])
        lines.append(f"- Do not use: {names}\n")
    lines.append("- Load project skills when the task matches; refuse plugin skills outside this list.\n")
    return "".join(lines)


def domain_agent_log_suffix() -> str:
    return (
        "\n### Governed work — domain agent logging (mandatory)\n"
        "- **Governed work** = any task impacting code, specs, or baselines (E1+ or pre-worker curation).\n"
        "- After reading L0/L1, log validation:\n"
        "  `python3 aegf-tooling/.github/scripts/agent-log.py validate-context "
        "--domain-agent-role <role> --target-repository <repo> --issue <N> --clear-active`\n"
        "- Log thinking as you work (major curation decisions):\n"
        "  `python3 .../agent-log.py think --agent-kind domain --domain-agent-role <role> --message \"...\"`\n"
        "- Confirm **framework_pins** (aegf, aapf, …) in the validation event match enterprise baseline / VERSION.\n"
        "- Hooks auto-track reads into `context_validation` when possible; always run `validate-context` before handoff.\n"
    )


def worker_agent_log_suffix() -> str:
    return (
        "\n### Governed work — worker agent logging\n"
        "- Log thinking during analysis: `agent-log.py think --agent-kind worker --worker-agent-role <role> --message \"...\"`\n"
        "- After pin bumps or before implementation, log `freshness_validated` via agent-log skill.\n"
    )


def subagent_governance_suffix(subagent_type: str) -> str:
    roles = load_yaml(role_catalog_path())
    cfg = roles.get("cursor_subagents", {}).get(subagent_type, {})
    max_env = cfg.get("max_envelope", "E0")
    firing = cfg.get("firing_report", "advisory")
    role = cfg.get("role", subagent_type)
    lines = [
        "\n\n---\n**AEGF subagent constraints (mandatory)**\n",
        f"- Role: {role} | Max envelope: {max_env}\n",
        "- Obey workspace AGENTS.md: issue-first, development branch, allowed paths only\n",
        f"- Firing report: {firing}\n",
        "- Do not merge to `main`. Escalate if scope exceeds envelope.\n",
        "- Load only issue **context pack** tiers (L0–L2); do not ingest full repository\n",
        "- End of task: **Context used** table in PR or final message; attest CTX-002\n",
    ]
    if max_env in ("E2", "E3", "E4") or subagent_type in ("engineer", "generalPurpose", "shell"):
        lines.append("- E2+ implementation: domain agent context pack must exist on issue before coding (CTX-003)\n")
    if subagent_type == "explore":
        lines.append(domain_agent_log_suffix())
    if subagent_type in ("engineer", "quality-engineer", "enterprise-architect"):
        lines.append(worker_agent_log_suffix())
    lines.append(skills_policy_suffix(subagent_type))
    return "".join(lines)


def subagent_requires_report(subagent_type: str, modified_files: list | None = None) -> bool:
    roles = load_yaml(role_catalog_path())
    cfg = roles.get("cursor_subagents", {}).get(subagent_type, {})
    policy = cfg.get("firing_report", "advisory")
    if policy == "never":
        return False
    if policy == "required":
        return True
    if policy == "required_if_modified":
        return bool(modified_files)
    return False


def write_session_state(state_path: Path, payload: dict) -> None:
    state_path.parent.mkdir(parents=True, exist_ok=True)
    state_path.write_text(json.dumps(payload, indent=2), encoding="utf-8")


def read_session_state(state_path: Path) -> dict:
    if not state_path.is_file():
        return {}
    return json.loads(state_path.read_text(encoding="utf-8"))


def mark_report_logged(state_path: Path, command: str = "") -> None:
    state = read_session_state(state_path)
    state["report_logged"] = True
    state["report_logged_at"] = datetime.now(timezone.utc).isoformat()
    if command:
        state["report_command"] = command[:500]
    write_session_state(state_path, state)


def main() -> None:
    if len(sys.argv) < 2:
        print("Usage: governance-instruction-context.py <command>", file=sys.stderr)
        sys.exit(1)
    cmd = sys.argv[1]
    ws = workspace_root()

    if cmd == "context-md":
        kind = sys.argv[2] if len(sys.argv) > 2 else "primary"
        print(governance_context_markdown(ws, kind))
    elif cmd == "validate-json":
        ok, gaps, present = validate_instruction_layer(ws)
        print(json.dumps({"ok": ok, "gaps": gaps, "present": present}, indent=2))
    elif cmd == "followup":
        print(report_followup_message())
    elif cmd == "subagent-suffix":
        st = sys.argv[2] if len(sys.argv) > 2 else "generalPurpose"
        print(subagent_governance_suffix(st), end="")
    else:
        print(f"Unknown command: {cmd}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
