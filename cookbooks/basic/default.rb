package 'software-properties-common'

# localeをen_US.UTF-8したい。
# デフォルトでは無い場合があるのでlocale-gen en_US.UTF-8したい。
# en_USがないため、locales-allをinstallしたい。
# locales-allはno installation candidateになるのでuniverseをapt repoに入れる
# universeを入れるために、launchpad-getkeysをinstallしたい。
# launchpad-getkeysはデフォルトでinstallできないので、ppaを追加する。
package 'locales'
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

# libffi-devを入れたい。
# TODO: failするので修正
execute 'install libffi-dev' do
  case node[:platform]
  when 'ubuntu', 'debian'
    command "
    sudo apt-key adv --keyserver hkp://keyserver.#{node[:platform]}.com:80 --recv-keys 15CF4D18AF4F7421 &&
    sudo apt-get update &&
    sudo apt-get install -y libffi-dev
    "
  end
  not_if "dpkg -l | grep '^ii' | grep libffi-dev"
end

package 'zlib1g-dev'
package 'curl'
package 'openssh-client'
package 'build-essential'
package 'zip'

# クリップボードコピー
case node[:platform]
when 'darwin'
  # macはpbcopyがデフォルトで入っている
  Mitamae.logger.info "macOS detected, skip install xclip"
else
  package 'xclip'
end