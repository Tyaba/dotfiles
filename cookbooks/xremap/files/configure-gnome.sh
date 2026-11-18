#!/usr/bin/env bash
# Enables the xremap GNOME extension and user service. Safe to run repeatedly.
set -euo pipefail

extension_uuid=$1

runtime_dir=/run/user/$(id -u)
if [ ! -S "$runtime_dir/bus" ]; then
  echo "[dotfiles/xremap] WARNING: no user session bus. Log in to GNOME and re-run ./install.sh." >&2
  exit 0
fi
export XDG_RUNTIME_DIR=$runtime_dir
export DBUS_SESSION_BUS_ADDRESS=unix:path=$runtime_dir/bus

current=$(gsettings get org.gnome.shell enabled-extensions)
case "$current" in
  *"'$extension_uuid'"*) ;;
  "@as []" | "[]") gsettings set org.gnome.shell enabled-extensions "['$extension_uuid']" ;;
  *) gsettings set org.gnome.shell enabled-extensions "${current%]}, '$extension_uuid']" ;;
esac

# The service starts at the next login, when the input group and extension apply.
systemctl --user daemon-reload
systemctl --user enable xremap.service
