#!/usr/bin/env bash
set -euo pipefail

gcloud=${YUI_PROXY_GCLOUD:-gcloud}
port=${YUI_PROXY_PORT:-52981}
retry_interval=${YUI_PROXY_RETRY_INTERVAL:-60}
platform=$(uname)
stamp="${TMPDIR:-/tmp}/yui-proxy-auth-notified"
work_dir=$(mktemp -d "${TMPDIR:-/tmp}/yui-proxy.XXXXXX")
child_pid=''
stdout_pid=''
stderr_pid=''
sleep_pid=''

cleanup() {
  local pid
  for pid in "$child_pid" "$stdout_pid" "$stderr_pid" "$sleep_pid"; do
    if [[ -n $pid ]]; then kill -TERM "$pid" 2>/dev/null || true; fi
  done
  for pid in "$child_pid" "$stdout_pid" "$stderr_pid" "$sleep_pid"; do
    if [[ -n $pid ]]; then wait "$pid" 2>/dev/null || true; fi
  done
  rm -rf "$work_dir"
}
trap cleanup EXIT
trap 'exit 143' TERM
trap 'exit 130' INT

notify_auth() {
  touch "$work_dir/auth-error"
  # Both stream readers can detect the same failure concurrently. Only the
  # first reader per attempt checks the persistent notification timestamp.
  if ! mkdir "$work_dir/notifying" 2>/dev/null; then return; fi
  if [[ -f $stamp ]] && [[ -n $(find "$stamp" -mmin -30 -print) ]]; then return; fi
  touch "$stamp"
  if [[ $platform == Darwin ]]; then
    osascript -e 'display notification "gcloud の再認証が必要です。yui-login を実行してください" with title "yui"' || true
  elif command -v notify-send >/dev/null 2>&1; then
    notify-send 'yui' 'gcloud の再認証が必要です。yui-login を実行してください' || true
  else
    echo '[yui-proxy] gcloud の再認証が必要です。yui-login を実行してください' >&2
  fi
}

monitor() {
  local line complete
  while true; do
    complete=0
    IFS= read -r line && complete=1
    if (( complete )); then
      printf '%s\n' "$line"
    elif [[ -n $line ]]; then
      printf '%s' "$line"
    else
      break
    fi
    case "$line" in
      *'Reauthentication failed'*|*'gcloud auth login'*) notify_auth ;;
    esac
    if (( ! complete )); then break; fi
  done
}

mkfifo "$work_dir/stdout" "$work_dir/stderr"
while true; do
  monitor < "$work_dir/stdout" &
  stdout_pid=$!
  monitor < "$work_dir/stderr" >&2 &
  stderr_pid=$!
  "$gcloud" run services proxy yui-backend --region=asia-northeast1 "--port=$port" \
    > "$work_dir/stdout" 2> "$work_dir/stderr" &
  child_pid=$!
  result=0
  wait "$child_pid" || result=$?
  child_pid=''
  # Drain both streams before inspecting the marker, including the final line
  # emitted immediately before gcloud exits.
  wait "$stdout_pid"
  stdout_pid=''
  wait "$stderr_pid"
  stderr_pid=''
  if [[ ! -f $work_dir/auth-error ]]; then exit "$result"; fi

  sleep "$retry_interval" &
  sleep_pid=$!
  wait "$sleep_pid"
  sleep_pid=''
  rm -f "$work_dir/auth-error"
  rmdir "$work_dir/notifying"
done
