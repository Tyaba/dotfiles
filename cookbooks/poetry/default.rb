# pythonの準備

# PATHに~/.local/binを追加する poetry用
unless ENV['PATH'].include?("#{ENV['HOME']}/.local/bin")
  MItamae.logger.info('Prepending ~/.local/bin to PATH during this execution')
  ENV['PATH'] = "#{ENV['HOME']}/.local/bin:#{ENV['PATH']}"
end

# poetryをinstall
execute "curl -sSL https://install.python-poetry.org | python -" do
  not_if 'which poetry'
end

case node[:platform]
# 補完を有効にする
when 'darwin'
  execute 'poetry completions zsh > $(brew --prefix)/share/zsh/site-functions/_poetry' do
    not_if 'test -f $(brew --prefix)/share/zsh/site-functions/_poetry'
  end
else
  execute 'mkdir ~/.zfunc && poetry completions zsh > ~/.zfunc/_poetry' do
    not_if 'test -f ~/.zfunc/_poetry'
  end
end

execute 'poetry config virtualenvs.in-project true' do
  not_if 'poetry config virtualenvs.in-project | grep true'
end
