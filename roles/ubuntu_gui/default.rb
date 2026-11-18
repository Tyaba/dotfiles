# coding: utf-8
# Ubuntu のデスクトップ環境専用の設定。
# roles/ubuntu が gnome-shell の有無を判定して include する。
include_cookbook 'vicinae'

# cookbooks/ghostty は SSH 接続先でも必要な terminfo だけを扱うため、
# 端末アプリ本体はデスクトップ環境でのみ入れる。
package 'ghostty'
dotfile '.config/ghostty'
include_cookbook 'jetbrains-mono-nerd-font'
include_cookbook 'gnome-settings'

# macOS の Karabiner-Elements に相当するキー変換
include_cookbook 'xremap'

# Wayland のクリップボード操作（pbcopy / pbpaste の実体）
package 'wl-clipboard'

# ローカル開発プロキシ（*.tyaba.test）
include_cookbook 'dnsmasq'
include_cookbook 'mkcert'
include_cookbook 'traefik'
