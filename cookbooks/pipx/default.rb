execute "install pipx" do
  command "python -m pip install --user --upgrade pipx"
  not_if 'which pipx'
end


