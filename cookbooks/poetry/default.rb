case node[:platform]
when 'darwin'
  execute 'curl -sSL https://raw.githubusercontent.com/python-poetry/poetry/master/install-poetry.py | python -' do
    not_if 'which poetry'
  end
else
  raise NotImplementedError
end

execute 'poetry completions zsh > $(brew --prefix)/share/zsh/site-functions/_poetry' do
  not_if 'test -f $(brew --prefix)/share/zsh/site-functions/_poetry'
end

execute 'poetry config virtualenvs.in-project true' do
  not_if 'test true == $(poetry config virtualenvs.in-project)'
end
