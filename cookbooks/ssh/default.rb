# Deploy SSH client config fragments under ~/.ssh/config.d/ and wire them in
# via a single `Include` line at the top of ~/.ssh/config.
#
# ~/.ssh/config itself is intentionally NOT symlinked or templated: it holds
# host-specific entries and gcloud `config-ssh`-generated blocks that must stay
# local (and may differ per machine). We own only the portable fragments and
# the Include line; everything else in ~/.ssh/config is left untouched.
#
# Included by the real-machine roles (darwin / ubuntu / debian), NOT by the
# devcontainer role: in a devcontainer ~/.ssh is a readonly bind mount of the
# host, so writing here would fail and is unnecessary — the container reads the
# host-generated config (which already Includes these fragments) directly.

dotfile '.ssh/config.d/00-base.config'

dotfile '.ssh/config.d/10-darwin.config' if node[:platform] == 'darwin'

# Idempotently ensure ~/.ssh/config pulls in the fragments. The Include is
# prepended so the fragment defaults (notably IgnoreUnknown) are parsed before
# any pre-existing inline options.
execute 'ensure ~/.ssh/config Includes config.d fragments' do
  command <<~SH
    set -eu
    ssh_dir="$HOME/.ssh"
    config="$ssh_dir/config"
    line='Include ~/.ssh/config.d/*.config'
    mkdir -p "$ssh_dir"
    chmod 700 "$ssh_dir"
    if [ ! -e "$config" ]; then
      printf '%s\n' "$line" > "$config"
      chmod 600 "$config"
    elif ! grep -qxF "$line" "$config"; then
      tmp="$(mktemp)"
      { printf '%s\n\n' "$line"; cat "$config"; } > "$tmp"
      cat "$tmp" > "$config"
      rm -f "$tmp"
    fi
  SH
  user node[:user] if node[:user]
end
