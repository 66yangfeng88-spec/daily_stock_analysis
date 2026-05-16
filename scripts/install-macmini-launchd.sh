#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LAUNCH_AGENTS_DIR="$HOME/Library/LaunchAgents"
SERVICE_LABEL="com.daily-stock-analysis.macmini"
SYNC_LABEL="com.daily-stock-analysis.upstream-sync"
SERVICE_PLIST="$LAUNCH_AGENTS_DIR/$SERVICE_LABEL.plist"
SYNC_PLIST="$LAUNCH_AGENTS_DIR/$SYNC_LABEL.plist"
USER_ID="$(id -u)"

mkdir -p "$LAUNCH_AGENTS_DIR" "$REPO_DIR/logs"
chmod +x "$REPO_DIR/scripts/macmini-run.sh" "$REPO_DIR/scripts/macmini-sync-upstream.sh"

cat > "$SERVICE_PLIST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>$SERVICE_LABEL</string>
  <key>ProgramArguments</key>
  <array>
    <string>$REPO_DIR/scripts/macmini-run.sh</string>
  </array>
  <key>WorkingDirectory</key>
  <string>$REPO_DIR</string>
  <key>RunAtLoad</key>
  <true/>
  <key>KeepAlive</key>
  <true/>
  <key>StandardOutPath</key>
  <string>$REPO_DIR/logs/macmini_launchd.out.log</string>
  <key>StandardErrorPath</key>
  <string>$REPO_DIR/logs/macmini_launchd.err.log</string>
</dict>
</plist>
PLIST

cat > "$SYNC_PLIST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>$SYNC_LABEL</string>
  <key>ProgramArguments</key>
  <array>
    <string>$REPO_DIR/scripts/macmini-sync-upstream.sh</string>
  </array>
  <key>WorkingDirectory</key>
  <string>$REPO_DIR</string>
  <key>StartCalendarInterval</key>
  <dict>
    <key>Weekday</key>
    <integer>1</integer>
    <key>Hour</key>
    <integer>8</integer>
    <key>Minute</key>
    <integer>30</integer>
  </dict>
  <key>StandardOutPath</key>
  <string>$REPO_DIR/logs/upstream_sync_launchd.out.log</string>
  <key>StandardErrorPath</key>
  <string>$REPO_DIR/logs/upstream_sync_launchd.err.log</string>
</dict>
</plist>
PLIST

plutil -lint "$SERVICE_PLIST" "$SYNC_PLIST"

launchctl bootout "gui/$USER_ID" "$SERVICE_PLIST" 2>/dev/null || true
launchctl bootout "gui/$USER_ID" "$SYNC_PLIST" 2>/dev/null || true
launchctl bootstrap "gui/$USER_ID" "$SERVICE_PLIST"
launchctl bootstrap "gui/$USER_ID" "$SYNC_PLIST"
launchctl enable "gui/$USER_ID/$SERVICE_LABEL"
launchctl enable "gui/$USER_ID/$SYNC_LABEL"
launchctl kickstart -k "gui/$USER_ID/$SERVICE_LABEL"

echo "Installed launchd jobs:"
echo "  $SERVICE_LABEL: WebUI + daily scheduled analysis"
echo "  $SYNC_LABEL: weekly upstream sync, Monday 08:30 local time"
