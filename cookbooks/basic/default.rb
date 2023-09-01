package 'software-properties-common'

# locale-gen
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
    sudo apt-get update
    "
  end
  not_if "locale | grep en_US.UTF-8"
end

package 'locales-all'
execute 'sudo locale-gen en_US.UTF-8' do
  not_if "locale | grep en_US.UTF-8"
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