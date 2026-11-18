# Key remapper for GNOME on Wayland. Config: config/.config/xremap/config.yml
xremap_version = '0.15.18'
xremap_sha256 = '5b6ea4cabf81ef80c78a1313e0ded36634c61e6e5969302bf9153ce27e7913f4'
xremap_url = "https://github.com/xremap/xremap/releases/download/v#{xremap_version}/xremap-linux-x86_64-gnome.zip"
xremap_bin = "#{ENV['HOME']}/.local/bin/xremap"

# The extension reports the focused application to xremap.
extension_uuid = 'xremap@k0kubun.com'
extension_commit = '602c74dfd81fc0d4f1e310e87300e05f543127c3'
extension_sha256 = '41f7d86065e3da42279414bec216a551fd1fb1c9990a2c3931327eaab1e2992b'
extension_url = "https://github.com/xremap/xremap-gnome/archive/#{extension_commit}.tar.gz"
extension_dir = "#{ENV['HOME']}/.local/share/gnome-shell/extensions/#{extension_uuid}"

files_dir = File.join(File.dirname(__FILE__), 'files')
login_user = node[:user] || ENV['USER']

package 'unzip'

# xremap reads keyboards through the input group and writes through uinput.
execute "gpasswd -a #{login_user} input" do
  not_if "id -nG #{login_user} | tr ' ' '\\n' | grep -qx input"
end

file '/etc/modules-load.d/uinput.conf' do
  content "uinput\n"
  mode '644'
  owner 'root'
  group 'root'
end

file '/etc/udev/rules.d/99-input.rules' do
  content %(KERNEL=="uinput", GROUP="input", TAG+="uaccess", MODE:="0660", OPTIONS+="static_node=uinput"\n)
  mode '644'
  owner 'root'
  group 'root'
  notifies :run, 'execute[reload uinput udev rule]', :immediately
end

execute 'reload uinput udev rule' do
  command 'modprobe uinput && udevadm control --reload-rules && udevadm trigger --name-match=uinput'
  action :nothing
end

execute 'install xremap' do
  command <<~SH
    set -eu
    work_dir=$(mktemp -d)
    trap 'rm -rf "$work_dir"' EXIT
    curl -fsSL -o "$work_dir/xremap.zip" #{xremap_url}
    echo "#{xremap_sha256}  $work_dir/xremap.zip" | sha256sum -c -
    unzip -q "$work_dir/xremap.zip" -d "$work_dir/bin"
    mkdir -p "$(dirname "#{xremap_bin}")"
    install -m 0755 "$work_dir/bin/xremap" "#{xremap_bin}"
  SH
  user node[:user] if node[:user]
  not_if %Q["#{xremap_bin}" --version | grep -qF #{xremap_version}]
end

execute 'install xremap gnome extension' do
  command <<~SH
    set -eu
    work_dir=$(mktemp -d)
    trap 'rm -rf "$work_dir"' EXIT
    curl -fsSL -o "$work_dir/extension.tar.gz" #{extension_url}
    echo "#{extension_sha256}  $work_dir/extension.tar.gz" | sha256sum -c -
    rm -rf "#{extension_dir}"
    mkdir -p "#{extension_dir}"
    tar -xzf "$work_dir/extension.tar.gz" -C "#{extension_dir}" --strip-components=1
    echo "#{extension_commit}" > "#{extension_dir}/.commit"
  SH
  user node[:user] if node[:user]
  not_if %Q[grep -qxF #{extension_commit} "#{extension_dir}/.commit"]
end

dotfile '.config/xremap/config.yml'

execute 'install xremap user service' do
  command %Q[install -D -m 0644 "#{files_dir}/xremap.service" "#{ENV['HOME']}/.config/systemd/user/xremap.service"]
  user node[:user] if node[:user]
  not_if %Q[cmp -s "#{files_dir}/xremap.service" "#{ENV['HOME']}/.config/systemd/user/xremap.service"]
end

execute 'configure xremap gnome session' do
  command %Q[bash "#{files_dir}/configure-gnome.sh" "#{extension_uuid}"]
  user node[:user] if node[:user]
end
