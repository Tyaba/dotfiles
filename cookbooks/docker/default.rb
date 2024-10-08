docker_compose_version = '2.29.2'
docker_compose_path = "#{ENV['HOME']}/.docker/cli-plugins/docker-compose"
package 'ca-certificates'
package 'curl'
package 'gnupg'

case node[:platform]
when 'darwin'
  execute 'brew install docker-slim' do
    not_if 'which slim'
  end
  case `uname -m`.chomp
  when 'x86_64'  # Intel Mac
    execute 'brew install --cask docker' do
      not_if 'which docker'
    end
  when 'arm64'  # M1 Mac
    execute 'brew install lima' do
      not_if 'which lima'
    end
    package 'qemu' do
      not_if 'which qemu-system-aarch64'
    end
    execute 'brew install docker' do
      not_if 'which docker'
    end
    execute "mkdir -p #{ENV['HOME']}/.docker/cli-plugins && rm -f #{docker_compose_path} && curl -L https://github.com/docker/compose/releases/download/v#{docker_compose_version}/docker-compose-darwin-aarch64 -o #{docker_compose_path} && sudo chmod +x #{docker_compose_path}" do
      not_if "docker compose version | grep v#{docker_compose_version}"
    end
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

# Kubernetes
source <(kubectl completion zsh)
alias k=kubectl
complete -o default -F __start_kubectl k
EOF
''' do
  not_if 'grep kubectl ~/.zsh/lib/aliases'
end

execute '''cat <<EOF >> ~/.zsh/lib/aliases
# Docker
alias d=docker
EOF
''' do
  not_if 'grep "# Docker" ~/.zsh/lib/aliases'
end
