case node[:platform]
when 'darwin'
  execute 'brew install dnsmasq' do
    not_if 'which dnsmasq'
  end

  execute 'mkdir -p "$(brew --prefix)/etc/dnsmasq.d"' do
    not_if 'test -d "$(brew --prefix)/etc/dnsmasq.d"'
  end

  execute 'configure dnsmasq for .test wildcard' do
    command 'printf "%s\n" "address=/test/127.0.0.1" > "$(brew --prefix)/etc/dnsmasq.d/tyaba-test.conf"'
    not_if 'test -f "$(brew --prefix)/etc/dnsmasq.d/tyaba-test.conf" && grep -qx "address=/test/127.0.0.1" "$(brew --prefix)/etc/dnsmasq.d/tyaba-test.conf"'
  end

  execute 'create /etc/resolver/test for .test wildcard' do
    command 'sudo mkdir -p /etc/resolver && printf "%s\n" "nameserver 127.0.0.1" | sudo tee /etc/resolver/test > /dev/null'
    not_if 'test -f /etc/resolver/test && grep -q "nameserver 127.0.0.1" /etc/resolver/test'
  end

  execute 'sudo brew services restart dnsmasq' do
    not_if 'sudo brew services list | grep -E "^dnsmasq[[:space:]]+started"'
  end
else
  raise NotImplementedError
end
