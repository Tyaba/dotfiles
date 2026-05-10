execute "install mise via curl" do
    command 'curl -fsSL https://mise.run | sh'
    not_if "test -x #{ENV['HOME']}/.local/bin/mise"
end

# miseで入れたものをPATHに追加
unless ENV['PATH'].include?("#{ENV['HOME']}/.local/share/mise/shims")
    MItamae.logger.info("Prepending ~/.local/share/mise/shims to PATH during this execution")
    ENV['PATH'] = "#{ENV['HOME']}/.local/share/mise/shims:#{ENV['PATH']}"
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
    package 'python3-setuptools'
end

# tflint
case node[:platform]
when 'darwin'
    package 'tflint'
else
    execute 'install tflint' do
        command 'curl -s https://raw.githubusercontent.com/terraform-linters/' +\
        'tflint/master/install_linux.sh | bash'
        not_if 'which tflint'
    end
end

execute "install mise kubectl plugin" do
    command "#{ENV['HOME']}/.local/bin/mise plugin install kubectl https://github.com/asdf-community/asdf-kubectl.git"
    not_if "#{ENV['HOME']}/.local/bin/mise plugin | grep -q kubectl"
end

execute "install mise pnpm plugin" do
    command "#{ENV['HOME']}/.local/bin/mise plugin install pnpm https://github.com/jonathanmorley/asdf-pnpm.git"
    not_if "#{ENV['HOME']}/.local/bin/mise plugin | grep -q pnpm"
end

mise_config_erb = File.expand_path('../../config/mise/config.toml.erb', File.dirname(__FILE__))

directory "#{ENV['HOME']}/.config/mise" do
    user node[:user]
end

execute "rm -f #{ENV['HOME']}/.config/mise/config.toml" do
    only_if "test -L #{ENV['HOME']}/.config/mise/config.toml"
end

template "#{ENV['HOME']}/.config/mise/config.toml" do
    source mise_config_erb
    user node[:user]
    mode '0644'
end

execute "mise install all tools from config" do
    command "#{ENV['HOME']}/.local/bin/mise install"
    user node[:user]
end
