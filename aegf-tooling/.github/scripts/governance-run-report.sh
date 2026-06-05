#!/usr/bin/env bash
# Generate governance firing / coverage report. See docs/metrics/governance-firing-model.md
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
exec python3 "$ROOT/.github/scripts/governance-run-report.py" "$@"
