case node[:platform]
when 'darwin'
  execute 'brew install --cask ghostty' do
    not_if 'test -d /Applications/Ghostty.app'
  end
else
  # Install xterm-ghostty terminfo for SSH sessions from Ghostty
  terminfo_src = File.join(File.dirname(__FILE__), 'files', 'xterm-ghostty.terminfo')
  execute "tic -x #{terminfo_src}" do
    not_if 'infocmp xterm-ghostty > /dev/null 2>&1'
  end
end
