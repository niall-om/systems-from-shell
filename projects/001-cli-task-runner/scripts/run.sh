#!/usr/bin/env bash
set -eou pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "[run] starting project"
echo "[run] project root: $PROJECT_ROOT"

# Example:
# "$PROJECT_ROOT/scripts/orchestrator.sh"