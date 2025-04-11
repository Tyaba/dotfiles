# PATHに/opt/python/3.10/bin/を追加する. Compute Engine用
unless ENV['PATH'].include?("/opt/python/3.10/bin")
  MItamae.logger.info('Prepending /opt/python/3.10/bin to PATH during this execution')
  ENV['PATH'] = "/opt/python/3.10/bin:#{ENV['PATH']}"
end

execute "install pipx" do
  command "python -m pip install --user --upgrade pipx"
  not_if 'which pipx'
end


