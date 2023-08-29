# dotfiles
> Accio, My Utensils!

## TODO
- [] linuxのときsudo locale-gen en_US.UTF-8するlocale cookbook追加
- [] linuxのときlibffi-develをinstallするcookbook追加

## Usage
### Clone this repository
```shell
git clone --recursive https://github.com/Tyaba/dotfiles.git
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
