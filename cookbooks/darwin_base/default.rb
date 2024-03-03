# ref: https://furusax0621.hatenablog.com/entry/2019/03/06/093921
case node[:platform]
when 'darwin'
  # font
  # you can search font with `brew search '/font-.*-nerd-font/'`
  execute 'download hack nerd font' do
    command"brew tap homebrew/cask-fonts && brew install --cask font-meslo-lg-nerd-font"
    not_if 'brew list --cask | grep font-meslo-lg-nerd-font'
  end
  # システム環境設定
  execute 'disable screen saver' do
    command 'defaults -currentHost write com.apple.screensaver idleTime -int 0'
    not_if 'defaults -currentHost read com.apple.screensaver idleTime | test -w 0'
  end
  execute 'disable hidden files in finder' do
    command 'defaults write com.apple.finder AppleShowAllFiles -boolean true'
    not_if 'defaults read com.apple.finder AppleShowAllFiles | test -w 1'
  end
  execute 'disable live henkan' do
    command 'defaults write com.apple.inputmethod.Kotoeri JIMPrefLiveConversionKey 0'
    not_if 'defaults read com.apple.inputmethod.Kotoeri JIMPrefLiveConversionKey | test -w 0'
  end
  execute 'display suffix in finder' do
    command 'defaults write NSGlobalDomain AppleShowAllExtension -bool true'
    not_if 'defaults read NSGlobalDomain AppleShowAllExtension | test -w 1'
  end
  execute 'display battery percentage' do
    command 'defaults write com.apple.menuextra.battery ShowPercent -string "YES"'
    not_if 'defaults read com.apple.menuextra.battery ShowPercent | test -w YES'
  end
  execute 'enable tap to click' do
    command 'defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true && defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1 && defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1'
    not_if 'defaults read com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking | test -w 1'
  end
  execute 'enable two finger tap to right click' do
    command 'defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -int 1 && defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadRightClick -int 1 && defaults write com.apple.AppleMultitouchTrackpad Clicking -int 1 && defaults write com.apple.AppleMultitouchTrackpad TrackpadRightClick -int 1'
    not_if 'defaults read com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking | test -w 1'
  end
  # not working
  execute 'enable quick trackpad and mouse' do
    command 'defaults write -g com.apple.trackpad.scaling -float 3.0 && defaults write -g com.apple.mouse.scaling -float 3.0'
    not_if 'defaults read -g com.apple.trackpad.scaling | test -w 3'
  end
  execute 'set dark mode' do
    command "osascript -e 'tell application \"System Events\" to tell appearance preferences to set dark mode to true'"
    not_if "osascript -e 'tell application \"System Events\" to tell appearance preferences to get dark mode' | test -w true"
  end
  execute 'disable DS_Store' do
    command 'defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true && defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true'
    not_if 'defaults read com.apple.desktopservices DSDontWriteNetworkStores | test -w 1'
  end
else
  raise NotImplementedError
end
