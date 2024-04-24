cargo 'mise'

# Python
python_version = "3.11.7"
execute "install python with mise" do
    command "mise install python@#{python_version} && mise use --global python@#{python_version}"
    not_if "mise ls | grep python"
end

# terraform
terraform_version = "latest"
execute "install terraform with mise" do
    command "mise install terraform@#{terraform_version} && mise use --global terraform@#{terraform_version}"
    not_if "mise ls | grep terraform"
end

# kubectl
execute "install mise kubectl plugin" do
    command "mise plugin install kubectl https://github.com/asdf-community/asdf-kubectl.git"
    not_if "mise plugin | grep kubectl"
end
kubectl_version = "latest"
execute "install kubectl with mise" do
    command "mise install kubectl@#{kubectl_version} && mise use --global kubectl@#{kubectl_version}"
    not_if "mise ls | grep kubectl"
end

# node
node_version = "latest"
execute "install node with mise" do
    command "mise install node@#{node_version} && mise use --global node@#{node_version}"
    not_if "mise ls | grep node"
end

# pnpm
execute "install mise pnpm plugin" do
    command "mise plugin install pnpm https://github.com/jonathanmorley/asdf-pnpm.git"
    not_if "mise plugin | grep pnpm"
end
pnpm_version = "latest"
execute "install pnpm with mise" do
    command "mise install pnpm@#{pnpm_version} && mise use --global pnpm@#{pnpm_version}"
    not_if "mise ls | grep pnpm"
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