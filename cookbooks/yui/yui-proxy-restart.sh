#!/usr/bin/env bash
set -euo pipefail

action=${1:-restart}
case "$action" in
  restart) echo '[yui-proxy] restarting proxy with new credentials...' ;;
  stop) echo '[yui-proxy] stopping proxy (auth revoked)' ;;
  *) echo "[yui-proxy] usage: yui-proxy-restart [restart|stop]" >&2; exit 2 ;;
esac

if [[ $(uname) == Darwin ]]; then
  plist="$HOME/Library/LaunchAgents/com.tepein.yui-proxy.plist"
  if [[ $action == stop ]]; then
    launchctl unload "$plist" 2>/dev/null || true
  else
    launchctl kickstart -k "gui/$(id -u)/com.tepein.yui-proxy" || launchctl load "$plist"
  fi
else
  systemctl --user "$action" yui-proxy
fi
