case node[:platform]
when 'darwin'
  execute 'disable screen saver' do
    command 'defaults -currentHost write com.apple.screensaver idleTime -int 0'
    not_if 'defaults -currentHost read com.apple.screensaver idleTime | test -w 0'
  end
else
  raise NotImplementedError
end
