case node[:platform]
when 'darwin'
  execute 'brew install --cask ghostty' do
    not_if 'test -d /Applications/Ghostty.app'
  end
else
  # Install xterm-ghostty terminfo for SSH sessions from Ghostty
  execute 'curl -fSL -o /tmp/ghostty.terminfo https://raw.githubusercontent.com/ghostty-org/ghostty/main/src/terminfo/ghostty.terminfo && tic -x /tmp/ghostty.terminfo' do
    not_if 'infocmp xterm-ghostty > /dev/null 2>&1'
  end
end
