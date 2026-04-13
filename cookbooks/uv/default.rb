# uvをinstall
execute "install uv" do
    command "curl -LsSf https://astral.sh/uv/install.sh | sh"
    not_if 'which uv'
end
