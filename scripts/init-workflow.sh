#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

"$SCRIPT_DIR/specflow.sh" init

if [[ $# -gt 0 ]]; then
  "$SCRIPT_DIR/specflow.sh" new "$*"
fi

"$SCRIPT_DIR/status.sh"
