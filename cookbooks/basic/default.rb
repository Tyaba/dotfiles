# locale-gen
case node[:platform]
when 'ubuntu'
  execute 'sudo locale-gen en_US.UTF-8' do
    not_if "locale | grep en_US.UTF-8"
  end
end

# libffi-devel
case node[:platform]
when 'darwin'
  execute 'brew install libffi-dev' do
    not_if "brew list | grep libffi-dev"
  end
when 'ubuntu'
  execute 'sudo apt install libffi-dev' do
    not_if "dpkg -l | grep '^ii' | grep libffi-dev"
  end
end

# zlib1g-dev
case node[:platform]
when 'darwin'
  execute 'brew install zlib1g-dev' do
    not_if "brew list | grep zlib1g-dev"
  end
when 'ubuntu'
  execute 'sudo apt install zlib1g-dev' do
    not_if "dpkg -l | grep '^ii' | grep zlib1g-dev"
  end
end

# curl
case node[:platform]
when 'darwin'
  execute 'brew install curl' do
    not_if "which curl"
  end
when 'ubuntu'
  execute 'sudo apt install -y curl' do
    not_if 'which curl'
  end
end

# openssh-client
case node[:platform]
when 'darwin'
  execute 'brew install openssh-client' do
    not_if "brew list | grep openssh-client"
  end
when 'ubuntu'
  execute 'sudo apt install -y openssh-client' do
    not_if "dpkg -l | grep '^ii' | grep openssh-client"
  end
end

# build-essential (gcc, g++, make, etc.)
case node[:platform]
when 'darwin'
  execute 'brew install build-essential' do
    not_if "brew list | grep build-essential"
  end
when 'ubuntu'
  execute 'sudo apt install -y build-essential' do
    not_if "dpkg -l | grep '^ii' | grep build-essential"
  end
end