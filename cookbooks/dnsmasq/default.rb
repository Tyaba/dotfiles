case node[:platform]
when 'darwin'
  # dnsmasq は $(brew --prefix)/sbin に入り、PATH に sbin が無い環境では which が常に失敗する。
  # which 判定だと install が毎回実行扱いになり restart 通知が毎回飛ぶため、brew list で判定する。
  execute 'brew install dnsmasq' do
    not_if 'brew list dnsmasq >/dev/null 2>&1'
    notifies :run, 'execute[restart dnsmasq]', :delayed
  end

  execute 'mkdir -p "$(brew --prefix)/etc/dnsmasq.d"' do
    not_if 'test -d "$(brew --prefix)/etc/dnsmasq.d"'
  end

  execute 'configure dnsmasq for .test wildcard' do
    command 'printf "%s\n" "address=/test/127.0.0.1" > "$(brew --prefix)/etc/dnsmasq.d/tyaba-test.conf"'
    not_if 'test -f "$(brew --prefix)/etc/dnsmasq.d/tyaba-test.conf" && grep -qx "address=/test/127.0.0.1" "$(brew --prefix)/etc/dnsmasq.d/tyaba-test.conf"'
    notifies :run, 'execute[restart dnsmasq]', :delayed
  end

  execute 'create /etc/resolver/test for .test wildcard' do
    command 'sudo mkdir -p /etc/resolver && printf "%s\n" "nameserver 127.0.0.1" | sudo tee /etc/resolver/test > /dev/null'
    not_if 'test -f /etc/resolver/test && grep -q "nameserver 127.0.0.1" /etc/resolver/test'
  end

  # restart は install または conf 更新の通知時だけ遅延実行し、定常状態では sudo を呼ばない。
  # sudo の secure_path に Homebrew の bin が含まれない環境向けに $(which brew) でフルパスを解決する。
  # root サービスの状態は非 sudo の brew services list では正しく判定できないため、停止判定には pgrep -x dnsmasq を使う。
  execute 'start dnsmasq if stopped' do
    command "sudo \"$(which brew)\" services start dnsmasq"
    not_if 'pgrep -x dnsmasq'
  end

  execute 'restart dnsmasq' do
    command "sudo \"$(which brew)\" services restart dnsmasq"
    action :nothing
  end
else
  raise NotImplementedError
end
