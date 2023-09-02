package 'software-properties-common'

# localeをen_US.UTF-8したい。
# デフォルトでは無い場合があるのでlocale-gen en_US.UTF-8したい。
# en_USがないため、locales-allをinstallしたい。
# locales-allはno installation candidateになるのでuniverseをapt repoに入れる
# universeを入れるために、launchpad-getkeysをinstallしたい。
# launchpad-getkeysはデフォルトでinstallできないので、ppaを追加する。
package 'locales'
execute 'locale-gen-setup' do
  case node[:platform]
  when 'ubuntu', 'debian'
    command "
    sudo add-apt-repository ppa:nilarimogard/webupd8 &&
    sudo apt-get update &&
    sudo apt-get install launchpad-getkeys &&
    sudo apt-get update &&
    sudo add-apt-repository -y universe &&
    sudo apt-get update &&
    sudo apt-get install -y locales-all &&
    sudo locale-gen en_US.UTF-8 &&
    sudo update-locale LANG=en_US.UTF-8
    "
  end
  not_if "locale | grep en_US.UTF-8"
end

case node[:platform]
when 'ubuntu', 'debian'
  execute "sudo apt-key adv --keyserver hkp://keyserver.#{node[:platform]}.com:80 --recv-keys 15CF4D18AF4F7421"
  execute "sudo apt-get update"
end
package 'libffi-dev'
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