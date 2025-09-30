case node[:platform]
when 'ubuntu'
  package 'software-properties-common'
  package 'locales'
when 'debian'
  # Debian 13 (trixie)ではsoftware-properties-commonが利用できない場合がある
  # 代わりに、必要な依存関係を個別にインストール
  package 'apt-transport-https'
  package 'ca-certificates'
  package 'gnupg'
  package 'lsb-release'
  package 'locales'
end
  # localeをen_US.UTF-8したい。
  # デフォルトでは無い場合があるのでlocale-gen en_US.UTF-8したい。
  # en_USがないため、locales-allをinstallしたい。
  # locales-allはno installation candidateになるのでuniverseをapt repoに入れる
  # universeを入れるために、launchpad-getkeysをinstallしたい。
  # launchpad-getkeysはデフォルトでinstallできないので、ppaを追加する。
case node[:platform]
when 'ubuntu'
  execute 'locale-gen' do
    command "
    sudo add-apt-repository -y ppa:nilarimogard/webupd8 &&
    sudo apt-get update &&
    sudo apt-get install -y launchpad-getkeys &&
    sudo apt-get update &&
    sudo add-apt-repository -y universe &&
    sudo apt-get update &&
    sudo apt-get install -y locales-all &&
    sudo locale-gen en_US.UTF-8 &&
    sudo update-locale --no-checks LANG=en_US.UTF-8
    "
  not_if "locale | grep 'Cannot set'"
  end
when 'debian'
  execute 'locale gen' do
    command '
    sudo apt-get update &&
    sudo apt-get install -y locales-all &&
    sudo locale-gen --purge "en_US.UTF-8" &&
    sudo dpkg-reconfigure --frontend noninteractive locales
    '
    not_if "locale | grep 'Cannot set'"
  end
end


# libffi-devを入れる。
case node[:platform]
when 'ubuntu'
  package 'libffi-dev'
end

case node[:platform]
when 'ubuntu', 'debian'
  package 'zlib1g-dev'
  package 'openssh-client'
  package 'build-essential'
end
package 'curl'
package 'zip'
package 'tmux'

# クリップボードコピー
case node[:platform]
when 'darwin'
  # macはpbcopyがデフォルトで入っている
  MItamae.logger.info "macOS detected, skip install xclip"
else
  package 'xclip'
end
