# prerequisites:
# install cargo from https://doc.rust-lang.org/cargo/getting-started/installation.html
#

# "ln"等を効かせるために、MSYS=winsymlinks:nativestrictを設定
export MSYS=winsymlinks:nativestrict
# .bashrcを用意
if [ ! -f ~/.bashrc ]; then
    sudo ln -s ~/.dotfiles/windows/config/.bashrc ~/.bashrc
fi
# .bash_profileを用意
if [ ! -f ~/.bashrc ]; then
    sudo ln -s ~/.dotfiles/windows/config/.bash_profile ~/.bash_profile
fi
# .bashを用意
if [ ! -d ~/.bash ]; then
    ln -s ~/.dotfiles/windows/config/.bash ~/.bash
fi
# package manager
winget_install="winget install --force"
cargo_install="cargo install --force --verbose"
# winget install
winget_packages=(
    "BurntSushi.ripgrep.MSVC"
    "GNU.Emacs"
    "JernejSimoncic.Wget"
)
for package in ${winget_packages[@]}; do
    # if ! winget show $package &> /dev/null; then
    $winget_install ${package}
    # fi
done

# exa
cargo install --git https://github.com/skyline75489/exa --branch chesterliu/dev/win-support
# cargo install
cargo_packages=(
    "autojump"
    "bat"
    "bottom"
    "du-dust"
    "fd-find"
    "hub"
    "ripgrep"
)
# cargo package install
for package in "${cargo_packages[@]}" ; do
    if [[ $(cargo install --list | grep ${package}) ]]; then
        echo "${package} is already installed with cargo"
        continue
    fi
    $cargo_install ${package}
done

# fzf
if [ ! -d ~/.fzf ]; then
    git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
    ~/.fzf/install --all
fi

# poetry
curl -sSL https://install.python-poetry.org | python3 -
