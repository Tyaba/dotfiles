# JetBrainsMono Nerd Font, referenced by config/.config/ghostty/config.
# Installed per user because only the login user's terminal needs it.
font_version = 'v3.5.1'
font_sha256 = '04d5e8f903693f9dd13e16f867e994834e681eb3c72c0d337a770dcda09010cf'
font_url = "https://github.com/ryanoasis/nerd-fonts/releases/download/#{font_version}/JetBrainsMono.tar.xz"
font_dir = "#{ENV['HOME']}/.local/share/fonts/JetBrainsMonoNerdFont"

execute 'install JetBrainsMono Nerd Font' do
  command <<~SH
    set -eu
    work_dir=$(mktemp -d)
    trap 'rm -rf "$work_dir"' EXIT
    curl -fsSL -o "$work_dir/font.tar.xz" #{font_url}
    echo "#{font_sha256}  $work_dir/font.tar.xz" | sha256sum -c -
    rm -rf "#{font_dir}"
    mkdir -p "#{font_dir}"
    tar -xJf "$work_dir/font.tar.xz" -C "#{font_dir}"
    echo "#{font_version}" > "#{font_dir}/.version"
    fc-cache -f "#{font_dir}"
  SH
  user node[:user] if node[:user]
  not_if %Q[grep -qxF #{font_version} "#{font_dir}/.version"]
end
