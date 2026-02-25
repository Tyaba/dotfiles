local_ruby_block 'install bun' do
  bun_path = "#{ENV['HOME']}/.bun/bin/bun"

  block do
    system("curl -fsSL https://bun.sh/install | bash")

    until File.exist?(bun_path)
      sleep 1
    end
  end
  not_if "test -f #{bun_path}"
end
