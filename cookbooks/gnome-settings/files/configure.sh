#!/usr/bin/env bash
# Applies GNOME preferences and shortcuts. Safe to run repeatedly.
set -euo pipefail

runtime_dir=/run/user/$(id -u)
if [ ! -S "$runtime_dir/bus" ]; then
  echo "[dotfiles/gnome-settings] WARNING: no user session bus. Log in to GNOME and re-run ./install.sh." >&2
  exit 0
fi
export XDG_RUNTIME_DIR=$runtime_dir
export DBUS_SESSION_BUS_ADDRESS=unix:path=$runtime_dir/bus

# Removes a string from a gsettings string array, keeping the other entries.
remove_from_list() {
  local schema=$1 key=$2 value=$3 current updated
  current=$(gsettings get "$schema" "$key")
  updated=$(printf '%s' "$current" | sed -e "s/'$value', //" -e "s/, '$value'//" -e "s/'$value'//")
  if [ "$updated" != "$current" ]; then
    gsettings set "$schema" "$key" "$updated"
  fi
}

# Sets a key only when its schema is installed.
set_if_available() {
  local schema=$1 key=$2 value=$3
  if gsettings writable "$schema" "$key" >/dev/null 2>&1; then
    gsettings set "$schema" "$key" "$value"
  fi
}

# Ghostty uses Super+D for a right split. Show Desktop keeps its other shortcuts.
remove_from_list org.gnome.desktop.wm.keybindings show-desktop '<Super>d'

# Ghostty uses Super+Alt+Left/Right to move between splits.
# Workspace switching keeps Ctrl+Alt+Left/Right and Super+Page Up/Down.
remove_from_list org.gnome.desktop.wm.keybindings switch-to-workspace-left '<Super><Alt>Left'
remove_from_list org.gnome.desktop.wm.keybindings switch-to-workspace-right '<Super><Alt>Right'

# Show hidden files in the file manager and file dialogs.
set_if_available org.gnome.nautilus.preferences show-hidden-files true
set_if_available org.gtk.gtk4.Settings.FileChooser show-hidden true
set_if_available org.gtk.Settings.FileChooser show-hidden true

# Turn the screen off after one hour of inactivity.
gsettings set org.gnome.desktop.session idle-delay 'uint32 3600'
