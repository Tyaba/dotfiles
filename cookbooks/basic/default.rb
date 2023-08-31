# locale-gen
package 'locales'
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