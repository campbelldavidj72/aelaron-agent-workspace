#!/usr/bin/env python3
"""Generate AEGF governance firing / coverage reports for agent runs and PRs."""
from __future__ import annotations

import argparse
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

try:
    import yaml
except ImportError:
    print("ERROR: PyYAML required (pip install pyyaml)", file=sys.stderr)
    sys.exit(1)

ROOT = Path(__file__).resolve().parents[2]
CATALOG = ROOT / "templates/governance-firing-catalog.yaml"


def load_catalog() -> dict:
    return yaml.safe_load(CATALOG.read_text()) or {}


def applicable_elements(catalog: dict, run_type: str) -> list[dict]:
    rt = catalog.get("run_types", {}).get(run_type, {})
    group_names = rt.get("groups", [])
    out: list[dict] = []
    for gname in group_names:
        group = catalog.get("groups", {}).get(gname, {})
        for el in group.get("elements", []):
            el_run_types = el.get("run_types")
            if el_run_types and run_type not in el_run_types:
                continue
            out.append(
                {
                    "id": el["id"],
                    "name": el["name"],
                    "group": gname,
                    "group_label": group.get("label", gname),
                    "detect": el.get("detect", "attested"),
                    "ci_context": el.get("ci_context", ""),
                }
            )
    return out


def parse_ids(s: str | None) -> set[str]:
    if not s:
        return set()
    return {x.strip() for x in s.split(",") if x.strip()}


def parse_ci(s: str | None) -> set[str]:
    return parse_ids(s)


def build_report(
    catalog: dict,
    run_type: str,
    fired: set[str],
    ci_pass: set[str],
) -> tuple[dict, str]:
    elements = applicable_elements(catalog, run_type)
    by_group: dict[str, list[dict]] = {}
    for el in elements:
        eid = el["id"]
        if el["detect"] == "ci":
            is_fired = eid in fired or el.get("ci_context", "") in ci_pass
        else:
            is_fired = eid in fired
        el["fired"] = is_fired
        by_group.setdefault(el["group_label"], []).append(el)

    total_applicable = len(elements)
    total_fired = sum(1 for el in elements if el["fired"])
    pct = round((total_fired / total_applicable * 100), 1) if total_applicable else 0.0

    lines = [
        "## Governance run report",
        "",
        f"Run type: `{run_type}` | Fired: **{total_fired}/{total_applicable}** ({pct}%)",
        "",
        "| Group | Fired | Applicable | Coverage |",
        "|---|---:|---:|---:|",
    ]
    for label, els in by_group.items():
        f = sum(1 for e in els if e["fired"])
        a = len(els)
        p = round((f / a * 100), 1) if a else 0.0
        lines.append(f"| {label} | {f} | {a} | {p}% |")
    lines.append(f"| **Total** | **{total_fired}** | **{total_applicable}** | **{pct}%** |")
    lines.append("")
    lines.append("### Fired elements")
    fired_list = [el for el in elements if el["fired"]]
    if fired_list:
        for el in fired_list:
            lines.append(f"- `{el['id']}` {el['name']}")
    else:
        lines.append("- _(none attested)_")
    lines.append("")
    missed = [el for el in elements if not el["fired"]]
    if missed:
        lines.append("### Missed (applicable but not fired)")
        for el in missed:
            lines.append(f"- `{el['id']}` {el['name']}")
        lines.append("")

    summary = {
        "run_type": run_type,
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "fired": total_fired,
        "applicable": total_applicable,
        "coverage_pct": pct,
        "fired_ids": [el["id"] for el in elements if el["fired"]],
        "missed_ids": [el["id"] for el in elements if not el["fired"]],
    }
    return summary, "\n".join(lines)


def append_log(log_path: Path, entry: dict) -> None:
    log_path.parent.mkdir(parents=True, exist_ok=True)
    with log_path.open("a", encoding="utf-8") as f:
        f.write(json.dumps(entry, separators=(",", ":")) + "\n")


def summarize_log(log_path: Path) -> str:
    if not log_path.is_file():
        return "## Governance coverage (cumulative)\n\n_No run log found._\n"

    entries = []
    for line in log_path.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if line:
            entries.append(json.loads(line))
    if not entries:
        return "## Governance coverage (cumulative)\n\n_Empty run log._\n"

    all_fired: set[str] = set()
    all_missed: set[str] = set()
    run_type = entries[-1].get("run_type", "standard")
    for e in entries:
        all_fired.update(e.get("fired_ids", []))
        all_missed.update(e.get("missed_ids", []))
    # Latest run type for applicable set
    catalog = load_catalog()
    applicable = {el["id"] for el in applicable_elements(catalog, run_type)}
    cumulative_fired = all_fired & applicable
    cumulative_missed = applicable - cumulative_fired
    total = len(applicable)
    fired_n = len(cumulative_fired)
    pct = round((fired_n / total * 100), 1) if total else 0.0

    lines = [
        "## Governance coverage (cumulative)",
        "",
        f"Runs logged: **{len(entries)}** | Run type: `{run_type}` | "
        f"Cumulative fired: **{fired_n}/{total}** ({pct}%)",
        "",
        "### All fired IDs (across runs on this branch)",
    ]
    for eid in sorted(cumulative_fired):
        lines.append(f"- `{eid}`")
    if cumulative_missed:
        lines.append("")
        lines.append("### Still missed vs applicable catalog")
        for eid in sorted(cumulative_missed):
            lines.append(f"- `{eid}`")
    lines.append("")
    return "\n".join(lines)


def main() -> None:
    parser = argparse.ArgumentParser(description="AEGF governance run report")
    parser.add_argument("--run-type", default="standard", choices=["standard", "material", "release"])
    parser.add_argument("--issue", help="Linked issue number")
    parser.add_argument("--profile", help="Verification profile ID")
    parser.add_argument("--fire", help="Comma-separated element IDs attested as fired")
    parser.add_argument("--ci-pass", help="Comma-separated CI context names passed")
    parser.add_argument("--append-log", type=Path, help="Append JSON line to run log")
    parser.add_argument("--summarize-log", type=Path, help="Summarize cumulative log for PR")
    parser.add_argument("--for-pr", action="store_true", help="Alias for --summarize-log default path")
    args = parser.parse_args()

    if args.for_pr or args.summarize_log:
        log = args.summarize_log or Path("governance/metrics/runs.jsonl")
        print(summarize_log(log))
        return

    catalog = load_catalog()
    fired = parse_ids(args.fire)
    ci_pass = parse_ci(args.ci_pass)

    # Auto-map common attestation from flags
    if args.issue:
        fired.update({"INT-001", "VER-AGT-01"})
    if args.profile:
        fired.add("EXE-003")
        if args.profile.startswith("VP-GOV"):
            fired.add("VER-GOV-01")
        if args.profile.startswith("VP-REL"):
            fired.update({"VER-REL-01", "REL-001", "REL-002", "BRN-002"})

    summary, markdown = build_report(catalog, args.run_type, fired, ci_pass)
    if args.issue:
        summary["issue"] = args.issue
    if args.profile:
        summary["profile"] = args.profile

    print(markdown)
    if args.append_log:
        append_log(args.append_log, summary)


if __name__ == "__main__":
    main()
