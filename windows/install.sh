# prerequisites
# cargo: https://doc.rust-lang.org/cargo/getting-started/installation.html
# ohmyzsh もしなければ
if [ ! -d ~/.oh-my-zsh ]; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

# 設定をcp
mv ~/.zshrc ~/.bkup.zshrc
cp ~/.dotfiles/config/.zshrc ~/.zshrc
cp ~/.dotfiles/config/.zshrc.windows ~/.zshrc.windows

# pacmanでinstall
# FIXME: $MSYS_PATH/usr/bin/pacman
pacman_install="/c/msys64/usr/bin/pacman -S --noconfirm --needed"
# cargoでinstall
cargo_install="cargo install --force --verbose"
pacman_packages=(
    "curl"
    "zip"
    "git"
    "emacs"
    "zsh"
)
cargo_packages=(
    "bat"
    "du-dust"
    "bottom"
    "ripgrep"
    "fd-find"
    "hub"
)
# pacman package install
for package in "${pacman_packages[@]}" ; do
    if [[ $(pacman -Q | grep ${package}) ]]; then
        echo "${package} is already installed with pacman"
        continue
    fi
    $pacman_install ${package}
done
# cargo package install
for package in "${cargo_packages[@]}" ; do
    if [[ $(cargo install --list | grep ${package}) ]]; then
        echo "${package} is already installed with cargo"
        continue
    fi
    $cargo_install ${package}
done

# TODO: fzf, exa, direnv

# zsh plugin install
if [ ! -d ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions ]; then
    echo "zsh-autosuggestions is already installed"
else
    git clone https://github.com/zsh-users/zsh-autosuggestions.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
fi

# zshを使う設定
ln -s ~/.dotfiles/windows/config/.bashrc ~/.bashrc