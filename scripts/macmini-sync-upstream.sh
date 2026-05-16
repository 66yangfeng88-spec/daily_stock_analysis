#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOG_DIR="$REPO_DIR/logs"
LOCK_DIR="$REPO_DIR/.git/macmini-upstream-sync.lock"
UPSTREAM_URL="${UPSTREAM_REPO_URL:-https://github.com/ZhuLinsen/daily_stock_analysis.git}"

mkdir -p "$LOG_DIR"
exec >> "$LOG_DIR/upstream_sync.log" 2>&1

echo "[$(date '+%Y-%m-%d %H:%M:%S')] upstream sync start"
cd "$REPO_DIR"

if ! mkdir "$LOCK_DIR" 2>/dev/null; then
  echo "another upstream sync is already running"
  exit 0
fi
trap 'rmdir "$LOCK_DIR"' EXIT

if ! git remote get-url upstream >/dev/null 2>&1; then
  git remote add upstream "$UPSTREAM_URL"
fi

git fetch origin main --prune
git fetch upstream main --prune

if [ "$(git rev-parse --abbrev-ref HEAD)" != "main" ]; then
  git checkout main
fi

if [ -n "$(git status --porcelain)" ]; then
  echo "working tree is dirty; skip automatic upstream sync"
  git status --short
  exit 1
fi

git pull --ff-only origin main

if git merge-base --is-ancestor upstream/main HEAD; then
  echo "already includes upstream/main; nothing to do"
  exit 0
fi

echo "new upstream commits:"
git log --oneline HEAD..upstream/main

if ! git merge --no-edit upstream/main; then
  echo "merge conflict while syncing upstream; aborting"
  git status --short
  git merge --abort || true
  exit 1
fi

"$REPO_DIR/.venv/bin/python" -m compileall -q \
  "$REPO_DIR/main.py" \
  "$REPO_DIR/server.py" \
  "$REPO_DIR/webui.py" \
  "$REPO_DIR/api" \
  "$REPO_DIR/bot" \
  "$REPO_DIR/data_provider" \
  "$REPO_DIR/src"

git push origin main
echo "[$(date '+%Y-%m-%d %H:%M:%S')] upstream sync complete"
