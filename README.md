# dotfiles
> Accio, My Utensils!

## TODO
- [x] linuxのときsudo locale-gen en_US.UTF-8するlocale cookbook追加
- [x] linuxのときlibffi-develをinstallするcookbook追加
- [x] cookbooks/poetryの20行目 poetry not foundになる

## Usage
### Clone this repository
```shell
git clone --recursive https://github.com/Tyaba/dotfiles.git
```
### Clone submodule (zplug)
```shell
git submodule init
git submodule update
```
### wslの場合
windowsのPATHが入っているとinstall済と誤判定するので直す
sudo emacs /etc/wsl.conf
```
# WindowsのPATHを引き継がない設定を追記する
[interop]
appendWindowsPath = false
```

### Dry-run
```shell
./install.sh -n
```

### Apply
```shell
./install.sh
```

### Add new cookbook
```shell
mkdir cookbooks/:app_name
$EDITOR cookbooks/:app_name/default.rb
$EDITOR roles/$(uname)/default.rb
```

