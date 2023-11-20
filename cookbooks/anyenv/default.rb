git "install anyenv" do
  not_if 'which anyenv'
  repository "https://github.com/anyenv/anyenv.git"
  destination "#{ENV['HOME']}/.anyenv"
end

git "install anyenv-update" do
  dest = "#{ENV['HOME']}/.anyenv/plugins/anyenv-update"
  not_if "test -d #{dest}"
  repository "https://github.com/znz/anyenv-update.git"
  destination dest
end

git "install anyenv-git" do
  dest = "#{ENV['HOME']}/.anyenv/plugins/anyenv-git"
  not_if "test -d #{dest}"
  repository "https://github.com/znz/anyenv-git.git"
  destination dest
end

# ~/.anyenvをPATHに追加
unless ENV['PATH'].include?("#{ENV['HOME']}/.anyenv/bin:")
  MItamae.logger.info('Prepending ~/.anyenv/bin to PATH during this execution')
  ENV['PATH'] = "#{ENV['HOME']}/.anyenv/bin:#{ENV['PATH']}"
end

execute "anyenv install --force-init --force" do
  not_if "test -d #{ENV['HOME']}/.config/anyenv/anyenv-install"
end

# Python
execute "anyenv install -f pyenv" do
  not_if "which pyenv"
end

# ~/.anyenv/envs/pyenv/binをPATHに追加
unless ENV['PATH'].include?("#{ENV['HOME']}/.anyenv/envs/pyenv/bin:")
  MItamae.logger.info('Prepending ~/.anyenv/envs/pyenv/bin to PATH during this execution')
  ENV['PATH'] = "#{ENV['HOME']}/.anyenv/envs/pyenv/bin:#{ENV['PATH']}"
end
# pythonをPATHに追加
unless ENV['PATH'].include?("#{ENV['PYENV_ROOT']}/shims")
  MItamae.logger.info("Prepending #{ENV['PYENV_ROOT']}/shims to PATH during this execution")
  ENV['PATH'] = "#{ENV['PYENV_ROOT']}/shims:#{ENV['PATH']}"
end

# pyenvに必要なパッケージのインストール
# ref. https://github.com/pyenv/pyenv/wiki#suggested-build-environment
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

python_version = "3.10"
execute "pyenv install #{python_version} && pyenv global #{python_version}" do
  not_if "pyenv versions | grep #{python_version}"
end

# FIX ME:
# zshrcをsourceできないので、pyenv initを手動実行する必要あり

# terraform
execute "anyenv install -f tfenv" do
  not_if "which tfenv"
end

# ~/.anyenv/envs/tfenv/binをPATHに追加
unless ENV['PATH'].include?("#{ENV['HOME']}/.anyenv/envs/tfenv/bin:")
  MItamae.logger.info('Prepending ~/.tfenv/bin to PATH during this execution')
  ENV['PATH'] = "#{ENV['HOME']}/.anyenv/envs/tfenv/bin:#{ENV['PATH']}"
end
terraform_version = "1.5.6"
execute "tfenv install #{terraform_version}"do
  not_if "tfenv list | grep #{terraform_version}"
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

# ~/.anyenvをユーザーの所有にする
case node[:platform]
when 'ubuntu', 'debian'
  execute "sudo chown -R #{node[:user]} ~/.anyenv" do
    not_if "ls -l ~/.anyenv | awk '{print $3}' | grep $(whoami)"
  end
end
