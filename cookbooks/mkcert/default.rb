case node[:platform]
when 'darwin'
  execute 'brew install mkcert nss' do
    not_if 'which mkcert'
  end

  execute 'mkcert -install' do
    not_if 'security find-certificate -c "mkcert" /Library/Keychains/System.keychain > /dev/null 2>&1'
  end
else
  raise NotImplementedError
end
