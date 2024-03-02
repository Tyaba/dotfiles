execute "download asdf" do
    command "git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.14.0"
    not_if 'ls ~/.asdf'
end

# asdfコマンドをPATHに追加
unless ENV['PATH'].include?("#{ENV['HOME']}/.asdf/bin:")
    MItamae.logger.info('Prepending ~/.asdf/bin to PATH during this execution')
    ENV['PATH'] = "#{ENV['HOME']}/.asdf/bin:#{ENV['PATH']}"
end
# python, terraform, nodejsなどasdfで入れたものをPATHに追加
unless ENV['PATH'].include?("#{ENV['HOME']}/.asdf/shims")
    MItamae.logger.info("Prepending #{ENV['HOME']}/.asdf/shims to PATH during this execution")
    ENV['PATH'] = "#{ENV['HOME']}/.asdf/shims:#{ENV['PATH']}"
end

# Python
execute "install asdf python plugin" do
    command "asdf plugin add python"
    not_if "asdf list | grep python"
end

python_version = "3.10.13"
execute "asdf install python" do
    command "asdf install python #{python_version} && asdf global python #{python_version}"
    not_if "asdf current python"
end

# for python
case node[:platform]
when 'ubuntu', 'debian'
    package 'build-essential'
    package 'libssl-dev'
    package 'zlib1g-dev'
    package 'libbz2-dev'
    package 'libreadline-dev'
    package 'libsqlite3-dev'
    package 'libncursesw5-dev'
    package 'xz-utils'
    package 'tk-dev'
    package 'libxml2-dev'
    package 'libxmlsec1-dev'
    package 'libffi-dev'
    package 'liblzma-dev'
    package 'python3-distutils'
end

# terraform
execute "asdf install terraform plugin" do
    command "asdf plugin add terraform"
    not_if "asdf list | grep terraform"
end

terraform_version = "latest"
execute "asdf install terraform" do
    command "asdf install terraform #{terraform_version} && asdf global terraform #{terraform_version}"
    not_if "asdf current terraform"
end

# node
execute "asdf install nodejs plugin" do
    command "asdf plugin add nodejs"
    not_if "asdf list | grep nodejs"
end

node_version = "latest"
execute "asdf install nodejs" do
    command "asdf install nodejs #{node_version} && asdf global nodejs #{node_version}"
    not_if "asdf current nodejs"
end

# tflint
case node[:platform]
when 'darwin'
  package 'tflint'
else
  execute 'curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash' do
    not_if 'which tflint'
  end
end

# kubectl
execute "install kubectl plugin into asdf" do
    command "asdf plugin-add kubectl https://github.com/asdf-community/asdf-kubectl.git"
    not_if "asdf plugin list | grep kubectl"
end

execute "install kubectl" do
    command "asdf install kubectl latest && asdf global kubectl $(asdf list kubectl | tail -n 1)"
    not_if "which kubectl"
end