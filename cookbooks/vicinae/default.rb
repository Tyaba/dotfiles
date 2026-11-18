# Vicinae — Raycast-compatible launcher for Linux (https://vicinae.com)
#
# Raycast has no Linux build, so Ubuntu desktops use Vicinae instead.
# roles/ubuntu includes this cookbook only when gnome-shell is installed.
#
# Everything is installed per user under ~/.local. The upstream installer grants
# cap_dac_override to the input server only when it runs as root; running it as
# the login user avoids that capability, at the cost of snippet expansion and
# paste into other applications.
vicinae_version = '0.30.1'
vicinae_installer_sha256 = '481ed1287e0b79655d81a09e1fd1fddef4cb454461da47d610e52bdc5c9997fd'
vicinae_appimages = {
  'x86_64' => {
    name: 'Vicinae-x86_64.AppImage',
    sha256: '9f573dd04389693a1b70653dd4cc3886a1623fc159d50e207486162e6ae91ab2',
  },
  'aarch64' => {
    name: 'Vicinae-aarch64.AppImage',
    sha256: '1b2290d4c4f5c1ef51358a19d2322c17f489f3dfcf790367a0f1634261abaeea',
  },
}

# The extension provides the floating window that closes on focus loss, which
# GNOME Wayland does not offer to applications through layer shell.
extension_version = '1.8.1'
extension_uuid = 'vicinae@dagimg-dot'
extension_zip = "#{extension_uuid}.shell-extension-v#{extension_version}.zip"
extension_sha256 = '8bac485400dc167effb189f1775f00d083a34b574e61b9c9a4167345cafe829e'
extension_metadata = "#{ENV['HOME']}/.local/share/gnome-shell/extensions/#{extension_uuid}/metadata.json"

arch = run_command('uname -m').stdout.strip
appimage = vicinae_appimages.fetch(arch)
release_url = "https://github.com/vicinaehq/vicinae/releases/download/v#{vicinae_version}"
installer_url = "https://raw.githubusercontent.com/vicinaehq/vicinae/v#{vicinae_version}/scripts/install.sh"
vicinae_bin = "#{ENV['HOME']}/.local/bin/vicinae"
uid = run_command("id -u #{node[:user]}").stdout.strip
session_bus = "/run/user/#{uid}/bus"
session_env = "XDG_RUNTIME_DIR=/run/user/#{uid} DBUS_SESSION_BUS_ADDRESS=unix:path=#{session_bus}"

include_cookbook 'jq'
# vicinae-server links against libOpenGL.so.0, which the AppImage does not bundle.
package 'libopengl0'

execute 'install vicinae' do
  command <<~SH
    set -eu
    work_dir=$(mktemp -d)
    trap 'rm -rf "$work_dir"' EXIT
    curl -fsSL -o "$work_dir/install.sh" #{installer_url}
    curl -fsSL -o "$work_dir/#{appimage[:name]}" #{release_url}/#{appimage[:name]}
    echo "#{vicinae_installer_sha256}  $work_dir/install.sh" | sha256sum -c -
    echo "#{appimage[:sha256]}  $work_dir/#{appimage[:name]}" | sha256sum -c -
    TERM=xterm bash "$work_dir/install.sh" --prefix "$HOME/.local" --appimage "$work_dir/#{appimage[:name]}" </dev/null
  SH
  user node[:user] if node[:user]
  not_if "#{vicinae_bin} version 2>/dev/null | grep -qF #{vicinae_version}"
end

# gnome-extensions and gsettings need the login session, so a run without one
# (for example over SSH before the first login) leaves these steps for later.
execute 'install vicinae gnome extension' do
  command <<~SH
    set -eu
    work_dir=$(mktemp -d)
    trap 'rm -rf "$work_dir"' EXIT
    curl -fsSL -o "$work_dir/extension.zip" https://github.com/vicinaehq/gnome-extension/releases/download/v#{extension_version}/#{extension_zip}
    echo "#{extension_sha256}  $work_dir/extension.zip" | sha256sum -c -
    env #{session_env} gnome-extensions install --force "$work_dir/extension.zip"
  SH
  user node[:user] if node[:user]
  only_if "test -S #{session_bus}"
  not_if %Q[grep -qF '"version-name": "#{extension_version}"' #{extension_metadata}]
end

execute 'configure vicinae gnome session' do
  command "bash #{File.join(File.dirname(__FILE__), 'files', 'configure-gnome.sh')} #{vicinae_bin} #{extension_uuid}"
  user node[:user] if node[:user]
end
