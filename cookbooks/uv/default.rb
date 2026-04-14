# uvをinstall
execute "install uv" do
    command "curl -LsSf https://astral.sh/uv/install.sh | INSTALLER_NO_MODIFY_PATH=1 sh"
    not_if 'which uv'
end
