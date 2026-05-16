#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_DIR"

mkdir -p data logs reports

exec "$REPO_DIR/.venv/bin/python" "$REPO_DIR/main.py" --webui --schedule --no-run-immediately
