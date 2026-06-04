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

  # brew services restart は停止中でも起動するため idempotent。conf 更新時に毎回 reload する目的で not_if は付けない。
  # sudo の secure_path に /opt/homebrew/bin が含まれない環境向けに $(which brew) でフルパスを解決。
  execute 'sudo brew services restart dnsmasq' do
    command "sudo \"$(which brew)\" services restart dnsmasq"
  end
else
  raise NotImplementedError
end
