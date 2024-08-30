# poetryをinstall
execute "install uv" do
    command "pipx install uv"
    not_if 'which uv'
end
