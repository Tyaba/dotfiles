cargo 'mise'

# Python
python_minor_version = "3.11"
python_version = "3.11.7"
execute "install python with mise" do
    command <<-EOF
    mise install python@#{python_version}
    mise use --global python@#{python_version}
    EOF
    not_if "mise ls | grep python"
end

# pythonをPATHに追加
unless ENV['PATH'].include?("#{ENV['HOME']}/.local/share/mise/installs/python/#{python_minor_version}/bin")
    MItamae.logger.info("Prepending #{ENV['HOME']}/.local/share/mise/installs/python/#{python_minor_version}/bin to PATH during this execution")
    ENV['PATH'] = "#{ENV['HOME']}/.local/share/mise/installs/python/#{python_minor_version}/bin:#{ENV['PATH']}"
end

# terraform
terraform_version = "latest"
execute "install terraform with mise" do
    command <<-EOF
        mise install terraform@#{terraform_version}
        mise use --global terraform@#{terraform_version}
    EOF
    not_if "mise ls | grep terraform"
end

kubectl_version = "latest"
execute "install kubectl with mise" do
    command <<-EOF
        mise plugin install kubectl https://github.com/asdf-community/asdf-kubectl.git
        mise install kubectl@#{kubectl_version}
        mise use --global kubectl@#{kubectl_version}
    EOF
    not_if "mise ls | grep kubectl"
end

# node
node_version = "latest"
execute "install node with mise" do
    command <<-EOF
        mise install node@#{node_version}
        mise use --global node@#{node_version}
    EOF
    not_if "mise ls | grep node"
end

# pnpm
execute "install mise pnpm plugin" do
    command ""
    not_if "mise plugin | grep pnpm"
end
pnpm_version = "latest"
execute "install pnpm with mise" do
    command <<-EOF
        mise plugin install pnpm https://github.com/jonathanmorley/asdf-pnpm.git
        mise install pnpm@#{pnpm_version}
        mise use --global pnpm@#{pnpm_version}
    EOF
    not_if "mise ls | grep pnpm"
end

# go
execute "install go with mise" do
    command <<-EOF
        mise install go@latest
        mise use --global go@latest
    EOF
    not_if "mise ls | grep go"
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

# flutter if darwin
case node[:platform]
when 'darwin'
    execute "install flutter with mise" do
        command "mise install flutter@latest"
        not_if "mise ls | grep flutter"
    end
end