#!/usr/bin/env bash
# Binds Super+Space to the Vicinae launcher in the current user's GNOME session.
# Safe to run repeatedly. Existing shortcuts and extensions are preserved.
set -euo pipefail

vicinae_bin=$1
extension_uuid=$2

binding='<Super>space'
media_keys=org.gnome.settings-daemon.plugins.media-keys
keybinding_path=/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/vicinae/
keybinding_schema="$media_keys.custom-keybinding:$keybinding_path"

runtime_dir=/run/user/$(id -u)
if [ ! -S "$runtime_dir/bus" ]; then
  echo "[dotfiles/vicinae] WARNING: no user session bus. Log in to GNOME and re-run ./install.sh to bind Super+Space." >&2
  exit 0
fi
export XDG_RUNTIME_DIR=$runtime_dir
export DBUS_SESSION_BUS_ADDRESS=unix:path=$runtime_dir/bus

# Appends a string to a gsettings string array unless it is already present.
append_to_list() {
  local schema=$1 key=$2 value=$3 current
  current=$(gsettings get "$schema" "$key")
  case "$current" in
    *"'$value'"*) return 0 ;;
    '@as []' | '[]') gsettings set "$schema" "$key" "['$value']" ;;
    *) gsettings set "$schema" "$key" "${current%]}, '$value']" ;;
  esac
}

# Removes a string from a gsettings string array, keeping the other entries.
remove_from_list() {
  local schema=$1 key=$2 value=$3 current updated
  current=$(gsettings get "$schema" "$key")
  updated=$(printf '%s' "$current" | sed -e "s/'$value', //" -e "s/, '$value'//" -e "s/'$value'//")
  if [ "$updated" != "$current" ]; then
    gsettings set "$schema" "$key" "$updated"
  fi
}

# GNOME assigns Super+Space to input source switching by default.
remove_from_list org.gnome.desktop.wm.keybindings switch-input-source "$binding"

append_to_list "$media_keys" custom-keybindings "$keybinding_path"
gsettings set "$keybinding_schema" name 'Vicinae'
gsettings set "$keybinding_schema" command "$vicinae_bin toggle"
gsettings set "$keybinding_schema" binding "$binding"

# GNOME Shell loads a newly installed extension at the next login.
append_to_list org.gnome.shell enabled-extensions "$extension_uuid"

systemctl --user daemon-reload
systemctl --user enable vicinae.service
systemctl --user start vicinae.service ||
  echo "[dotfiles/vicinae] WARNING: vicinae.service did not start. Check: journalctl --user -u vicinae" >&2
