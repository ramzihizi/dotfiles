#!/usr/bin/env bash
# <xbar.title>Awake</xbar.title>
# <xbar.author>Ramzi</xbar.author>
# <xbar.desc>Menu-bar indicator + toggle for the com.rmh.awake keep-awake LaunchAgent.</xbar.desc>
# <swiftbar.refreshOnOpen>true</swiftbar.refreshOnOpen>
#
# Reflects and controls the `com.rmh.awake` LaunchAgent (which runs
# `caffeinate -i` so the Mac never idle-sleeps). The filename's `.10s.` encodes
# SwiftBar's refresh interval, so the icon re-syncs every 10s; toggle actions
# also force an immediate refresh. Toggling is per-session: the plist stays in
# ~/Library/LaunchAgents, so a "turn off" only lasts until the next login.
set -euo pipefail

LABEL="com.rmh.awake"
UID_NUM="$(id -u)"
SERVICE="gui/${UID_NUM}/${LABEL}"
PLIST="$HOME/Library/LaunchAgents/${LABEL}.plist"
LAUNCHCTL="/bin/launchctl"

if "$LAUNCHCTL" print "$SERVICE" 2>/dev/null | grep -q "state = running"; then
  state="on"
elif "$LAUNCHCTL" print "$SERVICE" >/dev/null 2>&1; then
  state="loaded" # registered but not currently running
else
  state="off"
fi

# ----- menu bar title (first line) -----
if [[ "$state" == "on" ]]; then
  echo "☕"
else
  echo "💤"
fi

echo "---"

case "$state" in
on)
  echo "Awake: ON — caffeinate -i | color=#98971a"
  echo "Turn off (until next login) | bash=$LAUNCHCTL param1=bootout param2=$SERVICE terminal=false refresh=true"
  ;;
loaded)
  echo "Awake: loaded, not running | color=#d79921"
  echo "Start now | bash=$LAUNCHCTL param1=kickstart param2=-k param3=$SERVICE terminal=false refresh=true"
  echo "Turn off | bash=$LAUNCHCTL param1=bootout param2=$SERVICE terminal=false refresh=true"
  ;;
off)
  echo "Awake: OFF — Mac can idle-sleep | color=#cc241d"
  echo "Turn on | bash=$LAUNCHCTL param1=bootstrap param2=gui/${UID_NUM} param3=$PLIST terminal=false refresh=true"
  ;;
esac

echo "---"
echo "Refresh | refresh=true"
