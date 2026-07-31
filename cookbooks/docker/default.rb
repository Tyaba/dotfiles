docker_compose_version = '2.29.2'
docker_compose_path = "#{ENV['HOME']}/.docker/cli-plugins/docker-compose"
package 'ca-certificates'
package 'curl'
package 'gnupg'

case node[:platform]
when 'darwin'
  # Docker CLI stack via brew formula (not cask). The Docker daemon itself is
  # provided by colima (see cookbooks/colima). Docker Desktop is NOT installed
  # by this recipe; users switching from Docker Desktop should uninstall it
  # after verifying colima works. If Docker Desktop is managed by Homebrew, the
  # cask token is `docker-desktop` (`brew uninstall --cask docker-desktop`).
  # Otherwise, run `/Applications/Docker.app/Contents/MacOS/uninstall`; it may
  # stop with a TCC-protected container metadata error after the important
  # cleanup has completed. Run `rm -rf /Applications/Docker.app` separately
  # afterwards (no sudo required for a user-owned app), not chained with `&&`.
  execute 'brew install docker' do
    command 'brew install docker'
    not_if 'brew list docker >/dev/null 2>&1'
  end
  execute 'brew install docker-compose' do
    command 'brew install docker-compose'
    not_if 'brew list docker-compose >/dev/null 2>&1'
  end
  execute 'brew install docker-buildx' do
    command 'brew install docker-buildx'
    not_if 'brew list docker-buildx >/dev/null 2>&1'
  end
  execute 'brew install docker-credential-helper' do
    command 'brew install docker-credential-helper'
    not_if 'brew list docker-credential-helper >/dev/null 2>&1'
  end
  # Homebrew installs Docker CLI plugins outside the default Docker CLI plugin
  # search paths. Register the brew plugin directory while preserving existing
  # Docker Desktop and docker login settings in config.json.
  execute 'configure docker cli plugins and credentials' do
    command <<-EOF
set -eu
mkdir -p "$HOME/.docker"
plugin_dir="$(brew --prefix)/lib/docker/cli-plugins"
config_path="$HOME/.docker/config.json"
export DOCKER_CLI_PLUGIN_DIR="$plugin_dir"
export DOCKER_CONFIG_PATH="$config_path"
python3 <<'PY'
import json
import os
from pathlib import Path

path = Path(os.environ["DOCKER_CONFIG_PATH"])
plugin_dir = os.environ["DOCKER_CLI_PLUGIN_DIR"]

if path.exists():
    with path.open() as f:
        data = json.load(f)
else:
    data = {}

if not isinstance(data, dict):
    raise SystemExit(f"{path} must contain a JSON object")

dirs = data.get("cliPluginsExtraDirs")
if not isinstance(dirs, list):
    dirs = []

if plugin_dir not in dirs:
    dirs.append(plugin_dir)

data["cliPluginsExtraDirs"] = dirs
data["credsStore"] = "osxkeychain"

tmp_path = path.with_name(path.name + ".tmp")
with tmp_path.open("w") as f:
    json.dump(data, f, indent=2)
    f.write("\\n")

tmp_path.replace(path)
PY
    EOF
    not_if <<-EOF
plugin_dir="$(brew --prefix)/lib/docker/cli-plugins"
config_path="$HOME/.docker/config.json"
test -f "$config_path" && DOCKER_CLI_PLUGIN_DIR="$plugin_dir" DOCKER_CONFIG_PATH="$config_path" python3 <<'PY'
import json
import os
import sys
from pathlib import Path

path = Path(os.environ["DOCKER_CONFIG_PATH"])
plugin_dir = os.environ["DOCKER_CLI_PLUGIN_DIR"]

try:
    with path.open() as f:
        data = json.load(f)
except (OSError, json.JSONDecodeError):
    sys.exit(1)

dirs = data.get("cliPluginsExtraDirs")
if (
    isinstance(data, dict)
    and isinstance(dirs, list)
    and plugin_dir in dirs
    and data.get("credsStore") == "osxkeychain"
):
    sys.exit(0)

sys.exit(1)
PY
    EOF
  end
  execute 'remove dangling docker cli plugin symlinks' do
    command 'find "$HOME/.docker/cli-plugins" -type l ! -exec test -e {} \; -exec rm -f {} +'
    only_if '! test -d /Applications/Docker.app'
    not_if 'test ! -d "$HOME/.docker/cli-plugins" || ! find "$HOME/.docker/cli-plugins" -type l ! -exec test -e {} \; -print -quit | grep -q .'
  end
  # Warn if Docker Desktop is still installed - remind user to uninstall it
  # once colima has been verified working. Not auto-uninstalled to avoid
  # surprising users mid-session.
  execute 'warn about lingering Docker Desktop' do
    command <<-EOF
      if brew list --cask docker-desktop >/dev/null 2>&1; then
        echo "[dotfiles/docker] WARNING: Docker Desktop (/Applications/Docker.app) is still installed. After verifying colima works, run: brew uninstall --cask docker-desktop. Re-run this recipe after uninstalling Docker Desktop to remove stale ~/.docker/cli-plugins symlinks automatically." >&2
      else
        echo "[dotfiles/docker] WARNING: Docker Desktop (/Applications/Docker.app) is still installed outside Homebrew cask management. After verifying colima works, run these commands separately:" >&2
        echo "  /Applications/Docker.app/Contents/MacOS/uninstall" >&2
        echo "  rm -rf /Applications/Docker.app" >&2
        echo "Re-run this recipe after uninstalling Docker Desktop to remove stale ~/.docker/cli-plugins symlinks automatically." >&2
      fi
      EOF
    only_if 'test -d /Applications/Docker.app'
  end
when 'ubuntu', 'debian'
  execute 'sudo mkdir -p /etc/apt/keyrings' do
    not_if 'test -d /etc/apt/keyrings'
  end
  package 'lsb-release'
  execute "install docker" do
    # ref: https://docs.docker.com/engine/install/ubuntu/
    command <<-EOF
      for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do sudo apt-get remove $pkg; done
      sudo apt-get update
      sudo apt-get install ca-certificates curl
      sudo install -m 0755 -d /etc/apt/keyrings
      sudo curl -fsSL https://download.docker.com/linux/#{node[:platform]}/gpg -o /etc/apt/keyrings/docker.asc
      sudo chmod a+r /etc/apt/keyrings/docker.asc
      echo \
      'deb [arch='$(dpkg --print-architecture)' signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/#{node[:platform]} \
      '$(. /etc/os-release && echo #{node[:codename]})' stable' | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
      sudo apt-get update
      sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
      EOF
    not_if 'which docker'
  end
  # ユーザをdockerグループに追加
  execute "sudo gpasswd -a #{node[:user]} docker" do
    not_if "cat /etc/group | grep docker | grep #{node[:user]}"
  end
  # Docker Compose
  execute "mkdir -p #{ENV['HOME']}/.docker/cli-plugins && rm -f #{docker_compose_path} && curl -L https://github.com/docker/compose/releases/download/v#{docker_compose_version}/docker-compose-#{`uname`.downcase.strip}-#{`uname -m`.strip} -o #{docker_compose_path} && sudo chmod +x #{docker_compose_path}" do
    not_if "docker compose version | grep v#{docker_compose_version}"
  end
end
# zsh用の設定
execute '''cat <<EOF >> ~/.zsh/lib/apps

# Docker
export DOCKER_BUILDKIT=1
export COMPOSE_DOCKER_CLI_BUILD=1
EOF
''' do
  not_if 'grep DOCKER_BUILDKIT ~/.zsh/lib/apps'
end

execute '''cat <<EOF >> ~/.zsh/lib/aliases
# Docker
alias d=docker
EOF
''' do
  not_if 'grep "# Docker" ~/.zsh/lib/aliases'
end
