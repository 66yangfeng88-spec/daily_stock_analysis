# Mac mini Local Deployment

This fork is maintained and run from `/Users/y/Projects/daily_stock_analysis`.

## Jobs

- `com.daily-stock-analysis.macmini`
  - Starts at user login.
  - Runs `scripts/macmini-run.sh`.
  - Keeps the WebUI and built-in daily scheduler alive.
  - WebUI follows `.env` (`WEBUI_HOST` / `WEBUI_PORT`).

- `com.daily-stock-analysis.upstream-sync`
  - Runs every Monday at 08:30 local time.
  - Fetches `ZhuLinsen/daily_stock_analysis` as `upstream`.
  - Merges `upstream/main` into local `main`, runs `compileall`, and pushes `origin/main`.
  - If the working tree is dirty or a merge conflict occurs, it aborts and writes details to `logs/upstream_sync.log`.

## Install Or Update

```bash
cd /Users/y/Projects/daily_stock_analysis
scripts/install-macmini-launchd.sh
```

## Useful Commands

```bash
launchctl print gui/$(id -u)/com.daily-stock-analysis.macmini
launchctl print gui/$(id -u)/com.daily-stock-analysis.upstream-sync
tail -f logs/macmini_launchd.err.log
tail -f logs/upstream_sync.log
```
