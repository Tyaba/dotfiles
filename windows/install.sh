# prerequisites
# cargo: https://doc.rust-lang.org/cargo/getting-started/installation.html
# ohmyzsh もしなければ
if [ ! -d ~/.oh-my-zsh ]; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

# 設定をcp
mv ~/.zshrc ~/.bkup.zshrc
ln -s ~/.dotfiles/config/.zshrc ~/
ln -s ~/.dotfiles/config/.zshrc.windows ~/

# pacmanでinstall
# FIXME: $MSYS_PATH/usr/bin/pacman
pacman_install="/c/msys64/usr/bin/pacman -S --noconfirm --needed"
# cargoでinstall
cargo_install="cargo install --force --verbose"
pacman_packages=(
    "curl"
    "emacs"
    "git"
    "man"
    "unzip"
    "zip"
    "zsh"
)
cargo_packages=(
    "autojump"
    "bat"
    "bottom"
    "du-dust"
    "fd-find"
    "hub"
    "ripgrep"
)
zsh_plugins=(
    "zsh-autosuggestions"
    "zsh-completions"
    "zsh-history-substring-search"
    "zsh-syntax-highlighting"
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

# fzf
if [ -d $HOME/.fzf ]; then
    echo "fzf is already installed"
else
    git clone --depth 1 https://github.com/junegunn/fzf.git $HOME/.fzf && $HOME/.fzf/install --all
fi
# direnv
if [ -d /usr/local/bin ]; then
    echo "direnv is already installed"
else
    curl -sfL https://direnv.net/install.sh | bin_path=/usr/local/bin bash
fi

# zsh plugin install
for plugin in "${zsh_plugins[@]}" ; do
    if [ -d ${ZSH_CUSTOM:-${ZSH:-~/.oh-my-zsh}/custom}/plugins/${plugin} ]; then
        echo "${plugin} is already installed"
        continue
    fi
    git clone https://github.com/zsh-users/${plugin} ${ZSH_CUSTOM:-${ZSH:-~/.oh-my-zsh}/custom}/plugins/${plugin}
done
# enhancd
if [ -d ${ZSH_CUSTOM:-${ZSH:-~/.oh-my-zsh}/custom}/plugins/enhancd ]; then
        echo "enhancd is already installed"
else
    git clone https://github.com/b4b4r07/enhancd ${ZSH_CUSTOM:-${ZSH:-~/.oh-my-zsh}/custom}/plugins/enhancd
fi
# pyenv
if [ -d ~/.pyenv ]; then
    echo "pyenv is already installed"
else
    git clone https://github.com/pyenv-win/pyenv-win.git ~/.pyenv
fi
# zshを使う設定
ln -s ~/.dotfiles/windows/config/.bashrc ~/.bashrc
