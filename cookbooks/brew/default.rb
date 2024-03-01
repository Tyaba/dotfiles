case node[:platform]
when 'darwin'
  unless ENV['PATH'].include?("/opt/homebrew/bin")
    MItamae.logger.info('Prepending /opt/homebrew/bin to PATH during this execution')
    ENV['PATH'] = "/opt/homebrew/bin:#{ENV['PATH']}"
  end
  execute 'install brew' do
    command 'NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
    not_if 'which brew'
  end
  execute 'brew update' do
    command 'brew update'
  end
else
  raise NotImplementedError
end
