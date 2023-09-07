case node[:platform]
when 'ubuntu', 'debian'
  package 'software-properties-common'
  package 'locales'
  # localeをen_US.UTF-8したい。
  # デフォルトでは無い場合があるのでlocale-gen en_US.UTF-8したい。
  # en_USがないため、locales-allをinstallしたい。
  # locales-allはno installation candidateになるのでuniverseをapt repoに入れる
  # universeを入れるために、launchpad-getkeysをinstallしたい。
  # launchpad-getkeysはデフォルトでinstallできないので、ppaを追加する。
  # TODO: fix ログは出ないし終わらない
  execute 'locale-gen-setup' do
    case node[:platform]
    when 'ubuntu', 'debian'
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
    end
    not_if "locale | grep en_US.UTF-8"
  end
end

# libffi-devを入れる。
case node[:platform]
when 'ubuntu', 'debian'
  execute 'install libffi-dev' do
    command "
    sudo apt-key adv --keyserver hkp://keyserver.#{node[:platform]}.com:80 --recv-keys 15CF4D18AF4F7421 &&
    sudo apt-get update &&
    sudo apt-get install -y libffi-dev
    "
  end
  not_if "dpkg -l | grep '^ii' | grep libffi-dev"
end

case node[:platform]
when 'ubuntu', 'debian'
  package 'zlib1g-dev'
  package 'openssh-client'
  package 'build-essential'
end
package 'curl'
package 'zip'

# クリップボードコピー
case node[:platform]
when 'darwin'
  # macはpbcopyがデフォルトで入っている
  MItamae.logger.info "macOS detected, skip install xclip"
else
  package 'xclip'
end
