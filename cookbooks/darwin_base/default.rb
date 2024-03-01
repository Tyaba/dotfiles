case node[:platform]
when 'darwin'
  execute 'disable screen saver' do
    command 'sudo defaults -currentHost write com.apple.screensaver idleTime 0'
  end
else
  raise NotImplementedError
end
