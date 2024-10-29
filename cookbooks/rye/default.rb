# PATHに~/.rye/shimsを追加する rye用
unless ENV['PATH'].include?("#{ENV['HOME']}/.rye/shims")
    MItamae.logger.info('Prepending ~/.rye/shims to PATH during this execution')
    ENV['PATH'] = "#{ENV['HOME']}/.rye/shims:#{ENV['PATH']}"
  end

execute "install rye" do
    command 'curl -sSf https://rye.astral.sh/get | RYE_INSTALL_OPTION="--yes" bash'
    not_if 'which rye'
end

execute "rye completion" do
    command "rye self completion -s zsh > ~/.zfunc/_rye"
    not_if 'test -f ~/.zfunc/_rye'
end