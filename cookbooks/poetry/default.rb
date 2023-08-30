case node[:platform]
when 'darwin'
  execute 'curl -sSL https://install.python-poetry.org | python3 -' do
    not_if 'which poetry'
  end
when 'ubuntu'
  execute 'curl -sSL https://install.python-poetry.org | python3 -' do
    not_if 'which poetry'
  end
else
  raise NotImplementedError
end

# この実行中のみ、PATHに~/.poetry/binを追加する
unless ENV['PATH'].include?("#{ENV['HOME']}/.poetry/bin:")
  MItamae.logger.info('Prepending ~/.poetry/bin to PATH during this execution')
  ENV['PATH'] = "#{ENV['HOME']}/.poetry/bin:#{ENV['PATH']}"
end

case node[:platform]
# 補完を有効にする
when 'darwin'
  execute 'poetry completions zsh > $(brew --prefix)/share/zsh/site-functions/_poetry' do
    not_if 'test -f $(brew --prefix)/share/zsh/site-functions/_poetry'
  end
when 'ubuntu'
  execute 'mkdir ~/.zfunc && $HOME/.local/bin/poetry completions zsh > ~/.zfunc/_poetry' do
    not_if 'test -f ~/.zfunc/_poetry'
  end
end

execute '$HOME/.local/bin/poetry config virtualenvs.in-project true' do
  not_if '$HOME/.local/bin/poetry config virtualenvs.in-project | grep true'
end
