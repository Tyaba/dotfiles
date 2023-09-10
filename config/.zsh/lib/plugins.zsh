#!/bin/zsh
# oh my zsh path
if [ "$OSTYPE" == "msys" ]; then
    echo "windows msys detected"
else
    export ZSH="$HOME/.local/share/sheldon/repos/github.com/ohmyzsh/ohmyzsh"
    ZSH_THEME="jonathan"
fi
## enhancd: cd -> ls
export ENHANCD_HOOK_AFTER_CD=ls

# sheldon 設定を読み込む
if [ "$OSTYPE" == "msys" ]; then
    echo "windows msys detected"
else
    eval "$(sheldon source)"
fi

