case node[:platform]
when 'darwin'
  execute 'brew install mkcert nss' do
    not_if 'which mkcert'
  end

  execute 'mkcert -install' do
    not_if 'security find-certificate -c "mkcert" /Library/Keychains/System.keychain > /dev/null 2>&1'
  end
when 'ubuntu', 'debian'
  package 'mkcert'
  package 'libnss3-tools'

  ca_root = "#{ENV['HOME']}/.local/share/mkcert"
  system_ca = '/usr/local/share/ca-certificates/mkcert-development-ca.crt'

  # mkcert cannot prompt for sudo here, so it only handles the user's browser
  # trust stores and the system store is updated by the next resource.
  execute 'create mkcert local CA' do
    command %Q[HOME="#{ENV['HOME']}" CAROOT="#{ca_root}" TRUST_STORES=nss mkcert -install]
    user node[:user] if node[:user]
    not_if %Q[test -f "#{ca_root}/rootCA.pem"]
  end

  execute 'trust mkcert local CA system-wide' do
    command %Q[install -m 0644 "#{ca_root}/rootCA.pem" #{system_ca} && update-ca-certificates]
    not_if %Q[cmp -s "#{ca_root}/rootCA.pem" #{system_ca}]
  end
else
  raise NotImplementedError
end
